# Linux 環境構築

```bash
curl -sSLo setup.sh https://raw.githubusercontent.com/natsume6075/setup/master/linux/setup.sh
bash setup.sh
rm setup.sh
```

上のコマンドを実行すると、以下ができる。

- lib/ の準備
    - Dropbox を使うなら、Dropbox をセットアップする。
    - そうでないなら ./lib を作成し、各ライブラリをリポジトリからダウンロードし、lib 配下に配置する。
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

