Templates for building single-tenant hosted coding environments
("**workbenches**") based on [code-server](https://github.com/coder/code-server),
with access managed by [Cloudflare](https://developers.cloudflare.com/cloudflare-one/).

## Prerequisites

To use these templates, you'll need:

1. A [Hetzner](https://www.hetzner.com/) account, for hosting the Workbench VM(s).
2. A [Cloudflare](https://www.cloudflare.com/) account, for managing access to the Workbench VM(s).
3. A domain managed by and registered to your Cloudflare account.
4. [`packer`](https://developer.hashicorp.com/packer) to build the Workbench VM(s).
5. [`terraform`](https://developer.hashicorp.com/terraform) to deploy the Workbench VM(s).

If you're on some flavor of RHEL, Fedora, or Rocky Linux,
you can install all the prerequisites by running this script:

```sh
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y packer terraform
```

## Building the VM Image

First, create a `packer/variables.auto.pkrvars.hcl` containing:

```hcl
hetzner_api_token = "HETZNER_TOKEN"
```

Where:

- `HETZNER_TOKEN` is your [Hetzner API Token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/).

Then, run: `sh build.sh`

<details>
<summary>Click me to learn what <code>build.sh</code> does!</summary>

This script executes [this `packer` template](packer/workbench.pkr.hcl),
which configures and publishes a new [Rocky Linux](https://rockylinux.org/)
snapshot image to your Hetzner account.

This image:

- Installs _common_ dev packages like `git`, `docker`, and `epel-release`.
  Language-specific packages like `npm` or `cargo` are _not_ installed.

- Is hardened against network attacks, including strict default
  `firewalld`, `sshd`, and `fail2ban` configurations that only
  allow access to the VM via the `cloudflared` tunnel, or over
  `SSH` from the private `10.0.0.0/24` IP address range.

- Installs a lightly customized version of
  [code-server](https://github.com/coder/code-server).

This image _doesn't_ create any user accounts, or configure
the networking services for `code-server` or `cloudflared`;
these steps are handled during the `terraform` deployment.
</details>

## Deploying the VM Image

First, create a `terraform/variables.auto.tfvars`, containing:

```tfvars
user_name  = "YOUR_USER_NAME"
user_email = "YOUR_EMAIL"

cf_api_token        = "CLOUDFLARE_TOKEN"
cf_account_id       = "ACCOUNT_ID"
cf_team_name        = "CLOUDFLARE_TEAM_NAME"
cf_app_domain       = "YOUR_DOMAIN"
cf_app_subdomain    = "YOUR_SUBDOMAIN"

hetzner_api_token     = "HETZNER_TOKEN"
```

Where:

- `YOUR_USER_NAME` is whatever you'd like your user name in the workbench to be.
- `YOUR_EMAIL` is the email address which Cloudflare Access will authenticate
  against when accessing the workbench.
- `CLOUDFLARE_TOKEN` is your [Cloudflare API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/), which must have the following permissions:
   - `Account / Cloudflare Tunnel / Edit`
   - `Account / Access: Apps and Policies / Edit`
   - `Zone / Access: Apps and Policies / Edit`
   - `Zone / DNS / Edit`
- `ACCOUNT_ID` is your [Cloudflare Account ID](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/).
- `CLOUDFLARE_TEAM_NAME` is the name of your team in Cloudflare Access;
  this name is the `<your-team-name>` in `<your-team-name>.cloudflareaccess.com`.
- `YOUR_DOMAIN` is the _name_ of the Cloudflare domain to connect the VM to.
- `YOUR_SUBDOMAIN` is the _name_ of the subdomain to connect the VM to.
- `HETZNER_TOKEN` is your [Hetzner API Token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/).

Then, run: `sh deploy.sh`

If anything goes wrong, you can run `terraform destroy` from
within the `terraform` directory. This command will destroy
any resources that were created (or partially created) by
`sh deploy.sh`.

<details>
<summary>Click me to learn what <code>deploy.sh</code> does!</summary>

This script executes a `terraform` deployment, which will:

1. Provision a new [Cloudflare Access Application](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/self-hosted-apps/) connected to `YOUR_DOMAIN.YOUR_SUBDOMAIN`, with
   a default access policy of _only_ granting access to users with `YOUR_EMAIL`.

2. Provision a new [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/), which will route traffic from Cloudflare's
   network to the workbench--but only if that traffic successfully authenticates
   with the Access app from step 1.

3. Provision a new `CNAME` record in your Cloudflare domain, which will
   route traffic from your domain to the workbench via the Cloudflare tunnel.

4. Provision a new Hetzner VM using the snapshot created by `build.sh`
   in the previous section.
   - The VM is provisioned with a new virtual private network.
   - The VM is provisioned with a _public_ `IPv4` address due
     to constraints imposed by Hetzner; however, almost no traffic
     will be able to actually _access_ the VM via the public IP.

Upon provisioning the VM, the `terraform` deployment will upload two
scripts to the VM:

1. A [_common_](terraform/workbench.cloud-init.tftpl.sh) setup script.
2. A [_user-specified_](terraform/user-setup.sh) setup script.

The _common_ setup script:

- Creates and configures a new user account with `YOUR_USER_NAME`.
- Installs a `systemd` service for launching `code-server` as the user on start-up.
- Executes the _user-specified_ setup script (if any).
- Installs a `systemd` service for `cloudflared`, connecting it to the Cloudflare network.

The _user-specified_ setup script can contain anything you like,
and can be a good place to install and configure your ideal dev
environment. The output this script is piped to `~/.workbench/setup.log`
if you need to debug any issues during the first boot.
</details>