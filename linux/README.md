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


## Agent harness (Codex / WSL2)

既存の `setup.sh` は変更せず、Codex用の追加セットアップを独立スクリプトで実施する。
先にWindowsの [WSL設定](../win/README.md) で Ubuntu 24.04 LTSを準備する。

```bash
# Ubuntu 24.04 のターミナルで実行
curl -fsSLo setup-agent-harness.sh https://raw.githubusercontent.com/natsume6075/setup/feat/add-agent-harness/linux/setup-agent-harness.sh
# 実行前にファイルの内容を確認
less setup-agent-harness.sh
bash setup-agent-harness.sh
rm setup-agent-harness.sh

# ChatGPTで認証（ブラウザ操作が必要）
codex login

# 初回ワークスペースへ
cd ~/workspace/agent-workspace
codex
```

- Node.js LTS がなければ nvm経由で導入し、Codex CLI をインストールする。
- `natsume6075/agent-workspace` をクローンし、未作成なら共通指示と引き継ぎ資料をコピーする。
- clone先は [agent-workspace](https://github.com/natsume6075/agent-workspace) を正本とする。`README.md`・`AGENTS.md`・`.agents/docs/TASKS.md`・`.agents/docs/HANDOFF.md`・`.codex/config.toml` をGit管理済み。自動セットアップはこれらを上書きしない。
- Windows側で [Koofr Desktop](https://koofr.eu/) をセットアップする。Linux作業ツリーをクラウド同期フォルダへ移動しない。インストールやiPhone操作は [Windows・端末手順](../win/README.md) を参照。
- iPhoneのObsidian同期には [Koofr Sync](https://community.obsidian.md/plugins/koofr-sync) を使用し、PCとの往復編集テストを行う（認証や実機検証は人間の作業）。
- [Codex CLI](https://github.com/openai/codex) / [nvm](https://github.com/nvm-sh/nvm)

`feat/add-agent-harness` の検証・Draft PRレビューを経てマージする際、ダウンロードURLのブランチを `master` に更新する。以後のタスク管理・Codexへの引き継ぎの正本は [agent-workspace/.agents/docs/](https://github.com/natsume6075/agent-workspace/tree/main/.agents/docs) にある。

