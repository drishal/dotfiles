import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { createBinding, For, This } from "ags"

import style from "./style/main.scss"
import fallbackTheme from "./theme.css"
import Bar from "./widget/Bar"
import Dashboard from "./windows/Dashboard"
import NotificationCenter from "./windows/NotificationCenter"
import PowerMenu from "./windows/PowerMenu"
import NotificationPopups from "./windows/NotificationPopups"

/**
 * Stylix integration.
 *
 * Home Manager writes the live base16 palette to ~/.config/ags-stylix.css as a
 * block of GTK `@define-color` rules (see ags.nix). We read it here and prepend
 * it to the compiled stylesheet so the named colours (@base0D, …) resolve
 * before any rule uses them. If the file is missing (running straight from the
 * repo), fall back to the palette bundled in theme.css.
 */
function stylixCss(): string {
  const path = `${GLib.get_user_config_dir()}/ags-stylix.css`
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    if (ok && bytes && bytes.length > 0) return new TextDecoder().decode(bytes)
  } catch (_e) {
    // fall through to bundled fallback
  }
  return fallbackTheme
}

app.start({
  css: `${stylixCss()}\n${style}`,
  main() {
    // One bar + popups per monitor, reactive to hotplug (autodetect). The
    // notifd subscription behind NotificationPopups is a module-level singleton,
    // so only the windows are per-monitor, not the event handling.
    const monitors = createBinding(app, "monitors")
    return (
      <For each={monitors}>
        {(monitor) => (
          <This this={app}>
            <Bar gdkmonitor={monitor} />
            <Dashboard gdkmonitor={monitor} />
            <NotificationCenter gdkmonitor={monitor} />
            <PowerMenu gdkmonitor={monitor} />
            <NotificationPopups gdkmonitor={monitor} />
          </This>
        )}
      </For>
    )
  },
})
