import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

// Airplane mode via rfkill. A udev ACL grants the user rw on /dev/rfkill, so no
// sudo is needed. Polls the SOFT block column every 5s; airplane = nothing
// unblocked. (SOFT reads "blocked"/"unblocked" — match the whole word.)
export const airplaneOn = createPoll(
  false,
  5000,
  ["bash", "-c", "rfkill --output SOFT --noheadings 2>/dev/null || true"],
  (out) => (out.trim() ? !/\bunblocked\b/i.test(out) : false),
)

export function toggleAirplane(on: boolean) {
  // `on` is the *current* state — flip it.
  execAsync(["bash", "-c", on ? "rfkill unblock all" : "rfkill block all"]).catch(
    console.error,
  )
}
