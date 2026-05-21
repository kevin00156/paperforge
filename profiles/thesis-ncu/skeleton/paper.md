---
profile: thesis-ncu  # PaperForge 編譯時自動套用此 profile（可被 CLI --profile 覆寫）

# ============================================================
# === NCU 論文基本資訊（請替換以下 placeholder） ===
# ============================================================
thesis-title-zh: "<您的論文中文題目>"
thesis-title-en: "<Your Thesis Title in English>"
department: "<您的系所，例如：機械工程學系>"
program: "<您的學程，例如：光機電工程碩士班>"
degree: "碩士論文"                  # 或 "博士論文"
student: "<您的姓名>"
advisor: "<指導教授姓名> 博士"
year: "<民國年，例如：115>"
month: "<月份，例如：6>"

# ============================================================
# === 圖片子圖支援 ===
# ============================================================
subfigure: true

# ============================================================
# === 紙張與邊距（依 NCU 規範） ===
# ============================================================
geometry: "top=2.5cm, bottom=2.5cm, left=3cm, right=2cm"
papersize: a4
classoption: [fleqn]

# ============================================================
# === 字體設定（NCU 嚴格規範） ===
# ============================================================
# 若系統無「標楷體」（常見於 Linux/macOS），可改用 "Noto Serif CJK TC" 或 "思源宋體"
mainfont: "Times New Roman"
CJKmainfont: "標楷體"
fontsize: 12pt
linestretch: 1.5

# ============================================================
# === 引用/參考文獻（biblatex + biber） ===
# ============================================================
bibliography: references.bib
biblatex: true
biblio-style: ieee
suppress-bibliography: true       # 文末手動 \printbibliography 控制位置

# ============================================================
# === 頁碼與標題設定 ===
# ============================================================
numbersections: true
secnumdepth: 4                    # 編號最深到 #### 第四層
toc: false                        # 手動插入 \tableofcontents

# ============================================================
# === LaTeX 標題格式、頁碼、超連結等進階設定 ===
# ============================================================
header-includes:
  - |
    ```{=latex}
    \usepackage{titlesec}
    \usepackage{makecell}
    \usepackage{indentfirst}
    \usepackage{fancyhdr}
    \usepackage{graphicx}
    \usepackage{caption}
    \usepackage{hyperref}
    \usepackage{xcolor}
    \usepackage{float}
    \usepackage{longtable}
    \usepackage{colortbl}

    % === 圖表位置：偏好原位，允許少量浮動 ===
    \floatplacement{figure}{!htbp}
    \floatplacement{table}{!htbp}

    % === 公式：靠左 + 自動編號 (節號-公式號) ===
    \setlength{\mathindent}{0pt}
    \numberwithin{equation}{section}
    \renewcommand{\theequation}{\arabic{section}-\arabic{equation}}

    % === 超連結設定 ===
    \hypersetup{
      colorlinks=true,
      linkcolor=black,
      citecolor=blue,
      urlcolor=blue
    }

    % === 首行縮排 2 字元 ===
    \setlength{\parindent}{2em}

    % === 圖表標題置中，名稱中文化 ===
    \captionsetup{justification=centering}
    \captionsetup[figure]{name={圖},labelsep=space}
    \captionsetup[table]{name={表},labelsep=space}

    % === 目錄/圖目錄/表目錄標題 ===
    \renewcommand{\contentsname}{目錄}
    \renewcommand{\listfigurename}{圖目錄}
    \renewcommand{\listtablename}{表目錄}

    % === 章標題格式：置中、加粗、加上「第 X 章」前綴 ===
    \titleformat{\section}
      {\centering\Large\bfseries}
      {第\arabic{section}章}{1em}{}
    \titlespacing*{\section}{0pt}{0pt}{24pt}

    % === 節標題格式 ===
    \titleformat{\subsection}
      {\large\bfseries}
      {\arabic{section}.\arabic{subsection}}{1em}{}
    \titlespacing*{\subsection}{0pt}{18pt}{6pt}

    % === 小節標題格式 ===
    \titleformat{\subsubsection}
      {\normalsize\bfseries}
      {\arabic{section}.\arabic{subsection}.\arabic{subsubsection}}{1em}{}
    \titlespacing*{\subsubsection}{0pt}{12pt}{6pt}

    % === 第四層標題格式 ===
    \titleformat{\paragraph}
      {\normalsize\bfseries}
      {\arabic{section}.\arabic{subsection}.\arabic{subsubsection}.\arabic{paragraph}}{1em}{}
    \titlespacing*{\paragraph}{0pt}{12pt}{6pt}

    % === 頁碼樣式 ===
    \fancypagestyle{frontmatter}{
      \fancyhf{}
      \fancyfoot[C]{\thepage}
      \renewcommand{\headrulewidth}{0pt}
    }
    \fancypagestyle{mainmatter}{
      \fancyhf{}
      \fancyfoot[C]{\thepage}
      \renewcommand{\headrulewidth}{0pt}
    }

    % === 左右對齊 ===
    \usepackage{ragged2e}
    \justifying
    \setlength{\emergencystretch}{3em}

    % === 技術識別符允許在底線處換行；math mode 內保留原行為，避免 \mathit{a\_b} 之類爆掉 ===
    \let\paperforgeOrigUnderscore\_
    \renewcommand{\_}{\ifmmode\paperforgeOrigUnderscore\else\textunderscore\allowbreak\fi}

    % === 實驗數據變數（在此集中管理，全文自動更新） ===
    \usepackage{fp}
    % 範例：
    % \def\experimentTotal{1000}
    % \def\experimentCorrect{950}
    % \FPeval{\experimentAccuracy}{round(\experimentCorrect/\experimentTotal*100:2)}
    ```
