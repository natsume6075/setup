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

``` shell
choco install -y keypirinha vivaldi autohotkey googleJapaneseInput quicklook microsoft-windows-terminal 7zip QTTabBar win32yank beeftext cica
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

### WSL install

https://aka.ms/wslinstall

### linux に入る

- ubuntu アプリを起動
- アカウント情報入れる
- terminal でプロファイルが参照できるようになる

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

- Setting sync のインストール
- Setting sync する

## AutoHotKey script

https://github.com/natsume6075/AutoHotKey-scripts

## font をインストール

https://github.com/edihbrandon/RictyDiminished

- RictyDiminished-Regular
- RictyDiminished Regular for Powerline


## vivaldi

- Sync を設定する

## logicool options

- ブラウザでインストールする
- なぜか「データ提供する」を選択しないとアプリ起動しないバグがあるので、提供しないを選択

## QTTabBar

インストール後、エクスプローラーの［表示］リボンから［オプション］の文字部分（上部のアイコンからではなく）をクリックし、［QT タブ バー］を選択したのちWindowsを再起動もしくはWindowsにサインインし直すと、ツールバー上にタブが追加され、開いたフォルダーがタブに追加されるようになる。

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

