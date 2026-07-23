#!/usr/bin/env bash
# =============================================================================
# Unity プロジェクトセットアップスクリプト (共通処理)
# -----------------------------------------------------------------------------
# 使い方: setup-project.sh <プロジェクトディレクトリ> <EditorVersion 例: 6000.0.32f1>
#
# 指定ディレクトリ配下に Unity プロジェクトの骨組みを構成する。
#   1. changeset の解決 (同梱 TSV → 公式 API の順。解決不能ならエラー停止)
#   2. Assets/ (.gitkeep 付き), Packages/, ProjectSettings/ の作成 (冪等)
#   3. ProjectSettings/ProjectVersion.txt の生成
#   4. resolve-upm.sh による manifest.json の生成
#
# 呼び出し元: template-init.yml / add-unity-project.yml / set-unity-version.yml
# ディレクトリの存在チェック (新規作成 or 既存のみ) は呼び出し側で行うこと。
# =============================================================================
set -euo pipefail

PROJECT_DIR="$1"
VER="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── changeset 解決 ─────────────────────────────────────────
# 1) 同梱 TSV (生成時点のスナップショット。無い/古い場合がある)
REV=$(awk -F'\t' -v v="$VER" '$1==v{print $2; exit}' .github/unity-versions.tsv 2>/dev/null || true)

# 2) 公式 API の全件走査フォールバック
#    (unity-versions-update.yml と同一のページング呼び出し形式。
#     応答が想定外の型でも .results?[]? がエラーにせず読み飛ばす)
if [ -z "$REV" ]; then
  LIMIT=25
  OFFSET=0
  TOTAL=1
  while [ -z "$REV" ] && [ "$OFFSET" -lt "$TOTAL" ]; do
    RESP=$(curl -sf "https://services.api.unity.com/unity/editor/release/v1/releases?limit=$LIMIT&offset=$OFFSET") || break
    T=$(echo "$RESP" | jq -r '.total? // 0' 2>/dev/null || echo 0)
    case "$T" in (*[!0-9]*|'') T=0 ;; esac
    TOTAL=$T
    REV=$(echo "$RESP" \
      | jq -r --arg v "$VER" '.results?[]? | select(.version? == $v) | .shortRevision? // empty' 2>/dev/null \
      | head -n1 || true)
    OFFSET=$((OFFSET + LIMIT))
    sleep 0.2
  done
fi

if [ -z "$REV" ]; then
  echo "::error::'$VER' の changeset を解決できません。バージョン表記 (例: 6000.0.32f1) を確認してください。表記が正しい場合は .github/unity-versions.tsv の更新か Unity Release API の応答を確認してください" >&2
  exit 1
fi

# ── 骨組み作成 ─────────────────────────────────────────────
mkdir -p "$PROJECT_DIR/Assets" "$PROJECT_DIR/Packages" "$PROJECT_DIR/ProjectSettings"
# Assets は空のままコミットされうるため .gitkeep で保持する
[ -e "$PROJECT_DIR/Assets/.gitkeep" ] || touch "$PROJECT_DIR/Assets/.gitkeep"

cat > "$PROJECT_DIR/ProjectSettings/ProjectVersion.txt" <<EOF
m_EditorVersion: $VER
m_EditorVersionWithRevision: $VER ($REV)
EOF

# ── UPM パッケージ解決 ─────────────────────────────────────
bash "$SCRIPT_DIR/resolve-upm.sh" "$VER" "$PROJECT_DIR"

echo "Unity $VER ($REV) : $PROJECT_DIR" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
