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
 export the npm profile
export PATH="$HOME/.npm-packages/bin:$PATH"


export NIXPKGS_ALLOW_UNFREE=1
# export USE_CCACHE=1
# export CCACHE_EXEC=/usr/bin/ccache
# for home manager 
# export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH

#starship config
# export STARSHIP_CONFIG=~/dotfiles/config/starship.toml

# adb bin
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# locals for home manager 
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
# source ~/dotfiles/aliases.sh

#locale archive
# export LOCALE_ARCHIVE="/usr/lib/locale/locale-archive"


