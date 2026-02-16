# [Client Name] プロジェクト

## プロジェクト概要
[Here: プロジェクトの概要を記述してください]

## 開発・運用ガイド (Human Operations)

### 1. 環境セットアップ
このリポジトリの機能をフル活用するために、以下の設定を行ってください。

#### GitHub Secrets の設定 (必須)
GitHub Actions による Issue 自動同期機能を利用するために、リポジトリに以下の Secrets を登録してください。

| Secret Name | Value | Description |
| :--- | :--- | :--- |
| `AKAZAWA_PAT` | `ghp_...` | Project操作権限を持つ Personal Access Token (PAT) |

**PAT の作成方法**:
1. GitHub設定 > Developer settings > **Personal access tokens (Tokens (classic))**
2. **Generate new token (classic)**
3. **Scopes (権限)**:
   - `repo` (コード操作)
   - `write:org` (Project V2 アイテム追加)
   - `read:org` (Organization情報読み取り)
   - `project` (念のため)

### 2. Issue管理の運用
- **全件同期 (Global)**: Issueが作成・再開されると、自動的に `HinotoAI` Organization の **Project #[PROJECT_ID]** に追加されます。
- **個別同期 (Template)**: 特定のユーザーにアサインされた場合に、個別のProjectに追加する運用も可能です。

#### 設定手順
1. `.github/workflows/global-sync.yml` を編集し、`PROJECT_NUMBER` を正しいIDに変更してください。

### 3. 他メンバーの利用 (テンプレート)
特定のユーザー (`Sokan3`など) 以外のメンバーが同様の機能を利用する場合は、テンプレートから設定ファイルを作成してください。

#### 設定手順
1. **Secretsの登録**:
   - リポジトリに `YOUR_NAME_PAT` (例: `YAMADA_PAT`) を登録します。
2. **ワークフローの作成**:
   - `docs/templates/add-to-project.yml` を `.github/workflows/add-to-project-<YOUR_NAME>.yml` にコピーします。
   - ファイル内の `<YOUR_GITHUB_USERNAME>`, `<YOUR_PROJECT_NUMBER>`, `<YOUR_PAT_SECRET_NAME>` を書き換えて Push してください。

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
