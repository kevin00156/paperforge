#!/usr/bin/env bash
# ============================================================
# PaperForge 環境健檢腳本 (Linux/macOS)
# ============================================================
# 檢查所有必要工具是否可用，並回報版本資訊。
# ============================================================

set -uo pipefail

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' CYAN='' NC=''
fi

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

check_pass() { echo -e "${GREEN}  ✓${NC} $*"; ((PASS_COUNT++)); }
check_warn() { echo -e "${YELLOW}  !${NC} $*"; ((WARN_COUNT++)); }
check_fail() { echo -e "${RED}  ✗${NC} $*"; ((FAIL_COUNT++)); }

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          PaperForge 環境健檢                                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}—— 核心工具 ——${NC}"

# Pandoc
if command -v pandoc &> /dev/null; then
    version=$(pandoc --version | head -n1)
    check_pass "Pandoc: $version"
else
    check_fail "Pandoc 未安裝"
fi

# XeLaTeX
if command -v xelatex &> /dev/null; then
    version=$(xelatex --version 2>/dev/null | head -n1 | sed 's/^[^0-9]*//')
    check_pass "XeLaTeX: $version"
else
    check_fail "XeLaTeX 未安裝（請安裝 TeX Live with texlive-xetex）"
fi

# biber
if command -v biber &> /dev/null; then
    version=$(biber --version 2>&1 | head -n1)
    check_pass "biber: $version"
else
    check_fail "biber 未安裝"
fi

# bibtex (fallback)
if command -v bibtex &> /dev/null; then
    check_pass "bibtex 可用（biber 的後備）"
else
    check_warn "bibtex 未安裝（biber 是主要工具，bibtex 為後備）"
fi

echo -e "\n${CYAN}—— LaTeX 套件 ——${NC}"

if command -v kpsewhich &> /dev/null; then
    packages=(xeCJK fontspec subcaption subfigure titlesec fancyhdr biblatex)
    for pkg in "${packages[@]}"; do
        if kpsewhich "$pkg.sty" &> /dev/null || kpsewhich "$pkg.cls" &> /dev/null; then
            check_pass "$pkg.sty 可用"
        else
            check_warn "$pkg.sty 不可用（XeLaTeX 編譯時會嘗試自動下載）"
        fi
    done
else
    check_warn "kpsewhich 不可用，無法檢查 LaTeX 套件"
fi

echo -e "\n${CYAN}—— CJK 字體 ——${NC}"

if command -v fc-list &> /dev/null; then
    if fc-list :lang=zh-tw | grep -qi "kai\|標楷體\|DFKai"; then
        check_pass "標楷體 (DFKai-SB / kai*) 可用"
    else
        check_warn "未偵測到標楷體"
    fi
    if fc-list :lang=zh-tw | grep -qi "Noto.*CJK.*TC\|Noto.*Serif.*CJK"; then
        check_pass "Noto CJK TC 可用（可作為標楷體 fallback）"
    else
        check_warn "未偵測到 Noto CJK TC"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if system_profiler SPFontsDataType 2>/dev/null | grep -qi "BiauKai\|標楷體"; then
        check_pass "macOS 標楷體可用"
    else
        check_warn "未偵測到 macOS 標楷體"
    fi
else
    check_warn "字體偵測工具不可用"
fi

echo -e "\n${CYAN}—— 可選工具 ——${NC}"

if command -v python3 &> /dev/null; then
    version=$(python3 --version)
    check_pass "Python: $version"
else
    check_warn "Python3 未安裝（僅圖表生成腳本需要）"
fi

if command -v uv &> /dev/null; then
    version=$(uv --version)
    check_pass "uv: $version"
else
    check_warn "uv 未安裝（pip 可作為替代）"
fi

if command -v git &> /dev/null; then
    version=$(git --version)
    check_pass "git: $version"
else
    check_warn "git 未安裝（版本控制建議使用）"
fi

# 監看模式工具
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v fswatch &> /dev/null; then
        check_pass "fswatch 可用（監看模式）"
    else
        check_warn "fswatch 未安裝（brew install fswatch 啟用監看模式）"
    fi
else
    if command -v inotifywait &> /dev/null; then
        check_pass "inotifywait 可用（監看模式）"
    else
        check_warn "inotifywait 未安裝（apt install inotify-tools 啟用監看模式）"
    fi
fi

echo -e "\n${CYAN}—— Skill 安裝狀態 ——${NC}"

if [[ -f "$HOME/.claude/skills/ncu-paper-writer/SKILL.md" ]]; then
    check_pass "ncu-paper-writer Skill 已安裝（使用者層級）"
elif [[ -f "$(pwd)/.claude/skills/ncu-paper-writer/SKILL.md" ]]; then
    check_pass "ncu-paper-writer Skill 已安裝（專案層級）"
else
    check_warn "ncu-paper-writer Skill 未安裝（執行 scripts/install-skill.sh）"
fi

# ============================================================
# 總結
# ============================================================
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "通過: ${GREEN}$PASS_COUNT${NC}  警告: ${YELLOW}$WARN_COUNT${NC}  失敗: ${RED}$FAIL_COUNT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "\n${RED}有必要工具未安裝。請執行 scripts/install.sh 進行完整安裝。${NC}"
    exit 1
elif [[ $WARN_COUNT -gt 0 ]]; then
    echo -e "\n${YELLOW}核心功能可用，但有部分可選工具未安裝。${NC}"
    exit 0
else
    echo -e "\n${GREEN}🎉 環境完整！可以開始撰寫論文了。${NC}"
    exit 0
fi
