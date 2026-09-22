# pi-zentui token-context patch

Makes the zentui footer/editor show real context token counts (`6.6k/131k`)
instead of percentages (`6.6%/131k`). Gauge fill and warning/error color
thresholds still use the percentage internally.

## Files

- `pi-zentui-token-context.patch` — the change itself (5 files in
  `extensions/zentui/`: format.ts, footer.ts, index.ts,
  minimalist-editor.ts, settings-previews.ts).
- `apply-zentui-patch.sh` — idempotent checker/applier.

## Why pi-zentui is pinned

`~/.pi/agent/settings.json` lists `npm:pi-zentui@0.20.2` (exact version).
Pi skips pinned npm specs during `pi update --extensions` / `--all`, so the
in-place patch in `~/.pi/agent/npm/node_modules/pi-zentui/` survives updates.

## Updating pi-zentui manually

```bash
pi install npm:pi-zentui@<new-version>   # replaces the package, un-patches it
~/.pi/agent/patches/apply-zentui-patch.sh # re-applies (or reports conflict)
```

If the script reports CONFLICT, upstream changed one of the 5 files.
Regenerate the patch:

```bash
cd /tmp && npm pack pi-zentui@<new-version> && tar xzf pi-zentui-*.tgz
# re-apply the 5-file change to package/extensions/zentui (or port hunks by hand), then:
cd package && diff -ru extensions <patched-copy>/extensions > ~/.pi/agent/patches/pi-zentui-token-context.patch
```
