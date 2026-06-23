import { createState, type Accessor } from "ags"
import AstalWp from "gi://AstalWp"

// The EasyEffects virtual sink is the system default, but its volume is
// inaudible — EE pushes the processed audio to a *physical* device whose level
// is what you actually hear (and what the media keys drive, via scripts/vol.sh).
// So the OSD and dashboard must watch/drive that physical output, not the
// default speaker. We can't tell which physical sink EE feeds from AstalWp
// alone (no priority data, EE drops its link when idle), so instead we watch
// every physical speaker and treat whichever one changes as the active output.
// That follows Spark → aux → speakers switching for free.

const wp = AstalWp.get_default()
const audio = wp?.audio

export const isEESink = (sp: AstalWp.Endpoint): boolean =>
  /easyeffects/i.test(sp.name ?? "") || /easy ?effects/i.test(sp.description ?? "")

const [endpoint, setEndpoint] = createState<AstalWp.Endpoint | null>(null)
const [percent, setPercent] = createState(0)
const [muted, setMuted] = createState(false)
const [pulse, setPulse] = createState(0)

/** Live endpoint of the active physical output (for set_volume / mute toggles). */
export const activeEndpoint: Accessor<AstalWp.Endpoint | null> = endpoint
/** Volume of the active physical output, 0..100. */
export const activePercent: Accessor<number> = percent
/** Mute state of the active physical output. */
export const activeMuted: Accessor<boolean> = muted
/** Bumped on every real volume/mute change — drives the OSD show trigger. */
export const changePulse: Accessor<number> = pulse

const sync = (sp: AstalWp.Endpoint) => {
  setEndpoint(sp)
  setPercent(Math.round(sp.volume * 100))
  setMuted(sp.mute)
}

if (audio) {
  const snap = (sp: AstalWp.Endpoint) => `${Math.round(sp.volume * 100)}/${sp.mute}`
  const baseline = new Map<AstalWp.Endpoint, string>()
  const handlers = new Map<AstalWp.Endpoint, number[]>()
  let pulses = 0

  const onChange = (sp: AstalWp.Endpoint) => {
    const cur = snap(sp)
    const prev = baseline.get(sp)
    baseline.set(sp, cur)
    sync(sp) // whichever physical speaker just moved becomes the active one
    if (prev !== undefined && prev !== cur) setPulse((pulses += 1))
  }

  const watch = (sp: AstalWp.Endpoint) => {
    if (isEESink(sp) || handlers.has(sp)) return
    baseline.set(sp, snap(sp))
    handlers.set(sp, [
      sp.connect("notify::volume", () => onChange(sp)),
      sp.connect("notify::mute", () => onChange(sp)),
    ])
    if (!endpoint.get()) sync(sp) // seed so consumers have a target at startup
  }

  const unwatch = (sp: AstalWp.Endpoint) => {
    handlers.get(sp)?.forEach((id) => sp.disconnect(id))
    handlers.delete(sp)
    baseline.delete(sp)
  }

  audio.get_speakers().forEach(watch)
  audio.connect("speaker-added", (_a: unknown, sp: AstalWp.Endpoint) => watch(sp))
  audio.connect("speaker-removed", (_a: unknown, sp: AstalWp.Endpoint) => unwatch(sp))
}
