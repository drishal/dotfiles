import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { For, createState, type Accessor } from "ags"
import GLib from "gi://GLib"
import {
  filtered,
  count,
  query,
  setQuery,
  copy,
  remove,
  wipe,
  refresh,
  type ClipEntry,
} from "../lib/clipboard"
import { closePopup } from "../lib/windows"

// ── one history row: number badge · thumbnail/glyph · kind + preview · delete ──
function Row({
  e,
  index,
  close,
  clearing,
}: {
  e: ClipEntry
  index: Accessor<number>
  close: () => void
  clearing: Accessor<boolean>
}) {
  return (
    <box class={clearing((c) => (c ? "clip-row clearing-out" : "clip-row"))}>
      <button
        class="clip-copy"
        hexpand
        tooltipText="Copy to clipboard"
        onClicked={() => {
          copy(e)
          close()
        }}
      >
        <box valign={Gtk.Align.CENTER}>
          <label class="clip-badge" valign={Gtk.Align.CENTER} label={index((i) => `${i + 1}`)} />
          {e.isImage ? (
            <image class="clip-thumb" valign={Gtk.Align.CENTER} file={e.thumb} />
          ) : (
            <label class="clip-glyph" valign={Gtk.Align.CENTER} label="󰅎" />
          )}
          <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
            <label
              class="clip-kind"
              halign={Gtk.Align.START}
              label={e.isImage ? `Image • ${e.dimensions} ${e.imageType.toUpperCase()}` : "Text"}
            />
            <label
              class="clip-preview"
              halign={Gtk.Align.START}
              xalign={0}
              maxWidthChars={52}
              ellipsize={3 /* Pango.EllipsizeMode.END */}
              label={e.preview}
            />
          </box>
        </box>
      </button>
      <button class="clip-action clip-del" tooltipText="Delete" onClicked={() => remove(e)}>
        <label label="󰅖" />
      </button>
    </box>
  )
}

export default function Clipboard({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const close = () => closePopup("clipboard", gdkmonitor)
  let entry: Gtk.Entry

  // Staggered slide-out before wiping (mirrors the notification-center clear).
  // Each row delays its exit by its position, then we drop the history and
  // release the clearing state once the last row has flown off.
  const [clearing, setClearing] = createState(false)
  const SLIDE_MS = 350
  function clearAll() {
    const n = filtered.get().length
    if (clearing.get() || n === 0) return
    setClearing(true)
    const total = (n - 1) * 50 + SLIDE_MS + 80
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, total, () => {
      wipe()
      setClearing(false)
      return GLib.SOURCE_REMOVE
    })
  }

  return (
    <window
      name={`clipboard-${gdkmonitor.get_connector()}`}
      namespace="ags-clipboard"
      class="ags-clipboard"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
      $={(self) => {
        // Refresh on open, clear the previous search; Escape closes.
        self.connect("notify::visible", () => {
          if (!self.visible) return
          setQuery("")
          if (entry) entry.text = ""
          refresh()
        })
        const key = new Gtk.EventControllerKey()
        key.connect("key-pressed", (_k, keyval) => {
          if (keyval === Gdk.KEY_Escape) {
            close()
            return true
          }
          return false
        })
        self.add_controller(key)
      }}
    >
      <box class="clipboard" orientation={Gtk.Orientation.VERTICAL} widthRequest={560}>
        {/* header */}
        <box class="clip-header" valign={Gtk.Align.CENTER}>
          <label class="clip-title-icon" valign={Gtk.Align.CENTER} label="󰅍" />
          <label
            class="clip-title"
            hexpand
            halign={Gtk.Align.START}
            label={count((c) => `Clipboard History (${c})`)}
          />
          <button
            class={clearing((c) => (c ? "clip-hbtn clip-wipe clearing" : "clip-hbtn clip-wipe"))}
            tooltipText="Clear all"
            onClicked={clearAll}
          >
            <label label="󰩹" />
          </button>
          <button class="clip-hbtn" tooltipText="Close" onClicked={close}>
            <label label="󰅖" />
          </button>
        </box>

        {/* search */}
        <box class="clip-searchbar" valign={Gtk.Align.CENTER}>
          <label class="clip-search-icon" valign={Gtk.Align.CENTER} label="󰍉" />
          <entry
            class="clip-search"
            hexpand
            placeholderText="Search clipboard…"
            $={(self) => {
              entry = self
              self.connect("changed", () => setQuery(self.text))
            }}
          />
        </box>

        {/* list */}
        <Gtk.ScrolledWindow
          class="clip-list"
          hexpand
          vexpand
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          heightRequest={560}
        >
          <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.START}>
            <For each={filtered}>
              {(e: ClipEntry, index: Accessor<number>) => (
                <Row e={e} index={index} close={close} clearing={clearing} />
              )}
            </For>
            <box
              class="clip-empty"
              orientation={Gtk.Orientation.VERTICAL}
              vexpand
              valign={Gtk.Align.CENTER}
              halign={Gtk.Align.CENTER}
              spacing={8}
              visible={count((c) => c === 0)}
            >
              <label class="clip-empty-icon" label="󰅎" />
              <label class="clip-empty-text" label="Clipboard is empty" />
            </box>
          </box>
        </Gtk.ScrolledWindow>
      </box>
    </window>
  )
}
