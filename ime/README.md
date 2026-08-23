# IME（Google 日本語入力）

macOS と Windows の**両方**で Google 日本語入力を使い、キーマップを 1 本の
`keymap.txt` で共有するための設定です。

| ファイル | 用途 |
|---------|------|
| `keymap.txt` | Google 日本語入力のキーマップ（**両 OS 共有**）。GUI から手動インポートする |
| `karabiner-ime-switch.json` | macOS US 配列用の Karabiner ルール。`home-darwin.nix` が symlink する |

## 切り替えの設計

合わせているのは**キー名ではなくスペースバーに対する親指の位置**です。US 配列の
MacBook には 無変換／変換 に相当するキーがありませんが、同じ位置に左⌘・右⌘が
あります。

```
Windows (JP 物理 / US レイアウト):  [無変換] [ space ] [変換]
macOS US:                           [  ⌘  ] [ space ] [ ⌘  ]   ← タップで切替、ホールドは通常の ⌘
macOS JIS (将来):                   [英数]  [ space ] [かな]
```

| 環境 | IME OFF（英数） | IME ON（かな） |
|------|----------------|---------------|
| Windows | 無変換 タップ → `F13`（kanata） | 変換 タップ → `F14`（kanata） |
| macOS US 配列 | 左⌘ タップ → `英数`（Karabiner） | 右⌘ タップ → `かな`（Karabiner） |
| macOS JIS 配列（将来） | 英数キー（そのまま） | かなキー（そのまま） |
| 保険（Windows のみ有効） | `Ctrl+Shift+;` | `Ctrl+Shift+J` |

macOS 側で Windows と同じ F13/F14 を使わないのは、`英数`/`かな` が macOS 標準の
キーコードで、**JIS 配列に交換したら Karabiner ルールを削除するだけ**で同じ挙動に
なるからです。F13/F14 経由にすると、JIS 交換後も「英数/かな → F13/F14」の変換
ルールを恒久的に抱えることになります。

`Ctrl+Shift+;` / `Ctrl+Shift+J` は Karabiner が動いていないとき、および親指キーの
無い外付けキーボード用の保険のつもりでしたが、**macOS では動きませんでした**。
キーマップのインポート自体はエラーなく通る（＝ Mozc のパーサは受理している）ので、
キー名がマッチしていないか、キーイベントが IME に届く前に奪われているかのどちらか
です。原因は特定していません。行は残してありますが、macOS では機能しないものとして
扱ってください（Windows 側は未検証）。

タップ判定は Karabiner の既定値（1000ms）に任せています。`kanata.kbd` の 200ms と
揃えたくなりますが、**両者は意味が違うので揃えてはいけません**。kanata の tap-hold は
200ms を超えると別の機能（右 Ctrl / レイヤー）に化けるので短い値に意味があります。
一方 Karabiner 側はホールドしても結果が同じ ⌘ なので、短くしても得るものが無く、
タップを取りこぼすだけです。実際、200ms を明示していたときは内蔵キーボード
（ストロークが浅くタップが 100ms 前後）では通るのに、メカニカルの外付け
（Keychron Q11）では打鍵が 200ms を超えて切り替わりませんでした。

他のキーを押した時点で `to_if_alone` はキャンセルされるため、タイムアウトを伸ばしても
⌘+C などの通常のショートカットには影響しません。影響するのは「⌘ を単独で長く握って
離した」ときに 英数/かな が出るかどうかだけです。

## keymap.txt の構成

Mozc のインポートは**キーマップ全体を置換**するため、このファイルは差分ではなく
*完全な*キーマップです。**MS-IME** ベースの標準キーマップに、下表の行だけを
上書き・追加してあります。