---

<!-- ============================================================ -->
<!-- 封面頁（無頁碼） -->
<!-- ============================================================ -->

\begin{titlepage}
\begin{center}

\vspace*{1cm}

{\fontsize{24pt}{28pt}\selectfont\bfseries \Spaced[1em]{\UniversityZh}}

\vspace{2cm}

{\fontsize{18pt}{24pt}\selectfont \Spaced[0.5em]{\Department}}

\vspace{0.3cm}

{\fontsize{18pt}{24pt}\selectfont \Spaced[0.5em]{\Program}}

\vspace{0.3cm}

{\fontsize{18pt}{24pt}\selectfont \Spaced[0.5em]{\Degree}}

\vspace{2.5cm}

{\fontsize{18pt}{24pt}\selectfont\bfseries \ThesisTitleZh}

\vspace{0.5cm}

{\fontsize{14pt}{18pt}\selectfont \ThesisTitleEn}

\vspace{4cm}

{\fontsize{14pt}{18pt}\selectfont \Spaced[0.3em]{研究生：}\StudentName}

\vspace{0.3cm}

{\fontsize{14pt}{18pt}\selectfont \Spaced[0.3em]{指導教授：}\AdvisorName}

\vspace{2cm}

{\fontsize{14pt}{18pt}\selectfont \Spaced[0.3em]{中華民國\ROCYear 年\ROCMonth 月}}

\end{center}
\end{titlepage}

<!-- ============================================================ -->
<!-- 摘要（羅馬數字頁碼 i, ii, iii ...） -->
<!-- ============================================================ -->

\pagenumbering{roman}
\pagestyle{frontmatter}

\begin{center}
{\Large\bfseries 摘要}
\end{center}

<請在此撰寫中文摘要，建議 500–800 字。摘要應包含：研究背景與動機、研究問題、所提方法、實驗結果與結論。>

\vspace{1cm}

\noindent\textbf{關鍵字：<關鍵字1>、<關鍵字2>、<關鍵字3>、<關鍵字4>、<關鍵字5>}

\newpage

<!-- ============================================================ -->
<!-- Abstract（英文摘要） -->
<!-- ============================================================ -->

\begin{center}
{\Large\bfseries Abstract}
\end{center}

<Write the English abstract here, typically 300–500 words. Should mirror the Chinese abstract in content.>

\vspace{1cm}

\noindent\textbf{Keywords: <Keyword1>, <Keyword2>, <Keyword3>, <Keyword4>, <Keyword5>}

\newpage

<!-- ============================================================ -->
<!-- 致謝 -->
<!-- ============================================================ -->

\begin{center}
{\Large\bfseries 致謝}
\end{center}

<請在此撰寫致謝詞。建議依序感謝：指導教授、口試委員、實驗室同學、家人。>

\vspace{0.5cm}
由衷感謝

\vspace{2cm}

\begin{flushright}
{\StudentName}　謹誌

中華民國 {\ROCYear} 年 {\ROCMonth} 月
\end{flushright}

\newpage

<!-- ============================================================ -->
<!-- 目錄 -->
<!-- ============================================================ -->

\tableofcontents

\newpage

