{
  description = "Configuration for my sysmem";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      lib = nixpkgs.lib;
    in {
      homeManagerConfigurations = {
        drishal = home-manager.lib.homeManagerConfigurations {
          inherit system pkgs;
          username = "drisal";
          homeDirectory = "/home/drishal";
          configuration = {
            imports = [
              ./NixOS/home.nix
            ];
          };
        };
      };
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;

          modules = [
            ./NixOS/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              #home-manager.users.hugosum = import ./home-manager.nix;
            }
            #./hardware-configuration.nix
          ];
        };
      };
    };
}
