!/bin/sh
#
# Simple script to toggle github remote to/from https/ssh.
#
# Dylan Araps
# make sure to read these before 
# https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account
# https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
# instructions:
# step 1: 
# ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# eval "$(ssh-agent -s)" 
# ssh-add ~/.ssh/id_ed25519
# xclip -selection clipboard < ~/.ssh/id_ed25519.pub

repo_remote="$(git remote get-url "${1:-origin}" || exit 1)"

case $repo_remote in
    git@github*)
        repo=${repo_remote##git@github.com:}
        repo=${repo%%.git}
        repo=https://github.com/$repo
    ;;  

    *https*github*)
        repo=${repo_remote##https://github.com/}
        repo=${repo%%.git}
        repo=git@github.com:$repo.git
    ;;  

    *) exit 1 ;;
esac

printf 'Changing repo to %s\n' "$repo"
git remote set-url origin "$repo"
