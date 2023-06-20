{
  description = "Configuration for my system";
  # nixConfig.substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
  # nixConfig.substituters = [ "https://aseipp-nix-cache.freetls.fastly.net" ];
  # nixConfig.extra-substituters = [ "https://contamination.cachix.org" "https://nix-community.cachix.org" ];
  # nixConfig.extra-trusted-public-keys = [ "contamination.cachix.org-1:KmdW5xVF8ccKEb9tvK6qtEMW+lGa83seGgFyBOkeM/4=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  # nixConfig.trusted-users=["root" "drishal"];
  # nixConfig.extra-substituters = [ "https://nix-community.cachix.org" ];
  # nixConfig.extra-trusted-public-keys = [  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  inputs = {

    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    # nixpkgs-master= { url = "github:nixos/nixpkgs/master"; };

    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    discord-flake = { url = github:InternetUnexplorer/discord-overlay; };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    declarative-cachix.url = "github:jonascarpay/declarative-cachix";

    # hyprland.url = "github:hyprwm/Hyprland/51a930f802c71a0e67f05e7b176ded74e8e95f87";
    hyprland.url = "github:hyprwm/Hyprland/5ac625d7bdff6b6318058f396f0fa1641bb6e807";

    emacs-overlay = {
      # url = "github:nix-community/emacs-overlay";
      # url = "github:nix-community/emacs-overlay/9bc16d788b9b09e986b2fba5a76fe44d35010d52";
      url = "github:nix-community/emacs-overlay/128bdc6a54bcf514c515377240f0809377f3d9b0";
    };

    private-stuff = {
      url = "path:/home/drishal/.private-stuff";
      flake = false;
    };

  };

  outputs = { nixpkgs, home-manager, discord-flake, nur, emacs-overlay, cachix, declarative-cachix,hyprland, private-stuff,chaotic, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      # master-pkgs = import nixpkgs-master {
      #   inherit system;
      #   config = { allowUnfree = true; };
      # };


      lib = nixpkgs.lib;
    in
    {
      homeConfigurations."drishal" = home-manager.lib.homeManagerConfiguration {
        # pkgs = nixpkgs.legacyPackages.${system};
        inherit pkgs;
        modules = [
          ./NixOS/home-config/home.nix
          {nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];}
          hyprland.homeManagerModules.default
          "${private-stuff}/hm-email.nix" # sorry, I cannot reveal email settings and stuff as they are private (dont forget to delete this line)
          {
            home = {
              username = "drishal";
              homeDirectory = "/home/drishal";
              stateVersion = "22.05";
            };
          }
        ];
      };
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          modules = [
            # { nixpkgs.overlays = [ emacs-overlay.overlay ];}
            { nixpkgs.overlays = [ nur.overlay inputs.emacs-overlay.overlay inputs.discord-flake.overlay  ]; }
            # hyprland.nixosModules.default
            ./NixOS/system-config/configuration.nix
            chaotic.nixosModules.default
            # { programs.hyprland.enable = true; }
          ];
          specialArgs = { inherit inputs; };
        };
      };
      packages."x86_64-linux".thorium = pkgs.callPackage ./NixOS/custom-packages/thorium-browser/default.nix {};
      packages."x86_64-linux".qtile= pkgs.callPackage ./NixOS/custom-packages/qtile/default.nix {};

    };
}
