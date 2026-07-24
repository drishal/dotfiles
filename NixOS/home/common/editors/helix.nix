{
  inputs,
  pkgs,
  ...
}:

# Helix, via the steelix fork (helix + Steel scheme plugins)
{
  programs.helix = {
    enable = true;
    package = pkgs.steelix;

    settings = {
      theme = "gruvbox_dark_hard";

      editor = {
        bufferline = "multiple";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "block";
        };
      };

      # vim.hx owns the vim emulation; only helix-native extras it doesn't cover live here
      keys.normal = {
        C-o = ":config-open";
        A-r = ":config-reload"; # C-r is vim's redo, taken by vim.hx
        C-h = "select_prev_sibling";
        C-j = "shrink_selection";
        C-k = "expand_selection";
        C-l = "select_next_sibling";
      };
    };

    languages = {
      language-server.steel-language-server.command = "steel-language-server";
      language = [
        {
          name = "scheme";
          language-servers = [ "steel-language-server" ];
        }
      ];
    };
  };

  # steel repl, forge package manager, steel-language-server
  home.packages = [ pkgs.steel ];

  xdg.configFile = {
    # vendored instead of `forge pkg install` — forge writes to STEEL_HOME, which is a store path
    "helix/cogs/vim-hx".source = inputs.vim-hx;

    # loaded before init.scm; anything exported here becomes a `:typed-command`
    "helix/helix.scm".text = ''
      (require (prefix-in helix. "helix/commands.scm"))
      (require (prefix-in helix.static. "helix/static.scm"))

      (provide open-helix-scm open-init-scm)

      ;;@doc
      ;; Open helix.scm
      (define (open-helix-scm)
        (helix.open (helix.static.get-helix-scm-path)))

      ;;@doc
      ;; Open init.scm
      (define (open-init-scm)
        (helix.open (helix.static.get-init-scm-path)))
    '';

    "helix/init.scm".text = ''
      (require "cogs/vim-hx/init.scm")
      (set-vim-keybindings!)
    '';
  };
}
