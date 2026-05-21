# CLAUDE.md — PaperForge 專案開發指引

本檔案給後續在這個 **repo 本身**進行開發的 Claude 看（不是給「使用此工具寫論文／報告」的使用者看 — 那份在 `profiles/<profile>/skeleton/CLAUDE.md`）。

---

## 專案定位

PaperForge 是「Markdown → 格式精準 PDF」的鍛造工具鏈本身的開發 repo，不是某人的論文。所有撰寫工作流統一在 `profiles/<type>-<style>/` 抽象之下，目前有兩種 type：

**論文／報告 type（Pandoc + XeLaTeX）**：
- profile 例：`thesis-ncu`、`journal-ieee`（未來）、`report-gov-tw`（未來）
- 每個 profile 含：
  - `profile.yaml`：元資料（name、type、style、defaults）
  - `template.latex`：Pandoc LaTeX 模板
  - `skeleton/`：使用者 `cp -r` 當論文／報告起點的骨架
  - `skill/SKILL.md`：Claude Code Skill 撰寫規範
- 編譯：`build.{ps1,sh}` — profile 套用優先序為 **CLI 旗標 `--profile <name>` > 輸入檔 YAML frontmatter 的 `profile:` 欄位 > 預設 `thesis-ncu`**
- 範例：`examples/minimal`、`examples/full`

**簡報 type（Marp）**：
- profile 例：`slides-ncu`（目前唯一）、`slides-ntu`（未來）
- 每個 profile 含：
  - `profile.yaml`：元資料
  - `theme.css`：Marp 主題 CSS
  - `skeleton/`：使用者 `cp -r` 當簡報起點（含 `slides.md`、`assets/`、個人化的 `theme.css` override）
  - `skill/SKILL.md`：Claude Code Skill 撰寫規範
- 編譯：`build-slides.{ps1,sh}` — profile 套用優先序同上（YAML `profile:` 欄位寫在 `slides.md` 開頭即可），預設 `slides-ncu`
- 範例：`examples/slides-minimal`

**共用**：
- 跨 profile 引用樣式：`shared/cites/`（目前主要服務論文 type）
- 跨平台安裝腳本：`scripts/install*.{ps1,sh}`
- 教學文件：`docs/01` ~ `docs/06`

**Profile 命名慣例**：`<type>-<style>`。type 來自 profile.yaml 的 `type:` 欄位（`thesis` / `journal` / `report` / `slides` / 未來新增）。style 是學校／期刊／機關識別。

**Profile 偵測（重要）**：build script 不再硬寫單一預設 profile。當使用者沒帶 `--profile` 旗標時（例：VS Code `ctrl+shift+b`，task 只傳 `${file}`），build script 會解析輸入 `.md` 開頭的 YAML frontmatter 並讀取 `profile:` 欄位；解析失敗或欄位不存在時，才落到預設 `thesis-ncu`（論文）/ `slides-ncu`（簡報）。**因此所有 skeleton 與 examples 都應在 YAML 開頭顯式寫出 `profile: <name>`**，使用者複製後也應保留此欄位。

**抽象層 vs profile 內容（重要）**：
PaperForge 是「殼／框架」 — 負責 profile 載入、build pipeline、跨平台安裝、CI 等共用機制。
**profile 內容（含 skill、template、skeleton、theme）保留各自學校／機關／單位的原生身分**：
- skill 的 `name:` 由 profile／skill 作者自己決定（例：`ncu-paper-writer`、`ncu-slides-writer`），**不要強制掛 `paperforge-` 前綴**。
- 各 SKILL.md、template、skeleton 的內容描述應該以該學校／機關為主語，而非 PaperForge。
- 改框架時不要動到 profile 的學校 / 機關特定內容；要為其他學校／機關新增 profile 時，照 `profiles/<type>-<style>/` 加一份即可。

