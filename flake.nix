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
      # "https://emacsng.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "emacsng.cachix.org-1:i7wOr4YpdRpWWtShI8bT6V7lOTnPeI7Ho6HaZegFWMI="
    ];
  };
  inputs = {

    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    # nixpkgs = { url = "github:PedroHLC/nixpkgs/pull-284487"; };
    # nixpkgs-master = {
    #   url = "github:nixos/nixpkgs/9b5ca6a80c775a62734e1fefa0d04f1b0c91c91b";
    # };

    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    discord-flake = {
      url = "github:InternetUnexplorer/discord-overlay";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    declarative-cachix.url = "github:jonascarpay/declarative-cachix";

    # hyprland.url = "github:hyprwm/Hyprland/v0.40.0";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/";
    };
    emacs-lsp-booster.url = "github:slotThe/emacs-lsp-booster-flake";
    emacs-ng.url = "github:emacs-ng/emacs-ng";

    programsdb = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickemu = {
      url = "github:quickemu-project/quickemu";
    };


    private-stuff = {
      url = "path:/home/drishal/.private-stuff";
      flake = false;
    };

    ags.url = "github:Aylur/ags";
    astal.url = "github:astal-sh/libastal";

    lobster.url = "github:justchokingaround/lobster";

    base16.url = "github:SenchoPens/base16.nix";

    ngrok.url = "github:ngrok/ngrok-nix";

    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    eww = {
      url = "github:elkowar/eww";
    };
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
  };

  outputs =
    {
      # nixpkgs-master,
      ags,
      astal,
      auto-cpufreq,
      base16,
      cachix,
      chaotic,
      declarative-cachix,
      discord-flake,
      emacs-lsp-booster,
      emacs-ng,
      emacs-overlay,
      eww,
      home-manager,
      hyprland,
      nixpkgs,
      nixvim,
      ngrok,
      nur,
      private-stuff,
      programsdb,
      quickemu,
      stylix,
      tt-schemes,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      # pkgs-master = import nixpkgs-master {
      #   inherit system;
      #   config = {
      #     allowUnfree = true;
      #   };
      # };
      lib = nixpkgs.lib;

      # here we would define some variables for stylix so we can use it across both home manager and system-configuration
      # wallpaper = ./wallpapers/summer_1am.jpg;
    in
    {
      homeConfigurations."drishal" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          # inherit pkgs-master;
        };
        modules = [
          ./NixOS/home-config/home.nix
          { nixpkgs.overlays = [ inputs.emacs-overlay.overlay emacs-lsp-booster.overlays.default ]; }
          # inputs.ags.homeManagerModules.default
          base16.homeManagerModule
          nixvim.homeManagerModules.nixvim
          stylix.homeManagerModules.stylix
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
            {
              nixpkgs.overlays = [
                nur.overlay
                inputs.emacs-overlay.overlay
                inputs.discord-flake.overlay
                # inputs.neovim-nightly-overlay.overlay
              ];
            }
            ngrok.nixosModules.ngrok
            ./NixOS/system-config/configuration.nix
            auto-cpufreq.nixosModules.default
            chaotic.nixosModules.default
            stylix.nixosModules.stylix
          ];
        in
        {
          nixos-desktop = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              # ./NixOS/system-config/hardware-configuration/hardware-configuration-desktop.nix
            ];
            specialArgs = {
              inherit inputs;
            };
          };
          nixos = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              ./NixOS/system-config/nixos/hardware-configuration.nix
            ];
            specialArgs = {
              inherit inputs;
            };
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
