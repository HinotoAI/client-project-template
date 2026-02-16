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

# --- Issue 1 ---
read -r -d '' BODY1 << 'ISSUE_EOF' || true
## 概要
パスコ（矢尾板様）へ以下の会社情報を送付する（電子ファイル可）。

## タスク
- [ ] 会社案内を準備
- [ ] 登記簿コピーを準備
- [ ] パスコへ送付
- [ ] （代替）契約書雛形に押印者情報を記入して返送

## 参考
- NDA手続きフロー: 担当者間合意 → 稟議起案・決裁 → 押印・発送
- 連絡先: 矢尾板 啓 (aaktiy9527@pasco.co.jp)
ISSUE_EOF
create_issue \
  "会社情報（会社案内・登記簿コピー）をパスコへ送付" \
  "admin,NDA" \
  "$BODY1"

# --- Issue 2 ---
read -r -d '' BODY2 << 'ISSUE_EOF' || true
## 概要
会議内容および共有予定の資料に基づき、画像解析・データ拡張のアプローチに関する提案資料を作成し、パスコ（矢尾板様）へ送付する。

## 提案に含めるべき内容
- [ ] データ拡張手法（回転、明暗調整、ノイズ付加など）
- [ ] 教師データ品質改善の方針
- [ ] 撮影条件（白飛び、斜め撮影等）への対処法
- [ ] モデル改善の具体的アプローチ

## 背景
- 既存のAIは教師データの質・量に課題あり（2年間取り組み中）
- ゴミ検出、クラック検出など定義の難しい異常検出が求められている
- パスコは航空写真・多種カメラ（熱画像、レーザー等）のデータを保有
ISSUE_EOF
create_issue \
  "技術提案資料（画像解析・データ拡張アプローチ）を作成・送付" \
  "proposal,tech" \
  "$BODY2"

# --- Issue 3 ---
read -r -d '' BODY3 << 'ISSUE_EOF' || true
## 概要
パスコの実務担当者（報告書作成・抽出作業担当）との面談日程を調整する。

## 目的
- Hinotoが技術的に協力できる範囲を具体的に検討
- 来年度（2026年度夏前発注予定）の業務に向けた見積もり準備

## タスク
- [ ] パスコ（矢尾板様）へ面談希望の連絡
- [ ] 候補日程の提示
- [ ] 面談実施
ISSUE_EOF
create_issue \
  "パスコ現場担当者との面談日程を調整" \
  "meeting" \
  "$BODY3"

# ---------------------------------------------------------------------------
echo ""
if $DRY_RUN; then
  echo "? DRY-RUN 完了。問題なければ --execute をつけて再実行してください。"
else
  echo "? 全 Issue の作成が完了しました。確認: gh issue list"
fi
