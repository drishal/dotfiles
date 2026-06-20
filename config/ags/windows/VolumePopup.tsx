import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, createState, onCleanup } from "ags"
import AstalWp from "gi://AstalWp"
import GLib from "gi://GLib"

const TIMEOUT_MS = 1800

/**
 * Small toast-style volume indicator, anchored to the bottom-center of each
 * monitor. Fires whenever the default speaker's volume or mute state changes
 * (media keys, dashboard slider, app control).
 */
export default function VolumePopup({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { BOTTOM } = Astal.WindowAnchor
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker

  if (!speaker) {
    return (
      <window
        name={`volpopup-${gdkmonitor.get_connector()}`}
        namespace="ags-volpopup"
        class="ags-volpopup"
        application={app}
        gdkmonitor={gdkmonitor}
        layer={Astal.Layer.OVERLAY}
        anchor={BOTTOM}
        exclusivity={Astal.Exclusivity.IGNORE}
        visible={false}
      />
    )
  }

  const vol = createBinding(speaker, "volume")
  const mute = createBinding(speaker, "mute")

  // Reactive visibility — lets GTK4 CSS transitions work properly
  // (static visible={false} fights imperative .show()/.hide() in GTK4).
  const [visible, setVisible] = createState(false)

  // Composite state drives the show trigger.
  const state = createComputed([mute, vol], (m, v) => ({
    muted: m,
    percent: Math.round(v * 100),
  }))

  // Baseline from the current speaker state so the *first* media-key press
  // already shows the popup (rather than just establishing a baseline).
  let prevMuted = state.get().muted
  let prevPercent = state.get().percent

  let timeout: number | null = null
  const clearHide = () => {
    if (timeout) {
      GLib.source_remove(timeout)
      timeout = null
    }
  }
  const scheduleHide = () => {
    clearHide()
    timeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, TIMEOUT_MS, () => {
      setVisible(false)
      timeout = null
      return GLib.SOURCE_REMOVE
    })
  }

  // Subscribe for the side effect — a derived accessor would never run unless
  // it were mounted, so use an explicit subscription instead.
  const unsub = state.subscribe(() => {
    const s = state.get()
    if (s.muted !== prevMuted || s.percent !== prevPercent) {
      prevMuted = s.muted
      prevPercent = s.percent
      setVisible(true)
      scheduleHide()
    }
  })

  onCleanup(() => {
    unsub()
    clearHide()
  })

  const icon = createComputed([mute, vol], (m, v) => {
    if (m) return "󰖁"
    const p = Math.round(v * 100)
    if (p === 0) return "󰝟"
    if (p <= 33) return "󰕿"
    if (p <= 66) return "󰖀"
    return "󰕾"
  })

  const label = createComputed([mute, vol], (m, v) => {
    if (m) return "Muted"
    return `${Math.round(v * 100)}%`
  })

  const cls = createComputed([mute], (m) => (m ? "volpopup volpopup-muted" : "volpopup"))

  return (
    <window
      name={`volpopup-${gdkmonitor.get_connector()}`}
      namespace="ags-volpopup"
      class={cls}
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={BOTTOM}
      exclusivity={Astal.Exclusivity.IGNORE}
      visible={visible}
    >
      <box class="volpopup-inner" valign={Gtk.Align.CENTER} spacing={12}>
        <label class="volpopup-icon" label={icon} />
        <slider
          class="volpopup-slider"
          hexpand
          valign={Gtk.Align.CENTER}
          value={vol}
          onChangeValue={({ value }) => speaker.set_volume(value)}
        />
        <label class="volpopup-text" label={label} />
      </box>
    </window>
  )
}
