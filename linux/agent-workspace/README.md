# Agent Workspace

ハーネスに依存せずに使える、自己完結したエージェントの作業領域。

## 起動

```bash
cd ~/workspace/agent-workspace
codex
```

環境構築（WSL・Node.js・Codexのインストール）は [setup](https://github.com/natsume6075/setup/tree/feat/add-agent-harness/linux) で行う。

## ディレクトリ構成

```text
agent-workspace/
├── README.md             # 人間向けの入口
├── AGENTS.md             # エージェントの自動読み込み入口
├── .agents/
│   ├── docs/             # 設計・方針・引き継ぎ・作業状況
│   └── skills/           # ハーネス間で共有するSkills（必要時に追加）
├── .codex/               # Codex固有の宣言的設定（必要時に追加）
├── projects/             # 各プロジェクトと成果物
└── .gitignore
```

`README.md` と `AGENTS.md` はルートに残す。共通の管理資料は `.agents/docs/` に集める。Codexの設定は必要に応じて `.codex/` に置き、プロジェクト外には適用しない。

## Git管理

- **Gitで管理する**: 共通指示、Skills、設定（秘密情報を除く）、管理資料、プロジェクト内のテキスト・コード・小さな成果物。
- **Gitに含めない**: 認証情報、トークン、セッション/キャッシュ、依存パッケージ、ビルド出力、大きな一時成果物。
- **クラウド同期**: 個人のObsidian Vaultや大容量成果物はKoofrへ。Gitの作業ツリー全体をKoofrと二重同期しない。
- **他のGitリポジトリ**: `projects/` に入れ子でcloneする前に、別管理やworktreeを検討する。

## 作業の継続

新しいCodexセッションでは、`AGENTS.md` と [引き継ぎ資料](.agents/docs/HANDOFF.md) を参照する。

