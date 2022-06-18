{
  description = "Configuration for my system";

nixConfig.extra-substituters = [ "https://contamination.cachix.org" "https://nix-community.cachix.org" ];
nixConfig.extra-trusted-public-keys = [ "contamination.cachix.org-1:KmdW5xVF8ccKEb9tvK6qtEMW+lGa83seGgFyBOkeM/4=" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
"];



  inputs = {

    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";

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
      url = "github:nix-community/emacs-overlay/85c0398418b657c2c91ea8a52fcebca3e04529b5";
    };

    mach-nix = {
      url = "github:DavHau/mach-nix";
    };

    private-stuff = {
      url = "path:/home/drishal/.private-stuff";
      flake = false;
    };

  };

  outputs = { nixpkgs, home-manager, discord-flake, nur, emacs-overlay, neovim-nightly-overlay, cachix, declarative-cachix, private-stuff, mach-nix , ... }@inputs:
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
            "${private-stuff}/hm-email.nix" # sorry, I cannot reveal email settings and stuff as they are private (dont forget to delete this line)
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
          ];
          specialArgs = {inherit inputs;};
        };
      };

    };
}
