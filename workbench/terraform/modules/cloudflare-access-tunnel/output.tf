output "cf_tunnel_token" {
  value = cloudflare_tunnel.workbench_tunnel.tunnel_token
  description = "Token which will connect any remote agent to the tunnel via `cloudflared service install`"
  sensitive = true
}