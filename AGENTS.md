# Dotfiles — NixOS + Home Manager

## What this is

NixOS system + Home Manager user configuration managed via a single flake at `~/dotfiles`. Three machine targets: `nixos-desktop`, `nixos-work`, `nixos` (template baseline). System is `x86_64-linux`, username `drishal`.

When making changes that affect repo structure, imports, modules, flake inputs, or machine targets, update this file to keep it accurate. Stale docs are worse than no docs.

**Before making host-specific changes, verify which machine you're on** — run `hostname` to confirm whether the active target is `nixos-desktop`, `nixos-work`, or something else. The three targets below have different hardware, drivers, and tuning; don't assume.

## Apply changes

```bash
# System (NixOS)
sudo nixos-rebuild switch --flake ~/dotfiles -L

# User (Home Manager)
home-manager switch --flake ~/dotfiles

# Both (typical workflow after a change)
sudo nixos-rebuild switch --flake ~/dotfiles -L && home-manager switch --flake ~/dotfiles

# Update all flake inputs
nix flake update
```

First-time Home Manager setup:

```bash
nix run --no-write-lock-file --impure github:nix-community/home-manager -- switch --flake ~/dotfiles
```

Shorthand: `scripts/flake.sh` runs `sudo nixos-rebuild switch --flake .#`

## Repo layout

```
flake.nix / flake.lock       ← top-level flake (inputs, outputs, overlays)
NixOS/
  hosts/                     ← NixOS system modules
    common/                  ← shared across all hosts
      default.nix            ← imports audio/base/gui/nix/packages/users/virt/searx + shared/stylix (firewall, tlp commented out)
      audio.nix              ← bit-perfect audio: WirePlumber rate-switching for Audiocular Spark DAC (shared work+desktop)
      base.nix               ← boot, networking, pipewire, bluetooth, tailscale, kernel pkg
      gui.nix                ← display server, Hyprland, input, fonts
      nix.nix                ← nix daemon settings
      packages.nix           ← system-level packages
      users.nix              ← user accounts
      virtualisation.nix     ← libvirt, docker
      jellyfin.nix           ← opt-in: jellyfin media server
      firewall.nix, searx.nix, tlp.nix
      memory.nix             ← opt-in: dirty_bytes 4G / bg 64M, zram, swappiness
      network-tuning.nix     ← opt-in: BBR/MTU probing/keepalive/buffer tuning for Tailscale
      storage.nix            ← opt-in: NVMe sched=none, HDD bfq, nr_requests=2048
      cpu/
        amd-pstate.nix       ← opt-in: amd_pstate=active + perf governor
        intel-pstate.nix     ← opt-in: intel_pstate=active + perf governor
      scheduler/
        lavd.nix             ← opt-in: scx_lavd (gaming/desktop)
        bpfland.nix          ← opt-in: scx_bpfland (server/throughput)
      graphics/
        amd.nix              ← amdgpu driver, VA-API, RADV
        nvidia.nix           ← proprietary nvidia driver
    nixos/                   ← template baseline host
      default.nix            ← imports common + memory + storage + network-tuning + amd graphics
      hardware-configuration.nix
    nixos-desktop/           ← main desktop (Ryzen 7900X + RX 6800)
      default.nix            ← common + brave-previews + memory + storage + network-tuning + amd-pstate + lavd + amd graphics + packages + jellyfin
      hardware-configuration.nix
      packages.nix           ← desktop-only packages
      llama-cpp.nix          ← local llama.cpp derivation (Zen4 + LTO), callPackage'd from packages.nix; tracks whichever fork the `llama-cpp` input points at
    nixos-work/              ← work workstation (Xeon W-2295 + T400 nvidia)
      default.nix            ← common + memory + storage + network-tuning + intel-pstate + bpfland + nvidia + packages + virt
      hardware-configuration.nix
      packages.nix
      virtualisation.nix
  home/                      ← Home Manager modules
    common/
      default.nix            ← imports individual core/desktop/editors/terminals files + shells + stylix
      stylix.nix             ← HM-level stylix overrides
      core/                  ← packages.nix, git.nix, tmux.nix, fastfetch.nix
        tmux/                ← Hermes/OpenCode lifecycle adapters for tmux-agent-status
      shells/                ← default.nix, fish.nix, zsh.nix, aliases.nix (shell-agnostic aliases + PATH + env)
      desktop/               ← hyprland, sway, waybar, rofi, dms, ags, eww, quickshell, default-apps, file-managers, hermes-app, icons
      editors/               ← default.nix, emacs.nix, nixvim.nix, helix.nix
      terminals/             ← default.nix (kitty, ghostty, alacritty via single module)
      browsers/              ← default.nix, betterfox.nix (firefox+betterfox; only betterfox imported)
      media/                 ← mpv.nix
      colors/                ← doom* palette yamls (legacy, unused by stylix)
    nixos-desktop/           ← desktop-only HM overrides (hyprland monitor, sway)
    nixos-work/              ← work-only HM overrides (dual monitor, hyprland, sway)
  pkgs/                      ← custom nix derivations
    default.nix              ← attrset exposing all packages via callPackage
    thorium-browser/
    galaxy-buds-client/
  shared/
    stylix.nix               ← cross-cutting stylix theming (catppuccin-mocha base24)
config/                      ← XDG-style app configs (non-HM-managed / legacy)
  hyprland/, waybar/, rofi/, fish/, kitty/, ghostty/, nvim/, etc.
  helix/config.toml          ← standalone vim-keybind config for non-nix machines; NOT read by helix.nix
  suckless/                  ← dwm, st, dmenu, dwl, dwmblocks (compiled via sudo make install)
emacs/                       ← Emacs config.org (tangled to ~/.config/emacs/init.el)
  config.org, snippets/, themes/, unicode-fonts/, packages/
scripts/                     ← utility shell scripts
wallpapers/                  ← wallpapers (used by stylix.image)
```

