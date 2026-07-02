# BIZ UDPGothic (vendored, pinned)

日本語スライド (ppt-master) のデッキ主フォント。字形の一貫性を最優先するため、
特定バージョンの OFL TTF をリポジトリに vendor し、両 OS (WSL2 / Windows) へ**同一実体**を配る。

- **ピンタグ**: `v1.051`
- **配布元**: <https://github.com/googlefonts/morisawa-biz-ud-gothic> (SIL Open Font License 1.1)
- **ファミリ名**: `BIZ UDPGothic` (Regular / Bold) — 両 OS で同じファミリ名に解決される

## 収録ファイル

| ファイル | 取得元 (raw, tag `v1.051`) |
| --- | --- |
| `BIZUDPGothic-Regular.ttf` | `fonts/ttf/BIZUDPGothic-Regular.ttf` |
| `BIZUDPGothic-Bold.ttf`    | `fonts/ttf/BIZUDPGothic-Bold.ttf` |
| `OFL.txt`                  | リポジトリ root `OFL.txt` |

等幅 (`BIZUDGothic`) や明朝 (`morisawa-biz-ud-mincho`) は今回は入れていない。必要になれば同じ手順で追加する。

## インストール先

- **Linux / WSL2**: `home-linux.nix` が `~/.local/share/fonts/` へ配置し、`fonts.fontconfig.enable` で fc-cache。
- **Windows**: `windows/configuration.dsc.yaml` の `fonts-biz-udp` Script が per-user
  (`%LOCALAPPDATA%\Microsoft\Windows\Fonts` + `HKCU` レジストリ) へ登録。

フォールバックの `Noto Sans CJK JP` は容量が大きいため vendor せず、WSL2 では Nix パッケージ
`noto-fonts-cjk-sans` 経由で導入する。

## 更新手順

```sh
tag=v1.051   # 新しいタグに差し替える
base=https://raw.githubusercontent.com/googlefonts/morisawa-biz-ud-gothic/$tag
curl -fsSL -o BIZUDPGothic-Regular.ttf "$base/fonts/ttf/BIZUDPGothic-Regular.ttf"
curl -fsSL -o BIZUDPGothic-Bold.ttf    "$base/fonts/ttf/BIZUDPGothic-Bold.ttf"
curl -fsSL -o OFL.txt                  "$base/OFL.txt"
```

更新したらこの README のピンタグも書き換え、`rebuild` (WSL2) と `winget configure` (Windows) を再実行する。
