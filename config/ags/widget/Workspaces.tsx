import AstalHyprland from "gi://AstalHyprland"
import { Gtk } from "ags/gtk4"
import { createBinding, createComputed, For } from "ags"

export default function Workspaces() {
  const hypr = AstalHyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")

  // The Lua Hyprland config evaluates dispatch IPC as `hl.dispatch(<msg>)`, so a
  // plain "workspace N" is invalid Lua. Send a dispatcher expression instead —
  // `luaArg` is a bare number (absolute) or a quoted relative like '"e+1"'.
  const focusWs = (luaArg: string) =>
    hypr.dispatch(`hl.dsp.focus({ workspace = ${luaArg} })`, "")

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
    <box
      class="workspaces"
      // Scroll over the pill to step through workspaces.
      $={(self) => {
        const scroll = new Gtk.EventControllerScroll({
          flags: Gtk.EventControllerScrollFlags.VERTICAL,
        })
        scroll.connect("scroll", (_s, _dx, dy) => {
          focusWs(dy > 0 ? '"e+1"' : '"e-1"')
          return true
        })
        self.add_controller(scroll)
      }}
    >
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
            <button class={cls} onClicked={() => focusWs(`${id}`)}>
              <label label={`${id}`} />
            </button>
          )
        }}
      </For>
    </box>
  )
}
