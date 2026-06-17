import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, For, onCleanup } from "ags"
import AstalNotifd from "gi://AstalNotifd"
import GLib from "gi://GLib"
import Pango from "gi://Pango"

// How long a transient popup lingers before sliding out of the corner. It stays
// in the notification center either way — this only hides the popup. Critical
// popups never auto-hide (mirrors the old end-rs reaper behaviour).
const TIMEOUT_MS = 5000

function time(unix: number) {
  try {
    return GLib.DateTime.new_from_unix_local(unix).format("%H:%M") ?? ""
  } catch (_e) {
    return ""
  }
}

// ── shared popup state ──────────────────────────────────────────────────────
// One subscription to notifd, regardless of how many monitors render popups.
// Each monitor's window renders its own widgets from this single source.
const notifd = AstalNotifd.get_default()
const [popups, setPopups] = createState(new Array<AstalNotifd.Notification>())
const timers = new Map<number, number>()

function clearTimer(id: number) {
  const t = timers.get(id)
  if (t) GLib.source_remove(t)
  timers.delete(id)
}
function remove(id: number) {
  clearTimer(id)
  setPopups((ns) => ns.filter((n) => n.id !== id))
}

notifd.connect("notified", (_, id, replaced) => {
  if (notifd.dontDisturb) return
  const n = notifd.get_notification(id)
  if (!n) return

  if (replaced && popups.get().some((p) => p.id === id)) {
    setPopups((ns) => ns.map((p) => (p.id === id ? n : p)))
  } else {
    setPopups((ns) => [n, ...ns])
  }

  clearTimer(id)
  if (n.urgency !== AstalNotifd.Urgency.CRITICAL) {
    timers.set(
      id,
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, TIMEOUT_MS, () => {
        remove(id)
        return GLib.SOURCE_REMOVE
      }),
    )
  }
})

notifd.connect("resolved", (_, id) => remove(id))

// ── popup card ──────────────────────────────────────────────────────────────
// Drop the implicit "default" action and label-less actions (they'd render as
// empty full-width buttons).
function visibleActions(n: AstalNotifd.Notification) {
  return n.actions.filter((a) => a.id !== "default" && (a.label?.trim() ?? "") !== "")
}

function Popup({ n }: { n: AstalNotifd.Notification }) {
  const hasImage = !!n.image && GLib.file_test(n.image, GLib.FileTest.EXISTS)
  const actions = visibleActions(n)
  return (
    <box
      class={n.urgency === AstalNotifd.Urgency.CRITICAL ? "Notification critical" : "Notification"}
      orientation={Gtk.Orientation.VERTICAL}
      widthRequest={400}
    >
      <box class="header">
        {(n.appIcon || n.desktopEntry) && (
          <image class="app-icon" iconName={n.appIcon || n.desktopEntry} />
        )}
        <label class="app-name" halign={Gtk.Align.START} hexpand ellipsize={Pango.EllipsizeMode.END} label={n.appName || "Notification"} />
        <label class="time" halign={Gtk.Align.END} label={time(n.time)} />
        <button onClicked={() => n.dismiss()}>
          <label label="󰅖" />
        </button>
      </box>
      <box class="content">
        {hasImage && <image class="image" file={n.image} valign={Gtk.Align.START} />}
        <box orientation={Gtk.Orientation.VERTICAL} hexpand>
          <label class="summary" halign={Gtk.Align.START} xalign={0} ellipsize={Pango.EllipsizeMode.END} label={n.summary || ""} />
          {n.body && (
            <label class="body" halign={Gtk.Align.START} xalign={0} wrap useMarkup maxWidthChars={36} label={n.body} />
          )}
        </box>
      </box>
      {actions.length > 0 && (
        <box class="actions" homogeneous>
          {actions.map(({ label, id }) => (
            <button hexpand onClicked={() => n.invoke(id)}>
              <label label={label} halign={Gtk.Align.CENTER} hexpand />
            </button>
          ))}
        </box>
      )}
    </box>
  )
}

// One popup stack per monitor (rendered inside app.tsx's per-monitor loop).
export default function NotificationPopups({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP } = Astal.WindowAnchor
  onCleanup(() => win?.destroy())

  return (
    <window
      $={(self) => (win = self)}
      name={`notification-popups-${gdkmonitor.get_connector()}`}
      namespace="ags-notification-popups"
      class="NotificationPopups"
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP}
      visible={popups((ns) => ns.length > 0)}
      application={app}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        <For each={popups}>{(n) => <Popup n={n} />}</For>
      </box>
    </window>
  )
}
