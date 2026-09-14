# Linux Bootstrap System Design Guide

> original version written by ChatGPT-4

This document outlines practical patterns and mindset recommendations
for building a maintainable Linux bootstrap system. The goal is to make
machine provisioning repeatable, understandable, and safe to re-run.

------------------------------------------------------------------------

# Core Principles

1.  **Idempotent Tasks**
    -   Running the bootstrap script multiple times should not break
        anything.
    -   Scripts should check current system state before making changes.
2.  **Small Focused Modules**
    -   Avoid large monolithic scripts.
    -   Each script should perform one category of work.
3.  **Predictable Execution**
    -   Scripts should run in a known order so outcomes are
        deterministic.

------------------------------------------------------------------------

# Recommended Project Layout

    bootstrap/
    │
    ├── bootstrap.sh          # main entrypoint
    ├── lib/
    │   ├── logging.sh
    │   ├── checks.sh
    │   └── helpers.sh
    │
    ├── modules/
    │   ├── 00_system.sh
    │   ├── 10_network.sh
    │   ├── 20_packages.sh
    │   ├── 30_security.sh
    │   └── 40_devtools.sh
    │
    └── config/
        └── settings.env

------------------------------------------------------------------------

# 1. Entry Point (Controller)

The controller script orchestrates execution of modules.

``` bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/lib/logging.sh"
source "$ROOT_DIR/config/settings.env"

log "Starting bootstrap..."

for module in "$ROOT_DIR/modules/"*.sh; do
    log "Running module: $(basename "$module")"
    bash "$module"
done

log "Bootstrap complete."
```

Benefits: - Predictable execution order - Easy to disable or add
modules - Clear orchestration layer

------------------------------------------------------------------------

# 2. Modules (Single Responsibility)

Each module should handle one category of system configuration.

Example:

``` bash
#!/usr/bin/env bash
set -e

CONF="/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"

sudo mkdir -p /etc/NetworkManager/conf.d

if [ -f "$CONF" ]; then
    sudo sed -i 's/wifi\.powersave *= *[0-9]/wifi.powersave = 2/' "$CONF"
else
    sudo tee "$CONF" > /dev/null <<EOF
[connection]
wifi.powersave = 2
EOF
fi

sudo systemctl restart NetworkManager
```

Guideline: A module should be understandable in roughly **30 seconds**.

------------------------------------------------------------------------

# 3. Configuration Layer

Separate configuration from code.

Example:

`config/settings.env`

    USERNAME=dev
    INSTALL_DOCKER=true
    INSTALL_NODE=true
    ENABLE_UFW=true

Modules can then reference environment variables.

    if [ "$INSTALL_DOCKER" = true ]; then
        install_docker
    fi

------------------------------------------------------------------------

# 4. Logging Helpers

Centralized logging makes debugging easier.

Example:

``` bash
log() {
    echo "[BOOTSTRAP] $1"
}

warn() {
    echo "[WARNING] $1"
}

fail() {
    echo "[ERROR] $1"
    exit 1
}
```

------------------------------------------------------------------------

# 5. Environment Checks

Fail early when prerequisites are not satisfied.

Example:

``` bash
require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Run as root"
        exit 1
    fi
}
```

------------------------------------------------------------------------

# 6. Idempotency Patterns

Bootstrap scripts should always check system state first.

### Package Installation

    dpkg -s package >/dev/null 2>&1 || sudo apt install -y package

### File Configuration

    if ! grep -q "setting" file; then
        echo "setting" >> file
    fi

### Service Enablement

    systemctl is-enabled service || systemctl enable service

------------------------------------------------------------------------

# 7. Optional Parallel Execution

Modules that do not depend on each other can run in parallel.

Example:

``` bash
bash modules/10_network.sh &
bash modules/20_packages.sh &
wait
```

This can significantly reduce provisioning time.

------------------------------------------------------------------------

# 8. State Tracking (Incremental Bootstrap)

A state directory allows modules to skip work that has already
completed.

Example location:

    /var/lib/bootstrap/state/

Example pattern:

``` bash
STATE="/var/lib/bootstrap/state/network_done"

if [ -f "$STATE" ]; then
    exit 0
fi

# perform work

sudo mkdir -p /var/lib/bootstrap/state
sudo touch "$STATE"
```

This allows the bootstrap process to become incremental and safe to
re-run.

------------------------------------------------------------------------

# 9. Profiles (Advanced Feature)

Profiles allow subsets of modules to run depending on machine purpose.

Examples:

    bootstrap install laptop
    bootstrap install server
    bootstrap install dev

Each profile simply maps to a collection of modules.

This enables a single bootstrap system to support multiple machine
roles.

------------------------------------------------------------------------

# Summary

A good bootstrap system should be:

-   Modular
-   Idempotent
-   Deterministic
-   Easy to extend
-   Easy to debug

The Bash module approach provides a strong balance between simplicity,
portability, and control while avoiding heavy configuration management
dependencies.
