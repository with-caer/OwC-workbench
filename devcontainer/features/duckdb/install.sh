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

# Link libraries onto the global library path.
ln -s /usr/local/etc/owc/features/libduckdb/libduckdb.so /usr/local/lib/libduckdb.so
ln -s /usr/local/etc/owc/features/libduckdb/duckdb.h /usr/local/include/duckdb.h
ln -s /usr/local/etc/owc/features/libduckdb/duckdb.hpp /usr/local/include/duckdb.hpp

# Add extracted libraries to the system profile.
cat >> /etc/profile.d/owc-workbench-duckdb.sh << 'EOF'
export DUCKDB_LIB_DIR=/usr/local/etc/owc/features/duckdb
export DUCKDB_INCLUDE_DIR=/usr/local/etc/owc/features/duckdb
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/etc/owc/features/duckdb
EOF