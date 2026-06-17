import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createState, For, type Accessor } from "ags"
import AstalNotifd from "gi://AstalNotifd"
import GLib from "gi://GLib"
import {
  weatherState,
  wmoInfo,
  windDirToCompass,
  formatHour,
  type WeatherData,
} from "../lib/weather"

// ─── notification list ──────────────────────────────────────────────────────
function timeLabel(unix: number): string {
  try {
    return GLib.DateTime.new_from_unix_local(unix).format("%H:%M") ?? ""
  } catch (_e) {
    return ""
  }
}

// Show the freedesktop summary as the bold title (GNOME-style); drop the
// implicit "default" action (invoked by clicking the notification) and any
// label-less actions so they don't render as empty full-width buttons.
function visibleActions(n: AstalNotifd.Notification) {
  return n.actions.filter((a) => a.id !== "default" && (a.label?.trim() ?? "") !== "")
}

function NotifCard({ n, clearing }: { n: AstalNotifd.Notification, clearing: Accessor<boolean> }) {
  const hasImage = !!n.image && GLib.file_test(n.image, GLib.FileTest.EXISTS)
  const title = n.summary || n.appName || "Notification"
  const actions = visibleActions(n)
  const base = n.urgency === AstalNotifd.Urgency.CRITICAL ? "ncard card critical" : "ncard card"
  return (
    <box class={clearing((c) => (c ? `${base} clearing-out` : base))} hexpand valign={Gtk.Align.START}>
      {hasImage ? (
        <image class="ncard-img" valign={Gtk.Align.CENTER} halign={Gtk.Align.START} file={n.image} />
      ) : (
        <label class="ncard-glyph" label="󰂚" xalign={0.5} halign={Gtk.Align.START} valign={Gtk.Align.CENTER} />
      )}
      <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
        <box valign={Gtk.Align.CENTER}>
          <label class="ncard-title" halign={Gtk.Align.START} xalign={0} hexpand maxWidthChars={30} ellipsize={3} label={title} />
          <label class="ncard-time" halign={Gtk.Align.END} label={timeLabel(n.time)} />
          <button class="ncard-close" tooltipText="Dismiss" onClicked={() => n.dismiss()}>
            <label label="󰅖" />
          </button>
        </box>
        {n.body && <label class="ncard-body" halign={Gtk.Align.START} xalign={0} hexpand maxWidthChars={48} ellipsize={3} useMarkup label={n.body} />}
        {actions.length > 0 && (
          <box class="ncard-actions" halign={Gtk.Align.START} spacing={6}>
            {actions.map((a) => (
              <button class="ncard-action" onClicked={() => n.invoke(a.id)}>
                <label label={a.label} />
              </button>
            ))}
          </box>
        )}
      </box>
    </box>
  )
}

function NotesColumn() {
  const notifd = AstalNotifd.get_default()
  const list = createBinding(notifd, "notifications")
  const dnd = createBinding(notifd, "dontDisturb")
  const count = list((n) => n.length)
  const [clearing, setClearing] = createState(false)

  const SLIDE_MS = 350

  function clearAll() {
    if (clearing.get() || list.get().length === 0) return
    setClearing(true)
    const n = list.get().length
    const total = (n - 1) * 50 + SLIDE_MS + 80
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, total, () => {
      list.get().forEach((notif) => notif.dismiss())
      setClearing(false)
      return GLib.SOURCE_REMOVE
    })
  }

  return (
    <box class="notescol" orientation={Gtk.Orientation.VERTICAL}>
      <Gtk.ScrolledWindow
        class="nlist"
        hexpand
        vexpand
        hscrollbarPolicy={Gtk.PolicyType.NEVER}
        heightRequest={520}
      >
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.START}>
          <For each={list}>{(n) => <NotifCard n={n} clearing={clearing} />}</For>
          <box
            class="nempty"
            orientation={Gtk.Orientation.VERTICAL}
            vexpand
            valign={Gtk.Align.CENTER}
            halign={Gtk.Align.CENTER}
            spacing={8}
            visible={count((c) => c === 0)}
          >
            <label class="nempty-icon" label="󰂛" />
            <label class="nempty-text" label="You're all caught up" />
          </box>
        </box>
      </Gtk.ScrolledWindow>

      <box class="nfooter" valign={Gtk.Align.CENTER}>
        <label class="nfoot-label" hexpand halign={Gtk.Align.START} label="Do Not Disturb" />
        <button
          class={dnd((d) => (d ? "dnd dnd-on" : "dnd"))}
          valign={Gtk.Align.CENTER}
          halign={Gtk.Align.CENTER}
          onClicked={() => (notifd.dontDisturb = !notifd.dontDisturb)}
        >
          <box class="dnd-track" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
            <box class="dnd-thumb" halign={dnd((d) => (d ? Gtk.Align.END : Gtk.Align.START))} valign={Gtk.Align.CENTER} />
          </box>
        </button>
        <button class={clearing((c) => (c ? "nclear clearing" : "nclear"))} onClicked={clearAll}>
          <label label="Clear" />
        </button>
      </box>
    </box>
  )
}

