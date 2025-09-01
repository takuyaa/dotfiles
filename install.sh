#!/usr/bin/env bash

set -euo pipefail

install_nix() {
    if command -v nix &>/dev/null; then
        echo "Nix is already installed"
        return 0
    fi

    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
}

install_nix_darwin() {
    if command -v darwin-rebuild &>/dev/null; then
        echo "nix-darwin is already installed"
        return 0
    fi

    echo "Installing nix-darwin..."
    # sudo nix --extra-experimental-features 'flakes nix-command' run nix-darwin -- switch --flake .#macos
    sudo nix --extra-experimental-features 'flakes nix-command' run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch --flake .#macos
}

main() {
    echo "Starting dotfiles setup for macOS..."
    
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "This setup script is only for macOS"
        exit 1
    fi

    install_nix

    if command -v nix &>/dev/null; then
        echo "Setting up macOS configuration..."
        install_nix_darwin
    else
        echo "Nix not available. Please restart your terminal and run again."
        exit 1
    fi

    echo "Setup complete."
}

main "$@"
