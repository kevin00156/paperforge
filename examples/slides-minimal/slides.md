---
profile: slides-ncu
marp: true
theme: ncu
paginate: true
footer: "PaperForge · 口試簡報範例"
math: katex
title: "Marp 最小可編譯範例"
description: "驗證 Marp + NCU 主題編譯流程"
---

<!-- _class: lead -->

# Marp 最小可編譯範例

## Minimal Compilable Slides Example

---

**研究生**：範例學生
**指導教授**：範例教授 博士

範例學系 · 範例學程碩士班
中華民國 115 年 5 月

---

<!-- _class: lead -->

# 大綱

1. 範例動機
2. 範例方法
3. 範例結果
4. 結論

---

<!-- _class: section-divider -->

# 1 · 範例動機

---

## 問題定義

本範例用於驗證 PaperForge 的 Marp 編譯流程：

- **驗證 PDF 輸出**：marp-cli 能產生 > 100 KB 的 PDF
- **驗證主題套用**：`profiles/slides-ncu/theme.css` 正確載入
- **驗證 CJK 渲染**：中文字型 fallback 正常

---

<!-- _class: section-divider -->

# 2 · 範例方法

---

## 系統架構

<div class="columns">

<div>

### 編譯流程

1. Markdown 原始檔
2. marp-cli 處理
3. Chromium 渲染
4. PDF 輸出

</div>

<div>

### 主題套用

- frontmatter 指定 `theme: ncu`
- 命令列 `--theme-set`
- CSS 從 `profiles/slides-ncu/theme.css` 載入

</div>

</div>

---

## 數學公式範例

公式 $E = mc^2$ 是行內示範。獨立公式如下：

$$
\mathcal{L}_{\text{total}} = \mathcal{L}_{\text{task}} + \lambda \cdot \mathcal{L}_{\text{reg}}
$$

- $\mathcal{L}_{\text{task}}$：任務損失
- $\lambda$：權衡係數

---

<!-- _class: section-divider -->

# 3 · 範例結果

---

## 編譯結果

| 項目 | 預期值 |
|------|--------|
| PDF 檔案大小 | > 100 KB |
| 頁數 | ≥ 8 頁 |
| CJK 渲染 | 正常 |
| 主題色 | 海軍藍 `#003366` |

---

<!-- _class: lead -->

# 4 · 結論

若你看到這份 PDF，
**代表 Marp 工作流已正確安裝。**

---

<!-- _class: lead -->

# 敬請指教

**Q & A**
