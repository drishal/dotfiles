# aliases
alias nix-config="sudo vim /etc/nixos/configuration.nix"
alias xon="~/Desktop/games/Xonotic2/xonotic-linux-sdl.sh"
alias xon-glx="~/Desktop/games/Xonotic2/xonotic-linux-glx.sh"
alias stk="~/Desktop/games/SuperTuxKart-1.2-linux/run_game.sh"

# yay = pary
alias yay="paru"
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
export EXA_ICON_SPACING=2

# man pager
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

#resetting the right usb
alias usb_1="cd /sys/bus/pci/drivers/xhci_hcd/"
alias usb_2="su root -c  'for file in ????:??:??.? ; do  echo -n "$file" > unbind;  echo -n "$file" > bind; done'"

#nix aliases
alias nfu="sudo nix flake update ~/dotfiles"
alias nrs="sudo nixos-rebuild switch --flake ~/dotfiles -L"
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
#fetch
#pfetch
#pactl load-module module-bluetooth-discover
