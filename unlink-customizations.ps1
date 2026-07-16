<#
.SYNOPSIS
  link-customizations.ps1 で作成したリンク／マージを解除する。
  スキル・カスタムエージェントのリンクを削除し、ユーザーの mcp.json から
  このワークスペースが定義した MCP サーバーキーを取り除く。

.DESCRIPTION
  - スキル: ~/.copilot/skills/<name> がこのリポジトリを指すリンク（ジャンクション/
    シンボリックリンク）の場合のみ削除する。実体フォルダは既定では削除しない（-Force で削除）。
  - エージェント: %APPDATA%\Code\User\prompts\*.agent.md のうち、このリポジトリの
    .github/agents/ に同名ファイルがあるものを対象とする。リンク（シンボリック/ハード）は
    既定で削除、コピー（実体ファイル）は -Force のときだけ削除する。
  - MCP サーバー: .vscode/mcp.json で定義したサーバーキーを、ユーザーの
    %APPDATA%\Code\User\mcp.json から削除する。この処理は既定では実行しない（link 前から
    存在した定義を誤って消さないため）。-IncludeMcp を指定したときだけ対象とし、
    既定は「値も一致するキー」だけ削除、-Force 併用時は同名なら値が違っても削除する。
    他のサーバー定義や inputs は維持する。※ユーザーの mcp.json は書き換え時に再整形され、
    コメントは失われる。

  link 側と対をなす操作。リポジトリ側（.github/、.vscode/mcp.json）はソースなので変更しない。

.PARAMETER Force
  実体フォルダ／コピーされたファイル、および値が一致しない同名 MCP キーも削除する。

.PARAMETER IncludeMcp
  ユーザーの mcp.json から、このワークスペースが定義した MCP サーバーキーを削除する。
  指定しない限り MCP は一切変更しない。

.EXAMPLE
  ./unlink-customizations.ps1
  ./unlink-customizations.ps1 -Force
  ./unlink-customizations.ps1 -IncludeMcp
  ./unlink-customizations.ps1 -IncludeMcp -Force
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$IncludeMcp
)

$ErrorActionPreference = 'Stop'

$repoSkills   = Join-Path $PSScriptRoot '.github\skills'
$repoAgents   = Join-Path $PSScriptRoot '.github\agents'
$repoMcp      = Join-Path $PSScriptRoot '.vscode\mcp.json'
$globalSkills = Join-Path $env:USERPROFILE '.copilot\skills'
$globalAgents = Join-Path $env:APPDATA 'Code\User\prompts'
$globalMcp    = Join-Path $env:APPDATA 'Code\User\mcp.json'

# ---- スキルのリンク解除（フォルダ単位） ----
if (Test-Path $repoSkills) {
    Write-Host "`n== スキル ==" -ForegroundColor Cyan
    Get-ChildItem -Path $repoSkills -Directory | ForEach-Object {
        $name   = $_.Name
        $source = $_.FullName
        $target = Join-Path $globalSkills $name

        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-Host "スキップ（対象なし）: $name" -ForegroundColor DarkGray
            return
        }

        $isLink = $null -ne $existing.LinkType
        if ($isLink) {
            # ジャンクション/シンボリックリンク: このリポジトリを指すものだけ外す
            if ($existing.Target -and ($existing.Target -ne $source) -and -not $Force) {
                Write-Host "警告（別ソースを指すリンク。-Force で削除）: $target -> $($existing.Target)" -ForegroundColor Yellow
                return
            }
            (Get-Item -LiteralPath $target).Delete()
            Write-Host "リンク削除: $name" -ForegroundColor Green
        } else {
            # 実体フォルダ: 既定では触らない
            if (-not $Force) {
                Write-Host "警告（実体フォルダが存在。-Force で削除）: $target" -ForegroundColor Yellow
                return
            }
            Remove-Item -LiteralPath $target -Recurse -Force
            Write-Host "フォルダ削除: $name" -ForegroundColor Green
        }
    }
} else {
    Write-Host ".github\skills フォルダが見つかりません（スキップ）: $repoSkills" -ForegroundColor DarkYellow
}

