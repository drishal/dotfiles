{ config, pkgs, inputs, lib, ... }:

{
  virtualisation = {
    # libvert
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };

    #docker
    docker.enable = true;

    # virtualbox
    virtualbox.host.enable = true;
  };

  users.extraGroups.vboxusers.members = [ "drishal" ];

}
