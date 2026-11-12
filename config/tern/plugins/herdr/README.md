# tern-herdr

Herdr inside Tern, drawn by Tern itself. Herdr keeps the agents and terminals running; Tern shows them as native tabs, splits and a sidebar, and answers Herdr's prefix keys.

## Two views

**Tabs mirror** (`cmd+shift+m`, "Herdr: Toggle Tabs Mirror"). Every Herdr tab becomes a Tern tab and every Herdr pane a Tern split in it. Tabs are named after their space (`api`, `web · 2`) and colored by agent state: red is blocked, yellow is working, green is done. New Herdr tabs and panes appear within two seconds, and closed ones disappear. Closing a Tern tab only hides it; Herdr keeps the pane. Turning the mirror off closes the Tern tabs and leaves Herdr running.

**Sidebar** (`cmd+shift+h`, "Herdr: Open Sidebar"). A `herdr` tab with a native rail on the left and one terminal on the right that follows what you click.

- The rail lists spaces with their git branches, then agents by priority. Click a space to show its most urgent agent (or its active tab), or click an agent.
- The bar between the two sections has **new** (a new space), **▴ ▾** (move the agents section up or down; `[` and `]` do the same) and **menu** (new space, new tab, close space, integrations, machine, tabs mirror, refresh). Closing a space takes a second click.
- As in Herdr, a dot on **menu** means the machine has agent integrations to install or update: an agent's command is on PATH but its Herdr integration is missing or outdated. The menu lists them; click one to run `herdr integration install` on that machine. The check runs about once a minute.
- Under the space being shown, a row lists its Herdr tabs as `1 2 +`. Click a tab to show it, or `+` to create one. (It lives in the sidebar because a separate Tern block can't be shorter than three rows.)
- Keys in the rail: `↑`/`↓` select, `enter` shows, `n` new space, `m` menu, `r` refresh.

## Remote machines

List ssh targets in `~/.config/tern-herdr/machines`, one per line:

```
devbox
```

Each target needs Herdr on its PATH. The sidebar shows a chip per machine; the tabs mirror covers every machine and prefixes remote tab names (`devbox: api`). API calls run `ssh HOST herdr …` and terminals run `ssh -t HOST herdr terminal attach …`, so an ssh `ControlMaster` in `~/.ssh/config` keeps polling fast. A machine that stops answering keeps its tabs until it comes back.

## Herdr keys

The plugin reads `[keys]` from `~/.config/herdr/config.toml` over Herdr's defaults, and binds each `prefix+…` key as a Tern sequence: with prefix `ctrl+x`, `prefix+c` becomes `ctrl+x c`. The keys work only while a Herdr pane (mirrored or sidebar) has focus. Pressing the prefix twice sends the prefix to the program.

| Herdr action | Does |
|---|---|
| `new_tab`, `new_workspace` | `herdr tab create` / `herdr workspace create` in the current pane's space and directory, then focuses it |
| `split_vertical`, `split_horizontal` | `herdr pane split` right / down; the new pane appears as a Tern split on that side |
| `close_pane`, `close_tab`, `close_workspace` | closes it in Herdr; the mirror follows |
| `next_tab`, `previous_tab`, `switch_tab 1..9` | moves between the current space's tabs |
| `next_workspace`, `previous_workspace`, `switch_workspace 1..9` | moves between spaces |
| `next_agent`, `previous_agent` | cycles agents in space order |
| `focus_pane_left/down/up/right`, `cycle_pane_*`, `last_pane` | moves focus between Tern panes |
| `zoom`, `rename_tab` | Tern's zoom and rename |
| `workspace_picker`, `goto`, `toggle_sidebar` | opens the sidebar |
| `detach` | turns the tabs mirror off |

Herdr settings, help, resize mode, scrollback editing and worktrees aren't mapped.

## Also

- A toast appears when an agent turns blocked, or goes from working to done.
- "Herdr: Jump to Agent Needing Attention" (`cmd+shift+j`) shows the most urgent blocked or done agent.
- With `status_bar` on, the status line shows counts such as `herdr 1 blocked · 2 working`.

## How it works

- Each Tern pane runs `follow.sh`, which attaches to the terminal named in its target file (`MACHINE TERMINAL_ID`) under the plugin's data directory: `herdr terminal attach` locally, or the same command over `ssh -t`. To switch terminals, the plugin writes a new target and types `ctrl+b q`, which Herdr's direct attach always takes as detach. A failed attach is retried, because a hidden pane has no size yet and Herdr refuses a zero-sized grid.
- `window.luau` polls `herdr workspace/tab/pane list` on every machine every 2 s. It mirrors tabs and panes, registers the key sequences and calls the Herdr CLI for each action.
- `keymap.luau` turns Herdr's key specs into Tern sequences. For example, `prefix+shift+1..9` becomes `ctrl+x>shift+1` and `ctrl+x>!`, because terminals report shifted keys either way.
- `host.luau` holds the sidebar block, styled by `sidebar.css`. The `tabs` block is an older tab strip, kept so existing layouts still load.
- `common.luau` finds the binaries, parses Herdr's JSON and holds the link helpers.

Requires Herdr with `herdr terminal attach` and Tern with plugin support.

## Install

```sh
tern plugin install github.com/safzanpirani/tern-herdr
```

Or clone it and run `tern plugin link .` to use it in place. Run `tern plugin types .` to write `tern.d.luau` for luau-lsp.

The plugin talks to the default Herdr session on each machine.
