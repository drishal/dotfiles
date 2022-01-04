if status is-interactive
    # Commands to run in interactive sessions can go here
end

if not functions -q fundle; eval (curl -sfL https://git.io/fundle-install); end

fundle plugin 'edc/bass'

fundle plugin "acomagu/fish-async-prompt"

#fundle plugin "dracula/fish"

# fundle plugin "matchai/spacefish"

fundle init

bass source /etc/profile

bass source ~/dotfiles/.profile

fish_add_path ~/.local/bin

set fish_greeting

starship init fish | source

pfetch
