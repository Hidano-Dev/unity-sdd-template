# Unity プロジェクトテンプレート 仕様・運用手順書

> **この README はテンプレートリポジトリ専用です。** テンプレートから生成されたリポジトリでは、初期化ワークフローによって生成先用のスリムな README (`.github/PROJECT_README.md`) に自動で差し替えられます。

## 1. 概要

GitHub のテンプレートリポジトリ機能を使い、新規 Unity プロジェクトのリポジトリを「常に鮮度の高い状態」で自動セットアップする仕組みです。テンプレート自体には骨組みだけを置き、鮮度が必要なもの (cc-sdd、UPM パッケージのバージョン、Unity の changeset) はリポジトリ生成時の GitHub Actions で解決します。これによりテンプレートの定期メンテナンスをほぼ不要にしています。

リポジトリは**マルチプロジェクト構成**を前提とします。リポジトリ直下に Assets 等は置かず、プロジェクトごとにディレクトリを設け、その中に `Assets/`, `Packages/`, `ProjectSettings/` を展開します。初期化時にはリポジトリ名のプロジェクトが 1 つ自動作成され、以後は Actions からプロジェクトを追加できます。

Unity Editor は運用安定化のため標準バージョン (ステークホルダー間で最も使われている安定版) に固定し、UPM パッケージは各プロジェクトの Editor バージョンに適合する最新版を採用します。Editor バージョンの上げ下げはプロジェクト単位で、生成後のリポジトリの Actions タブから誰でも実行できます。

## 2. ファイル構成

```
(テンプレートリポジトリ)
├─ .github/
│   ├─ workflows/
│   │   ├─ unity-versions-update.yml   … バージョン:ハッシュ一覧の日次更新 (テンプレート側のみ稼働)
│   │   ├─ template-init.yml           … 生成時に 1 回だけ走る初期化 (実行後に自己削除)
│   │   ├─ set-unity-version.yml       … プロジェクト単位のバージョン変更 (生成先に常駐)
│   │   └─ add-unity-project.yml       … プロジェクト追加 (生成先に常駐)
│   ├─ scripts/
│   │   ├─ setup-project.sh            … プロジェクト骨組み構成の共通処理 (常駐)
│   │   └─ resolve-upm.sh              … Editor 適合の UPM バージョン解決 (常駐)
│   ├─ PROJECT_README.md               … 生成先用のスリム README (初期化時に README.md へ差し替え)
│   └─ unity-versions.tsv              … バージョン<TAB>changeset<TAB>stream の一覧 (自動生成)
├─ .gitignore                          … Unity 生成物の除外 (**/ 前置で全プロジェクトに適用)
└─ README.md                           … 本書 (テンプレート専用。生成先では上記に置換される)

(生成されたリポジトリ ※初期化後)
├─ .github/                            … 常駐ワークフロー・スクリプト・TSV
├─ <リポジトリ名>/                      … 初期プロジェクト (以後 Actions で追加可能)
│   ├─ Assets/.gitkeep
│   ├─ Packages/manifest.json
│   └─ ProjectSettings/ProjectVersion.txt
├─ .gitignore
└─ README.md                           … 生成先用スリム README
```

テンプレート側にプレースホルダのプロジェクトディレクトリや `.gitkeep` を置く必要はありません。ディレクトリ構成は初期化ワークフローが動的に生成します。

## 3. 各ワークフロー・スクリプトの仕様

### 3.1 unity-versions-update.yml (テンプレート側・日次)

毎日 06:00 JST に Unity 公式 Editor Release API (認証不要) を全ページ取得し、`.github/unity-versions.tsv` を再生成します。差分がある時だけコミットするため、Unity のリリースが無い日はリポジトリは変化しません。全件を毎回取り直す冪等な作りなので、実行が数日止まっても次回で自己修復します。`is_template == true` の条件により、生成先リポジトリにコピーされても空振りします (さらに初期化時に削除されます)。

補足: GitHub の仕様でスケジュールワークフローはリポジトリが 60 日間無更新だと自動停止しますが、本ワークフロー自身が TSV 更新コミットを打つため、Unity のリリースが続く限り実質的に稼働し続けます。

### 3.2 template-init.yml (生成先で 1 回だけ)

テンプレートから新規リポジトリを生成すると、その最初の push をトリガーに実行されます。処理内容は次の 3 つです。

1. **cc-sdd セットアップ (リポジトリ直下)** — 以下の 2 コマンドを実行します (レジストリ明示指定つき)。
   - `npx -y --registry https://registry.npmjs.org/ cc-sdd@latest --claude-agent --lang ja`
   - `npx -y --registry https://registry.npmjs.org/ cc-sdd@latest --codex-skills --lang ja`
2. **初期プロジェクトの骨組み生成** — リポジトリ名のディレクトリを作成し、`setup-project.sh` で標準バージョン (`env: UNITY_VERSION`) の ProjectVersion.txt と適合 UPM の manifest.json を構成します。ディレクトリ名を変えたい場合は、初期化後にリネームするか `env: PROJECT_DIR` を書き換えます。
3. **自己削除とコミット** — `template-init.yml` と `unity-versions-update.yml` を削除し、テンプレート専用の README を生成先用 (`.github/PROJECT_README.md`) に差し替えたうえで、全変更を `chore: initialize from template` としてコミット・push します。`set-unity-version.yml` / `add-unity-project.yml` / scripts は以後も使うため残します。

採用された Unity バージョンとプロジェクトディレクトリは Actions の実行サマリーに表示されます。

デバッグ時は `workflow_dispatch` (手動実行) を使うと自己削除がスキップされるため、テスト用リポジトリ 1 つで修正→再実行のループを回せます。

### 3.3 set-unity-version.yml (生成先に常駐)

