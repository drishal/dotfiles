// cliphist-backed clipboard history.
//
// `cliphist list` emits one entry per line as `<id>\t<preview>`. Image entries
// have a synthetic preview like `[[ binary data 178 KiB png 876x781 ]]`; we
// decode those to small temp thumbnails (downscaled with ImageMagick, cached by
// id) so the popup stays light — loading full-resolution images into every row
// makes scrolling/hover crawl. Text entries pass through verbatim. Copying
// re-decodes the entry to the clipboard with the right MIME type (mirrors
// scripts/clipboard-wofi.sh).
//
// Entry payloads can contain arbitrary shell metacharacters, so deletes feed
// the raw line to `cliphist delete` over stdin (never the shell). Copies/decodes
// key off the numeric id, which is always shell-safe.

import { execAsync } from "ags/process"
import { createState, createComputed } from "ags"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

// Versioned dir: thumbnails here are always small PNGs (decode → downscale).
// The unversioned name held full-resolution decodes from an earlier build.
const THUMB_DIR = `${GLib.get_tmp_dir()}/ags-clip-thumbs-v1`
const MAX_ROWS = 100 // cap rendered rows — history can hold 750; nobody scrolls that
const DECODE_LIMIT = 6 // concurrent thumbnail decodes

// `[[ binary data 178 KiB png 876x781 ]]` (cliphist ≤0.6 says "binary data",
// newer builds say "image"); capture size, type and dimensions.
const IMG_RE = /^\[\[ (?:binary data|image) (.+?) (jpe?g|png|bmp|webp|gif) (\d+x\d+) \]\]/

export type ClipEntry = {
  id: string
  raw: string // exact `id\tpreview` line — fed to `cliphist delete` on stdin
  preview: string
  isImage: boolean
  imageType: string
  sizeText: string
  dimensions: string
  thumb: string // decoded+downscaled thumbnail path (images only)
}

const [entries, setEntries] = createState<ClipEntry[]>([])
const [total, setTotal] = createState(0)
const [query, setQuery] = createState("")

export { entries, query, setQuery }

export const filtered = createComputed([entries, query], (list, q) => {
  const needle = q.trim().toLowerCase()
  return needle ? list.filter((e) => e.preview.toLowerCase().includes(needle)) : list
})

export const count = total

function parse(out: string): ClipEntry[] {
  const res: ClipEntry[] = []
  for (const line of out.split("\n")) {
    const tab = line.indexOf("\t")
    if (tab < 0) continue
    const id = line.slice(0, tab)
    const preview = line.slice(tab + 1)
    const m = preview.match(IMG_RE)
    if (m) {
      const ext = m[2] === "jpeg" ? "jpg" : m[2]
      res.push({
        id, raw: line, preview, isImage: true,
        sizeText: m[1], imageType: m[2], dimensions: m[3],
        thumb: `${THUMB_DIR}/${id}-${ext}.png`,
      })
    } else {
      res.push({ id, raw: line, preview, isImage: false, imageType: "", sizeText: "", dimensions: "", thumb: "" })
    }
  }
  return res
}

// Bounded-concurrency map so a fresh history with dozens of images doesn't spawn
// dozens of decode processes at once (which stalls the GJS main loop).
async function runPool<T>(items: T[], limit: number, fn: (t: T) => Promise<void>) {
  let i = 0
  const worker = async () => {
    while (i < items.length) await fn(items[i++])
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker))
}

let refreshing = false

// Reload history. Publishes the list immediately (cached thumbs show at once),
// then decodes any missing thumbnails in the background and re-publishes. Safe
// to call on every open — entries persist between calls, so the popup never
// flashes empty while this resolves.
export async function refresh() {
  if (refreshing) return
  refreshing = true
  try {
    const out = await execAsync(["cliphist", "list"])
    const all = parse(out)
    setTotal(all.length)
    const list = all.slice(0, MAX_ROWS)
    setEntries(list)

    GLib.mkdir_with_parents(THUMB_DIR, 0o755)
    const pending = list.filter((e) => e.isImage && !GLib.file_test(e.thumb, GLib.FileTest.EXISTS))
    if (pending.length === 0) return
    await runPool(pending, DECODE_LIMIT, (e) =>
      // decode → downscale to a tiny thumbnail (160px long edge) so GTK loads
      // kilobytes per row, not megabytes.
      execAsync(["bash", "-c", `cliphist decode ${e.id} | magick - -thumbnail 160x160 '${e.thumb}'`]).catch(() => {}),
    )
    setEntries(all.slice(0, MAX_ROWS)) // new objects → rows re-render with thumbs
  } catch (e) {
    console.error(e)
  } finally {
    refreshing = false
  }
}

export async function copy(e: ClipEntry) {
  try {
    if (e.isImage) {
      const mime = e.imageType === "jpg" || e.imageType === "jpeg" ? "image/jpeg" : `image/${e.imageType}`
      await execAsync(["bash", "-c", `cliphist decode ${e.id} | wl-copy --type ${mime}`])
    } else {
      await execAsync(["bash", "-c", `cliphist decode ${e.id} | wl-copy`])
    }
  } catch (err) {
    console.error(err)
  }
}

// Pass the raw entry on stdin — never through the shell — so clipboard contents
// with quotes/newlines/$() can't be interpreted.
function pipeStdin(argv: string[], input: string): Promise<void> {
  return new Promise((resolve, reject) => {
    try {
      const proc = Gio.Subprocess.new(argv, Gio.SubprocessFlags.STDIN_PIPE)
      proc.communicate_utf8_async(input, null, (p, res) => {
        try {
          p!.communicate_utf8_finish(res)
          resolve()
        } catch (e) {
          reject(e)
        }
      })
    } catch (e) {
      reject(e)
    }
  })
}

export async function remove(e: ClipEntry) {
  await pipeStdin(["cliphist", "delete"], e.raw).catch(console.error)
  await refresh()
}

export async function wipe() {
  await execAsync(["cliphist", "wipe"]).catch(console.error)
  await refresh()
}
