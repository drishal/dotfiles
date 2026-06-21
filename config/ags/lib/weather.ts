import { createState } from "ags"
import GLib from "gi://GLib"
import { clockTime } from "./clock"

// ─── types ─────────────────────────────────────────────────────────────────
export interface CurrentWeather {
  temp: number
  feelsLike: number
  humidity: number
  windSpeed: number
  windDir: number
  precipitation: number
  weatherCode: number
  isDay: boolean
  uvIndex: number
}

export interface HourlyEntry {
  time: string
  temp: number
  weatherCode: number
  precipProb: number
}

export interface WeatherData {
  current: CurrentWeather
  hourly: HourlyEntry[]
  location: string
}

export type WeatherState =
  | { status: "loading" }
  | { status: "ready"; data: WeatherData }
  | { status: "error"; message: string }

// ─── config ────────────────────────────────────────────────────────────────
// Ahmedabad, Gujarat, India
const LAT = 23.0225
const LON = 72.5714
const LOCATION_NAME = "Ahmedabad"
const UPDATE_INTERVAL_MS = 15 * 60 * 1000 // 15 minutes
const FORECAST_HOURS = 5 // next 5 hours

// ─── WMO weather code → icon + description ─────────────────────────────────
// Open-Meteo uses WMO weather interpretation codes.
// Icons are Nerd Font glyphs that work with "Maple Mono NF".
interface WmoInfo {
  icon: string
  desc: string
}

const WMO_DAY: Record<number, WmoInfo> = {
  0: { icon: "󰖙", desc: "Clear sky" },
  1: { icon: "󰖙", desc: "Mainly clear" },
  2: { icon: "󰼰", desc: "Partly cloudy" },
  3: { icon: "󰖕", desc: "Overcast" },
  45: { icon: "󰖑", desc: "Fog" },
  48: { icon: "󰖑", desc: "Depositing rime fog" },
  51: { icon: "󰼰", desc: "Light drizzle" },
  53: { icon: "󰼰", desc: "Moderate drizzle" },
  55: { icon: "󰖗", desc: "Dense drizzle" },
  56: { icon: "󰖗", desc: "Freezing drizzle" },
  57: { icon: "󰖗", desc: "Dense freezing drizzle" },
  61: { icon: "󰖖", desc: "Slight rain" },
  63: { icon: "󰖖", desc: "Moderate rain" },
  65: { icon: "󰖖", desc: "Heavy rain" },
  66: { icon: "󰖖", desc: "Freezing rain" },
  67: { icon: "󰖖", desc: "Heavy freezing rain" },
  71: { icon: "󰖘", desc: "Slight snow" },
  73: { icon: "󰖘", desc: "Moderate snow" },
  75: { icon: "󰖘", desc: "Heavy snow" },
  77: { icon: "󰖘", desc: "Snow grains" },
  80: { icon: "󰖖", desc: "Slight rain showers" },
  81: { icon: "󰖖", desc: "Moderate rain showers" },
  82: { icon: "󰖖", desc: "Violent rain showers" },
  85: { icon: "󰖘", desc: "Slight snow showers" },
  86: { icon: "󰖘", desc: "Heavy snow showers" },
  95: { icon: "󰖞", desc: "Thunderstorm" },
  96: { icon: "󰖞", desc: "Thunderstorm with hail" },
  99: { icon: "󰖞", desc: "Severe thunderstorm" },
}

const WMO_NIGHT: Record<number, WmoInfo> = {
  0: { icon: "󰖜", desc: "Clear sky" },
  1: { icon: "󰖜", desc: "Mainly clear" },
  2: { icon: "󰼱", desc: "Partly cloudy" },
  3: { icon: "󰖕", desc: "Overcast" },
  45: { icon: "󰖑", desc: "Fog" },
  48: { icon: "󰖑", desc: "Depositing rime fog" },
  51: { icon: "󰼱", desc: "Light drizzle" },
  53: { icon: "󰼱", desc: "Moderate drizzle" },
  55: { icon: "󰖗", desc: "Dense drizzle" },
  56: { icon: "󰖗", desc: "Freezing drizzle" },
  57: { icon: "󰖗", desc: "Dense freezing drizzle" },
  61: { icon: "󰖖", desc: "Slight rain" },
  63: { icon: "󰖖", desc: "Moderate rain" },
  65: { icon: "󰖖", desc: "Heavy rain" },
  66: { icon: "󰖖", desc: "Freezing rain" },
  67: { icon: "󰖖", desc: "Heavy freezing rain" },
  71: { icon: "󰖘", desc: "Slight snow" },
  73: { icon: "󰖘", desc: "Moderate snow" },
  75: { icon: "󰖘", desc: "Heavy snow" },
  77: { icon: "󰖘", desc: "Snow grains" },
  80: { icon: "󰖖", desc: "Slight rain showers" },
  81: { icon: "󰖖", desc: "Moderate rain showers" },
  82: { icon: "󰖖", desc: "Violent rain showers" },
  85: { icon: "󰖘", desc: "Slight snow showers" },
  86: { icon: "󰖘", desc: "Heavy snow showers" },
  95: { icon: "󰖞", desc: "Thunderstorm" },
  96: { icon: "󰖞", desc: "Thunderstorm with hail" },
  99: { icon: "󰖞", desc: "Severe thunderstorm" },
}

