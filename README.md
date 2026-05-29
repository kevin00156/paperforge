<p align="center">
  <img src="docs/assets/logo.png" alt="PaperForge logo" width="200">
</p>

# PaperForge

> Markdown 寫稿、Pandoc + XeLaTeX 鍛出格式精準的 PDF 論文／報告，附 Marp 簡報工作流

[![Lint](https://github.com/kevin00156/paperforge/actions/workflows/lint.yml/badge.svg)](https://github.com/kevin00156/paperforge/actions/workflows/lint.yml)
[![Build Examples](https://github.com/kevin00156/paperforge/actions/workflows/build.yml/badge.svg)](https://github.com/kevin00156/paperforge/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Pandoc](https://img.shields.io/badge/Pandoc-%E2%89%A53.0-blue)](https://pandoc.org)

PaperForge 是一套以 **Markdown + Pandoc + XeLaTeX** 為核心的「文件鍛造」工作鏈，給需要產出**格式絕對正確**的專業文件使用：學位論文、期刊投稿、政府報告書、技術白皮書等。圖、表、引用、目錄、交叉參照全部走 LaTeX 自動編號，封面字距與裝幀細節由 profile 模板掌控。

PaperForge並沒有新寫任何的新工具，僅提供一個框架，整合所有工具鏈，以保證此專案的穩定性。

同一份原稿還能順帶鍛出口試／工作會議用的 **Marp 簡報**（PDF / HTML），共用一套版本控制與資產目錄。

---

## 影片教學（麻瓜友善）

完全不熟命令列、Git、LaTeX？這套影片從零講起，跟著做就能編出第一份 PDF：

▶️ **[YouTube 播放清單：PaperForge 麻瓜入門系列](https://www.youtube.com/playlist?list=PLR0wzekWGCT6TZnI4mxCV1HcQOE0iJjy9)**

文字版教學請見下方「[5 分鐘快速開始](#5-分鐘快速開始)」與 [docs/](docs/) 目錄。

---

## 為什麼選這套？

| 痛點 | PaperForge 解法 |
|------|----------|
| Word 排版難掌控、追修不同步 | Markdown 純文字 + Git 版本控制 |
| 引用格式手動維護易出錯 | Zotero 自動匯出 BibTeX |
| 章節編號、圖表編號改一個動全身 | LaTeX 自動編號 + 跨章節 `\ref{}` |
| 不熟學校／期刊規範細節 | profile 內建 Claude Skill 熟悉規範 |
| 同學／同事間 Word 檔互傳衝突 | GitHub 協作 |

---

## 適合誰？

✅ **適合**：
- 需要產出嚴格格式 PDF 的研究生、研究員、技術文件作者
- 已會基本 Markdown、願意花 30 分鐘安裝環境
- 偏好純文字工作流、會用 Git 版本控制

❌ **不適合**：
- 完全不熟悉命令列、不想學新工具
- 系所／單位有強制 Word 模板要求且不可繞過

---

## 系統需求

- **作業系統**：Windows 10/11、Ubuntu 22.04+、macOS 13+
- **磁碟空間**：約 4 GB（TeX Live 完整安裝）
- **網路**：首次安裝下載依賴

---

## 5 分鐘快速開始

### 1. Clone repo

```bash
git clone https://github.com/kevin00156/paperforge.git
cd paperforge
```

### 2. 執行一鍵安裝

**Windows (PowerShell)**：
```powershell
.\scripts\install.ps1
```

**Linux / macOS (Bash)**：
```bash
bash scripts/install.sh
```

安裝腳本會自動安裝：Pandoc、XeLaTeX、biber、CJK 字體、Python+uv（可選），以及把各 profile 內附的 Claude Skill（例如 `thesis-ncu` profile 自帶的 `ncu-paper-writer`，與簡報用的 `ncu-slides-writer`）安裝到 `~/.claude/skills/`。各 skill 的名稱由其作者決定，PaperForge 只負責掃描安裝、不強制命名。

### 3. 複製論文骨架

```bash
# Windows
Copy-Item -Recurse profiles\thesis-ncu\skeleton my-thesis

# Linux/macOS
cp -r profiles/thesis-ncu/skeleton/ my-thesis/
```

### 4. 編輯 `my-thesis/paper.md`

打開檔案，把 YAML 區塊裡的 `<您的姓名>` 等 placeholder 替換為實際內容。

### 5. 編譯

```bash
# Windows
.\scripts\build.ps1 my-thesis\paper.md

# Linux/macOS
./scripts/build.sh my-thesis/paper.md

# 或使用 make
make build INPUT=my-thesis/paper.md
```

完成後，`my-thesis/paper.pdf` 即為符合所選 profile 規範的 PDF。

---

## 簡報（Marp）

論文／報告寫完了？同一個 repo 也能寫對應簡報：

```bash
# 1. 安裝 marp-cli（首次）
bash scripts/install-marp.sh      # Linux / macOS
.\scripts\install-marp.ps1        # Windows

# 2. 複製簡報骨架
cp -r profiles/slides-ncu/skeleton/ my-defense/

# 3. 編輯 my-defense/slides.md（Marp Markdown 語法）

# 4. 編譯
./scripts/build-slides.sh my-defense/slides.md --pdf
# 或
make slides SLIDES=my-defense/slides.md
```

簡報用獨立的 `ncu-slides-writer` Claude skill 協助你掌握節奏、頁數、版面。設計上不共享論文內容（簡報是口頭表達，不是論文縮小版）。詳見 [profiles/slides-ncu/skeleton/CLAUDE.md](profiles/slides-ncu/skeleton/CLAUDE.md)。

---

## 目錄結構

```
paperforge/
├── profiles/                # 所有 profile（論文／簡報／…，每個 profile 自成一套）
│   ├── README.md
│   ├── thesis-ncu/          # 國立中央大學學位論文 profile（type: thesis）
│   │   ├── profile.yaml     # 元資料：name, type, style, defaults
│   │   ├── template.latex   # Pandoc LaTeX 模板
│   │   ├── skeleton/        # 骨架（cp -r 出去當你的論文/報告起點）
│   │   │   ├── paper.md
│   │   │   ├── references.bib
│   │   │   ├── images/
│   │   │   └── CLAUDE.md
│   │   └── skill/
│   │       └── SKILL.md     # NCU 論文撰寫 skill
│   └── slides-ncu/          # NCU 學位論文口試簡報 profile（type: slides）
│       ├── profile.yaml
│       ├── theme.css        # Marp 主題 CSS（保守海軍藍）
│       ├── skeleton/        # 簡報骨架（cp -r 出去當你的簡報起點）
│       │   ├── slides.md
│       │   ├── theme.css    # 個人化主題微調（@import 主題後 override）
│       │   ├── assets/
│       │   ├── Makefile
│       │   └── CLAUDE.md
│       └── skill/
│           └── SKILL.md     # NCU 口試簡報撰寫 skill
├── shared/                  # 跨 profile 共用資源
│   └── cites/ieee.csl       # IEEE 引用樣式
├── scripts/                 # 框架腳本（編譯、安裝、健檢）
│   ├── build.{ps1,sh}       # 論文編譯（接受 --profile <name>）
│   ├── build-slides.{ps1,sh}# 簡報編譯（接受 --profile <name>）
│   ├── install.{ps1,sh}     # 一鍵安裝
│   ├── install-skill.{ps1,sh}
│   ├── install-marp.{ps1,sh}
│   ├── check-env.{ps1,sh}
│   └── check-fonts.py
├── examples/                # 可編譯範例
│   ├── minimal/             # 最小論文範例
│   ├── full/                # 完整論文範例
│   └── slides-minimal/      # 最小簡報範例
├── docs/                    # 詳細教學
│   ├── 01-installation.md
│   ├── 02-writing-workflow.md
│   ├── 03-zotero-setup.md
│   ├── 04-pandoc-syntax.md
│   ├── 05-troubleshooting.md
│   └── 06-customization.md
└── Makefile                 # Linux/macOS make 入口
```

---

## 進階使用

### 監看模式（檔案變動自動重編）

```bash
./scripts/build.sh my-thesis/paper.md --watch
# 或
make watch INPUT=my-thesis/paper.md
```

### 環境健檢

```bash
./scripts/check-env.sh         # Linux/macOS
.\scripts\check-env.ps1        # Windows
```

### 僅安裝 Skill（已有 Pandoc/LaTeX 環境）

```bash
bash scripts/install-skill.sh
```

### 字體偵測與推薦

```bash
python scripts/check-fonts.py
# 或
python scripts/check-fonts.py --verbose
```

---

## 文件

- [📚 安裝教學（含疑難排解）](docs/01-installation.md)
- [✍️ 寫作流程指南](docs/02-writing-workflow.md)
- [📖 Zotero + Better BibTeX 設定](docs/03-zotero-setup.md)
- [📝 Pandoc 語法速查](docs/04-pandoc-syntax.md)
- [🛠 疑難排解](docs/05-troubleshooting.md)
- [🎨 客製化（封面、字體、模板）](docs/06-customization.md)

---

## FAQ

### Q: 我沒有「標楷體」怎麼辦？

A: Windows 預設內建；若 Linux/macOS 沒有，可改用 `Noto Serif CJK TC`（思源宋體）。詳見 [docs/05-troubleshooting.md](docs/05-troubleshooting.md)。（此問題僅影響 `thesis-ncu` 等中文 CJK profile。）

### Q: 雲端同步資料夾（OneDrive / pCloud / iCloud / Dropbox）會干擾編譯嗎？

A: 編譯腳本已用系統暫存目錄處理。但仍建議文件資料夾不要設在頻繁同步的目錄根部。

### Q: 為什麼用 biblatex 而非 Pandoc citeproc？

A: biblatex + biber 與 IEEE 等學術引用格式相容性最佳，且支援更複雜的引用樣式。

### Q: 可以寫英文論文／報告嗎？

A: 可以。調整 YAML 中的 `CJKmainfont` 與部分中文標題即可（或建立純英文 profile）。

### Q: Claude Code Skill 是什麼？需要付費嗎？

A: Claude Code 是 Anthropic 的官方 CLI 工具；Skill 是讓 Claude 熟悉特定領域規範的擴充。本專案每個 profile 自帶對應的 skill（如 NCU 論文撰寫規範）。需要 Anthropic API key 或 Claude Pro 訂閱才能使用 Claude Code 本身。

### Q: 我不用 Claude Code 也可以用這套工作流嗎？

A: 完全可以。Skill 是可選的；核心的 Pandoc + LaTeX 編譯工作流獨立運作。就算你純手寫或用ChatGPT的Codex也行。*千萬別用Gemini，智商不足*

---

## 貢獻

歡迎 PR！包括：

- 新 profile（其他學校論文、期刊樣板、報告書範本）
- 字體相容性回饋（其他 distro、其他作業系統）
- 文件改進（截圖、教學）
- 既有 profile skill 規則擴充（附規範來源）

詳見 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 致謝

PaperForge 發想自實際撰寫 NCU 碩士論文的工作流；profile-based 架構讓它能擴充到其他文件類型。感謝 Pandoc、TeX Live、Zotero、Marp 等開源專案，以及所有貢獻者。

---

## 授權

MIT License — 見 [LICENSE](LICENSE)。

模板與 Skill 內容亦採 MIT 授權。各 profile 對應的學校／期刊／單位格式規範屬其原權利人所有，PaperForge 僅整理並協助撰寫。
