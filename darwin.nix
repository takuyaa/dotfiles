{ self, system, username, userHome, homebrew-core, homebrew-cask, homebrew-bundle }:
{ pkgs, ... }:

{
  # Disable nix-darwin's Nix management to avoid conflict with Determinate.
  nix.enable = false;

  # nix-homebrew configuration
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    autoMigrate = true;
    user = username;

    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
    };
  };

  # System configuration
  nixpkgs.hostPlatform = system;

  # Homebrew configuration
  homebrew = {
    enable = true;
    # onActivation.cleanup = "zap";
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    # Homebrew casks managed via official nix-darwin integration
    # All other packages (nix packages) are managed in home.nix
    taps = [
      "satococoa/tap"
    ];
    brews = [
      "mas"
      "pam-reattach"
      "satococoa/tap/wtp"
      "terminal-notifier"
    ];
    casks = [
      "font-plemol-jp-nf"
      "android-studio"
      "chatgpt"
      "claude"
      "deepl"
      "ghostty"
      "karabiner-elements"
      "iterm2"
      "lm-studio"
      "notion"
      "orbstack"
      "rectangle"
      "slack"
      "spotify"
      "visual-studio-code"
    ];
    
    masApps = {
      "Kindle" = 302584613;
    };
  };

  # Shell configuration
  programs.bash.enable = true;
  environment.shells = with pkgs; [
    bash
  ];

  # The user
  users.knownUsers = [ username ];
  users.users.${username} = {
    name = username;
    home = userHome;
    shell = pkgs.bash;
    uid = 502;
  };

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # macOS System Preferences
  system.defaults = {
    # Dock
    dock = {
      autohide = true;
      tilesize = 48;
    };

    # Finder
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Global settings
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  # Keyboard remapping
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # Enable Touch ID for sudo authentication (with tmux support)
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Set primary user for homebrew and other user-specific options
  system.primaryUser = username;

  # Rectangle settings
  system.activationScripts.postActivation.text = ''
    # Enable launch at login for Rectangle
    sudo -u ${username} defaults write com.knollsoft.Rectangle launchOnLogin -bool true
  '';

  system.stateVersion = 5;
}