**目錄區分**：
- `profiles/`（核心）= 所有 profile，每個資料夾自成一套
- `shared/`（共用資源）= 跨 profile 共用（如 `shared/cites/ieee.csl`）
- `scripts/`（框架腳本）= 安裝、健檢、字體偵測等

---

## Git 工作流偏好

### 工具開發 vs 個人論文：用 worktree 隔離

**這個 repo 有「兩條腿」**：

1. **主分支 `main`**：PaperForge 工具本身的開發
2. **使用者自己的論文／報告分支**（如 `wu`、`nstc` 等）：使用者實際撰寫文件時建立的個人分支

**問題**：使用者在 IDE 中可能正切在自己的論文分支寫論文，這時 Claude 若直接 `git commit` 工具相關修正會誤投到使用者分支上（已踩過兩次，commit `4d7c1c1` 跑到 wu、`1d47953` 跑到 nstc）。

**解法（強制）**：Claude 做工具開發時**一律使用 worktree**，與使用者的工作目錄完全隔離。

```bash
# 一次性設定（第一次需要時建立）
git worktree add ../paperforge.wt-main main

# 之後所有工具開發都在 worktree 目錄裡操作
cd ../paperforge.wt-main
# ... 編輯、commit、push 都在這裡
```

> 註：在尚未把本機目錄從 `ncu_paper_writer/` 改名為 `paperforge/` 之前，worktree 路徑請沿用 `../ncu_paper_writer.wt-main`；目錄改名後再同步更新。

**檢查清單**：每次開始工具開發任務前先驗證：

```bash
git worktree list   # 應該看到 .wt-main 存在
pwd                  # 應該在 .wt-main 目錄
git branch --show-current  # 應該是 main
```

如果發現自己在主工作目錄而非 `.wt-main`，**先 `cd` 過去**再開始任何 commit。

### main 是受保護分支：所有變更必走 PR

GitHub 端對 `main` 已開啟 branch protection（透過 REST API `PUT /repos/{owner}/{repo}/branches/main/protection` 設定），規則如下：

- **必須透過 PR 合併** — 直接 `git push origin main` 會被 server reject
- **線性歷史強制** — 只接受 rebase / fast-forward 形式的合併，PR 必須 rebase 到最新 main 才能合進去
- **`enforce_admins: true`** — 連 repo owner（含本人）都不能繞過；想直接 commit 上 main 就是不行
- **必跑 `Lint Skill markdown` 才能合併**（CI status check 強制）
- **禁止 force push、禁止刪除 main**
- **PR conversation 須全部 resolved 才能合併**
- 目前 `required_approving_review_count: 0`（個人開發階段可自合）；加入協作者後調高為 1，並考慮開啟 `require_code_owner_reviews`

**結論：所有工具修改一律走「feature 分支 → PR → rebase 合併」**，無例外。

### 標準開發流程（強制）

```bash
# 1. 在 .wt-main 確認在最新 main 上
cd ../paperforge.wt-main          # 名稱未改前用 ncu_paper_writer.wt-main
git fetch origin
git rebase origin/main            # 同步到最新 main

# 2. 開一個專屬該工作的 worktree + feature 分支（或在現有 feature worktree 上工作）
cd ..
git worktree add ./paperforge.wt-<short-name> -b <type>/<short-desc> main
cd paperforge.wt-<short-name>

# 3. 在這個 worktree 寫程式、commit
# ... edit, git add, git commit ...

# 4. 推上 GitHub
git push -u origin <type>/<short-desc>

# 5. 開 PR（標題用 Conventional Commits 風格）
gh pr create --title "feat: ..." --body "..."

# 6. 等 lint 過綠後，rebase merge（保持線性歷史）
gh pr merge --rebase --delete-branch

# 7. 同步本地 main
cd ../paperforge.wt-main
git fetch origin
git rebase origin/main

# 8. 清理用完的 worktree
git worktree remove ../paperforge.wt-<short-name>
```

### 若 main 在 feature 分支期間有更新

