{ config, pkgs, inputs, lib, ... }:

{
  virtualisation = {
    # libvert
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
      # qemuOvmf = true;
      qemu.swtpm.enable = true;
      # qemu.ovmf.package = pkgs.OVMFFull;
    };

    #docker
    docker.enable = true;

    #waydroid
    # waydroid.enable = true;
    # lxd.enable = true;


    # virtualbox
    # virtualbox.host.enable = true;

    #podman
    # podman = {
    #   enable = true;
    # };
  };

  users.extraGroups.vboxusers.members = [ "drishal" ];

}