| モード | キー | コマンド | 用途 |
|--------|------|----------|------|
| Precomposition / Composition / Conversion | `F13` | `IMEOff` | Windows: 無変換 |
| DirectInput | `F14` | `IMEOn` | Windows: 変換 |
| Precomposition | `F14` | `CompositionModeHiragana` | 同上 |
| Precomposition / Composition / Conversion | `Eisu` | `IMEOff` | macOS: 英数 |
| DirectInput | `Hiragana` | `IMEOn` | macOS: かな |
| Precomposition / Composition / Conversion | `Ctrl Shift ;` | `IMEOff` | 保険 |
| DirectInput | `Ctrl Shift j` | `IMEOn` | 保険 |
| Precomposition / Composition / Conversion | `Ctrl Shift j` | `CompositionModeHiragana` | 保険 |

DirectInput では `CompositionModeHiragana` ではなく `IMEOn` が必要です。
composition 系のコマンドは IME がすでにオンのときしか効きません。逆に IME が
オフの状態で 英数 を押しても何も起きなくてよいので、標準キーマップにあった
`DirectInput  Eisu  IMEOn` の行は削除しています。

`Hiragana` 行は MS-IME 標準のままで、macOS の かな キーに必要な挙動をすでに
満たしているため変更していません。

Windows 側では CapsLock を Scancode Map で左 Ctrl に潰しているため `Eisu` は
発火せず、macOS 向けの上書きが Windows の挙動に影響することはありません。同様に
F13/F14 は macOS では発火しません。**だからこの 1 ファイルを両 OS で共有できます。**

割り当てを変えるときは GUI で編集し、**ファイルにエクスポート…**で
`keymap.txt` を上書きしてください（数行に手で削らないこと。標準キーが消えます）。

## macOS セットアップ

### 1. `rebuild`

`darwin.nix` の cask `google-japanese-ime` と、`home-darwin.nix` による Karabiner
ルールの配置（`~/.config/karabiner/assets/complex_modifications/ime-switch.json`）が
これで入ります。

### 2. Karabiner-Elements の権限とルール有効化

初回のみ手動です。

1. Karabiner-Elements.app を起動し、**入力監視**の許可と、**システム機能拡張**
   （ドライバ）の承認を行う（システム設定 → プライバシーとセキュリティ）
2. Settings → **Complex Modifications** → **Add predefined rule**（v16.1 での表記。
   バージョンにより **Add rule**）→ 一覧の「IME switch (dotfiles)」を **Enable**

   隣の **Add your own rule** は JSON をその場に貼り付けるボタンで、こちらではない。
   一覧に出てこないときは Karabiner-Elements を再起動すると assets を読み直す。

Karabiner は `~/.config/karabiner/karabiner.json` を自分で書き換えるため、この
ファイルは Nix の read-only symlink にできません。そのため assets ディレクトリに
ルールを置いて GUI で 1 回取り込む形にしています。**`karabiner-ime-switch.json` を
編集したら、GUI でルールを削除して追加し直す**必要があります（有効化時に内容が
`karabiner.json` へコピーされるため）。

### 3. 入力ソースを Google 日本語入力だけにする

**先にログアウトして入り直すこと。** cask でインストールした直後は macOS の入力
メソッド登録が中途半端で、入力ソースの追加一覧に一部のモード（カタカナだけ等）しか
出てきません。Google 日本語入力の公式インストーラがログアウトを促すのと同じ理由です。

システム設定 → キーボード → 入力ソース → **編集** で、**追加してから削除**します。

1. 「+」→ 日本語 → **ひらがな (Google)** を追加（一覧に出ないときは「+」→ 日本語 を
   もう一度開き直す）
2. `日本語 - ローマ字入力`（ことえり）を「-」で削除

**`ABC` は削除できず、残したままで構いません。** macOS は ASCII を打てる入力ソースを
最低 1 つ要求しますが、Google 日本語入力の「ひらがな」モードは `smJapanese` スクリプト
なので該当しません（ASCII 担当は同バンドル別モードの「英数 (Google)」= `smRoman`）。
ABC を外すにはその「英数 (Google)」を足すしかなく、入力ソースが 2 つに戻って本末転倒
です。英数/かな キーは**現在アクティブな IME の内部モード**を切り替えるだけで ABC には
触れないため、ABC が選択されない限り実害はありません。

