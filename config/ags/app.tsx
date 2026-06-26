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
import VolumePopup from "./windows/VolumePopup"
import Clipboard from "./windows/Clipboard"
import { startWeatherService } from "./lib/weather"
import { refresh as refreshClipboard } from "./lib/clipboard"

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

/**
 * Stylix font bridge.
 *
 * GTK CSS has no font variables, so the SCSS leaves `AGS_FONT_SANS` /
 * `AGS_FONT_MONO` sentinels in place of font-family lists (see _colors.scss).
 * Home Manager writes the live Stylix families to ~/.config/ags-fonts.json
 * (see ags.nix); we swap the sentinels for them here. Missing file (running
 * straight from the repo) → bundled defaults.
 */
function applyFonts(css: string): string {
  let sans = '"Google Sans", "Maple Mono NF", sans-serif'
  let mono = '"Maple Mono NF", monospace'
  const path = `${GLib.get_user_config_dir()}/ags-fonts.json`
  try {
    const [ok, bytes] = GLib.file_get_contents(path)
    if (ok && bytes && bytes.length > 0) {
      const fonts = JSON.parse(new TextDecoder().decode(bytes))
      if (fonts.sans) sans = fonts.sans
      if (fonts.mono) mono = fonts.mono
    }
  } catch (_e) {
    // fall through to bundled defaults
  }
  return css.replaceAll("AGS_FONT_SANS", sans).replaceAll("AGS_FONT_MONO", mono)
}

app.start({
  css: applyFonts(`${stylixCss()}\n${style}`),
  main() {
    // Start weather polling (Open-Meteo, 15-min interval)
    startWeatherService()

    // Warm the clipboard history (parse + thumbnail decode) at startup so the
    // first popup open is instant and never flashes empty.
    refreshClipboard()

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
            <Clipboard gdkmonitor={monitor} />
            <NotificationPopups gdkmonitor={monitor} />
            <VolumePopup gdkmonitor={monitor} />
          </This>
        )}
      </For>
    )
  },
})
