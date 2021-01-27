#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
alias xon='~/Desktop/games/Xonotic/xonotic-linux-sdl.sh'
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '
#set editing-mode vi
#set -o vi
pfetch
eval "$(starship init bash)"
#echo -e -n "\x1b[\x30 q" # changes to blinking block
#echo -e -n "\x1b[\x35 q" # changes to blinking bar
#echo -e -n "\x1b[\x36 q" # changes to steady bar
#echo -e -n "\x1b[\x30 q" # changes to blinking block
#echo -e -n "\x1b[\x31 q" # changes to blinking block also
#echo -e -n "\x1b[\x32 q" # changes to steady block
#echo -e -n "\x1b[\x33 q" # changes to blinking underline
#echo -e -n "\x1b[\x34 q" # changes to steady underline
#echo -e -n "\x1b[\x35 q" # changes to blinking bar
#echo -e -n "\x1b[\x36 q" # changes to steady bar
