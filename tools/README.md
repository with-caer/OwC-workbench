## What's Here

- [`owc-commit`](commit.sh): A thin wrapper around `git` for performing ["Conventional Commits"](https://www.conventionalcommits.org/en/v1.0.0/) with
auto-generated changelogs normalized timestamps.

- [`owc-release`](release.sh): A thin wrapper around [`cargo release`](https://github.com/crate-ci/cargo-release) for publishing Rust workspaces to
[crates.io](https://crates.io) with auto-generated changelogs and semantic versioning.

## Installing

These tools can be installed onto any UNIX system via the [`install-tools.sh`](../install-tools.sh) script. Tools will be installed to `/usr/local/bin`, and their default configurations will be installed into `/usr/local/etc/owc`.