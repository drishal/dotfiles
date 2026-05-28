{ pkgs, lib, ... }:
{
  virtualisation = {
    #disable podman on work system
    podman.enable = lib.mkForce false;

    #enable docker
    docker.enable = true;
  };
}
