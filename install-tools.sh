#!/bin/sh

# Exit on first error.
set -e

# Check user.
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "please run this script as root, or with sudo"
    exit 1
fi

# Load script metadata.
script_dir=$( cd -- "$( dirname -- "$0}" )" &> /dev/null && pwd )

# Install executables.
cp ${script_dir}/tools/commit.sh /usr/local/bin/owc-commit
cp ${script_dir}/tools/release.sh /usr/local/bin/owc-release

# Install configurations.
mkdir -p /usr/local/etc/owc/
cp ${script_dir}/tools/cargo-release.toml /usr/local/etc/owc/cargo-release.toml
cp ${script_dir}/tools/git-cliff.toml /usr/local/etc/owc/git-cliff.toml