{
  description = "Configuration for my system";
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

    nixpkgs-master.url = "github:NixOS/nixpkgs/9b7a014c9083e9d625b8300313f13b20d4043dca";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nur.url = "github:nix-community/NUR";

    cachix.url = "github:cachix/cachix";

    hyprland.url = "github:hyprwm/Hyprland";

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/";
    };
    emacs-lsp-booster.url = "github:slotThe/emacs-lsp-booster-flake";

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

    lobster.url = "github:justchokingaround/lobster";

    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };

    stylix = {
      url = "github:nix-community/stylix/";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tmux-powerkit = {
      url = "github:fabioluciano/tmux-powerkit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    umu.url = "github:Open-Wine-Components/umu-launcher?dir=packaging/nix";

    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";

    direnv-instant.url = "github:Mic92/direnv-instant";

    ani-cli = {
      url = "github:pystardust/ani-cli";
      flake = false;
    };

    # neovim plugins
    gruvbox-material = {
      url = "github:sainnhe/gruvbox-material";
      flake = false;
    };

    dms.url = "github:AvengeMedia/DankMaterialShell";
    end-rs.url = "github:Dr-42/end-rs";
    llama-cpp.url = "github:ggml-org/llama.cpp";

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      chaotic,
      emacs-lsp-booster,
      emacs-overlay,
      home-manager,
      hyprland,
      nixpkgs,
      nixpkgs-master,
      nixvim,
      nix-gaming,
      nur,
      private-stuff,
      programsdb,
      quickemu,
      stylix,
      tt-schemes,
      umu,
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
       homeConfigurations =
        let
          commonModules = [
            ./NixOS/home/common
            {
              nixpkgs.overlays = [
                # inputs.hyprpanel.overlay
                inputs.emacs-overlay.overlay
                emacs-lsp-booster.overlays.default

              ];
            }
            nixvim.homeModules.nixvim
            stylix.homeModules.stylix
            "${private-stuff}/hm-email.nix"
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
              ./NixOS/home/nixos-desktop
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
              ./NixOS/home/nixos-work
            ];
            extraSpecialArgs = extraSpecialArgs;
          };
        };

      nixosConfigurations =
        let
          commonModules = [
            {
              nixpkgs.overlays = [
                inputs.emacs-overlay.overlay
              ];
            }
            # chaotic.nixosModules.default
            stylix.nixosModules.stylix
            chaotic.nixosModules.nyx-cache
            chaotic.nixosModules.nyx-overlay
            chaotic.nixosModules.nyx-registry
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
              ./NixOS/hosts/nixos-desktop
            ];
            specialArgs = specialArgs;
          };
          nixos = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              ./NixOS/hosts/nixos
            ];
            specialArgs = specialArgs;
          };
          nixos-work = lib.nixosSystem {
            inherit system;
            modules = commonModules ++ [
              ./NixOS/hosts/nixos-work
            ];
            specialArgs = specialArgs;
          };
        };
      # packages."x86_64-linux".thorium = pkgs.callPackage ./NixOS/custom-packages/thorium-browser/default.nix {};
      # packages."x86_64-linux".qtile= pkgs.callPackage ./NixOS/custom-packages/qtile/default.nix {};
      # packages."x86_64-linux".freedownloadmanager= pkgs.callPackage ./NixOS/custom-packages/free-download-manager/default.nix {};
    };
}
