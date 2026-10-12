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

既存の `setup.sh` の `AppsToSetup` に `agent-workspace` を追加した。他のアプリケーションと同様に、`agent-workspace` の取得と、そのリポジトリにある `setup.sh` の実行を選べる。Codex固有のインストール処理は [agent-workspace/setup.sh](https://github.com/natsume6075/agent-workspace/blob/main/setup.sh) に集約する。

Ubuntu 24.04は先に [Windows側のWSL設定](../win/README.md) に従って導入する。通常の環境構築と同じように、ページ先頭の `setup.sh` を実行し、確認画面で `agent-workspace` のセットアップを選択する。

- 外部ライブラリの取得時は、Dropboxを使わない場合にGit clone方式を選べる。既存の `dotfiles`、`nvim`、`bin` と同じ `lib/agent-workspace` にcloneされる。
- `agent-workspace` だけを設定したい場合は、既存の `AppsToSetup` の対話確認で他をスキップする。
- 取得済みリポジトリから直接 `bash setup.sh` することも可能。clone先の絶対パスは任意。
- 初回認証のみ `codex login` を実施し、`agent-workspace` のルートで `codex` を起動する。
- 詳細な作業・タスク・引き継ぎの正本は [agent-workspace](https://github.com/natsume6075/agent-workspace) 内の `.agents/docs/`。別リポジトリに同じ資料を複製しない。

Windows版KoofrとiPhoneのKoofr Syncは [Windows側の手順](../win/README.md) を参照。認証や実機テストは人間が行い、結果はagent-workspaceのタスク台帳に記録する。

- [Codex CLI](https://github.com/openai/codex)
- [nvm](https://github.com/nvm-sh/nvm)
