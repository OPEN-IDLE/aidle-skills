<#
.SYNOPSIS
    aidle-skills 安装脚本（Windows / PowerShell）

.DESCRIPTION
    将 skills/ 下的 skill 安装到 Claude Code 和 / 或 Codex 的本地目录。

.PARAMETER Skill
    要安装的 skill 名。留空表示交互式选择。

.PARAMETER Target
    安装目标: all (默认) / claude / codex

.PARAMETER All
    安装全部 skill。

.PARAMETER List
    仅列出可用 skill。

.PARAMETER DryRun
    仅打印将执行的操作，不真正复制。

.EXAMPLE
    ./install/install.ps1 -All
    ./install/install.ps1 -Skill git-helper -Target claude
    ./install/install.ps1 -List

.NOTES
    环境变量 CLAUDE_SKILLS_DIR / CODEX_SKILLS_DIR 可覆盖默认安装路径。
#>

[CmdletBinding()]
param(
    [string]$Skill = "",
    [ValidateSet("all", "claude", "codex")]
    [string]$Target = "all",
    [switch]$All,
    [switch]$List,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# PowerShell 5.1 不支持 -CmdletBinding 之外的某些 PS 7 特性，但 install 流程本身 PS 5+ 即可。
# image-gen 的 generate.ps1 需要 PS 7+，这里只对低版本给出友好提示，不强制阻断。
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "❌ 需要 PowerShell 5+。当前: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SkillsDir = Join-Path $RepoRoot "skills"

# 记录仓库路径，供 aidle meta-skill 等定位使用
$AidleDir = Join-Path $HOME ".aidle"
if (-not (Test-Path $AidleDir)) { New-Item -ItemType Directory -Path $AidleDir -Force | Out-Null }
Set-Content -Path (Join-Path $AidleDir "repo") -Value $RepoRoot -Encoding UTF8

function Write-Info { param($Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Ok   { param($Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err  { param($Msg) Write-Host "[ERR]   $Msg" -ForegroundColor Red }

function Get-AvailableSkills {
    if (-not (Test-Path $SkillsDir)) { return @() }
    Get-ChildItem -Path $SkillsDir -Directory |
        Where-Object { $_.Name -notlike "_*" } |
        Select-Object -ExpandProperty Name |
        Sort-Object
}

function Get-SkillDescription {
    param([string]$Name)
    $md = Join-Path $SkillsDir "$Name/SKILL.md"
    if (-not (Test-Path $md)) { return "" }
    foreach ($line in (Get-Content $md -TotalCount 30)) {
        if ($line -match '^description:\s*(.*)$') {
            return $matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ""
}

function Format-Truncate {
    param([string]$Text, [int]$Max = 90)
    if (-not $Text) { return "" }
    if ($Text.Length -le $Max) { return $Text }
    return $Text.Substring(0, $Max - 1) + "…"
}

function Install-OneSkill {
    param([string]$Name, [string]$DestRoot)

    $src = Join-Path $SkillsDir $Name
    if (-not (Test-Path $src)) {
        Write-Err "skill 不存在: $Name"
        return
    }
    if (-not (Test-Path (Join-Path $src "SKILL.md"))) {
        Write-Err "skill 缺少 SKILL.md: $Name"
        return
    }

    $dest = Join-Path $DestRoot $Name
    if ($DryRun) {
        Write-Info "[dry-run] Copy $src -> $dest"
        return
    }

    if (-not (Test-Path $DestRoot)) {
        New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
    }
    if (Test-Path $dest) {
        Remove-Item -Recurse -Force $dest
    }
    Copy-Item -Recurse -Path $src -Destination $dest
}

if ($List) {
    Write-Info "可用 skill (来自 $SkillsDir):"
    foreach ($name in Get-AvailableSkills) {
        $desc = Format-Truncate -Text (Get-SkillDescription -Name $name) -Max 90
        Write-Host ("  {0,-15} {1}" -f $name, $desc) -ForegroundColor Green
    }
    exit 0
}

# 决定要安装的 skill 列表
$ToInstall = @()
if ($Skill) {
    $ToInstall = @($Skill)
} elseif ($All) {
    $ToInstall = Get-AvailableSkills
} else {
    Write-Info "可用 skill:"
    Get-AvailableSkills | ForEach-Object { Write-Host "  - $_" }
    $input = Read-Host "请输入 skill 名（多个用空格分隔，留空安装全部）"
    if ([string]::IsNullOrWhiteSpace($input)) {
        $ToInstall = Get-AvailableSkills
    } else {
        $ToInstall = $input -split '\s+'
    }
}

if ($ToInstall.Count -eq 0) {
    Write-Warn "没有要安装的 skill，退出。"
    exit 0
}

# 决定目标目录
$ClaudeDir = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $HOME ".claude/skills" }
$CodexDir  = if ($env:CODEX_SKILLS_DIR)  { $env:CODEX_SKILLS_DIR }  else { Join-Path $HOME ".codex/skills" }

$Targets = switch ($Target) {
    "all"    { @(@{Name="claude"; Dir=$ClaudeDir}, @{Name="codex"; Dir=$CodexDir}) }
    "claude" { @(@{Name="claude"; Dir=$ClaudeDir}) }
    "codex"  { @(@{Name="codex"; Dir=$CodexDir}) }
}

foreach ($name in $ToInstall) {
    if ($name -eq "_template") {
        Write-Warn "跳过模板: $name"
        continue
    }
    foreach ($t in $Targets) {
        Install-OneSkill -Name $name -DestRoot $t.Dir
        Write-Ok "[$($t.Name)] $name -> $(Join-Path $t.Dir $name)"
    }
}

Write-Ok "安装完成。"