# ---- カスタムエージェントのリンク解除（ファイル単位） ----
if (Test-Path $repoAgents) {
    Write-Host "`n== エージェント ==" -ForegroundColor Cyan
    Get-ChildItem -Path $repoAgents -Filter '*.agent.md' -File | ForEach-Object {
        $name   = $_.Name
        $source = $_.FullName
        $target = Join-Path $globalAgents $name

        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-Host "スキップ（対象なし）: $name" -ForegroundColor DarkGray
            return
        }

        $isLink = $null -ne $existing.LinkType
        if ($isLink) {
            # シンボリックリンク/ハードリンク: link 側で作成したもの。削除する。
            # シンボリックリンクで別ソースを指す場合は -Force を要求。
            if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -and ($existing.Target -ne $source) -and -not $Force) {
                Write-Host "警告（別ソースを指すリンク。-Force で削除）: $target -> $($existing.Target)" -ForegroundColor Yellow
                return
            }
            Remove-Item -LiteralPath $target -Force
            Write-Host "リンク削除: $name  ($($existing.LinkType))" -ForegroundColor Green
        } else {
            # コピー（実体ファイル）: 既定では触らない
            if (-not $Force) {
                Write-Host "警告（実体ファイルが存在。-Force で削除）: $target" -ForegroundColor Yellow
                return
            }
            Remove-Item -LiteralPath $target -Force
            Write-Host "ファイル削除: $name" -ForegroundColor Green
        }
    }
} else {
    Write-Host ".github\agents フォルダが見つかりません（スキップ）: $repoAgents" -ForegroundColor DarkYellow
}

# ---- MCP サーバー定義の除去（JSON） ----
# 既定では実行しない。-IncludeMcp 指定時のみユーザー mcp.json からキーを削除する。
if (-not $IncludeMcp) {
    Write-Host "`n== MCP サーバー ==" -ForegroundColor Cyan
    Write-Host "スキップ（既定では MCP は変更しない。削除するには -IncludeMcp を指定）" -ForegroundColor DarkGray
} elseif (Test-Path $repoMcp) {
    Write-Host "`n== MCP サーバー ==" -ForegroundColor Cyan

    $srcMcp = Get-Content -LiteralPath $repoMcp -Raw | ConvertFrom-Json

    if (-not $srcMcp.PSObject.Properties['servers'] -or $null -eq $srcMcp.servers) {
        Write-Host "servers 定義が無いためスキップ: $repoMcp" -ForegroundColor DarkYellow
    } elseif (-not (Test-Path $globalMcp)) {
        Write-Host "ユーザーの mcp.json が無いためスキップ: $globalMcp" -ForegroundColor DarkGray
    } else {
        $dstMcp = Get-Content -LiteralPath $globalMcp -Raw | ConvertFrom-Json

        if (-not $dstMcp.PSObject.Properties['servers'] -or $null -eq $dstMcp.servers) {
            Write-Host "ユーザーの mcp.json に servers が無いためスキップ" -ForegroundColor DarkGray
        } else {
            $changed = $false
            foreach ($p in $srcMcp.servers.PSObject.Properties) {
                $name     = $p.Name
                $existing  = $dstMcp.servers.PSObject.Properties[$name]
                if (-not $existing) {
                    Write-Host "スキップ（対象なし）: $name" -ForegroundColor DarkGray
                    continue
                }

                # 値の一致判定（型と url を比較）。一致しなければ -Force を要求。
                $srcJson = $p.Value | ConvertTo-Json -Depth 32 -Compress
                $dstJson = $existing.Value | ConvertTo-Json -Depth 32 -Compress
                if ($srcJson -ne $dstJson -and -not $Force) {
                    Write-Host "警告（値が一致しない同名キー。-Force で削除）: $name" -ForegroundColor Yellow
                    continue
                }

                $dstMcp.servers.PSObject.Properties.Remove($name)
                Write-Host "削除: $name" -ForegroundColor Green
                $changed = $true
            }

            if ($changed) {
                ($dstMcp | ConvertTo-Json -Depth 32) | Set-Content -LiteralPath $globalMcp -Encoding UTF8
                Write-Host "書き込み: $globalMcp" -ForegroundColor Green
            } else {
                Write-Host "変更なし: $globalMcp" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host ".vscode\mcp.json が見つかりません（スキップ）: $repoMcp" -ForegroundColor DarkYellow
}

Write-Host "`n完了。VS Code を再読み込みしてください（Developer: Reload Window）。" -ForegroundColor Cyan
