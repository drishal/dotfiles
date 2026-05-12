# Dotfiles — NixOS + Home Manager

## What this is

NixOS system + Home Manager user configuration managed via a single flake at `~/dotfiles`. Three machine targets: `nixos-desktop`, `nixos`, `nixos-work`. System is `x86_64-linux`, username `drishal`.

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
flake.nix / flake.lock     ← top-level flake (inputs, outputs, overlays)
NixOS/
  system-config/            ← NixOS system modules (configuration.nix imports these)
    configuration.nix       ← main system entrypoint
    base.nix                ← kernel, boot, networking, pipewire, bluetooth, tailscale
    gui.nix                 ← display server, Hyprland, input, fonts
    nix-config.nix          ← nix daemon settings
    packages.nix            ← system-level packages
    users.nix               ← user accounts
    virtualization.nix      ← libvirt, docker
    nixos-desktop/          ← desktop hardware-configuration + packages
    nixos-work/             ← work hardware-configuration + packages
    nixos/                  ← laptop hardware-configuration
  home-config/              ← Home Manager modules (home.nix imports these)
    home.nix                ← main HM entrypoint (imports all below)
    packages.nix            ← user packages (large list)
    shells.nix              ← fish config
    editors.nix             ← emacs (from config.org), helix, zed-editor
    nixvim.nix              ← neovim via nixvim
    hyprland.nix            ← Hyprland window manager settings
    waybar.nix              ← waybar bar config
    terminals.nix           ← kitty, ghostty, alacritty
    stylix.nix              ← HM-level stylix overrides
    symlinks.nix            ← mostly commented-out (legacy, use HM directly)
    nixos-desktop/          ← desktop-specific HM overrides (hyprland monitor)
    nixos-work/             ← work-specific HM overrides (dual monitor, nixvim)
  stylix.nix                ← shared stylix theming (catppuccin-mocha base24)
  custom-packages/          ← custom nix derivations (thorium-browser, galaxy-buds-client)
config/                     ← XDG-style app configs (non-HM-managed / legacy)
  hyprland/, waybar/, rofi/, fish/, kitty/, ghostty/, nvim/, etc.
emacs/                      ← Emacs config.org (tangled to ~/.config/emacs/init.el)
suckless/                   ← dwm, st, dmenu, dwl, dwmblocks (compiled via sudo make install)
scripts/                    ← utility shell scripts
wallpapers/                 ← wallpapers (used by stylix.image)
```

## Critical gotchas

- **Path is hardcoded to `~/dotfiles`** — symlinks, flake references, and scripts all assume this location. Clone there.
- **Private flake input** — `private-stuff` points to `git+file:/home/drishal/.private-stuff/` (email settings, etc.). Must exist locally or builds fail.
- **Emacs config is an .org file** — `emacs/config.org` is tangled by Nix via `emacswithPackagesFromUsePackage { alwaysTangle = true; config = ../../emacs/config.org; }`. Don't look for init.el in this repo.
- **Some config/ files are .org** — `config/fish/config.org`, `config/hyprland/hyprland.org`, etc. need `org-babel-tangle` to produce their output. The legacy `scripts/home-setup.sh` does this; Home Manager handles most now.
- **Symlink loop** — `config/leftwm/onedark/onedark` is a self-referencing symlink. Don't traverse it.
- **Symlinks are legacy** — `home-config/symlinks.nix` is almost entirely commented out. Prefer Home Manager `programs.*` and `home.file.*` over manual symlinks.
- **suckless tools** — dwm, st, dwmblocks are compiled with `sudo make clean install`, not managed by Nix. Config changes require recompilation.
- **Kernel** — Uses `cachyosKernels.linuxPackages-cachyos-latest-zen4` from the `nix-cachyos-kernel` overlay, not a standard nixpkgs kernel.
- **GPU** — AMD (amdgpu driver). No NVIDIA config.

## Flake inputs worth knowing

| Input | Purpose |
|-------|---------|
| `nixpkgs` | `nixos-unstable` channel |
| `home-manager` | User environment management |
| `hyprland` | Hyprland WM (built from source) |
| `emacs-overlay` | Latest Emacs + packages |
| `stylix` | System-wide theming |
| `nixvim` | Declarative Neovim |
| `private-stuff` | Local private config (email etc.) |
| `nix-cachyos-kernel` | CachyOS kernel overlay |
| `astal` / `ags` | AGS desktop widgets |

## Target machines

| Target | Use | Key differences |
|--------|-----|-----------------|
| `nixos-desktop` | Main desktop | Custom hyprland config, extra packages |
| `nixos-work` | Work machine | Dual monitor (DP-1 + DP-2), separate nixvim |
| `nixos` | Laptop/generic | Minimal, no extra modules |
