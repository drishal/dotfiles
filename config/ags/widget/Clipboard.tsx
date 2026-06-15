import { execAsync } from "ags/process"

// cliphist + wl-clipboard are provided on the gjs runtime PATH via
// programs.ags.extraPackages. Requires the cliphist store daemon to be running
// (e.g. `wl-paste --watch cliphist store` in your Hyprland autostart).
const PICK = `cliphist list | rofi -dmenu -i -p "clipboard" | cliphist decode | wl-copy`

export default function Clipboard() {
  return (
    <button
      class="clipboard"
      tooltipText="Clipboard history"
      onClicked={() => execAsync(["bash", "-c", PICK]).catch(console.error)}
    >
      {/* nf-md-clipboard_text */}
      <label class="nerd icon" label="󰅍" />
    </button>
  )
}
