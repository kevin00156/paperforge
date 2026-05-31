#Requires -Version 5.1
<#
.SYNOPSIS
    PaperForge Windows 一鍵安裝腳本

.DESCRIPTION
    安裝以下項目：
      1. Pandoc
      2. MiKTeX (含 XeLaTeX + xeCJK + biber)
      3. CJK 字體檢查（標楷體為 Windows 內建）
      4. Python + uv（可選）
      5. Claude Code Skills（各 profile 內附，例：~\.claude\skills\ncu-paper-writer\）
      6. 編譯測試（examples\minimal）

.PARAMETER DryRun
    僅顯示將執行的指令，不實際安裝

.PARAMETER SkipTex
    跳過 MiKTeX 安裝

.PARAMETER SkipPython
    跳過 Python 環境設置

.PARAMETER SkipSkill
    跳過 Skill 安裝

.PARAMETER SkipTest
    跳過編譯測試

.PARAMETER SkillOnly
    僅安裝 Skill

.EXAMPLE
    .\scripts\install.ps1

.EXAMPLE
    .\scripts\install.ps1 -SkipTex -SkillOnly
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipTex,
    [switch]$SkipPython,
    [switch]$SkipSkill,
    [switch]$SkipTest,
    [switch]$SkillOnly
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $PSCommandPath
$ProjectRoot = Split-Path -Parent $ScriptDir
$InstallLog = Join-Path (Get-Location) "install.log"

if ($SkillOnly) {
    $SkipTex = $true
    $SkipPython = $true
    $SkipTest = $true
}

# --- 報告陣列 ---
$Report = @()

function Write-Info  { param([string]$m) Write-Host "[INFO]    " -ForegroundColor Cyan -NoNewline; Write-Host $m }
function Write-Step  { param([string]$m) Write-Host "`n===> $m" -ForegroundColor Cyan }
function Write-Pass  { param([string]$m) Write-Host "[PASS]    " -ForegroundColor Green -NoNewline; Write-Host $m }
function Write-WarnMsg { param([string]$m) Write-Host "[WARN]    " -ForegroundColor Yellow -NoNewline; Write-Host $m }
function Write-Fail  { param([string]$m) Write-Host "[FAIL]    " -ForegroundColor Red -NoNewline; Write-Host $m }

function Add-Report {
    param([string]$Status, [string]$Label)
    $script:Report += [PSCustomObject]@{ Status = $Status; Label = $Label }
    switch ($Status) {
        "PASS" { Write-Pass $Label }
        "WARN" { Write-WarnMsg $Label }
        "FAIL" { Write-Fail $Label }
    }
}

function Invoke-Run {
    param([string]$Cmd, [string[]]$ArgList)
    if ($DryRun) {
        Write-Host "[DRY-RUN] $Cmd $($ArgList -join ' ')" -ForegroundColor Yellow
        return $true
    }
    Write-Info "執行：$Cmd $($ArgList -join ' ')"
    & $Cmd @ArgList
    return ($LASTEXITCODE -eq 0)
}

# PowerShell 5.1 會把 native exe 的 stderr 包成 NativeCommandError，
# 配合 $ErrorActionPreference = "Stop" 會中斷腳本（即使 exit code = 0）。
# 呼叫 native command 時改用此 helper，與 scripts\build.ps1 一致。
function Invoke-Native {
    param([string]$Cmd, [string[]]$ArgList)
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Cmd @ArgList 2>&1 | Out-Null
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevPref
    }
}

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# --- 開頭橫幅 ---
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║          PaperForge 安裝腳本 (Windows)                       ║
╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

if ($DryRun) {
    Write-WarnMsg "DRY-RUN 模式，僅顯示將執行的指令"
}

# --- winget 存在性檢查 ---
if (-not (Test-Command "winget")) {
    Write-Fail "找不到 winget。請從 Microsoft Store 安裝「應用程式安裝程式」(App Installer)。"
    exit 1
}

# ============================================================
# Step 1: Pandoc
# ============================================================
function Install-PandocStep {
    Write-Step "Step 1/6: 安裝 Pandoc"
    if (Test-Command "pandoc") {
        $version = (pandoc --version)[0]
        Add-Report "PASS" "Pandoc 已安裝：$version"
        return
    }
    if (Invoke-Run "winget" @("install", "--id", "JohnMacFarlane.Pandoc", "-e", "--silent", "--accept-package-agreements", "--accept-source-agreements")) {
        # 重新整理 PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (Test-Command "pandoc") {
            Add-Report "PASS" "Pandoc 安裝成功"
        } else {
            Add-Report "WARN" "Pandoc 已透過 winget 安裝，請重啟終端後再次驗證"
        }
    } else {
        Add-Report "FAIL" "Pandoc 安裝失敗，請手動從 https://pandoc.org/installing.html 下載"
    }
}

