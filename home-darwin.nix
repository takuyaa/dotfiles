{ config, pkgs, lib, username, userHome, ... }:
{
  imports = [ ./home-common.nix ];

  # macOS-specific packages
  home.packages = with pkgs; [
    terminal-notifier
    iproute2mac
    cocoapods
  ];

  # rebuild alias (macOS uses darwin-rebuild)
  programs.bash.shellAliases.rebuild = "sudo darwin-rebuild switch --flake .#macos";

  # macOS-specific profileExtra (appended after common profileExtra)
  programs.bash.profileExtra = lib.mkAfter ''
    # Silence macOS bash deprecation warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # Add per-user profile to PATH for home-manager packages
    if [ -d "/etc/profiles/per-user/$USER/bin" ]; then
      export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
    fi

    # Add Homebrew (Apple Silicon) to PATH
    if [ -d "/opt/homebrew/bin" ]; then
      export PATH="/opt/homebrew/bin:$PATH"
    fi

    # Android SDK
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/emulator
    export PATH=$PATH:$ANDROID_HOME/platform-tools
  '';

  # Ghostty (installed via Homebrew cask, config only)
  programs.ghostty = {
    enable = true;
    package = null;
    enableBashIntegration = true;
    settings = {
      font-family = "PlemolJP Console NF";
      font-size = 14;
      theme = "Catppuccin Mocha";
      cursor-style = "bar";
      cursor-style-blink = false;
      window-padding-x = 8;
      window-padding-y = 8;
      window-padding-balance = true;
      window-decoration = false;
      macos-titlebar-style = "hidden";
      macos-option-as-alt = true;
      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";
      command = "bash -l -c 'tmux new-session -A -s main'";
      confirm-close-surface = false;
    };
  };

  # gpg-agent pinentry (macOS)
  services.gpg-agent.pinentry.package = pkgs.pinentry_mac;

  # Claude CLAUDE.md (macOS version: rebuild = darwin-rebuild)
  home.file.".claude/CLAUDE.md".text = ''
    # Global Claude Code Settings

    ~/.claude/settings.json and ~/.claude/notify.sh are managed by Nix (Home Manager).
    They are read-only symlinks and must not be edited directly.

    To change settings:
    1. Edit ~/ghq/github.com/takuyaa/dotfiles/home-common.nix (or home-darwin.nix for macOS-specific)
    2. Run `rebuild`

    Private instructions should be placed in ~/.claude/CLAUDE.local.md (gitignored).
  '';

  # Claude notify.sh (terminal-notifier version for macOS)
  home.file.".claude/notify.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      input=$(cat)
      cwd=$(echo "$input" | jq -r '.cwd')
      project=$(basename "$cwd")
      type=$(echo "$input" | jq -r '.notification_type')

      case "$type" in
        permission_prompt) msg="Waiting for permission"; sound="Ping" ;;
        idle_prompt)       msg="Waiting for input";      sound="Purr" ;;
        stop)              msg="Task completed";         sound="Glass" ;;
        *)                 msg="Notification";           sound="default" ;;
      esac

      args=(-title "Claude Code" -subtitle "$project" -message "$msg" -sound "$sound")
      [[ -n "$__CFBundleIdentifier" ]] && args+=(-activate "$__CFBundleIdentifier")

      terminal-notifier "''${args[@]}"
    '';
  };
}
