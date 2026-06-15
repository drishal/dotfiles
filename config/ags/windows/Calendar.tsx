import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"

export default function Calendar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      name={`calendar-${gdkmonitor.get_connector()}`}
      namespace="ags-calendar"
      class="ags-window ags-calendar-window"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="ags-window-content">
        <Gtk.Calendar />
      </box>
    </window>
  )
}
