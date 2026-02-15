---
description: docs/context.md のアクションアイテムから GitHub Issue を自動作成する
---

# context.md から GitHub Issue を作成する

## 概要
`docs/context.md` のセクション4「直近のアクションアイテム」に記載された Hinoto 側のタスクを、
GitHub Issue として自動作成するワークフロー。`scripts/create_issues.sh` を使用する。

## 前提条件
- `gh` CLI がインストールされていること
- `gh auth login` で GitHub に認証済みであること（`gh auth status` で確認可）

## 手順

### 1. context.md の確認・更新
`docs/context.md` セクション4を確認し、新しいアクションアイテムがあるか確認する。
- **対象**: Hinoto 側のアクションアイテムのみ
- **対象外**: パスコ側のアクションアイテム

### 2. scripts/create_issues.sh の更新
新しいアクションアイテムがある場合、`scripts/create_issues.sh` に Issue 定義を追加する。
既存の Issue 定義を参考に、以下の形式で追加:

```bash
# --- Issue N ---
read -r -d '' BODYN << 'ISSUE_EOF' || true
## 概要
[タスクの説明]

## タスク
- [ ] [具体的なタスク1]
- [ ] [具体的なタスク2]
ISSUE_EOF
create_issue \
  "[Issue タイトル]" \
  "[label1,label2]" \
  "$BODYN"
```

利用可能なラベル: `admin`, `NDA`, `proposal`, `tech`, `meeting`（新規ラベルも自動作成される）

### 3. dry-run で確認
// turbo
```bash
./scripts/create_issues.sh
```
出力された Issue 内容を確認する。

### 4. Issue を作成
```bash
./scripts/create_issues.sh --execute
```
- 同名の Issue が既に存在する場合は自動でスキップされる
- ラベルが存在しない場合は自動作成される

### 5. 作成結果を確認
// turbo
```bash
gh issue list
```
