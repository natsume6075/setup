#!/bin/bash
AppsToInstall="zsh neovim tmux tree xdg-utils zip python3-pip"
# AppsToInstall="fish zsh neovim tmux tree xdg-utils zip python3-pip"
AppsToSetup=(dotfiles nvim bin agent-workspace)
ReposToFetch=(setup "${AppsToSetup[@]}")
# AppsToSetup=(dotfiles nvim fish bin)

# A standalone script uses the caller's directory. The managed copy uses its own lib.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ "$SCRIPT_DIR" == */lib/setup/linux ]] && [ -f "$SCRIPT_DIR/../win/README.md" ]; then
    LIB_DIRECTORY="$(cd -- "$SCRIPT_DIR/../.." && pwd -P)"
    MANAGED_SETUP=true
else
    LIB_DIRECTORY="$PWD/lib"
    MANAGED_SETUP=false
fi

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

# ネットワーク設定を行う。初回のみ対話入力で ~/.proxy_env を生成し、以降はそれを読む。
function Bootstrap() {
    # 初回のみ入力を求めて ~/.proxy_env を生成（proxy IP 等はローカルに留め repo に含めない）
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

    # proxy 設定を現セッションに適用（以降の git clone / curl / apt が proxy 経由になる）
    . ~/.proxy_env

    # git@github.com: を https://github.com/ に読み替え（dotfiles clone 前から必要）
    git config --global url."https://github.com/".insteadOf "git@github.com:"

    # apt 用 proxy 設定（apt は env var を参照しないため専用ファイルが必要）
    printf "Acquire::http::Proxy \"$http_proxy\";\nAcquire::https::Proxy \"$http_proxy\";\n" \
        > /tmp/99proxy.conf
    sudo cp /tmp/99proxy.conf /etc/apt/apt.conf.d/99proxy.conf

    # DNS 設定（CORP_DNS が指定された場合のみ）
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

# Keep existing repositories untouched and obtain missing ones only.
function FetchMissingRepos() {
    local app archive
    mkdir -p "$LIB_DIRECTORY" || return 1
    local missing=()
    for app in "${ReposToFetch[@]}"; do
        if [ -e "$LIB_DIRECTORY/$app" ] || [ -L "$LIB_DIRECTORY/$app" ]; then
            if [ ! -d "$LIB_DIRECTORY/$app" ]; then
                echo "Not a directory: $LIB_DIRECTORY/$app" >&2
                return 1
            fi
        else
            missing+=("$app")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "All repositories already exist in $LIB_DIRECTORY"
        return 0
    fi

    if GetConfirmation "Download missing repositories BY GIT CLONE?" ; then
        for app in "${missing[@]}"; do
            git clone "git@github.com:natsume6075/$app.git" "$LIB_DIRECTORY/$app" || return 1
        done
    elif GetConfirmation "Download missing repositories BY CURL?" ; then
        for app in "${missing[@]}"; do
            archive="$(mktemp)" || return 1
            if ! curl -fsSLo "$archive" "https://api.github.com/repos/natsume6075/$app/tarball"; then
                rm -f "$archive"
                return 1
            fi
            mkdir -p "$LIB_DIRECTORY/$app" || return 1
            if ! tar -zxf "$archive" --strip-components 1 -C "$LIB_DIRECTORY/$app"; then
                rm -f "$archive"
                return 1
            fi
            rm -f "$archive"
        done
    else
        echo "Repository download cancelled." >&2
        return 1
    fi
}

function PrepareLibWithoutDropbox() {
    if [ "$MANAGED_SETUP" = true ] || GetConfirmation "現在のディレクトリ直下に lib/ を作成してよろしいですか？"; then
        FetchMissingRepos
    else
        echo "Abort setup."
        return 1
    fi
}

Bootstrap

# If necessary, install apps by apt.
if GetConfirmation "Install following apps by apt?\n${AppsToInstall// /'\n'}\n" ; then

    # apt の stable バージョンでは lua とかはいっていない(required by dein)ので unstable から取ってくる。
    # sudo-rs (Ubuntu 26.04) does not support -E; pass only the network settings needed by add-apt-repository.
    sudo env http_proxy="${http_proxy:-}" https_proxy="${https_proxy:-}" \
        HTTP_PROXY="${HTTP_PROXY:-}" HTTPS_PROXY="${HTTPS_PROXY:-}" \
        no_proxy="${no_proxy:-}" add-apt-repository ppa:neovim-ppa/unstable

    sudo apt update
    sudo apt install -y $AppsToInstall
fi

# Reuse the managed lib on repeat runs; standalone runs can still choose Dropbox.
if [ "$MANAGED_SETUP" = true ]; then
    PrepareLibWithoutDropbox || exit 1
elif GetConfirmation "Download the library for setup. Use Dropbox?" ; then
    PrepareLibWithDropbox
    FetchMissingRepos || exit 1
else
    PrepareLibWithoutDropbox || exit 1
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
