---
profile: thesis-ncu

# === NCU 論文最小範例 ===
# 此範例僅含必要結構，用於驗證編譯環境。
# 注意：CI 環境（GitHub Actions Ubuntu runner）沒有「標楷體」，
# 因此 CI 中使用 Noto Serif CJK TC。本機編譯請改回標楷體。

thesis-title-zh: "範例論文：最小可編譯結構"
thesis-title-en: "Example Thesis: Minimal Compilable Structure"
department: "範例學系"
program: "範例學程碩士班"
degree: "碩士論文"
student: "範例學生"
advisor: "範例教授 博士"
year: "115"
month: "5"

subfigure: true

geometry: "top=2.5cm, bottom=2.5cm, left=3cm, right=2cm"
papersize: a4

# CI / 跨平台用免費字體；本機若要符合 NCU 嚴格規範請改成
#   mainfont: "Times New Roman"
#   CJKmainfont: "標楷體"
# Latin Modern Roman：lmodern 套件提供，MiKTeX / TeX Live 都預裝，
# 不需網路下載也能跑（不像 TeX Gyre Termes 在乾淨 MiKTeX 要先下載）
mainfont: "Latin Modern Roman"
CJKmainfont: "Noto Serif CJK TC"
fontsize: 12pt
linestretch: 1.5

bibliography: references.bib
biblatex: true
biblio-style: ieee
suppress-bibliography: true

numbersections: true
secnumdepth: 4
toc: false

# 章節格式、圖表標題、頁碼、超連結等 LaTeX 設定皆由 profile thesis-ncu 的
# template.latex 提供，使用者複製後不需在此重抄；本範例僅保留資料欄位。
---

<!-- ============================================================ -->
<!-- 封面頁 -->
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
<!-- 摘要 -->
<!-- ============================================================ -->

\pagenumbering{arabic}
\pagestyle{mainmatter}

\begin{center}
{\Large\bfseries 摘要}
\end{center}

本文為 PaperForge 工作流的最小可編譯範例。本範例展示了完整的論文編譯流程，包括 Pandoc Markdown 轉 LaTeX、XeLaTeX 編譯、biber 處理參考文獻、以及最終的 PDF 生成。

\vspace{0.5cm}

\noindent\textbf{關鍵字：Pandoc、Markdown、LaTeX、論文寫作}

\newpage

<!-- ============================================================ -->
<!-- 正文 -->
<!-- ============================================================ -->

# 緒論 {#sec:intro}

## 範例段落 {#sec:intro-example}

本文展示了 PaperForge 的基本編譯能力。引用範例：He 等人[@he2016resnet]提出殘差學習。

本範例涵蓋的章節結構請見 \ref{sec:method} 章節。

# 方法 {#sec:method}

## 範例公式 {#sec:method-formula}

公式 \ref{eq:simple} 展示了基本範例：

\begin{equation}
y = ax + b
\label{eq:simple}
\end{equation}

# 結論 {#sec:conclusion}

若你看到這份 PDF 完整顯示中文、頁碼、引用，代表 PaperForge 環境已正確安裝。

<!-- 參考文獻 -->
\newpage
\printbibliography[title=參考文獻]
