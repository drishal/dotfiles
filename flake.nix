{
  description = "Configuration for my system";
  nixConfig.substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
  # nixConfig.substituters = [ "https://aseipp-nix-cache.freetls.fastly.net" ];
  # nixConfig.extra-substituters = [ "https://contamination.cachix.org" "https://nix-community.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "contamination.cachix.org-1:KmdW5xVF8ccKEb9tvK6qtEMW+lGa83seGgFyBOkeM/4=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
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

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    declarative-cachix.url = "github:jonascarpay/declarative-cachix";

    hyprland.url = "github:hyprwm/Hyprland/f27873a6f06dc2f87600edb890f3c38298bfb55f";
    # hyprland.url = "github:hyprwm/Hyprland/1c50a11688451049185baae3109ddc87a268a75e";

    emacs-overlay = {
      # url = "github:nix-community/emacs-overlay";
      # url = "github:nix-community/emacs-overlay/23488bbca5ea0012bafa2c75b88902b540ff9940";
      url = "github:nix-community/emacs-overlay/42a2a718bdcbe389e7ef284666d4aba09339a416";
    };

    private-stuff = {
      url = "path:/home/drishal/.private-stuff";
      flake = false;
    };

  };

  outputs = { nixpkgs, home-manager, discord-flake, nur, emacs-overlay, cachix, declarative-cachix,hyprland,  private-stuff, ... }@inputs:
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
            # { programs.hyprland.enable = true; }
          ];
          specialArgs = { inherit inputs; };
        };
      };

    };
}
