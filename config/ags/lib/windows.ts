import app from "ags/gtk4/app"
import { execAsync } from "ags/process"
import type Gdk from "gi://Gdk"

// All toggleable popups (base names). Opening one closes the others on the same
// monitor, so at most one popup is visible per display at a time.
const POPUPS = ["dashboard", "notes", "powermenu"]

/**
 * Toggle a named popup window, scoped to a monitor.
 *
 * Windows are named `${base}-${connector}` so each monitor owns its own
 * instance and bar buttons only affect the popup on the same display.
 */
export function togglePopup(base: string, gdkmonitor: Gdk.Monitor) {
  const connector = gdkmonitor.get_connector()
  for (const name of POPUPS) {
    if (name === base) continue
    const other = app.get_window(`${name}-${connector}`)
    if (other?.visible) other.hide()
  }
  app.toggle_window(`${base}-${connector}`)
}

export function closePopup(base: string, gdkmonitor: Gdk.Monitor) {
  const win = app.get_window(`${base}-${gdkmonitor.get_connector()}`)
  win?.hide()
}

export function sh(cmd: string) {
  execAsync(["bash", "-c", cmd]).catch(console.error)
}
