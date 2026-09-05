# プロジェクトセットアップガイド

このリポジトリは Unity プロジェクトテンプレートから生成され、GitHub Actions によって自動初期化されています (SDD ワークフロー設定の取り込み・設定済みプロジェクトのリネーム・Unity バージョン固定)。

リポジトリ直下の各ディレクトリがそれぞれ独立した Unity プロジェクトです。生成時には、テンプレートに同梱された設定済みプロジェクト (パッケージ構成・ProjectSettings・URP 設定込み) がリポジトリ名にリネームされて 1 つ配置されています (ProjectSettings の productName もリポジトリ名に設定済み)。

## はじめかた

1. **初期化の完了を確認** — Actions タブで `Template Init` が完了 (緑) していることを確認します。まだ実行中なら完了を待ってください。`chore: initialize from template` コミットが積まれていれば完了です。
2. **clone / pull** — 初期化コミットが積まれた後に clone してください。先に clone していた場合は `git pull` します。
3. **Unity Hub で開く** — 「Add project from disk」で**プロジェクトディレクトリ** (リポジトリ直下ではなく、その中の各プロジェクトフォルダ) を指定します。指定バージョンが未インストールの場合は Hub がインストールを案内します。
4. 初回起動で生成される `Packages/packages-lock.json` をコミットしておくと、メンバー間でパッケージ解決が揃います。

## プロジェクト名を変更したい場合

1. Actions タブ →「**Rename Project**」→「Run workflow」
2. 新しいプロジェクト名を入力して実行 (1 つの入力でディレクトリ名と ProjectSettings.asset の productName の両方が変わります)
3. 完了後に `git pull` し、Unity Hub で新しいディレクトリを「Add project from disk」で指定し直す

対象プロジェクトは `project` 欄を空欄にすると自動検出されます (プロジェクトが 1 つだけならそのままで OK)。プロジェクトを複数追加している場合は候補一覧を表示してエラー停止するので、その中から対象のディレクトリ名を `project` 欄に入力して再実行してください。

## プロジェクトを追加したい場合

1. Actions タブ →「**Add Unity Project**」→「Run workflow」
2. 新しいプロジェクトディレクトリ名とバージョン番号 (例: `6000.0.32f1`) を入力して実行。ハッシュ (changeset) を調べる必要はありません
3. 完了後に `git pull` し、Unity Hub でそのディレクトリを開く

リポジトリ直下に `Assets/`, `Packages/`, `ProjectSettings/` を備えた骨組みが作成されます (初期プロジェクトのような設定済み構成のコピーではなく最小構成です)。存在しないバージョンを入力した場合はエラーで停止するだけで、リポジトリは変更されません。利用可能なバージョン一覧は `.github/unity-versions.tsv` (生成時点のスナップショット) で確認できます。

## Unity バージョンを変更したい場合

専用のワークフローはありません。通常の Unity プロジェクトと同じく、Unity Hub で対象バージョンを選んで開き直す (ProjectVersion.txt が自動更新されます) か、`<プロジェクト>/ProjectSettings/ProjectVersion.txt` を直接編集してコミットしてください。パッケージの調整は Unity で開いた際に Package Manager で行います。

> **注意**: 開発が進んだ後に大きくバージョンを下げると `Assets/` 内のシーン・プレハブに非互換が起きる可能性があります。その場合はブランチで検証してから main に取り込んでください。

## SDD ワークフロー設定を最新化したい場合

kiro commands / dev-orchestrator skill などの SDD ワークフロー一式 (`.claude/` `.codex/` `.kiro/` `.agents/` `AGENTS.md`) は [orchestration-development-template](https://github.com/Hidano-Dev/orchestration-development-template) から取り込まれています。最新に追従したい場合:

1. Actions タブ →「**Orchestration Sync**」→「Run workflow」
2. 完了後に `git pull` (差分がある時だけ `chore: sync orchestration assets` コミットが積まれます)

ルート `CLAUDE.md` (プロジェクト固有メモ) には触れません。

## 困ったときは

- **SDD の設定 (`.claude/` 等) やプロジェクトディレクトリが見当たらない** → 初期化コミット前の状態です。`git pull` してください。
- **プロジェクト名変更 / プロジェクト追加が反映されない** → Actions の実行結果を確認してください。bot の push が拒否されている場合は、リポジトリ設定の Workflow permissions を「Read and write permissions」にします。

テンプレートの仕組みの詳細は、テンプレートリポジトリ側の README (仕様・運用手順書) を参照してください。
