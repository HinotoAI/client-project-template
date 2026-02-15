#!/bin/bash
# =============================================================================
# sync_tasks.sh
# GitHub Issues と docs/task.md を双方向で自動同期するスクリプト
#
# Usage:
#   ./scripts/sync_tasks.sh              # 同期を実行
#   ./scripts/sync_tasks.sh --dry-run    # 確認のみ（変更しない）
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_FILE="$REPO_ROOT/docs/task.md"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# ---------------------------------------------------------------------------
# Issue 情報を取得
# ---------------------------------------------------------------------------
get_issue_status() {
  gh issue list --state all --json number,title,state --jq '.[] | "\(.number)|\(.title)|\(.state)"'
}

# ---------------------------------------------------------------------------
# task.md から Issue 番号と完了状態を抽出
# ---------------------------------------------------------------------------
parse_task_md() {
  # [x] または [ ] の行のみを抽出し、Issue 番号 (#N) があるものを取得
  grep -E '^\s*- \[(x| )\].*\[#[0-9]+\]' "$TASK_FILE" | while IFS= read -r line; do
    # チェック状態を判定
    if echo "$line" | grep -q '^\s*- \[x\]'; then
      status="completed"
    else
      status="open"
    fi
    
    # Issue 番号を抽出
    issue_num=$(echo "$line" | grep -oE '#[0-9]+' | head -1 | tr -d '#')
    
    if [[ -n "$issue_num" ]]; then
      echo "$issue_num|$status"
    fi
  done
}

# ---------------------------------------------------------------------------
# Issue → task.md の同期
# ---------------------------------------------------------------------------
sync_issue_to_task() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "? Issue → task.md の同期"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local has_changes=false
  
  while IFS='|' read -r number title state; do
    # task.md での該当行を検索
    if grep -q "\[#$number\]" "$TASK_FILE"; then
      local current_status
      if grep "\[#$number\]" "$TASK_FILE" | grep -q '^\s*- \[x\]'; then
        current_status="completed"
      else
        current_status="open"
      fi
      
      # Issue がクローズされているが task.md で未完了の場合
      if [[ "$state" == "CLOSED" && "$current_status" == "open" ]]; then
        echo "  Issue #$number: CLOSED → task.md を [x] に更新"
        has_changes=true
        
        if ! $DRY_RUN; then
          # task.md のチェックボックスを [x] に変更
          sed -i.bak -E "s/(- \[) (\].*\[#$number\])/\1x\2/" "$TASK_FILE"
        fi
      fi
      
      # Issue がオープンだが task.md で完了済みの場合
      if [[ "$state" == "OPEN" && "$current_status" == "completed" ]]; then
        echo "  Issue #$number: OPEN → task.md を [ ] に戻す"
        has_changes=true
        
        if ! $DRY_RUN; then
          sed -i.bak -E "s/(- \[)x(\].*\[#$number\])/\1 \2/" "$TASK_FILE"
        fi
      fi
    fi
  done < <(get_issue_status)
  
  if ! $has_changes; then
    echo "  変更なし"
  fi
}

# ---------------------------------------------------------------------------
# task.md → Issue の同期
# ---------------------------------------------------------------------------
sync_task_to_issue() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "? task.md → Issue の同期"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local has_changes=false
  
  while IFS='|' read -r issue_num task_status; do
    # Issue の現在のステータスを取得
    local issue_state
    issue_state=$(gh issue view "$issue_num" --json state --jq '.state' 2>/dev/null || echo "NOT_FOUND")
    
    if [[ "$issue_state" == "NOT_FOUND" ]]; then
      echo "  ??  Issue #$issue_num: 見つかりません"
      continue
    fi
    
    # task.md で完了だが Issue がオープンの場合
    if [[ "$task_status" == "completed" && "$issue_state" == "OPEN" ]]; then
      echo "  Issue #$issue_num: task.md で完了 → Issue をクローズ"
      has_changes=true
      
      if ! $DRY_RUN; then
        gh issue close "$issue_num" --comment "task.md でタスク完了のため自動クローズ"
      fi
    fi
    
    # task.md で未完了だが Issue がクローズの場合（リオープン）
    if [[ "$task_status" == "open" && "$issue_state" == "CLOSED" ]]; then
      echo "  Issue #$issue_num: task.md で未完了 → Issue を再オープン"
      has_changes=true
      
      if ! $DRY_RUN; then
        gh issue reopen "$issue_num" --comment "task.md でタスク再開のため自動リオープン"
      fi
    fi
  done < <(parse_task_md)
  
  if ! $has_changes; then
    echo "  変更なし"
  fi
}

# ---------------------------------------------------------------------------
# メイン
# ---------------------------------------------------------------------------
echo "========================================"
if $DRY_RUN; then
  echo "? DRY-RUN モード（確認のみ）"
else
  echo "? 同期を実行します"
fi
echo "========================================"

sync_issue_to_task
sync_task_to_issue

echo ""
if $DRY_RUN; then
  echo "? DRY-RUN 完了。実際に同期するには --dry-run なしで再実行してください。"
else
  echo "? 同期完了"
  # バックアップファイルを削除
  rm -f "$TASK_FILE.bak"
fi
