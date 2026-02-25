{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
  }: let
    system = "aarch64-darwin"; # For Apple Silicon Macs (use "x86_64-darwin" for Intel Macs)
    username = "takuya.asano";
    userHome = "/Users/${username}";
  in {
    # macOS configuration
    darwinConfigurations = {
      "macos" = nix-darwin.lib.darwinSystem {
        modules = [
          (import ./darwin.nix {
            inherit self system username userHome homebrew-core homebrew-cask homebrew-bundle;
          })

          nix-homebrew.darwinModules.nix-homebrew

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.${username} = import ./home-darwin.nix;
            home-manager.extraSpecialArgs = {
              inherit username userHome;
            };
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };
    };

    # Linux standalone home-manager configuration
    homeConfigurations = {
      "takuya-a" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          username = "takuya-a";
          userHome = "/home/takuya-a";
        };
        modules = [ ./home-linux.nix ];
      };
    };
  };
}
