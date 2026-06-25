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
      default.nix            ← imports base/gui/nix/packages/users/virt/searx + shared/stylix (firewall, tlp commented out)
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
      default.nix            ← common + memory + storage + network-tuning + amd-pstate + lavd + amd graphics + packages + jellyfin
      hardware-configuration.nix
      packages.nix           ← desktop-only packages
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
      shells/                ← default.nix, fish.nix, zsh.nix, aliases.nix (shell-agnostic aliases + PATH + env)
      desktop/               ← hyprland, sway, waybar, rofi, dms, ags, eww, file-managers, hermes-app, icons
      editors/               ← default.nix, emacs.nix, nixvim.nix
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

## Critical gotchas

- **Path is hardcoded to `~/dotfiles`** — symlinks, flake references, and scripts all assume this location. Clone there.
- **Private flake input** — `private-stuff` points to `git+file:/home/drishal/.private-stuff/` (email settings, substituter token). Must exist locally or builds fail. Migration to sops-nix is planned.
- **Emacs config is an .org file** — `emacs/config.org` is tangled by Nix via `emacsWithPackagesFromUsePackage { alwaysTangle = true; config = ../../../../emacs/config.org; }`. Don't look for init.el in this repo.
- **Some `:tangle no` blocks intentionally skipped** — alternative fonts/ligatures/themes, the elpaca bootstrap, and the lsp-mode fallback stack. Don't tangle them blindly.
- **Some config/ files are .org** — `config/fish/config.org`, `config/hyprland/hyprland.org`, etc. need `org-babel-tangle` to produce their output. The legacy `scripts/home-setup.sh` does this; Home Manager handles most now.
- **Symlink loop** — `config/leftwm/onedark/onedark` is a self-referencing symlink. Don't traverse it.
- **Aliases live in shells/** — `home/common/shells/aliases.nix` defines `home.shellAliases` (applied to all shells by HM). Shell-specific config is in `zsh.nix` / `fish.nix`.
- **suckless tools** — dwm, st, dwmblocks are compiled with `sudo make clean install`, not managed by Nix. Config changes require recompilation.
- **Kernel** — Uses `pkgs.linuxPackages_xanmod_latest` (xanmod), not standard nixpkgs.
- **mitigations=off on nixos-desktop only** — `nixos-work` keeps CPU mitigations ON (Cascade Lake has MDS/L1TF/Zombieload). Don't promote `mitigations=off` to common.
- **scx scheduler split** — desktop uses `scx_lavd` (gaming), work uses `scx_bpfland` (throughput). The scheduler is NOT in common.
- **Widget stack is `drishal.widgets`** — an enum (`ags` | `eww` | `dms` | `waybar`, default `ags`, defined in `home/common/desktop/hyprland.nix`) picking the bar / notifications / control-center stack. Hyprland startup (`widgetStartup`) and the SUPER+X restart bind (`widgetRestart`, duplicated in `nixos-desktop/hyprland.nix`) branch on it; **switching requires logout**. `ags` and `eww` reproduce the same material design; only one notification daemon runs at a time (ags → AstalNotifd, eww → end-rs, gated in `eww.nix` on `widgets == "eww"`).
- **ags shell is GTK4 + Astal (v3 API)** — `config/ags/` is a TypeScript/JSX shell (`app.tsx` → per-monitor `<For each={monitors}>` autodetect; `widget/Bar.tsx`, `windows/{Dashboard,NotificationCenter,NotificationPopups,PowerMenu}.tsx`). Data comes from Astal libs (Hyprland/Wp/Network/Bluetooth/Notifd/Mpris/Tray/Battery), not shell scripts. Stylix feeds it the same way eww gets colours: `ags.nix` writes `~/.config/ags-stylix.css` (`@define-color base00..0F`), `style/_colors.scss` holds those as `"@base.."` string tokens emitted via `#{}` so dart-sass keeps the named-colour reference and the palette hot-swaps. `theme.css` is the run-from-repo fallback. The config dir is an out-of-store symlink, so TS/SCSS edits land on `ags quit; ags run` without a rebuild; `ags bundle app.tsx /tmp/out.js` typecheck-compiles without launching.
- **GPU drivers per host** — `amd.nix` for desktop/template, `nvidia.nix` for work (T400). Both live in `hosts/common/graphics/` but only one is imported per host.
- **hermes-app is an external repo** — the `hermes-app.nix` HM module (`home/common/desktop/`) wraps a PySide6 app that lives at `~/Desktop/git-stuff/hermes-app` (github.com/drishal/hermes-app), NOT in this tree. The wrapper points `appRoot` at that working tree so edits take effect on next launch; the module still generates `~/.config/HermesApp/colors.json` from stylix. Clone the repo there or the `hermes-app` command won't launch (the build still succeeds).

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
| `tmux-powerkit`          | Tmux status bar plugin                                              |
| `nvchad4nix`             | NvChad Neovim config for Nix                                        |
| `neovim-nightly-overlay` | Neovim nightly builds                                               |
| `direnv-instant`         | Instant direnv evaluation                                           |
| `ani-cli`                | Terminal anime streaming CLI                                        |
| `gruvbox-material`       | Gruvbox Material theme (flake=false, for nvim)                      |
| `llama-cpp`              | LLaMA.cpp inference engine                                          |

## Target machines

| Target          | Hardware                                        | Role                        | Key knobs                                         |
| --------------- | ----------------------------------------------- | --------------------------- | ------------------------------------------------- |
| `nixos-desktop` | Ryzen 7900X + RX 6800 + 64GB DDR5 + 2× 2TB NVMe | Main desktop / gaming       | amd-pstate, scx_lavd, mitigations=off, gamemode   |
| `nixos-work`    | Xeon W-2295 + NVIDIA T400 + 128GB + NVMe+HDD    | Workstation                 | intel-pstate, scx_bpfland, mitigations ON, nvidia |
| `nixos`         | template                                        | Baseline for fresh installs | memory + storage + amd graphics only              |

## Commit conventions

### Message format

```
scope: short description
```

or when a prefix adds clarity:

```
prefix(scope): short description
```

### When to use prefixes

This is a dotfiles repo — most changes are config tweaks, not software features. Reserve prefixes for situations where they genuinely aid scanning `git log`.

**`feat`** — Only for meaningful new capability: adding a new program, enabling a new service, introducing a new workflow. Does NOT apply to adding a package to an existing config, changing a setting, or minor customization.

- ✅ `feat(virtualization): add libvirt and docker support`
- ✅ `feat(hyprland): add monitor automation script`
- ❌ `feat(emacs): add agent-shell package` — just `emacs: add agent-shell package`
- ❌ `feat(waybar): show memory in GB` — just `waybar: show memory in GB`

**`fix`** — Correcting something broken or misconfigured.

- ✅ `fix(fish): correct PATH ordering for home-manager`
- ✅ `fix(hyprland): fix monitor assignment on work machine`

**`chore`** — Maintenance that doesn't change behavior: flake lock updates, dependency bumps, reformatting.

- ✅ `chore: update flake.lock`
- ✅ `chore(stylix): regenerate base24 colors`

**No prefix** — The default. Use `scope: description` for config changes, package additions, setting tweaks, and most day-to-day work.

- ✅ `emacs: add agent-shell package`
- ✅ `waybar: show memory in GB`
- ✅ `hyprland: enable blur`
- ✅ `dms: set weather location to Ahmedabad`

### Scope

Use the config area or tool name as scope: `emacs`, `hyprland`, `waybar`, `fish`, `nixvim`, `dms`, `mpv`, `flake.lock`, `desktop`, `work`, etc.

For machine-specific changes, use the target: `nixos-desktop:`, `nixos-work:`, `nixos:`.
For module-tree changes, prefer the area: `hosts:`, `home:`, `pkgs:`, `NixOS:` for cross-cutting.

### Grouping changes

**Single commit when:** changes are logically one action — adding a package and its config, fixing a setup across related files.

- Adding a Home Manager package + its program config → one commit
- Fixing a Hyprland keybind in both hyprland.nix and a script → one commit
- Updating flake.lock → always one commit (even if multiple inputs change)

**Separate commits when:** changes are independent and unrelated.

- Adding an Emacs package AND fixing a fish alias → two commits
- Updating waybar style AND adding a new NixOS service → two commits

### General rules

- **Lowercase** — descriptions are lowercase, no period at end
- **Imperative mood** — "add package" not "added package" or "adds package"
- **Keep it short** — if the description fits on one line, no body needed
- **Body when needed** — use a body only for non-obvious context (why, not what); the diff already shows what changed
- **Don't over-organize** — this is a personal dotfiles repo, not a team project; if you're spending more time on the commit message than the change, simplify
