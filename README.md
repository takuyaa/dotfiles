# dotfiles

Personal development environment configuration using Nix flakes, nix-darwin, and Home Manager.

## Supported Platforms

| Platform | Host | User | Tool |
|----------|------|------|------|
| macOS (aarch64-darwin) | — | `takuya.asano`, `takuya` | nix-darwin + Home Manager |
| Linux (x86_64-linux) | dev-01 (Ubuntu 24.04) | `takuya-a` | Home Manager (standalone) |
| Windows (x86_64)       | this laptop           | `takuy`        | winget configure (`windows/`, not Nix) |

## Quick Start

### macOS

#### Prerequisites

- Xcode Command Line Tools: `xcode-select --install`

#### Installation

```bash
git clone https://github.com/takuyaa/dotfiles.git
cd dotfiles
./install-darwin.sh
```

This will install Nix (via Determinate Systems installer), nix-darwin, and apply the initial configuration.

The script (and `make rebuild`) picks the `darwinConfigurations` entry matching the
logged-in account, via `id -un | tr . -`. To onboard another Mac account, add it to
`darwinHosts` in `flake.nix` with its login name and uid (`id -u <name>`).

### Linux (dev-01)

#### Installation

```bash
git clone https://github.com/takuyaa/dotfiles.git ~/ghq/github.com/takuyaa/dotfiles
cd ~/ghq/github.com/takuyaa/dotfiles
./install-linux.sh
```

This will install Nix (via Determinate Systems installer) and apply the Home Manager configuration.

#### Post-Bootstrap

Authenticate with GitHub:

```bash
gh auth login
```

Commits are signed with your SSH key (`~/.ssh/id_ed25519`). Register the
**public** key as a *Signing Key* on
[GitHub](https://github.com/settings/ssh/new) (key type: "Signing Key"):

```bash
cat ~/.ssh/id_ed25519.pub    # Copy to GitHub
```

If the key does not exist yet, generate it first:

```bash
ssh-keygen -t ed25519 -C "takuya.a@gmail.com"
```

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

## Japanese slides → PDF pipeline

日本語スライド（ppt-master 等で生成した `.pptx`）を、他人の環境でも字形が崩れない
PDF として配布するためのフォント整備と変換ツール。

- **デッキ主フォント `BIZ UDPGothic`**（SIL OFL, 埋め込み可）を `fonts/biz-udp/` に
  バージョン固定で vendor し、両 OS へ同一実体を配る。フォールバックは `Noto Sans CJK JP`。
  - **Linux/WSL2**: `home-linux.nix` が Nix パッケージとして導入（`rebuild` で反映）。
    Nix の fontconfig（LibreOffice が使う）はプロファイルの `share/fonts` しか見ないため、
    `~/.local/share/fonts` ではなくパッケージで配る。詳細は [`fonts/biz-udp/README.md`](fonts/biz-udp/README.md)。
  - **Windows**: `windows/configuration.dsc.yaml` の `fonts-biz-udp` が per-user 登録。
- **`pptx2pdf [-o OUTDIR] deck.pptx …`**（Linux/WSL2、`home-linux.nix` 定義）:
  LibreOffice headless で PDF 化し、`pdffonts` で全フォントの埋め込みを検証する。
  `BIZ UDPGothic` が無ければ即 fail（サイレント置換を防ぐ）。

```bash
pptx2pdf slides/deck.pptx     # → slides/deck.pdf（全フォント emb=yes を検証）
```

## Karabiner-Elements (macOS): manual setup

Karabiner rewrites `~/.config/karabiner/karabiner.json` itself, so that file cannot be a
read-only Nix symlink. Everything below is GUI state that has to be redone by hand on a
new machine. Nix only places the rule file under `assets/`, which Karabiner just reads.

| # | Where | What | Why |
|---|-------|------|-----|
| 1 | System Settings → Privacy & Security | Grant Input Monitoring, approve the DriverKit extension | Karabiner cannot grab any device without it |
| 2 | Settings → Complex Modifications | Enable "IME switch (dotfiles)" | Command taps → 英数/かな. Enabling **copies** the rule body into `karabiner.json`; re-add it after editing `ime/karabiner-ime-switch.json` |
| 3 | Settings → Devices | Tick "Modify events" on the Keychron Q11 row that lists as a mouse | QMK routes NKRO key reports through a shared endpoint whose primary usage is Mouse; Karabiner ignores pointing devices by default, so those keys never reach a manipulator |
| 4 | Settings → Devices | Tick "Modify events" + "Flip vertical wheel" on the Logitech `USB Receiver` | Reverses the wheel on the external mouse only. macOS has a single `com.apple.swipescrolldirection` shared by trackpad and mouse, so the OS setting would flip the trackpad too |

Steps 3 and 4 produce these entries, which are worth diffing against when something stops
working (`is_keyboard` **and** `is_pointing_device` both true is the mark of a QMK shared
endpoint; `13364`/`480` = Keychron Q11, `1133`/`50489` = Logitech Lightspeed receiver):

```json
{ "identifiers": { "is_keyboard": true, "is_pointing_device": true,
                   "product_id": 480, "vendor_id": 13364 },
  "ignore": false }
{ "identifiers": { "is_pointing_device": true, "product_id": 50489, "vendor_id": 1133 },
  "ignore": false, "mouse_flip_vertical_wheel": true }
```

Steps 2 and 3 are covered in detail, with the symptoms and the commands to diagnose them,
in [`ime/README.md`](./ime/README.md).

## File Structure

```text
.
├── flake.nix         # Entry point: darwinConfigurations + homeConfigurations
├── flake.lock        # Pinned dependencies
├── darwin.nix        # macOS system settings and Homebrew
├── home-common.nix   # Shared user config (packages, bash, git, tmux, etc.)
├── home-darwin.nix   # macOS-specific config (imports home-common.nix)
├── home-linux.nix    # Linux-specific config (imports home-common.nix)
├── skills/           # Own Agent Skills (agentskills.io); symlinked into ~/.claude/skills/ via home-common.nix (upstream skills come from the agent-skills flake input)
├── windows/          # Windows host config (winget DSC + kanata + Google IME); `winget configure`, not Nix
├── ime/              # Google Japanese IME keymap shared by macOS + Windows, plus the macOS Karabiner IME-switch rule
├── fonts/biz-udp/    # Vendored, version-pinned BIZ UDPGothic TTFs (Japanese deck font) for WSL2 + Windows
├── Makefile          # Platform-aware rebuild/update targets
├── install-darwin.sh  # macOS bootstrap script
├── install-linux.sh  # Linux bootstrap script
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