# ============================================================
# Step 2: MiKTeX
# ============================================================
function Install-MiKTeXStep {
    Write-Step "Step 2/6: 安裝 MiKTeX"
    if ($SkipTex) {
        Add-Report "WARN" "已跳過 MiKTeX 安裝（-SkipTex）"
        return
    }
    if ((Test-Command "xelatex") -and (Test-Command "biber")) {
        Add-Report "PASS" "MiKTeX 已安裝（xelatex + biber 可用）"
        return
    }

    Write-WarnMsg "MiKTeX 安裝會下載基本套件並按需擴展，預計需要 5-15 分鐘"

    if (-not (Invoke-Run "winget" @("install", "--id", "MiKTeX.MiKTeX", "-e", "--silent", "--accept-package-agreements", "--accept-source-agreements"))) {
        Add-Report "FAIL" "MiKTeX 安裝失敗，請手動從 https://miktex.org/download 下載"
        return
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # 啟用自動安裝缺套件
    if (Test-Command "initexmf") {
        Write-Info "啟用 MiKTeX 自動安裝缺套件"
        if (-not $DryRun) {
            $null = Invoke-Native -Cmd "initexmf" -ArgList @("--set-config-value", "[MPM]AutoInstall=1")
        }

        Write-Info "預先安裝必要的 LaTeX 套件（可能需要數分鐘）"
        $packages = @("xetex", "xecjk", "fontspec", "subfig", "subfigure",
                      "titlesec", "fancyhdr", "biblatex", "biblatex-ieee",
                      "biber", "etoolbox", "fp", "ragged2e", "indentfirst",
                      "makecell", "colortbl", "multirow")
        if (-not $DryRun) {
            foreach ($pkg in $packages) {
                Write-Host "  安裝套件：$pkg" -ForegroundColor Gray
                $null = Invoke-Native -Cmd "mpm" -ArgList @("install", $pkg)
            }
        } else {
            Write-Host "[DRY-RUN] 將安裝 MiKTeX 套件：$($packages -join ', ')" -ForegroundColor Yellow
        }
    }

    if (Test-Command "xelatex") {
        Add-Report "PASS" "MiKTeX 安裝成功"
    } else {
        Add-Report "WARN" "MiKTeX 已安裝但需要重啟終端才能使用"
    }
}

# ============================================================
# Step 3: 字體檢查
# ============================================================
function Test-Fonts {
    Write-Step "Step 3/6: 檢查 CJK 字體"

    $fontsDir = "$env:WINDIR\Fonts"
    $hasKai = $false
    $hasMing = $false

    # 標楷體：DFKai-SB.ttf 或 kaiu.ttf
    if ((Test-Path "$fontsDir\kaiu.ttf") -or (Test-Path "$fontsDir\DFKai-SB.ttf")) {
        $hasKai = $true
    }
    # 細明體
    if ((Test-Path "$fontsDir\mingliu.ttc") -or (Test-Path "$fontsDir\PMingLiU.ttf")) {
        $hasMing = $true
    }

    if ($hasKai) {
        Add-Report "PASS" "已安裝標楷體（符合 NCU 嚴格規範）"
    } elseif ($hasMing) {
        Add-Report "WARN" "未偵測到標楷體，但有細明體可用作 fallback"
    } else {
        Add-Report "WARN" "未偵測到標楷體。Windows 通常內建，請檢查 C:\Windows\Fonts\kaiu.ttf"
    }
}

# ============================================================
# Step 4: Python + uv
# ============================================================
function Install-PythonStep {
    Write-Step "Step 4/6: 設置 Python 環境"
    if ($SkipPython) {
        Add-Report "WARN" "已跳過 Python 環境設置（-SkipPython）"
        return
    }

    if (-not (Test-Command "python")) {
        Invoke-Run "winget" @("install", "--id", "Python.Python.3.12", "-e", "--silent") | Out-Null
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }

    if (-not (Test-Command "uv")) {
        Write-Info "安裝 uv（Python 套件管理工具）"
        if (-not $DryRun) {
            $installResult = Invoke-Run "winget" @("install", "--id", "astral-sh.uv", "-e", "--silent")
            if (-not $installResult) {
                Write-Info "winget 失敗，嘗試 PowerShell installer"
                if (-not $DryRun) {
                    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
                }
            }
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }

    if (Test-Command "uv") {
        $uvVersion = & uv --version
        Add-Report "PASS" "uv 可用：$uvVersion"
    } elseif (Test-Command "python") {
        Add-Report "WARN" "uv 安裝失敗，但 Python 可用，可改用 pip"
    } else {
        Add-Report "FAIL" "Python 與 uv 都無法安裝"
    }
}

# ============================================================
# Step 5: Skill 安裝
# ============================================================
function Install-SkillStep {
    Write-Step "Step 5/6: 安裝 Claude Code Skill"
    if ($SkipSkill) {
        Add-Report "WARN" "已跳過 Skill 安裝（-SkipSkill）"
        return
    }

    $skillScript = Join-Path $ScriptDir "install-skill.ps1"
    if (-not (Test-Path $skillScript)) {
        Add-Report "FAIL" "找不到 install-skill.ps1"
        return
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] & '$skillScript'" -ForegroundColor Yellow
        return
    }

    try {
        & $skillScript
        Add-Report "PASS" "Skill 安裝成功"
    } catch {
        Add-Report "FAIL" "Skill 安裝失敗：$_"
    }
}

# ============================================================
# Step 6: 編譯測試
# ============================================================
function Test-Build {
    Write-Step "Step 6/6: 編譯測試（examples\minimal）"
    if ($SkipTest) {
        Add-Report "WARN" "已跳過編譯測試（-SkipTest）"
        return
    }

    $buildScript = Join-Path $ProjectRoot "scripts\build.ps1"
    $minimalMd = Join-Path $ProjectRoot "examples\minimal\paper.md"

    if (-not (Test-Path $minimalMd)) {
        Add-Report "WARN" "找不到 examples\minimal\paper.md，跳過測試"
        return
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] & '$buildScript' '$minimalMd'" -ForegroundColor Yellow
        return
    }

    try {
        & $buildScript $minimalMd
        $pdfPath = Join-Path $ProjectRoot "examples\minimal\paper.pdf"
        if (Test-Path $pdfPath) {
            $pdfInfo = Get-Item $pdfPath
            if ($pdfInfo.Length -gt 10240) {
                Add-Report "PASS" "編譯測試成功：$($pdfInfo.FullName) ($($pdfInfo.Length) bytes)"
            } else {
                Add-Report "WARN" "PDF 產生但檔案過小（$($pdfInfo.Length) bytes）"
            }
        } else {
            Add-Report "FAIL" "編譯返回成功但找不到 PDF"
        }
    } catch {
        Add-Report "FAIL" "編譯測試失敗：$_"
    }
}

