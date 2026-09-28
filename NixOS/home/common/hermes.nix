# Imported from NixOS/home/common/default.nix.
# flake.nix input: hermes-agent.url = "github:NousResearch/hermes-agent";
#
# Does not set environment or environmentFiles. Either one rewrites ~/.hermes/.env
# from scratch. Does not set configFile: that overwrites config.yaml every
# activation. Does not set settings: Nix keys replace the same keys on disk,
# and memory.provider is already mnemosyne there. An empty settings attrset
# still deep-merges terminal.cwd = $HOME into config.yaml.
#
# Enabling the service writes ~/.hermes/.managed and blocks `hermes config set`,
# `hermes setup`, and `hermes gateway install`. The new unit is
# hermes-agent.service. The hand unit hermes-gateway.service is not managed here.
#
# Mnemosyne cannot ride this package. nixpkgs#mnemosyne is the spaced-repetition
# app. The live plugin is a dangling symlink into the deleted checkout venv
# (~/.hermes/plugins/mnemosyne -> hermes-agent/.venv/.../mnemosyne_hermes).
# mnemosyne-hermes is an entry-point package (hermes_agent.memory_providers),
# and the Nix hermes venv is sealed, so pip into it does not stick. extraPlugins
# of the git tree only drops plugin.yaml; Hermes still has to import
# mnemosyne_hermes. The path that survives a sealed runtime is their wrapper
# mode: a side venv outside the store, same Python major.minor as the nix
# hermes binary (not the old 3.12 checkout), then
#   mnemosyne-hermes install --mode wrapper --python "$VENV/bin/python"
# That writes a real plugins/mnemosyne directory. Activation only deletes
# plugins/nix-managed-* symlinks, so that directory is left alone. Not wired.
{ inputs, ... }:
{
  imports = [ inputs.hermes-agent.homeManagerModules.default ];

  programs.hermes-agent.enable = true;

  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
  };
}
