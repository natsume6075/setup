#!/bin/sh

echo "Install many many apps? (y/[other])"
read input
if [ $input = 'y' ] ; then
    sudo apt update
    sudo apt install -y fish zsh neovim tmux tree xdg-utils zip nautilus-dropbox

    # Install daemon and start dropbox, open URL to link Dropbox account.
    dropbox start -i
fi

echo set fish as default shell: chsh - which fish

