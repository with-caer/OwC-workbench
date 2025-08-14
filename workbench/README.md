## What's Here

0. `install-system.sh`: Performs the first-time setup for a fresh
Fedora or Rocky Linux installation. This script assumes it is run
as the `root` user.

1. `install-user.sh`: Performs the first-time setup for the primary
user account _after_ `install-system.sh` is run. This script assumes
it is run as the primary non-`root` user, and will result in the host
system being exposed to the public internet.