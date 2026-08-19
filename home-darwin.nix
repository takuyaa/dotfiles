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
      # Open a plain login shell (no auto tmux). Connect to dev on demand with the
      # `etdev` command, which is where tmux lives now (single tmux, on dev).
      confirm-close-surface = false;
    };
  };

  # SSH: use macOS Keychain for passphrase storage
  programs.ssh.settings."*".UseKeychain = "yes";

  # SSH: serve keys from 1Password's agent instead of on-disk private keys.
  # The socket path has spaces, so the quotes are part of the ssh_config value.
  # Enabling the agent itself is a 1Password app setting (Settings → Developer
  # → Use the SSH agent) and cannot be declared here.
  programs.ssh.settings."*".IdentityAgent =
    ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';

  # Git commit signing through 1Password. There is no private key on disk here,
  # so the signing key has to be the public key literal (git then passes -U and
  # lets the agent hold the private half) rather than the path home-common.nix
  # uses on Linux.
  programs.git.signing = {
    key = lib.mkForce "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUUYK9l21+ujAg7PUQ//XNSVeN9xJ255HkBIyfWkBw4";
    signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };

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
  # Karabiner-Elements: IME switch rule (US layout thumb keys).
  # Karabiner rewrites ~/.config/karabiner/karabiner.json itself, so that file
  # cannot be a read-only Nix symlink. Instead the rule is dropped into the
  # assets directory, which Karabiner only *reads*; enable it once in the GUI
  # (Settings -> Complex Modifications -> Add rule). Re-enable after editing.
  home.file.".config/karabiner/assets/complex_modifications/ime-switch.json".source =
    ./ime/karabiner-ime-switch.json;

  # Disable the two OS input-source switching shortcuts so the IME owns switching:
  #   60 = ^Space   "Select the previous input source"
  #   61 = ^~Space  "Select next source in Input menu"
  # `ABC` cannot be removed from the input sources (macOS keeps one ASCII-capable
  # source and Google IME's ひらがな mode is smJapanese), so these shortcuts are the
  # only way to land on ABC by accident. ^Space also collides with Emacs set-mark.
  # Mirrors the ime-*-hotkeys entries in windows/configuration.dsc.yaml.
  #
  # Deliberately NOT system.defaults.CustomUserPreferences: nix-darwin emits one
  # `defaults write <domain> <key> <value>` per key, which would replace the whole
  # AppleSymbolicHotKeys dictionary and drop the ~17 other entries macOS keeps there
  # (13 of them are stored as enabled=false). `-dict-add` merges a single entry.
  # The parameters are (ASCII, key code, modifier mask): 32/49 = Space,
  # 262144 = ^, 786432 = ^~ — i.e. the stock shortcuts, kept but disabled.
  #
  # The value has to be XML, not the old-style `{ enabled = 0; ... }` literal: that
  # syntax has no number/bool type, so everything lands as a string and macOS —
  # which stores these as real bool/int — does not honour it.
  home.activation.disableInputSourceHotkeys =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      hotkey_off() {
        run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
          -dict-add "$1" "
            <dict>
              <key>enabled</key><false/>
              <key>value</key>
              <dict>
                <key>type</key><string>standard</string>
                <key>parameters</key>
                <array>
                  <integer>32</integer>
                  <integer>49</integer>
                  <integer>$2</integer>
                </array>
              </dict>
            </dict>"
      }

      hotkey_off 60 262144
      hotkey_off 61 786432

      # Make the change take effect without a logout (best effort).
      run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
        || true
    '';
}
