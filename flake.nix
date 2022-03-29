{
  description = "Configuration for my sysmem";

  inputs = {

    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    home-manager = {
      url = "github:nix-community/home-manager";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    discord-flake = {url = github:InternetUnexplorer/discord-overlay;};

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
    };
  };

  outputs = { nixpkgs, home-manager, discord-flake ,nur, emacs-overlay, neovim-nightly-overlay,cachix , ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib;
    in {
      homeConfigurations."drishal" = home-manager.lib.homeManagerConfiguration {
      # also dont forget to use this command once
      # nix run --no-write-lock-file --impure github:nix-community/home-manager -- switch   --flake  . 
        inherit system pkgs;
        username="drishal";
        # pkgs = nixpkgs.legacyPackages.${system};
        homeDirectory = "/home/drishal";
        configuration = {
          nixpkgs.overlays = [ inputs.emacs-overlay.overlay  inputs.neovim-nightly-overlay.overlay  ];
          # nixpkgs.overlays = [ inputs ];
          imports = [
            ./NixOS/home.nix
          ];

        };
      };
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          modules = [
            # { nixpkgs.overlays = [ emacs-overlay.overlay ];}
            { nixpkgs.overlays = [ nur.overlay ]; }
            ./NixOS/configuration.nix
            # ./enable-flake.nix

            #./hardware-configuration.nix
          ];
        };
      };

    };
}

  # home-manager.nixosModules.home-manager
  # {
  #   home-manager.useGlobalPkgs = true;
  #   home-manager.useUserPackages = true;
  # home-manager.users.drishal = import ./NixOS/home.nix;
  # }

