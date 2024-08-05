{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  virtualisation = {
    # libvert
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
      # qemuOvmf = true;
      qemu.swtpm.enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      # qemu.ovmf.package = pkgs.OVMFFull;
    };

    #docker
    #docker.enable = true;

    #podman
    podman = {
      enable = true;
      dockerCompat = true;
      # defaultNetwork.dnsname.enable = true;
    };

    #waydroid
    waydroid.enable = true;
    # lxd.enable = true;

    # virtualbox
    # virtualbox.host.enable = true;
    # virtualbox.host.enableExtensionPack = true;

    #podman
    # podman = {
    #   enable = true;
    # };
  };

  # services.kubernetes = {
  #   roles = ["master" "node"];
  #   masterAddress = kubeMasterHostname;
  #   apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
  #   easyCerts = true;
  #   apiserver = {
  #     securePort = kubeMasterAPIServerPort;
  #     advertiseAddress = kubeMasterIP;
  #   };

  #   # use coredns
  #   addons.dns.enable = true;
  # };
  programs.virt-manager.enable = true;

  users.extraGroups.vboxusers.members = [ "drishal" ];
  virtualisation.spiceUSBRedirection.enable = true;
}