## Module organization conventions

- **`hosts/<host>/default.nix` is the orchestrator** — it imports `../common`, then opt-in modules (memory, storage, cpu/_, scheduler/_, graphics/\*), then `./hardware-configuration.nix`, then per-host `packages.nix` / extras.
- **`home/common/default.nix` is the orchestrator** — imports individual files from `core/`, `desktop/`, `editors/`, `terminals/`, plus `shells/default.nix`, `browsers/betterfox.nix`, `media/mpv.nix`, and both stylix modules. Does NOT import whole `core/`, `browsers/`, or `media/` directories.
- **Per-host tunings are opt-in** — `memory.nix`, `storage.nix`, `cpu/*-pstate.nix`, `scheduler/*.nix` are NOT imported by `common/default.nix`. Each host's `default.nix` picks what applies. Lets `nixos` (template) stay minimal.
- **Per-host home overrides** live in `home/<host>/default.nix` and stack on top via flake module composition.

## Code style

- **Comments** — short and precise; max 1 line, 2 only if the explanation is genuinely needed. No comment if the code is self-explanatory.

## Critical gotchas

- **Path is hardcoded to `~/dotfiles`** — symlinks, flake references, and scripts all assume this location. Clone there.
- **Private flake input** — `private-stuff` points to `git+file:/home/drishal/.private-stuff/` (email settings, substituter token). Must exist locally or builds fail. Migration to sops-nix is planned.
- **Emacs config is an .org file** — `emacs/config.org` is tangled by Nix via `emacsWithPackagesFromUsePackage { alwaysTangle = true; config = ../../../../emacs/config.org; }`. Don't look for init.el in this repo.
- **Some `:tangle no` blocks intentionally skipped** — alternative fonts/ligatures/themes, the elpaca bootstrap, and the lsp-mode fallback stack. Don't tangle them blindly.
- **Some config/ files are .org** — `config/fish/config.org`, `config/hyprland/hyprland.org`, etc. need `org-babel-tangle` to produce their output. The legacy `scripts/home-setup.sh` does this; Home Manager handles most now.
- **Symlink loop** — `config/leftwm/onedark/onedark` is a self-referencing symlink. Don't traverse it.
- **helix runs steelix + vim.hx** — `home/common/editors/helix.nix` sets `programs.helix.package = pkgs.steelix` (helix fork with the Steel scheme runtime) and vendors the `vim-hx` flake input to `~/.config/helix/cogs/vim-hx`, loaded by a generated `init.scm`. Vim emulation lives in Steel, so `settings.keys` only holds helix-native binds vim.hx doesn't cover. `config/helix/config.toml` is a *separate* portable config for non-nix machines — editing it changes nothing here.
- **Aliases live in shells/** — `home/common/shells/aliases.nix` defines `home.shellAliases` (applied to all shells by HM). Shell-specific config is in `zsh.nix` / `fish.nix`.
- **suckless tools** — dwm, st, dwmblocks are compiled with `sudo make clean install`, not managed by Nix. Config changes require recompilation.
- **Kernel** — Uses `pkgs.linuxPackages_xanmod_latest` (xanmod), not standard nixpkgs.
- **mitigations=off on nixos-desktop only** — `nixos-work` keeps CPU mitigations ON (Cascade Lake has MDS/L1TF/Zombieload). Don't promote `mitigations=off` to common.
- **scx scheduler split** — desktop uses `scx_lavd` (gaming), work uses `scx_bpfland` (throughput). The scheduler is NOT in common.
- **Widget stack is `drishal.widgets`** — enum (`ags` | `eww` | `dms` | `waybar` | `quickshell`, default `ags`, defined in `home/common/desktop/hyprland.nix`) picking bar / notifications / control-center. Hyprland startup (`widgetStartup`) and the SUPER+X restart bind (`widgetRestart`, duplicated in `nixos-desktop/hyprland.nix`) branch on it; **switching requires logout**. `ags`/`eww`/`quickshell` share the same material design; one notification daemon at a time (ags → AstalNotifd, eww → end-rs gated in `eww.nix` on `widgets == "eww"`, quickshell → its own `NotificationServer`). Only one may own `org.freedesktop.Notifications` at a time — running two shells at once logs a "server already registered" warning.
- **quickshell shell is Quickshell 0.3.0 + QML** — `config/quickshell/` is a faithful QML port of the ags shell (`shell.qml` per-monitor `Variants`; `Modules/{Bar,Workspaces,Dashboard,WifiDetail,NotificationCenter,NotificationPopups,PowerMenu,VolumePopup,Clipboard}.qml`), driven by Quickshell native services (Hyprland/Pipewire/Mpris/SystemTray/UPower/Bluetooth/Notifications) plus singletons in `Services/` (Sys, Net, Radios, Weather, Clip, Audio, Brightness, Notif, Popups). Colours: `quickshell.nix` writes `~/.config/quickshell-stylix.json` (`{colors, fonts}`); `Common/Theme.qml` reads it via `FileView` (hot-reloads on switch) with a baked gruvbox fallback. Config dir is an out-of-store symlink, so QML edits apply on `qs kill; qs` (or the built-in hot reload) without a rebuild. **Hyprland runs `configType = "lua"`, so workspace/exit dispatches are Lua expressions** (`hl.dsp.focus{...}`, `hl.dsp.exit()`), exactly like the ags config — not classic `dispatch workspace N`. Popups toggle in-process via the `Popups` singleton (per-monitor), also reachable via IPC: `qs ipc call popups toggle dashboard`. Test-load without launching: `qs -p config/quickshell/shell.qml` and watch the log for QML errors.
- **Dashboard detail panels expand inline** — the Network tile's chevron toggles `Dashboard.expandedSection`, and the `Detail` host slides `WifiDetail` in *between* tile rows (DMS control-center pattern). The panel is built up-front and `Net` only scans while `live` (ref-counted, delayed past the animation). **Don't animate the slot's height** — that resized the layer-shell surface every frame (and flip-flopped it twice per frame as the binding re-evaluated), which is what made it stutter. Instead the slot's height animates inside a window pinned (`Dashboard.holdHeight`, set on show) to the size a detail needs, so expanding/collapsing resizes the surface **zero** times — even the single end-of-collapse resize flickers. `mask: Region { item: card }` keeps the reserved-but-empty strip click-through. The card is sized to its content (not `anchors.fill` on the window) or the background stays at full size and snaps when the hold releases, and the tile rows carry their gap as `bottomPadding` (Column `spacing: 0`) because a spacing quantum appearing/disappearing with the slot is a visible 8px jump at the end of the collapse. Wifi actions all shell out to `nmcli` from `Services/Net.qml`.
- **ags shell is GTK4 + Astal (v3 API)** — `config/ags/` is a TS/JSX shell (`app.tsx` per-monitor autodetect; `widget/Bar.tsx`, `windows/{Dashboard,NotificationCenter,NotificationPopups,PowerMenu}.tsx`), driven by Astal libs (Hyprland/Wp/Network/Bluetooth/Notifd/Mpris/Tray/Battery), not shell scripts. Colours: `ags.nix` writes `~/.config/ags-stylix.css` (`@define-color base00..0F`); `style/_colors.scss` references them as `"@base.."` tokens via `#{}` so dart-sass preserves the named colour and the palette hot-swaps (`theme.css` is the run-from-repo fallback). Config dir is an out-of-store symlink, so TS/SCSS edits apply on `ags quit; ags run` without a rebuild; `ags bundle app.tsx /tmp/out.js` typecheck-compiles without launching.
- **Default apps are single-sourced** — `home/common/desktop/default-apps.nix` defines `drishal.defaultApps` (terminal/browser/editor/filemanager…), consumed by `xdg.mimeApps` + `xdg.terminal-exec`, by hyprland/sway keybinds, and by quickshell/ags/eww at runtime via `~/.config/drishal/default-apps.json`. Override per-host in the host's home module; don't hardcode app names elsewhere.
- **GPU drivers per host** — `amd.nix` for desktop/template, `nvidia.nix` for work (T400). Both live in `hosts/common/graphics/` but only one is imported per host.
- **hermes-app is an external repo** — the `hermes-app.nix` HM module (`home/common/desktop/`) wraps a PySide6 app living at `~/Desktop/git-stuff/hermes-app` (github.com/drishal/hermes-app), NOT in this tree. `appRoot` points at that working tree (edits apply on next launch); the module generates `~/.config/HermesApp/colors.json` from stylix. Clone it there or the `hermes-app` command won't launch (build still succeeds).

## Flake inputs worth knowing

| Input                    | Purpose                                                             |
| ------------------------ | ------------------------------------------------------------------- |
| `nixpkgs`                | `nixos-unstable` channel                                            |
| `nixpkgs-master`         | Pinned specific nixpkgs commit for select packages                  |
| `home-manager`           | User environment management                                         |
| `hyprland`               | Hyprland WM (built from source)                                     |
| `emacs-overlay`          | Latest Emacs + packages                                             |
| `emacs-lsp-booster`      | Faster LSP over JSON-RPC (for eglot)                                |
| `stylix`                 | System-wide theming                                                 |
| `nixvim`                 | Declarative Neovim                                                  |
| `private-stuff`          | Local private config (email, substituter token); must exist locally |
| `chaotic`                | Chaotic-Nyx overlay (cachix, kernel patches)                        |
| `nur`                    | Nix User Repository                                                 |
| `cachix`                 | Cachix CLI (for ad-hoc `cachix use` / `cachix push`)                |
| `nix-gaming`             | Gaming-focused nix packages (gamescope, etc.)                       |
| `betterfox`              | Firefox user.js hardening                                           |
| `ghostty`                | Ghostty terminal emulator (built from source)                       |
| `dms`                    | Dank Material Shell (KDE Plasma widget)                             |
| `end-rs`                 | end-rs notification daemon (for eww widget stack)                    |
| `ags`                    | Astal/GTK4 shell framework (ags v3)                                  |
| `umu`                    | Unified Middleware for Users (Windows game launcher)                |
| `zen-browser`            | Zen Browser flake                                                   |
| `tt-schemes`             | Tinted Theming color schemes (base16)                               |
| `programsdb`             | Flake programs SQLite database                                      |
| `quickemu`               | Quick VM creation                                                   |
| `lobster`                | Terminal anime streaming                                            |
| `tmux-which-key`         | Declarative discoverable tmux key menu                              |
| `tmux-agent-status`      | Agent attention/status source (flake=false, packaged by tmux.nix)   |
| `nvchad4nix`             | NvChad Neovim config for Nix                                        |
| `neovim-nightly-overlay` | Neovim nightly builds                                               |
| `direnv-instant`         | Instant direnv evaluation                                           |
| `ani-cli`                | Terminal anime streaming CLI                                        |
| `gruvbox-material`       | Gruvbox Material theme (flake=false, for nvim)                      |
| `vim-hx`                 | Steel vim-bindings plugin for helix (flake=false, vendored by `helix.nix`) |
| `llama-cpp`              | llama.cpp src (flake=false); a fork, swapped often to test models needing a special build; built via `llama-cpp.nix` |
| `brave-previews`         | Brave Beta/Nightly browser flake (desktop nixos module)             |

## Target machines

| Target          | Hardware                                        | Role                        | Key knobs                                         |
| --------------- | ----------------------------------------------- | --------------------------- | ------------------------------------------------- |
| `nixos-desktop` | Ryzen 7900X + RX 6800 + 64GB DDR5 + 2× 2TB NVMe | Main desktop / gaming       | amd-pstate, scx_lavd, mitigations=off, gamemode   |
| `nixos-work`    | Xeon W-2295 + NVIDIA T400 + 128GB + NVMe+HDD    | Workstation                 | intel-pstate, scx_bpfland, mitigations ON, nvidia |
| `nixos`         | template                                        | Baseline for fresh installs | memory + storage + amd graphics only              |

## Commit conventions

Format: `scope: short description`, or `prefix(scope): short description` when a prefix earns its place. This is a personal dotfiles repo, so **no prefix is the default** — reserve prefixes for cases that genuinely aid scanning `git log`.

- **`feat`** — only meaningful new capability (new program, new service, new workflow). NOT for adding a package to existing config or tweaking a setting. ✅ `feat(virtualization): add libvirt and docker support` ❌ `feat(emacs): add agent-shell package` → just `emacs: add agent-shell package`
- **`fix`** — correcting something broken/misconfigured. ✅ `fix(fish): correct PATH ordering for home-manager`
- **`chore`** — maintenance with no behavior change (lock bumps, reformatting). ✅ `chore: update flake.lock`
- **No prefix** — config changes, package additions, setting tweaks. ✅ `waybar: show memory in GB`, `hyprland: enable blur`

**Scope** = config area or tool (`emacs`, `hyprland`, `waybar`, `fish`, `nixvim`, `dms`, `flake.lock`…). Machine-specific → target (`nixos-desktop:`, `nixos-work:`, `nixos:`). Module-tree → area (`hosts:`, `home:`, `pkgs:`, `NixOS:`).

**Rules:** lowercase, imperative, no trailing period. One logical action = one commit (package + its config together; flake.lock always one commit); unrelated changes = separate commits. Body only for non-obvious *why*. Don't over-organize.
