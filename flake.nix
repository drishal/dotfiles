
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
      url = "github:nixos/nixpkgs/nixos-unstable/";
    };
    nixpkgs-master.url = "github:NixOS/nixpkgs/a46925097143c5535a814c0d9ca53b29fb2a5d1d";
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
    # emacs-ng.url = "github:emacs-ng/emacs-ng";

    programsdb = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickemu = {
      url = "github:quickemu-project/quickemu";
    };


    private-stuff = {
      url = "git+file:/home/drishal/.private-stuff/";
      flake = false;
    };

    ags.url = "github:Aylur/ags";
    astal.url = "github:astal-sh/libastal";

    lobster.url = "github:justchokingaround/lobster";

    #base16.url = "github:SenchoPens/base16.nix";

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
    stylix = {
      url = "github:danth/stylix/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";
    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nvchad-starter.follows = "nvchad-starter";
    };
    nvchad-starter = {
      url = "github:NvChad/starter";
      flake = false;
    };
    # nvchad-on-steroids = {  # <- here
    #   url = "github:MOIS3Y/nvchad-on-steroids";
    #   flake = false;
    # };
    umu= {
      url = "git+https://github.com/Open-Wine-Components/umu-launcher/?dir=packaging\/nix&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      ags,
      astal,
      auto-cpufreq,
      #base16,
      cachix,
      chaotic,
      declarative-cachix,
      discord-flake,
      emacs-lsp-booster,
      # emacs-ng,
      emacs-overlay,
      eww,
      home-manager,
      hyprland,
      nixpkgs,
      nixpkgs-master,
      nixvim,
      nix-gaming,
      ngrok,
      # nvchad4nix,
      # nvchad-on-steroids,
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

      pkgs-master = import nixpkgs-master {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      lib = nixpkgs.lib;

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
          #base16.homeManagerModule
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
            #base16.nixosModule
          ];
          specialArgs = {
            inherit inputs;
            inherit pkgs-master;
          };
        in
          {
          nixos-desktop = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              ./NixOS/system-config/nixos-desktop/hardware-configuration.nix
            ];
            specialArgs = specialArgs;
          };
          nixos = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              ./NixOS/system-config/nixos/hardware-configuration.nix
            ];
            specialArgs = specialArgs;
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
