Workbenches are single-user development environments
intended to be hosted on dedicated VMs, physical workstations, or [Dev Containers](https://containers.dev).

## Getting Started

### With a Dev Container

The easiest way to get started with Workbenches is to use
the pre-built [Workbench Dev Container](.devcontainer/):

```json
{
    "image": "ghcr.io/with-caer/owc/workbench:latest"
}
```

Once your Workbench Dev Container is up-and-running, consider
trying some of the [Workbench Dev Container Features](#workbench-dev-container-features).

### With a VM/Server/Computer

Alternatively, the  [`install-local.sh`](install-local.sh) script can be used to configure a fresh Fedora 42+ installation as a workbench. In addition to configuring the workbench, this script will provision a Cloudflare Tunnel to expose the workbench over the internet for remote use via a bundled [code-server](https://github.com/coder/code-server). 

## Workbench Tools

Workbenches (when provided as a pre-built Dev Container, or when installed via the local installer script) come with a set of pre-installed command-line tools:

- [`owc-commit`](tools/commit.sh): A thin wrapper around `git` for performing ["Conventional Commits"](https://www.conventionalcommits.org/en/v1.0.0/) with
auto-generated changelogs normalized timestamps.

- [`owc-release`](tools/release.sh): A thin wrapper around [`cargo release`](https://github.com/crate-ci/cargo-release) for publishing Rust workspaces to
[crates.io](https://crates.io) with auto-generated changelogs and semantic versioning.

These tools can be _manually_ installed onto any UNIX system via the [`install-tools.sh`](install-tools.sh) script. Tools will be installed to `/usr/local/bin`, and their default configurations will be installed into `/usr/local/etc/owc`.

## Workbench Dev Container Features

```json
"features": {

    // DuckDB native libraries.
    "ghcr.io/with-caer/owc/workbench/duckdb": {
        "version": "1.3.2"
    },

    // Macroquad native libraries.
    "ghcr.io/with-caer/owc/workbench/macroquad": {},
}
```

## What's Here

1. `assets/` contains reusable assets like fonts, imagery, and system patches for configuring new workbenches.

2. `features/` contains reusable Dev Container features for use with the Workbench Dev Container.

3. `pulumi/` contains [Pulumi](https://www.pulumi.com) for provisioning cloud infrastructure, like [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/), for workbenches.

4. `pyinfra/` contains [PyInfra](https://pyinfra.com) templates for configuring new workbenches.

5. `tools/` contains tools, shell scripts, and configuration files for the tools pre-installed on workbenches.