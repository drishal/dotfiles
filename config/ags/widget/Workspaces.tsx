import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, For } from "ags"
import { execAsync } from "ags/process"

export default function Workspaces() {
  const hypr = AstalHyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")

  // Show real (non-special) workspaces, but always keep at least 1..5 visible
  // so the bar doesn't collapse on a fresh session.
  const slots = createComputed([createBinding(hypr, "workspaces")], (workspaces) => {
    const ids = new Set<number>()
    for (let i = 1; i <= 5; i++) ids.add(i)
    for (const ws of workspaces) {
      if (ws.id > 0) ids.add(ws.id)
    }
    return [...ids].sort((a, b) => a - b)
  })

  return (
    <box class="workspaces">
      <For each={slots}>
        {(id: number) => {
          const occupied = createBinding(hypr, "workspaces")(
            (ws) => ws.some((w) => w.id === id && w.clients.length > 0),
          )
          const cls = createComputed([focused, occupied], (f, occ) => {
            if (f?.id === id) return "ws-focused"
            if (occ) return "ws-occupied"
            return ""
          })
          return (
            <button
              class={cls}
              // hyprctl CLI rather than AstalHyprland.dispatch: the latter wraps
              // the command as Lua (hl.dispatch(...)) which breaks on the
              // Lua-based Hyprland config.
              onClicked={() =>
                execAsync(["hyprctl", "dispatch", "workspace", `${id}`]).catch(
                  console.error,
                )
              }
            >
              <label label={`${id}`} />
            </button>
          )
        }}
      </For>
    </box>
  )
}
