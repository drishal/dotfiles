{
  config,
  inputs,
  pkgs,
  ...
}:
{
  programs.fish = {
    enable = true;
    functions = {
      fish_prompt = "";
      fish_right_prompt = "";
    };
    interactiveShellInit = ''
      for c in normal command keyword quote redirection end error param \
               comment operator escape autosuggestion selection search_match \
               cwd cwd_root user host
          set -eU fish_color_$c 2>/dev/null
      end
      for c in progress prefix completion description
          set -eU fish_pager_color_$c 2>/dev/null
      end

      set -g fish_color_normal        ${config.lib.stylix.colors.base05}
      set -g fish_color_command       ${config.lib.stylix.colors.base0B}
      set -g fish_color_keyword       ${config.lib.stylix.colors.base0D}
      set -g fish_color_quote         ${config.lib.stylix.colors.base0C}
      set -g fish_color_redirection   ${config.lib.stylix.colors.base09}
      set -g fish_color_end           ${config.lib.stylix.colors.base03}
      set -g fish_color_error         ${config.lib.stylix.colors.base08}
      set -g fish_color_param         ${config.lib.stylix.colors.base05}
      set -g fish_color_comment       ${config.lib.stylix.colors.base03}
      set -g fish_color_operator      ${config.lib.stylix.colors.base0B}
      set -g fish_color_escape        ${config.lib.stylix.colors.base0D}
      set -g fish_color_autosuggestion ${config.lib.stylix.colors.base03}
      set -g fish_color_selection     ${config.lib.stylix.colors.base05} --bold --background=${config.lib.stylix.colors.base02}
      set -g fish_color_search_match  --background=${config.lib.stylix.colors.base02}
      set -g fish_color_cwd           ${config.lib.stylix.colors.base0B}
      set -g fish_color_cwd_root      ${config.lib.stylix.colors.base08}
      set -g fish_color_user          ${config.lib.stylix.colors.base0B}
      set -g fish_color_host          ${config.lib.stylix.colors.base05}

      set -g fish_pager_color_progress    ${config.lib.stylix.colors.base0E}
      set -g fish_pager_color_prefix      ${config.lib.stylix.colors.base0C}
      set -g fish_pager_color_completion  ${config.lib.stylix.colors.base05}
      set -g fish_pager_color_description ${config.lib.stylix.colors.base0E}
    '';
    plugins = [
      # {
      #   name = "catppuccin";
      #   src = inputs.catppuccin-fish; # ← directly reference the input
      # }
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      # Manually packaging and enable a plugin
      # {
      #   name = "bass";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "edc";
      #     repo = "Bass";
      #     rev = "79b62958ecf4e87334f24d6743e5766475bcf4d0";
      #     sha256 = "sha256-3d/qL+hovNA4VMWZ0n1L+dSM1lcz7P5CQJyy+/8exTc=";
      #   };
      # }

      # {
      #   name = "fzf-fish";
      #   src = pkgs.fishPlugins.fzf-fish.src;
      # }
    ];
  };
}
