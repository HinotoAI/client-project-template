# プロジェクト概要

ここは各自contextを保持

# エージェントの行動指針 (Rules)

### 1. タスク管理とIssue作成

- **自動化**: GitHub Actions (`.github/workflows/global-sync.yml`) により、作成されたIssueは自動的に指定したProjectに追加されます。
- **同期**: エージェントはタスクを整理し、随時 `docs/task.md` を更新してください。
- **一括作成**: 複数のIssueを作成する場合は `scripts/create_issues.sh` (内部で `gh issue create` を使用) の利用を検討してください。

### 2. ドキュメント管理

- `docs/context.md` はプロジェクトの最新状態を表します。アクションアイテムや議事録、決定事項はここに集約してください。

## 利用可能なワークフロー (Skills)

### `/create-issues`

`docs/context.md` のアクションアイテムから GitHub Issue を自動作成します。

### `/sync-tasks`

GitHub Issues と `docs/task.md` のステータスを双方向に同期します。

- `docs/task.md` のチェックボックスを更新すると、対応する Issue をクローズ/再オープンします。
- GitHub Issue がクローズされると、`docs/task.md` のチェックボックスを完了にします。

## GitHub ワークフロー (Auto-running)

### `global-sync.yml`

新しく作成された Issue を、組織のグローバルプロジェクトに自動追加します。

### `add-to-project-sokan3.yml`

Issue の担当者に `Sokan3` が設定された場合、自動的に Project 10 (Sokan3's Project) に追加します。

## エンコーディング

`docs/` 配下のファイルは **UTF-8** で統一されています。
文字化けが発生する場合は、エディタの設定を確認してください。

## ディレクトリ構成

- `docs/`: ドキュメント類
  - `context.md`: プロジェクト定義 (Source of Truth)
  - `mails.md`: メール記録
  - `templates/`: 各種テンプレート
    - `add-to-project.yml`: メンバー個別同期用テンプレート
- `scripts/`: 運用スクリプト
  - `create_issues.sh`: Issue作成スクリプト
  - `sync_tasks.sh`: タスク同期スクリプト
- `.github/workflows/`: GitHub Actions 定義
  - `global-sync.yml`: 全件同期用 (要編集)
  - `add-to-project-sokan3.yml`: Sokan3用 (サンプル)
