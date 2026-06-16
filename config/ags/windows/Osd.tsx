import app from "ags/gtk4/app"
import AstalWp from "gi://AstalWp"
import GLib from "gi://GLib"
import { Astal, Gtk } from "ags/gtk4"
import { createBinding, createState } from "ags"
import type Gdk from "gi://Gdk"

/**
 * Transient on-screen display for volume / mute.
 *
 * Subscribes to the default speaker and reveals a small bottom-centre overlay
 * whenever the volume or mute state changes, auto-hiding after a short delay.
 * The first ~1s of changes are swallowed so it doesn't flash on startup.
 */
export default function Osd({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { BOTTOM } = Astal.WindowAnchor

  const [visible, setVisible] = createState(false)
  const [icon, setIcon] = createState("audio-volume-high-symbolic")
  const [value, setValue] = createState(0)
  const [text, setText] = createState("")

  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker

  if (speaker) {
    let hideTimer = 0
    let primed = false
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
      primed = true
      return GLib.SOURCE_REMOVE
    })

    const reveal = () => {
      setVisible(true)
      if (hideTimer) GLib.source_remove(hideTimer)
      hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1600, () => {
        setVisible(false)
        hideTimer = 0
        return GLib.SOURCE_REMOVE
      })
    }

    const update = () => {
      const muted = speaker.mute
      setValue(muted ? 0 : speaker.volume)
      setIcon(speaker.volumeIcon)
      setText(muted ? "Muted" : `${Math.round(speaker.volume * 100)}%`)
      if (primed) reveal()
    }

    createBinding(speaker, "volume").subscribe(update)
    createBinding(speaker, "mute").subscribe(update)
  }

  return (
    <window
      name={`osd-${gdkmonitor.get_connector()}`}
      namespace="ags-osd"
      class="ags-window ags-osd-window"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={BOTTOM}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      visible={visible}
    >
      <box class="osd" spacing={12}>
        <image class="osd-icon" iconName={icon} />
        <Gtk.LevelBar class="osd-level" hexpand value={value} maxValue={1} />
        <label class="osd-text" label={text} />
      </box>
    </window>
  )
}
