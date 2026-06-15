import app from "ags/gtk4/app"
import type Gdk from "gi://Gdk"

/**
 * Toggle a named AGS window, scoped to a monitor.
 *
 * Windows are named `${baseName}-${monitor.connector}` so each monitor gets
 * its own instance and bar buttons only affect the window on the same display.
 */
export function toggleWindow(baseName: string, gdkmonitor: Gdk.Monitor) {
  const name = `${baseName}-${gdkmonitor.get_connector()}`
  app.toggle_window(name)
}