```bash
# 在 feature 分支 worktree 中：
git fetch origin
git rebase origin/main
# 解決衝突（若有）後 force-push（force-with-lease 較安全）
git push --force-with-lease
# PR 會自動更新；等 CI 重跑後即可 merge
```

> 注意：`--force-with-lease` 只對 feature 分支安全且必要；對 `main` 任何形式的 force push 都被 server 擋下，不要嘗試。

### 不要做的事

- ❌ 直接 `git push origin main` — server 會 reject，不要試圖繞過
- ❌ `git merge --no-ff`（產生 merge commit、非線性歷史，且 protection 也會擋）
- ❌ `git merge feature-branch`（同上）
- ❌ `git pull` 不加 `--rebase`（會產生 merge commit）— 建議設 `git config pull.rebase true`
- ❌ `git push --force` 到 `main`（被 protection 擋；對 feature 分支用 `--force-with-lease`）
- ❌ `gh pr merge --merge` 或 `--squash` 形式合併 — 用 `--rebase` 才符合 linear history 要求
- ❌ 改 branch protection 設定不留紀錄 — 任何調整都該在 CLAUDE.md 同步更新

### Commit message 慣例

採 Conventional Commits 風格：

- `feat:` 新功能
- `fix:` bug 修復
- `docs:` 文件
- `test:` 測試相關
- `chore:` 雜項（CI、build 配置）
- `refactor:` 重構

範例（看 git log 既有提交）：

```
fix(windows): UTF-8 BOM 與 native command stderr 處理
test(workflow): Windows 端對端編譯驗證
docs(skill): 補入 Windows 實測發現的兩個撰寫慣例
```

---

## Windows 平台關鍵注意事項

實測發現以下兩點容易踩雷，已在 `f04a556` 修正並寫入 `scripts/build.ps1`：

### 1. PowerShell 5.1 編碼

**所有 `.ps1` 檔案必須存為 UTF-8 with BOM**，否則 PowerShell 5.1 會用 ANSI（台灣 locale 為 Big5）讀取，導致中文字串被當作亂碼造成 parser error。

新增/修改 `.ps1` 檔案後，務必執行：

```powershell
$utf8Bom = New-Object System.Text.UTF8Encoding $true
$content = [System.IO.File]::ReadAllText("path\to\file.ps1", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText("path\to\file.ps1", $content, $utf8Bom)
```

未來考慮在 CI 加 lint 驗證所有 `.ps1` 有 BOM。

### 2. Native command stderr 處理

PowerShell 5.1 會把 native exe（pandoc/xelatex/biber）的 stderr 包成 `NativeCommandError`，當 `$ErrorActionPreference = "Stop"` 時會中斷腳本，**即使 exe 實際 exit code 為 0**（例如 MiKTeX 的 "check for updates" 提示）。

在 `scripts/build.ps1` 已新增 `Invoke-Native` helper：呼叫 native command 時改用 `$ErrorActionPreference = "Continue"` 並透過 `$LASTEXITCODE` 檢查。新增其他 native command 呼叫處請沿用此模式。

---

## 撰寫慣例（已寫入各 profile 的 SKILL.md）

各 profile 對應內容的撰寫原則放在 `profiles/<name>/skill/SKILL.md`，不要在 `CLAUDE.md` 重複。修改格式規範時更新對應 `SKILL.md`，並重新執行 `scripts/install-skill.ps1 -Force` 同步到使用者目錄（指定單一 skill：`-Only <skill-name>`，例 `-Only ncu-paper-writer`）。

幾個會反覆遇到的撰寫陷阱（以 `thesis-ncu` 為例，其他 profile 視規範而定）：

1. **所有章節必須有 `{#sec:...}` 錨點**（包含 `##`、`###`、`####`）
2. **`\ref{}` 只回傳數字**，中文敘述需手動補「第」「章」「節」前後綴
3. **標楷體缺 glyph**：`✓ ✗ → ≤ α °` 等符號要用 LaTeX 指令或數學模式
4. **禁用「——」全形破折號**

