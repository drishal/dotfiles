import { createPoll } from "ags/time"
import GLib from "gi://GLib"

// Does the active locale (LC_TIME) use a 24-hour clock? Probe it with a fixed
// afternoon time: a 24-hour locale renders "13:00", a 12-hour one "01:00 PM".
const use24h = GLib.DateTime.new_local(2000, 1, 1, 13, 0, 0).format("%X")!.includes("13")

// Locale-aware "15:45" or "3:45 PM". GLib's format() doesn't reliably honour the
// glibc `-` no-pad flag, so the 12h hour is trimmed by hand.
export function clockTime(dt: GLib.DateTime): string {
  const min = dt.format("%M")!
  if (use24h) return `${dt.format("%H")!}:${min}`
  const h24 = dt.get_hour()
  const h12 = h24 % 12 === 0 ? 12 : h24 % 12
  return `${h12}:${min} ${h24 < 12 ? "AM" : "PM"}`
}

// Bar clock — "Jun 17   15:45" or "Jun 17   3:45 PM" per the locale. The day is
// trimmed by hand for the same no-pad reason as the hour.
export const barClock = createPoll("", 1000, () => {
  const now = GLib.DateTime.new_now_local()
  return `${now.format("%b")!} ${now.get_day_of_month()}   ${clockTime(now)}`
})
