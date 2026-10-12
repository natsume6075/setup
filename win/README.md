# Windows 環境構築

## OS の設定

以下をエクスプローラに入力すると設定画面を開ける。
別にあまり楽にならなずしゃらくさい。コマンドのみで済ませたいが。。。

URIスキームは、以下のサイトが参考になる。

https://www.atmarkit.co.jp/ait/articles/1707/11/news009_2.html

```shell
start ms-settings:hoge
```

- ms-settings:taskbar
  - Automatically hide the taskbar in desktop mode [ON]
  - Use small taskbar buttons [ON]
  - Taskbar location on screen [Top]
- ms-settings:developers
  - Developer Mode [ON]
- ms-settings:powersleep
  - Sleep > When plugged in, PC goes to sleep after [30 minutes]
  - Additional power settings > Choose what closing the lid does > When I close the lid: [Sleep, Do nothing]
  - (クラムシェルのために設定)
- ms-settings:devices-touchpad
  - 速度を変更する[max]
  - 右下右クリック[OFF]
  - ３本指ジェスチャ
  - スクロール方向
- ms-settings:mousetouchpad
  - Cursor speed [最高値]
  - Adjust mouse & cursor size > 大きく(3pt)、反転色、
  - Additional mouse options > ダブルクリック早く、
- start ms-settings:personalization-background
  - 壁紙を変更する
- ms-settings:easeofaccess-display
  - アニメーションをOFFにする。

@TODO 多分まだある

## Chocolatey

### Chocolatey のインストール

下記 URL からインストールのためのワンライナーをコピペし、powershell(root) で実行する。

https://chocolatey.org/install

### chocolatey でソフトをインストール

#### 必須なソフトたち

- win32yank: equalsraf/win32yank A clipboard tool for windows. clip.exe と違ってコマンドラインでクリップボードの読み込みもできる。主に WSL からクリップボードを触るために使用。nvim ならこれ入れるだけで reg: * と連携してくれる(魔法?)。vim が clopboard tool を認識できているかどうかは、checkhealth で確認可能。
- cica: 等幅フォント

``` shell
choco install -y keypirinha vivaldi autohotkey googleJapaneseInput quicklook microsoft-windows-terminal 7zip win32yank beeftext cica
```

#### 個人用PCなら必須なソフトたち

``` shell
choco install -y bitwarden evernote anki dropbox
```

#### 必要に応じて入れれば良いソフトたち

``` shell
choco install -y pandoc xmind steam adb mpc-hc wireshark androidstudio teraterm line virtualbox
```

#### WSL Linux コントリビューション

choco search ubuntu して、新しいの入れる

## Chocolatey で入らないソフトたち

- SylphyHorn: 仮想デスクトップの使い勝手向上。目的は、アニメーション無しでの切り替え・仮想デスクトップ間のウィンドウ移動。

## WSL 設定

### WSL2 Ubuntu の更新（agent harness 用）

既存の Ubuntu 20.04 は削除せず、新しい Ubuntu 24.04 LTS を別ディストリビューションとして導入する。
PowerShell で実行する。

```powershell
wsl --update
wsl --list --online
wsl --install -d Ubuntu-24.04
wsl --list --verbose
```

Ubuntu-24.04 の初回起動時にユーザーを作成する。セットアップ後の起動は `wsl -d Ubuntu-24.04`。
移行を検証するまで、古いディストリビューションに `wsl --unregister` を実行しない。

#### DNS / VPN / Proxy トラブル

古い `/etc/resolv.conf` 固定書き換えの前に、WSL更新と DNS tunneling を確認する。
Windows 11 22H2 以降の新しいWSLでは、通常 `dnsTunneling=true` が既定で有効。必要なら `%UserProfile%\.wslconfig` の既存内容を確認し、**上書きせず** `[wsl2]` セクションへ追加する。

```ini
[wsl2]
dnsTunneling=true
# 会社のプロキシを Windows 側から継承する必要がある場合だけ:
# autoProxy=true
```

`wsl --shutdown` で反映。Ubuntuで `getent hosts archive.ubuntu.com` と `sudo apt update` を確認する。
企業のVPN/Proxyが必要な環境では、既存の `linux/setup.sh` の設定方法を参照しつつ、まずWindows側のネットワーク設定を確認する。DNSだけでなくTLSやproxyの問題も切り分ける。

