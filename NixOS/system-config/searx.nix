{ config, pkgs, inputs, lib, ... }:

{
  services.searx = {
    enable=false;
    settings = {
      server.port="8888";
      server.bind_address = "127.0.0.1";
      server.secret_key = "@SEARX_SECRET_KEY@";
    };
  };
}
