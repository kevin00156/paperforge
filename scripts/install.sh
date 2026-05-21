#!/usr/bin/env bash
# ============================================================
# PaperForge — Linux/macOS 一鍵安裝腳本
# ============================================================
#
# 安裝項目：
#   1. Pandoc
#   2. TeX Live (含 XeLaTeX + xeCJK + biber)
#   3. CJK 字體（Noto CJK 作為 fallback；標楷體需手動下載）
#   4. Python + uv（可選，用於繪圖腳本）
#   5. Claude Code Skills（各 profile 內附，例：~/.claude/skills/ncu-paper-writer/）
#   6. 編譯測試（examples/minimal）
#
# 用法：
#   bash scripts/install.sh [選項]
#
# 選項：
#   --dry-run         僅顯示將執行的指令，不實際安裝
#   --skip-tex        跳過 TeX Live 安裝
#   --skip-python     跳過 Python 環境設置
#   --skip-skill      跳過 Skill 安裝
#   --skip-test       跳過編譯測試
#   --skill-only      僅安裝 Skill
#   -h, --help        顯示說明
#
# ============================================================

set -uo pipefail

# --- 顏色輸出 ---
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

log_info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
log_step()    { echo -e "\n${CYAN}===> $*${NC}"; }
log_ok()      { echo -e "${GREEN}[PASS]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC}    $*" >&2; }

# --- 全域狀態 ---
DRY_RUN=false
SKIP_TEX=false
SKIP_PYTHON=false
SKIP_SKILL=false
SKIP_TEST=false
SKILL_ONLY=false
INSTALL_LOG="$(pwd)/install.log"
declare -a REPORT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --skip-tex) SKIP_TEX=true; shift ;;
        --skip-python) SKIP_PYTHON=true; shift ;;
        --skip-skill) SKIP_SKILL=true; shift ;;
        --skip-test) SKIP_TEST=true; shift ;;
        --skill-only) SKILL_ONLY=true; shift ;;
        -h|--help)
            sed -n '/^# 用法/,/^# ===/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) log_error "未知選項: $1"; exit 1 ;;
    esac
done

if [[ "$SKILL_ONLY" == "true" ]]; then
    SKIP_TEX=true; SKIP_PYTHON=true; SKIP_TEST=true
fi

# --- run helper ---
run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
        return 0
    fi
    log_info "執行：$*"
    "$@"
}

record() {
    local status="$1"
    local label="$2"
    REPORT+=("$status|$label")
    case "$status" in
        PASS) log_ok "$label" ;;
        WARN) log_warn "$label" ;;
        FAIL) log_error "$label" ;;
    esac
}

# --- Distro 偵測 ---
detect_distro() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

DISTRO="$(detect_distro)"
log_step "偵測作業系統：$DISTRO"

# --- 必須的指令 ---
need_cmd() {
    command -v "$1" &> /dev/null
}

# ============================================================
# Step 1: Pandoc
# ============================================================
install_pandoc() {
    log_step "Step 1/6: 安裝 Pandoc"
    if need_cmd pandoc; then
        local version
        version=$(pandoc --version | head -n1)
        record PASS "Pandoc 已安裝：$version"
        return 0
    fi

    case "$DISTRO" in
        ubuntu|debian)
            run sudo apt update && run sudo apt install -y pandoc
            ;;
        fedora|rhel|centos)
            run sudo dnf install -y pandoc
            ;;
        arch|manjaro)
            run sudo pacman -S --noconfirm pandoc
            ;;
        macos)
            if ! need_cmd brew; then
                record FAIL "macOS 需要 Homebrew。請先安裝：https://brew.sh"
                return 1
            fi
            run brew install pandoc
            ;;
        *)
            record FAIL "未知 distro，請手動安裝 pandoc：https://pandoc.org/installing.html"
            return 1
            ;;
    esac

    if need_cmd pandoc; then
        record PASS "Pandoc 安裝成功"
    else
        record FAIL "Pandoc 安裝失敗"
    fi
}