<!-- ============================================================ -->
<!-- 圖目錄 -->
<!-- ============================================================ -->

\listoffigures

\newpage

<!-- ============================================================ -->
<!-- 表目錄 -->
<!-- ============================================================ -->

\listoftables

\newpage

<!-- ============================================================ -->
<!-- 正文開始（阿拉伯數字頁碼） -->
<!-- ============================================================ -->

\pagenumbering{arabic}
\pagestyle{mainmatter}

# 緒論 {#sec:intro}

## 研究背景 {#sec:intro-background}

<請在此撰寫研究背景。簡述問題領域的現況、重要性，以及為什麼這個題目值得研究。可引用文獻：[@example-key]。>

## 研究動機與目的 {#sec:intro-motivation}

<請說明研究動機（觀察到什麼問題、現有方法的不足）與研究目的（你想解決什麼、達成什麼）。>

## 研究貢獻 {#sec:intro-contribution}

<請條列本論文的主要貢獻，建議 2-4 點。>

1. **<貢獻一>**：<簡述貢獻內容>
2. **<貢獻二>**：<簡述貢獻內容>
3. **<貢獻三>**：<簡述貢獻內容>

## 論文架構 {#sec:intro-structure}

<說明本論文後續各章節的安排。範例：>

本論文共分為五章。\ref{sec:literature} 章回顧相關文獻；\ref{sec:method} 章說明所提方法；\ref{sec:results} 章呈現實驗結果與討論；\ref{sec:conclusion} 章總結本研究並提出未來工作方向。

# 文獻探討 {#sec:literature}

## <第一個主題> {#sec:literature-topic1}

<請在此回顧該主題的相關研究。引用文獻範例：[@example-key1; @example-key2]。>

## <第二個主題> {#sec:literature-topic2}

<請在此回顧另一個主題的相關研究。>

## 小結 {#sec:literature-summary}

<簡述文獻回顧的整體發現，以及本研究與既有研究的差異。>

# 研究方法 {#sec:method}

## 系統概述 {#sec:method-overview}

<請說明你的方法整體架構。可插入系統流程圖：>

<!--
範例：插入單張圖片
![系統架構流程](images/system_overview.png){#fig:system-overview width=80%}

範例：插入單張大圖（精確控制尺寸）
\begin{figure}[!htbp]
\centering
\includegraphics[width=1\textwidth,height=0.9\textheight,keepaspectratio]{images/system_overview.png}
\caption{系統架構流程}
\label{fig:system-overview}
\end{figure}
-->

如圖 \ref{fig:system-overview} 所示，本研究的整體架構分為三個主要模組。

## <方法一> {#sec:method-approach1}

<請說明第一個方法元件的細節。可插入公式：>

公式 \ref{eq:example-formula} 定義了核心運算：

\begin{equation}
y = f(x; \theta) + \epsilon
\label{eq:example-formula}
\end{equation}

## <方法二> {#sec:method-approach2}

<請說明第二個方法元件。>

# 實驗結果與討論 {#sec:results}

## 實驗設定 {#sec:results-setup}

<請說明：資料集、評估指標、實驗環境、超參數設定。可用表格呈現：>

<!--
範例 LaTeX 表格：
\begin{table}[htbp]
\centering
\caption{實驗超參數設定}
\label{tab:hyperparameters}
\small
\begin{tabular}{ll}
\hline
\textbf{超參數} & \textbf{值} \\
\hline
學習率 (Learning Rate) & 1e-4 \\
批次大小 (Batch Size)  & 32 \\
訓練週期 (Epochs)      & 100 \\
最佳化器 (Optimizer)   & AdamW \\
\hline
\end{tabular}
\end{table}
-->

實驗超參數設定如表 \ref{tab:hyperparameters} 所示。

## 主要結果 {#sec:results-main}

<請呈現主要實驗結果。建議搭配表格與圖表。>

## 消融研究 {#sec:results-ablation}

<請說明各元件對性能的貢獻。>

## 討論 {#sec:results-discussion}

<請分析結果背後的意義、與現有方法的比較、模型的限制等。>

# 結論與未來工作 {#sec:conclusion}

## 結論 {#sec:conclusion-summary}

<請總結本論文的研究成果與貢獻。>

## 未來工作 {#sec:conclusion-future}

<請說明本研究可能的延伸方向。>

<!-- ============================================================ -->
<!-- 參考文獻（Pandoc + biblatex 自動產生） -->
<!-- ============================================================ -->

\newpage
\printbibliography[title=參考文獻]
