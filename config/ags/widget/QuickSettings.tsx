import { toggleWindow } from "../lib/window"
import type Gdk from "gi://Gdk"

export default function QuickSettings({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  return (
    <button
      class="module controlcenter"
      tooltipText="Control center"
      onClicked={() => toggleWindow("quicksettings", gdkmonitor)}
    >
      {/* nf-md-volume-high */}
      <label class="nerd icon" label="󰕾" />
    </button>
  )
}
