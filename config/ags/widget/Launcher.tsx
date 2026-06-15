import { execAsync } from "ags/process"

// Reuses the existing rofi setup (see hyprland.nix SUPER+D).
const LAUNCH = "rofi -show drun -icon-theme Papirus -show-icons"

export default function Launcher() {
  return (
    <button
      class="launcher"
      tooltipText="App launcher"
      onClicked={() => execAsync(["bash", "-c", LAUNCH]).catch(console.error)}
    >
      {/* nf-md-snowflake (NixOS-ish, MDI range renders reliably) */}
      <label class="nerd" label="󰜗" />
    </button>
  )
}
