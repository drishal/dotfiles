{
  description = "Configuration for my system";

  inputs = {

    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    home-manager = {
      url = "github:nix-community/home-manager";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    discord-flake = { url = github:InternetUnexplorer/discord-overlay; };

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    declarative-cachix.url = "github:jonascarpay/declarative-cachix";

    emacs-overlay = {
      # url = "github:nix-community/emacs-overlay";
      url = "github:nix-community/emacs-overlay/5daf2e7e8dc77c029c2436ae32d7aa869acce648";
    };

    private-stuff = {
     url = "path:/home/drishal/.private-stuff";
     flake = false;
   };

  };

  outputs = { nixpkgs, home-manager, discord-flake, nur, emacs-overlay, neovim-nightly-overlay, cachix, declarative-cachix, private-stuff, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib;
    in
    {
      homeConfigurations."drishal" = home-manager.lib.homeManagerConfiguration {
        # also dont forget to use this command once
        # nix run --no-write-lock-file --impure github:nix-community/home-manager -- switch   --flake  . 
        inherit system pkgs;
        username = "drishal";
        # pkgs = nixpkgs.legacyPackages.${system};
        homeDirectory = "/home/drishal";
        configuration = {
          nixpkgs.overlays = [ inputs.emacs-overlay.overlay inputs.neovim-nightly-overlay.overlay ];
          # nixpkgs.overlays = [ inputs ];
          imports = [
            ./NixOS/home.nix
            "${private-stuff}/hm-email.nix"
          ];

        };
      };
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          modules = [
            # { nixpkgs.overlays = [ emacs-overlay.overlay ];}
            { nixpkgs.overlays = [ nur.overlay inputs.emacs-overlay.overlay ]; }
            ./NixOS/configuration.nix
            # ./enable-flake.nix

            #./hardware-configuration.nix
          ];
        };
      };

    };
}
