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

    # Japanese slide fonts (see fonts/biz-udp/README.md). Deck font BIZ UDPGothic
    # is vendored and shipped as a package below (NOT via home.file into
    # ~/.local/share/fonts — Nix's fontconfig, which Nix apps use, only scans the
    # profile's share/fonts, so a font dropped in the XDG dir is invisible to them
    # and gets silently substituted). Noto is the fallback insurance (family
    # "Noto Sans CJK JP" — NOT the Google Fonts "Noto Sans JP", a different family).
    (runCommand "biz-udpgothic-fonts" { } ''
      install -Dm644 ${./fonts/biz-udp/BIZUDPGothic-Regular.ttf} \
        $out/share/fonts/truetype/BIZUDPGothic-Regular.ttf
      install -Dm644 ${./fonts/biz-udp/BIZUDPGothic-Bold.ttf} \
        $out/share/fonts/truetype/BIZUDPGothic-Bold.ttf
    '')
    noto-fonts-cjk-sans

    # Chromium + its runtime libs (RPATH-resolved) for ppt-master's opt-in
    # `visual-review` workflow, which renders each SVG page headless via
    # Playwright. Pairs with PLAYWRIGHT_BROWSERS_PATH below; the slides repo pins
    # its pip `playwright` to this driver's version. Avoids listing ~20 raw libs
    # (libnspr4/libnss3/…) or running `sudo playwright install-deps`.
    playwright-driver.browsers
  ];

  # pip-installed native wheels (e.g. numpy, PyMuPDF used by ppt-master) link
  # against libstdc++.so.6, which Nix's Python does not put on the dynamic
  # loader's search path. Expose the gcc runtime libs so those wheels import.
  # libstdc++ is backward-compatible, so shadowing other apps' copy is harmless.
  home.sessionVariables.LD_LIBRARY_PATH =
    "${pkgs.stdenv.cc.cc.lib}/lib\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}";

  # Point the pip-installed Playwright (ppt-master `visual-review`) at the
  # Nix-provided browsers, which ship with their runtime libs already resolved,
  # so Chromium launches without `playwright install` or extra system libraries.
  # Keep the slides repo's pip `playwright` pinned to pkgs.playwright-driver.version.
  home.sessionVariables.PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  home.sessionVariables.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  # Build the fontconfig cache for profile fonts (the BIZ UDPGothic package above
  # and noto-fonts-cjk-sans) so Nix apps like Chromium resolve them.
  fonts.fontconfig.enable = true;

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

    # Eternal Terminal server: this dev box is a container with no systemd user
    # instance (PID 1 is sshd), so start etserver on login if not already running.
    # Listens on TCP 2022, reachable only over the Tailscale tailnet. After a pod
    # restart, one plain `ssh dev` bootstraps it; then `etdev` reconnects-survives.
    # --pidfile/--logdir must point at a writable path: the default /var/run is
    # root-only, so --daemon would abort here.
    if command -v etserver &> /dev/null && ! pgrep -x etserver &> /dev/null; then
      mkdir -p "$HOME/.local/state/et"
      etserver --port 2022 --daemon \
        --pidfile "$HOME/.local/state/et/etserver.pid" \
        --logdir "$HOME/.local/state/et" &> /dev/null || true
    fi

    # NOTE: tmux is intentionally NOT auto-started here. dev's tmux is launched
    # only by the `etdev` command (its `tmux attach || new-session` -c), so a plain
    # `ssh dev` stays a raw shell with no tmux.
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
