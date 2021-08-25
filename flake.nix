{
  description = "Configuration for my sysmem";

  inputs = {

    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    home-manager = {
      url = "github:nix-community/home-manager";
      #inputs = { nixpkgs.follows = "nixpkgs"; };
    };

    nur.url = "github:nix-community/NUR";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
    };
    #fu.url = "github:numtide/flake-utils";
    #utils = {
    #  url = "github:gytis-ivaskevicius/flake-utils-plus/staging";
    #  inputs.flake-utils.follows = "fu";
    #};
  };

  outputs = { nixpkgs, home-manager, nur, emacs-overlay, ... }@inputs:
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
          nixpkgs.overlays = [ inputs.emacs-overlay.overlay];
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

