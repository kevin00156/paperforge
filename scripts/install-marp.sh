#!/usr/bin/env bash
# ============================================================
# 安裝 @marp-team/marp-cli（Marp 簡報編譯工具）
# ============================================================
#
# 前置需求：Node.js + npm
#   - 若未偵測到 Node.js，會嘗試以系統 package manager 自動安裝
#     (apt / dnf / pacman / brew)，預設會詢問，加 --auto 跳過詢問
#
# 用法：
#   bash scripts/install-marp.sh              # 互動式
#   bash scripts/install-marp.sh --auto       # 自動安裝 Node.js
#
# ============================================================

set -euo pipefail

AUTO=0
for arg in "$@"; do
    case "$arg" in
        --auto|-y) AUTO=1 ;;
        -h|--help)
            sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
    BLUE='\033[0;34m'; NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' NC=''
fi

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 偵測可用的 package manager 並回傳安裝指令
detect_node_install_cmd() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "sudo apt-get install -y nodejs npm"
    elif command -v dnf >/dev/null 2>&1; then
        echo "sudo dnf install -y nodejs npm"
    elif command -v pacman >/dev/null 2>&1; then
        echo "sudo pacman -S --noconfirm nodejs npm"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew install node"
    else
        echo ""
    fi
}

# --- 偵測 Node.js / npm，缺失時嘗試以 package manager 自動安裝 ---
if ! command -v npm >/dev/null 2>&1; then
    log_warn "找不到 Node.js / npm"

    INSTALL_CMD="$(detect_node_install_cmd)"
    if [[ -z "$INSTALL_CMD" ]]; then
        log_error "找不到可用的 package manager (apt / dnf / pacman / brew)"
        log_info "請手動安裝 Node.js 18+，從 https://nodejs.org 下載 LTS 版本"
        exit 1
    fi

    log_info "建議安裝指令：$INSTALL_CMD"

    confirm="y"
    if [[ "$AUTO" != "1" ]]; then
        printf "要執行嗎？(Y/n) "
        read -r confirm
        confirm="${confirm:-y}"
    fi

    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        log_info "已取消。請手動執行：$INSTALL_CMD"
        exit 1
    fi

    if ! eval "$INSTALL_CMD"; then
        log_error "Node.js 安裝失敗"
        exit 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log_error "安裝完成但 npm 仍不可見，請重開 shell 後再執行本腳本"
        exit 1
    fi
    log_ok "Node.js 安裝成功"
fi

NODE_VERSION="$(node --version 2>/dev/null || echo unknown)"
log_info "Node.js: $NODE_VERSION"
log_info "npm:     $(npm --version)"

# --- 已安裝檢查 ---
if command -v marp >/dev/null 2>&1; then
    log_ok "marp-cli 已安裝：$(marp --version 2>&1 | head -n1)"
    exit 0
fi

# --- 安裝 ---
log_info "安裝 @marp-team/marp-cli（全域）"
if npm install -g @marp-team/marp-cli; then
    log_ok "marp-cli 安裝成功：$(marp --version 2>&1 | head -n1)"
else
    log_error "marp-cli 安裝失敗"
    log_info "備用方案：可直接用 npx 呼叫（build-slides.sh 已支援 npx fallback）"
    log_info "  npx @marp-team/marp-cli slides.md --pdf"
    exit 1
fi

# --- Chromium 提示 ---
log_info ""
log_info "首次輸出 PDF 時 Marp 會下載 Chromium（約 200 MB）"
log_info "或可指定既有的 Chrome/Chromium：export CHROME_PATH=/usr/bin/chromium"
