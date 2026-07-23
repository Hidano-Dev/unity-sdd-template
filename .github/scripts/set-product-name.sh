#!/usr/bin/env bash
# =============================================================================
# プロダクト名変更スクリプト
# -----------------------------------------------------------------------------
# 使い方: set-product-name.sh <プロジェクトディレクトリ> <新しいプロダクト名>
#
# <プロジェクトディレクトリ>/ProjectSettings/ProjectSettings.asset の
# productName を書き換える。ディレクトリ名は変更しない。
#
# ※ 置換は環境変数経由で行うため、名前に記号が含まれていても安全。
#    ただし ':' や '#' など YAML 的に特殊な文字を含む名前は Unity 側でも
#    問題を起こしうるため避けること。
#
# 呼び出し元: template-init.yml / set-product-name.yml
# =============================================================================
set -euo pipefail

PROJECT_DIR="$1"
NEW_NAME="$2"
FILE="$PROJECT_DIR/ProjectSettings/ProjectSettings.asset"

if [ ! -f "$FILE" ]; then
  echo "::error::$FILE が見つかりません" >&2
  exit 1
fi

PRODUCT_NAME="$NEW_NAME" perl -pi -e 's/^(\s*productName:\s*).*/$1.$ENV{PRODUCT_NAME}/e' "$FILE"

if ! grep -F "productName: $NEW_NAME" "$FILE" >/dev/null; then
  echo "::error::productName の書き換えに失敗しました ($FILE に productName 行が見つからない可能性)" >&2
  exit 1
fi

echo "productName: $NEW_NAME : $PROJECT_DIR" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
