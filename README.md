# Copilot Customizations Hub

個人用の GitHub Copilot **Agent Skills** と **カスタムエージェント** の置き場（git 管理）。

- `.github/skills/` 配下の各フォルダ（`SKILL.md` を含む）が 1 つの**スキル**。
- `.github/agents/` 配下の各 `*.agent.md` が 1 つの**カスタムエージェント**（利用ツールを限定できる）。

- **このリポジトリを開いているとき**は、`.github/skills/` と `.github/agents/` が自動で認識されます（clone 直後・別 PC でもそのまま動く）。
- **他のワークスペースからも使いたいとき**は、`link-customizations.ps1` でユーザープロファイルへリンクします（スキル → `~/.copilot/skills/`、エージェント → `%APPDATA%\Code\User\prompts\`）。

> **スキル vs カスタムエージェント**: スキルは `tools` を指定できず全ツールが使えるのに対し、
> カスタムエージェントは `tools` フィールドで利用可能ツールを限定できる。
> 「特定の MCP サーバーだけ使って正確な情報に絞りたい」用途はエージェントが適する。

## 仕組み

Copilot はスキルを次の場所から探します:

| 場所 | スコープ | このリポジトリでの役割 |
| --- | --- | --- |
| `<repo>/.github/skills/<name>/SKILL.md` | そのワークスペースのみ | **ソース（git 管理）** |
| `~/.copilot/skills/<name>/SKILL.md` | 全ワークスペース共通（個人用） | 参照先（リンクで接続） |

`.github/skills/` を唯一のソースとし、グローバル参照はそこへのリンクで実現します（実体を二重に持たない）。

## セットアップ

### A. このリポジトリ内で使うだけ

追加設定は不要。VS Code 設定 `chat.agent.skills` が `true` であれば、
このワークスペースを開くだけで `.github/skills/` 内のスキルが認識されます。

### B. 他のワークスペースからも使う（全 WS 共通）

1. VS Code 設定 `chat.agent.skills` を `true`。
2. スキルをグローバルへリンク:

   ```powershell
   ./link-customizations.ps1
   ```

3. VS Code を再読み込み（コマンドパレット → *Developer: Reload Window*）。

> リンクは各マシンローカルの設定なので git には含まれません。別 PC で clone した場合は
> B を使うときだけ `./link-customizations.ps1` を一度実行してください（A のみなら不要）。

## 開発フロー（ブランチ運用）

開発中のスキルも `.github/skills/` に置けば、このワークスペースを開いている限り
すぐに発火テストできる（グローバルへのリンクは不要）。ブランチで隔離することで、
未完成スキルを `main` に混ぜずに試行錯誤できる。

1. 開発ブランチを切る: `git switch -c skill/<name>`
2. `.github/skills/<name>/SKILL.md` を作成・編集。
3. **このWSで発火テスト**（別WSに影響なし）。必要なら *Developer: Reload Window*。
   - スキルが生成する中間ファイルや動作確認用の出力は `output/` に吐かせる
     （git 管理外なのでリポが汚れない）。
4. 満足したら `main` にマージ。
5. 全 WS で使うなら `./link-customizations.ps1` を実行してグローバルへ昇格。

> `output/` は「テスト成果物・スクラッチ専用」。スキル本体は置かない。
> リポジトリのルート直下には成果物ファイルを置かず、必ず `output/` 配下に出力する
> （[.github/copilot-instructions.md](.github/copilot-instructions.md) で指示）。

## 新しいスキルの追加

1. `.github/skills/<kebab-case-name>/SKILL.md` を作成（下記フォーマット）。
2. 全 WS で使うなら `./link-customizations.ps1` を再実行（新規分だけリンクされます）。
3. commit & push。

### SKILL.md フォーマット

```markdown
---
name: my-skill-name
description: 何をするスキルか / いつ使うか。トリガーとなる語句を具体的に含める。
---

# My Skill

- 手順やルールを箇条書き・番号付きで明確に
- 例やエッジケースを添える
```

- `name`: 小文字・数字・ハイフンのみ。フォルダ名と一致させる。
- `description`: これを見て Copilot が読み込み可否を判断するため、具体的に。

### 命名規則（フォルダ = スキル名）

`.github/skills/` は**フラット構造**が前提で、カテゴリ用の中間フォルダ
（例: `.github/skills/azure/xxx/`）は Copilot に認識されない。
そのため、グルーピングは**名前のプレフィックス**で表現する。

- 形式: `<領域>-<対象>`（すべて小文字・数字・ハイフン）
- 例: `azure-storage`, `azure-functions`, `azure-rbac`, `m365-teams`
- 汎用スキルはプレフィックスなしでも可: `example-skill`
- プレフィックスで並ぶため、ファイルツリー上は視覚的にグルーピングされる

```text
.github/skills/
├── azure-storage/     SKILL.md
├── azure-functions/   SKILL.md
├── azure-rbac/        SKILL.md
└── example-skill/     SKILL.md
```

> 参考: Microsoft 公式の Azure スキルカタログも同じ命名方式
> （[Azure Agent Skills](https://learn.microsoft.com/training/support/agent-skills#getting-started)）。

## ディレクトリ構成

```text
ws-skills-inventory-zukako/
├── README.md
├── .gitignore
├── link-customizations.ps1      # skills/* と agents/* をユーザープロファイルへリンク
├── output/                      # 開発中のテスト成果物・スクラッチ（git 管理外）
└── .github/
    ├── copilot-instructions.md  # ルート直置き禁止など、このリポの作業ルール
    ├── skills/
    │   └── <skill-name>/
    │       └── SKILL.md         # スキル: メタデータ + 手順
    └── agents/
        └── <agent-name>.agent.md  # カスタムエージェント: tools 限定可
