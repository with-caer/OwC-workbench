"""A Python Pulumi program"""

import pulumi
import pulumi_cloudflare as cloudflare

# Load configuration.
workbench_config = pulumi.Config()
account_id = workbench_config.require('account_id')
team_name = workbench_config.require('team_name')
policy_id = workbench_config.require('policy_id')
app_domain = workbench_config.require('app_domain')
app_subdomain = workbench_config.require('app_subdomain')

# Find the Cloudflare Zone ID for the configured account ID.
zones = cloudflare.get_zones(
    account = {"id": account_id},
    status = "active",
    name = app_domain,
)
zone = zones.results[0]

# Provision Cloudflare access application.
workbench_tunnel_access_app = cloudflare.ZeroTrustAccessApplication(
    "workbench-tunnel-access-app",
    zone_id = zone.id,
    name = f"{app_subdomain}-{app_domain}-access-app",
    domain = f"{app_subdomain}.{app_domain}",
    type = "self_hosted",
    session_duration = "24h",
    auto_redirect_to_identity = False,
    policies = [{"id": policy_id}],
)
workbench_access_app_aud = workbench_tunnel_access_app.aud.apply(lambda aud: f"{aud}")

# Provision Cloudflare tunnel.
workbench_tunnel = cloudflare.ZeroTrustTunnelCloudflared(
    "workbench-tunnel",
    account_id = account_id,
    name = f"{app_subdomain}-{app_domain}-tunnel",
    config_src = "cloudflare",
)

# Export the tunnel's token for local use.
workbench_tunnel_token = cloudflare.get_zero_trust_tunnel_cloudflared_token_output(
    account_id = workbench_tunnel.account_id,
    tunnel_id =  workbench_tunnel.id,
);
pulumi.export("workbench_tunnel_token", workbench_tunnel_token.token)

# Provision CNAME record (HTTP path) routing traffic to the tunnel.
workbench_tunnel_cname = cloudflare.DnsRecord(
    "workbench-tunnel-cname",
    zone_id = zone.id,
    name = app_subdomain,
    type = "CNAME",
    proxied = True,
    ttl = 1,

    # See: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/routing-to-tunnel/dns/#create-a-dns-record-for-the-tunnel
    content = workbench_tunnel.id.apply(lambda id: f"{id}.cfargotunnel.com"),
)

# Configure tunnel.
workbench_tunnel_config = cloudflare.ZeroTrustTunnelCloudflaredConfig(
    "workbench-tunnel-config",
    account_id = account_id,
    tunnel_id =  workbench_tunnel.id.apply(lambda id: id),
    config = {
        "ingresses": [

            # Route traffic from the tunnel to the local
            # code-server service listening on port 31545.
            {
                # Public hostname the tunnel binds to.
                "hostname": f"{app_subdomain}.{app_domain}",

                # Local service the tunnel routes to.
                "service": "http://localhost:31545",

                # Require an authenticated access user.
                "origin_request": {
                    "access": {
                        "required": True,
                        "team_name": team_name,
                        "aud_tags": [workbench_access_app_aud]
                    }
                },
            },

            # Default rule to return a 404 if no other rules match.
            {
                "service": "http_status:404",
            }
        ]
    }
)