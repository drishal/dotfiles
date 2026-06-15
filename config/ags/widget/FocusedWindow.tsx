import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, With } from "ags"

function truncate(s: string, n = 48) {
  return s.length > n ? `${s.slice(0, n - 1)}…` : s
}

export default function FocusedWindow() {
  const hypr = AstalHyprland.get_default()
  const client = createBinding(hypr, "focusedClient")

  return (
    <box class="focused-window">
      <With value={client}>
        {(c) =>
          c && (
            <box spacing={6}>
              {/* nf-md-window_restore */}
              <label class="nerd fw-icon" label="󰖯" />
              <label
                class="fw-title"
                label={createComputed([createBinding(c, "title")], (t) =>
                  truncate(t || ""),
                )}
              />
            </box>
          )
        }
      </With>
    </box>
  )
}
