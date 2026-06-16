import { createState, type Accessor } from "ags"
import { execAsync } from "ags/process"
import GLib from "gi://GLib"

export type Brightness = {
  available: boolean
  value: Accessor<number> // 0..1
  set: (v: number) => void
}

// First backlight device under /sys, or null on machines without one
// (desktops). Used to decide whether the brightness slider renders at all.
function backlightDevice(): string | null {
  try {
    const dir = GLib.Dir.open("/sys/class/backlight", 0)
    const name = dir.read_name()
    dir.close()
    return name ?? null
  } catch (_e) {
    return null
  }
}

/**
 * Backlight brightness via brightnessctl. Returns `available: false` (and a
 * no-op setter) when there's no backlight, so callers can hide the control.
 */
export function createBrightness(): Brightness {
  const [value, setValue] = createState(0)
  const device = backlightDevice()
  if (!device) return { available: false, value, set: () => {} }

  // `brightnessctl -m i` => "amdgpu_bl1,backlight,128,50%,255"; field 4 is %.
  const refresh = () => {
    execAsync(["bash", "-c", "brightnessctl -m i | cut -d, -f4 | tr -d '%'"])
      .then((out) => {
        const n = Number(out.trim())
        if (!isNaN(n)) setValue(n / 100)
      })
      .catch(() => {})
  }
  refresh()

  const set = (v: number) => {
    const pct = Math.max(0, Math.min(100, Math.round(v * 100)))
    setValue(pct / 100)
    execAsync(["brightnessctl", "s", `${pct}%`]).catch(() => {})
  }

  return { available: true, value, set }
}