export function wmoInfo(code: number, isDay: boolean): WmoInfo {
  const table = isDay ? WMO_DAY : WMO_NIGHT
  return table[code] ?? { icon: "󰼳", desc: "Unknown" }
}

// ─── state ─────────────────────────────────────────────────────────────────
export const [weatherState, setWeatherState] = createState<WeatherState>({
  status: "loading",
})

// ─── fetch ─────────────────────────────────────────────────────────────────
// GJS has no fetch() — use curl via GLib.spawn_command_line_sync.
function fetchWeather(): void {
  const currentParams = [
    "temperature_2m",
    "apparent_temperature",
    "relative_humidity_2m",
    "weathercode",
    "windspeed_10m",
    "winddirection_10m",
    "precipitation",
    "is_day",
    "uv_index",
  ].join(",")

  const hourlyParams = [
    "temperature_2m",
    "weathercode",
    "precipitation_probability",
  ].join(",")

  const url =
    `https://api.open-meteo.com/v1/forecast` +
    `?latitude=${LAT}&longitude=${LON}` +
    `&current=${currentParams}` +
    `&hourly=${hourlyParams}` +
    `&forecast_days=2&timezone=auto`

  try {
    const [ok, stdout, _stderr, _exit] = GLib.spawn_command_line_sync(
      `curl -s '${url}'`,
    )
    if (!ok || stdout.length === 0) {
      setWeatherState({ status: "error", message: "curl returned empty" })
      return
    }

    const text = new TextDecoder().decode(stdout)
    const json: any = JSON.parse(text)

    const cur = json.current
    const current: CurrentWeather = {
      temp: Math.round(cur.temperature_2m),
      feelsLike: Math.round(cur.apparent_temperature),
      humidity: cur.relative_humidity_2m,
      windSpeed: Math.round(cur.windspeed_10m),
      windDir: cur.winddirection_10m,
      precipitation: cur.precipitation,
      weatherCode: cur.weathercode,
      isDay: cur.is_day === 1,
      uvIndex: cur.uv_index ?? 0,
    }

    // Find the current hour index, then start one hour ahead — the current
    // conditions already live in the block above, so the strip shows the next
    // 5 hours rather than repeating "now".
    const nowIso = cur.time.slice(0, 13) // "2026-06-18T00"
    const startIdx = json.hourly.time.findIndex((t: string) =>
      t.startsWith(nowIso),
    )
    const safeStart = Math.max(0, startIdx) + 1

    const hourly: HourlyEntry[] = []
    for (
      let i = safeStart;
      i < safeStart + FORECAST_HOURS && i < json.hourly.time.length;
      i++
    ) {
      hourly.push({
        time: json.hourly.time[i],
        temp: Math.round(json.hourly.temperature_2m[i]),
        weatherCode: json.hourly.weathercode[i],
        precipProb: json.hourly.precipitation_probability?.[i] ?? 0,
      })
    }

    setWeatherState({
      status: "ready",
      data: { current, hourly, location: LOCATION_NAME },
    })
  } catch (err: any) {
    setWeatherState({ status: "error", message: String(err) })
  }
}

// ─── lifecycle ─────────────────────────────────────────────────────────────
let timerId: number | null = null

export function startWeatherService(): void {
  fetchWeather()
  timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, UPDATE_INTERVAL_MS, () => {
    fetchWeather()
    return GLib.SOURCE_CONTINUE
  })
}

export function stopWeatherService(): void {
  if (timerId !== null) {
    GLib.source_remove(timerId)
    timerId = null
  }
}

// ─── helpers ───────────────────────────────────────────────────────────────
export function windDirToCompass(deg: number): string {
  const dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
  return dirs[Math.round(deg / 45) % 8]
}

export function formatHour(iso: string): string {
  // Open-Meteo hourly timestamps look like "2026-06-21T15:00" (no seconds, no
  // timezone), which GLib.DateTime.new_from_iso8601 refuses to parse — pull the
  // parts out by hand and build a local DateTime.
  const m = iso.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/)
  if (!m) return ""
  const dt = GLib.DateTime.new_local(+m[1], +m[2], +m[3], +m[4], +m[5], 0)
  return dt ? clockTime(dt) : ""
}
