{ ... }:

{
  wayland.windowManager.sway.config = {
    # --- Output/Monitor config (from hyprland: DP-1 + DP-2, both 1080p) ---
    output = {
      "DP-1" = {
        mode = "1920x1080";
        pos = "0 0";
        scale = "1";
      };
      "DP-2" = {
        mode = "1920x1080";
        pos = "1920 0";
        scale = "1";
      };
    };

    # --- Workspace → output assignments ---
    workspaceOutputAssign = [
      { workspace = "1"; output = "DP-1"; }
      { workspace = "2"; output = "DP-1"; }
      { workspace = "3"; output = "DP-1"; }
      { workspace = "4"; output = "DP-1"; }
      { workspace = "5"; output = "DP-1"; }
      { workspace = "6"; output = "DP-2"; }
      { workspace = "7"; output = "DP-2"; }
      { workspace = "8"; output = "DP-2"; }
      { workspace = "9"; output = "DP-2"; }
      { workspace = "10"; output = "DP-2"; }
    ];
  };
}
