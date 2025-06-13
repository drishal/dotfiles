{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  virtualisation = {
    # libvirt
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
      qemu.swtpm.enable = true;
      qemu.ovmf.packages = [(pkgs.OVMF.override {
        secureBoot = true;
        tpmSupport = true;
      }).fd
      ];
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    #docker
    #docker.enable = true;

    #podman
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
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
