# クライアントプロジェクト管理テンプレート

## プロジェクト概要

クライアントプロジェクトの進行管理、コミュニケーション記録、タスク管理を一元化するためのテンプレート。
GitHub Issues との同期機能を備え、効率的なプロジェクト管理を実現します。

## ディレクトリ構成

```
docs/
  context.md        # プロジェクトの全体像・関係者・ステータス・アクションアイテム
  task.md           # タスク管理（GitHub Issues とリンク）
  mails.md          # メールのやりとり記録
  meetings/         # 会議記録（日付.md）
scripts/
  create_issues.sh  # context.md のアクションアイテムから GitHub Issue を自動作成
  sync_tasks.sh     # task.md と GitHub Issues を双方向同期
.agent/workflows/
  create-issues.md  # Issue 作成ワークフロー
  sync-tasks.md     # タスク同期ワークフロー
```

## エンコーディングに関する注意

`docs/` 配下のファイルは **Shift-JIS (CP932)** でエンコードされている可能性があります。
読み取り時は `iconv -f CP932 -t UTF-8` で変換してから処理してください。

## 利用可能なワークフロー (Skills)

- `/create-issues` — `docs/context.md` のアクションアイテムから GitHub Issue を自動作成する
- `/sync-tasks` — GitHub Issues と `docs/task.md` を同期する

## セットアップ

1. **プロジェクト情報をカスタマイズ**
   - `docs/context.md.sample` → `docs/context.md` にコピーして編集
   - `docs/task.md.sample` → `docs/task.md` にコピーして編集
   - `docs/mails.md.sample` → `docs/mails.md` にコピー（任意）

2. **GitHub CLI をセットアップ**
   ```bash
   brew install gh
   gh auth login
   ```

3. **Issue 作成スクリプトをカスタマイズ**
   - `scripts/create_issues.sh` にプロジェクト固有の Issue 定義を追加

詳細は [README.md](../README.md) を参照してください。
