{ inputs, pkgs, ... }:

{
  imports = [ inputs.deepseek-harness.nixosModules.default ];

  programs.dsh.enable = true;

  # `mutable`: Nix seeds the profile once, then never touches it, so Settings/`dsh plugin` edits stick.
  programs.dsh.profiles = {
    web = {
      bundles = [ pkgs.dsh.bundles.web-app ];
      mode = "mutable";
    };
    tui = {
      bundles = [ pkgs.dsh.bundles.tui ];
      mode = "mutable";
    };
  };

  programs.dsh.defaultProfile = "nix-web";
}
