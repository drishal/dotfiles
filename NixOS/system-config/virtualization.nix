{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            pkgs.OVMFFull
            pkgs.edk2
            # (pkgs.OVMF.override {
            # secureBoot = true;
            # tpmSupport = true;
            # }).fd
          ];
        };
      };
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
    environment = {
      etc = {
        "ovmf/edk2-x86_64-secure-code.fd" = {
          source = "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-x86_64-secure-code.fd";
        };

        "ovmf/edk2-i386-vars.fd" = {
          source = "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-i386-vars.fd";
          mode = "0644";
          user = "libvirtd";
        };
      };
    };


}
