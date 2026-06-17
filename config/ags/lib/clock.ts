import { createPoll } from "ags/time"
import GLib from "gi://GLib"

// Bar clock — "Jun 17   3:45 PM". GLib's format() doesn't reliably honour the
// glibc `-` no-pad flag, so the 12h hour and day are trimmed by hand.
export const barClock = createPoll("", 1000, () => {
  const now = GLib.DateTime.new_now_local()
  const month = now.format("%b")!
  const day = now.get_day_of_month()
  const h24 = now.get_hour()
  const h12 = h24 % 12 === 0 ? 12 : h24 % 12
  const min = now.format("%M")!
  const ampm = h24 < 12 ? "AM" : "PM"
  return `${month} ${day}   ${h12}:${min} ${ampm}`
})
