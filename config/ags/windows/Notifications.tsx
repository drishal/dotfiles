import app from "ags/gtk4/app"
import AstalNotifd from "gi://AstalNotifd"
import { Astal, Gtk } from "ags/gtk4"
import { createBinding, For } from "ags"
import type Gdk from "gi://Gdk"

export default function Notifications({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const notifd = AstalNotifd.get_default()
  const list = createBinding(notifd, "notifications")
  const dnd = createBinding(notifd, "dontDisturb")
  const count = list((n) => n.length)
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      name={`notifications-${gdkmonitor.get_connector()}`}
      namespace="ags-notifications"
      class="ags-window ags-notifications-window"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="ags-window-content" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <box class="notif-header" spacing={8}>
          <label label="Notifications" hexpand xalign={0} />
          <button onClicked={() => (notifd.dontDisturb = !notifd.dontDisturb)}>
            <label class="dim" label={dnd((d) => (d ? "DND: on" : "DND: off"))} />
          </button>
          <button onClicked={() => list.get().forEach((n) => n.dismiss())}>
            <label class="dim" label="Clear" />
          </button>
        </box>

        <For each={list}>
          {(n) => (
            <box class="notif-item" orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              <box spacing={6}>
                <label class="notif-app" label={n.appName || "system"} xalign={0} hexpand />
                <button onClicked={() => n.dismiss()}>
                  <label class="dim" label="✕" />
                </button>
              </box>
              <label class="notif-summary" label={n.summary || ""} xalign={0} wrap maxWidthChars={34} />
              <label
                class="notif-body"
                label={n.body || ""}
                xalign={0}
                wrap
                maxWidthChars={34}
                visible={!!n.body}
              />
            </box>
          )}
        </For>

        <label class="dim" label="No notifications" visible={count((c) => c === 0)} />
      </box>
    </window>
  )
}
