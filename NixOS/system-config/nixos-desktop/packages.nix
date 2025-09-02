{ pkgs, inputs, ... }:

{
  networking.enableIPv6  = false;
  # environment.systemPackages = with pkgs; [
    # inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
    # inputs.nix-gaming.packages.${pkgs.system}.winetricks-git
  # ];

  #postgresql
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    # CREATE ROLE drishal WITH LOGIN PASSWORD 'catuserbot' CREATEDB;
    # CREATE DATABASE catuserbot;
    # GRANT ALL PRIVILEGES ON DATABASE catuserbot TO drishal;
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE drishal WITH LOGIN PASSWORD 'aiphonepass' CREATEDB;
      CREATE DATABASE aiphone;
      GRANT ALL PRIVILEGES ON DATABASE aiphone TO drishal;
    '';
  };


}
