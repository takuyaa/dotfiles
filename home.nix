{ config, pkgs, username, userHome, ... }:

let
  linear-tui = pkgs.buildGoModule {
    pname = "linear-tui";
    version = "unstable-2024-12-25";

    src = pkgs.fetchFromGitHub {
      owner = "Boostly";
      repo = "linear-tui";
      rev = "b3fc9bab6b02ca3ba4c77da85dfed9a666024aa0";
      hash = "sha256-DMD2OVLUfiFDGhHeBkN+aN7gHCj4cWhGhBm33vUfXCY=";
    };

    vendorHash = "sha256-eRqZXgJR9woZDqh+LAL30EqnJV2vMBPh0aO6EicsUus=";

    meta = with pkgs.lib; {
      description = "A TUI for Linear";
      homepage = "https://github.com/Boostly/linear-tui";
      license = licenses.mit;
      mainProgram = "linear-tui";
    };
  };
in
{
  home.username = username;
  home.homeDirectory = userHome;

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # Development tools
    buf
    postgresql
    terminal-notifier
    claude-code
    cocoapods
    codex
    copier
    fzf
    glow
    livekit
    livekit-cli
    mise
    shellcheck
    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
    jless
    jq
    jwt-cli
    tree
    watch
    yq

    # Network tools
    curl
    grpcurl
    iproute2mac
    mtr
    nmap
    rsync
    wget

    # Git
    delta
    gh
    ghq
    git-lfs
    lazygit

    # System tool alternatives
    bat
    btop
    duf
    dust
    eza
    fd
    ripgrep
    tlrc
    tre

    # Programming languages
    go
    jdk
    nodejs_22
    pnpm
    python3
    python3Packages.huggingface-hub
    rustup
    uv

    # Kubernetes tools
    k9s
    kubectl
    kubectx
    kubernetes-helm
    stern

    # Custom packages
    linear-tui

    # tmux helper: show git branch or basename for window status
    (writeShellScriptBin "tmux-window-info" ''
      path="$1"
      max=24
      branch=$(cd "$path" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
      if [ -n "$branch" ]; then
        repo=$(cd "$path" && basename "$(git rev-parse --show-toplevel)")
        result="$repo:$branch"
      else
        result=$(basename "$path")
      fi
      if [ "''${#result}" -le "$max" ]; then
        echo "$result"
      else
        echo "''${result:0:$((max-1))}…"
      fi
    '')

    # tmux helper: show git branch or truncated path in pane border
    (writeShellScriptBin "tmux-pane-info" ''
      path="$1"
      width="$2"

      # Try git branch first
      branch=$(cd "$path" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
      if [ -n "$branch" ]; then
        echo "$branch"
        exit 0
      fi

      # Fall back to truncated directory path
      p="''${path/#$HOME/~}"
      max=$(( width / 3 ))
      [ "$max" -lt 10 ] && max=10
      if [ "''${#p}" -le "$max" ]; then
        echo "$p"
      else
        echo "…''${p: -$(( max - 1 ))}"
      fi
    '')

    # Homebrew casks are managed as Homebrew casks in flake.nix
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      # System tool alternatives
      cat = "bat";
      du = "dust";
      df = "duf";
      la = "eza -la";
      ll = "eza -l";
      ls = "eza";
      less = "less -R";
      top = "btop";

      # Documentation/Help
      tldr = "tldr --color always";

      # Nix
      rebuild = "sudo darwin-rebuild switch --flake .#macos";
      flake-update = "nix flake update";

      # Emacs
      e = "emacs";

      # Git aliases
      g = "git";
      ga = "git add";
      gap = "git add -p";
      gb = "git branch";
      gba = "git branch -a";
      gbd = "git branch -d";
      gbm = "git branch -m";
      gc = "git commit";
      gca = "git commit --amend";
      gcm = "git commit --message";
      gcma = ''
        git commit -m "$(claude -p --no-session-persistence "Analyze the staged changes below and generate a commit message.
        Requirements:
        - Exactly ONE line, max 60 characters
        - Imperative mood (Add/Update/Fix/Remove/Refactor/Rename)
        - ASCII only, no quotes, no code blocks, no emojis, no trailing period
        - Output ONLY the commit message itself, nothing else
        - Do NOT include any prefixes, suffixes, explanations, or conversation markers

        Stat:
        $(git diff --cached --stat --no-color)

        Diff:
        $(git diff --cached --unified=0 --no-color | head -c 8000)")"
      '';
      gcl = "git clone";
      gco = "git checkout";
      gd = "git diff";
      gdc = "git diff --cached";
      gf = "git fetch";
      gg = "git grep";
      gl = "git log";
      gl1 = "git log --oneline";
      gm = "git merge";
      gp = "git push";
      gpl = "git pull";
      gpr = ''
        gh pr create --draft \
        --title "$(claude -p --no-session-persistence "以下の差分を読み、簡潔なPRタイトルをConventional Commits形式（<type>[optional scope]: <description>）で1行だけ生成してください。descriptionは小文字始まりで50文字以内の英語で、常体、Markdown装飾なし。余計な説明は不要。利用可能なtypeとscopeは .github/workflows/pr-title-lint.yml を参照してください。\n\n$(git diff origin/main...HEAD --no-color)")" \
        --body "$(claude -p --no-session-persistence "以下のPRテンプレートと差分を元に、PRの本文を日本語のMarkdown形式で作成してください。Markdownのコードブロック枠（\`\`\`）や挨拶は含めず、本文のみを出力してください。\n\nTemplate:\n$(cat "$(git rev-parse --show-toplevel)/.github/pull_request_template.md" 2>/dev/null || echo "")\n\nDiff:\n$(git diff origin/main...HEAD --no-color)")"
      '';
      gr = "git reset";
      gs = "git status";
      gswa = ''
        git switch -c "$(claude -p --no-session-persistence "Analyze the staged changes below and generate a Git branch name.\
        Requirements:\
        - Format: <type>/<short-description>\
        - Types: feat, fix, refactor, docs, chore, test, style, perf, ci, build\
        - Description: lowercase, hyphen-separated, max 40 characters\
        - ASCII only, no quotes, no code blocks, no trailing slash\
        - Output ONLY the branch name itself, nothing else\
        - Examples: feat/add-user-auth, fix/null-pointer-exception, refactor/simplify-config\
        \
        Files changed:\
        $(git diff --cached --stat --no-color)\
        \
        Detailed changes:\
        $(git diff --cached --unified=5 --no-color)")"
      '';
      gtag = "git tag";

      # ghq
      gcd = "dir=$(ghq list -p | fzf) && [ -n \"$dir\" ] && cd \"$dir\"";

      # wtp (git worktree)
      # wtls = "wtp list";
      # wtrm = "wt=$(wtp list -q | fzf) && [ -n \"$wt\" ] && read -p \"Remove worktree '$wt'? [y/N] \" -n 1 -r && echo && [[ $REPLY =~ ^[Yy]$ ]] && wtp rm -f --with-branch \"$wt\"";

      # stern
      stern = "kubectl stern";

      # kubectl
      k = "kubectl";
      kc = "kubectl config";
      kcx = "kubectl config use-context";
      kcxn = "kubectl config set-context --current --namespace";
      kn = "kubens";
      kx = "kubectx";

      # k9s with TERM fix for tmux (https://github.com/derailed/k9s/issues/3722)
      k9s = "TERM=xterm-256color k9s";
    };

    profileExtra = ''
      # Silence macOS bash deprecation warning
      export BASH_SILENCE_DEPRECATION_WARNING=1

      # Add ~/.local/bin to PATH
      if [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi

      # Add per-user profile to PATH for home-manager packages
      if [ -d "/etc/profiles/per-user/$USER/bin" ]; then
        export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
      fi

      # Add Homebrew (Apple Silicon) to PATH
      if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
      fi

      # Set Emacs as default editor
      export EDITOR="emacs"
      export VISUAL="emacs"
      
      # Enable color output for less
      export LESS="-R"

      # Android SDK
      export ANDROID_HOME=$HOME/Library/Android/sdk
      export PATH=$PATH:$ANDROID_HOME/emulator
      export PATH=$PATH:$ANDROID_HOME/platform-tools

      # GitHub token for API access (also configures Nix to avoid rate limits)
      if command -v gh &> /dev/null; then
        GITHUB_TOKEN=$(gh auth token 2>/dev/null) && export GITHUB_TOKEN
        if [ -n "$GITHUB_TOKEN" ]; then
          export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
        fi
      fi
    '';

    initExtra = ''
      # gsw function: git switch with fzf when no argument provided
      gsw() {
        if [ $# -eq 0 ]; then
          branch=$(git branch --all --sort=-committerdate | grep -v HEAD | sed 's/.* //' | sed 's#remotes/origin/##' | awk '!seen[$0]++' | fzf)
          [ -n "$branch" ] && git switch "$branch"
        else
          git switch "$@"
        fi
      }

      # Load git completion script
      if [ -f ${pkgs.git}/share/bash-completion/completions/git ]; then
        source ${pkgs.git}/share/bash-completion/completions/git
      fi
      
      # Git prompt configuration
      export GIT_PS1_SHOWDIRTYSTATE=true
      export GIT_PS1_SHOWUNTRACKEDFILES=true
      export GIT_PS1_SHOWSTASHSTATE=true
      export GIT_PS1_SHOWUPSTREAM=auto
      
      # Git completion for aliases
      if type __git_complete &>/dev/null; then
        __git_complete g __git_main
        __git_complete ga _git_add
        __git_complete gap _git_add
        __git_complete gb _git_branch
        __git_complete gba _git_branch
        __git_complete gbd _git_branch
        __git_complete gbm _git_branch
        __git_complete gc _git_commit
        __git_complete gca _git_commit
        __git_complete gcm _git_commit
        __git_complete gcma _git_commit
        __git_complete gcl _git_clone
        __git_complete gco _git_checkout
        __git_complete gd _git_diff
        __git_complete gdc _git_diff
        __git_complete gf _git_fetch
        __git_complete gg _git_grep
        __git_complete gl _git_log
        __git_complete gl1 _git_log
        __git_complete gm _git_merge
        __git_complete gp _git_push
        __git_complete gpl _git_pull
        __git_complete gr _git_reset
        __git_complete gs _git_status
        __git_complete gsw _git_switch
        __git_complete gtag _git_tag
      fi
      
      # kubectl completion for alias
      if command -v kubectl &> /dev/null; then
        source <(kubectl completion bash)
        complete -F __start_kubectl k
      fi
      
      # kubectx/kubens completion for aliases
      if command -v kubectx &> /dev/null && [ -f ${pkgs.kubectx}/share/bash-completion/completions/kubectx ]; then
        source ${pkgs.kubectx}/share/bash-completion/completions/kubectx
        complete -F _kube_contexts kx
      fi
      if command -v kubens &> /dev/null && [ -f ${pkgs.kubectx}/share/bash-completion/completions/kubens ]; then
        source ${pkgs.kubectx}/share/bash-completion/completions/kubens
        complete -F _kube_namespaces kn
      fi
      
      # mise setup
      if command -v mise &> /dev/null; then
        eval "$(mise activate bash)"
      fi

      # Krew setup
      if command -v krew &> /dev/null; then
        export PATH="${userHome}/.krew/bin:$PATH"
        
        # Install krew plugins if not already installed
        if [ ! -f "${userHome}/.krew/bin/kubectl-ctx" ]; then
          kubectl krew install ctx 2>/dev/null || true
        fi
        if [ ! -f "${userHome}/.krew/bin/kubectl-ns" ]; then
          kubectl krew install ns 2>/dev/null || true
        fi
      fi

      # wtcd - Interactive worktree navigation with fzf
      # Generated by: wtcd --hook bash
      # Usage: wtcd [worktree-name]
      #   Without arguments: interactive selection with fzf
      #   With argument: navigate directly to the specified worktree
      wtcd() {
          # Check for wtp
          if ! command -v wtp &>/dev/null; then
              echo "Error: wtp is not installed" >&2
              return 1
          fi

          local selected

          # If argument provided, use it directly
          if [[ $# -gt 0 ]]; then
              selected="$1"
          else
              # Get worktree list (quiet mode for full names without truncation)
              local worktrees
              worktrees=$(wtp list -q 2>/dev/null)

              if [[ -z "$worktrees" ]]; then
                  echo "No worktrees found" >&2
                  return 1
              fi

              # Select worktree
              if command -v fzf &>/dev/null; then
                  selected=$(echo "$worktrees" | fzf \
                      --height 40% \
                      --reverse \
                      --prompt="worktree> " \
                      --header="Select a worktree to navigate to")
              else
                  echo "Available worktrees:" >&2
                  echo "$worktrees" >&2
                  echo "" >&2
                  echo -n "Enter worktree name: " >&2
                  read -r selected
              fi
          fi

          if [[ -z "$selected" ]]; then
              return 0
          fi

          # Get worktree path and cd (selected is the full worktree name)
          local target_dir
          target_dir=$(wtp cd -- "$selected" 2>&1)
          local wtp_exit=$?

          if [[ $wtp_exit -ne 0 ]]; then
              echo "Error: wtp cd failed for '$selected': $target_dir" >&2
              return 1
          fi

          if [[ -z "$target_dir" ]]; then
              echo "Error: wtp cd returned empty path for: $selected" >&2
              return 1
          fi

          if [[ ! -d "$target_dir" ]]; then
              echo "Error: Worktree directory does not exist: $target_dir" >&2
              return 1
          fi

          cd -- "$target_dir"
          echo "Switched to: $selected" >&2
      }
    '';
  };

  xdg.configFile = {
    "nix/nix.conf".text = ''
      experimental-features = nix-command flakes
    '';
  };

  home.file.".claude/settings.json" = {
    text = builtins.toJSON {
      alwaysThinkingEnabled = true;
      enabledMcpjsonServers = ["linear-server"];
      enableAllProjectMcpServers = true;
      env = {
        ENABLE_TOOL_SEARCH = "true";
      };
      hooks = {
        PreToolUse = [{
          matcher = "AskUserQuestion";
          hooks = [{
            type = "command";
            command = "echo '{\"cwd\": \"'\"$(pwd)\"'\", \"notification_type\": \"idle_prompt\"}' | ~/.claude/notify.sh";
          }];
        }];
        Stop = [{
          matcher = "";
          hooks = [{
            type = "command";
            command = "echo '{\"cwd\": \"'\"$(pwd)\"'\", \"notification_type\": \"stop\"}' | ~/.claude/notify.sh";
          }];
        }];
        Notification = [{
          matcher = "permission_prompt";
          hooks = [{
            type = "command";
            command = "echo '{\"cwd\": \"'\"$(pwd)\"'\", \"notification_type\": \"permission_prompt\"}' | ~/.claude/notify.sh";
          }];
        }];
      };
      permissions = {
        allow = [
          "Bash(basename:*)"
          "Bash(cal:*)"
          "Bash(cut:*)"
          "Bash(date:*)"
          "Bash(darwin-rebuild list-generations:*)"
          "Bash(diff:*)"
          "Bash(dirname:*)"
          "Bash(file:*)"
          "Bash(gh run view:*)"
          "Bash(git add:*)"
          "Bash(git blame:*)"
          "Bash(git diff:*)"
          "Bash(git fetch:*)"
          "Bash(git log:*)"
          "Bash(git ls-files:*)"
          "Bash(git ls-remote:*)"
          "Bash(git ls-tree:*)"
          "Bash(git pull:*)"
          "Bash(git remote:*)"
          "Bash(git rev-parse:*)"
          "Bash(git shortlog:*)"
          "Bash(git show:*)"
          "Bash(git status:*)"
          "Bash(git worktree:*)"
          "Bash(grep:*)"
          "Bash(head:*)"
          "Bash(jq:*)"
          "Bash(ls:*)"
          "Bash(mkdir:*)"
          "Bash(nix derivation show:*)"
          "Bash(nix flake info:*)"
          "Bash(nix flake metadata:*)"
          "Bash(nix flake show:*)"
          "Bash(nix hash:*)"
          "Bash(nix log:*)"
          "Bash(nix path-info:*)"
          "Bash(nix registry list:*)"
          "Bash(nix search:*)"
          "Bash(nix show-config:*)"
          "Bash(nix store ls:*)"
          "Bash(nix why-depends:*)"
          "Bash(pwd:*)"
          "Bash(realpath:*)"
          "Bash(sort:*)"
          "Bash(stat:*)"
          "Bash(tail:*)"
          "Bash(touch:*)"
          "Bash(tr:*)"
          "Bash(tree:*)"
          "Bash(uniq:*)"
          "Bash(wc:*)"
          "Bash(which:*)"
          "WebFetch(domain:code.claude.com)"
          "WebFetch(domain:docs.anthropic.com)"
          "WebFetch(domain:docs.claude.com)"
          "WebFetch(domain:docs.docker.com)"
          "WebFetch(domain:github.com)"
          "WebSearch"
          "mcp__linear-server__get_document"
          "mcp__linear-server__get_issue"
          "mcp__linear-server__get_issue_status"
          "mcp__linear-server__get_project"
          "mcp__linear-server__get_team"
          "mcp__linear-server__get_user"
          "mcp__linear-server__list_comments"
          "mcp__linear-server__list_cycles"
          "mcp__linear-server__list_documents"
          "mcp__linear-server__list_issue_labels"
          "mcp__linear-server__list_issue_statuses"
          "mcp__linear-server__list_issues"
          "mcp__linear-server__list_project_labels"
          "mcp__linear-server__list_projects"
          "mcp__linear-server__list_teams"
          "mcp__linear-server__list_users"
          "mcp__linear-server__search_documentation"
          "mcp__notion__notion-fetch"
          "mcp__notion__notion-get-comments"
          "mcp__notion__notion-get-self"
          "mcp__notion__notion-get-teams"
          "mcp__notion__notion-get-user"
          "mcp__notion__notion-get-users"
          "mcp__notion__notion-query-data-sources"
          "mcp__notion__notion-search"
        ];
        deny = [];
        ask = [];
      };
      language = "japanese";
    };
  };

  home.file.".claude/CLAUDE.md".text = ''
    # Global Claude Code Settings

    ~/.claude/settings.json and ~/.claude/notify.sh are managed by Nix (Home Manager).
    They are read-only symlinks and must not be edited directly.

    To change settings:
    1. Edit ~/ghq/github.com/takuyaa/dotfiles/home.nix
    2. Run `rebuild`

    Private instructions should be placed in ~/.claude/CLAUDE.local.md (gitignored).
  '';

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

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;  # This automatically adds direnv hook to bash
    nix-direnv.enable = true;
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;  # Terminal-only Emacs without GUI support
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.ghostty = {
    enable = true;
    package = null;  # Installed via Homebrew cask
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

  programs.git = {
    enable = true;
    signing = {
      key = "95A468733FD3BFA52C2D99805E243D42C1E76500";
      signByDefault = true;
    };
    ignores = [
      # macOS
      ".DS_Store"

      # Claude
      "**/.claude/settings.local.json"
      "CLAUDE.local.md"

      # Serena MCP
      ".serena/"

      # Playwright MCP
      ".playwright-mcp/"
    ];
    settings = {
      user = {
        name = "Takuya Asano";
        email = "takuya.a@gmail.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = false;
      core.editor = "emacs";
      tag.gpgSign = true;
      gpg = {
        format = "openpgp";
        openpgp.program = "${pkgs.gnupg}/bin/gpg";
      };
    };
  };

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;  # This automatically adds starship init to bash
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;              # Start window numbering at 1
    escapeTime = 0;             # No delay for Escape key
    historyLimit = 50000;       # Scrollback buffer size
    keyMode = "emacs";          # Emacs keybindings
    mouse = true;               # Enable mouse support
    prefix = "C-t";             # Use Ctrl-t as prefix (Ctrl-b conflicts with Emacs backward-char)
    terminal = "tmux-256color";
    extraConfig = ''
      # Pane splitting keybindings
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Emacs-style pane navigation
      bind C-p select-pane -U
      bind C-n select-pane -D
      bind C-b select-pane -L
      bind C-f select-pane -R

      # Pane resizing
      bind -r M-Up resize-pane -U 5
      bind -r M-Down resize-pane -D 5
      bind -r M-Left resize-pane -L 5
      bind -r M-Right resize-pane -R 5

      # Open new window in current directory
      bind c new-window -c "#{pane_current_path}"

      # Status bar
      set -g status-position top
      set -g status-style "bg=default,fg=white"
      set -g status-left "#[fg=green][#S] "
      set -g status-right "#[fg=cyan]%Y-%m-%d %H:%M"

      # Window status - show git branch or directory basename
      set -g window-status-format "#I:#(tmux-window-info '#{pane_current_path}')#F"
      set -g window-status-current-format "#I:#(tmux-window-info '#{pane_current_path}')#F"
      set -g window-status-current-style "fg=yellow,bold"

      # Pane styling - dim inactive panes to highlight active pane
      set -g window-style "fg=colour240,bg=terminal"
      set -g window-active-style "fg=terminal,bg=terminal"
      set -g pane-border-style "fg=colour238"
      set -g pane-active-border-style "fg=green"
      set -g pane-border-lines heavy
      set -g pane-border-indicators arrows
      set -g pane-border-status top
      set -g status-interval 5
      set -g pane-border-format " #[fg=colour240]#{pane_index} #{?pane_active,#[fg=green]●,#[fg=colour238]○} #[fg=colour240]#{pane_current_command} #[fg=magenta]#(tmux-pane-info '#{pane_current_path}' #{pane_width})#[default] "
    '';
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
}
