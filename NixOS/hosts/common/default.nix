{ ... }:
{
  imports = [
    ./base.nix
    ./gui.nix
    ./nix.nix
    ./packages.nix
    ./users.nix
    ./virtualisation.nix
    ./searx.nix
    # ./firewall.nix
    # ./tlp.nix
    ../../shared/stylix.nix
  ];

  system.stateVersion = "23.05";
}
