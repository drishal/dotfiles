import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { sh, closePopup } from "../lib/windows"

type Action = { icon: string; label: string; cmd: string }

const actions: Action[] = [
  { icon: "󰍁", label: "Lock", cmd: "loginctl lock-session" },
  { icon: "󰒲", label: "Suspend", cmd: "systemctl suspend" },
  { icon: "󰍃", label: "Logout", cmd: "hyprctl dispatch exit" },
  { icon: "󰜉", label: "Reboot", cmd: "systemctl reboot" },
  { icon: "󰐥", label: "Shutdown", cmd: "systemctl poweroff" },
]

export default function PowerMenu({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      name={`powermenu-${gdkmonitor.get_connector()}`}
      namespace="ags-powermenu"
      class="ags-powermenu"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="powermenu">
        {actions.map((a) => (
          <button
            class="pm-btn"
            tooltipText={a.label}
            onClicked={() => {
              closePopup("powermenu", gdkmonitor)
              sh(a.cmd)
            }}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4} halign={Gtk.Align.CENTER}>
              <label class="pm-icon" label={a.icon} />
              <label class="pm-label" label={a.label} />
            </box>
          </button>
        ))}
      </box>
    </window>
  )
}
