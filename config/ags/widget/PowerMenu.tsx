import { toggleWindow } from "../lib/window"
import type Gdk from "gi://Gdk"

export default function PowerMenu({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  return (
    <button
      class="module powermenu"
      tooltipText="Power menu"
      onClicked={() => toggleWindow("powermenu", gdkmonitor)}
    >
      {/* nf-md-power */}
      <label class="nerd" label="󰄥" />
    </button>
  )
}
