import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { onCleanup } from "ags"

import Launcher from "./Launcher"
import Workspaces from "./Workspaces"
import FocusedWindow from "./FocusedWindow"
import Clock from "./Clock"
import Notifications from "./Notifications"
import Clipboard from "./Clipboard"
import SysInfo from "./SysInfo"
import Battery from "./Battery"
import QuickSettings from "./QuickSettings"
import PowerMenu from "./PowerMenu"
import Tray from "./Tray"
import Weather from "./Weather"

// Widget placement mirrors the old dms.nix bar:
//   left   → launcher · workspaces · focused window
//   center → clock · notifications
//   right  → clipboard · cpu/mem · battery · control center · power · tray
export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  // Windows aren't auto-destroyed on monitor unplug; the <For> cleanup handles it.
  onCleanup(() => win?.destroy())

  return (
    <window
      $={(self) => (win = self)}
      visible
      name="ags-bar"
      namespace="ags-bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="bar-inner">
        <box $type="start" spacing={8} halign={Gtk.Align.START}>
          <Launcher />
          <Workspaces />
          <FocusedWindow />
        </box>

        <box $type="center" spacing={8}>
          <Clock gdkmonitor={gdkmonitor} />
          <Notifications gdkmonitor={gdkmonitor} />
        </box>

        <box $type="end" spacing={8} halign={Gtk.Align.END}>
          <Weather />
          <Clipboard />
          <SysInfo />
          <Battery />
          <QuickSettings gdkmonitor={gdkmonitor} />
          <PowerMenu gdkmonitor={gdkmonitor} />
          <Tray />
        </box>
      </centerbox>
    </window>
  )
}
