{ pkgs,lib, ... }:

{
  environment.systemPackages = with pkgs; [
    go
  ];
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

}
