# ========================================
# Ultra-Minimal Zsh (Instant Start) + Zinit
# ========================================
#turn off system prompt
prompt off
# --- Bootstrap Zinit (fast, silent) ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d $ZINIT_HOME ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- Basic shell settings ---
setopt no_beep interactive_comments prompt_subst
unsetopt share_history nomatch

# --- Minimal keybinds (batched for speed) ---
bindkey -e
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# --- Environment ---
export KITTY_SHELL_INTEGRATION=no-cursor
export DIRENV_LOG_FORMAT=""
export DISABLE_AUTO_TITLE="false"
export ZSH_TAB_TITLE_ADDITIONAL_TERMS='alacritty|kitty|foot'

source ~/dotfiles/scripts/aliases.sh

# --- Zinit turbo plugins (async load) ---
zinit light-mode lucid for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

# --- Nonessential plugins (lazy/turbo) ---
zinit wait'!0' lucid for \
    zdharma-continuum/history-search-multi-word \
    trystan2k/zsh-tab-title \
    Aloxaf/fzf-tab

# --- Optional snippet (colored man pages) ---
zinit snippet OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh

# --- Lazy Starship Init ---
autoload -Uz add-zsh-hook
_starship_lazy_init() {
  if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
    add-zsh-hook -d precmd _starship_lazy_init
  fi
}
add-zsh-hook precmd _starship_lazy_init

# --- Lazy Direnv ---
zinit ice wait"0b" silent atload'command -v direnv >/dev/null && eval "$(direnv hook zsh)"'
zinit load zdharma-continuum/null

# --- Optimized compinit ---
if [[ -r ~/.zcompdump.zwc ]]; then
  compinit -C
else
  compinit -d ~/.zcompdump
  zcompile ~/.zcompdump
fi

# --- Final: preload compiled Zinit core for next launch ---
if [[ ! -f ${ZINIT_HOME}/zinit.zwc || ${ZINIT_HOME}/zinit.zsh -nt ${ZINIT_HOME}/zinit.zwc ]]; then
  zcompile ${ZINIT_HOME}/zinit.zsh
fi
