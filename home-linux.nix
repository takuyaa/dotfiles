{ config, pkgs, lib, username, userHome, ... }:
{
  imports = [ ./home-common.nix ];

  # Linux-specific packages
  home.packages = with pkgs; [
    # build-essential equivalent (C/C++ toolchain)
    binutils
    gcc
    gnumake
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

  # rebuild/update aliases (delegate to Makefile so the source of truth is one place)
  programs.bash.shellAliases.rebuild = "make -C ~/ghq/github.com/takuyaa/dotfiles rebuild";
  programs.bash.shellAliases.update = "make -C ~/ghq/github.com/takuyaa/dotfiles update";

  programs.bash.profileExtra = lib.mkAfter ''
    # Source Nix profile (single-user install; HM overwrites .profile so this must be explicit)
    if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi

    # Auto-install Happy CLI via npm global if not present
    if command -v npm &> /dev/null && [ ! -x "$HOME/.npm-global/bin/happy" ]; then
      npm install -g happy-coder
    fi
  '';

  # SSH host settings
  programs.ssh.settings = {
    "dev" = {
      HostName = "100.120.98.107";
      User = "takuya-a";
      IdentityFile = "~/.ssh/id_ed25519";
    };
    "10.0.*.*" = {
      User = "ubuntu";
      IdentityFile = "~/.ssh/id_ed25519";
    };
  };

  # keychain: reuses ssh-agent across login sessions
  # Passphrase is only needed once per machine reboot
  programs.keychain = {
    enable = true;
    keys = [ "id_ed25519" ];
    enableBashIntegration = true;
  };

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
