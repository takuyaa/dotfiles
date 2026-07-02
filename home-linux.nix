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

    # Japanese slide fonts & pptx→PDF pipeline (see fonts/biz-udp/README.md).
    # Deck font BIZ UDPGothic is vendored + placed via home.file below; Noto is the
    # fallback insurance (family "Noto Sans CJK JP" — NOT the Google Fonts
    # "Noto Sans JP", which is a different family). libreoffice/poppler are the
    # heavy downloads flagged for wifi; `soffice` converts, `pdffonts` verifies.
    noto-fonts-cjk-sans
    libreoffice
    poppler-utils

    # pptx2pdf: convert a deck to PDF in a font-installed environment and verify
    # every font is embedded, so distributed PDFs render identically on machines
    # without the fonts. Refuses to run if BIZ UDPGothic is absent (no silent
    # substitution). A global bin so it works from any deck dir (ppt-master is a
    # separate repo). Usage: pptx2pdf [-o OUTDIR] deck.pptx [more.pptx ...]
    (writeShellScriptBin "pptx2pdf" ''
      set -euo pipefail

      # Preflight: require the deck font in the font cache. Without it soffice
      # silently substitutes and bakes the wrong glyphs permanently into the PDF.
      if ! ${pkgs.fontconfig}/bin/fc-list | grep -qi 'BIZ UDPGothic'; then
        echo "❌ BIZ UDPGothic が見つかりません。フォント未導入の環境では変換しません（サイレント置換防止）。" >&2
        echo "   'rebuild' でフォントを導入してから再実行してください。" >&2
        exit 1
      fi

      outdir=""
      inputs=()
      while [ $# -gt 0 ]; do
        case "$1" in
          -o|--outdir) outdir="$2"; shift 2 ;;
          -h|--help)
            echo "usage: pptx2pdf [-o OUTDIR] file.pptx [more.pptx ...]"; exit 0 ;;
          *) inputs+=("$1"); shift ;;
        esac
      done

      if [ ''${#inputs[@]} -eq 0 ]; then
        echo "usage: pptx2pdf [-o OUTDIR] file.pptx [more.pptx ...]" >&2
        exit 2
      fi

      rc=0
      for src in "''${inputs[@]}"; do
        if [ ! -f "$src" ]; then
          echo "❌ 入力が見つかりません: $src" >&2
          rc=1; continue
        fi
        out="''${outdir:-$(dirname "$src")}"
        mkdir -p "$out"
        echo "▶ 変換: $src → $out/"
        ${pkgs.libreoffice}/bin/soffice --headless --convert-to pdf --outdir "$out" "$src"

        base="$(basename "$src")"
        pdf="$out/''${base%.*}.pdf"
        if [ ! -f "$pdf" ]; then
          echo "❌ 変換に失敗しました: $pdf が生成されていません" >&2
          rc=1; continue
        fi

        # Verify every font is embedded. pdffonts' "emb" column is the 4th field;
        # a subset embed shows emb=yes,sub=yes so this passes it too.
        if ${pkgs.poppler-utils}/bin/pdffonts "$pdf" | tail -n +3 \
            | awk '$4=="no"{print "  NOT EMBEDDED:",$0; bad=1} END{exit bad+0}'; then
          echo "✅ 埋め込みOK: $pdf"
        else
          echo "❌ 未埋め込みフォントあり（変換環境にフォントが無い可能性）: $pdf" >&2
          rc=1
        fi
      done
      exit $rc
    '')
  ];

  # Vendored BIZ UDPGothic → user font dir; fontconfig picks it up after fc-cache.
  fonts.fontconfig.enable = true;
  home.file.".local/share/fonts/BIZUDPGothic-Regular.ttf".source =
    ./fonts/biz-udp/BIZUDPGothic-Regular.ttf;
  home.file.".local/share/fonts/BIZUDPGothic-Bold.ttf".source =
    ./fonts/biz-udp/BIZUDPGothic-Bold.ttf;

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
