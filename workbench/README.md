> _Note_: The contents of this repository are built on the assumption that
> every workbench is based off of [Fedora](https://fedoraproject.org)
> `42` or newer.

Workbenches are single-user development environments
intended to be hosted on dedicated VMs or physical workstations.

## What's Here

### Basic System Configuration

0. `./configure-packages.sh` (run as `root`): Configures the DNF package manager and performs an initial refresh of all installed packages.

1. `./configure-user.sh $USER_NAME` (run as `root`): Configures a non-`root` `$USER_NAME ` with `sudo` access.

### Networked System Configuration

1. `./configure-network.sh` (run as `root` or with `sudo`): Configures networking, including the SSH server and firewall rules.

2. `./configure-code-server.sh $USER_NAME` (run as `root` or with `sudo`): Installs and configures
[`code-server`](https://github.com/coder/code-server) to run as `$USER_NAME` on start-up.
   > It's recommended to run `code-server` as the primary non-`root` user account on the workbench.

3. `./provision-code-server-network.sh`: Provisions a [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
via [Pulumi](https://www.pulumi.com) for the `code-server`, exposing the locally-configured `code-server` instance over the tunnel.

### Default Customizations

0. `default-bashrc.sh`: This file contains a default `.bashrc` with a pretty shell.

1. `default-vscode-settings.json`: This file contains a default VS Code `settings.json` intended
to pair with the defaults in `install-default-code-server-extensions.sh`.

2. `./install-default-packages.sh` (run as `root` or with `sudo`): Installs a set of recommended
development packages.

3. `./install-default-rust-packages.sh`: Installs a set of packages recommended for [`Rust`](https://www.rust-lang.org) development.

4. `./install-default-code-server-extensions.sh`: Installs a set of recommended extensions for `Rust` development into the locally-deployed `code-server` instance.