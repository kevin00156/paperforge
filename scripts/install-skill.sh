#!/usr/bin/env bash
# ============================================================
# 安裝 Claude Code Skills（掃描 profiles/*/skill/ 與 skill/*/ 兩個來源）
# ============================================================
#
# 用法：
#   bash scripts/install-skill.sh [選項]
#
# 選項：
#   --user            安裝到 ~/.claude/skills/（預設，跨專案共用）
#   --project         安裝到 ./.claude/skills/（僅當前專案）
#   --force           已存在則直接覆蓋（不備份）
#   --only NAME       僅安裝指定 skill name（依 SKILL.md frontmatter 比對）
#   -h, --help        說明
#
# 安裝目錄名稱沿用 SKILL.md frontmatter 的 name 欄位。
# 來源範圍：
#   - profiles/<name>/skill/SKILL.md（論文 profile 自帶的 skill）
#   - skill/<name>/SKILL.md（不屬於任何 profile 的 skill，例：ncu-slides-writer）
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

# --- 參數 ---
SCOPE="user"
FORCE=false
ONLY=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)    SCOPE="user"; shift ;;
        --project) SCOPE="project"; shift ;;
        --force)   FORCE=true; shift ;;
        --only)    ONLY="$2"; shift 2 ;;
        -h|--help)
            sed -n '/^# 用法/,/^# ===/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) log_error "未知選項: $1"; exit 1 ;;
    esac
done

# --- 路徑 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

case "$SCOPE" in
    user)    TARGET_BASE="$HOME/.claude/skills" ;;
    project) TARGET_BASE="$(pwd)/.claude/skills" ;;
esac

log_info "目標：$TARGET_BASE (scope=$SCOPE)"

# --- 從 SKILL.md frontmatter 讀取 name 欄位 ---
get_skill_name() {
    local skill_md="$1"
    grep -E '^name:' "$skill_md" | head -n1 | sed -E 's/^name:[[:space:]]*//'
}

# --- 安裝單一 skill ---
install_one() {
    local source_dir="$1"

    local skill_md="$source_dir/SKILL.md"
    if [[ ! -f "$skill_md" ]]; then
        log_warn "$source_dir 缺少 SKILL.md，跳過"
        return 1
    fi

    local skill_name
    skill_name="$(get_skill_name "$skill_md")"
    if [[ -z "$skill_name" ]]; then
        log_warn "$skill_md 無法讀取 frontmatter 的 name 欄位，跳過"
        return 1
    fi

    if [[ -n "$ONLY" && "$skill_name" != "$ONLY" ]]; then
        return 1
    fi

    local target_dir="$TARGET_BASE/$skill_name"

    if [[ -e "$target_dir" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_warn "$skill_name 已存在，強制覆蓋"
            rm -rf "$target_dir"
        else
            local ts
            ts="$(date +%Y%m%d-%H%M%S)"
            local backup_dir="${target_dir}.bak.${ts}"
            log_warn "$skill_name 已存在，備份至：$backup_dir"
            mv "$target_dir" "$backup_dir"
        fi
    fi

    mkdir -p "$TARGET_BASE"
    cp -r "$source_dir" "$target_dir"

    if [[ -f "$target_dir/SKILL.md" ]]; then
        log_ok "$skill_name 安裝成功（來源：$source_dir）"
        return 0
    else
        log_error "$skill_name 安裝失敗"
        return 1
    fi
}

# --- 收集所有來源：profiles/*/skill/ 與 skill/*/ ---
sources=()
if [[ -d "$REPO_ROOT/profiles" ]]; then
    for d in "$REPO_ROOT/profiles"/*/; do
        [[ -d "$d/skill" ]] && sources+=("$d/skill")
    done
fi
if [[ -d "$REPO_ROOT/skill" ]]; then
    for d in "$REPO_ROOT/skill"/*/; do
        [[ -d "$d" ]] && sources+=("${d%/}")
    done
fi

if [[ ${#sources[@]} -eq 0 ]]; then
    log_error "找不到任何 skill 來源（profiles/*/skill/ 或 skill/*/）"
    exit 1
fi

# --- 主流程 ---
installed=0
for src in "${sources[@]}"; do
    if install_one "$src"; then
        installed=$((installed + 1))
    fi
done

if [[ $installed -eq 0 ]]; then
    if [[ -n "$ONLY" ]]; then
        log_error "找不到 skill：$ONLY"
    else
        log_error "沒有任何 skill 被安裝"
    fi
    exit 1
fi

log_info "在 Claude Code 中執行任務時將自動載入這些 skill"
if [[ "$SCOPE" == "user" ]]; then
    log_info "（跨專案可用，目前安裝在使用者層級）"
else
    log_info "（僅當前專案可用）"
fi
