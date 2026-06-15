import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"
import { toggleWindow } from "../lib/window"
import type Gdk from "gi://Gdk"

export default function Clock({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  // Date format mirrors the old DMS bar: "Mon 16 Jun".
  const date = createPoll("", 30_000, () =>
    GLib.DateTime.new_now_local().format("%a %d %b")!,
  )
  const time = createPoll("", 1000, () =>
    GLib.DateTime.new_now_local().format("%H:%M:%S")!,
  )

  return (
    <button
      class="module clock"
      tooltipText="Calendar"
      onClicked={() => toggleWindow("calendar", gdkmonitor)}
    >
      <box spacing={8}>
        <label class="date" label={date} />
        <label class="time" label={time} />
      </box>
    </button>
  )
}
