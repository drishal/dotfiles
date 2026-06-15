import { createPoll } from "ags/time"
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
