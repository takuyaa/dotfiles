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
    claude-code
    cocoapods
    codex
    copier
    fzf
    glow
    mise
    shellcheck
    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
    jless
    jq
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
    nodejs
    pnpm
    python3
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
        git commit -m "$(claude -p "Analyze the staged changes below and generate a commit message.\
        Requirements:\
        - Exactly ONE line, max 60 characters\
        - Imperative mood (Add/Update/Fix/Remove/Refactor/Rename)\
        - ASCII only, no quotes, no code blocks, no emojis, no trailing period\
        - Output ONLY the commit message itself, nothing else\
        - Do NOT include any prefixes, suffixes, explanations, or conversation markers\
        Staged changes:\
        $(git diff --cached --unified=0 --no-color)")"
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
        --title "$(claude -p "以下の差分を読み、簡潔なPRタイトルをConventional Commits形式（<type>[optional scope]: <description>）で1行だけ生成してください。descriptionは小文字始まりで50文字以内の英語で、常体、Markdown装飾なし。余計な説明は不要。利用可能なtypeとscopeは .github/workflows/pr-title-lint.yml を参照してください。\n\n$(git diff origin/main...HEAD --no-color)")" \
        --body "$(claude -p "以下のPRテンプレートと差分を元に、PRの本文を日本語のMarkdown形式で作成してください。Markdownのコードブロック枠（\`\`\`）や挨拶は含めず、本文のみを出力してください。\n\nTemplate:\n$(cat "$(git rev-parse --show-toplevel)/.github/pull_request_template.md" 2>/dev/null || echo "")\n\nDiff:\n$(git diff origin/main...HEAD --no-color)")"
      '';
      gr = "git reset";
      gs = "git status";
      gsw = "git switch";
      gtag = "git tag";

      # ghq
      gcd = "dir=$(ghq list -p | fzf) && [ -n \"$dir\" ] && cd \"$dir\"";

      # wtp (git worktree)
      wtadd = "wtp add -b";
      wtcd = "wtp cd $(wtp list -q | fzf)";
      wtls = "wtp list";
      wtrm = "wt=$(wtp list -q | fzf) && [ -n \"$wt\" ] && read -p \"Remove worktree '$wt'? [y/N] \" -n 1 -r && echo && [[ $REPLY =~ ^[Yy]$ ]] && wtp rm -f --with-branch \"$wt\"";

      # stern
      stern = "kubectl stern";

      # kubectl
      k = "kubectl";
      kc = "kubectl config";
      kcx = "kubectl config use-context";
      kcxn = "kubectl config set-context --current --namespace";
      kn = "kubens";
      kx = "kubectx";
    };

    profileExtra = ''
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

      # Set Emacs as default editor
      export EDITOR="emacs"
      export VISUAL="emacs"
      
      # Enable color output for less
      export LESS="-R"

      # Android SDK
      export ANDROID_HOME=$HOME/Library/Android/sdk
      export PATH=$PATH:$ANDROID_HOME/emulator
      export PATH=$PATH:$ANDROID_HOME/platform-tools
    '';

    initExtra = ''
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

      # wtp setup
      if command -v wtp &> /dev/null; then
        eval "$(wtp shell-init bash)"
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
    '';
  };

  xdg.configFile = {
    "nix/nix.conf".text = ''
      experimental-features = nix-command flakes
      auto-optimise-store = true
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

      # Highlight active window
      set -g window-status-current-style "fg=yellow,bold"
    '';
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
}
