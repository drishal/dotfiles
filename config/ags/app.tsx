import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { createBinding, For, This } from "ags"

import style from "./style/main.scss"
import fallbackTheme from "./theme.css"
import Bar from "./widget/Bar"
import Calendar from "./windows/Calendar"
import Notifications from "./windows/Notifications"
import QuickSettings from "./windows/QuickSettings"
import PowerMenu from "./windows/PowerMenu"
import Osd from "./windows/Osd"

/**
 * Stylix integration.
 *
 * Home Manager writes the live base16 palette to ~/.config/ags-stylix.css as a
 * block of GTK `@define-color` rules. We read it here and prepend it to the
 * compiled stylesheet so the named colors resolve before any rule uses them.
 * If the file is missing (running straight from the repo), fall back to the
 * gruvbox palette bundled in theme.css.
 */
function stylixCss(): string {
  const path = `${GLib.get_user_config_dir()}/ags-stylix.css`
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    if (ok && bytes && bytes.length > 0) {
      return new TextDecoder().decode(bytes)
    }
  } catch (_e) {
    // fall through to bundled fallback
  }
  return fallbackTheme
}

app.start({
  css: `${stylixCss()}\n${style}`,
  main() {
    // One bar per monitor, reactive to hotplug (GTK4 pattern).
    const monitors = createBinding(app, "monitors")
    return (
      <For each={monitors}>
        {(monitor) => (
          <This this={app}>
            <Bar gdkmonitor={monitor} />
            <Calendar gdkmonitor={monitor} />
            <Notifications gdkmonitor={monitor} />
            <QuickSettings gdkmonitor={monitor} />
            <PowerMenu gdkmonitor={monitor} />
            <Osd gdkmonitor={monitor} />
          </This>
        )}
      </For>
    )
  },
})
