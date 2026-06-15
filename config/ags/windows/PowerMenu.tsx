import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import type Gdk from "gi://Gdk"

const LOCK =
  "swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5"

type Action = { icon: string; label: string; cmd: string }

const actions: Action[] = [
  { icon: "system-lock-screen-symbolic", label: "Lock", cmd: LOCK },
  { icon: "system-log-out-symbolic", label: "Logout", cmd: "hyprctl dispatch exit" },
  { icon: "system-suspend-symbolic", label: "Suspend", cmd: "systemctl suspend" },
  { icon: "system-reboot-symbolic", label: "Reboot", cmd: "systemctl reboot" },
  { icon: "system-shutdown-symbolic", label: "Shutdown", cmd: "systemctl poweroff" },
]

export default function PowerMenu({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`powermenu-${gdkmonitor.get_connector()}`}
      namespace="ags-powermenu"
      class="ags-window ags-powermenu-window"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="ags-window-content power-popover" spacing={2}>
        {actions.map((a) => (
          <button
            tooltipText={a.label}
            onClicked={() => execAsync(["bash", "-c", a.cmd]).catch(console.error)}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <image class="pm-icon" iconName={a.icon} />
              <label class="dim" label={a.label} />
            </box>
          </button>
        ))}
      </box>
    </window>
  )
}
