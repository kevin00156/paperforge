#Requires -Version 5.1
<#
.SYNOPSIS
    PaperForge 跨平台編譯腳本 (Windows PowerShell)

.DESCRIPTION
    將 Markdown 編譯成 PDF。會根據檔名自動分派：
      - paper.md  → Pandoc + XeLaTeX 論文流程
      - slides.md → 委派給 build-slides.ps1 (Marp)
      - 其他檔名 → 互動式詢問模式
    論文流程：Pandoc → LaTeX → biber → LaTeX × 2

.PARAMETER InputFile
    輸入的 Markdown 檔案路徑。若未指定，會依當前目錄存在的
    paper.md / slides.md 自動偵測；兩者皆存在時會互動式詢問。

.PARAMETER Output
    輸出目錄。預設為原檔目錄。

.PARAMETER Watch
    監看模式：偵測檔案變動自動重編。

.PARAMETER Clean
    清理中間檔（不編譯）。

.PARAMETER NoBib
    跳過 biber 步驟。

.PARAMETER KeepTex
    保留 .tex 中間檔。

.PARAMETER Engine
    PDF 引擎。預設 xelatex。

.PARAMETER ProfileName
    Profile 名稱。優先序：CLI 旗標 > 輸入檔 YAML 的 profile: 欄位 >
    預設 thesis-ncu。對應 profiles/<name>/。
    例：thesis-ncu、journal-ieee（未來新增）。

.PARAMETER Template
    Pandoc LaTeX 模板路徑。若指定則覆寫 -ProfileName 推導出的模板路徑。

.PARAMETER BibStyle
    biblatex 樣式名稱。預設 ieee。

.PARAMETER MainFont
    覆寫西文主字體（-V mainfont，優先於輸入檔 YAML）。

.PARAMETER CjkFont
    覆寫中文主字體（-V CJKmainfont，優先於輸入檔 YAML）。
    用途：無標楷體的環境可改用免費楷體（如 "AR PL UKai TW"）。

.PARAMETER ListProfiles
    列出目前可用的 profile（讀 profiles\*\profile.yaml）後結束，不需輸入檔。

.PARAMETER Verbose
    詳細輸出。

.EXAMPLE
    .\scripts\build.ps1 paper.md

.EXAMPLE
    .\scripts\build.ps1 examples\minimal\paper.md --Verbose

.EXAMPLE
    .\scripts\build.ps1 -Watch
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$InputFile = "",

    [string]$Output = "",
    [switch]$Watch,
    [switch]$Clean,
    [switch]$NoBib,
    [switch]$KeepTex,
    [switch]$NoLint,
    [switch]$LintStrict,

    [ValidateSet("xelatex", "lualatex")]
    [string]$Engine = "xelatex",

    [Alias("Profile")]
    [string]$ProfileName = "thesis-ncu",

    [string]$Template = "",
    [string]$BibStyle = "ieee",
    [string]$MainFont = "",
    [string]$CjkFont = "",
    [switch]$ListProfiles
)

# --- 顏色輸出 ---
function Write-Info  { param([string]$Message) Write-Host "[INFO]  " -ForegroundColor Cyan -NoNewline; Write-Host $Message }
function Write-Ok    { param([string]$Message) Write-Host "[OK]    " -ForegroundColor Green -NoNewline; Write-Host $Message }
function Write-WarnMsg { param([string]$Message) Write-Host "[WARN]  " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
function Write-ErrorMsg { param([string]$Message) Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $Message }

# PowerShell 5.1 會把 native exe 的 stderr 包成 ErrorRecord，當 $ErrorActionPreference="Stop" 時會中斷
# 我們改用 Continue 並透過 $LASTEXITCODE 檢查 native command 結果
$ErrorActionPreference = "Continue"

# 呼叫 native command 並回傳 exit code，吞掉 stderr 避免 PowerShell 5.1 的 NativeCommandError 問題
function Invoke-Native {
    param(
        [string]$Cmd,
        [string[]]$ArgList,
        [switch]$ShowOutput
    )
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if ($ShowOutput) {
            & $Cmd @ArgList 2>&1 | ForEach-Object { Write-Host $_ }
        } else {
            & $Cmd @ArgList 2>&1 | Out-Null
        }
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevPref
    }
}

