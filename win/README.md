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

## Chocolatey で入らないソフトたち

- SylphyHorn: 仮想デスクトップの使い勝手向上。目的は、アニメーション無しでの切り替え・仮想デスクトップ間のウィンドウ移動。

## WSL2 — Ubuntu 24.04 LTS

Windows PowerShellから操作する。WSLの更新・Ubuntuの新規導入・旧ディストリビューションの削除は、次の順に行う。

### 1. WSLを更新し、Ubuntu 24.04を導入する

```powershell
wsl --update
wsl --list --online
wsl --install -d Ubuntu-24.04
wsl --list --verbose
wsl -d Ubuntu-24.04
```

Ubuntu初回起動時にLinuxユーザー名とパスワードを設定する。Ubuntuのターミナルで以下を実行し、24.04の起動とネットワークを確認する。

```bash
cat /etc/os-release
getent hosts archive.ubuntu.com
sudo apt update
```

問題なければPowerShellへ戻り、Ubuntu 24.04を既定のディストリビューションにする。

```powershell
wsl --set-default Ubuntu-24.04
wsl --list --verbose
```

### 2. DNS・VPN・プロキシのトラブルシュート

まず `wsl --update`、Windows側のVPN・プロキシ設定、新Ubuntuでの `getent hosts archive.ubuntu.com` と `sudo apt update` の結果を確認する。古い環境の `/etc/resolv.conf` をそのままコピーしない。

Windows 11 22H2以降では、DNS tunnelingは通常既定で有効。DNS解決に失敗する場合のみ、PowerShellで `notepad $env:USERPROFILE\.wslconfig` を開き、既存内容を保ったまま以下を設定する（既に `[wsl2]` があれば重複させず、その下に追加）。

```ini
[wsl2]
dnsTunneling=true
# Windows側でHTTPプロキシを利用している場合だけ必要に応じて:
# autoProxy=true
```

変更したらPowerShellで `wsl --shutdown` を実行し、Ubuntuを再起動して名前解決・aptを再検証する。DNS解決、HTTPプロキシ、証明書の問題は分けて切り分ける。

- [WSLインストール — Microsoft](https://learn.microsoft.com/ja-jp/windows/wsl/install)
- [WSL DNS・ネットワーク — Microsoft](https://learn.microsoft.com/ja-jp/windows/wsl/networking)
- [WSL .wslconfig — Microsoft](https://learn.microsoft.com/ja-jp/windows/wsl/wsl-config)

### 3. 旧Ubuntuディストリビューションを削除する

**新Ubuntuの起動・ネットワークが正常であることを確認してから行う。** 旧ディストリビューション内のファイル・設定・インストール済みアプリは `wsl --unregister` で完全に消える。必要なGit未pushの変更、SSH鍵、dotfiles、個人ファイルなどがないか先に確認する。

PowerShellで登録名を確認し、**旧Ubuntuに一致する正確な名前**を指定する。以下の `Ubuntu-20.04` は例。実際には `Ubuntu` など別の名前になっている場合がある。

```powershell
wsl --list --verbose
wsl -d Ubuntu-20.04 -- cat /etc/os-release
```

必要なデータの退避には、旧ディストリビューション全体をWindows側へエクスポートできる。バックアップファイルは機密情報を含み得るため安全に保管する。

```powershell
wsl --export Ubuntu-20.04 "$env:USERPROFILE\ubuntu20-backup.tar"
Get-Item "$env:USERPROFILE\ubuntu20-backup.tar"
```

**確認した旧ディストリビューションだけ**を削除する。バックアップと必要データの確認後、以下を実行する。

```powershell
wsl --unregister Ubuntu-20.04
wsl --list --verbose
```

上の3箇所の `Ubuntu-20.04` は、すべて実際の旧ディストリビューション名に置き換える。**`Ubuntu-24.04` を指定しないこと。**

- [WSLのエクスポート・登録解除 — Microsoft](https://learn.microsoft.com/ja-jp/windows/wsl/basic-commands)

### 4. Linux環境とCodexをセットアップする

[linux/README.md](../linux/README.md) にある共通の `setup.sh` をUbuntu 24.04で実行し、`AppsToSetup` の `agent-workspace` を選択する。Codex固有の導入は [agent-workspace/setup.sh](https://github.com/natsume6075/agent-workspace/blob/main/setup.sh) に集約している。

PR検証中は `setup` の `feat/add-agent-harness` を取得して実行する。Linuxセットアップの動作検証後、[PR #2](https://github.com/natsume6075/setup/pull/2) をレビュー・マージする。ログイン後の作業と残タスクは [agent-workspaceのタスク台帳](https://github.com/natsume6075/agent-workspace/blob/main/.agents/docs/TASKS.md) で管理する。

### 5. KoofrとiPhone Obsidian

[Koofr Desktop](https://koofr.eu/) をWindowsに導入してログインし、同期フォルダを設定する。WSLからはWindows側の実際の同期パス（通常 `/mnt/c/Users/<ユーザー名>/...`）を参照する。**Gitの作業ツリーをKoofrで二重同期しない。**

iPhoneではObsidianのローカルVaultに [Koofr Sync](https://github.com/bartekmp/koofr-obsidian-sync) プラグインをインストールし、Koofrのアプリ専用パスワードとPC側のVaultに対応するクラウドフォルダを設定する。PCでテストノートを作る→iPhoneで確認・編集する→PCで反映を確認する、という往復テストを行う。同期はバックアップの代用にならない。

外部サービスのOAuth/認証、Remote Controlの実機検証、バックアップは、[agent-workspaceのタスク台帳](https://github.com/natsume6075/agent-workspace/blob/main/.agents/docs/TASKS.md) に引き継ぐ。

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



