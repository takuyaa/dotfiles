# CLAUDE.md

Personal dotfiles managed with Nix flakes, nix-darwin, and Home Manager.
Declarative, reproducible config for macOS (Apple Silicon) and Linux.

## Commands

- `rebuild` — apply configuration changes (delegates to the Makefile)
- `update` — update flake inputs, then rebuild
- `nix flake check` — validate the configuration

## Layout

- `flake.nix` — inputs and outputs (macOS + Linux)
- `darwin.nix` — macOS system settings and Homebrew
- `home-common.nix` — packages, dotfiles, and shell config shared by all hosts
- `home-darwin.nix` / `home-linux.nix` — OS-specific overrides

Roll back a bad macOS rebuild with `darwin-rebuild switch --rollback`.

## Claude-powered git aliases

`home-common.nix` defines git aliases that call `claude` to generate text:
`gcma` (commit message), `gpr` (draft PR title + body), `gswa` (branch name).
