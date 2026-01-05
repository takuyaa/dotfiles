# dotfiles

Personal development environment configuration using Nix flakes, nix-darwin, and Home Manager for macOS.

## Quick Start

### Prerequisites

- macOS
- Xcode Command Line Tools: `xcode-select --install`
- Git access to clone this repository

### Installation

Clone the repository:

```bash
git clone https://github.com/takuyaa/dotfiles.git
cd dotfiles
```

Run the installation script:

```bash
./install.sh
```

This will:

- Install Nix package manager (via Determinate Systems installer)
- Install nix-darwin for macOS system management
- Apply the initial configuration

### Post-Installation

After installation, use the `rebuild` alias to apply configuration changes:

```bash
rebuild
```

Or use the full command:

```bash
darwin-rebuild switch --flake .#macos
```

## File Structure

```text
.
├── darwin.nix      # macOS system settings and Homebrew
├── flake.lock      # Pinned dependencies
├── flake.nix       # Main configuration entry point
├── home.nix        # User packages and dotfiles
├── install.sh      # Bootstrap script
├── LICENSE.txt     # License file
└── README.md       # This file
```

## Maintenance

### Update all dependencies

```bash
flake-update
rebuild
```

### Check configuration

```bash
nix flake check
```

### View generations

```bash
darwin-rebuild list-generations
```

### Rollback if needed

```bash
darwin-rebuild switch --rollback
```

## License

[MIT](./LICENSE.txt)
