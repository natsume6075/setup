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

function Bootstrap() {
    if [ ! -f ~/.proxy_env ]; then
        read -p "Corporate proxy URL (e.g. http://172.x.x.x:8080): " _p
        read -p "Corporate DNS servers, space-separated (e.g. 10.x.x.x 10.x.x.x, blank to skip): " _dns
        read -p "DNS search domains, space-separated (e.g. corp.example.com, blank to skip): " _domains
        cat > ~/.proxy_env <<'ENVEOF'
# Corporate proxy — edit this file to change these values
_P=PROXY_PLACEHOLDER
export http_proxy=$_P
export https_proxy=$_P
export HTTP_PROXY=$_P
export HTTPS_PROXY=$_P
# no_proxy: hosts/domains/IP ranges that bypass the proxy. Add internal domains as needed.
export no_proxy="127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
unset _P

export CORP_DNS="DNS_PLACEHOLDER"
export CORP_DOMAINS="DOMAINS_PLACEHOLDER"
ENVEOF
        sed -i "s|PROXY_PLACEHOLDER|$_p|" ~/.proxy_env
        sed -i "s|DNS_PLACEHOLDER|$_dns|" ~/.proxy_env
        sed -i "s|DOMAINS_PLACEHOLDER|$_domains|" ~/.proxy_env
    fi

    . ~/.proxy_env

    printf "Acquire::http::Proxy \"$http_proxy\";\nAcquire::https::Proxy \"$http_proxy\";\n" \
        > /tmp/99proxy.conf
    sudo cp /tmp/99proxy.conf /etc/apt/apt.conf.d/99proxy.conf

    if [ -n "$CORP_DNS" ]; then
        sudo mkdir -p /etc/systemd/resolved.conf.d
        printf "[Resolve]\nDNS=$CORP_DNS\n${CORP_DOMAINS:+Domains=$CORP_DOMAINS\n}DNSSEC=no\n" \
            > /tmp/dns.conf
        sudo cp /tmp/dns.conf /etc/systemd/resolved.conf.d/dns.conf
        sudo systemctl restart systemd-resolved
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


Bootstrap

# If necessary, install apps by apt.
if GetConfirmation "Install following apps by apt?\n${AppsToInstall// /'\n'}\n" ; then

    # apt の stable バージョンでは lua とかはいっていない(required by dein)ので unstable から取ってくる。
    sudo -E add-apt-repository ppa:neovim-ppa/unstable

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
