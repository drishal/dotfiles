import { createPoll } from "ags/time"
import { createState, type Accessor } from "ags"
import { execAsync } from "ags/process"
import GLib from "gi://GLib"

function readFile(path: string): string {
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    return ok && bytes ? new TextDecoder().decode(bytes) : ""
  } catch (_e) {
    return ""
  }
}

// CPU usage as a 0-100 integer, derived from /proc/stat deltas.
let lastIdle = 0
let lastTotal = 0
export const cpuUsage = createPoll(0, 2000, () => {
  const line = readFile("/proc/stat").split("\n")[0]
  if (!line.startsWith("cpu")) return 0
  const v = line.trim().split(/\s+/).slice(1).map(Number)
  const idle = (v[3] ?? 0) + (v[4] ?? 0) // idle + iowait
  const total = v.reduce((a, b) => a + b, 0)
  const dIdle = idle - lastIdle
  const dTotal = total - lastTotal
  lastIdle = idle
  lastTotal = total
  if (dTotal <= 0) return 0
  return Math.min(100, Math.max(0, Math.round((1 - dIdle / dTotal) * 100)))
})

export type Mem = { usedGb: number; totalGb: number; percent: number }

export const memUsage = createPoll<Mem>({ usedGb: 0, totalGb: 0, percent: 0 }, 2000, () => {
  const info = readFile("/proc/meminfo")
  const field = (k: string) => {
    const m = info.match(new RegExp(`^${k}:\\s+(\\d+)`, "m"))
    return m ? Number(m[1]) : 0 // kB
  }
  const total = field("MemTotal")
  const avail = field("MemAvailable")
  const used = Math.max(0, total - avail)
  return {
    usedGb: used / 1024 / 1024,
    totalGb: total / 1024 / 1024,
    percent: total ? Math.round((used / total) * 100) : 0,
  }
})

// ---------------------------------------------------------------------------
// Weather (wttr.in)
// ---------------------------------------------------------------------------

// System uptime as "Xh Ym", refreshed each minute.
export const uptime = createPoll("", 60_000, () => {
  const secs = Number(readFile("/proc/uptime").split(/\s+/)[0] || 0)
  const h = Math.floor(secs / 3600)
  const m = Math.floor((secs % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
})

export type Weather = { temp: string; cond: string; icon: string }

// Map a wttr condition string to a Nerd Font weather glyph.
function weatherIcon(cond: string): string {
  const c = cond.toLowerCase()
  if (/thunder|storm/.test(c)) return "" // nf-weather-thunderstorm
  if (/snow|sleet|ice|blizzard/.test(c)) return "" // nf-weather-snow
  if (/rain|drizzle|shower/.test(c)) return "" // nf-weather-rain
  if (/fog|mist|haze/.test(c)) return "" // nf-weather-fog
  if (/overcast|cloud/.test(c)) return "" // nf-weather-cloudy
  if (/partly|sun.*cloud|cloud.*sun/.test(c)) return "" // nf-weather-day-cloudy
  if (/clear|sunny|fair/.test(c)) return "" // nf-weather-day-sunny
  return "" // nf-weather-na (default)
}

/**
 * Reactive weather for a location, refreshed every 15 min via wttr.in.
 * Returns "—" until the first fetch resolves; network failures are ignored
 * (keeps the previous value), so the bar never shows an error state.
 */
export function createWeather(location: string): Accessor<Weather> {
  const [weather, setWeather] = createState<Weather>({ temp: "—", cond: "", icon: "" })

  const fetch = () => {
    const url = `wttr.in/${encodeURIComponent(location)}?format=%t|%C`
    execAsync(["bash", "-c", `curl -sf --max-time 10 '${url}'`])
      .then((out) => {
        const [temp, cond] = out.trim().split("|")
        if (temp) {
          setWeather({
            temp: temp.replace("+", ""),
            cond: cond ?? "",
            icon: weatherIcon(cond ?? ""),
          })
        }
      })
      .catch(() => {}) // offline / DNS hiccup — keep the last good value
  }

  fetch()
  GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 900, () => {
    fetch()
    return GLib.SOURCE_CONTINUE
  })

  return weather
}
