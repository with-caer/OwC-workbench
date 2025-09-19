#!/bin/sh

# Default global configuration path for OWC scripts.
OWC_CONFIG_PATH=/usr/local/etc/owc
config_path=${OWC_CONFIG_PATH}
if [ ! -e ${config_path}/git-cliff.toml ]; then
    printf "${config_path}//git-cliff.toml is missing; please (re)install workbench tools\n"
    exit 1
fi

# Supported commit types.
declare -a COMMIT_TYPES=("feat" "docs" "fix" "ops")

# Load script metadata.
script_name=$0
script_dir=$( cd -- "$( dirname -- "$script_name}" )" &> /dev/null && pwd )

# Check arguments.
if [ "$#" -lt 2 ]; then
    printf "please provide a commit type and message. examples:\n\n"
    printf "  ${script_name} feat \"added a new feature\"\n"
    printf "  ${script_name} docs \"edited some documentation\"\n"
    printf "  ${script_name} fix \"fixed an issue\"\n"
    printf "  ${script_name} ops \"improved the ci/cd pipeline\"\n"
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

# Update root-level changelog.
git cliff --with-commit "${commit_message}" --config ${config_path}/git-cliff.toml -o CHANGELOG.md

# Update changelogs for all sub-crates in a Rust project.
ls */Cargo.toml | while read; do
    crate_path=${REPLY%/*}
    git cliff --include-path ${crate_path}/* --with-commit "${commit_message}" --config ${config_path}/git-cliff.toml -o ${crate_path}/CHANGELOG.md
done | sort -u

# Stage all changes and show the staged changes to the user.
git add --all .

# Cache color codes for terminal rendering.
GREEN=\\x01$(tput setaf 2)\\x02
MAGENTA=\\x01$(tput setaf 198)\\x02
PURPLE=\\x01$(tput setaf 5)\\x02
BOLD=\\x01$(tput bold)\\x02
NORMAL=\\x01$(tput sgr0)\\x02
YELLOW=\\x01$(tput setaf 3)\\x02

# Preview staged changes and commit message.
printf "\n${YELLOW}preview of commit @ ${utc_day_begin}:${NORMAL}\n\n"
git diff --name-status --cached | while read -r line; do

    # See: https://git-scm.com/docs/git-status#_short_format
    if [[ $line == M* ]]; then # Modified
        printf "  ${GREEN}${line}${NORMAL}\n"
    elif [[ $line == T* ]]; then # File Type Changed
        printf "  ${PURPLE}${line}${NORMAL}\n"
    elif [[ $line == A* ]]; then # Addded
        printf "  ${GREEN}${line}${NORMAL}\n"
    elif [[ $line == D* ]]; then # Deleted
        printf "  ${MAGENTA}${line}${NORMAL}\n"
    elif [[ $line == R* ]]; then # Renamed
        printf "  ${PURPLE}${line}${NORMAL}\n"
    elif [[ $line == C* ]]; then # Copied
        printf "  ${PURPLE}${line}${NORMAL}\n"
    elif [[ $line == U* ]]; then # Updated but unmerged
        printf "  ${PURPLE}${line}${NORMAL}\n"
    else # Unrecognized
        printf "  ${BOLD}${commit_message}${NORMAL}\n"
    fi
done

printf "  \n${YELLOW}${commit_message}${NORMAL}\n\n"

# Prompt for commit confirmation.
read -p "commit (y / N)? " -n 1 -r
printf "\n"

# Execute commit if yes.
if [[ $REPLY =~ ^[Yy]$ ]]
then
    GIT_AUTHOR_DATE=$utc_day_begin GIT_COMMITTER_DATE=$utc_day_begin git commit -m "${commit_message}"

# Abort commit if no.
else
    printf "commit aborted"
fi