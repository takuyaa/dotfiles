{ self, system, username, userHome, homebrew-core, homebrew-cask, homebrew-bundle }:
{ pkgs, ... }:

{
  # System configuration
  nixpkgs.hostPlatform = system;

  # Disable nix-darwin's Nix management to avoid conflict with Determinate.
  nix.enable = false;

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  # Set primary user for homebrew and other user-specific options
  system.primaryUser = username;

  # The user
  users.knownUsers = [ username ];
  users.users.${username} = {
    name = username;
    home = userHome;
    shell = pkgs.bash;
    uid = 503;
  };

  # nix-homebrew configuration
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    autoMigrate = true;
    user = username;

    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
    };
  };

  # Homebrew configuration
  homebrew = {
    enable = true;
    # onActivation.cleanup = "zap";
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    # Homebrew casks managed via official nix-darwin integration
    # All other packages (nix packages) are managed in home.nix
    brews = [];
    casks = [
      "iterm2"
      "visual-studio-code"
      "warp"
    ];
  };

  # Shell configuration
  programs.bash.enable = true;
  environment.shells = with pkgs; [
    bash
  ];

  # Keyboard remapping
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

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
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    # Global settings
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
    };
  };
}
