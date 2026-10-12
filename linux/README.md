# Linux 環境構築

## 自動化スクリプト setup.sh

```bash
curl -sSLo setup.sh https://raw.githubusercontent.com/natsume6075/setup/master/linux/setup.sh
bash setup.sh
rm setup.sh
```

WSL でDNSエラーが出る場合は、まず [Windows側のWSL/DNS手順](../win/README.md) を参照。古い固定DNSの変更を行う前にWSL更新とDNS tunnelingを確認する。

社内プロキシ環境下では、初回実行時にプロキシ URL の入力を求められる。入力すると `~/.proxy_env` が生成され、apt・git・curl のネットワーク設定が自動で行われる。


上のコマンドを実行すると、以下ができる。

- アプリのインストール
    - setup.sh で定義する変数 AppsToInstall のアプリがインストールされる
- アプリのセットアップ
    - setup.sh で定義する変数 AppsToSetup のアプリがセットアップされる
        - 制限事項: 以下の名前が全て一致している必要がある
            - AppsToSetup の要素名
            - Dropbox 内のディレクトリ名
            - リポジトリ名
            - シンボリックリンクのディレクトリ名
    - lib/ の準備
        - Dropbox を使うなら、Dropbox をセットアップする。
        - そうでないなら ./lib を作成し、各ライブラリをリポジトリからダウンロードし、lib 配下に配置する。(git clone / curl)
    - lib/ 中の各 setup.sh を実行

## 再実行

初回は、上記のコマンドを実行した**カレントディレクトリ直下**に `lib/` を作成する（例: `/work/lib`）。
`lib/` には `setup/` 自身も取得される。2回目以降はその中のスクリプトから起動する。どのディレクトリから実行しても、スクリプトが存在する `lib/` を使用する。

```bash
bash /work/lib/setup/linux/setup.sh  # /work/lib は実際の配置先に置き換える
```

既に存在するリポジトリは自動取得・上書きしない。不足するリポジトリだけ追加する。既存リポジトリの更新は必要に応じてGitで行う。

## セットアップ後の確認

```bash
# OS・パッケージとネットワーク
cat /etc/os-release
sudo apt update
nvim --version
tmux -V
zsh --version

# Codex (agent-workspace/setup.sh を実行した場合)
source ~/.nvm/nvm.sh
node --version
npm --version
codex --version

# lib の配置とGit管理（Git clone方式の場合）
LIB_DIRECTORY=/work/lib  # 初回に作成した実際のlibに置き換える
ls -la "$LIB_DIRECTORY"
git -C "$LIB_DIRECTORY/setup" status --short --branch
git -C "$LIB_DIRECTORY/agent-workspace" status --short --branch

# agent-workspace のアクセス用リンク（入力時に既定値を選んだ場合）
readlink -f ~/agent-workspace
```

`readlink -f` の出力が `$LIB_DIRECTORY/agent-workspace` と一致することを確認する。リンクの場所を変更した場合は、その指定パスで確認する。curl方式の場合はGit履歴がないため `git status` は対象外。

## そのた自動化していないこと

### デフォルトシェルの設定
chsh - which fish

### ssh key の用意と登録

```bash
cd
mkdir .ssh
cd .ssh
ssh-keygen
```

```bash
cat id_rsa.pub | clip.exe
clip < id_rsa.pub
pbcopy < id_rsa.pub
```

github で登録

- Settings > SSH and GPG keys > New SSH key


### shell theme

```bash
omf install pure
omf theme pure
```
