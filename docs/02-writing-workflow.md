# 02 — 寫作流程指南

本文件說明從零開始撰寫一份 NCU 論文的完整工作流。

## 整體流程

```
1. 複製 profiles/thesis-ncu/skeleton/ 為自己的論文資料夾
2. 設定 Zotero 自動匯出 references.bib
3. 編輯 paper.md（YAML metadata + 章節內容）
4. 邊寫邊用 scripts/build.sh / scripts/build.ps1 編譯預覽
5. 完稿後用監看模式作最後校對
```

## Step 1：建立論文資料夾

從對應 profile 的 `skeleton/` 複製出來（NCU 學位論文使用 `thesis-ncu`）：

```bash
# Linux/macOS
cp -r profiles/thesis-ncu/skeleton/ my-thesis/

# Windows PowerShell
Copy-Item -Recurse profiles\thesis-ncu\skeleton my-thesis
```

可以放在 PaperForge repo 內，或獨立目錄都可以（編譯時注意路徑即可）。

**建議**：把 `my-thesis/` 作為獨立的 Git repo 來追蹤論文修改歷史。

```bash
cd my-thesis
git init
git add .
git commit -m "Initial commit from template"
```

## Step 2：填寫 YAML metadata

打開 `my-thesis/paper.md`，把 YAML 區塊頂端的 placeholder 替換為實際內容：

```yaml
---
profile: thesis-ncu                   # PaperForge 編譯時自動套用此 profile（skeleton 已預填）
thesis-title-zh: "你的論文中文題目"
thesis-title-en: "Your Thesis English Title"
department: "機械工程學系"          # 改成你的系所
program: "光機電工程碩士班"        # 改成你的學程
degree: "碩士論文"                    # 或 "博士論文"
student: "王小明"                     # 你的姓名
advisor: "李大華 博士"                # 指導教授
year: "115"                           # 民國年（畢業年）
month: "6"                            # 畢業月份
---
```

字體設定一般不需要動：

```yaml
mainfont: "Times New Roman"
CJKmainfont: "標楷體"
fontsize: 12pt
linestretch: 1.5
```

若你的系統沒有「標楷體」，把 `CJKmainfont` 改為 `Noto Serif CJK TC`。

## Step 3：撰寫章節

### 章節結構

按照 NCU 慣用結構撰寫：

```markdown
# 緒論 {#sec:intro}
## 研究背景 {#sec:intro-background}
## 研究動機 {#sec:intro-motivation}
## 論文架構 {#sec:intro-structure}

# 文獻探討 {#sec:literature}
...

# 研究方法 {#sec:method}
...
```

**強制規範**：每個章節（包含 `##`、`###`、`####`）後面**必須**加 `{#sec:...}` 錨點。
詳見 [Pandoc 語法速查](04-pandoc-syntax.md#章節標題)。

### 引用文獻

```markdown
Vaswani 等人[@vaswani2017attention]提出 Transformer 架構。

近期研究[@he2016resnet; @dosovitskiy2020vit]證實...
```

### 插入圖片

```markdown
![系統流程圖](images/system_overview.png){#fig:system-overview width=80%}

如圖 \ref{fig:system-overview} 所示，本研究包含三個模組。
```

### LaTeX 表格

```latex
\begin{table}[htbp]
\centering
\caption{實驗超參數}
\label{tab:hyperparameters}
\begin{tabular}{ll}
\hline
\textbf{參數} & \textbf{值} \\
\hline
學習率 & 1e-4 \\
批次大小 & 32 \\
\hline
\end{tabular}
\end{table}
```

### 公式

```latex
\begin{equation}
y = \mathrm{softmax}(W x + b)
\label{eq:classification}
\end{equation}

依公式 \ref{eq:classification} 計算。
```

### LaTeX 變數（實驗數據集中管理）

在 YAML `header-includes` 中定義變數：

```latex
\def\experimentTotal{1000}
\def\experimentCorrect{952}
\FPeval{\experimentAccuracy}{round(\experimentCorrect/\experimentTotal*100:2)}
```

文中使用：

```markdown
共 `\experimentTotal`{=latex} 筆樣本，正確率 `\experimentAccuracy`{=latex}\%
```

**好處**：修改實驗數字只需改一處，全文自動更新。

## Step 4：編譯預覽

每寫完一個段落就編譯一次，及早發現問題：

```bash
# Linux/macOS
./scripts/build.sh my-thesis/paper.md

# Windows
.\scripts\build.ps1 my-thesis\paper.md

# Make
make build INPUT=my-thesis/paper.md
```

開啟 `my-thesis/paper.pdf` 預覽。

## Step 5：監看模式（推薦）

寫作期間建議開監看模式，存檔即重編：

```bash
./scripts/build.sh my-thesis/paper.md --watch
```

按 Ctrl+C 結束。

## 使用 Claude Code Skill 輔助

如果你裝了 Claude Code 並啟用 `ncu-paper-writer` skill，在論文資料夾中執行 `claude` 即可進入互動模式。

範例提問：

- 「幫我把這段研究背景再潤一下，更學術一點」
- 「這段公式排版有問題嗎？符合 NCU 規範嗎？」
- 「幫我把第 3.2 節重新組織，分成 2-3 個小節」
- 「檢查整篇有沒有用到禁止的破折號」

Skill 會自動載入 NCU 格式規範，並會：

- 主動補上缺少的 `{#sec:...}` 錨點
- 提醒「——」破折號的使用
- 建議實驗數字用 LaTeX 變數管理
- 檢查 `\ref{}` 與 `\label{}` 配對

## 校對清單

完稿前的最終檢查：

- [ ] YAML metadata 全部填寫正確（姓名、教授、年月）
- [ ] 所有章節都有 `{#sec:...}` 錨點
- [ ] 所有圖、表都有 `\label{}` 與 `\ref{}` 引用
- [ ] 參考文獻 `.bib` 條目齊全，無「???」未解析引用
- [ ] 中英文摘要關鍵字一致
- [ ] 目錄、圖目錄、表目錄完整
- [ ] 沒有「——」破折號
- [ ] 沒有錯字（建議用 `LTeX` VS Code 延伸套件）
- [ ] 頁碼前置部分為羅馬數字、正文為阿拉伯數字
- [ ] PDF 連結（藍色、超連結）正常運作

## 下一步

- Zotero 設定：[03-zotero-setup.md](03-zotero-setup.md)
- Pandoc 語法速查：[04-pandoc-syntax.md](04-pandoc-syntax.md)
- 客製化封面、字體：[06-customization.md](06-customization.md)