```

## カスタムエージェント

利用ツールを絞りたい調査系・専門系の役割は、スキルではなく**カスタムエージェント**
（`.github/agents/<name>.agent.md`）として作る。フロントマターの `tools` で
利用可能ツール（MCP サーバーは `<server>/*`）を限定でき、「静的で正確な情報だけに
制御する」用途に向く。

収録例:

- `azure-research`: Microsoft Learn MCP（`microsoft.docs.mcp`）と
  Release Communications MCP（`mrc-mcp-server`）だけを使い、必ず出典リンク付きで
  Azure 技術情報を調べる読み取り専用エージェント。

```markdown
---
description: 何をする / いつ使うか（トリガー語を具体的に）
name: 'my-agent'
tools: ['microsoft.docs.mcp/*', 'mrc-mcp-server/*']
argument-hint: 入力の例
---

# 役割と制約・手順をここに記述
```

> エージェントはユーザーの `prompts` フォルダ（`%APPDATA%\Code\User\prompts\`）から
> 全 WS 共通で認識される。`./link-customizations.ps1` はエージェントファイルもここへリンクする。

## `link-customizations.ps1` の仕組みと出力

### リンクだから「編集は自動で伝わる」

このスクリプトはリポジトリ側（ソース）とユーザープロファイル側（参照先）を
**リンクで接続**する。リンクは「同じ実体を指す別名」であってコピーではないため、
**リポジトリ側のファイルを編集すれば参照先にもそのまま反映される**。編集のたびに
スクリプトを再実行して張り直す必要はない。

| 対象 | 既定のリンク種別 | 補足 |
| --- | --- | --- |
| スキル（フォルダ） | ジャンクション（`-Symbolic` でシンボリックリンク） | フォルダ単位で接続 |
| エージェント（`*.agent.md`） | ハードリンク（`-Symbolic` でシンボリックリンク） | 同一ボリューム限定。不可ならコピーにフォールバック |
| MCP サーバー（`mcp.json`） | — | JSON のキー単位でマージ（リンク不可のため） |

再実行時はエージェントについて**内容ハッシュで同期判定**する。リンクが生きていれば
ソースと参照先は同じ実体なのでハッシュは常に一致し、`OK（同期済み）` と表示される
（＝すでに最新、対処不要）。

### 「再リンク」が実際に走るのはどんなとき

ハッシュが食い違ったとき、つまり**リンクが切れて実体が 2 つに分かれたとき**だけ、
削除して張り直し最新を取り込む。主なケース:

- `git` の `checkout` / `pull` / `stash` などでリポジトリ側ファイルが別実体に置き換わった
- 一部エディタの「アトミック保存」で inode が作り直された
- 過去にコピー（フォールバック）で作られていた

> つまり通常の編集運用では `OK（同期済み）` が出るのが正常で、変更はリアルタイムに
> 反映されている。VS Code 上でエージェントの挙動が変わらないと感じたら、ファイル同期
> ではなく *Developer: Reload Window* が必要なだけのことが多い。

### 出力メッセージの色

| 色 | 意味 |
| --- | --- |
| 緑 | **変更が発生**（リンク作成／コピー／MCP の追加・更新・書き込み、フォルダ新規作成） |
| グレー | 変更なし（`OK（同期済み）` / `OK（既存リンク）` / MCP `変更なし` など、すでに最新） |
| 黄 | 注意（実体フォルダが存在し `-Force` 未指定でスキップ など） |
| 濃い黄 | 対象なしでスキップ（`.github/skills` や `mcp.json` が無い等） |

### 主なオプション

- `-Force`: 参照先に既存のフォルダ/ファイル/リンクや MCP 定義があっても作り直す・上書きする。
- `-Symbolic`: ジャンクション/ハードリンクの代わりにシンボリックリンクを作る
  （管理者権限か開発者モードが必要）。

## 参考

- [Use Agent Skills with GitHub Copilot](https://learn.microsoft.com/visualstudio/ide/copilot-agent-skills?view=visualstudio#create-a-skill)
- [Customize GitHub Copilot modernization](https://learn.microsoft.com/dotnet/core/porting/github-copilot-app-modernization/customization#create-custom-skills)
