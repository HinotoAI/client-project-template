#!/bin/bash
# =============================================================================
# create_issues.sh
# docs/context.md のアクションアイテムから GitHub Issue を自動作成するスクリプト
#
# Usage:
#   ./scripts/create_issues.sh              # dry-run (確認のみ)
#   ./scripts/create_issues.sh --execute    # 実際に Issue を作成
# =============================================================================

set -euo pipefail

DRY_RUN=true
if [[ "${1:-}" == "--execute" ]]; then
  DRY_RUN=false
fi

# ---------------------------------------------------------------------------
# ラベル確認・作成
# ---------------------------------------------------------------------------
ensure_labels() {
  if $DRY_RUN; then return; fi
  echo "?  ラベルを確認中..."
  for label in admin NDA proposal tech meeting; do
    if ! gh label list --search "$label" --limit 1 2>/dev/null | grep -qw "$label"; then
      echo "   ラベル '$label' を作成します"
      gh label create "$label" --description "" --color "ededed" 2>/dev/null || true
    fi
  done
}

# ---------------------------------------------------------------------------
# Issue 作成関数
# ---------------------------------------------------------------------------
issue_count=0

create_issue() {
  local title="$1"
  local labels="$2"
  local body="$3"

  issue_count=$((issue_count + 1))

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf '? Issue #%d: %s\n' "$issue_count" "$title"
  printf '?  Labels: %s\n' "$labels"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$body"
  echo ""

  if $DRY_RUN; then
    echo "?  [DRY-RUN] スキップ"
  else
    # 重複チェック
    local existing
    existing="$(gh issue list --search "\"$title\" in:title" --state all --limit 1 2>/dev/null || true)"
    if echo "$existing" | grep -q "$title"; then
      echo "??  同名の Issue が既に存在するためスキップ"
    else
      gh issue create \
        --title "$title" \
        --body "$body" \
        --label "$labels"
      echo "? Issue を作成しました"
    fi
  fi
}

# ---------------------------------------------------------------------------
# メイン
# ---------------------------------------------------------------------------
echo "========================================"
if $DRY_RUN; then
  echo "? DRY-RUN モード（確認のみ）"
  echo "   実際に作成するには: $0 --execute"
else
  echo "? EXECUTE モード（Issue を作成します）"
fi
echo "========================================"

ensure_labels

# --- サンプル Issue ---
# 以下のテンプレートをコピーして、プロジェクト固有の Issue を追加してください

read -r -d '' BODY1 << 'ISSUE_EOF' || true
## 概要
[タスクの説明をここに記載]

## タスク
- [ ] サブタスク1
- [ ] サブタスク2
- [ ] サブタスク3

## 参考
[参考情報や背景を記載]
ISSUE_EOF
create_issue \
  "[Issue タイトル]" \
  "admin" \
  "$BODY1"

# 追加の Issue は上記テンプレートをコピーして作成してください
# 利用可能なラベル: admin, NDA, proposal, tech, meeting

# ---------------------------------------------------------------------------
echo ""
if $DRY_RUN; then
  echo "? DRY-RUN 完了。問題なければ --execute をつけて再実行してください。"
else
  echo "? 全 Issue の作成が完了しました。確認: gh issue list"
fi
