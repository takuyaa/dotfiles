{ config, pkgs, lib, username, userHome, ... }:
{
  imports = [ ./home-common.nix ];

  # macOS-specific packages
  home.packages = with pkgs; [
    terminal-notifier
    iproute2mac
    cocoapods
  ];

  # rebuild/update aliases (delegate to Makefile so the source of truth is one place)
  programs.bash.shellAliases.rebuild = "make -C ~/ghq/github.com/takuyaa/dotfiles rebuild";
  programs.bash.shellAliases.update = "make -C ~/ghq/github.com/takuyaa/dotfiles update";

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
      # attach to the most-recent existing session regardless of name,
      # else create "main" (new-session -A only matches the exact name "main")
      command = "bash -l -c 'tmux attach || tmux new-session -s main'";
      confirm-close-surface = false;
    };
  };

  # SSH: use macOS Keychain for passphrase storage
  programs.ssh.settings."*".UseKeychain = "yes";

  # Claude statusline script
  home.file.".claude/statusline-command.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      input=$(cat)

      # Directory: shorten $HOME to ~
      cwd=$(echo "$input" | jq -r '.workspace.current_dir')
      short_dir="''${cwd/#$HOME/~}"

      # Git branch (skip optional locks)
      branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

      # Model display name
      model=$(echo "$input" | jq -r '.model.display_name')

      # Context usage
      used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

      # Build status line
      parts="$short_dir"
      [ -n "$branch" ] && parts="$parts  $branch"
      parts="$parts  $model"
      [ -n "$used" ] && parts="$parts  ctx:''${used}%"

      printf "%s" "$parts"
    '';
  };

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
