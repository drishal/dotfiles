{ pkgs,lib, ... }:

{
  environment.systemPackages = with pkgs; [
    go
  ];
}
