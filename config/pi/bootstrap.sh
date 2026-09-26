#!/usr/bin/env bash
# Rebuild ~/.pi from this repo on a fresh machine.
#
#   ~/dotfiles/config/pi/bootstrap.sh              link config, install, patch
#   ~/dotfiles/config/pi/bootstrap.sh --check      report drift, change nothing
#   ~/dotfiles/config/pi/bootstrap.sh --sync-back  pull live changes into repo
#
# Config is symlinked out of the repo so edits here are edits there.
#
# Packages are NOT pinned by a lockfile: settings.json `packages[]` is the
# source of truth and step 4 runs `pi install` for each entry. Pin a version
# in packages[] (e.g. npm:pi-zentui@0.25.0) when something depends on it.
# pi's own lockfile (npm/, --legacy-peer-deps) stays machine-local.
#
# settings.json is a third case. It mixes shared config with per-machine
# choices, so it is MERGED in both directions: the repo owns the shared keys,
# this machine owns LOCAL_KEYS (provider, model, thinking level). The model
# name never enters the repo — different machines run different providers.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
CHECK=0; SYNC_BACK=0
case "${1:-}" in
  --check)     CHECK=1 ;;
  --sync-back) SYNC_BACK=1 ;;
esac

say() { printf '%s\n' "$*"; }
ok()  { printf '  ok      %s\n' "$*"; }
act() { printf '  %s %s\n' "$([ $CHECK -eq 1 ] && echo 'DRIFT  ' || echo "${VERB:-link}   ")" "$*"; }

# Files pi/npm never write — safe to symlink at the repo.
LINKS=(
  AGENTS.md zentui.json pi-fff.json subagents.json patches
)
# Directories linked entry-by-entry rather than whole, because they also hold
# files this repo deliberately does not track:
#   extensions/ -> litellm-auto.ts (gitignored, per-machine)
#   themes/     -> <name>.json generated from each <name>.yaml by
#                  extensions/base16-theme.ts, and stylix.yaml (home-manager)
# Linking the directory itself would delete those.
PER_ENTRY=( extensions themes skills )
# settings.json is neither linked nor copied wholesale: it holds BOTH shared
# config (packages, theme, compaction) and per-machine choices. These keys are
# per-machine and never enter the repo — a different box runs a different
# provider, and the model name is not public information. (Settings that
# need a per-machine value but can expand ${VAR} — the pi-memory-mem0 block —
# stay shared; remember-model.ts exports the values from model-state.json.)
LOCAL_KEYS='["defaultProvider","defaultModel","defaultThinkingLevel","lastChangelogVersion"]'

say "pi bootstrap: $REPO -> $PI"

# --- 0. sync-back ---------------------------------------------------------
# Live -> repo, for the files pi/npm rewrite in place. LOCAL_KEYS are stripped
# on the way out, so a model name physically cannot reach the repo even if you
# run this right after switching providers. Symlinked files need no sync-back:
# editing them already edits the repo.
if [ $SYNC_BACK -eq 1 ]; then
  say "sync-back: $PI -> $REPO"
  if [ -f "$PI/settings.json" ]; then
    jq --argjson keys "$LOCAL_KEYS" \
       'delpaths([$keys[] | [.]])' "$PI/settings.json" > "$REPO/agent/settings.json" \
      || { say "  jq strip failed"; exit 1; }
    ok "settings.json (local keys stripped)"
  fi
  say ""
  say "Review with: git -C \"$REPO\" diff ."
  exit 0
fi

# --- 1. prerequisites -----------------------------------------------------
command -v pi  >/dev/null || { say "pi not on PATH — install it first"; exit 1; }
command -v npm >/dev/null || { say "npm not on PATH"; exit 1; }

mkdir -p "$PI/npm" "$PI/themes"

# --- 2. symlinked config --------------------------------------------------
say "config:"
for f in "${LINKS[@]}"; do
  src="$REPO/agent/$f"; dst="$PI/$f"
  [ -e "$src" ] || continue
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    ok "$f"; continue
  fi
  act "$f"
  [ $CHECK -eq 1 ] && continue
  rm -rf "$dst"; ln -s "$src" "$dst"
done