$ScriptDir = Split-Path -Parent $PSCommandPath
$RepoRoot = Split-Path -Parent $ScriptDir

# --- 列出 profiles\*\profile.yaml 的 name / type / style / description ---
# 動態枚舉，新增 profile 自動出現，無需維護清單。
function Show-ProfileList {
    Write-Host "PaperForge — 可用 profile（profiles\<name>\）：`n"
    Write-Host ("  {0,-26} {1,-8} {2,-10} {3}" -f "NAME", "TYPE", "STYLE", "DESCRIPTION")
    $found = 0
    foreach ($yaml in Get-ChildItem -Path (Join-Path $RepoRoot "profiles") -Filter "profile.yaml" -Recurse -ErrorAction SilentlyContinue) {
        $found++
        $name = ""; $type = ""; $style = ""; $desc = ""; $want = $false
        foreach ($line in Get-Content -LiteralPath $yaml.FullName -Encoding UTF8) {
            if ($want -and -not $desc) {
                $desc = $line.Trim() -replace '^[''"]|[''"]$', ''
                $want = $false
                continue
            }
            if ($line -match '^name\s*:\s*(.*)$')  { $name  = $Matches[1].Trim() -replace '^[''"]|[''"]$', ''; continue }
            if ($line -match '^type\s*:\s*(.*)$')  { $type  = $Matches[1].Trim() -replace '^[''"]|[''"]$', ''; continue }
            if ($line -match '^style\s*:\s*(.*)$') { $style = $Matches[1].Trim() -replace '^[''"]|[''"]$', ''; continue }
            if ($line -match '^description\s*:\s*(.*)$') {
                $v = $Matches[1].Trim()
                if ($v -eq "|" -or $v -eq ">" -or $v -eq "") { $want = $true }
                else { $desc = $v -replace '^[''"]|[''"]$', '' }
            }
        }
        Write-Host ("  {0,-26} {1,-8} {2,-10} {3}" -f $name, $type, $style, $desc)
    }
    if ($found -eq 0) {
        Write-ErrorMsg "找不到任何 profiles\*\profile.yaml"
        return $false
    }
    Write-Host "`n用法：在 paper.md / slides.md 開頭 YAML 寫 profile: <NAME>，或編譯時帶 -ProfileName <NAME>。"
    return $true
}

if ($ListProfiles) {
    if (Show-ProfileList) { exit 0 } else { exit 1 }
}

# 是否由 CLI 顯式指定 -ProfileName（用 -Profile 別名也算）
$ProfileFromCli = $PSBoundParameters.ContainsKey('ProfileName')

# --- 讀取 Markdown 檔開頭 YAML frontmatter 的 profile: 欄位 ---
# 若沒有 frontmatter 或 profile 欄位則回傳空字串
function Read-YamlProfile {
    param([string]$File)
    if (-not (Test-Path $File)) { return "" }
    $sawStart = $false
    $inFm = $false
    foreach ($line in Get-Content -LiteralPath $File -Encoding UTF8) {
        if ($line -match '^---\s*$') {
            if (-not $sawStart) {
                $sawStart = $true
                $inFm = $true
                continue
            } else {
                break
            }
        }
        if ($inFm -and $line -match '^profile\s*:\s*(.+?)\s*$') {
            $val = $Matches[1]
            $val = $val -replace '\s+#.*$', ''
            $val = $val -replace '^[''"]|[''"]$', ''
            return $val.Trim()
        }
    }
    return ""
}

