#!/bin/bash
AppsToInstall="zsh neovim tmux tree xdg-utils zip python3-pip"
# AppsToInstall="fish zsh neovim tmux tree xdg-utils zip python3-pip"
AppsToSetup=(dotfiles nvim bin)
# AppsToSetup=(dotfiles nvim fish bin)

function GetConfirmation() {
    echo -e "$1 (y/n)"
    read input
    if [ "$input" = 'y' ] ; then
        return 0
    elif [ "$input" = 'n' ] ; then
        return 1
    else
        GetConfirmation "$1"
    fi
}

function PrepareLibWithDropbox() {
    if [ -d ${HOME}/Dropbox/lib ] ; then
        LIB_DIRECTORY="${HOME}/Dropbox/lib"
    else
        echo "まだ ~/Dropbox/lib が存在しません。以下を実行して同期を待った後、再実行してください。"
	echo "apt install -y nautilus-dropbox"
        echo "dropbox start -i"
        exit 0
    fi
}

function PrepareLibWithoutDropbox() {
    if GetConfirmation "現在のディレクトリ直下に lib/ を作成してよろしいですか？" ; then
        LIB_DIRECTORY="./lib"
        mkdir lib

	if GetConfirmation "Download all libraries included in AppsToSetup from my repositories BY GIT CLONE." ; then
            for app in "${AppsToSetup[@]}"
            do
		echo "clone $app"
		git clone git@github.com:natsume6075/$app.git $LIB_DIRECTORY/$app
            done
	elif GetConfirmation "Download all libraries included in AppsToSetup from my repositories BY CURL." ; then
            for app in "${AppsToSetup[@]}"
            do
                curl -sSLo $app.tar.gz https://github.com/natsume6075/$app/tarball/master
                mkdir $LIB_DIRECTORY/$app
                tar -zxf $app.tar.gz --strip-components 1 -C $LIB_DIRECTORY/$app
                rm $app.tar.gz
            done
	fi

    else
        echo "Abort setup."
        exit 0
    fi
}


# If necessary, install apps by apt.
if GetConfirmation "Install following apps by apt?\n${AppsToInstall// /'\n'}\n" ; then

    # apt の stable バージョンでは lua とかはいっていない(required by dein)ので unstable から取ってくる。
    sudo add-apt-repository ppa:neovim-ppa/unstable

    sudo apt update
    sudo apt install -y $AppsToInstall
fi

# Download the library via Dropbox or curl, then set LIB_DIRECTORY.
if GetConfirmation "Download the library for setup. Use Dropbox?" ; then
    PrepareLibWithDropbox
else
    PrepareLibWithoutDropbox
fi

# Traverse all setup.sh.
for app in "${AppsToSetup[@]}"
do
    echo ""
    if GetConfirmation "Set up $app?" ; then
        echo "--- start setup $app ---"
        bash $LIB_DIRECTORY/$app/setup.sh
        echo "--- finish setup $app ---"
    fi
done
