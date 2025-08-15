#!/bin/sh

# Exit on first error.
set -e

USER_NAME=$1

# TODO: This step may not be necessary on desktop installations,
#       since they often make the default user a sudoer on install.
# Make user sudoer.
# echo "${USER_NAME} ALL=(ALL:ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/${USER_NAME}

# Disable the sudoer password requirement.
touch /etc/sudoers.d/$USER_NAME
echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/${USER_NAME}
chmod 0440 /etc/sudoers.d/${USER_NAME}