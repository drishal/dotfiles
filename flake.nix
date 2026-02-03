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
    nixpkgs-master.url = "github:NixOS/nixpkgs/88cb04966c1b83706a80a71fc5926082ca5e7792";
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
    ignis = {
      url = "github:ignis-sh/ignis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    # discord-flake = {
    #   url = "github:InternetUnexplorer/discord-overlay";
    # };

    # chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    declarative-cachix.url = "github:jonascarpay/declarative-cachix";

    # hyprland.url = "github:hyprwm/Hyprland";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1/v0.53.3";
    # hyprland.url = "github:hyprwm/Hyprland/v0.53.3";

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

    # ags.url = "github:Aylur/ags";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    umu.url = "github:Open-Wine-Components/umu-launcher?dir=packaging/nix";

    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    aporetic.url = "github:Echinoidea/Aporetic-Nerd-Font";


    # hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
  };

  outputs =
    {
      ags,
      astal,
      auto-cpufreq,
      #base16,
      cachix,
      # chaotic,
      declarative-cachix,
      # discord-flake,
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
      # hyprpanel,
      tt-schemes,
      umu,
      nix-cachyos-kernel,
      ghostty,
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
      name = "myshell.py";

    in
    {
      # homeConfigurations."drisha" = home-manager.lib.homeManagerConfiguration {
      #   inherit pkgs;
      #   extraSpecialArgs = {
      #     inherit inputs;
      #     # inherit pkgs-master;
      #   };
      #   modules = [
      #     ./NixOS/home-config/home.nix
      #     {
      #       nixpkgs.overlays = [
      #         inputs.emacs-overlay.overlay
      #         inputs.hyprpanel.overlay
      #         emacs-lsp-booster.overlays.default
      #       ];
      #     }
      #     # inputs.ags.homeManagerModules.default
      #     #base16.homeManagerModule
      #     nixvim.homeManagerModules.nixvim
      #     stylix.homeManagerModules.stylix
      #     "${private-stuff}/hm-email.nix" # sorry, I cannot reveal email settings and stuff as they are private (dont forget to delete this line)
      #     {
      #       home = {
      #         username = "drishal";
      #         homeDirectory = "/home/drishal";
      #       };
      #     }
      #   ];
      # };
      homeConfigurations =
        let
          commonModules = [
            ./NixOS/home-config/home.nix
            {
              nixpkgs.overlays = [
                # inputs.hyprpanel.overlay
                inputs.emacs-overlay.overlay
                emacs-lsp-booster.overlays.default
              ];
            }
            # inputs.ags.homeManagerModules.default
            #base16.homeManagerModule
            nixvim.homeManagerModules.nixvim
            stylix.homeModules.stylix
            "${private-stuff}/hm-email.nix" # sorry, I cannot reveal email settings and stuff as they are private (dont forget to delete this line)
          ];
          extraSpecialArgs = {
            inherit system;
            inherit inputs;
          };
          user = "drishal";
        in
        {
          "${user}@nixos-desktop" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = commonModules ++ [
              ./NixOS/home-config/nixos-desktop/home.nix
            ];
            extraSpecialArgs = extraSpecialArgs;
          };
          "${user}@nixos" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = commonModules ++ [
            ];
            extraSpecialArgs = extraSpecialArgs;
          };
          "${user}@nixos-work" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = commonModules ++ [
              ./NixOS/home-config/nixos-work/home.nix
            ];
            extraSpecialArgs = extraSpecialArgs;
          };
        };

      nixosConfigurations =
        let
          commonModules = [
            {
              nixpkgs.overlays = [
                # nur.overlay
                inputs.emacs-overlay.overlay
                inputs.nix-cachyos-kernel.overlays.pinned
                # inputs.discord-flake.overlay
                # inputs.neovim-nightly-overlay.overlay
              ];
            }
            ngrok.nixosModules.ngrok
            ./NixOS/system-config/configuration.nix
            auto-cpufreq.nixosModules.default
            # chaotic.nixosModules.default
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
          nixos-work = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              ./NixOS/system-config/nixos-work/hardware-configuration.nix
            ];
            specialArgs = specialArgs;
          };
        };
      # packages.${system}.default = pkgs.stdenv.mkDerivation {
      #   inherit name;
      #   src = ./config/ags;

      #   nativeBuildInputs = with pkgs; [
      #     wrapGAppsHook
      #     gobject-introspection
      #   ];

      #   buildInputs = [
      #     (pkgs.python3.withPackages (ps: [
      #       # any other python package
      #     ps.pygobject3
      #     ]))
      #     astal.packages.${system}.io
      #     astal.packages.${system}.astal3
      #     # any other gi lib
      #   ];

      #   # you shouldn't really copy the whole src to $out/bin
      #   # but for now it works
      #   installPhase = ''
      #   mkdir -p $out/bin
      #   cp * $out/bin
      #   chmod +x $out/bin/${name}
      # '';
      # };
      # devShell.x86_64-linux = nixpkgs.legacyPackages.${system}.mkShell {
      #   buildInputs = with astal.packages.${system}; [
      #     astal3
      #     io
      #   ];
      #   nativeBuildInputs = [
      #     ags.packages.${system}.default
      #     pkgs.wrapGAppsHook
      #   pkgs.gobject-introspection
      #   ];
      # };
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
