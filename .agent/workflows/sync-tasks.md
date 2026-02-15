---
description: GitHub Issues と docs/task.md を同期する
---

# GitHub Issues と task.md を同期

## 概要
`docs/task.md` のチェックボックスと GitHub Issues のステータスを双方向で同期する。

## 手順

### 1. Issue → task.md の同期（Issue のステータスを task.md に反映）

// turbo
```bash
gh issue list --state all --json number,title,state --jq '.[] | "\(.number),\(.title),\(.state)"'
```

このコマンドで取得した Issue 一覧と `docs/task.md` のチェックボックスを見比べて、手動または自動で同期する。

**手動同期の場合**:
1. クローズされた Issue を確認
2. `task.md` で該当タスクを `- [x]` にマーク
3. 完了タスクを「完了したタスク」セクションに移動

**自動同期（今後実装予定）**:
`scripts/sync_tasks.sh` を作成し、Issue API から状態を取得 → `task.md` を自動更新

### 2. task.md → Issue の同期（task.md の完了を Issue に反映）

`task.md` でタスクを完了 (`- [x]`) にマークした際、対応する Issue をクローズする。

```bash
# 例: Issue #1 を完了させる
gh issue close 1 --comment "タスク完了"
```

### 3. 新しいタスクを追加

`context.md` に新しいアクションアイテムが追加されたら:

1. `/create-issues` で Issue を作成
2. `task.md` に対応するタスクを追加（Issue 番号リンク付き）

```markdown
- [ ] [タスク名] [#N](https://github.com/HinotoAI/your-project/issues/N)
```

## 今後の拡張案
- `scripts/sync_tasks.sh` ? GitHub API で Issue 状態を取得し、`task.md` を自動更新
- `scripts/close_issue.sh` ? `task.md` の `[x]` からクローズすべき Issue を自動検出してクローズ
