# Dotfiles — NixOS + Home Manager

## What this is

NixOS system + Home Manager user configuration managed via a single flake at `~/dotfiles`. Three machine targets: `nixos-desktop`, `nixos-work`, `nixos` (template baseline). System is `x86_64-linux`, username `drishal`.

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
      default.nix            ← imports base/gui/nix/packages/users/virt/searx + shared/stylix
      base.nix               ← boot, networking, pipewire, bluetooth, tailscale, kernel pkg
      gui.nix                ← display server, Hyprland, input, fonts
      nix.nix                ← nix daemon settings
      packages.nix           ← system-level packages
      users.nix              ← user accounts
      virtualisation.nix     ← libvirt, docker
      firewall.nix, searx.nix, tlp.nix
      memory.nix             ← opt-in: dirty_bytes 4G / bg 64M, zram, swappiness
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
      default.nix            ← imports common + memory + storage + amd graphics
      hardware-configuration.nix
    nixos-desktop/           ← main desktop (Ryzen 7900X + RX 6800)
      default.nix            ← common + memory + storage + amd-pstate + lavd + amd graphics + packages
      hardware-configuration.nix
      packages.nix           ← desktop-only packages
    nixos-work/              ← work workstation (Xeon W-2295 + T400 nvidia)
      default.nix            ← common + memory + storage + intel-pstate + bpfland + nvidia + packages + virt
      hardware-configuration.nix
      packages.nix
      virtualisation.nix
  home/                      ← Home Manager modules
    common/
      default.nix            ← imports all below + sessionVariables, username, stateVersion
      stylix.nix             ← HM-level stylix overrides
      core/                  ← packages, shells (fish), aliases, git, services, symlinks, tmux
      desktop/               ← hyprland, sway, waybar, rofi, dms, file-managers, icons (lf)
      editors/               ← default.nix (emacs+helix+zed), nixvim.nix
      terminals/             ← kitty, ghostty, alacritty
      browsers/              ← default.nix (chromium/brave), betterfox.nix (firefox+betterfox)
      media/                 ← mpv.nix
      colors/                ← doom* palette yamls (legacy, unused by stylix)
    nixos-desktop/           ← desktop-only HM overrides (hyprland monitor, sway)
    nixos-work/              ← work-only HM overrides (dual monitor, nixvim, hyprland, sway)
  pkgs/                      ← custom nix derivations
    default.nix              ← attrset exposing all packages via callPackage
    thorium-browser/
    galaxy-buds-client/
  shared/
    stylix.nix               ← cross-cutting stylix theming (catppuccin-mocha base24)
config/                      ← XDG-style app configs (non-HM-managed / legacy)
  hyprland/, waybar/, rofi/, fish/, kitty/, ghostty/, nvim/, etc.
emacs/                       ← Emacs config.org (tangled to ~/.config/emacs/init.el)
  config.org, snippets/, themes/, unicode-fonts/, packages/
suckless/                    ← dwm, st, dmenu, dwl, dwmblocks (compiled via sudo make install)
scripts/                     ← utility shell scripts
wallpapers/                  ← wallpapers (used by stylix.image)
```

## Module organization conventions

- **`hosts/<host>/default.nix` is the orchestrator** — it imports `../common`, then opt-in modules (memory, storage, cpu/*, scheduler/*, graphics/*), then `./hardware-configuration.nix`, then per-host `packages.nix` / extras.
- **`hardware-configuration.nix` is auto-generated content only** — filesystems, kernel modules, hostPlatform, microcode. Do NOT add `imports = [ ./packages.nix ];` or graphics imports here; they belong in `default.nix`.
- **Per-host tunings are opt-in** — `memory.nix`, `storage.nix`, `cpu/*-pstate.nix`, `scheduler/*.nix` are NOT imported by `common/default.nix`. Each host's `default.nix` picks what applies. Lets `nixos` (template) stay minimal.
- **`home/common/default.nix` is the orchestrator** — imports all `core/desktop/editors/terminals/browsers/media` subtrees + `stylix.nix` + `../../shared/stylix.nix`.
- **Per-host home overrides** live in `home/<host>/default.nix` and stack on top via flake module composition.

## Critical gotchas

- **Path is hardcoded to `~/dotfiles`** — symlinks, flake references, and scripts all assume this location. Clone there.
- **Private flake input** — `private-stuff` points to `git+file:/home/drishal/.private-stuff/` (email settings, substituter token). Must exist locally or builds fail. Migration to sops-nix is planned.
- **Emacs config is an .org file** — `emacs/config.org` is tangled by Nix via `emacsWithPackagesFromUsePackage { alwaysTangle = true; config = ../../../../emacs/config.org; }`. Don't look for init.el in this repo.
- **Some `:tangle no` blocks intentionally skipped** — alternative fonts/ligatures/themes, the elpaca bootstrap, and the lsp-mode fallback stack. Don't tangle them blindly.
- **Some config/ files are .org** — `config/fish/config.org`, `config/hyprland/hyprland.org`, etc. need `org-babel-tangle` to produce their output. The legacy `scripts/home-setup.sh` does this; Home Manager handles most now.
- **Symlink loop** — `config/leftwm/onedark/onedark` is a self-referencing symlink. Don't traverse it.
- **Symlinks are legacy** — `home/common/core/symlinks.nix` is almost entirely commented out. Prefer Home Manager `programs.*` and `home.file.*` over manual symlinks.
- **suckless tools** — dwm, st, dwmblocks are compiled with `sudo make clean install`, not managed by Nix. Config changes require recompilation.
- **Kernel** — Uses `pkgs.linuxPackages_xanmod_latest` (xanmod), not standard nixpkgs.
- **mitigations=off on nixos-desktop only** — `nixos-work` keeps CPU mitigations ON (Cascade Lake has MDS/L1TF/Zombieload). Don't promote `mitigations=off` to common.
- **scx scheduler split** — desktop uses `scx_lavd` (gaming), work uses `scx_bpfland` (throughput). The scheduler is NOT in common.
- **GPU drivers per host** — `amd.nix` for desktop/template, `nvidia.nix` for work (T400). Both live in `hosts/common/graphics/` but only one is imported per host.

## Flake inputs worth knowing

| Input | Purpose |
|-------|---------|
| `nixpkgs` | `nixos-unstable` channel |
| `home-manager` | User environment management |
| `hyprland` | Hyprland WM (built from source) |
| `emacs-overlay` | Latest Emacs + packages |
| `emacs-lsp-booster` | Faster LSP over JSON-RPC (for eglot) |
| `stylix` | System-wide theming |
| `nixvim` | Declarative Neovim |
| `private-stuff` | Local private config (email, substituter token) |
| `nix-cachyos-kernel` | CachyOS kernel overlay (currently unused in active config) |
| `astal` / `ags` / `dms` | Desktop widgets / shells |
| `betterfox` | Firefox user.js hardening |
| `auto-cpufreq` | CPU frequency daemon (currently commented out) |

## Target machines

| Target | Hardware | Role | Key knobs |
|--------|----------|------|-----------|
| `nixos-desktop` | Ryzen 7900X + RX 6800 + 64GB DDR5 + 2× 2TB NVMe | Main desktop / gaming | amd-pstate, scx_lavd, mitigations=off, gamemode |
| `nixos-work` | Xeon W-2295 + NVIDIA T400 + 128GB + NVMe+HDD | Workstation | intel-pstate, scx_bpfland, mitigations ON, nvidia |
| `nixos` | template | Baseline for fresh installs | memory + storage + amd graphics only |

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
