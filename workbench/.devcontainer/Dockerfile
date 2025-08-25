FROM fedora:43

# Install common OS-level development packages.
RUN dnf install -y awk curl wget hostname \
                   gcc g++ cmake \
                   git \
                   openssl openssl-devel

# Install the base Rust toolchain.
RUN dnf install -y rustup
RUN rustup-init -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install the Rust WASM cross-compilation target.
RUN rustup target add wasm32-unknown-unknown

# Install `cargo-binstall` for installing pre-packaged cargo binaries.
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

# Install common Cargo binaries.
RUN cargo binstall --no-confirm cargo-audit \
                                cargo-server \
                                cargo-release \
                                git-cliff

# Install workbench customizations.
COPY assets/default-bashrc.sh /root/.bashrc
COPY tools/commit.sh /usr/local/bin/owc-commit
COPY tools/release.sh /usr/local/bin/owc-release
COPY tools/cargo-release.toml /usr/local/etc/owc/cargo-release.toml
COPY tools/git-cliff.toml /usr/local/etc/owc/git-cliff.toml