// ─── weather widget ────────────────────────────────────────────────────────
// Helper: derive a string from weatherState for a given selector
function wxBind<T>(sel: (d: WeatherData) => T): string {
  return weatherState((s) =>
    s.status === "ready" ? String(sel(s.data)) : "",
  )
}

function WeatherWidget() {
  const s = weatherState
  const isLoading = s((st) => st.status === "loading")
  const isError = s((st) => st.status === "error")
  const isReady = s((st) => st.status === "ready")

  // Pre-compute derived accessor strings for the "ready" state
  const icon = s((st) =>
    st.status === "ready"
      ? wmoInfo(st.data.current.weatherCode, st.data.current.isDay).icon
      : "",
  )
  const desc = s((st) =>
    st.status === "ready"
      ? wmoInfo(st.data.current.weatherCode, st.data.current.isDay).desc
      : "",
  )
  const temp = wxBind((d) => `${d.current.temp}°C`)
  const feels = wxBind((d) => `Feels ${d.current.feelsLike}°`)
  const loc = s((st) => (st.status === "ready" ? st.data.location : ""))
  const humidity = wxBind((d) => `${d.current.humidity}%`)
  const windSpeed = wxBind((d) => `${d.current.windSpeed}`)
  const windDir = wxBind((d) => `${windDirToCompass(d.current.windDir)} km/h`)
  const uv = wxBind((d) => d.current.uvIndex.toFixed(1))
  const precip = wxBind((d) => `${d.current.precipitation}mm`)

  // Hourly forecast — bind the whole list reactively
  const hourly = s((st) =>
    st.status === "ready" ? st.data.hourly : [],
  )

  return (
    <box class="wcol" orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.END} vexpand>
      {/* ── loading state ── */}
      <box class="weather-card" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} visible={isLoading}>
        <label class="weather-loading" label="󰑤" />
      </box>

      {/* ── error state ── */}
      <box class="weather-card" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} visible={isError}>
        <label class="weather-error" label="󰅚 Weather unavailable" />
      </box>

      {/* ── ready state ── */}
      <box class="weather-card" orientation={Gtk.Orientation.VERTICAL} visible={isReady}>
        {/* current conditions */}
        <box class="weather-current" valign={Gtk.Align.CENTER}>
          <label class="weather-icon" label={icon} />
          <box orientation={Gtk.Orientation.VERTICAL} hexpand>
            <label class="weather-temp" halign={Gtk.Align.START} label={temp} />
            <label class="weather-desc" halign={Gtk.Align.START} label={desc} />
          </box>
          <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.END}>
            <label class="weather-loc" label={loc} />
            <label class="weather-feels" label={feels} />
          </box>
        </box>

        {/* detail metrics */}
        <box class="weather-details" homogeneous>
          <box class="weather-metric" orientation={Gtk.Orientation.VERTICAL}>
            <label class="weather-metric-icon" halign={Gtk.Align.CENTER} label="󰖎" />
            <label class="weather-metric-val" halign={Gtk.Align.CENTER} label={humidity} />
            <label class="weather-metric-label" halign={Gtk.Align.CENTER} label="Humidity" />
          </box>
          <box class="weather-metric" orientation={Gtk.Orientation.VERTICAL}>
            <label class="weather-metric-icon" halign={Gtk.Align.CENTER} label="󰖝" />
            <label class="weather-metric-val" halign={Gtk.Align.CENTER} label={windSpeed} />
            <label class="weather-metric-label" halign={Gtk.Align.CENTER} label={windDir} />
          </box>
          <box class="weather-metric" orientation={Gtk.Orientation.VERTICAL}>
            <label class="weather-metric-icon" halign={Gtk.Align.CENTER} label="󰓅" />
            <label class="weather-metric-val" halign={Gtk.Align.CENTER} label={uv} />
            <label class="weather-metric-label" halign={Gtk.Align.CENTER} label="UV Index" />
          </box>
          <box class="weather-metric" orientation={Gtk.Orientation.VERTICAL}>
            <label class="weather-metric-icon" halign={Gtk.Align.CENTER} label="󰖗" />
            <label class="weather-metric-val" halign={Gtk.Align.CENTER} label={precip} />
            <label class="weather-metric-label" halign={Gtk.Align.CENTER} label="Rain" />
          </box>
        </box>

        {/* hourly forecast */}
        <box class="weather-hourly" homogeneous>
          <For each={hourly}>
            {(h) => {
              const hwmo = wmoInfo(h.weatherCode, true)
              return (
                <box class="weather-hour" orientation={Gtk.Orientation.VERTICAL}>
                  <label class="weather-hour-time" halign={Gtk.Align.CENTER} label={formatHour(h.time)} />
                  <label class="weather-hour-icon" halign={Gtk.Align.CENTER} label={hwmo.icon} />
                  <label class="weather-hour-temp" halign={Gtk.Align.CENTER} label={`${h.temp}°`} />
                  {h.precipProb > 0 && (
                    <label class="weather-hour-precip" halign={Gtk.Align.CENTER} label={`${h.precipProb}%`} />
                  )}
                </box>
              )
            }}
          </For>
        </box>
      </box>
    </box>
  )
}

