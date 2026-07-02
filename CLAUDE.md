# CLAUDE.md

Personal dotfiles managed with Nix flakes, nix-darwin, and Home Manager.
Declarative, reproducible config for macOS (Apple Silicon), Linux, and Windows.

## Commands

- `rebuild` — apply configuration changes (delegates to the Makefile)
- `update` — update flake inputs, then rebuild
- `nix flake check` — validate the configuration
- `pptx2pdf [-o OUTDIR] deck.pptx …` (Linux/WSL2) — convert a slide deck to PDF with
  LibreOffice headless and verify every font is embedded; refuses to run if the deck
  font `BIZ UDPGothic` is missing, to prevent silent glyph substitution

## Layout

- `flake.nix` — inputs and outputs (macOS + Linux)
- `darwin.nix` — macOS system settings and Homebrew
- `home-common.nix` — packages, dotfiles, and shell config shared by all hosts
- `home-darwin.nix` / `home-linux.nix` — OS-specific overrides
- `windows/` — Windows host config (winget DSC + kanata + Google Japanese IME); applied with `winget configure`, not Nix
- `fonts/biz-udp/` — vendored, version-pinned BIZ UDPGothic TTFs (Japanese deck font) shared by both OSes; installed via `home-linux.nix` (Nix) and `windows/configuration.dsc.yaml` (DSC)

Roll back a bad macOS rebuild with `darwin-rebuild switch --rollback`.

## Claude-powered git aliases

`home-common.nix` defines git aliases that call `claude` to generate text:
`gcma` (commit message), `gpr` (draft PR title + body), `gswa` (branch name).
