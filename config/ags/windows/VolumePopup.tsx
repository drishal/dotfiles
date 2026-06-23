import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createComputed, createState, onCleanup } from "ags"
import GLib from "gi://GLib"
import { activeEndpoint, activePercent, activeMuted, changePulse } from "../lib/audio"

const TIMEOUT_MS = 1800

/**
 * Small toast-style volume indicator, anchored to the bottom-center of each
 * monitor. Fires whenever the active *physical* output's volume or mute state
 * changes (media keys, dashboard slider, app control) — following Spark / aux /
 * speakers switching. The system default sink is the EasyEffects virtual sink,
 * whose volume is inaudible, so we track the real output via lib/audio.
 */
export default function VolumePopup({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { BOTTOM } = Astal.WindowAnchor

  // Reactive visibility — lets GTK4 CSS transitions work properly
  // (static visible={false} fights imperative .show()/.hide() in GTK4).
  const [visible, setVisible] = createState(false)

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

  // changePulse bumps only on a real volume/mute change of the active output,
  // so this never fires on startup (no baseline-establishing flash).
  const unsub = changePulse.subscribe(() => {
    setVisible(true)
    scheduleHide()
  })

  onCleanup(() => {
    unsub()
    clearHide()
  })

  const icon = createComputed([activeMuted, activePercent], (m, p) => {
    if (m) return "󰖁"
    if (p === 0) return "󰝟"
    if (p <= 33) return "󰕿"
    if (p <= 66) return "󰖀"
    return "󰕾"
  })

  const label = createComputed([activeMuted, activePercent], (m, p) => (m ? "Muted" : `${p}%`))
  const cls = activeMuted((m) => (m ? "volpopup volpopup-muted" : "volpopup"))
  const sliderVal = activePercent((p) => p / 100)

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
          value={sliderVal}
          onChangeValue={({ value }) => activeEndpoint.get()?.set_volume(value)}
        />
        <label class="volpopup-text" label={label} />
      </box>
    </window>
  )
}
