#!/bin/sh

# Exit on first error.
set -e

# Enter packer build context.
cd packer

# Run initialization and linting.
/usr/bin/packer init .
/usr/bin/packer validate .
/usr/bin/packer fmt .

# Run build.
/usr/bin/packer build .