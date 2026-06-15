import AstalTray from "gi://AstalTray"
import { Gtk } from "ags/gtk4"
import { createBinding, For } from "ags"

// The whole reason for this bar: a rock-solid Wayland systray (SNI).
export default function Tray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")

  const init = (btn: Gtk.MenuButton, item: AstalTray.TrayItem) => {
    btn.menuModel = item.menuModel
    btn.insert_action_group("dbusmenu", item.actionGroup)
    item.connect("notify::action-group", () => {
      btn.insert_action_group("dbusmenu", item.actionGroup)
    })
  }

  return (
    <box class="module tray" spacing={4} visible={items((i) => i.length > 0)}>
      <For each={items}>
        {(item) => (
          <menubutton
            class="tray-item"
            tooltipMarkup={createBinding(item, "tooltipMarkup")}
            $={(self) => init(self, item)}
          >
            <image gicon={createBinding(item, "gicon")} />
          </menubutton>
        )}
      </For>
    </box>
  )
}