# ============================================================
# Step 2: TeX Live (XeLaTeX + xeCJK + biber)
# ============================================================
install_tex() {
    log_step "Step 2/6: 安裝 TeX Live"
    if [[ "$SKIP_TEX" == "true" ]]; then
        record WARN "已跳過 TeX Live 安裝（--skip-tex）"
        return 0
    fi

    if need_cmd xelatex && need_cmd biber; then
        record PASS "TeX Live 已安裝（xelatex + biber 可用）"
        return 0
    fi

    log_warn "TeX Live 安裝會下載 1-4 GB，預計需要 10-30 分鐘。"

    case "$DISTRO" in
        ubuntu|debian)
            run sudo apt update
            run sudo apt install -y \
                texlive-xetex \
                texlive-lang-cjk \
                texlive-fonts-recommended \
                texlive-fonts-extra \
                texlive-bibtex-extra \
                texlive-publishers \
                biber \
                fonts-noto-cjk \
                fonts-noto-cjk-extra
            ;;
        fedora|rhel|centos)
            run sudo dnf install -y \
                texlive-scheme-medium \
                texlive-xecjk \
                texlive-biblatex \
                texlive-biblatex-ieee \
                biber \
                google-noto-sans-cjk-tc-fonts \
                google-noto-serif-cjk-tc-fonts
            ;;
        arch|manjaro)
            run sudo pacman -S --noconfirm \
                texlive-most \
                texlive-langchinese \
                biber \
                noto-fonts-cjk
            ;;
        macos)
            if ! need_cmd brew; then
                record FAIL "macOS 需要 Homebrew"
                return 1
            fi
            log_warn "在 macOS 上將安裝 MacTeX（4GB+）"
            run brew install --cask mactex-no-gui
            run brew install --cask font-noto-sans-cjk font-noto-serif-cjk
            ;;
        *)
            record FAIL "未知 distro，請手動安裝 TeX Live"
            return 1
            ;;
    esac

    if need_cmd xelatex; then
        record PASS "TeX Live 安裝成功"
    else
        record FAIL "TeX Live 安裝失敗，請檢查錯誤訊息"
        return 1
    fi
}

# ============================================================
# Step 3: 字體偵測
# ============================================================
check_fonts() {
    log_step "Step 3/6: 檢查 CJK 字體"
    if [[ "$SKIP_TEX" == "true" ]] && [[ "$SKILL_ONLY" == "true" ]]; then
        record WARN "已跳過字體檢查"
        return 0
    fi

    if ! need_cmd fc-list && [[ "$DISTRO" != "macos" ]]; then
        record WARN "fc-list 不可用，無法檢查字體"
        return 0
    fi

    local has_kai=false
    local has_noto=false

    if [[ "$DISTRO" == "macos" ]]; then
        if system_profiler SPFontsDataType 2>/dev/null | grep -qi "BiauKai\|標楷體\|DFKai"; then
            has_kai=true
        fi
    elif need_cmd fc-list; then
        if fc-list :lang=zh-tw | grep -qi "kai\|標楷體\|DFKai"; then
            has_kai=true
        fi
        if fc-list :lang=zh-tw | grep -qi "Noto.*CJK.*TC"; then
            has_noto=true
        fi
    fi

    if [[ "$has_kai" == "true" ]]; then
        record PASS "已安裝標楷體（符合 NCU 嚴格規範）"
    elif [[ "$has_noto" == "true" ]]; then
        record WARN "未安裝標楷體，但已有 Noto Serif CJK TC。請於 paper.md YAML 將 CJKmainfont 改為 \"Noto Serif CJK TC\""
    else
        record WARN "未偵測到任何 CJK 字體。請參考 docs/05-troubleshooting.md 安裝。"
    fi
}

# ============================================================
# Step 4: Python + uv
# ============================================================
install_python() {
    log_step "Step 4/6: 設置 Python 環境"
    if [[ "$SKIP_PYTHON" == "true" ]]; then
        record WARN "已跳過 Python 環境設置（--skip-python）"
        return 0
    fi

    if ! need_cmd python3; then
        case "$DISTRO" in
            ubuntu|debian) run sudo apt install -y python3 python3-pip ;;
            fedora|rhel|centos) run sudo dnf install -y python3 python3-pip ;;
            arch|manjaro) run sudo pacman -S --noconfirm python python-pip ;;
            macos) run brew install python ;;
        esac
    fi

    if ! need_cmd python3; then
        record FAIL "Python 安裝失敗"
        return 1
    fi

    if ! need_cmd uv; then
        log_info "安裝 uv（Python 套件管理工具）"
        run bash -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
        export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
    fi

    if need_cmd uv; then
        record PASS "uv 可用：$(uv --version)"
    else
        record WARN "uv 安裝失敗，可改用 pip"
    fi
}

