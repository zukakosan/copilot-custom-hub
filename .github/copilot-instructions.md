---
applyTo: '**'
---
# このリポジトリでの作業ルール

このリポジトリは GitHub Copilot **Agent Skills** の置き場です。スキル本体は
`.github/skills/<skill-name>/SKILL.md` に置きます。

## 出力ファイルの配置

- スキルの動作確認・テストで生成する中間ファイルや成果物は、**必ず `output/` 配下に出力**すること。
- **リポジトリのルート直下にファイルを新規作成しない**こと（`README.md`・`.gitignore`・`link-skills.ps1` など既存の管理ファイルを除く）。
- `output/` は `.gitignore` 済み（git 管理外）。散らかしても commit されない。
- 恒久的に残したいもの（スキル本体・ドキュメント）だけを、適切なディレクトリ（`.github/skills/` 等）に置く。

## スキルの命名

- スキルのフォルダ名（= `SKILL.md` の `name`）は `<領域>-<対象>` のプレフィックス形式にする。
  例: `azure-storage`, `azure-functions`, `m365-teams`。
- `.github/skills/` はフラット構造。カテゴリ用の中間フォルダは作らない。