# --- 自動偵測：根據檔名分派至 paper 或 slides 編譯流程 ---
function Get-BuildMode {
    param([string]$File)
    if ($File) {
        $name = [System.IO.Path]::GetFileName($File).ToLower()
        if ($name -eq "paper.md")  { return "paper" }
        if ($name -eq "slides.md") { return "slides" }
        return "unknown"
    }
    $hasPaper  = Test-Path "paper.md"
    $hasSlides = Test-Path "slides.md"
    if ($hasPaper  -and -not $hasSlides) { return "paper" }
    if ($hasSlides -and -not $hasPaper)  { return "slides" }
    if ($hasPaper  -and $hasSlides)      { return "both" }
    return "none"
}

function Read-BuildMode {
    param([string]$Prompt = "請選擇編譯模式")
    Write-Host ""
    Write-Host "  [P] 論文 (Pandoc + XeLaTeX)" -ForegroundColor Cyan
    Write-Host "  [S] 簡報 (Marp)" -ForegroundColor Cyan
    while ($true) {
        $ans = Read-Host "$Prompt (P/S)"
        if ($null -ne $ans) {
            switch ($ans.Trim().ToUpper()) {
                "P" { return "paper" }
                "S" { return "slides" }
            }
        }
        Write-WarnMsg "請輸入 P 或 S"
    }
}

$BuildMode = Get-BuildMode -File $InputFile

if ($BuildMode -eq "none") {
    Write-ErrorMsg "未指定輸入檔案，且當前目錄無 paper.md 或 slides.md"
    Get-Help $PSCommandPath -Full | Out-String | Write-Host
    exit 1
}

if ($BuildMode -eq "unknown") {
    Write-Info "檔案 '$InputFile' 不是 paper.md 也不是 slides.md"
    $BuildMode = Read-BuildMode
} elseif ($BuildMode -eq "both") {
    Write-Info "當前目錄同時有 paper.md 與 slides.md"
    $BuildMode = Read-BuildMode "請選擇要編譯哪一個"
    if (-not $InputFile) {
        if ($BuildMode -eq "paper")  { $InputFile = "paper.md" }
        if ($BuildMode -eq "slides") { $InputFile = "slides.md" }
    }
}

# 自動補上預設檔名（若使用者沒給檔但 cwd 有對應檔）
if (-not $InputFile) {
    if ($BuildMode -eq "paper")  { $InputFile = "paper.md" }
    if ($BuildMode -eq "slides") { $InputFile = "slides.md" }
}

# 簡報模式 → 委派給 build-slides.ps1
if ($BuildMode -eq "slides") {
    Write-Info "偵測為簡報模式 → 委派給 build-slides.ps1"
    $slidesScript = Join-Path $ScriptDir "build-slides.ps1"
    if (-not (Test-Path $slidesScript)) {
        Write-ErrorMsg "找不到 build-slides.ps1：$slidesScript"
        exit 1
    }
    $passArgs = @()
    if ($InputFile) { $passArgs += $InputFile }
    if ($PSBoundParameters.ContainsKey('Output')) { $passArgs += @("-Output", $Output) }
    if ($Watch) { $passArgs += "-Watch" }
    if ($ProfileFromCli) { $passArgs += @("-ProfileName", $ProfileName) }
    & $slidesScript @passArgs
    exit $LASTEXITCODE
}

# --- 以下為 paper 模式 ---

# 若 CLI 沒指定 -ProfileName，嘗試從輸入檔的 YAML frontmatter 讀 profile: 欄位
if (-not $ProfileFromCli -and $InputFile -and (Test-Path $InputFile)) {
    $yamlProfile = Read-YamlProfile -File $InputFile
    if ($yamlProfile) {
        $ProfileName = $yamlProfile
        Write-Info "從 YAML frontmatter 偵測到 profile：$ProfileName"
    }
}

# --- 模板與 CSL 路徑（由 profile 推導，可被 -Template 覆寫） ---
$ProfileDir = Join-Path $RepoRoot "profiles\$ProfileName"
if (-not (Test-Path $ProfileDir)) {
    Write-ErrorMsg "找不到 profile：$ProfileName（預期目錄：$ProfileDir）"
    exit 1
}
if (-not $Template) {
    $Template = Join-Path $ProfileDir "template.latex"
}
$CslPath = Join-Path $RepoRoot "shared\cites\ieee.csl"

