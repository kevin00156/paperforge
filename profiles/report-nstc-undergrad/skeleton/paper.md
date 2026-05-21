---
# ============================================================
# === 國科會大專學生研究計畫成果報告基本資訊 ===
# === 請替換以下 placeholder ===
# ============================================================
project-title-zh: "<您的計畫中文名稱>"
project-title-en: "<Your Project Title in English>"
project-id: "NSTC <114-2813-C-XXX-XXX-X>"
project-type: "國科會 大專學生專題研究計畫"
student: "<您的姓名>"
advisor: "<指導教授姓名>"
period-from: "<起始日期，例如：114年07月01日>"
period-to: "<結束日期，例如：115年02月28日>"
period-months: "<月數，例如：計8個月>"
affiliation: "<執行單位，例如：國立聯合大學機械工程學系>"
handling-method: "本計畫可公開查詢"
year: "<報告年（民國），例如：115>"
month: "<報告月，例如：4>"
day: "<報告日，例如：27>"

# ============================================================
# === 圖片子圖支援 ===
# ============================================================
subfigure: true

# ============================================================
# === 紙張與邊距 ===
# ============================================================
geometry: "top=2.5cm, bottom=2.5cm, left=3cm, right=2cm"
papersize: a4
classoption: [fleqn]

# ============================================================
# === 字體設定 ===
# ============================================================
# 若系統無「標楷體」（常見於 Linux/macOS / CI），可改用 "Noto Serif CJK TC"
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
suppress-bibliography: true

# ============================================================
# === 頁碼與標題設定 ===
# ============================================================
numbersections: true
secnumdepth: 4
toc: false

