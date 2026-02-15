# HinotoAI クライアントプロジェクト管理テンプレート

**クライアントプロジェクトの進行管理、コミュニケーション記録、タスク管理を一元化するためのテンプレートリポジトリ**

このテンプレートは、GitHub Issues との同期機能を備え、効率的なプロジェクト管理を実現します。

---

## ? このテンプレートでできること

- ? プロジェクトの全体像・関係者・ステータスを一元管理（`docs/context.md`）
- ? アクションアイテムから GitHub Issues を自動作成（`/create-issues`）
- ? タスク管理ファイルと GitHub Issues を双方向同期（`/sync-tasks`）
- ? 会議記録・メールのやりとりを構造化して保存
- ? AI エージェント（Antigravity）がプロジェクト構造を理解して効率的にサポート

---

## ? ディレクトリ構成

```
.
├── .agent/
│   └── workflows/          # カスタムワークフロー定義
│       ├── create-issues.md   # context.md から Issue 自動作成
│       └── sync-tasks.md      # task.md と Issue を同期
├── .antigravity/
│   └── instructions.md     # AI エージェント向けプロジェクト説明
├── docs/
│   ├── context.md          # プロジェクト全体像・関係者・アクションアイテム
│   ├── task.md             # タスク管理（Issue とリンク）
│   ├── mails.md            # メールコミュニケーション記録
│   └── meetings/           # 会議記録（日付.md）
├── scripts/
│   ├── create_issues.sh    # context.md から GitHub Issue 作成
│   └── sync_tasks.sh       # task.md と Issue を双方向同期
└── README.md               # このファイル
```

---

## ? セットアップ手順

### 1. このテンプレートから新しいリポジトリを作成

GitHubで「Use this template」ボタンをクリックして、新しいプロジェクト用のリポジトリを作成します。

```bash
# リポジトリをクローン
git clone git@github.com:HinotoAI/your-project-name.git
cd your-project-name
```

### 2. プロジェクト情報をカスタマイズ

#### ? `docs/context.md` を作成

`docs/context.md.sample` をコピーして、プロジェクト固有の情報を記載：

```bash
cp docs/context.md.sample docs/context.md
```

以下のセクションを埋めます：
- **プロジェクト概要**: 目的、背景、目標
- **関係者**: クライアント側・Hinoto側の担当者
- **プロジェクトステータス**: 進捗、マイルストーン
- **直近のアクションアイテム**: Hinoto側・クライアント側のタスク

#### ? `docs/task.md` を作成

```bash
cp docs/task.md.sample docs/task.md
```

タスクを追加し、GitHub Issue番号とリンクさせます。

#### ?? `docs/mails.md` を作成（任意）

```bash
cp docs/mails.md.sample docs/mails.md
```

メールのやりとりを記録します。

#### ? `.antigravity/instructions.md` を更新

プロジェクト固有の技術詳細やAIエージェント向けの指示を追加します。

### 3. GitHub CLI のセットアップ

Issue 作成・同期スクリプトを使用するには `gh` CLI が必要です：

```bash
# インストール（macOS）
brew install gh

# 認証
gh auth login

# 確認
gh auth status
```

---

## ? 使い方

### ワークフロー 1: `/create-issues` - Issue 自動作成

`docs/context.md` のアクションアイテムから GitHub Issues を自動作成します。

#### 手順

1. **`docs/context.md` のセクション4「直近のアクションアイテム」を更新**
   - Hinoto 側のアクションアイテムを記載

2. **`scripts/create_issues.sh` に Issue 定義を追加**
   
   既存のサンプルを参考に、以下の形式で追加：
   
   ```bash
   # --- Issue N ---
   read -r -d '' BODYN << 'ISSUE_EOF' || true
   ## 概要
   [タスクの説明]
   
   ## タスク
   - [ ] サブタスク1
   - [ ] サブタスク2
   ISSUE_EOF
   create_issue \
     "[Issue タイトル]" \
     "admin,tech" \
     "$BODYN"
   ```

3. **dry-run で確認**
   
   ```bash
   ./scripts/create_issues.sh
   ```

4. **Issue を作成**
   
   ```bash
   ./scripts/create_issues.sh --execute
   ```

5. **作成結果を確認**
   
   ```bash
   gh issue list
   ```

---

### ワークフロー 2: `/sync-tasks` - タスク同期

`docs/task.md` と GitHub Issues を双方向で同期します。

#### 手順

1. **同期を実行**
   
   ```bash
   ./scripts/sync_tasks.sh
   ```
   
   - Issue がクローズされている → `task.md` を `[x]` に更新
   - `task.md` で `[x]` 完了 → Issue をクローズ

2. **dry-run で確認**
   
   ```bash
   ./scripts/sync_tasks.sh --dry-run
   ```

---

## ? ベストプラクティス

### タスク管理のフロー

1. **アクションアイテムを `context.md` に記載**
2. **`/create-issues` で GitHub Issue を作成**
3. **`task.md` に Issue 番号付きでタスクを追加**
   
   ```markdown
   - [ ] タスク名 [#1](https://github.com/HinotoAI/your-project/issues/1)
   ```

4. **タスク完了時は `task.md` で `[x]` にマーク**
5. **`/sync-tasks` で Issue を自動クローズ**

### ファイルエンコーディングについて

クライアントから受け取る資料が **Shift-JIS (CP932)** の場合があります。その際は以下のコマンドで UTF-8 に変換してください：

```bash
iconv -f CP932 -t UTF-8 docs/mails.md > docs/mails_utf8.md
mv docs/mails_utf8.md docs/mails.md
```

---

## ? 利用可能なラベル

Issue 作成時に使用できるラベル：
- `admin` - 事務的・契約関連のタスク
- `NDA` - NDA・機密保持関連
- `proposal` - 提案・企画書作成
- `tech` - 技術的なタスク
- `meeting` - 会議・面談関連

新しいラベルは `scripts/create_issues.sh` の `ensure_labels()` 関数に追加すると自動作成されます。

---

## ? AI エージェント連携

このテンプレートは Antigravity AI エージェントと連携するよう設計されています。

- `.antigravity/instructions.md` にプロジェクト構造を記載
- `.agent/workflows/` にカスタムワークフローを定義
- AI エージェントが `/create-issues` や `/sync-tasks` コマンドを理解してサポート

---

## ? ライセンス

このテンプレートは HinotoAI のクライアントプロジェクト管理用に設計されています。

---

## ? フィードバック・改善提案

テンプレートの改善提案は HinotoAI チームまでお願いします。