- [WSLインストール (Microsoft)](https://learn.microsoft.com/windows/wsl/install)
- [WSL DNS tunneling・proxy (Microsoft)](https://learn.microsoft.com/windows/wsl/networking)
- [WSL .wslconfig (Microsoft)](https://learn.microsoft.com/windows/wsl/wsl-config)

#### Koofr（Windows側）

[Koofr Desktop](https://koofr.eu/) をWindowsにインストールし、ログイン・同期フォルダ指定を行う。
WSL内へ二重にKoofrをインストールしない。WSLからは `/mnt/c/Users/<ユーザー名>/...` の実際の同期フォルダを使う。
Gitの作業ツリーはWSL側に置き、KoofrはObsidian Vault・成果物を同期する。

### Codexの導入

Ubuntu-24.04で [linux/README.md](../linux/README.md) の agent harness セクションに従う。

#### iPhoneのObsidianとKoofr Sync

iPhoneの標準「ファイル」アプリからKoofrのフォルダをそのままObsidian Vaultとして開くことはできない。Obsidian内のローカルVaultをKoofr Syncプラグインでクラウドと同期する。

1. [Koofr](https://koofr.eu/) のWeb設定から**アプリ専用パスワード**を作成する（通常パスワードや秘密情報をリポジトリに保存しない）。
2. iPhoneのObsidianでローカルVaultを作り、設定 → Community Plugins → Browse から [Koofr Sync](https://community.obsidian.md/plugins/koofr-sync) をインストール・有効化。
3. Koofr Sync設定にメールアドレス・アプリ専用パスワードを入力し、PCで同期しているVaultの**同じクラウドフォルダ**を指定。
4. 自動同期と競合処理を確認し、**PCでテストノート作成 → iPhoneに反映 → iPhoneで編集 → PCに反映** の往復テストを行う。
5. 同期はバックアップではない。誤削除・競合に備え、別媒体で履歴バックアップを用意し、復元も検証する。

- [Koofr Sync公式実装とセットアップ](https://github.com/bartekmp/koofr-obsidian-sync)
- [Koofr Sync — Obsidianプラグイン](https://community.obsidian.md/plugins/koofr-sync)

#### この環境に関する人力操作と検証

以下はOSやアプリのログイン・実機テストが必要で、自動セットアップでは実行しない。

- Windowsから新しいUbuntu 24.04を起動・初期ユーザー作成し、旧20.04を温存。
- 新UbuntuでDNS/Proxyを確認して [Linux用のCodexセットアップ](../linux/README.md) を実施。
- CodexのChatGPT認証（`codex login`）とワークスペース内での初回起動。
- Koofr Desktop導入・ログイン・同期先選択、iPhoneでのKoofr Sync有効化と往復テスト。
- 外部サービス接続（Google / Slack / LINE / GitHub）のOAuthや権限承認、Remote Controlの実機検証。
- 検証後に [setup Draft PR #2](https://github.com/natsume6075/setup/pull/2) をレビューし、問題がなければ `master` へマージ。

作業の状態・Codexへの恒久的な引き継ぎは [agent-workspaceのタスク台帳](https://github.com/natsume6075/agent-workspace/blob/main/.agents/docs/TASKS.md) で管理する。

## Windows-Termianl 設定

@TODO

/mnt/c/Users/natsu/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/

の中身を、Dropbox に置いておいて、URLを張る。

これもシンボリックリンクにしたほうがいいのか？

## VSCode を設定する

### VSCode で remote-WSL を設定

- VScode を起動して Remote-WSL をインストール
- ubuntu を起動、以下 ubuntu で実行
- apt

    ```shell
    sudo apt update
    sudo apt upgrade
    ```

- vscode を管理者権限で起動

    ```shell
    code .
    ```

### VSCode で Setting sync を設定

- Setting sync (VSCode のネイティブ設定) を設定する。

## AutoHotKey script

https://github.com/natsume6075/AutoHotKey-scripts

## vivaldi

- Sync を設定する

## logicool options

- ブラウザでインストールする
- なぜか「データ提供する」を選択しないとアプリ起動しないバグがあるので、提供しないを選択

## keypirinha

### Keypirinha Package Control を入れる

- keypirinha 起動
- F2
- 以下を入力
```
import keypirinha as kp,keypirinha_net as kpn,os;p="PackageControl.keypirinha-package";d=kpn.build_urllib_opener().open("https://github.com/ueffel/Keypirinha-PackageControl/releases/download/1.0.4/"+p);pb=d.read();d.close();f=open(os.path.join(kp.installed_package_dir(),p),"wb");f.write(pb);f.close()
```

### Keypirinha Pacage Control で入れたいパッケージ

Install Pacage "Keypirinha-WindwsApps"

microsoft store からインストールしたアプリを keypirinha で参照する。

## Android Studio

File > Manage IDE Settings > Settings Repository...

https://github.com/natsume6075/AndroidStudio_settings



