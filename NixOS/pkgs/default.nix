{ pkgs ? import <nixpkgs> { } }:
{
  thorium-browser = pkgs.callPackage ./thorium-browser { };
  galaxy-buds-client = pkgs.callPackage ./galaxy-buds-client { };
}
