#!/usr/bin/env bash
echo -e "\033[1mPushing dotfiles"
bash ~/dotfiles/push.sh 
echo -e "\033[1mPushing notes"
bash ~/notes/push.sh 
