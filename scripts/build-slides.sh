#!/usr/bin/env bash
# ============================================================
# PaperForge — Marp 簡報編譯腳本 (Linux/macOS)
# ============================================================
#
# 用法：
#   ./scripts/build-slides.sh [INPUT] [選項]
#
# 選項：
#   --pdf              輸出 PDF（預設）
#   --html             輸出 HTML
#   --watch            監看模式（搭配 --html / --pdf 使用）
#   --output DIR       輸出目錄（預設為輸入檔目錄）
#   --profile <name>   Profile 名稱（預設 slides-ncu，對應 profiles/<name>/）
#   --theme FILE       主題 CSS（覆寫 --profile 推導出的 theme.css）
#   --verbose          詳細輸出
#   -h, --help         說明
#
# ============================================================

set -euo pipefail

# --- 顏色 ---
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

# --- 預設參數 ---
INPUT=""
FORMAT="pdf"
WATCH=false
VERBOSE=false
OUTPUT=""
PROFILE="slides-ncu"
THEME=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- 解析參數 ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --pdf)     FORMAT="pdf"; shift ;;
        --html)    FORMAT="html"; shift ;;
        --watch)   WATCH=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --output)  OUTPUT="$2"; shift 2 ;;
        --profile) PROFILE="$2"; shift 2 ;;
        --theme)   THEME="$2"; shift 2 ;;
        -h|--help)
            sed -n '/^# 用法/,/^# ===/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        --*)
            log_error "未知選項: $1"
            exit 1 ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            else
                log_error "多餘參數: $1"
                exit 1
            fi
            shift ;;
    esac
done

# --- Profile 解析 ---
PROFILE_DIR="${REPO_ROOT}/profiles/${PROFILE}"
if [[ ! -d "$PROFILE_DIR" ]]; then
    log_error "找不到 profile：$PROFILE（預期目錄：$PROFILE_DIR）"
    exit 1
fi
if [[ -z "$THEME" ]]; then
    THEME="${PROFILE_DIR}/theme.css"
fi

# --- 預設輸入 ---
if [[ -z "$INPUT" ]]; then
    if [[ -f "slides.md" ]]; then
        INPUT="slides.md"
    else
        log_error "未指定輸入檔案，且當前目錄無 slides.md"
        exit 1
    fi
fi

if [[ ! -f "$INPUT" ]]; then
    log_error "找不到輸入檔案：$INPUT"
    exit 1
fi

if [[ ! -f "$THEME" ]]; then
    log_error "找不到主題檔：$THEME"
    exit 1
fi

# --- 路徑解析 ---
INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
SRC_DIR="$(dirname "$INPUT_ABS")"
BASENAME="$(basename "$INPUT_ABS" .md)"

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="$SRC_DIR"
fi
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"

OUTPUT_FILE="$OUTPUT/$BASENAME.$FORMAT"

# --- 工具偵測：marp-cli 或 npx ---
MARP_CMD=""
if command -v marp >/dev/null 2>&1; then
    MARP_CMD="marp"
elif command -v npx >/dev/null 2>&1; then
    MARP_CMD="npx --yes @marp-team/marp-cli"
    log_warn "未找到 marp 全域指令，使用 npx 即時呼叫（首次會下載）"
else
    log_error "找不到 marp 或 npx。請執行 scripts/install-marp.sh 或 npm i -g @marp-team/marp-cli"
    exit 1
fi

# --- 編譯 ---
log_info "輸入：$INPUT_ABS"
log_info "輸出：$OUTPUT_FILE"
log_info "Profile：$PROFILE"
log_info "主題：$THEME"
log_info "格式：$FORMAT"

MARP_ARGS=(
    "$INPUT_ABS"
    "--theme-set" "$THEME"
    "--output" "$OUTPUT_FILE"
    "--allow-local-files"
    "--no-stdin"
)

case "$FORMAT" in
    pdf)  MARP_ARGS+=("--pdf") ;;
    html) MARP_ARGS+=("--html") ;;
esac

if [[ "$WATCH" == "true" ]]; then
    MARP_ARGS+=("--watch")
    log_info "監看模式：Ctrl+C 結束"
fi

if [[ "$VERBOSE" == "true" ]]; then
    log_info "執行：$MARP_CMD ${MARP_ARGS[*]}"
fi

# shellcheck disable=SC2086
$MARP_CMD "${MARP_ARGS[@]}"

if [[ "$WATCH" == "false" ]]; then
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        log_error "編譯失敗：找不到輸出檔 $OUTPUT_FILE"
        exit 1
    fi
    size=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE")
    log_ok "編譯完成：$OUTPUT_FILE ($size bytes)"
fi
