import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, For, With, onCleanup } from "ags"
import AstalHyprland from "gi://AstalHyprland"
import AstalBattery from "gi://AstalBattery"
import AstalNotifd from "gi://AstalNotifd"
import AstalTray from "gi://AstalTray"

import { barClock } from "../lib/clock"
import { cpuUsage, memUsage } from "../lib/system"
import { networkState } from "../lib/network"
import { togglePopup, sh } from "../lib/windows"

const LAUNCH = "rofi -show drun -icon-theme Papirus -show-icons"

// ── left: launcher · workspaces · focused window ──────────────────────────
function Launcher() {
  return (
    <button class="launcher" tooltipText="Apps" onClicked={() => sh(LAUNCH)}>
      <label label="󰀻" />
    </button>
  )
}

function Workspaces() {
  const hypr = AstalHyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")
  const workspaces = createBinding(hypr, "workspaces")

  const focusWs = (id: number) => sh(`hyprctl dispatch workspace ${id}`)

  // Real (non-special) workspaces, but always keep 1..5 so the bar never
  // collapses on a fresh session.
  const slots = createComputed([workspaces], (wss) => {
    const ids = new Set<number>()
    for (let i = 1; i <= 5; i++) ids.add(i)
    for (const ws of wss) if (ws.id > 0) ids.add(ws.id)
    return [...ids].sort((a, b) => a - b)
  })

  return (
    <box
      class="workspaces"
      $={(self) => {
        const scroll = new Gtk.EventControllerScroll({
          flags: Gtk.EventControllerScrollFlags.VERTICAL,
        })
        scroll.connect("scroll", (_s, _dx, dy) => {
          sh(`hyprctl dispatch workspace ${dy > 0 ? "e+1" : "e-1"}`)
          return true
        })
        self.add_controller(scroll)
      }}
    >
      <For each={slots}>
        {(id: number) => {
          const occupied = workspaces((wss) =>
            wss.some((w) => w.id === id && w.clients.length > 0),
          )
          const cls = createComputed([focused, occupied], (f, occ) => {
            if (f?.id === id) return "ws ws-active"
            if (occ) return "ws ws-busy"
            return "ws"
          })
          return (
            <button class={cls} onClicked={() => focusWs(id)}>
              <label label={`${id}`} />
            </button>
          )
        }}
      </For>
    </box>
  )
}

function AppName() {
  const hypr = AstalHyprland.get_default()
  const client = createBinding(hypr, "focusedClient")
  return (
    <box class="appname-box">
      <With value={client}>
        {(c) =>
          c && (
            <label
              class="appname"
              maxWidthChars={32}
              ellipsize={3 /* Pango.EllipsizeMode.END */}
              label={createBinding(c, "title")((t) => t || "")}
            />
          )
        }
      </With>
    </box>
  )
}

// ── center: clock → notification center, with unread dot ──────────────────
function Clock({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const notifd = AstalNotifd.get_default()
  const count = createBinding(notifd, "notifications")((n) => n.length)
  return (
    <button
      class="clock"
      tooltipText="Notifications & calendar"
      onClicked={() => togglePopup("notes", gdkmonitor)}
    >
      <box spacing={6}>
        <label class="clock-txt" label={barClock} />
        <box class="clock-dot" valign={Gtk.Align.CENTER} visible={count((c) => c > 0)} />
      </box>
    </button>
  )
}

// ── right: battery · net · mem · cpu · control center · tray · power ──────
function Battery() {
  const bat = AstalBattery.get_default()
  const present = createBinding(bat, "isPresent")
  const percent = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")
  return (
    <box class="ringmod battery" visible={present} spacing={4} tooltipText="Battery">
      <label class="ring-icon bat" label={charging((c) => (c ? "󰂅" : "󰁹"))} />
      <label class="ring-text bat" label={percent((p) => `${Math.round(p * 100)}%`)} />
    </box>
  )
}

function Net() {
  const { icon, label } = networkState()
  return (
    <button class="net" tooltipText="Network settings" onClicked={() => sh("nm-connection-editor")}>
      <box spacing={4}>
        <label class="net-icon" label={icon} />
        <label class="net-text" maxWidthChars={16} ellipsize={3} label={label} />
      </box>
    </button>
  )
}

function Stats() {
  return (
    <box spacing={4}>
      <box class="ringmod" spacing={4} tooltipText="Memory used">
        <label class="ring-icon mem" label="" />
        <label
          class={memUsage((m) => (m.percent >= 90 ? "ring-text mem si-warn" : "ring-text mem"))}
          label={memUsage((m) => `${m.usedGb.toFixed(1)}G`)}
        />
      </box>
      <box class="ringmod" spacing={4} tooltipText="CPU usage">
        <label class="ring-icon cpu" label="" />
        <label
          class={cpuUsage((v) => (v >= 85 ? "ring-text cpu si-warn" : "ring-text cpu"))}
          label={cpuUsage((v) => `${v}%`)}
        />
      </box>
    </box>
  )
}

function Tray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")
  const init = (btn: Gtk.MenuButton, item: AstalTray.TrayItem) => {
    btn.menuModel = item.menuModel
    btn.insert_action_group("dbusmenu", item.actionGroup)
    item.connect("notify::action-group", () =>
      btn.insert_action_group("dbusmenu", item.actionGroup),
    )
  }
  return (
    <box class="tray" spacing={4} visible={items((i) => i.length > 0)}>
      <For each={items}>
        {(item) => (
          <menubutton
            class="tray-item"
            tooltipMarkup={createBinding(item, "tooltipMarkup")}
            $={(self) => init(self, item)}
          >
            <image gicon={createBinding(item, "gicon")} />
          </menubutton>
        )}
      </For>
    </box>
  )
}

function Sep() {
  return <label class="sep" label="|" />
}

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  onCleanup(() => win?.destroy())

  return (
    <window
      $={(self) => (win = self)}
      visible
      name={`bar-${gdkmonitor.get_connector()}`}
      namespace="ags-bar"
      class="ags-bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="bar">
        <box $type="start" halign={Gtk.Align.START} valign={Gtk.Align.CENTER}>
          <Launcher />
          <Workspaces />
          <AppName />
        </box>

        <box $type="center" valign={Gtk.Align.CENTER}>
          <Clock gdkmonitor={gdkmonitor} />
        </box>

        <box $type="end" halign={Gtk.Align.END} valign={Gtk.Align.CENTER} spacing={2}>
          <Battery />
          <Net />
          <Sep />
          <Stats />
          <Sep />
          <button
            class="ctrl"
            tooltipText="Control center"
            onClicked={() => togglePopup("dashboard", gdkmonitor)}
          >
            <label label="󰘮" />
          </button>
          <Tray />
          <button
            class="power"
            tooltipText="Power"
            onClicked={() => togglePopup("powermenu", gdkmonitor)}
          >
            <label label="󰐥" />
          </button>
        </box>
      </centerbox>
    </window>
  )
}
