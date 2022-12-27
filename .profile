# aliases
alias nix-config="sudo vim /etc/nixos/configuration.nix"
alias xon="~/Desktop/games/Xonotic/xonotic-linux-sdl.sh"
alias xon-glx="~/Desktop/games/Xonotic/xonotic-linux-glx.sh"
alias stk="~/Desktop/games/SuperTuxKart-1.2-linux/run_game.sh"
alias sudo="sudo "
# yay = pary
alias yay="paru"
alias p="paru"
alias apt="sudo nala"
# ls related aliases
alias ls="exa --icons"
# alias ls="lsd"
# alias ls="ls --color"
# alias ls="ls --color"
alias ll="ls -l"
alias lh="ls -lh"
alias la="ls -la"
alias lah="ls -lah"
alias l="ls -lah"
#use with lsd:
# alias l="ls -laAh"
alias edd="emacs --daemon"
alias b="brightnessctl"
alias bs="brightnessctl s"
alias wayland-screenshot="grimshot copy output"
alias wayland-screenshot-area="grimshot copy area"
alias v="nvim"
alias whoogle="docker run --publish 5000:5000 --detach benbusby/whoogle-search:latest"
alias energy_now="cat /sys/class/power_supply/BAT0/energy_now"
alias set-wall="feh --bg-scale" # set-wall /path/to/file
alias push-all="~/dotfiles/scripts/push-all.sh"
alias galaxy-buds="steam-run ~/Desktop/GalaxyBudsClient.bin"
alias remove-dunst="sudo rm /usr/share/dbus-1/services/org.knopwob.dunst.service"
alias mongodb="sudo systemctl start mongodb.service"

alias tmux="tmux -f ~/dotfiles/config/tmux/tmux.conf"

alias wine64="Winearch=win64 WINEPREFIX="/home/drishal/.wine64" wine64"

#some sysctl commands
# tt scheduler - https://github.com/hamadmarri/TT-CPU-Scheduler
alias tt_balancer_normal="sudo sysctl -w kernel.sched_tt_balancer_opt=0"
alias tt_balancer_candidate="sudo sysctl -w kernel.sched_tt_balancer_opt=1"
alias tt_balancer_cfs="sudo sysctl -w kernel.sched_tt_balancer_opt=2"
alias tt_balancer_ps="sudo sysctl -w kernel.sched_tt_balancer_opt=3"

#powerctl
alias perf="powerprofilesctl set performance; sudo cpupower frequency-set -g performance"
alias bal="powerprofilesctl set balanced; sudo cpupower frequency-set -g schedutil"
alias ps="powerprofilesctl set power-saver"
alias pnow="cat /sys/firmware/acpi/platform_profile"
#direnv
export DIRENV_LOG_FORMAT=

export EXA_ICON_SPACING=2

# man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# node
# to use this: mkdir ~/.npm-global; npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH

#Editor: setting to nvim for command line 
export EDITOR=nvim
#resetting the right usb
alias usb_1="cd /sys/bus/pci/drivers/xhci_hcd/"
alias usb_2="su root -c  'for file in ????:??:??.? ; do  echo -n "$file" > unbind;  echo -n "$file" > bind; done'"

#nix 
# . $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
alias nfu="sudo nix flake update ~/dotfiles"
alias nrs="sudo nixos-rebuild switch --flake ~/dotfiles -L"
alias nrb="sudo nixos-rebuild boot --flake ~/dotfiles -L"
alias nrsi="sudo nixos-rebuild switch --flake --impure ~/dotfiles -L"
export NIXPKGS_ALLOW_UNFREE=1
# home manager
alias hms="home-manager switch --flake ~/dotfiles "
alias hms-offline="home-manager switch --flake ~/dotfiles --option substitute false"

# export the npm profile
export PATH="$HOME/.npm-packages/bin:$PATH"

# export USE_CCACHE=1
# export CCACHE_EXEC=/usr/bin/ccache
# for home manager 
# export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

#watch sync
alias watch-sync="watch -d grep -e Dirty: -e Writeback: /proc/meminfo"
alias watch-amd-gpu="sudo watch -n 0.5  cat /sys/kernel/debug/dri/0/amdgpu_pm_info"

#ytdlp
alias youtube-dl="yt-dlp"
alias yt-dlp-mp3="yt-dlp --no-playlist -x --audio-format=mp3"

#distrobox
alias fedora-distrobox="distrobox-enter fedora-toolbox-35"
alias arch-distrobox="distrobox-enter Arch"

# Bedrock alias
alias bed-ubuntu="strat -r tut-ubuntu bash"
alias bed-arch="strat -r arch zsh"
alias bed-alpine="strat -r alpine bash"
alias bed-void="strat -r tut-void bash"
#fetch
# repo sync alias
alias repo-sync="repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all);"

# batdistrack
alias sleep-check="journalctl -u systemd-suspend.service | tail"
#pfetch
#pactl load-module module-bluetooth-discover

# adb bin
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
#upload files; use as "upload filename"
alias upload="curl -sL https://git.io/file-transfer | sh && ./transfer wet"  

# locals for home manager 
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
