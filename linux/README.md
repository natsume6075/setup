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

## その他やること

echo set fish as default shell: chsh - which fish