### 3.5. 入力ソース切り替えショートカットを無効化する

そのかわり、事故で ABC に飛ばないよう OS 側の切り替えショートカットを切ります。
Windows 側で言語切替ホットキーを無効化している（`configuration.dsc.yaml` の
`ime-*-hotkeys`）のと同じ理由です。**`home-darwin.nix` の
`home.activation.disableInputSourceHotkeys` で自動適用されます。**

| symbolichotkey ID | 既定のキー | 項目 |
|---|---|---|
| 60 | `⌃Space` | 前の入力ソースを選択 |
| 61 | `⌃⌥Space` | 入力メニューの次のソースを選択 |

`⌃Space` は Emacs の set-mark と衝突するので、この意味でも切る価値があります。

これらは Apple 自身の "symbolic hot key" で、`~/Library/Preferences/com.apple.symbolichotkeys.plist`
の `AppleSymbolicHotKeys` 辞書に入っています（Karabiner とは無関係）。`parameters` は
(ASCII, キーコード, モディファイアマスク) で、32/49 = Space、262144 = `⌃`、786432 = `⌃⌥`。

`system.defaults.CustomUserPreferences` を使っていないのは、nix-darwin が 1 キーにつき
1 回の `defaults write <domain> <key> <value>` を出す実装で、`AppleSymbolicHotKeys` を
指定すると**辞書ごと置換**されるためです。この辞書には macOS が既定で 19 エントリ
（うち 13 個は `enabled=false`）を持っており、置換するとそれらが消えます。
`defaults write ... -dict-add` なら 1 エントリだけマージできます。

値は **XML plist** で渡す必要があります。旧形式リテラル（`{ enabled = 0; ... }`）には
数値・真偽値の型が無いため、`enabled` が文字列 `"0"`、`parameters` が文字列配列として
書き込まれ、bool/int を前提にしている macOS 側が解釈しません。

入力の行き来はすべて IME 内部のモード切り替えになるので、Windows と同じ
「IME の ON/OFF」体験になります。

### 4. keymap.txt のインポート

メニューバーのアイコン → 環境設定 → 一般 → 「キー設定の選択」 → **編集** →
エディタのメニューで **ファイルからインポート…** → この `keymap.txt` を選択 →
「キー設定の選択」を **カスタム** にして OK → 適用。

### 5. 動作確認

- 左⌘ タップ → 英数、右⌘ タップ → かな
- ⌘ を押しながら C/V/Tab などが通常どおり効く（ホールド時は素の ⌘）
- `Ctrl+Shift+J` / `Ctrl+Shift+;` でも切り替わる

## 実機で確認した挙動（macOS）

| 項目 | 結果 |
|------|------|
| 左⌘タップ → 英数 / 右⌘タップ → かな | **動作** |
| ⌘+C / ⌘+V / ⌘+Tab（ホールド時） | **動作**（タップ判定 200ms に取られない） |
| 変換中の Backspace / Enter / Space | **動作**（キーマップ全体が正しく置換されている証拠） |
| `Ctrl+Shift+J` / `Ctrl+Shift+;` | **動作しない**（原因未特定） |
| かな キーの Mozc 上のキー名 | `Hiragana` で正しい（`Kana` 行の追加は不要） |
| `IMEOff` の挙動 | Windows と同じく直接入力モードへ遷移する |

`Ctrl` 和音を macOS でも動かしたくなった場合の手がかり: `keymap.txt` のインポートは
成功しているのでパースは通っています。US 配列では Shift+`;` が `:` になるため
`Ctrl :` 表記を試す価値がありますが、`Ctrl Shift j`（文字の変形が起きない組み合わせ）
も同時に効かなかったので、キー名の問題ではなく IME に届く前の段階で奪われている
可能性の方が高いです。

## Windows セットアップ

`../windows/README.md` を参照してください。kanata が 無変換／変換 を F13/F14 に
変換し、この同じ `keymap.txt` がそれを IME OFF/ON に割り当てます。
