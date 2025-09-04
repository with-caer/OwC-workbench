# Compatible with: Python3.12
import io
from textwrap import dedent

from pyinfra.operations import dnf, files, systemd, server

# @caer: todo: conditional execution
CONFIG_DNF=True
CONFIG_SSH=False
CONFIG_USER=True
USER_NAME="caer"

CONFIG_CODE_SERVER=False # Doesn't work end-to-end on Docker hosts
CODE_SERVER_VERSION="4.103.0"
CODE_SERVER_ARCH="arm64" # amd64, arm64, armhfp
CODE_SERVER_RPM=f"code-server-{CODE_SERVER_VERSION}-{CODE_SERVER_ARCH}.rpm"
CODE_SERVER_RPM_URL=f"https://github.com/coder/code-server/releases/download/v{CODE_SERVER_VERSION}/{CODE_SERVER_RPM}"
CLOUDFLARED_TOKEN=""

CONFIG_DEFAULT_PACKAGES=True

if CONFIG_DNF:
    # Configure DNF to download packages in parallel.
    files.line(
        name="configure DNF fastest mirror",
        path="/etc/dnf/dnf.conf",
        line="fastestmirror=True",
    )
    files.line(
        name="configure DNF parallel downloads",
        path="/etc/dnf/dnf.conf",
        line="max_parallel_downloads=10",
    )

    # Refresh packages.
    dnf.update()

if CONFIG_SSH:
    # Install SSH server and firewalls.
    dnf.packages(
        name="install SSH and Fail2Ban",
        packages=[
            "openssh-server",
            "fail2ban"
        ],
        update=True,
    )

    # Disallow password and root login via SSH.
    files.put(
        name="harden SSH",
        dest="/etc/ssh/sshd_config.d/0-workbench.conf",
        create_remote_dir=True,
        src=io.StringIO(dedent("""
        PasswordAuthentication no
        PermitRootLogin no
        PermitEmptyPasswords no
        """)),
    )

    # Enable and configure firewall.
    systemd.service(
        name="enable firewalld service",
        service="firewalld",
        running=True,
        restarted=True,
        enabled=True,
    )
    server.shell(
        name="configure firewalld",
        commands=[
            "firewall-cmd --permanent --zone=public --remove-service=ssh",
            "firewall-cmd --permanent --zone=trusted --add-service=ssh",
        ]
    )

    # Enable and configure fail2ban.
    systemd.service(
        name="enable fail2ban service",
        service="fail2ban",
        running=True,
        restarted=True,
        enabled=True,
    )
    files.put(
        name="configure fail2ban",
        dest="/etc/fail2ban/jail.local",
        create_remote_dir=True,
        content=io.StringIO(dedent("""
        [DEFAULT]
        bantime = 3600
        [sshd]
        enabled = true
        """)),
    )

if CONFIG_USER:
    # Create user and configure them as sudoer.
    server.user(
        name="create user",
        user=USER_NAME,
        ensure_home=True,
        create_home=True,
    )
    files.line(
        name="make user sudoer",
        path=f"/etc/sudoers.d/{USER_NAME}",
        line=f"{USER_NAME} ALL=(ALL) NOPASSWD:ALL",
    )

if CONFIG_CODE_SERVER:
    # Install code-server
    dnf.rpm(
        name="install code-server",
        src=CODE_SERVER_RPM_URL,
    )

    # Configure code-server systemd service.
    files.put(
        name="configure code-server service",
        dest="/etc/systemd/system/code-server.service",
        create_remote_dir=True,
        src=io.StringIO(dedent(f"""
        [Unit]
        Description=code-server
        After=multi-user.target

        [Service]
        User={USER_NAME}
        ExecStart=/usr/bin/code-server --disable-telemetry --disable-getting-started-override --auth none --bind-addr localhost:31545
        Type=simple
        Restart=on-failure

        [Install]
        WantedBy=multi-user.target
        """)),
    )

    # @caer: todo: these patches can likely be rewritten to not require
    #.       a separate shell script.
    # Patch code-server.
    dnf.packages(
        name="install code-server patch support packages",
        packages=[
            "jq",
            "perl",
            "tee",
        ],
        update=True,
    )
    files.sync(
        name="sync code-server patch assets",
        src="../assets",
        dest="/tmp/workbench/assets",
    )
    server.shell(
        name="apply code-server patch",
        commands=[
            "cd /tmp/workbench/assets && sh patch-code-server.sh",
        ]
    )

    # Enable code-server.
    systemd.service(
        name="enable code-server service",
        service="code-server.service",
        running=True,
        restarted=True,
        enabled=True,
    )

    # Install code-server default extensions.
    server.shell(
        name="install code-server extensions",
        commands=[
            "code-server --install-extension rust-lang.rust-analyzer",
            "code-server --install-extension tamasfe.even-better-toml",
            "code-server --install-extension beardedbear.beardedtheme",
        ],
        _sudo=True,
        _sudo_user=USER_NAME,
        _use_sudo_login=True,
    )

    # Expose code-server via a Cloudflare Tunnel.
    dnf.repo(
        name="add Cloudflared RPM repository",
        src="https://pkg.cloudflare.com/cloudflared-ascii.repo"
    )
    dnf.packages(
        name="install Cloudflared",
        packages=[
            "cloudflared",
        ],
    )
    server.shell(
        name="start cloudflared",
        commands=[
            f"cloudflared service install {CLOUDFLARED_TOKEN}"
        ],
    )

if CONFIG_DEFAULT_PACKAGES:
    dnf.packages(
        name="install recommended default OS packages",
        packages=[
            "awk", "curl", "wget", "hostname",
            "gcc", "g++", "cmake", "git",
            "openssl", "openssl-devel", "perl",
            "rustup",
        ],
        update=True,
    )

    files.line(
        name="add ~/.cargo/bin to user profile PATH",
        path=f"/home/{USER_NAME}/.profile",
        line='PATH="${HOME}/.cargo/bin:${PATH}"',
        _sudo=True,
        _sudo_user=USER_NAME,
        _use_sudo_login=True,
    )

    server.shell(
        name="install recommended default Rust packages",
        commands=[
            "rustup-init -y",
            "rustup toolchain install stable",
            "curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash",
            "cargo binstall --only-signed --no-confirm cargo-audit cargo-release git-cliff",
        ],
        _sudo=True,
        _sudo_user=USER_NAME,
        _use_sudo_login=True,
    )