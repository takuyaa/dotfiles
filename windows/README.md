# Windows 開発環境 — 宣言的セットアップ

新しい Windows ノートを、できる限り宣言的にセットアップするための構成です。開発
環境そのものは **WSL** の中に置き、Windows 側はエディタ・ターミナル・少数のアプリ
とキーボードのカスタマイズだけに最小化しています。

このディレクトリ（`windows/`）は dotfiles リポジトリの Windows ホスト層です。Nix では
なく `winget configure` で適用します。kanata と winget は Windows ホストで動くため、
**Windows ファイルシステム上のクローン**から使います（このドキュメントは
`C:\Users\takuy\dotfiles` を前提）。WSL 内（`\\wsl$\...`）のクローンからの参照は避けて
ください。別の場所に置く場合は `configuration.dsc.yaml` の kanata タスクのパスと、各
コマンドの `cd` を合わせて変更します。

## リポジトリの取得・更新（Windows 側）

開発環境は WSL に寄せているので、Windows 側のクローンは**この `windows/` を使うためだけ**
のものです（ghq は使いません）。

初回はまず Git を入れます（この構成自体にも Git は含まれますが、クローン前なので最初だけ
手動。以後は winget が管理）。

```powershell
winget install -e --id Git.Git
```

リポジトリをクローンします。

```powershell
git clone https://github.com/takuyaa/dotfiles.git C:\Users\takuy\dotfiles
```

以降、設定をリポジトリ側で更新したら、Windows ではクローンに移動して、

```powershell
cd C:\Users\takuy\dotfiles
```

`git pull` で最新化し、必要に応じて下記「適用方法」を再実行します（kanata.kbd を変えた
だけなら kanata タスクの再起動でも可）。

```powershell
git pull
```

## 適用方法

セットアップは WinGet Configuration（`winget configure`）で適用します。キーボード
関連のレジストリ変更は HKLM に書き込むため、**管理者として**実行する必要があります。

1. **PowerShell を管理者として実行**（スタート → 「PowerShell」を右クリック →
   「管理者として実行」）し、このフォルダに `cd` します。

   ```powershell
   cd "C:\Users\takuy\dotfiles\windows"
   ```

2. 構成ファイルを**検証**します（構文・スキーマのチェック）。

   ```powershell
   winget configure validate .\configuration.dsc.yaml
   ```

3. **適用**します（冪等。すでに満たされているリソースはスキップされます）。

   ```powershell
   winget configure .\configuration.dsc.yaml
   ```

適用後、US キーボードレイアウト（ユーザー単位の `HKCU` 変更）を反映するには
**サインアウト → サインイン**、CapsLock→Ctrl（マシン全体の `Scancode Map`）を反映
するには**再起動**が必要です。再起動すれば両方カバーできます。winget v1.6.2631
以降が必要です。

## 何をするか

- **アプリ（winget）:** WSL、VS Code、Windows Terminal、Git（この dotfiles の
  pull 用）、Chrome、1Password、PowerToys、Discord、balenaEtcher、Slack、
  Tailscale、Google 日本語入力、kanata。
- **WSL の mirrored ネットワーク:** `windows/wslconfig` を `%UserProfile%\.wslconfig`
  に配置し、`networkingMode=mirrored` にします。WSL が Windows のネットワーク
  スタックを共有するので、Windows 側の Tailscale 経由で WSL から tailnet（`100.x`）
  に到達でき、`ssh dev` で homelab につながります。**`wsl --shutdown` が必要。**
- **JIS キーボードを US 配列として使う:** `HKCU\Keyboard Layout\Substitutes` で
  日本語レイアウト `00000411` → US `00000409` に置換します。レイアウトレベルの
  変更なので USB/HID キーボードでも効きます（古い `i8042prt` / `kbd101.dll`
  方式は PS/2 にしか効きません）。**サインアウト → サインインが必要。**
- **CapsLock → 左 Ctrl:** `Scancode Map` レジストリ値による変更。ログイン画面を
  含むシステム全体に適用されます。**再起動が必要。**
- **kanata の自動起動:** ログオン時のスケジュールタスク（"kanata"）が、kanata の
  GUI ビルド（コンソールウィンドウなし）を `kanata.kbd` で起動します。現在の
  ユーザーとして、対話トークン＋最高権限で実行されます。

## キーボードレイアウト（kanata.kbd）

スペースバー両脇の親指キーで、IME 切替（タップ）とレイヤー（ホールド）を行います。

