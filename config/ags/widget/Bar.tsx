import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, createState, For, With, onCleanup } from "ags"
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

function Workspaces({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const hypr = AstalHyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")
  const workspaces = createBinding(hypr, "workspaces")

  const connector = gdkmonitor.get_connector()
  const focusWs = (id: number) => sh(`hyprctl dispatch 'hl.dsp.focus({ workspace = ${id} })'`)

  // Urgent workspaces — a client rang its urgency hint (terminal bell, chat
  // mention, …). AstalHyprland only emits a one-shot `urgent` signal (no
  // persistent property on Workspace/Client), so we keep a Set of urgent ws
  // ids ourselves. A slot paints red while its id is in the set; focusing that
  // workspace — or having it already focused when it rings — clears it.
  const [urgent, setUrgent] = createState(new Set<number>())
  const urgentHandler = hypr.connect("urgent", (_h, c: AstalHyprland.Client) => {
    const wsId = c.workspace?.id
    if (!wsId || wsId <= 0) return
    if (focused.peek()?.id === wsId) return // already visible — not an alert
    setUrgent((prev) => (prev.has(wsId) ? prev : new Set(prev).add(wsId)))
  })
  const disposeFocus = focused.subscribe(() => {
    const fws = focused.peek()
    if (!fws || fws.id <= 0) return
    setUrgent((prev) => {
      if (!prev.has(fws.id)) return prev
      const next = new Set(prev)
      next.delete(fws.id)
      return next
    })
  })
  onCleanup(() => {
    hypr.disconnect(urgentHandler)
    disposeFocus()
  })

  // Per-monitor workspaces: only show workspaces that have clients on THIS
  // monitor, plus the focused one (even if empty).
  const slots = createComputed([workspaces, focused], (wss, fws) => {
    const onThis = wss
      .filter((ws) => ws.id > 0 && (ws.monitor as any).name === connector && ws.clients.length > 0)
      .map((ws) => ws.id)
    // Always include the focused workspace
    if (fws && fws.id > 0 && (fws.monitor as any).name === connector && !onThis.includes(fws.id)) {
      onThis.push(fws.id)
    }
    return onThis.sort((a, b) => a - b)
  })

  // Index of the focused workspace within the visible slots — drives the pill.
  // The pill travels `index × --ws-pitch` (see main.scss), so the pitch is a
  // single source of truth in CSS and stays HiDPI-correct: no hardcoded pixel
  // offset in the code.
  const activeIdx = createComputed([slots, focused], (ids, fws) => {
    if (!fws || fws.id <= 0) return -1
    return ids.indexOf(fws.id)
  })
  const pillStyle = activeIdx((i) =>
    i >= 0
      ? `.ws-slider { transform: translateX(calc(${i} * var(--ws-pitch))); }`
      : `.ws-slider { opacity: 0; }`,
  )

  return (
    <overlay class="ws-overlay">
      {/* bottom layer: a track of invisible spacers (sizes the stack) with the
          sliding accent pill painted just above them. The pill therefore sits
          below the number labels rendered in the top layer, so it glides under
          the numbers like a tab indicator. */}
      <overlay>
        <box class="ws-track">
          <For each={slots}>
            {(id: number) => <box class="ws" />}
          </For>
        </box>
        <box
          $type="overlay"
          class="ws-slider"
          halign={Gtk.Align.START}
          valign={Gtk.Align.CENTER}
          css={pillStyle}
        />
      </overlay>
      {/* top layer: the real workspace buttons — labels paint over the pill */}
      <box
        $type="overlay"
        class="workspaces"
        halign={Gtk.Align.START}
        $={(self) => {
          const scroll = new Gtk.EventControllerScroll({
            flags: Gtk.EventControllerScrollFlags.VERTICAL,
          })
          scroll.connect("scroll", (_s, _dx, dy) => {
            sh(`hyprctl dispatch 'hl.dsp.focus({ workspace = "${dy > 0 ? "e+1" : "e-1"}" })'`)
            return true
          })
          self.add_controller(scroll)
        }}
      >
        <For each={slots}>
          {(id: number) => {
            const isActive = createComputed([focused], (f) => f?.id === id)
            const occupied = workspaces((wss) =>
              wss.some((w) => w.id === id && (w.monitor as any).name === connector && w.clients.length > 0),
            )
            const cls = createComputed([isActive, occupied, urgent], (a, occ, u) =>
              a ? "ws ws-active" : u.has(id) ? "ws ws-alert" : occ ? "ws ws-busy" : "ws",
            )
            return (
              <button class={cls} onClicked={() => focusWs(id)}>
                <label label={`${id}`} />
              </button>
            )
          }}
        </For>
      </box>
    </overlay>
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

// ── right: battery · net · mem · cpu · tray · quick settings · power ──────
function Battery() {
  const bat = AstalBattery.get_default()
  const present = createBinding(bat, "isPresent")
  const percent = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")
  return (
    <box class="ringmod battery" visible={present} spacing={4} tooltipText="Battery">
      <label class="ring-icon bat" valign={Gtk.Align.BASELINE} label={charging((c) => (c ? "󰂅" : "󰁹"))} />
      <label class="ring-text bat" valign={Gtk.Align.BASELINE} label={percent((p) => `${Math.round(p * 100)}%`)} />
    </box>
  )
}

function Net() {
  const { icon, label } = networkState()
  return (
    <button class="net" tooltipText="Network settings" onClicked={() => sh("nm-connection-editor")}>
      <box spacing={4}>
        <label class="net-icon" valign={Gtk.Align.BASELINE} label={icon} />
        <label class="net-text" valign={Gtk.Align.BASELINE} maxWidthChars={16} ellipsize={3} label={label} />
      </box>
    </button>
  )
}

function Stats() {
  return (
    <box spacing={4}>
      <box class="ringmod" spacing={4} tooltipText="Memory used">
        <label class="ring-icon mem" valign={Gtk.Align.BASELINE} label="" />
        <label
          valign={Gtk.Align.BASELINE}
          class={memUsage((m) => (m.percent >= 90 ? "ring-text mem si-warn" : "ring-text mem"))}
          label={memUsage((m) => `${m.usedGb.toFixed(1)}G`)}
        />
      </box>
      <box class="ringmod" spacing={4} tooltipText="CPU usage">
        <label class="ring-icon cpu" valign={Gtk.Align.BASELINE} label="" />
        <label
          valign={Gtk.Align.BASELINE}
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
          <Workspaces gdkmonitor={gdkmonitor} />
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
          <Tray />
          <Sep />
          <button
            class="ctrl"
            tooltipText="Quick settings"
            onClicked={() => togglePopup("dashboard", gdkmonitor)}
          >
            <label label="󰘮" />
          </button>
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