# ============================================================
# 主流程
# ============================================================
Install-PandocStep
Install-MiKTeXStep
Test-Fonts
Install-PythonStep
Install-SkillStep
Test-Build

# ============================================================
# 報告
# ============================================================
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                        安裝報告                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$passCount = ($Report | Where-Object Status -eq "PASS").Count
$warnCount = ($Report | Where-Object Status -eq "WARN").Count
$failCount = ($Report | Where-Object Status -eq "FAIL").Count

foreach ($r in $Report) {
    switch ($r.Status) {
        "PASS" { Write-Host "  ✓ " -ForegroundColor Green -NoNewline; Write-Host $r.Label }
        "WARN" { Write-Host "  ! " -ForegroundColor Yellow -NoNewline; Write-Host $r.Label }
        "FAIL" { Write-Host "  ✗ " -ForegroundColor Red -NoNewline; Write-Host $r.Label }
    }
}

Write-Host ""
Write-Host "通過: " -NoNewline
Write-Host "$passCount" -ForegroundColor Green -NoNewline
Write-Host "   警告: " -NoNewline
Write-Host "$warnCount" -ForegroundColor Yellow -NoNewline
Write-Host "   失敗: " -NoNewline
Write-Host "$failCount" -ForegroundColor Red

Write-Host ""

if ($failCount -gt 0) {
    Write-Host "安裝過程有失敗項目，請檢視上方訊息。" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 安裝完成！" -ForegroundColor Green
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 複製骨架（選一個 profile，論文或簡報皆可）："
# 動態枚舉 profiles/*/profile.yaml，新增 profile 自動出現，無需維護清單。
Get-ChildItem (Join-Path $ProjectRoot "profiles") -Directory | ForEach-Object {
    $yaml = Join-Path $_.FullName "profile.yaml"
    $skel = Join-Path $_.FullName "skeleton"
    if ((Test-Path $yaml) -and (Test-Path $skel)) {
        $desc = ""
        $lines = Get-Content -Path $yaml
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^description\s*:\s*(.*)$') {
                $v = $Matches[1].Trim().Trim('"').Trim("'")
                if ($v -eq '|' -or $v -eq '>' -or $v -eq '') {
                    if ($i + 1 -lt $lines.Count) { $desc = $lines[$i + 1].Trim().Trim('"').Trim("'") }
                } else { $desc = $v }
                break
            }
        }
        Write-Host ("       Copy-Item -Recurse profiles\{0}\skeleton my-work    # {1}" -f $_.Name, $desc)
    }
}
Write-Host "     （完整清單與細節：.\scripts\build.ps1 --list-profiles）"
Write-Host "  2. 編輯 my-work\paper.md（簡報為 slides.md）的 YAML metadata"
Write-Host "  3. 設置 Zotero：見 docs\03-zotero-setup.md"
Write-Host "  4. 編譯：.\scripts\build.ps1 my-work\paper.md --profile <name>"
Write-Host "       （簡報改用 .\scripts\build-slides.ps1 my-work\slides.md --profile <name>）"