# ============================================================
# Step 5: Claude Code Skill
# ============================================================
install_skill() {
    log_step "Step 5/6: 安裝 Claude Code Skill"
    if [[ "$SKIP_SKILL" == "true" ]]; then
        record WARN "已跳過 Skill 安裝（--skip-skill）"
        return 0
    fi

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local install_skill_script="$script_dir/install-skill.sh"

    if [[ ! -f "$install_skill_script" ]]; then
        record FAIL "找不到 install-skill.sh"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} bash $install_skill_script"
        return 0
    fi

    if bash "$install_skill_script"; then
        record PASS "Skill 安裝成功"
    else
        record FAIL "Skill 安裝失敗"
    fi
}

# ============================================================
# Step 6: 編譯測試
# ============================================================
test_build() {
    log_step "Step 6/6: 編譯測試（examples/minimal）"
    if [[ "$SKIP_TEST" == "true" ]]; then
        record WARN "已跳過編譯測試（--skip-test）"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} ./scripts/build.sh examples/minimal/paper.md"
        return 0
    fi

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if [[ ! -f "$script_dir/examples/minimal/paper.md" ]]; then
        record WARN "找不到 examples/minimal/paper.md，跳過測試"
        return 0
    fi

    if bash "$script_dir/scripts/build.sh" "$script_dir/examples/minimal/paper.md"; then
        local pdf_path="$script_dir/examples/minimal/paper.pdf"
        if [[ -f "$pdf_path" ]]; then
            local size
            size=$(stat -c%s "$pdf_path" 2>/dev/null || stat -f%z "$pdf_path")
            if (( size > 10240 )); then
                record PASS "編譯測試成功：$pdf_path ($size bytes)"
            else
                record WARN "PDF 產生但檔案過小（$size bytes），可能有問題"
            fi
        else
            record FAIL "編譯返回成功但找不到 PDF"
        fi
    else
        record FAIL "編譯測試失敗"
    fi
}

# ============================================================
# 主流程
# ============================================================
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          PaperForge 安裝腳本 (Linux/macOS)                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY-RUN 模式，僅顯示將執行的指令"
fi

install_pandoc
install_tex
check_fonts
install_python
install_skill
test_build

# ============================================================
# 報告
# ============================================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                        安裝報告                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
for entry in "${REPORT[@]}"; do
    status="${entry%%|*}"
    label="${entry#*|}"
    case "$status" in
        PASS) echo -e "${GREEN}  ✓${NC} $label"; ((PASS_COUNT++)) ;;
        WARN) echo -e "${YELLOW}  !${NC} $label"; ((WARN_COUNT++)) ;;
        FAIL) echo -e "${RED}  ✗${NC} $label"; ((FAIL_COUNT++)) ;;
    esac
done

echo ""
echo -e "通過: ${GREEN}$PASS_COUNT${NC}   警告: ${YELLOW}$WARN_COUNT${NC}   失敗: ${RED}$FAIL_COUNT${NC}"
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}安裝過程有失敗項目，請檢視上方訊息。${NC}"
    echo -e "完整記錄：$INSTALL_LOG"
    exit 1
fi

echo -e "${GREEN}🎉 安裝完成！${NC}"
echo ""
echo "下一步："
echo "  1. 複製論文骨架（選一個 profile）："
echo "       cp -r profiles/thesis-ncu/skeleton/ my-thesis/    # 國立中央大學"
echo "       cp -r profiles/thesis-ccu/skeleton/ my-thesis/    # 國立中正大學"
echo "  2. 編輯 my-thesis/paper.md 的 YAML metadata"
echo "  3. 設置 Zotero：見 docs/03-zotero-setup.md"
echo "  4. 編譯論文：./scripts/build.sh my-thesis/paper.md --profile thesis-ncu  # 或 thesis-ccu"