# ============================================================
# === LaTeX 進階設定 ===
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

    % === 圖表位置：偏好原位 ===
    \floatplacement{figure}{!htbp}
    \floatplacement{table}{!htbp}

    % === 圖表編號採「章-序號」（國科會報告慣例：圖 1-1、表 3-2） ===
    \usepackage{chngcntr}
    \counterwithin{figure}{section}
    \counterwithin{table}{section}
    \renewcommand{\thefigure}{\arabic{section}-\arabic{figure}}
    \renewcommand{\thetable}{\arabic{section}-\arabic{table}}

    % === 公式：靠左 + 自動編號（節號-公式號） ===
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

    % === 技術識別符允許底線處換行 ===
    \let\paperforgeOrigUnderscore\_
    \renewcommand{\_}{\ifmmode\paperforgeOrigUnderscore\else\textunderscore\allowbreak\fi}
    ```
---

<!-- ============================================================ -->
<!-- 國科會制式外封（第一頁，無頁碼） -->
<!-- ============================================================ -->

\begin{titlepage}
\begin{center}

\vspace*{1.5cm}

{\fontsize{20pt}{28pt}\selectfont\bfseries 國科會補助}

\vspace{0.6cm}

{\fontsize{20pt}{28pt}\selectfont\bfseries 大專學生研究計畫研究成果報告}

\vspace{2cm}

{\fontsize{14pt}{20pt}\selectfont ＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊}

\vspace{0.3cm}

{\fontsize{14pt}{20pt}\selectfont 計\ 畫\ 名\ 稱：\ProjectTitleZh}

\vspace{0.3cm}

{\fontsize{14pt}{20pt}\selectfont ＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊}

\vspace{1.8cm}

\begin{flushleft}
\hspace{2cm}{\fontsize{14pt}{22pt}\selectfont 執行計畫學生：\StudentName}\\[4pt]
\hspace{2cm}{\fontsize{14pt}{22pt}\selectfont 學生計畫編號：\ProjectId}\\[4pt]
\hspace{2cm}{\fontsize{14pt}{22pt}\selectfont 研\ 究\ 期\ 間：\PeriodFrom 至\PeriodTo 止，\PeriodMonths}\\[4pt]
\hspace{2cm}{\fontsize{14pt}{22pt}\selectfont 指\ 導\ 教\ 授：\AdvisorName}
\end{flushleft}

\vfill

\begin{flushright}
{\fontsize{14pt}{22pt}\selectfont 處\ 理\ 方\ 式：\HandlingMethod}\hspace{1.5cm}\mbox{}\\[4pt]
{\fontsize{14pt}{22pt}\selectfont 執\ 行\ 單\ 位：\Affiliation}\hspace{1.5cm}\mbox{}\\[4pt]
{\fontsize{14pt}{22pt}\selectfont 中\ 華\ 民\ 國\ \ROCYear\ 年\ \ROCMonth\ 月\ \ROCDay\ 日}\hspace{1.5cm}\mbox{}
\end{flushright}

\vspace{1cm}

\end{center}
\end{titlepage}

<!-- ============================================================ -->
<!-- 內封（第二頁，無頁碼） -->
<!-- ============================================================ -->

\begin{titlepage}
\begin{center}

\vspace*{3cm}

{\fontsize{16pt}{24pt}\selectfont\bfseries \ProjectType}

\vspace{2.5cm}

{\fontsize{22pt}{30pt}\selectfont\bfseries \ProjectTitleZh}

\vspace{1cm}

{\fontsize{14pt}{20pt}\selectfont \ProjectId}

\vspace{4cm}

{\fontsize{14pt}{20pt}\selectfont 指導老師：\AdvisorName\ \ 老師}

\vspace{1cm}

{\fontsize{14pt}{20pt}\selectfont 專題學生：\StudentName}

\vfill

{\fontsize{14pt}{20pt}\selectfont 中\ 華\ 民\ 國\ \ROCYear\ 年\ \ROCMonth\ 月}

\vspace{1cm}

\end{center}
\end{titlepage}

<!-- ============================================================ -->
<!-- 摘要（羅馬數字頁碼 I, II, III ...） -->
<!-- 國科會大專生報告通常僅有中文摘要 -->
<!-- ============================================================ -->

\pagenumbering{Roman}
\pagestyle{frontmatter}

\begin{center}
{\Large\bfseries 摘要}
\end{center}

<請在此撰寫中文摘要，建議 500–800 字。摘要應包含：研究背景與動機、研究問題、所提方法、實驗結果與結論。>

\vspace{0.5cm}

\noindent\textbf{關鍵詞：<關鍵字1>、<關鍵字2>、<關鍵字3>、<關鍵字4>、<關鍵字5>}

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

<請在此撰寫研究背景。可引用文獻：[@example-conference]。>

## 研究動機 {#sec:intro-motivation}

<請說明研究動機與痛點觀察。>

## 研究目的 {#sec:intro-purpose}

<請條列本計畫的具體研究目的。>

## 研究範圍 {#sec:intro-scope}

<請界定研究對象、設備、材料與資料規模。>

## 研究流程 {#sec:intro-workflow}

<說明本計畫整體執行流程。可插入流程圖：>

<!--
範例：
![研究整體流程圖](images/workflow.png){#fig:workflow width=80%}
-->

# 文獻回顧 {#sec:literature}

## <主題一> {#sec:literature-topic1}

<請回顧第一個相關主題。>

## <主題二> {#sec:literature-topic2}

<請回顧第二個相關主題。>

# 研究方法 {#sec:method}

## 研究架構 {#sec:method-architecture}

<請說明整體研究架構。可插入系統架構圖：>

<!--
範例（精確控制圖片大小）：
\begin{figure}[!htbp]
\centering
\includegraphics[width=0.8\textwidth]{images/system.png}
\caption{系統架構圖}
\label{fig:system}
\end{figure}
-->

## 實驗設備 {#sec:method-equipment}

<請說明設備規格。可用表格呈現：>

<!--
範例：
\begin{table}[htbp]
\centering
\caption{設備技術規格}
\label{tab:equipment}
\small
\begin{tabular}{ll}
\hline
\textbf{規格項目} & \textbf{規格值} \\
\hline
最大尺寸 & 256 × 256 × 256 mm \\
最高速度 & 500 mm/s \\
\hline
\end{tabular}
\end{table}
-->

## 方法細節 {#sec:method-details}

<請說明方法的關鍵技術細節。如有公式：>

\begin{equation}
y = f(x; \theta) + \epsilon
\label{eq:example}
\end{equation}

公式 \ref{eq:example} 為示範公式。

# 實驗結果與分析 {#sec:results}

## 資料統計 {#sec:results-data}

<請呈現資料統計。>

## 主要結果 {#sec:results-main}

<請呈現主要實驗結果。>

## 討論 {#sec:results-discussion}

<請討論結果背後的意義與限制。>

# 結論與建議 {#sec:conclusion}

## 結論 {#sec:conclusion-summary}

<請總結本計畫主要研究成果。>

## 建議 {#sec:conclusion-future}

<請提出對後續研究的具體建議。>

<!-- ============================================================ -->
<!-- 參考文獻 -->
<!-- ============================================================ -->

\newpage
\printbibliography[title=參考文獻]

<!-- ============================================================ -->
<!-- 附錄（如有需要） -->
<!-- 國科會大專生報告常見附錄：實驗照片紀錄、設備設定截圖、原始數據 -->
<!-- ============================================================ -->

<!--
附錄章節範例（如不需要附錄請刪除以下整段）：

\newpage
\appendix
\renewcommand{\thesection}{附錄\ \Roman{section}}
\renewcommand{\thefigure}{附\arabic{section}-\arabic{figure}}
\renewcommand{\thetable}{附\arabic{section}-\arabic{table}}
\titleformat{\section}
  {\centering\Large\bfseries}
  {附錄\ \Roman{section}}{1em}{}

# 第一份附錄標題 {#sec:appendix-one}

<附錄內容>

# 第二份附錄標題 {#sec:appendix-two}

<附錄內容>
-->
