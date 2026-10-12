#!/bin/bash
AppsToInstall="zsh neovim tmux tree xdg-utils zip python3-pip"
# AppsToInstall="fish zsh neovim tmux tree xdg-utils zip python3-pip"
AppsToSetup=(dotfiles nvim bin agent-workspace)
ReposToFetch=(setup "${AppsToSetup[@]}")
# AppsToSetup=(dotfiles nvim fish bin)

# A standalone downloaded setup.sh uses the caller's directory; a managed
# lib/setup/linux/setup.sh always uses its own lib, regardless of the caller's cwd.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [ "$(basename -- "$SCRIPT_DIR")" = linux ] &&
   [ "$(basename -- "$(dirname -- "$SCRIPT_DIR")")" = setup ] &&
   [ "$(basename -- "$(dirname -- "$(dirname -- "$SCRIPT_DIR")")")" = lib ] &&
   [ -f "$SCRIPT_DIR/../win/README.md" ]; then
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
    if [ -d "${HOME}/Dropbox/lib" ] ; then
        LIB_DIRECTORY="${HOME}/Dropbox/lib"
    else
        echo "まだ ~/Dropbox/lib が存在しません。同期後に再実行してください。"
        return 1
    fi
    PrepareRepos
}

# Download only missing repositories. Existing trees (including local changes)
# are never overwritten or implicitly updated on subsequent runs.
function PrepareRepos() {
    mkdir -p -- "$LIB_DIRECTORY" || return 1

    local app path mode archive
    local missing=()
    for app in "${ReposToFetch[@]}"; do
        path="$LIB_DIRECTORY/$app"
        if [ -e "$path" ] || [ -L "$path" ]; then
            if [ ! -d "$path" ]; then
                echo "Repository path exists but is not a directory: $path" >&2
                return 1
            fi
            echo "Keep existing repository: $path"
        else
            missing+=("$app")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "All repositories already exist in $LIB_DIRECTORY"
        return 0
    fi

    if GetConfirmation "Download missing repositories BY GIT CLONE?" ; then
        mode=git
    elif GetConfirmation "Download missing repositories BY CURL?" ; then
        mode=curl
    else
        echo "Repository download cancelled." >&2
        return 1
    fi

    for app in "${missing[@]}"; do
        path="$LIB_DIRECTORY/$app"
        if [ "$mode" = git ]; then
            git clone "https://github.com/natsume6075/$app.git" "$path" || return 1
        else
            archive="$(mktemp)" || return 1
            if ! curl -fsSL -o "$archive" "https://api.github.com/repos/natsume6075/$app/tarball"; then
                rm -f -- "$archive"
                return 1
            fi
            mkdir -p -- "$path" || { rm -f -- "$archive"; return 1; }
            if ! tar -xzf "$archive" --strip-components=1 -C "$path"; then
                rm -f -- "$archive"
                echo "Extraction failed for $app; check incomplete directory: $path" >&2
                return 1
            fi
            rm -f -- "$archive"
        fi
    done
}

function PrepareLibWithoutDropbox() {
    PrepareRepos
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

# Managed reruns always use their existing lib; standalone runs may use Dropbox.
if [ "$MANAGED_SETUP" = true ]; then
    PrepareRepos || exit 1
elif GetConfirmation "Download the library for setup. Use Dropbox?" ; then
    PrepareLibWithDropbox || exit 1
else
    PrepareLibWithoutDropbox || exit 1
fi

# Traverse all application setup.sh files; setup itself is only fetched.
for app in "${AppsToSetup[@]}"
do
    echo ""
    if GetConfirmation "Set up $app?" ; then
        echo "--- start setup $app ---"
        if [ ! -f "$LIB_DIRECTORY/$app/setup.sh" ]; then
            echo "Missing setup script: $LIB_DIRECTORY/$app/setup.sh" >&2
            exit 1
        fi
        bash "$LIB_DIRECTORY/$app/setup.sh" || exit 1
        echo "--- finish setup $app ---"
    fi
done