if (-not (Test-Path $InputFile)) {
    Write-ErrorMsg "找不到輸入檔案：$InputFile"
    exit 1
}

# --- 路徑解析 ---
$InputAbs = (Resolve-Path $InputFile).Path
$SrcDir = Split-Path -Parent $InputAbs
$InputBasename = [System.IO.Path]::GetFileNameWithoutExtension($InputAbs)

if (-not $Output) {
    $Output = $SrcDir
}
if (-not (Test-Path $Output)) {
    New-Item -ItemType Directory -Path $Output -Force | Out-Null
}
$Output = (Resolve-Path $Output).Path

# --- 清理模式 ---
function Invoke-CleanArtifacts {
    Write-Info "清理中間檔於 $SrcDir"
    $exts = @("aux", "bbl", "bcf", "blg", "fdb_latexmk", "fls", "lof", "log", "lot", "out", "run.xml", "synctex.gz", "toc", "xdv", "tex")
    foreach ($ext in $exts) {
        $file = Join-Path $SrcDir "$InputBasename.$ext"
        if (Test-Path $file) {
            Remove-Item $file -Force
        }
    }
    Write-Ok "清理完成"
}

if ($Clean) {
    Invoke-CleanArtifacts
    exit 0
}

# --- 工具偵測 ---
function Test-Command {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

if (-not (Test-Command "pandoc")) {
    Write-ErrorMsg "找不到 pandoc。請執行 scripts\install.ps1 安裝環境。"
    exit 1
}
if (-not (Test-Command $Engine)) {
    Write-ErrorMsg "找不到 $Engine。請執行 scripts\install.ps1 安裝 MiKTeX 或 TeX Live。"
    exit 1
}
if (-not $NoBib -and -not (Test-Command "biber")) {
    Write-ErrorMsg "找不到 biber。請執行 scripts\install.ps1 安裝。"
    exit 1
}

if (-not (Test-Path $Template)) {
    Write-ErrorMsg "找不到模板：$Template"
    exit 1
}

# --- 編譯函式 ---
# 解析「真正可用的」python 直譯器。
# Windows 上 `python` / `python3` 常指向 Microsoft Store 的占位 stub
# （路徑落在 ...\WindowsApps\python.exe），它不會執行腳本、只會以非 0 退出，
# 必須排除，否則 lint 永遠跑不起來卻被誤判成「lint 發現問題」。
function Resolve-Python {
    foreach ($name in @("python", "python3")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        if ($cmd.Source -and $cmd.Source -like "*\WindowsApps\*") { continue }  # Store stub，跳過
        return $cmd.Source
    }
    return $null
}

# --- 格式檢查（lint）---
# 與 CI 共用同一支 scripts/lint.py。預設僅警告、不擋編譯；-LintStrict 才中止。沒有 python 時優雅略過。
function Invoke-Lint {
    if ($NoLint) { return }
    $linter = Join-Path $ScriptDir "lint.py"
    if (-not (Test-Path $linter)) { return }
    $py = Resolve-Python
    if (-not $py) { Write-WarnMsg "未安裝 python，略過格式檢查（lint）"; return }
    Write-Info "格式檢查（lint）：$InputAbs"
    $lintArgs = @($linter)
    if ($LintStrict) { $lintArgs += "--strict" }
    $lintArgs += $InputAbs
    $code = Invoke-Native -Cmd $py -ArgList $lintArgs -ShowOutput
    # lint.py 的退出碼語意：0=乾淨；1=發現問題。其他值代表 python 自身異常
    # （找不到模組、stub 沒跑等），不可當成 lint 結果，否則會誤報。
    if ($code -eq 1) {
        if ($LintStrict) {
            Write-ErrorMsg "lint 發現問題（-LintStrict 已啟用，中止編譯）"
            exit 1
        }
        Write-WarnMsg "lint 發現問題（僅警告，繼續編譯；要擋編譯請加 -LintStrict）"
    } elseif ($code -ne 0) {
        Write-WarnMsg "lint 無法執行（python 退出碼 $code），略過格式檢查"
    }
}

function Invoke-Build {
    $tmpdir = Join-Path $env:TEMP "paperforge_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tmpdir -Force | Out-Null

    try {
        Invoke-Lint

        Write-Info "暫存目錄：$tmpdir"

        # 複製來源目錄到暫存
        Write-Info "複製來源檔案到暫存目錄"
        Copy-Item -Path "$SrcDir\*" -Destination $tmpdir -Recurse -Force

        # 複製模板到暫存（內部統一命名為 template.latex）
        Copy-Item -Path $Template -Destination (Join-Path $tmpdir "template.latex") -Force

        # 複製 CSL（若需要）
        $tmpCslDir = Join-Path $tmpdir "cites"
        if ((Test-Path $CslPath) -and -not (Test-Path (Join-Path $tmpCslDir "ieee.csl"))) {
            if (-not (Test-Path $tmpCslDir)) {
                New-Item -ItemType Directory -Path $tmpCslDir -Force | Out-Null
            }
            Copy-Item -Path $CslPath -Destination (Join-Path $tmpCslDir "ieee.csl") -Force
        }

        Push-Location $tmpdir
        try {
            $showOutput = ($VerbosePreference -eq "Continue")

            # Step 1: Pandoc Markdown → LaTeX
            Write-Info "Pandoc：Markdown → LaTeX"
            $pandocArgs = @(
                "$InputBasename.md",
                "-o", "$InputBasename.tex",
                "--biblatex",
                "--template=template.latex",
                "--pdf-engine=$Engine"
            )
            # 字體覆寫：命令列 -V 優先於輸入檔 YAML 的 mainfont / CJKmainfont。
            if ($MainFont) { $pandocArgs += @("-V", "mainfont=$MainFont") }
            if ($CjkFont)  { $pandocArgs += @("-V", "CJKmainfont=$CjkFont") }
            if ($showOutput) {
                $pandocArgs += "--verbose"
            }
            $code = Invoke-Native -Cmd "pandoc" -ArgList $pandocArgs -ShowOutput:$showOutput
            if ($code -ne 0) {
                Write-ErrorMsg "Pandoc 編譯失敗 (exit=$code)"
                exit 1
            }

            # Step 2: 第一次 XeLaTeX
            Write-Info "${Engine}：第一次編譯"
            $latexArgs = @("-interaction=nonstopmode", "$InputBasename.tex")
            $null = Invoke-Native -Cmd $Engine -ArgList $latexArgs -ShowOutput:$showOutput

            # Step 3: biber
            if (-not $NoBib) {
                Write-Info "biber：處理參考文獻"
                $code = Invoke-Native -Cmd "biber" -ArgList @($InputBasename) -ShowOutput:$showOutput
                if ($code -ne 0) {
                    Write-WarnMsg "biber 失敗 (exit=$code)（可能是無引用條目）"
                }
            }

            # Step 4: 第二次 XeLaTeX
            Write-Info "${Engine}：第二次編譯（解析引用）"
            $null = Invoke-Native -Cmd $Engine -ArgList $latexArgs -ShowOutput:$showOutput

            # Step 5: 第三次 XeLaTeX（保留最後一趟的退出碼供驗證）
            Write-Info "${Engine}：第三次編譯（解析目錄）"
            $latexCode = Invoke-Native -Cmd $Engine -ArgList $latexArgs -ShowOutput:$showOutput

            # 驗證
            $pdfPath = Join-Path $tmpdir "$InputBasename.pdf"
            $logPath = Join-Path $tmpdir "$InputBasename.log"
            if (-not (Test-Path $pdfPath)) {
                Write-ErrorMsg "編譯失敗：找不到 PDF（${Engine} 退出碼 $latexCode）"
                if (Test-Path $logPath) {
                    Write-ErrorMsg "編譯記錄：$logPath"
                }
                exit 1
            }

            # 完整性檢查：xelatex 中途被中斷（例如 MiKTeX 更新提示升級成致命錯誤、
            # dvipdfmx 寫到一半夭折）時，會留下尾端缺 %%EOF 的截斷 PDF——大小看似正常、
            # 卻無法開啟。光看「檔案存在」不夠，必須確認 PDF 確實寫完。
            $tailLen = [Math]::Min(1024, (Get-Item $pdfPath).Length)
            $fs = [System.IO.File]::Open($pdfPath, "Open", "Read")
            try {
                $buf = New-Object byte[] $tailLen
                $null = $fs.Seek(-$tailLen, "End")
                $null = $fs.Read($buf, 0, $tailLen)
            } finally { $fs.Close() }
            $tailText = [System.Text.Encoding]::ASCII.GetString($buf)
            if ($tailText -notmatch "%%EOF") {
                Write-ErrorMsg "編譯失敗：PDF 不完整（缺 %%EOF，可能編譯途中被中斷；${Engine} 退出碼 $latexCode）"
                if (Test-Path $logPath) {
                    Write-ErrorMsg "請查看編譯記錄末尾找出中斷原因：$logPath"
                }
                exit 1
            }

            # 用 Copy-Item（而非 Move-Item）避免雲端同步誤刪
            Write-Info "複製 PDF 到輸出目錄：$Output"
            Copy-Item -Path $pdfPath -Destination (Join-Path $Output "$InputBasename.pdf") -Force

            if ($KeepTex) {
                $texPath = Join-Path $tmpdir "$InputBasename.tex"
                Copy-Item -Path $texPath -Destination (Join-Path $Output "$InputBasename.tex") -Force
            }

            $pdfInfo = Get-Item (Join-Path $Output "$InputBasename.pdf")
            Write-Ok "編譯完成：$($pdfInfo.FullName) ($($pdfInfo.Length) bytes)"

            # XeLaTeX 即使有警告（undefined references、overfull hbox 等）也可能回傳非零 exit code，
            # 但只要 PDF 成功產出且符合大小門檻，就視為成功。明確覆寫 $LASTEXITCODE。
            $global:LASTEXITCODE = 0
        }
        finally {
            Pop-Location
        }
    }
    finally {
        if (Test-Path $tmpdir) {
            Remove-Item -Path $tmpdir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- 監看模式 ---
function Invoke-Watch {
    Write-Info "監看模式：偵測 $SrcDir 變動..."
    Write-Info "Ctrl+C 結束"

    Invoke-Build

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $SrcDir
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor `
                            [System.IO.NotifyFilters]::FileName

    $excludePattern = '\.(aux|bbl|bcf|log|out|toc|pdf|tex|lof|lot|run\.xml)$'
    $lastRun = Get-Date

    try {
        while ($true) {
            $result = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
            if ($result.TimedOut) { continue }

            $changedPath = $result.Name
            if ($changedPath -match $excludePattern) { continue }

            # debounce: 同一秒內不重複編譯
            $now = Get-Date
            if (($now - $lastRun).TotalSeconds -lt 1) { continue }
            $lastRun = $now

            Write-Info "偵測到變動：$changedPath，重新編譯..."
            try {
                Invoke-Build
            } catch {
                Write-WarnMsg "編譯失敗：$($_.Exception.Message)，繼續監看"
            }
        }
    }
    finally {
        $watcher.Dispose()
    }
}

# --- 主流程 ---
Write-Info "輸入檔案：$InputAbs"
Write-Info "輸出目錄：$Output"
Write-Info "PDF 引擎：$Engine"
Write-Info "Profile：$ProfileName"
Write-Info "Pandoc 模板：$Template"

if ($Watch) {
    Invoke-Watch
} else {
    Invoke-Build
}

# 確保編譯成功時回傳 0（避免 native command 殘留的非零碼）
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
exit 0
