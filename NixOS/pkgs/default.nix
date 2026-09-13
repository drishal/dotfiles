{ pkgs ? import <nixpkgs> { } }:
{
  thorium-browser = pkgs.callPackage ./thorium-browser { };
  galaxy-buds-client = pkgs.callPackage ./galaxy-buds-client { };
  commit-mono-fixed = pkgs.callPackage ./commit-mono-fixed { };
}