---

## 修改流程提示

### 改 Skill / template

修改後同步到使用者目錄：

```powershell
.\scripts\install-skill.ps1 -Force
```

### 改 build/install 腳本

論文（XeLaTeX）實測在 `examples/minimal` 編譯：

```powershell
.\scripts\build.ps1 examples\minimal\paper.md
```

PDF 必須 > 10 KB 且 5 頁以上才算通過。

簡報（Marp）實測在 `examples/slides-minimal` 編譯：

```powershell
.\scripts\build-slides.ps1 examples\slides-minimal\slides.md
```

PDF 必須 > 100 KB 才算通過（Marp 內嵌字體較肥）。首次執行會下載 Chromium。

### CI 結構（三支 workflow）

- **`.github/workflows/lint.yml`**：每次 push/PR 都跑（30 秒）。檢查 Skill frontmatter、章節錨點、禁用破折號、Marp 簡報頁數上限。
- **`.github/workflows/docker-images.yml`**：在 `docker/**` 變動時 build & push CI base image 到 GHCR，打 `:latest` / `:<branch-slug>` / `:sha-<7chars>` tag。給外部 / release 用。
- **`.github/workflows/build.yml`**：含 prepare-image + build + build-slides 共四個 job：
  - `prepare-paper-image` / `prepare-slides-image`：用 GHA cache build `docker/{paper,slides}.Dockerfile` 並推 `:ci-<run_id>` tag。Dockerfile 沒變時幾乎瞬間。
  - `build`：以 paper image 為 container 跑，編譯論文 PDF。
  - `build-slides`：以 slides image 為 container 跑，編譯 Marp 簡報 PDF/HTML。

  只在以下時機跑：
  - PR 開啟/更新
  - 手動 `workflow_dispatch`
  - push 到 main 且改到 `profiles/`、`shared/`、`examples/`、`build*.{sh,ps1}`、`Makefile`、`docker/` 或 `build.yml` 自身

改 docs 等不影響編譯的檔案 push 上去只會跑 lint。

### CI build images（重要）

build.yml 不再每次跑 `apt install`，改用 GHCR 上的預建 image：
- `ghcr.io/<owner>/paperforge-paper:ci-<run_id>` — Pandoc + TeX Live + biber + Noto CJK
- `ghcr.io/<owner>/paperforge-slides:ci-<run_id>` — Node 20 + marp-cli + Chrome for Testing + Noto CJK

Dockerfile 在 [`docker/`](docker/)，詳細說明見 [`docker/README.md`](docker/README.md)。

**修改 image 內容**（加 LaTeX 套件、字體、Node lib 等）的流程：
1. 改 `docker/paper.Dockerfile` 或 `docker/slides.Dockerfile`
2. 開 PR — `build.yml` 的 `prepare-*-image` job 會自動 build 新版 image 並用於該 PR 的測試
3. 合入 main 後 `docker-images.yml` 會更新 `:latest`（給外部 fork / release 用）

**Fork 到 private repo 時**需手動把兩個 GHCR package visibility 改成 Public，否則拉不到 image（fork 到 public repo 通常會繼承 public，不用動）。詳見 [`docker/README.md`](docker/README.md) 的「第一次設定」段落。

### 改 docs

無 lint，但要確認章節錨點、`\ref{}` 前後綴、無「——」破折號。

---

## 不要做的事

- 不要 commit `*.pdf`、`*.tex`、`paper.tex` 等編譯產物（已在 `.gitignore`）
- 不要動 `profiles/thesis-ncu/template.latex` 的 `\Spaced` 巨集，那是封面字距加寬的核心
- 不要把使用者個資（姓名、學號、實際論文題目）寫進 `profiles/*/skeleton/` 或 `examples/`
- 不要在 `.ps1` 檔案使用全形引號「」，PowerShell 解析會出錯
