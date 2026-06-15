import AstalNotifd from "gi://AstalNotifd"
import { createBinding } from "ags"
import { toggleWindow } from "../lib/window"
import type Gdk from "gi://Gdk"

export default function Notifications({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const notifd = AstalNotifd.get_default()
  const list = createBinding(notifd, "notifications")
  const dnd = createBinding(notifd, "dontDisturb")
  const count = list((n) => n.length)

  return (
    <button
      class="module notifications"
      tooltipText="Notifications"
      onClicked={() => toggleWindow("notifications", gdkmonitor)}
    >
      <box spacing={5}>
        <label class="nerd icon" label={dnd((d) => (d ? "󰂛" : "󰂚"))} />
        <label label={count((c) => `${c}`)} visible={count((c) => c > 0)} />
      </box>
    </button>
  )
}
