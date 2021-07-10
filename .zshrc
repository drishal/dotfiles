# if [[ "$DESKTOP_SESSION" = *"plasma"* ]]; then
#     export QT_QPA_PLATFORMTHEME = "kde"
# fi

# if [[ "$DESKTOP_SESSION" != *"plasma"* ]]; then
#     export QT_QPA_PLATFORMTHEME="qt5ct"
# fi

zstyle :compinstall filename '/home/drishal/.zshrc'
autoload -Uz compinit
compinit

if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
autoload -U colors && colors
export PATH

source ~/.zsh-plugins/zsh-completions/zsh-completions.plugin.zsh

source ~/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

source ~/.zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /home/drishal/.zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

export RPROMPT=""

source ~/.zsh-plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# source ~/.zsh-plugins/dracula/dracula.zsh-theme
# ZSH_THEME="random"

# set some important options (as early as possible)

# append history list to the history file; this is the default but we make sure
# because it's required for share_history.
setopt append_history

# import new commands from the history file also in other zsh-session
setopt share_history

# save each command's beginning timestamp and the duration to the history file
setopt extended_history

# If a new command line being added to the history list duplicates an older
# one, the older command is removed from the list
setopt histignorealldups

# remove command lines from the history list when the first character on the
# line is a space
setopt histignorespace

# if a command is issued that can't be executed as a normal command, and the
# command is the name of a directory, perform the cd command to that directory.
setopt auto_cd

# in order to use #, ~ and ^ for filename generation grep word
# *~(*.gz|*.bz|*.bz2|*.zip|*.Z) -> searches for word not in compressed files
# don't forget to quote '^', '~' and '#'!
setopt extended_glob

# display PID when suspending processes as well
setopt longlistjobs

# report the status of backgrounds jobs immediately
setopt notify

# whenever a command completion is attempted, make sure the entire command path
# is hashed first.
setopt hash_list_all

# not just at the end
setopt completeinword

# Don't send SIGHUP to background processes when the shell exits.
setopt nohup

# make cd push the old directory onto the directory stack.
setopt auto_pushd

# avoid "beep"ing
setopt nobeep

# don't push the same dir twice.
setopt pushd_ignore_dups

# * shouldn't match dotfiles. ever.
setopt noglobdots

# use zsh style word splitting
setopt noshwordsplit

# don't error out when unset parameters are used
setopt unset

# TODO: This could use some additional information

# Make sure the completion system is initialised
(( ${+_comps} )) || return 1

# allow one error for every three characters typed in approximate completer
zstyle ':completion:*:approximate:'    max-errors 'reply=( $((($#PREFIX+$#SUFFIX)/3 )) numeric )'

# don't complete backup files as executables
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '(aptitude-*|*\~)'

# start menu completion only if it could find no unambiguous initial string
zstyle ':completion:*:correct:*'       insert-unambiguous true
zstyle ':completion:*:corrections'     format $'%{\e[0;31m%}%d (errors: %e)%{\e[0m%}'
zstyle ':completion:*:correct:*'       original true

# activate color-completion
zstyle ':completion:*:default'         list-colors ${(s.:.)LS_COLORS}

# format on completion
zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'

# automatically complete 'cd -<tab>' and 'cd -<ctrl-d>' with menu
# zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# insert all expansions for expand completer
zstyle ':completion:*:expand:*'        tag-order all-expansions
zstyle ':completion:*:history-words'   list false

# activate menu
zstyle ':completion:*:history-words'   menu yes

# ignore duplicate entries
zstyle ':completion:*:history-words'   remove-all-dups yes
zstyle ':completion:*:history-words'   stop yes

# match uppercase from lowercase
zstyle ':completion:*'                 matcher-list 'm:{a-z}={A-Z}'

# separate matches into groups
zstyle ':completion:*:matches'         group 'yes'
zstyle ':completion:*'                 group-name ''

if [[ "$NOMENU" -eq 0 ]] ; then
    # if there are more than 5 options allow selecting from a menu
    zstyle ':completion:*'               menu select=5
else
    # don't use any menus at all
    setopt no_auto_menu
fi

zstyle ':completion:*:messages'        format '%d'
zstyle ':completion:*:options'         auto-description '%d'

# describe options in full
zstyle ':completion:*:options'         description 'yes'

# on processes completion complete all user processes
zstyle ':completion:*:processes'       command 'ps -au$USER'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# provide verbose completion information
zstyle ':completion:*'                 verbose true

# recent (as of Dec 2007) zsh versions are able to provide descriptions
# for commands (read: 1st word in the line) that it will list for the user
# to choose from. The following disables that, because it's not exactly fast.
zstyle ':completion:*:-command-:*:'    verbose false

# set format for warnings
zstyle ':completion:*:warnings'        format $'%{\e[0;31m%}No matches for:%{\e[0m%} %d'

# define files to ignore for zcompile
zstyle ':completion:*:*:zcompile:*'    ignored-patterns '(*~|*.zwc)'
zstyle ':completion:correct:'          prompt 'correct to: %e'

# Ignore completion functions for commands you don't have:
zstyle ':completion::(^approximate*):*:functions' ignored-patterns '_*'

# Provide more processes in completion of programs like killall:
zstyle ':completion:*:processes-names' command 'ps c -u ${USER} -o command | uniq'

# complete manual by their section
zstyle ':completion:*:manuals'    separate-sections true
zstyle ':completion:*:manuals.*'  insert-sections   true
zstyle ':completion:*:man:*'      menu yes select

HISTFILE=${HISTFILE:-${ZDOTDIR:-${HOME}}/.zsh_history}
HISTSIZE=500  || HISTSIZE=5000
SAVEHIST=1000 || SAVEHIST=10000

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# source ~/.zsh-plugins/zshrc

source ~/.profile

DISABLE_AUTO_TITLE="true"
# export TITLE=$USER@$HOST 
# export PROMPT_COMMAND="echo -ne \"\033]0;$1 Hello World\007\""
# printf "\033]%s\07\n" "$USER@$HOST"

# export PS1="%F{blue}%~%f %(?.%F{green}❯%f.%F{red}❯%f) "
 eval "$(starship init zsh)"

pfetch

#  source ~/.zsh-plugins/termsupport.zsh