Actions タブから手動実行し、**指定したプロジェクトディレクトリ**を入力バージョンへ切り替えます。changeset は TSV → API の順で自動解決するため、**利用者がハッシュを調べる必要はありません**。存在しないバージョン (タイポ含む) や存在しないプロジェクトディレクトリはエラーで停止し、壊れた設定や意図しない新規フォルダがコミットされることはありません。あわせて UPM パッケージも対象 Editor に適合するバージョンへ自動で揃え直します (古い Editor への切り替え時はロールバックされます)。

### 3.4 add-unity-project.yml (生成先に常駐)

Actions タブから手動実行し、リポジトリ直下に新しい Unity プロジェクトディレクトリ (`Assets/.gitkeep`, `Packages/manifest.json`, `ProjectSettings/ProjectVersion.txt`) を追加します。バージョン指定は Set Unity Version と同じ流儀で、同名ディレクトリが既に存在する場合はエラーで停止します。

### 3.5 setup-project.sh / resolve-upm.sh (共通スクリプト)

`setup-project.sh <ディレクトリ> <バージョン>` がプロジェクト骨組み構成の共通処理で、初期化・プロジェクト追加・バージョン変更の 3 ワークフローすべてがこれを呼びます (冪等なので既存プロジェクトへの適用は上書き更新になります)。内部で `resolve-upm.sh` を呼び、Unity 公式レジストリのメタデータにある要求最小 Editor バージョン (`unity` フィールド) を参照して「対象 Editor で使える中で最も新しい安定版」を選定し manifest.json を生成します。プレリリース版 (-pre / -exp) は除外します。

対象パッケージの追加・削除は `resolve-upm.sh` 内の `PACKAGES` 変数を編集してください (全プロジェクト共通の初期構成)。対象は公式レジストリのみで、git URL 直指定や OpenUPM 等のパッケージは対象外です。

## 4. 運用手順

### 4.1 新規リポジトリの開始

1. テンプレートリポジトリで「Use this template」→「Create a new repository」。
2. Actions タブで「Template Init」の完了 (緑) を確認する。数分で cc-sdd 設定と初期プロジェクト (リポジトリ名のディレクトリ) が揃い、初期化コミットが積まれます。
3. 初期化コミットが積まれた**後に** clone する (先に clone した場合は pull)。
4. Unity Hub の「Add project from disk」で**プロジェクトディレクトリ** (リポジトリ直下ではない) を指定して開く。標準バージョンが未インストールなら Hub がインストールを案内します (changeset 入りなので正確なビルドに誘導されます)。
5. 初回起動で生成される `Packages/packages-lock.json` をコミットしておくと、メンバー間でパッケージ解決が揃います。

### 4.2 Unity バージョンの変更 (プロジェクト単位)

**対象プロジェクトの初回起動前 (開始時) に行うことを想定しています。**

1. 対象リポジトリの Actions タブ →「Set Unity Version」→「Run workflow」。
2. プロジェクトディレクトリ名とバージョン番号 (例: `6000.0.32f1`) を入力して実行。ハッシュは不要です。
3. 完了後に pull して Unity Hub で開く。

利用可能なバージョンの一覧はリポジトリ内 `.github/unity-versions.tsv` (生成時点のスナップショット) か、テンプレートリポジトリ側の最新 TSV で確認できます。

> **注意**: 本ワークフローが書き換えるのは ProjectVersion.txt と manifest.json のみで、`Assets/` 内のシリアライズ済みデータは変換されません。開発が進んだ後に大きくバージョンを下げる場合は、シーン・プレハブの非互換が起きうるためブランチで検証してから main に取り込んでください。

### 4.3 プロジェクトの追加

1. Actions タブ →「Add Unity Project」→「Run workflow」。
2. 新しいプロジェクトディレクトリ名とバージョン番号を入力して実行。
3. 完了後に pull し、Unity Hub でそのディレクトリを開く。

### 4.4 テンプレート自体のメンテナンス

- **標準バージョンの変更**: `template-init.yml` 冒頭の `env: UNITY_VERSION` を書き換えるだけです。
- **標準パッケージ構成の変更**: `resolve-upm.sh` の `PACKAGES` 変数を編集します。
- **共通アセット等の骨組み見直し**: テンプレートリポジトリ上で直接行います。既存の生成済みリポジトリには波及しません。
- 上記以外の定期メンテナンスは不要です (TSV 更新は自動)。

## 5. 前提条件・トラブルシューティング

| 事象 | 原因 / 対処 |
|---|---|
| 生成直後に初期化が走らない | Organization 設定で Actions が無効の可能性。有効化のうえ「Template Init」を手動実行する (手動実行は自己削除しないため、完了後にワークフロー 2 本の削除と README 差し替えを手で行う) |
| bot の push が拒否される | リポジトリ設定の Workflow permissions を「Read and write permissions」にする。ワークフローファイル削除まで拒否される組織設定の場合は、Fine-grained PAT (contents + workflows) を secret に置き checkout の `token` に渡す |
| 「〜は存在しないバージョンです」エラー | バージョン表記の確認 (例: `6000.0.32f1` のようにサフィックスまで含める) |
| 「〜は Unity プロジェクトとして見つかりません」エラー | Set Unity Version のプロジェクトディレクトリ名のタイポ。リポジトリ直下のディレクトリ名を確認する |
| 「〜は既に存在します」エラー | Add Unity Project で既存名を指定している。バージョン変更なら Set Unity Version を使う |
| 「〜に対応バージョンが見つかりません」エラー | 指定 Editor が古すぎて対象パッケージの適合版が存在しない。Editor バージョンか `PACKAGES` の構成を見直す |
| clone したのに cc-sdd 等が無い | 初期化コミット前に clone している。`git pull` する |
