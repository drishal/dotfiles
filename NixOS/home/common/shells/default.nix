{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.direnv-instant.homeModules.direnv-instant
    ./zsh.nix
    ./fish.nix
  ];

  programs.nushell = {
    enable = true;
  };

  # Kept zsh-only for now while bringing zsh completions on par with fish.
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
      nix_shell.symbol = "❄ ";
    };
  };
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
        if [ -x /usr/bin/ccache ]; then
          export USE_CCACHE=1
          export CCACHE_EXEC=/usr/bin/ccache
      fi
    '';
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  # programs.direnv-instant.enable = true;

  # PATH shared across all shells (replaces per-shell fish_add_path / export PATH).
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/bin/platform-tools"
    "$HOME/.node_modules/bin"
    "$HOME/.nimble/bin"
    "$HOME/.cargo/bin"
  ];

  # Shell-agnostic env vars; Home Manager wires these into fish, bash and zsh.
  home.sessionVariables = {
    EZA_ICON_SPACING = "2";
    EDITOR = "nvim";
    MANROFFOPT = "-c";
    MANPAGER = "sh -c 'col -bx | bat -plman'";
    LUTRIS_SKIP_INIT = "1";

    CCACHE_DIR = "${config.home.homeDirectory}/.ccache";
    CCACHE_MAXSIZE = "100G";

    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true"; # NixOS-specific: skips glibc/os checks
    PLAYWRIGHT_HOST_PLATFORM_OVERRIDE = "ubuntu-24.04"; # helps with version compatibility
  };
}
