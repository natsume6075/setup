#!/bin/bash
AppsToInstall="zsh neovim tmux tree xdg-utils zip python3-pip"
# AppsToInstall="fish zsh neovim tmux tree xdg-utils zip python3-pip"
AppsToSetup=(dotfiles nvim bin agent-workspace)
# Fetch setup itself, but execute setup.sh only for AppsToSetup entries.
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

# Validation and failure logs live next to the invoked setup.sh (even for a
# standalone first-run copy). Create the directory only when something fails.
LOG_DIRECTORY="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIRECTORY/setup-$(date +%Y%m%d-%H%M%S)-$$.log"
HEALTH_FAILURES=0

LogFailure() {
    local label="$1" details="$2" output_file="${3:-}"
    mkdir -p -m 700 -- "$LOG_DIRECTORY" || { echo "Cannot create $LOG_DIRECTORY" >&2; return 1; }
    (
        umask 077
        {
            printf '[%s] FAIL %s\n%s\n' "$(date -Is)" "$label" "$details"
            if [ -n "$output_file" ] && [ -f "$output_file" ]; then
                printf '%s\n' '--- output ---'
                cat -- "$output_file"
            fi
            printf '%s\n\n' '--- end ---'
        } >> "$LOG_FILE"
    ) || return 1
    echo "FAIL: $label (details: $LOG_FILE)" >&2
}

# Preserve live command output while retaining output only if a step fails.
RunStep() {
    local label="$1" capture fifo workdir tee_pid status
    shift
    workdir="$(mktemp -d)" || return 1
    capture="$workdir/output"
    fifo="$workdir/pipe"
    if ! mkfifo -- "$fifo"; then rmdir "$workdir"; return 1; fi
    tee "$capture" < "$fifo" &
    tee_pid=$!
    # Do not pipe the command itself: functions such as Bootstrap and
    # PrepareLibWithDropbox must update variables in this shell.
    "$@" > "$fifo" 2>&1
    status=$?
    wait "$tee_pid" || status=1
    if [ "$status" -ne 0 ]; then
        LogFailure "$label" "exit code: $status" "$capture"
    fi
    rm -rf -- "$workdir"
    return "$status"
}

HealthCheck() {
    local label="$1" output status
    shift
    output="$("$@" 2>&1)"
    status=$?
    if [ "$status" -eq 0 ]; then
        printf 'PASS: %s\n' "$label"
    else
        HEALTH_FAILURES=$((HEALTH_FAILURES + 1))
        local capture
        capture="$(mktemp)" || return 1
        printf '%s\n' "$output" > "$capture"
        LogFailure "$label" "health check exit code: $status" "$capture"
        rm -f -- "$capture"
    fi
    return "$status"
}

AssertLink() {
    local link="$1" target="$2"
    [ -L "$link" ] && [ "$(readlink -f -- "$link")" = "$(realpath -e -- "$target")" ]
}

CheckAptCommands() {
    # Only called when the user chose to install apt packages.
    HealthCheck 'apt/zsh' zsh --version || true
    HealthCheck 'apt/nvim' nvim --version || true
    HealthCheck 'apt/tmux' tmux -V || true
    HealthCheck 'apt/tree' tree --version || true
    HealthCheck 'apt/xdg-open' xdg-open --version || true
    HealthCheck 'apt/zip' zip -v || true
    HealthCheck 'apt/pip3' pip3 --version || true
}

CheckApp() {
    case "$1" in
        dotfiles)
            HealthCheck 'dotfiles/.zshenv' AssertLink "$HOME/.zshenv" "$LIB_DIRECTORY/dotfiles/.zshenv" || true
            HealthCheck 'dotfiles/zsh' AssertLink "$HOME/.config/zsh" "$LIB_DIRECTORY/dotfiles/zsh" || true
            ;;
        nvim)
            # Dein/pynvim have their own y/n prompt inside nvim/setup.sh.
            # Do not treat their intentional omission as a failed check here.
            HealthCheck 'nvim/config' AssertLink "$HOME/.config/nvim" "$LIB_DIRECTORY/nvim" || true
            ;;
        bin)
            HealthCheck 'bin/link' AssertLink "$HOME/bin" "$LIB_DIRECTORY/bin/bin" || true
            ;;
        agent-workspace)
            # The installer checks the user-chosen (possibly nondefault) link.
            # A subshell must load nvm because child scripts cannot update this
            # process's PATH. Missing PATH here is NOT proof Codex is missing.
            HealthCheck 'agent-workspace/codex' bash -c '
                set -e
                export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
                test -s "$NVM_DIR/nvm.sh"
                . "$NVM_DIR/nvm.sh"
                nvm use --silent default >/dev/null
                command -v codex
                codex --version
                npm list -g --depth=0 @openai/codex
            ' || true
            if ! command -v codex >/dev/null 2>&1; then
                echo 'NOTE: This shell may not have loaded nvm yet. Open a new shell and check codex --version.'
                echo '      If it is still missing, run: source ~/.nvm/nvm.sh'
                echo '      Custom zsh ZDOTDIR configurations may need an explicit nvm initialization.'
            fi
            ;;
    esac
}


