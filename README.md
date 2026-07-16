# ws-skills-inventory-zukako

個人用の GitHub Copilot **Agent Skills** 置き場（git 管理）。

`.github/skills/` 配下の各フォルダ（`SKILL.md` を含む）が 1 つのスキルです。

- **このリポジトリを開いているとき**は、`.github/skills/` が自動で認識されます（clone 直後・別 PC でもそのまま動く）。
- **他のワークスペースからも使いたいとき**は、`link-skills.ps1` で `~/.copilot/skills/` へリンクします。

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
   ./link-skills.ps1
   ```

3. VS Code を再読み込み（コマンドパレット → *Developer: Reload Window*）。

> リンクは各マシンローカルの設定なので git には含まれません。別 PC で clone した場合は
> B を使うときだけ `./link-skills.ps1` を一度実行してください（A のみなら不要）。

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
5. 全 WS で使うなら `./link-skills.ps1` を実行してグローバルへ昇格。

> `output/` は「テスト成果物・スクラッチ専用」。スキル本体は置かない。
> リポジトリのルート直下には成果物ファイルを置かず、必ず `output/` 配下に出力する
> （[.github/copilot-instructions.md](.github/copilot-instructions.md) で指示）。

## 新しいスキルの追加

1. `.github/skills/<kebab-case-name>/SKILL.md` を作成（下記フォーマット）。
2. 全 WS で使うなら `./link-skills.ps1` を再実行（新規分だけリンクされます）。
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
├── link-skills.ps1              # .github/skills/* を ~/.copilot/skills/ へリンク
├── output/                      # 開発中のテスト成果物・スクラッチ（git 管理外）
└── .github/
    ├── copilot-instructions.md  # ルート直置き禁止など、このリポの作業ルール
    └── skills/
        └── <skill-name>/
            └── SKILL.md         # 必須: メタデータ + 手順
```

## 参考

- [Use Agent Skills with GitHub Copilot](https://learn.microsoft.com/visualstudio/ide/copilot-agent-skills?view=visualstudio#create-a-skill)
- [Customize GitHub Copilot modernization](https://learn.microsoft.com/dotnet/core/porting/github-copilot-app-modernization/customization#create-custom-skills)
