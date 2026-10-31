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

初回にDropboxを使わない場合、ダウンロードした `setup.sh` を起動したディレクトリの直下に `lib/` を作成する。Dropboxを選んだ場合は `~/Dropbox/lib` を利用する。どちらの場合も `lib/` に `setup/` 自身を取得する。次回からは `lib/setup/linux/setup.sh` を実行すれば、実行時のカレントディレクトリに関係なく同じ `lib/` を利用する。

```bash
bash /work/lib/setup/linux/setup.sh  # /work/lib は実際の配置先に置き換える
```

既存リポジトリは自動で上書き・更新せず、不足しているものだけ取得する。Git管理の場合、更新は必要に応じて明示的に行う。

## セットアップ後の確認

```bash
# OS・パッケージ・ネットワーク
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

# agent-workspace のリンク（セットアップ時の既定位置を選んだ場合）
readlink -f ~/agent-workspace
```

出力が実際の `agent-workspace` リポジトリを指していることを確認する。リンクの場所をカスタマイズした場合は読み替える。

## 自動チェックと失敗ログ

セットアップ後に、選択した項目の動作を自動確認する。失敗した場合は、実行した `setup.sh` と同じディレクトリの `logs/` に記録する。ユーザーが `n` を選んだ項目は検証をスキップする。

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

## ローカルAIとGitHub CLI

`gh` は `AppsToInstall` に含み、apt導入のy/n選択に従う。認証は通常ユーザーが `gh auth login` で行う。

`local-llm` と `local-image-gen` は `AppsToSetup` のy/n選択後、それぞれのリポジトリ直下の `setup.sh` を実行する。privateリポジトリは選択した場合だけHTTPSでcloneするため、事前にGitHub認証が必要。`n` では取得・導入・検証をしない。
既存の `~/llm` と `~/image-gen` を優先し、新規取得時は通常どおり `lib/<repo名>` を使用する。既存ディレクトリは更新・上書きしない。

- local-llm: Docker/GPU基盤、Ollama、モデル、コマンド登録を所有する。必要なら子setup内でもy/n確認する。
- local-image-gen: Docker/GPU基盤はlocal-llmの `setup.sh --host-only` を再利用し、ComfyUI・SD 1.5・CLIを導入する。
- モデル重みと生成画像は各プロジェクトのGit対象外。手順・検証・復元方法は各READMEを参照。

旧 `setup-local-llm-docker.sh` と `setup-github-cli.sh` は廃止。中央の `setup.sh` または各repoの `setup.sh` を通常ユーザーで実行する。sudoers・dockerグループ・Windows GPUドライバーは変更しない。
GitHub認証情報をGitやチャットへ記録しない。dotfiles利用時の認証helperは `~/.config/git/local.inc` に置く。
