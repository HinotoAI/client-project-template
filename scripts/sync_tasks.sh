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
# ---------------------------------------------------------------------------
# task.md から Issue 番号と完了状態を抽出
# ---------------------------------------------------------------------------
parse_task_md() {
  # [x] または [ ] の行のみを抽出し、Issue 番号 (#N) があるものを取得
  LC_ALL=C grep -E '^[[:space:]]*- \[(x| )\]' "$TASK_FILE" | LC_ALL=C grep '\[#[0-9]\+\]' | while IFS= read -r line; do
    # チェック状態を判定
    if echo "$line" | LC_ALL=C grep -q '^[[:space:]]*- \[x\]'; then
      status="completed"
    else
      status="open"
    fi
    
    # Issue 番号を抽出
    issue_num=$(echo "$line" | LC_ALL=C grep -oE '#[0-9]+' | head -1 | tr -d '#')
    
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
    if LC_ALL=C grep -q "\[#$number\]" "$TASK_FILE"; then
      local current_status
      if LC_ALL=C grep "\[#$number\]" "$TASK_FILE" | LC_ALL=C grep -q '^[[:space:]]*- \[x\]'; then
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
          LC_ALL=C sed -i.bak -E "s/(- \[) (\].*\[#$number\])/\1x\2/" "$TASK_FILE"
        fi
      fi
      
      # Issue がオープンだが task.md で完了済みの場合
      # task.md で完了にした場合、後続の sync_task_to_issue で Issue をクローズするため、ここでは戻さない
      # if [[ "$state" == "OPEN" && "$current_status" == "completed" ]]; then
      #   echo "  Issue #$number: OPEN → task.md を [ ] に戻す"
      #   has_changes=true
      #   
      #   if ! $DRY_RUN; then
      #     LC_ALL=C sed -i.bak -E "s/(- \[)x(\].*\[#$number\])/\1 \2/" "$TASK_FILE"
      #   fi
      # fi
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
# task.md から Issue を自動作成（[#N] がないタスクを対象）
# ---------------------------------------------------------------------------
create_issues_from_task_md() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "? task.md → Issue の作成（新規タスク）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local has_changes=false
  # 一時ファイルを使用せず、行ごとに処理するためにループ
  # 注意: 行番号が変わると sed がずれる可能性があるため、逆順処理などは難しい。
  # ここでは単純にファイルを読み込み、マッチした行を処理する。
  
  # 変更を行うため、一時ファイルにコピーして作業
  cp "$TASK_FILE" "$TASK_FILE.tmp"
  
  while IFS= read -r line; do
    # - [ ] または - [x] で始まり、かつ [#N] を持たない行を検索
    # LC_ALL=C でバイト列として処理（エンコーディング問題を回避）
    if echo "$line" | LC_ALL=C grep -E -q '^[[:space:]]*- \[( |x)\] ' && ! echo "$line" | LC_ALL=C grep -E -q '\[#[0-9]+\]'; then
      
      # インデントとタスク内容を抽出
      indent=$(echo "$line" | LC_ALL=C grep -oE '^[[:space:]]*')
      status_mark=$(echo "$line" | LC_ALL=C grep -oE '\[( |x)\]')
      task_content=$(echo "$line" | LC_ALL=C sed -E 's/^[[:space:]]*- \[( |x)\] //')
      
      # 空のタスクはスキップ
      if [[ -z "$task_content" ]]; then continue; fi
      
      echo "  新規タスク検出: $task_content"
      has_changes=true
      
      if $DRY_RUN; then
        # 表示用に変換（失敗したらそのまま）
        echo "    [DRY-RUN] Issue 作成: $task_content"
      else
        # Issue 作成
        echo "    Issue を作成中..."
        new_issue_url=$(gh issue create --title "$task_content" --body "From task.md" --assignee "@me" 2>/dev/null)
        new_issue_num=$(echo "$new_issue_url" | awk -F'/' '{print $NF}')
        
        echo "    ✓ 作成完了: #$new_issue_num"
        
        # task.md の該当行を更新
        # 特殊文字のエスケープ処理が必要（sedの置換条件式で使うため）
        # \ [ ] * . ^ $ | & をエスケープ
        escaped_content=$(echo "$task_content" | LC_ALL=C sed 's/\\/\\\\/g' | LC_ALL=C sed 's/\[/\\[/g' | LC_ALL=C sed 's/\]/\\]/g' | LC_ALL=C sed 's/\*/\\*/g' | LC_ALL=C sed 's/\./\\./g' | LC_ALL=C sed 's/\^/\\^/g' | LC_ALL=C sed 's/\$/\\$/g' | LC_ALL=C sed 's/|/\\|/g' | LC_ALL=C sed 's/&/\\&/g')
        
        # 行全体を置換対象にする
        LC_ALL=C sed -i.bak "s|^\(${indent}- ${status_mark}\) ${escaped_content}\$|\1 ${escaped_content} [#${new_issue_num}](${new_issue_url})|" "$TASK_FILE"
      fi
    fi
  done < "$TASK_FILE.tmp"
  
  rm -f "$TASK_FILE.tmp"
  
  if ! $has_changes; then
    echo "  新規タスクなし"
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

create_issues_from_task_md
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
