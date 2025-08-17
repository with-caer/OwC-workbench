#!/bin/sh

# Default global configuration path for OWC scripts.
OWC_CONFIG_PATH=/usr/local/etc/owc

# Supported commit types.
declare -a COMMIT_TYPES=("feat" "docs" "fix" "ops")

# Load script metadata.
script_name=$0
script_dir=$( cd -- "$( dirname -- "$script_name}" )" &> /dev/null && pwd )

# Try loading configs from a common directory,
# falling back to the script directory if needed.
config_path=${script_dir}
if [ -e ${OWC_CONFIG_PATH}/git-cliff.toml ]; then
    config_path=${OWC_CONFIG_PATH}
fi

# Check arguments.
if [ "$#" -lt 2 ]; then
    printf "please provide a commit type and message. examples:\n"
    printf "  ${script_name} feat \"added a new feature\""
    printf "  ${script_name} docs \"edited some documentation\""
    printf "  ${script_name} fix \"fixed an issue\""
    printf "  ${script_name} ops \"improved the ci/cd pipeline\""
    exit 1
fi

# Extract arguments, merging all excess
# arguments into the commit message.
commit_type=$1
commit_message=$2
while shift && [ -n "$2" ]; do
    commit_message="${commit_message} $2"
done
commit_message="${commit_type}: ${commit_message}"

# Only allow supported commit types.
if [[ ! " ${COMMIT_TYPES[*]} " =~ [[:space:]]${commit_type}[[:space:]] ]]; then
    printf "${commit_type} is not one of: ${COMMIT_TYPES[*]}"
    exit 1
fi

# Normalize commit dates.
utc_day_begin=$(TZ=0 date +%F)T00:00:00+0000 

# Update changelogs for all crates.
ls */Cargo.toml | while read; do
    crate_path=${REPLY%/*}

    # Only udpate changelogs for crate paths affected by this commit.
    if [ ! -z "$(git status --porcelain ${crate_path})" ]; then
        cd ${crate_path}
        git cliff --with-commit "${commit_message}" --config ${config_path}/git-cliff.toml -o CHANGELOG.md
        cd ..
    fi
done | sort -u

# Stage all changes and show the staged changes to the user.
git add --all .

# Preview staged changes and commit message.
printf "\npreview of commit @ ${utc_day_begin}:\n"
git -c color.status=always status --short | grep '^\(\x1b\[[0-9]\{1,2\}m\)\{0,1\}[MARCD]'| sed -e 's/^/  /'
printf "  \n${commit_message}\n"

# Prompt for commit confirmation.
read -p "commit (y / N)? " -n 1 -r
printf ""

# Execute commit if yes.
if [[ $REPLY =~ ^[Yy]$ ]]
then
    GIT_AUTHOR_DATE=$utc_day_begin GIT_COMMITTER_DATE=$utc_day_begin git commit -m "${commit_message}"

# Abort commit if no.
else
    printf "commit aborted"
fi