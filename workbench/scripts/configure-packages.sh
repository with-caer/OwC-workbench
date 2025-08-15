#!/bin/sh

# Exit on first error.
set -e

# Configure DNF to find the fastest mirror
# and download packages in parallel; without
# these options, some hosts will timeout their
# package installations.
echo fastestmirror=True >> /etc/dnf/dnf.conf
echo max_parallel_downloads=10 >> /etc/dnf/dnf.conf

# Refresh repositories and packages.
dnf upgrade -y --refresh
