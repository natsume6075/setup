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
    if [ -d ${HOME}/Dropbox/lib ] ; then
        LIB_DIRECTORY="${HOME}/Dropbox/lib"
    else
        echo "まだ ~/Dropbox/lib が存在しません。以下を実行して同期を待った後、再実行してください。"
        echo "dropbox start -i"
        exit 0
    fi
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
    # apt の stable バージョンでは lua とかはいっていない(required by dein)ので unstable から取ってくる。
    sudo add-apt-repository ppa:neovim-ppa/unstable

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