// ─── calendar ─────────────────────────────────────────────────────────────
type Day = { d: number; cur: boolean; today: boolean }

function buildMonth(offset: number) {
  const now = new Date()
  const base = new Date(now.getFullYear(), now.getMonth() + offset, 1)
  const year = base.getFullYear()
  const month = base.getMonth()

  // Monday-first leading blanks.
  const firstDow = (new Date(year, month, 1).getDay() + 6) % 7
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const daysInPrev = new Date(year, month, 0).getDate()

  const cells: Day[] = []
  for (let i = 0; i < firstDow; i++) {
    cells.push({ d: daysInPrev - firstDow + 1 + i, cur: false, today: false })
  }
  for (let d = 1; d <= daysInMonth; d++) {
    const isToday =
      offset === 0 && d === now.getDate() && month === now.getMonth() && year === now.getFullYear()
    cells.push({ d, cur: true, today: isToday })
  }
  let next = 1
  while (cells.length % 7 !== 0 || cells.length < 42) {
    cells.push({ d: next++, cur: false, today: false })
    if (cells.length >= 42) break
  }

  const weeks: Day[][] = []
  for (let i = 0; i < cells.length; i += 7) weeks.push(cells.slice(i, i + 7))

  return {
    title: base.toLocaleDateString("en-US", { month: "long", year: "numeric" }),
    weeks,
  }
}

function CalendarColumn() {
  const now = new Date()
  const [offset, setOffset] = createState(0)
  const model = offset((o) => buildMonth(o))

  const DOW = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

  return (
    <box class="calcol" orientation={Gtk.Orientation.VERTICAL}>
      <label class="cal-weekday" halign={Gtk.Align.START} label={now.toLocaleDateString("en-US", { weekday: "long" })} />
      <label class="cal-date" halign={Gtk.Align.START} label={now.toLocaleDateString("en-US", { day: "numeric", month: "long" })} />

      <box class="cal-nav" valign={Gtk.Align.CENTER}>
        <button class="cal-arrow" onClicked={() => setOffset((o) => o - 1)}>
          <label label="󰅁" />
        </button>
        <label class="cal-title" hexpand halign={Gtk.Align.CENTER} label={model((m) => m.title)} />
        <button class="cal-arrow" onClicked={() => setOffset((o) => o + 1)}>
          <label label="󰅂" />
        </button>
      </box>

      <box class="cal-head" homogeneous>
        {DOW.map((d) => (
          <label class="cal-dow" label={d} />
        ))}
      </box>

      <box class="cal-grid" orientation={Gtk.Orientation.VERTICAL}>
        <For each={model((m) => m.weeks)}>
          {(week: Day[]) => (
            <box class="cal-week" homogeneous>
              {week.map((day) => (
                <label
                  class={`cal-day ${day.today ? "cal-today" : ""} ${day.cur ? "" : "cal-dim"}`}
                  label={`${day.d}`}
                />
              ))}
            </box>
          )}
        </For>
      </box>

      <WeatherWidget />
    </box>
  )
}

export default function NotificationCenter({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      name={`notes-${gdkmonitor.get_connector()}`}
      namespace="ags-notes"
      class="ags-notes"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="notecenter">
        <NotesColumn />
        <box class="ncenter-sep" />
        <CalendarColumn />
      </box>
    </window>
  )
}
