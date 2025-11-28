{ config, pkgs, username, userHome, ... }:

{
  home.username = username;
  home.homeDirectory = userHome;

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # Development tools
    buf
    claude-code
    codex
    copier
    fzf
    glow
    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
    jless
    jq
    tmux
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
    nodejs
    pnpm
    python3
    go
    rustup
    uv

    # Kubernetes tools
    k9s
    kubectl
    kubectx
    kubernetes-helm
    stern

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
      gb = "git branch";
      gba = "git branch -a";
      gbd = "git branch -d";
      gbm = "git branch -m";
      gc = "git commit";
      gca = "git commit --amend";
      gcm = "git commit --message";
      gcma = ''
        git commit -m "$(claude -p 'Read the staged changes by running: git diff --cached --unified=0 --no-color. 
        Produce exactly ONE concise English commit subject line (max 60 characters). 
        Rules: imperative mood (Add/Update/Fix/Remove/Refactor/Rename), ASCII only, 
        no quotes, no code blocks, no emojis, no trailing period, no explanations, and NO newlines. 
        Return ONLY the single line.')"
      '';
      gcl = "git clone";
      gco = "git checkout";
      gd = "git diff";
      gf = "git fetch";
      gl = "git log";
      gm = "git merge";
      gp = "git push";
      gpl = "git pull";
      gpr = ''
        gh pr create \
        --title "$(claude -p "以下の差分を読み、日本語で簡潔なPRタイトルを1行だけ生成してください（50文字以内、常体、Markdown装飾なし）。余計な説明は不要。\n\n$(git diff origin/main...HEAD --no-color)")" \
        --body "$(claude -p "以下のPRテンプレートと差分を元に、PRの本文を日本語のMarkdown形式で作成してください。Markdownのコードブロック枠（\`\`\`）や挨拶は含めず、本文のみを出力してください。\n\nTemplate:\n$(cat "$(git rev-parse --show-toplevel)/.github/pull_request_template.md" 2>/dev/null || echo "")\n\nDiff:\n$(git diff origin/main...HEAD --no-color)")"
      '';
      gr = "git reset";
      gs = "git status";
      gsw = "git switch";
      gtag = "git tag";

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
      
      # Set Emacs as default editor
      export EDITOR="emacs"
      export VISUAL="emacs"
      
      # Enable color output for less
      export LESS="-R"
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
        __git_complete gf _git_fetch
        __git_complete gl _git_log
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

  programs.git = {
    enable = true;
    userName = "Takuya Asano";
    userEmail = "takuya.a@gmail.com";
    signing = {
      key = "95A468733FD3BFA52C2D99805E243D42C1E76500";
      signByDefault = true;
    };
    ignores = [
      # macOS
      ".DS_Store"
      
      # Claude
      "CLAUDE.md"
      "**/.claude/settings.local.json"
      
      # Serena MCP
      ".serena/"

      # Playwright MCP
      ".playwright-mcp/"
    ];
    extraConfig = {
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

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
}
