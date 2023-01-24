#!/usr/bin/env bash
cd /home/drishal/dotfiles/
git add .
# echo 'Enter the commit message:'
# read commitMessage
commitMessage="update dotfiles"
git commit -m "$commitMessage"

# echo 'Enter the name of the branch:'
# read branch
git push --all

# git push origin $branch

# read
