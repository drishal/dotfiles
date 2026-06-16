import app from "ags/gtk4/app"
import AstalNotifd from "gi://AstalNotifd"
import GLib from "gi://GLib"
import { Astal, Gtk } from "ags/gtk4"
import { createBinding, For } from "ags"
import type Gdk from "gi://Gdk"

function timeLabel(unix: number): string {
  try {
    return GLib.DateTime.new_from_unix_local(unix).format("%H:%M") ?? ""
  } catch (_e) {
    return ""
  }
}

function urgencyClass(n: AstalNotifd.Notification): string {
  switch (n.urgency) {
    case AstalNotifd.Urgency.CRITICAL:
      return "notif-card critical"
    case AstalNotifd.Urgency.LOW:
      return "notif-card low"
    default:
      return "notif-card"
  }
}

function Notification({ n }: { n: AstalNotifd.Notification }) {
  const icon = n.appIcon || n.desktopEntry || "dialog-information-symbolic"

  return (
    <box class={urgencyClass(n)} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box class="notif-card-head" spacing={8}>
        <image class="notif-card-icon" iconName={icon} />
        <label class="notif-card-app" label={n.appName || "system"} xalign={0} hexpand />
        <label class="notif-card-time" label={timeLabel(n.time)} />
        <button class="notif-card-close" tooltipText="Dismiss" onClicked={() => n.dismiss()}>
          <label class="nerd" label="󰅖" />
        </button>
      </box>

      <label
        class="notif-card-summary"
        label={n.summary || ""}
        xalign={0}
        wrap
        maxWidthChars={32}
        visible={!!n.summary}
      />
      <label
        class="notif-card-body"
        label={n.body || ""}
        xalign={0}
        wrap
        maxWidthChars={34}
        visible={!!n.body}
      />

      {n.actions.length > 0 && (
        <box class="notif-card-actions" homogeneous spacing={6}>
          {n.actions.map((a) => (
            <button class="notif-action" onClicked={() => n.invoke(a.id)}>
              <label label={a.label} />
            </button>
          ))}
        </box>
      )}
    </box>
  )
}

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
      <box class="ags-window-content notif-center" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
        <box class="notif-title" spacing={8}>
          <label class="nerd notif-title-icon" label="󰂚" />
          <label class="notif-title-text" label="Notifications" />
          <label class="notif-count" label={count((c) => `${c}`)} visible={count((c) => c > 0)} />
          <box hexpand />
          <button
            class="notif-dnd"
            tooltipText="Toggle Do Not Disturb"
            onClicked={() => (notifd.dontDisturb = !notifd.dontDisturb)}
          >
            <label class="nerd" label={dnd((d) => (d ? "󰂛" : "󰂚"))} />
          </button>
          <button
            class="notif-clear"
            tooltipText="Clear all"
            onClicked={() => list.get().forEach((n) => n.dismiss())}
          >
            <label class="nerd" label="󰩹" />
            <label label="Clear" />
          </button>
        </box>

        <Gtk.ScrolledWindow
          class="notif-scroll"
          propagateNaturalHeight
          maxContentHeight={560}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
            <For each={list}>{(n) => <Notification n={n} />}</For>
          </box>
        </Gtk.ScrolledWindow>

        <box class="notif-empty" orientation={Gtk.Orientation.VERTICAL} spacing={6} visible={count((c) => c === 0)}>
          <label class="nerd notif-empty-icon" label="󰂛" />
          <label class="dim" label="No notifications" />
        </box>
      </box>
    </window>
  )
}
