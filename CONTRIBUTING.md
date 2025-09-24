# Contributing With Caer: A Guide

This doc is a general guide on how to contribute to _any_ project owned
or sponsored by With Caer.

## Certificate of Contributor's Ownership

Although annoying, every pull request must contain
[this boilerplate](.github/PULL_REQUEST_TEMPLATE.md#certificate-of-contributors-ownership)
before it can be merged.

## Contributing Code

With a few exceptions, almost every project is built with [Rust](https://www.rust-lang.org)
and organized as a [Cargo Workspace](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html).

### Before Committing Changes

...run:

1. `cargo fmt` to format all code changes.
2. `cargo clippy` to statically analyze all code changes.
3. `cargo test` to test all code changes.

### When Committing Changes

...use `owc-commit` instead of `git commit`. This script is automatically installed
by all our projects' Dev Containers, and can be locally/manually installed by cloning _this_
repository and running [`install-tools.sh`](install-tools.sh).