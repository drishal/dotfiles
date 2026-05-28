{ ... }:

{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      8022
      8000
    ];
  };

  programs.steam = {
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  services = {
    avahi.openFirewall = true;
    tailscale.openFirewall = true;
  };
}
