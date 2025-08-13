#!/bin/sh

# Exit on first error.
set -e

# Enter terraform build context.
cd terraform

# Run initialization and linting.
terraform init
terraform validate
terraform fmt

# Run deployment.
terraform apply