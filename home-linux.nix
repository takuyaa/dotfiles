{ config, pkgs, lib, username, userHome, ... }:
{
  imports = [ ./home-common.nix ];

  # Linux-specific packages
  home.packages = with pkgs; [
    code-server
    iproute2
    keychain
    rclone
    terraform
  ];

  # code-server systemd user service
  systemd.user.services.code-server = {
    Unit = {
      Description = "VS Code in the browser";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.code-server}/bin/code-server --bind-addr 0.0.0.0:8080";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # rebuild alias (Linux uses standalone home-manager)
  programs.bash.shellAliases.rebuild =
    "home-manager switch -b backup --flake ~/ghq/github.com/takuyaa/dotfiles#takuya-a";

  programs.bash.profileExtra = lib.mkAfter ''
    # Source Nix profile (single-user install; HM overwrites .profile so this must be explicit)
    if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi

    # Prompt for GPG passphrase if not cached (e.g. after reboot)
    if ! gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null | grep -q '1 P'; then
      echo "[GPG] Passphrase not cached. Run:  echo test | gpg -s > /dev/null"
    fi

    # Auto-install Happy CLI via npm global if not present
    if command -v npm &> /dev/null && [ ! -x "$HOME/.npm-global/bin/happy" ]; then
      npm install -g happy-coder
    fi
  '';

  # SSH host settings
  programs.ssh.matchBlocks = {
    "dev" = {
      hostname = "100.120.98.107";
      user = "takuya-a";
      identityFile = "~/.ssh/id_ed25519";
    };
    "10.0.*.*" = {
      user = "ubuntu";
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  # GPG signing key (dev-01 specific)
  programs.git.signing.key = lib.mkForce "F20538F59AADFFF0";

  # gpg-agent pinentry (headless server)
  services.gpg-agent.pinentry.package = pkgs.pinentry-curses;

  # keychain: reuses ssh-agent across login sessions
  # Passphrase is only needed once per machine reboot
  programs.keychain = {
    enable = true;
    keys = [ "id_ed25519" ];
    enableBashIntegration = true;
  };

  # Allow loopback pinentry for non-TTY environments (e.g. Claude Code)
  programs.gpg.settings.pinentry-mode = "loopback";

  # Claude CLAUDE.md (Linux version: rebuild = home-manager switch)
  home.file.".claude/CLAUDE.md".text = ''
    # Global Claude Code Settings

    ~/.claude/settings.json and ~/.claude/notify.sh are managed by Nix (Home Manager).
    They are read-only symlinks and must not be edited directly.

    To change settings:
    1. Edit ~/ghq/github.com/takuyaa/dotfiles/home-common.nix (or home-linux.nix for Linux-specific)
    2. Run `rebuild`

    Private instructions should be placed in ~/.claude/CLAUDE.local.md (gitignored).
  '';

  # Claude notify.sh (terminal bell + stderr version for Linux)
  home.file.".claude/notify.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      input=$(cat)
      cwd=$(echo "$input" | jq -r '.cwd')
      project=$(basename "$cwd")
      type=$(echo "$input" | jq -r '.notification_type')

      case "$type" in
        permission_prompt) msg="Waiting for permission" ;;
        idle_prompt)       msg="Waiting for input" ;;
        stop)              msg="Task completed" ;;
        *)                 msg="Notification" ;;
      esac

      # Terminal bell
      printf '\a' >&2

      # Log to stderr
      echo "[Claude Code] $project: $msg" >&2
    '';
  };
}