# Links left dangling by a file that was renamed or removed in the repo.
# Only links that point INTO this repo are touched.
while IFS= read -r l; do
  t="$(readlink "$l")"
  case "$t" in "$REPO"/*) ;; *) continue ;; esac
  [ -e "$l" ] && continue
  VERB=prune act "${l#"$PI"/} (target gone from repo)"
  [ $CHECK -eq 1 ] || rm -f "$l"
done < <(find "$PI" -maxdepth 2 -type l 2>/dev/null)

# Entry-by-entry: only paths this repo tracks are replaced. Anything else
# already in the directory is left exactly as it is.
for d in "${PER_ENTRY[@]}"; do
  [ -d "$REPO/agent/$d" ] || continue
  mkdir -p "$PI/$d"
  for src in "$REPO/agent/$d"/*; do
    [ -e "$src" ] || continue
    dst="$PI/$d/$(basename "$src")"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      ok "$d/$(basename "$src")"; continue
    fi
    act "$d/$(basename "$src")"
    [ $CHECK -eq 1 ] && continue
    rm -rf "$dst"; ln -s "$src" "$dst"
  done
done

# --- 3b. settings.json (merged, never overwritten) -------------------------
# The repo supplies the shared keys and wins where both define one. Nothing
# that exists only on this machine is dropped: LOCAL_KEYS (model choice, mem0
# config), any other live-only key, and packages installed here with
# `pi install` that the repo does not list yet. Those are reported as
# live-only so they can be shared with --sync-back (or deliberately kept
# local). A fresh machine simply gets the repo copy.
say "settings.json (merge, local keys preserved):"
SRC_S="$REPO/agent/settings.json"; DST_S="$PI/settings.json"
PNAME='def pname: (if type == "string" then . else (.source // "") end)
  | if startswith("npm:") then .[4:]
      | (if startswith("@") then "@" + (.[1:] | split("@")[0]) else split("@")[0] end)
    else . end;'
if [ ! -f "$SRC_S" ]; then
  say "  missing $SRC_S"
elif [ ! -f "$DST_S" ]; then
  act "settings.json (new)"
  [ $CHECK -eq 0 ] && cp -p "$SRC_S" "$DST_S"
else
  merged="$(jq -s "$PNAME"'
      .[0] as $repo | .[1] as $live
      | ($live * $repo)
      | .packages = (($repo.packages // [])
          + [($live.packages // [])[]
             | select(pname as $n | ($repo.packages // []) | map(pname) | index($n) | not)])' \
      "$SRC_S" "$DST_S")" || { say "  jq merge failed"; exit 1; }
  if [ "$merged" = "$(cat "$DST_S")" ]; then
    ok "settings.json"
  else
    act "settings.json"
    [ $CHECK -eq 0 ] && printf '%s\n' "$merged" > "$DST_S"
  fi
  for k in $(printf '%s' "$LOCAL_KEYS" | jq -r '.[]'); do
    v="$(jq -r --arg k "$k" '.[$k] // empty | if type == "string" then . else "(\(type), set)" end' "$DST_S")"
    [ -n "$v" ] && printf '  kept    %s = %s (local)\n' "$k" "$v"
  done
  jq -rs --argjson keys "$LOCAL_KEYS" "$PNAME"'
      .[0] as $repo | .[1] as $live
      | ([($live.packages // [])[] | select(pname as $n | ($repo.packages // []) | map(pname) | index($n) | not)
          | if type == "string" then . else .source end]
         + [$live | keys[] | select(. as $k | ($repo | has($k) | not) and ($keys | index($k) | not))])[]' \
      "$SRC_S" "$DST_S" | while IFS= read -r x; do
    printf '  live    %s (not in repo; --sync-back to share it)\n' "$x"
  done
fi

# --- 4. packages ----------------------------------------------------------
# One `pi install` per missing/mismatched packages[] entry. pi resolves peers
# its own way (--legacy-peer-deps), so we never run npm here directly.
# Installed-but-unpinned packages are left alone: upgrading is `pi update`.
say "packages (from settings.json):"
spec_name() { local s="${1#npm:}" at=""; [ "${s:0:1}" = "@" ] && { at="@"; s="${s:1}"; }
              printf '%s%s' "$at" "${s%%@*}"; }
spec_ver()  { local s="${1#npm:}"; s="${s#@}"; [ "${s#*@}" != "$s" ] && printf '%s' "${s#*@}"; }
while IFS= read -r spec; do
  [ -n "$spec" ] || continue
  case "$spec" in npm:*) ;; *)
    [ $CHECK -eq 1 ] && { ok "$spec (non-npm, not checked)"; continue; }
    pi install "$spec" >/dev/null 2>&1 && ok "$spec" || say "  FAILED  $spec"; continue ;;
  esac
  name="$(spec_name "$spec")"; want="$(spec_ver "$spec")"
  pj="$PI/npm/node_modules/$name/package.json"
  have="$( [ -f "$pj" ] && jq -r .version "$pj")"
  if [ -n "$have" ] && { [ -z "$want" ] || [ "$have" = "$want" ]; }; then
    ok "$spec ($have)"; continue
  fi
  VERB=install act "$spec${have:+ (have $have)}"
  [ $CHECK -eq 1 ] && continue
  pi install "$spec" >/dev/null 2>&1 || { say "  FAILED  pi install $spec"; exit 1; }
done < <(jq -r '.packages[]? | if type=="string" then . else .source end' "$PI/settings.json")

# --- 4b. memory storage ---------------------------------------------------
# mem0ai (behind the mem0 extension) imports some of its PEER dependencies at
# load time — better-sqlite3 for the local store, and pg, which it imports even
# though the SQLite store never uses it. pi installs with peers disabled, so
# after `pi install` memory fails with "Mem0 init failed: Cannot find package".
# Rather than hard-code that list, load mem0 and install whatever it reports
# missing (at mem0ai's declared peer range) until it loads. pi's own npm flags
# (--legacy-peer-deps) matter: plain `npm install` would also pull in every
# other package's peers (~370 modules).
mem0_missing() {   # first package mem0 cannot load; "" if fine; "!msg" otherwise
  (cd "$PI/npm" && node -e '
    import("mem0ai/oss")
      .then(() => { new (require("better-sqlite3"))(":memory:"); })
      .catch((e) => {
        const m = /Cannot find (?:package|module) \x27([^\x27]+)\x27/.exec(e.message);
        console.log(m ? m[1] : `!${String(e.message).split("\n")[0]}`);
      });' 2>/dev/null)
}
MEM0="$PI/npm/node_modules/mem0ai/package.json"
if [ -f "$MEM0" ]; then
  for _ in 1 2 3 4 5 6; do
    miss="$(mem0_missing)"
    [ -z "$miss" ] && { ok "mem0 dependencies load"; break; }
    case "$miss" in '!'*) say "  FAILED  mem0 does not load: ${miss#!}"; break ;; esac
    name="$(node -p "const s='$miss'; s.startsWith('@') ? s.split('/').slice(0, 2).join('/') : s.split('/')[0]")"
    range="$(node -p "require('$MEM0').peerDependencies?.['$name'] ?? 'latest'")"
    VERB=install act "$name@$range (mem0 peer)"
    [ $CHECK -eq 1 ] && break
    npm install "$name@$range" --prefix "$PI/npm" --legacy-peer-deps --no-audit --no-fund \
        </dev/null >/dev/null 2>&1 || { say "  FAILED  npm install $name@$range"; break; }
  done
  # The shared settings block names no models: remember-model.ts exports
  # them from model-state.json's "mem0" section, which only this machine has.
  for k in llm embedder; do
    jq -e --arg k "$k" '.mem0[$k] | strings | length > 0' "$PI/model-state.json" >/dev/null 2>&1 ||
      say "  NOTE    model-state.json has no mem0.$k; mem0 cannot run (SETUP.md step 8)"
  done
fi

# --- 5. the silent one ----------------------------------------------------
# The zentui patch lives INSIDE node_modules, which is untracked. A fresh
# install yields unpatched zentui with no error — percentages instead of real
# token counts in the footer. This step is why the script exists.
say "patches:"
if [ -x "$PI/patches/apply-zentui-patch.sh" ]; then
  if [ $CHECK -eq 1 ]; then
    "$PI/patches/apply-zentui-patch.sh" --check | sed 's/^/  /'
  else
    "$PI/patches/apply-zentui-patch.sh" | sed 's/^/  /'
  fi
else
  say "  patches/apply-zentui-patch.sh missing"
fi

# --- 6. what this script cannot do ----------------------------------------
cat <<EOF

Not handled here (secrets / per-machine — see SETUP.md):
  $PI/auth.json          pi auth login
  $PI/models.json        provider config incl. LAN IP
  $PI/models-store.json  xai oauth token store
  $PI/mcp.json           MCP servers; carries inline credentials
                         (rebuild from SETUP.md step 5)

Per-machine model choice (never in the repo):
  $PI/model-state.json   written by extensions/remember-model.ts
  Pick a model/thinking level with Enter — it is remembered per machine, and
  each model keeps its own thinking level. Avoid Ctrl+S in /model or /thinking:
  that writes defaultModel etc. into settings.json (harmless — --sync-back
  strips them — but it duplicates the choice).

  Its "mem0" section holds the memory models (llm, embedder), which
  remember-model.ts exports for the shared settings.json block to expand
  (SETUP.md step 8). Memories live in $PI/memories/.
EOF
