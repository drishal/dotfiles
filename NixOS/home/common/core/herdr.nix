{ inputs, pkgs, ... }:

# herdr writes config.toml from its own settings UI (theme, sound, toast,
# onboarding, channel), so a store symlink breaks those writes. mutableSettings
# merges these values over the file at activation and keeps keys added there.
# Plugins stay hand-managed: their installs are built with cargo/go/bun.
let
  # The locked nixpkgs predates pkgs.herdr, so use the flake's own package. It
  # is the same derivation the NixOS overlay installs, and HM needs the store
  # path for the post-activation `herdr server reload-config`.
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
in
{
  programs.herdr = {
    enable = true;
    package = herdr;

    mutableSettings = true;
    settings = {
      onboarding = false;

      theme.name = "catppuccin";

      ui = {
        sound.enabled = false;
        toast.delivery = "system";
      };

      keys.command = [
        {
          key = "prefix+shift+a";
          type = "plugin_action";
          command = "herdr.auto-title.restart";
          description = "restart auto title";
        }
      ];
    };
  };
}
