# aliases
alias nix-config="sudo vim /etc/nixos/configuration.nix"
alias xon="~/Desktop/games/Xonotic/xonotic-linux-sdl.sh"
alias xon-glx="~/Desktop/games/Xonotic/xonotic-linux-glx.sh"
alias stk="~/Desktop/games/SuperTuxKart-1.2-linux/run_game.sh"

# yay = pary
alias yay="paru"
alias p="paru"
# ls related aliases
alias ls="exa --icons"
# alias ls="ls --color"
alias ll="ls -l"
alias lh="ls -lh"
alias la="ls -la"
alias lah="ls -lah"
alias l="ls -lah"
alias edd="emacs --daemon"
alias b="brightnessctl"
alias bs="brightnessctl s"
alias wayland-screenshot="grimshot copy output"
alias wayland-screenshot-area="grimshot copy area"
alias v="nvim"
export EXA_ICON_SPACING=2

# man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

#resetting the right usb
alias usb_1="cd /sys/bus/pci/drivers/xhci_hcd/"
alias usb_2="su root -c  'for file in ????:??:??.? ; do  echo -n "$file" > unbind;  echo -n "$file" > bind; done'"

#nix 
alias nfu="sudo nix flake update ~/dotfiles"
alias nrs="sudo nixos-rebuild switch --flake ~/dotfiles -L"
alias nrsi="sudo nixos-rebuild switch --flake --impure ~/dotfiles -L"
export NIXPKGS_ALLOW_UNFREE=1
# home manager
alias hms="home-manager switch --flake ~/dotfiles "

# export the npm profile
export PATH="$HOME/.npm-packages/bin:$PATH"

#ccace
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
# for home manager 
# export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

#watch sync
alias watch-sync="watch -d grep -e Dirty: -e Writeback: /proc/meminfo"

# locals for home manager 
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
#ytdlp
alias youtube-dl="yt-dlp"
alias yt-dlp-mp3="yt-dlp -x --audio-format=mp3"

#distrobox
alias fedora-distrobox="distrobox-enter fedora-toolbox-35"

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
