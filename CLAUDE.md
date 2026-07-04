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
- `skills/` — vendor-neutral [Agent Skills](https://agentskills.io) (open standard: `SKILL.md` folders, portable across Claude Code, Codex, Cursor, opencode, …). These are the canonical copies; `home-common.nix` symlinks each `skills/<name>` read-only into every consuming agent's discovery path. Today only Claude Code (`~/.claude/skills/<name>`); other tools are one extra symlink line. Add a directory plus a `home.file` line, then `rebuild`. Upstream skills are pulled instead from flake inputs (`agent-skills` = `anthropics/skills`, Apache-2.0; `mattpocock-skills` = `mattpocock/skills`, MIT — source of `grill-me` + `grilling`), pinned in `flake.lock` and symlinked from the Nix store — nothing is vendored, so nothing is redistributed; add one by symlinking another `skills/<name>` subdir of an input in `home-common.nix`.
- `windows/` — Windows host config (winget DSC + kanata + Google Japanese IME); applied with `winget configure`, not Nix
- `fonts/biz-udp/` — vendored, version-pinned BIZ UDPGothic TTFs (Japanese deck font) shared by both OSes; installed via `home-linux.nix` (Nix) and `windows/configuration.dsc.yaml` (DSC)

Roll back a bad macOS rebuild with `darwin-rebuild switch --rollback`.

## Claude-powered git aliases

`home-common.nix` defines git aliases that call `claude` to generate text:
`gcma` (commit message), `gpr` (draft PR title + body), `gswa` (branch name).
