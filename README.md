# dotfiles

Personal development environment configuration using Nix flakes, nix-darwin, and Home Manager.

## Supported Platforms

| Platform | Host | User | Tool |
|----------|------|------|------|
| macOS (aarch64-darwin) | — | `takuya.asano` | nix-darwin + Home Manager |
| Linux (x86_64-linux) | dev-01 (Ubuntu 24.04) | `takuya-a` | Home Manager (standalone) |

## Quick Start

### macOS

#### Prerequisites

- Xcode Command Line Tools: `xcode-select --install`

#### Installation

```bash
git clone https://github.com/takuyaa/dotfiles.git
cd dotfiles
./install.sh
```

This will install Nix (via Determinate Systems installer), nix-darwin, and apply the initial configuration.

### Linux (dev-01)

#### Prerequisites

- [Nix package manager](https://nixos.org/download/)

#### Bootstrap

```bash
git clone https://github.com/takuyaa/dotfiles.git ~/ghq/github.com/takuyaa/dotfiles
cd ~/ghq/github.com/takuyaa/dotfiles
nix run home-manager -- switch -b backup --flake .#takuya-a
```

#### Post-Bootstrap

Authenticate with GitHub:

```bash
gh auth login
```

Generate a GPG signing key and register it on [GitHub](https://github.com/settings/gpg/new):

```bash
gpg --full-generate-key          # Choose ECC (option 9)
gpg --list-secret-keys --keyid-format=long  # Note the key ID
gpg --armor --export <KEY_ID>    # Copy to GitHub
```

Then update `home-linux.nix` with the new key ID and `rebuild`.

## Daily Usage

Apply configuration changes:

```bash
make rebuild
```

Update all dependencies and rebuild:

```bash
make update
```

Or use the `rebuild` / `flake-update` shell aliases directly.

## File Structure

```text
.
├── flake.nix         # Entry point: darwinConfigurations + homeConfigurations
├── flake.lock        # Pinned dependencies
├── darwin.nix        # macOS system settings and Homebrew
├── home-common.nix   # Shared user config (packages, bash, git, tmux, etc.)
├── home-darwin.nix   # macOS-specific config (imports home-common.nix)
├── home-linux.nix    # Linux-specific config (imports home-common.nix)
├── Makefile          # Platform-aware rebuild/update targets
├── install.sh        # macOS bootstrap script
├── LICENSE.txt       # License file
└── README.md         # This file
```

## Maintenance

### Check configuration

```bash
nix flake check
```

### View generations (macOS)

```bash
darwin-rebuild list-generations
```

### Rollback (macOS)

```bash
darwin-rebuild switch --rollback
```

### Rollback (Linux)

```bash
home-manager generations   # list generations
# activate a previous generation by running its activate script
```

## License

[MIT](./LICENSE.txt)