function GetConfirmation() {
    local input
    while true; do
        echo -e "$1 (y/n)"
        if ! read -r input; then
            LogFailure "input" "Unexpected end of input while prompting: $1"
            exit 1
        fi
        case "$input" in
            y) return 0 ;;
            n) return 1 ;;
            *) echo "Please enter y or n." ;;
        esac
    done
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

# Existing directories belong to the user: never pull, replace, or delete them.
# Only missing repository paths are fetched; this is not a repository health check.
function FetchMissingRepos() {
    local app archive staging
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
            # Extract beside the destination, then rename on success so a failed
            # download never leaves a partial directory that looks installed.
            staging="$(mktemp -d "$LIB_DIRECTORY/.${app}.tmp.XXXXXX")" || { rm -f "$archive"; return 1; }
            if ! tar -zxf "$archive" --strip-components 1 -C "$staging"; then
                rm -f "$archive"
                rm -rf -- "$staging"
                return 1
            fi
            rm -f "$archive"
            if ! mv -T -- "$staging" "$LIB_DIRECTORY/$app"; then
                rm -rf -- "$staging"
                return 1
            fi
        done
    else
        echo "SKIP: repository download (user selected n)"
        return 0
    fi
}

function PrepareLibWithoutDropbox() {
    if [ "$MANAGED_SETUP" = true ] || GetConfirmation "現在のディレクトリ直下に lib/ を作成してよろしいですか？"; then
        FetchMissingRepos
    else
        echo "SKIP: lib preparation (user selected n)"
        return 0
    fi
}

InstallAptApps() {
    # Ubuntu 26.04 sudo-rs does not support sudo -E.
    sudo env http_proxy="${http_proxy:-}" https_proxy="${https_proxy:-}" \
        HTTP_PROXY="${HTTP_PROXY:-}" HTTPS_PROXY="${HTTPS_PROXY:-}" \
        no_proxy="${no_proxy:-}" add-apt-repository ppa:neovim-ppa/unstable &&
    sudo apt update &&
    sudo apt install -y $AppsToInstall
}

RunStep 'network/bootstrap' Bootstrap || exit 1

if GetConfirmation "Install following apps by apt?\n${AppsToInstall// /'\n'}\n" ; then
    RunStep 'apt/install' InstallAptApps || exit 1
    CheckAptCommands
else
    echo 'SKIP: apt installation and checks (user selected n)'
fi

# Managed reruns reuse their lib. A standalone run may use Dropbox.
if [ "$MANAGED_SETUP" = true ]; then
    RunStep 'repos/prepare' PrepareLibWithoutDropbox || exit 1
elif GetConfirmation "Download the library for setup. Use Dropbox?" ; then
    PrepareLibWithDropbox
    RunStep 'repos/prepare' FetchMissingRepos || exit 1
else
    RunStep 'repos/prepare' PrepareLibWithoutDropbox || exit 1
fi

for app in "${AppsToSetup[@]}"; do
    echo ""
    if GetConfirmation "Set up $app?" ; then
        echo "--- start setup $app ---"
        if [ ! -f "$LIB_DIRECTORY/$app/setup.sh" ]; then
            echo "SKIP: setup/$app (repository not available)"
            continue
        fi
        RunStep "setup/$app" bash "$LIB_DIRECTORY/$app/setup.sh" || exit 1
        CheckApp "$app"
        echo "--- finish setup $app ---"
    else
        echo "SKIP: setup/$app and checks (user selected n)"
    fi
done

if [ "$HEALTH_FAILURES" -ne 0 ]; then
    echo "Validation failed: $HEALTH_FAILURES check(s). See $LOG_FILE" >&2
    exit 1
fi
echo "Selected setup tasks and health checks completed."
