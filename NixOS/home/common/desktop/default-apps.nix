{
  config,
  lib,
  pkgs,
  ...
}:

# Single source of truth for default applications. Consumed by:
#   - xdg.mimeApps + xdg.terminal-exec (this file, below)
#   - hyprland.nix / sway.nix keybinds (read `config.drishal.defaultApps`)
#   - quickshell / ags / eww at runtime, via the JSON mirror under
#     ~/.config/drishal/default-apps.json.
#
# Override per-host by setting `drishal.defaultApps.<key> = "..."` in the
# host's home override module.

let
  apps = {
    terminal = "kitty";
    fileManager = "nemo";
    browser = "firefox";
    pdf = "okular";
    media = "mpv";
  };

  desktopId = app: "${apps.${app}}.desktop";
  terminalDesktopId = desktopId "terminal";
  browserDesktopId = desktopId "browser";
  pdfDesktopId = "org.kde.okular.desktop"; # kdePackages.okular ships as org.kde.okular.desktop
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
    default = apps;
    example = apps;
  };

  config = {
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

        # Media — common video/audio types. Wildcards aren't valid in
        # mimeapps.list, so list concrete types mpv actually handles.
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

    # JSON mirror so runtime shells (quickshell/ags/eww) can resolve the
    # same defaults without re-implementing the lookup in TypeScript/QML/Lua.
    xdg.configFile."drishal/default-apps.json".text =
      builtins.toJSON config.drishal.defaultApps;
  };
}
