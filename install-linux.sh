#!/usr/bin/env bash

set -euo pipefail

install_nix() {
    if command -v nix &>/dev/null; then
        echo "Nix is already installed"
        return 0
    fi

    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Ensure the Nix daemon is running (may not be started yet after fresh install)
    if ! sudo test -e /nix/var/nix/daemon-socket/socket 2>/dev/null; then
        echo "Starting Nix daemon..."
        if systemctl is-system-running &>/dev/null; then
            sudo systemctl start nix-daemon.service
        else
            sudo /nix/var/nix/profiles/default/bin/nix-daemon &
            # Wait for the daemon socket to appear
            for _ in $(seq 1 30); do
                if sudo test -e /nix/var/nix/daemon-socket/socket 2>/dev/null; then
                    break
                fi
                sleep 0.5
            done
        fi
    fi

    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
}

install_home_manager() {
    echo "Applying Home Manager configuration..."
    nix run home-manager -- switch -b backup --flake .#takuya-a
}

main() {
    echo "Starting dotfiles setup for Linux..."

    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "This setup script is only for Linux"
        exit 1
    fi

    install_nix

    if command -v nix &>/dev/null; then
        install_home_manager
    else
        echo "Nix not available. Please restart your terminal and run again."
        exit 1
    fi

    echo "Setup complete."
}

main "$@"
