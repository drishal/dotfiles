{
  description = "Configuration for my system";
  # nixConfig.substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
  # nixConfig.substituters = [ "https://aseipp-nix-cache.freetls.fastly.net" ];
  # nixConfig.extra-substituters = [ "https://contamination.cachix.org" "https://nix-community.cachix.org" ];
  # nixConfig.extra-trusted-public-keys = [ "contamination.cachix.org-1:KmdW5xVF8ccKEb9tvK6qtEMW+lGa83seGgFyBOkeM/4=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  # nixConfig.trusted-users=["root" "drishal"];
  # nixConfig.extra-substituters = [ "https://nix-community.cachix.org" ];
  # nixConfig.extra-trusted-public-keys = [  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {

    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    # nixpkgs-master= { url = "github:nixos/nixpkgs/master"; };

    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
    };

    nix-colors = {
      url = "github:misterio77/nix-colors";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    discord-flake = { url = github:InternetUnexplorer/discord-overlay; };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    declarative-cachix.url = "github:jonascarpay/declarative-cachix";

    # hyprland.url = "github:hyprwm/Hyprland/12d79d63421e2ed3f31130755c7a37f0e4fb5cb1";
    hyprland.url = "github:hyprwm/Hyprland/";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/";
    };

    programsdb = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private-stuff = {
      url = "path:/home/drishal/.private-stuff";
      flake = false;
    };

  };

  outputs = { nixpkgs, chaotic ,home-manager,programsdb, discord-flake, nur, emacs-overlay, cachix, declarative-cachix,hyprland,nix-colors, nixvim, private-stuff, ... }@inputs:
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
          inherit pkgs;
          extraSpecialArgs={inherit inputs;};
          modules = [
            ./NixOS/home-config/home.nix
            {nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];}
            nixvim.homeManagerModules.nixvim
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
        nixosConfigurations =
          let
            commonModules = [
              { nixpkgs.overlays = [ nur.overlay inputs.emacs-overlay.overlay inputs.discord-flake.overlay inputs.neovim-nightly-overlay.overlay]; }
              ./NixOS/system-config/hardware-configuration/hardware-configuration-desktop.nix
              ./NixOS/system-config/configuration.nix
              chaotic.nixosModules.default
            ];
          in
            {
              nixos-desktop = lib.nixosSystem {
                inherit system;
                modules = commonModules ++ [
                  ./NixOS/system-config/hardware-configuration/hardware-configuration-desktop.nix
                ];
                specialArgs = { inherit inputs; };
              };
              nixos = lib.nixosSystem {
                inherit system;
                modules = commonModules ++ [
                  ./NixOS/system-config/hardware-configuration/hardware-configuration-laptop.nix
                ];
                specialArgs = { inherit inputs; };
              };
            };

        # nixosConfigurations = {
        #   nixos = lib.nixosSystem {
        #     inherit system;
        #     modules = [
        #       # { nixpkgs.overlays = [ emacs-overlay.overlay ];}
        #       { nixpkgs.overlays = [ nur.overlay inputs.emacs-overlay.overlay inputs.discord-flake.overlay]; }
        #       # hyprland.nixosModules.default
        #       ./NixOS/system-config/hardware-configuration/hardware-configuration-laptop.nix
        #       ./NixOS/system-config/configuration.nix
        #       chaotic.nixosModules.default
        #       # { programs.hyprland.enable = true; }
        #     ];
        #     specialArgs = { inherit inputs; };
        #   };
        # };
        # packages."x86_64-linux".thorium = pkgs.callPackage ./NixOS/custom-packages/thorium-browser/default.nix {};
        # packages."x86_64-linux".qtile= pkgs.callPackage ./NixOS/custom-packages/qtile/default.nix {};
        # packages."x86_64-linux".freedownloadmanager= pkgs.callPackage ./NixOS/custom-packages/free-download-manager/default.nix {};

      };
}
