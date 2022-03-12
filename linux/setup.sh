#!/bin/bash
AppToSetup=(dotfiles nvim fish bin)

function GetConfirmation() {
    echo "$1 (y/n)"
    read input
    if [ "$input" = 'y' ] ; then
        return 1
    elif [ "$input" = 'n' ] ; then
        return 0
    else
        GetConfirmation "$1"
    fi
}

function PrepareLibWithDropbox() {
    dropbox start -i
    LIB_DIRECTORY="${HOME}/Dropbox/lib"
}

function PrepareLibWithoutDropbox() {
    if GetConfirmation "現在のディレクトリ直下に lib/ を作成してよろしいですか？" ; then
        echo "Abort setup."
        exit 0
    fi
    LIB_DIRECTORY="./lib"
    mkdir lib

    # Download all libraries included in AppToSetup from my repositories.
    for app in "${AppToSetup[@]}"
    do
        curl -sSLo $app.tar.gz https://github.com/natsume6075/$app/tarball/master
        mkdir $LIB_DIRECTORY/$app
        tar -zxf $app.tar.gz --strip-components 1 -C $LIB_DIRECTORY/$app
        rm $app.tar.gz
    done
}


# If necessary, install apps by apt.
if ! GetConfirmation "Install many many apps by apt?" ; then
    sudo apt update
    sudo apt install -y fish zsh neovim tmux tree xdg-utils zip nautilus-dropbox
fi

# Download the library via Dropbox or curl, then set LIB_DIRECTORY.
if ! GetConfirmation "Download the library for setup. Use Dropbox?" ; then
    PrepareLibWithDropbox
else
    PrepareLibWithoutDropbox
fi

# Traverse all setup.sh.
for app in "${AppToSetup[@]}"
do
    echo ""
    if ! GetConfirmation "Set up $app?" ; then
        echo "--- start setup $app ---"
        bash $LIB_DIRECTORY/$app/setup.sh
        echo "--- finish setup $app ---"
    fi
done

