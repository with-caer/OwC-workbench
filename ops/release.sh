#!/bin/sh

# Default global configuration path for OWC scripts.
OWC_CONFIG_PATH=/usr/local/etc/owc

# Supported release types.
#
# This script will fail if any of the released crates
# do not contain a preexisting CHANGELOG.md.
declare -a RELEASE_TYPES=("patch" "minor" "major")

# Load script metadata.
script_name=$0
script_dir=$( cd -- "$( dirname -- "$script_name}" )" &> /dev/null && pwd )

# Try loading configs from a common directory,
# falling back to the script directory if needed.
config_path=${script_dir}
if [ -e ${OWC_CONFIG_PATH}/cargo-release.toml ]; then
    config_path=${OWC_CONFIG_PATH}
fi

# Check arguments.
if [ "$#" -lt 1 ]; then
    printf "please provide a release type. examples:\n"
    printf "  ${script_name} patch\n"
    printf "  ${script_name} minor\n"
    printf "  ${script_name} major\n"
    exit 1
fi

# Extract arguments.
release_type=$1

# Only allow supported release types.
if [[ ! " ${RELEASE_TYPES[*]} " =~ [[:space:]]${release_type}[[:space:]] ]]; then
    printf "${release_type} is not one of: ${RELEASE_TYPES[*]}\n"
    exit 1
fi

# Only allow releases on a clean working directory.
if [ ! -z "$(git status --porcelain)" ]; then
    printf "aborting release: uncommited changes present in repository\n"
    exit 1
fi

# Verify workspace.
cargo fmt --check
cargo clippy
cargo test

# Dry-run release.
printf "beginning release dry-run...\n"
cargo release $release_type --config ${config_path}/cargo-release.toml
printf "cleaning up dry-run changes...\n"
git stash

# Prompt for commit confirmation.
read -p "execute release (y / N)? " -n 1 -r
printf "\n"

# Execute release if yes.
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Normalize release dates.
    utc_day_begin=$(TZ=0 date +%F)T00:00:00+0000
    GIT_AUTHOR_DATE=$utc_day_begin GIT_COMMITTER_DATE=$utc_day_begin cargo release $releaseType --config ${config_path}/cargo-release.toml --execute
# Abort commit if no.
else
    printf "release aborted\n"
fi