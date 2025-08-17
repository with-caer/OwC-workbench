Workbenches are single-user development environments
intended to be hosted on dedicated VMs, physical workstations, or [Dev Containers](https://containers.dev).

## Getting Started

### With a Dev Container

The easiest way to get started with Workbenches is to use
one of the pre-built [Workbench Dev Containers](../devcontainers/).

### With a VM/Server/Computer

Alternatively, the  [`install-local.sh`](install-local.sh) can be used to configure a fresh Fedora 42+ installation as a workbench. In addition to configuring the workbench, this script will provision a Cloudflare Tunnel to expose the workbench over the internet for remote use via a bundled [code-server](https://github.com/coder/code-server). 

## What's Here

1. `assets/` contains reusable assets like fonts, imagery, and system patches for configuring new workbenches.

2. `pulumi/` contains [Pulumi](https://www.pulumi.com) for provisioning cloud infrastructure, like [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/), for workbenches.

3. `pyinfra` contains [PyInfra](https://pyinfra.com) templates for configuring new workbenches.