#!/bin/sh
set -e

if [ ! -f /etc/redhat-release ]; then
    echo "this feature is designed for Fedora and Rocky Workbenches"
    exit 1
fi

# Download the DuckDB C/C++ native libraries.
wget https://github.com/duckdb/duckdb/releases/download/v${VERSION}/libduckdb-linux-amd64.zip -O libduckdb.zip

# Prepare output path for the native libraries.
mkdir -p /usr/local/etc/owc/features/duckdb

# Extract the native libraries to the path.
dnf install -y unzip
unzip libduckdb.zip -d /usr/local/etc/owc/features/duckdb

# Add extracted libraries to the path.
cat >> ~/.profile << EOF
DUCKDB_LIB_DIR=/usr/local/etc/owc/features/duckdb
DUCKDB_INCLUDE_DIR=/usr/local/etc/owc/features/duckdb
EOF