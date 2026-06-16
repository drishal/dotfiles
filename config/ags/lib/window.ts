import app from "ags/gtk4/app"
import type Gdk from "gi://Gdk"

// All toggleable popup windows (base names). Opening one closes the others so
// at most a single popup is visible at a time.
const POPUPS = ["calendar", "notifications", "quicksettings", "powermenu"]

/**
 * Toggle a named AGS window, scoped to a monitor.
 *
 * Windows are named `${baseName}-${monitor.connector}` so each monitor gets
 * its own instance and bar buttons only affect the window on the same display.
 *
 * Before toggling, any other open popup on the same monitor is hidden, so the
 * popups behave mutually exclusively (opening the calendar closes notifications,
 * etc.).
 */
export function toggleWindow(baseName: string, gdkmonitor: Gdk.Monitor) {
  const connector = gdkmonitor.get_connector()

  for (const name of POPUPS) {
    if (name === baseName) continue
    const other = app.get_window(`${name}-${connector}`)
    if (other?.visible) other.hide()
  }

  app.toggle_window(`${baseName}-${connector}`)
}