| キー | タップ | ホールド |
|-----|--------|----------|
| 無変換（スペース左） | F13（→ 英数 / IME OFF） | **右 Ctrl**（押している間、任意キー = Ctrl+任意キー） |
| 変換（スペース右）   | F14（→ かな / IME ON）  | NUMS レイヤー: `q w e … p` → `1 2 … 0`、`1 2 … 0` → `F1 F2 … F10`、`h j k l` → 矢印、`n m , .` → Home/PgDn/PgUp/End |

タップは Muhenkan/Henkan ではなく **F13 / F14**（レイアウト非依存）を送ります。
US 配列では Muhenkan/Henkan のスキャンコードが仮想キーに変換されず、IME に届かない
ためです。F13/F14 は `keymap.txt` で IME OFF / ON に割り当てています。

矢印（h j k l → ←↓↑→）は変換側 NUMS レイヤーのみ。無変換側はモディファイア専用なので
無変換+h/j/k/l は Ctrl+H/J/K/L になります。

また、macOS 風の Emacs カーソル移動／編集を再現しています。

| Ctrl+ | 動作 | Ctrl+ | 動作 |
|-------|------|-------|------|
| a | 行頭（Home） | e | 行末（End） |
| b | ← | f | → |
| p | ↑ | n | ↓ |
| d | 前方削除（Delete） | h | 後方削除（Backspace） |
| [ | Esc | | |

移動・削除系（a/e/b/f/p/n/d/h/[）は `defoverrides` で実装しています。`defoverrides` は
タイムアウトが無く、押されているキーの組み合わせを毎回判定するので、Ctrl を押しっぱなしで
連打しても毎回効きます（`defchordsv2` は最初の Ctrl 押下から計時するため、押しっぱなしだと
2回目以降が時間切れで素のキーになる）。

なお Ctrl+k（行末まで kill）と Ctrl+o は**あえて差し替えていません**。以前は GUI 向けに
Shift+End→Shift+Delete（行末まで切り取り）や Enter→Left（行を開く）へ `fork` していましたが、
ターミナル（WSL / Windows Terminal）では kanata の低レベルフックがキーを横取りするため、
これらが端末のエスケープシーケンスとして届き、シェル上で Ctrl+k が `~F` などと表示される
問題がありました。そのため素通しにして、ターミナルの readline 標準（Ctrl+k = 行末まで kill）が
効くようにしています。代償として、GUI アプリでの macOS 風の行末切り取り／行を開く は無くなります。

差し替えるのはこれらの Ctrl コンボだけで、他（Ctrl+C/V/X/Z/S、Ctrl+←→ など）はそのまま
使えます。代償として、差し替えたキーの標準の意味（Ctrl+A 全選択、Ctrl+F 検索、Ctrl+B
太字、Ctrl+E、Ctrl+N 新規、Ctrl+P 印刷、Ctrl+D など）はその Ctrl からは失われます（下記の
無変換キーで取り戻せます）。macOS と違い Windows には Cmd が無く、kanata はテキスト欄かどうかを
判別できないため、これは全アプリ共通（テキスト欄限定ではない）になります。

### 無変換キー＝Cmd（アプリ操作）

奪われた Ctrl ショートカット（全選択など）は **無変換キーを押しながら**取り戻せます。
無変換は親指ホームポジションで、Win キーより届きやすく常用に向きます。無変換ホールドは
レイヤーを切り替えずに単に **右 Ctrl** を押した状態にするので、列挙なしで
`無変換+a〜z`、`無変換+1〜9`（タブ切替）など Ctrl 系すべてが効きます。

| 無変換 + | 動作 |
|---------|------|
| `a` | Ctrl+A（全選択） |
| `c` / `v` / `x` | Ctrl+C / V / X（コピー / ペースト / カット） |
| `f` | Ctrl+F（検索） |
| `n` | Ctrl+N（新規） |
| `y` / `z` | Ctrl+Y（redo） / Ctrl+Z（undo） |
| `s` | Ctrl+S（保存） |
| `1`〜`9` | Ctrl+1〜9（タブ切替など） |
| `[` / `]` | **Alt+Left / Alt+Right**（ブラウザ・Explorer・VSCode 等の back / forward） |
| 任意キー | Ctrl+任意キー |

右 Ctrl で発火するのは、左 Ctrl ベースの defoverrides（Ctrl+a→Home など）に
横取りされないため。無変換+a は Select All のままで、Home にはなりません。

`[` / `]` は例外で、defoverrides で `(rctl [)` / `(rctl ])` を Alt+Left / Alt+Right に
置換しています（macOS の Cmd+[ / Cmd+] に近い指の動きで browser back / forward）。
代償として 無変換+[ から Esc（Ctrl+[ = ASCII 0x1B）が出なくなるので、Esc は物理キーか
**左 Ctrl+[**（こちらは defoverrides で Esc 化済み）で取ります。

注意: 無変換は `tap-hold-press` を使っており、無変換を押した後**別のキーを押した瞬間**に
ホールド（=右 Ctrl）が発火します。`無変換↓ → c↓ → c↑ → 無変換↑` で Ctrl+C。
無変換だけ押して離せば F13 がタップ発火して IME が「英数」に切り替わります。
Win キーは素のままなので、Win+L / Win+D / Win+E / Win+1〜9 などの Windows 標準コンボは
そのまま使えます。

キーの挙動が不安定に感じる場合は `kanata.kbd` で 200ms タイムアウトを調整するか、
無変換を素のキー（ホールド無し）に戻せば遅延をゼロにできます。

## 手動の後処理ステップ 1: 再起動

キーボード関連のレジストリ変更を反映させるため、**再起動**します。

## 手動の後処理ステップ 2: Google 日本語入力のキーマップ

`keymap.txt`（宣言的なソース）をインポートします。タスクトレイのアイコン →
プロパティ → 一般 → 「キー設定の選択」 → **編集** → エディタのメニューで
**ファイルからインポート…** → `keymap.txt` を選択 → 「キー設定の選択」を
**カスタム** にして OK → 適用。

`keymap.txt` について: Mozc のインポートは**キーマップ全体を置換**するため、
ファイルは差分だけでなく*完全な*キーマップである必要があります。これは
**MS-IME** ベースの完全なキーマップに、親指キー（F13/F14）の行だけを変更した
ものです。

| モード | キー | コマンド |
|--------|------|----------|
| DirectInput | F14 | IMEOn（→ かな。IME をオンにする） |
| Precomposition | F14 | CompositionModeHiragana（→ ひらがな） |
| DirectInput / Precomposition / Composition / Conversion | F13 | IMEOff（→ 英数） |

DirectInput では `CompositionModeHiragana` ではなく `IMEOn` が必要です。
composition 系のコマンドは IME がすでにオンのときしか効きません。

割り当てを変えるときは GUI で編集し、**ファイルにエクスポート…**で
`keymap.txt` を上書きしてください（数行に手で削らないこと。標準キーが消えます）。
ATOK/ことえりベースに作り直すときは、そのプリセットを再インポートし、上記 2 つの
上書きを当て直してからエクスポートします。

補足: 完全な無人適用（Mozc の `config1.db` protobuf を直接書く方法）はサポート
されておらず、バージョン依存で壊れやすいです。インポート/エクスポートが確実な
方法です。

トラブルシュート: 変換中に Backspace / Enter / Space が効かなくなった場合、
アクティブなキーマップが部分的なもの（数エントリのみ）になっています。短い
ファイルをインポートして全体が置換された状態です。完全な `keymap.txt`（163 行）
を入れ直すか、まず MS-IME プリセットを選んで標準に戻してください。

## 手動の後処理ステップ 3: kanata の動作確認

次回ログオン時に "kanata" スケジュールタスクで起動します。ログアウトせずに今すぐ
起動するには、タスクを実行します。

```powershell
Start-ScheduledTask -TaskName kanata
```

確認: 無変換 + `q` のホールド → `1`、変換 + `q` のホールド → `F1`、CapsLock が
Ctrl として効くこと。kanata を昇格実行中にゲーム/アプリが誤作動する場合は、
自動起動スクリプトの `-RunLevel Highest` を `Limited` に変えて再適用してください。

## 手動の後処理ステップ 4: WSL ディストロの初期化

`Microsoft.WSL` は WSL 機能を入れるだけで、開発環境そのものは
[takuyaa/dotfiles](https://github.com/takuyaa/dotfiles) を使って Nix
（Home Manager、standalone）で宣言的に管理します。一般的なベストプラクティスは
[Microsoft の WSL セットアップガイド](https://learn.microsoft.com/en-us/windows/wsl/setup/environment)
を参照。

### 4a. ディストロのインストール

Ubuntu 24.04 LTS ディストロをインストールします（dotfiles の Linux ターゲットに
合わせています）。WSL 機能のインストール直後は、これが動く前に再起動が必要な場合が
あります。

```powershell
wsl --install -d Ubuntu-24.04
```

### 4b. UNIX ユーザーの作成

初回起動時に Ubuntu が UNIX ユーザー名とパスワードを尋ねます。ユーザー名は
**`takuya-a`** にしてください。Home Manager の設定はこのユーザー名
（`homeConfigurations."takuya-a"`）をキーにしているため、別名だと一致しません。

このアカウントがディストロの既定ユーザーになり、`sudo` を実行できる管理者になります
（Windows のユーザー名とは無関係）。なお、パスワード入力中は画面に何も表示されません
（ブラインドタイプ。正常な挙動です）。パスワードを変えたいときはディストロ内で
`passwd` を実行します。

### 4c. dotfiles の適用（リポジトリ本体の手順を参照）

WSL 内での Nix 導入・Home Manager 適用・GitHub 認証・SSH 署名鍵・日常運用
（`make rebuild` / `make update`）は、**このリポジトリ本体の README「Linux (dev-01)」
セクション**に従ってください。二重管理を避けるため、ここでは手順を重複させません。
流れだけ示すと、WSL 内に dotfiles を clone（`~/ghq/github.com/takuyaa/dotfiles`）→
`./install-linux.sh` → `gh auth login` と SSH 署名鍵を設定 → 以降は `make rebuild`。
開発ツールはすべて Nix 管理なので個別の `apt install` は避けます（ベース更新の
`sudo apt update && sudo apt upgrade` は随時可）。

### 4d. ファイル配置とエディタ（ベストプラクティス）

プロジェクトのファイルは **Linux 側のファイルシステム**（`~` 配下）に置きます。
`C:\` や `/mnt/c/...`（Windows 側）に置くとファイルシステムを跨いでアクセスが遅く
なるためです。dotfiles が `~/ghq/github.com/...` に clone するのはこの理由に沿った
配置です。

Windows のエクスプローラーから WSL 内のファイルを開くには、`\\wsl$\Ubuntu-24.04\`
を辿るか、WSL 内のディレクトリで次を実行します（末尾のピリオドが必要）。

```bash
explorer.exe .
```

VS Code は WSL 内のプロジェクトディレクトリで次を実行すると、WSL リモートとして開けます
（初回は WSL 拡張が自動で入ります。末尾のピリオドが必要）。

```bash
code .
```

## 手動の後処理ステップ 5: Tailscale でホームラボに接続

`ssh dev`（WSL 内の `home-linux.nix` で定義。宛先は homelab の Tailscale IP）を
使えるようにするための手順です。winget で Tailscale 本体は入りますが、tailnet への
サインインと WSL の再起動は手動です。

1. **Tailscale にサインイン。** スタートメニューから Tailscale を起動し、dev-01 と
   同じ tailnet にサインインします（または管理者 PowerShell で `tailscale up`）。
   タスクトレイのアイコンが接続済みになり、`tailscale ip -4` で `100.x` の自分の IP
   が出れば OK。複数アカウントを使い分けている場合は、GUI のアカウント切替（または
   `tailscale switch`）で**正しい tailnet をアクティブに**してください（別アカウントの
   ままだと dev-01 が peer に現れません）。

2. **WSL を再起動して mirrored ネットワークを反映。** PowerShell で:

   ```powershell
   wsl --shutdown
   ```

   再度 WSL を開き、`ip route` の default が `eth0`（mirrored では Windows 共有）に
   なっていること、`ping 100.120.98.107` などで homelab に届くことを確認します。

3. **公開鍵を GitHub に登録 → dev Pod を再起動。** dev-01（k3s 上の Pod）は
   `entrypoint.sh` で起動時に `https://github.com/takuyaa.keys` から
   `authorized_keys` を取得します（`PasswordAuthentication no` なので `ssh-copy-id`
   は通りません）。WSL 内で:

   ```bash
   # GITHUB_TOKEN を export している場合は一時的に外して refresh する
   GITHUB_TOKEN= gh auth refresh -h github.com -s admin:public_key
   GITHUB_TOKEN= gh ssh-key add ~/.ssh/id_ed25519.pub --title "wsl-<host>"
   ```

   その後、kubectl が使えるマシンから Pod を再起動して `authorized_keys` を
   取り直させます（`authorized_keys` は PVC に残るため、再起動しない限り反映
   されません）。

   ```bash
   export KUBECONFIG=$HOME/.kube/k3s-prod.yaml
   kubectl delete pod -n dev dev-0
   ```

   Pod が立ち上がったら `ssh dev` でログインできます。

## 使い方メモ

- **アプリランチャー:** PowerToys Run（PowerToys の一部）はファジー検索の
  ランチャーです。アプリ名の先頭を打つと起動できます。起動キーは既定で
  **Alt+Space**。変更は PowerToys → PowerToys Run → 起動ショートカット から。
  標準機能の代替として、**Windows** キー（または `Win+S`）を押して入力する方法も
  あります。

## 編集方法

- アプリを追加する: `configuration.dsc.yaml` の `WinGetPackage` ブロックをコピー
  して `settings.id` を変更します（ID は `winget search <名前>` で探せます）。
- キーマップを変更する: `kanata.kbd` を編集し（`defsrc` と各 `deflayer` は位置で
  対応するので揃えること）、kanata タスクを再実行するか再ログインします。
