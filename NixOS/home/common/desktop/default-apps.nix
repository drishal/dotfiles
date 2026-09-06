{
  config,
  lib,
  pkgs,
  ...
}:

# Single source of truth for default apps: xdg.mimeApps + xdg.terminal-exec below,
# hyprland/sway keybinds, and ~/.config/drishal/default-apps.json for runtime shells.
# Override per-host with `drishal.defaultApps.<key>` in the host's home module.

let
  cfg = config.drishal.defaultApps;

  # Binary name -> .desktop id, only where they differ from "<binary>.desktop".
  desktopIdOverrides = {
    okular = "org.kde.okular.desktop"; # kdePackages.okular
  };
  desktopId = key: desktopIdOverrides.${cfg.${key}} or "${cfg.${key}}.desktop";

  terminalDesktopId = desktopId "terminal";
  browserDesktopId = desktopId "browser";
  pdfDesktopId = desktopId "pdf";
  mediaDesktopId = desktopId "media";
  fileManagerDesktopId = desktopId "fileManager";
in
{
  options.drishal.defaultApps = lib.mkOption {
    description = ''
      Default applications. Keys are the logical app name; values are the
      package/binary name (e.g. "kitty", "nemo"). Used for both MIME
      associations and WM keybinds. Override per-host as needed.
    '';
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      terminal = "kitty";
      browser = "firefox";
    };
  };

  config = {
    # mkDefault per key so overriding one app doesn't drop the others.
    drishal.defaultApps = lib.mapAttrs (_: lib.mkDefault) {
      terminal = "ghostty";
      fileManager = "nemo";
      browser = "firefox";
      pdf = "okular";
      media = "mpv";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # Browser — covers http(s) links, plain HTML, and unknown schemes.
        "text/html" = browserDesktopId;
        "x-scheme-handler/http" = browserDesktopId;
        "x-scheme-handler/https" = browserDesktopId;
        "x-scheme-handler/about" = browserDesktopId;
        "x-scheme-handler/unknown" = browserDesktopId;

        # PDF.
        "application/pdf" = pdfDesktopId;

        # Media — wildcards aren't valid in mimeapps.list, so list concrete types.
        "video/mp4" = mediaDesktopId;
        "video/x-matroska" = mediaDesktopId;
        "video/webm" = mediaDesktopId;
        "video/ogg" = mediaDesktopId;
        "video/mpeg" = mediaDesktopId;
        "video/quicktime" = mediaDesktopId;
        "audio/mpeg" = mediaDesktopId;
        "audio/flac" = mediaDesktopId;
        "audio/ogg" = mediaDesktopId;
        "audio/wav" = mediaDesktopId;
        "audio/mp4" = mediaDesktopId;

        # File manager.
        "inode/directory" = fileManagerDesktopId;

        # "Open terminal here" actions / xdg-terminal-exec consumers.
        "x-scheme-handler/terminal" = terminalDesktopId;
      };
    };

    # Default Terminal Execution Specification — per-DE resolution of the
    # `xdg-terminal-exec` program (used by foot, kitty, wezterm, etc.).
    xdg.terminal-exec = {
      enable = true;
      package = pkgs.xdg-terminal-exec;
      settings = {
        default = [ terminalDesktopId ];
        Hyprland = [ terminalDesktopId ];
        sway = [ terminalDesktopId ];
      };
    };

    # JSON mirror so runtime shells (quickshell/ags/eww) can resolve the same
    # defaults without re-implementing the lookup. Nothing reads it yet.
    xdg.configFile."drishal/default-apps.json".text = builtins.toJSON cfg;
  };
}
