#Requires -Version 5.1
<#
.SYNOPSIS
    PaperForge — 安裝 Claude Code Skills（掃描 profiles/*/skill/ 與 skill/*/ 兩個來源）

.DESCRIPTION
    預設安裝所有 skill：
      - profiles/<name>/skill/SKILL.md（論文 profile 自帶的 skill，例：thesis-ncu profile 的 ncu-paper-writer）
      - skill/<name>/SKILL.md（不屬於任何 profile 的 skill，例：ncu-slides-writer）
    安裝目錄名稱沿用 SKILL.md frontmatter 的 name 欄位（由 skill 作者決定，PaperForge 不強制命名）。

.PARAMETER User
    安裝到 ~\.claude\skills\（預設，跨專案共用）

.PARAMETER Project
    安裝到 .\.claude\skills\（僅當前專案）

.PARAMETER Force
    已存在則直接覆蓋（不備份）

.PARAMETER Only
    僅安裝指定 skill name（依 SKILL.md frontmatter 比對）。
    例：-Only ncu-paper-writer 或 -Only ncu-slides-writer

.EXAMPLE
    .\scripts\install-skill.ps1

.EXAMPLE
    .\scripts\install-skill.ps1 -Project

.EXAMPLE
    .\scripts\install-skill.ps1 -Only ncu-slides-writer -Force
#>

[CmdletBinding(DefaultParameterSetName = "User")]
param(
    [Parameter(ParameterSetName = "User")]
    [switch]$User,

    [Parameter(ParameterSetName = "Project")]
    [switch]$Project,

    [switch]$Force,

    [string]$Only = ""
)

$ErrorActionPreference = "Stop"

function Write-Info     { param([string]$m) Write-Host "[INFO]  " -ForegroundColor Cyan -NoNewline; Write-Host $m }
function Write-Ok       { param([string]$m) Write-Host "[OK]    " -ForegroundColor Green -NoNewline; Write-Host $m }
function Write-WarnMsg  { param([string]$m) Write-Host "[WARN]  " -ForegroundColor Yellow -NoNewline; Write-Host $m }
function Write-Fail     { param([string]$m) Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $m }

$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = Split-Path -Parent $ScriptDir

$Scope = if ($Project) { "project" } else { "user" }
if ($Scope -eq "user") {
    $TargetBase = Join-Path $env:USERPROFILE ".claude\skills"
} else {
    $TargetBase = Join-Path (Get-Location) ".claude\skills"
}

Write-Info "目標：$TargetBase (scope=$Scope)"

# 從 SKILL.md frontmatter 讀取 name 欄位（決定安裝目錄名稱）
# 只認 --- 包住的 frontmatter（與 build.ps1 的 Read-YamlProfile 同款），
# 避免誤讀正文中以 name: 開頭的行；同時去註解與單雙引號。
function Get-SkillName {
    param([string]$SkillMd)
    $sawStart = $false
    $inFm = $false
    foreach ($line in Get-Content -LiteralPath $SkillMd -Encoding UTF8) {
        if ($line -match '^---\s*$') {
            if (-not $sawStart) { $sawStart = $true; $inFm = $true; continue }
            else { break }
        }
        if ($inFm -and $line -match '^name\s*:\s*(.+?)\s*$') {
            $val = $Matches[1]
            $val = $val -replace '\s+#.*$', ''
            $val = $val -replace '^[''"]|[''"]$', ''
            return $val.Trim()
        }
    }
    return $null
}

function Install-OneSkill {
    param(
        [string]$SourceDir
    )

    $skillMd = Join-Path $SourceDir "SKILL.md"
    if (-not (Test-Path $skillMd)) {
        Write-WarnMsg "$SourceDir 缺少 SKILL.md，跳過"
        return $null
    }

    $skillName = Get-SkillName -SkillMd $skillMd
    if (-not $skillName) {
        Write-WarnMsg "$skillMd 無法讀取 frontmatter 的 name 欄位，跳過"
        return $null
    }

    if ($Only -and $skillName -ne $Only) {
        return $null
    }

    $targetDir = Join-Path $TargetBase $skillName

    if (Test-Path $targetDir) {
        if ($Force) {
            Write-WarnMsg "$skillName 已存在，強制覆蓋"
            Remove-Item $targetDir -Recurse -Force
        } else {
            $ts = Get-Date -Format "yyyyMMdd-HHmmss"
            $backupDir = "${targetDir}.bak.${ts}"
            Write-WarnMsg "$skillName 已存在，備份至：$backupDir"
            Move-Item $targetDir $backupDir
        }
    }

    if (-not (Test-Path $TargetBase)) {
        New-Item -ItemType Directory -Path $TargetBase -Force | Out-Null
    }
    Copy-Item -Path $SourceDir -Destination $targetDir -Recurse -Force

    if (Test-Path (Join-Path $targetDir "SKILL.md")) {
        Write-Ok "$skillName 安裝成功（來源：$SourceDir）"
        return $skillName
    } else {
        Write-Fail "$skillName 安裝失敗"
        return $null
    }
}

# 收集所有 skill 來源目錄：profiles/*/skill/ 與 skill/*/
$sources = @()

$profilesDir = Join-Path $RepoRoot "profiles"
if (Test-Path $profilesDir) {
    Get-ChildItem -Path $profilesDir -Directory | ForEach-Object {
        $skillDir = Join-Path $_.FullName "skill"
        if (Test-Path $skillDir) { $sources += $skillDir }
    }
}

$topSkillDir = Join-Path $RepoRoot "skill"
if (Test-Path $topSkillDir) {
    Get-ChildItem -Path $topSkillDir -Directory | ForEach-Object {
        $sources += $_.FullName
    }
}

if ($sources.Count -eq 0) {
    Write-Fail "找不到任何 skill 來源（profiles/*/skill/ 或 skill/*/）"
    exit 1
}

$installed = 0
foreach ($src in $sources) {
    $result = Install-OneSkill -SourceDir $src
    if ($result) { $installed++ }
}

if ($installed -eq 0) {
    if ($Only) {
        Write-Fail "找不到 skill：$Only"
    } else {
        Write-Fail "沒有任何 skill 被安裝"
    }
    exit 1
}

Write-Info "在 Claude Code 中執行任務時將自動載入這些 skill"
if ($Scope -eq "user") {
    Write-Info "（跨專案可用，目前安裝在使用者層級）"
} else {
    Write-Info "（僅當前專案可用）"
}
