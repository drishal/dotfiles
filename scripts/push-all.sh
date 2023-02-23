#!/usr/bin/env bash
echo -e '\033[1mPushing dotfiles\033[0m'
bash ~/dotfiles/scripts/push.sh 
echo -e '\033[1mPushing Notes\033[0m'
bash ~/notes/push.sh 
