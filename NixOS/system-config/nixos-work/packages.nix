{ pkgs,lib, ... }:

{
  environment.systemPackages = with pkgs; [
    go
  ];
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };
  # Service - WARNING: Open to public!
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    chrootlocalUser = true;
    allowWriteableChroot = true;
  };
}
