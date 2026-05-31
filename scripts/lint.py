#!/usr/bin/env python3
"""PaperForge lint — 單一真相來源的格式檢查器。

設計原則:規則只寫一份,由三個入口共用,避免 bash/PowerShell/CI 三處抄寫漂移:
  • build.sh / build.ps1  編譯時呼叫(warn-only,不擋編譯)
  • .github/workflows/lint.yml  CI 用 --ci 跑全套(error 才 fail)
  • 開發者本機 / pre-commit  直接 lint.py <file>

用法:
  lint.py <file.md> [<file2.md> ...]   檢查指定檔案(build 整合用)
  lint.py --ci                          跑 CI 全套(SKILL frontmatter + 所有 skeleton/examples/marp)
  lint.py --strict                      警告也視為失敗

嚴重度:
  error  會破壞 PDF 或違反硬規範(缺錨點、缺字引用、缺圖、全形破折號、marp 缺 theme/超頁、SKILL 缺欄位)
  warn   品質提醒,不擋編譯(孤兒 \\label、未引用的 bib 條目)

Exit code: 0 乾淨;1 有 error(或 --strict 下有任何 warn)。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

MAX_SLIDE_PAGES = 35

# pandoc-crossref 的交叉參照命名空間(@fig:x / @sec:x / @tbl:x ...),不是文獻 key,不可當引用檢查
CROSSREF_PREFIXES = {"fig", "tbl", "sec", "eq", "lst", "subfig"}

# --- 顏色(僅在 tty 輸出) ---
if sys.stderr.isatty():
    C_RED, C_YEL, C_GRN, C_NC = "\033[0;31m", "\033[0;33m", "\033[0;32m", "\033[0m"
else:
    C_RED = C_YEL = C_GRN = C_NC = ""


class Finding:
    __slots__ = ("severity", "file", "line", "msg")

    def __init__(self, severity: str, file: str, line: int, msg: str):
        self.severity = severity  # "error" | "warn"
        self.file = file
        self.line = line
        self.msg = msg


def err(file, line, msg):
    return Finding("error", str(file), line, msg)


def warn(file, line, msg):
    return Finding("warn", str(file), line, msg)


# ============================================================
# 共用解析
# ============================================================

def split_frontmatter(lines: list[str]) -> tuple[dict, int]:
    """回傳 (frontmatter dict, frontmatter 結束的行號 1-based)。

    無 frontmatter 時回傳 ({}, 0)。只做淺層 key: value 解析,夠用於 profile/marp/theme/bibliography。
    """
    if not lines or lines[0].strip() != "---":
        return {}, 0
    fm: dict[str, str] = {}
    for i, line in enumerate(lines[1:], start=2):
        if line.strip() == "---":
            return fm, i
        m = re.match(r"^([A-Za-z][A-Za-z0-9_-]*)\s*:\s*(.*)$", line)
        if m:
            fm[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return fm, 0  # 沒有收尾 --- 視為無 frontmatter


def iter_body(lines: list[str], fm_end: int):
    """逐行產生正文 (line_no, text),跳過 YAML frontmatter / code block / HTML 註解行。"""
    in_code = False
    for i, line in enumerate(lines, start=1):
        if i <= fm_end:
            continue
        stripped = line.strip()
        if stripped.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if line.lstrip().startswith("<!--"):
            continue
        yield i, line


# ============================================================
# 規則
# ============================================================

def check_em_dash(path: Path, lines: list[str], fm_end: int) -> list[Finding]:
    out = []
    for i, line in iter_body(lines, fm_end):
        if line.lstrip().startswith("%"):  # LaTeX 註解
            continue
        if "——" in line:
            out.append(err(path, i, "禁用全形破折號「——」"))
    return out


def check_anchors(path: Path, lines: list[str], fm_end: int) -> list[Finding]:
    out = []
    for i, line in iter_body(lines, fm_end):
        if re.match(r"^#{1,4}\s+\S", line) and "{#sec:" not in line:
            out.append(err(path, i, f"標題缺章節錨點 {{#sec:...}}:{line.strip()}"))
    return out


def check_citations(path: Path, fm: dict, lines: list[str], fm_end: int) -> list[Finding]:
    """[@key] 引用的 key 必須存在於 .bib,否則 biber 默默吞掉、PDF 出現粗體 ??。"""
    bib = resolve_bib(path, fm)
    if bib is None:
        return []  # 無 bib 檔則略過(可能是不需引用的文件)
    defined = parse_bib_keys(bib)
    out, used = [], set()
    for i, line in iter_body(lines, fm_end):
        line = re.sub(r"`[^`]*`", "", line)  # 去掉行內 code span，避免把 `foo@bar`、`.bbl` 等當成引用
        for m in re.finditer(r"(?<![A-Za-z0-9])@([A-Za-z0-9][\w:.#$%&+?<>~/-]*)", line):
            key = m.group(1)
            if key.split(":", 1)[0] in CROSSREF_PREFIXES:
                continue  # 交叉參照,非文獻引用
            used.add(key)
            if key not in defined:
                out.append(err(path, i, f"引用 [@{key}] 不存在於 {bib.name}"))
    # 未被引用的 bib 條目(warn)
    for key in sorted(defined - used):
        out.append(warn(bib, 0, f"bib 條目 '{key}' 從未被引用(死引用)"))
    return out


def check_images(path: Path, lines: list[str], fm_end: int) -> list[Finding]:
    """Markdown ![](path) 與 LaTeX \\includegraphics{path} 的檔案必須存在。"""
    out = []
    base = path.parent
    pat_md = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
    pat_tex = re.compile(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}")
    for i, line in iter_body(lines, fm_end):
        for m in list(pat_md.finditer(line)) + list(pat_tex.finditer(line)):
            ref = m.group(1).strip().split()[0].strip('"')  # 去掉 markdown title 與引號
            if ref.startswith(("http://", "https://", "data:")):
                continue
            if not (base / ref).exists():
                out.append(err(path, i, f"圖片不存在:{ref}"))
    return out


def check_orphan_labels(path: Path, lines: list[str], fm_end: int) -> list[Finding]:
    """\\label{x} 沒有任何 \\ref/\\eqref/\\autoref/\\pageref{x} 對應 → warn。"""
    labels: dict[str, int] = {}
    refs: set[str] = set()
    for i, line in iter_body(lines, fm_end):
        for m in re.finditer(r"\\label\{([^}]+)\}", line):
            labels.setdefault(m.group(1), i)
        for m in re.finditer(r"\\(?:auto|page|eq|c|C)?ref\{([^}]+)\}", line):
            for part in m.group(1).split(","):
                refs.add(part.strip())
    return [warn(path, ln, f"\\label{{{name}}} 沒有對應的 \\ref")
            for name, ln in labels.items() if name not in refs]


def count_slides(lines: list[str], fm_end: int) -> int:
    """Marp 分頁:正文中行首 --- 的數量 + 1(首頁不需 ---)。"""
    count = 0
    for i, line in enumerate(lines, start=1):
        if i <= fm_end:
            continue
        if line.strip() == "---":
            count += 1
    return count + 1


# ============================================================
# bib 工具
# ============================================================

def resolve_bib(md_path: Path, fm: dict) -> Path | None:
    cands = []
    if fm.get("bibliography"):
        cands.append(md_path.parent / fm["bibliography"])
    cands.append(md_path.parent / "references.bib")
    for c in cands:
        if c.exists():
            return c
    return None


def parse_bib_keys(bib: Path) -> set[str]:
    text = bib.read_text(encoding="utf-8", errors="replace")
    return set(re.findall(r"@\w+\s*\{\s*([^,\s]+)", text))


# ============================================================
# 檔案分派
# ============================================================

def lint_md(path: Path) -> list[Finding]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    fm, fm_end = split_frontmatter(lines)
    out = check_em_dash(path, lines, fm_end)
    if str(fm.get("marp", "")).lower() == "true":
        # 簡報
        if not fm.get("theme"):
            out.append(err(path, 1, "marp frontmatter 缺少 theme:"))
        pages = count_slides(lines, fm_end)
        if pages > MAX_SLIDE_PAGES:
            out.append(err(path, 1, f"簡報共 {pages} 頁,超過上限 {MAX_SLIDE_PAGES} 頁"))
    else:
        # 論文 / 報告
        out += check_anchors(path, lines, fm_end)
        out += check_citations(path, fm, lines, fm_end)
        out += check_images(path, lines, fm_end)
        out += check_orphan_labels(path, lines, fm_end)
    return out


def lint_skill(path: Path) -> list[Finding]:
    text = path.read_text(encoding="utf-8", errors="replace")
    out = []
    if not re.search(r"^name:", text, re.M):
        out.append(err(path, 1, "SKILL frontmatter 缺少 name:"))
    if not re.search(r"^description:", text, re.M):
        out.append(err(path, 1, "SKILL frontmatter 缺少 description:"))
    return out


def collect_ci_targets(repo: Path) -> tuple[list[Path], list[Path], list[Path]]:
    """CI 模式要掃的目標:SKILL、論文檔(examples + skeleton)、所有 marp 檔。"""
    skills = sorted(repo.glob("profiles/*/skill/SKILL.md"))
    papers = sorted(repo.glob("examples/*/paper.md")) + sorted(repo.glob("profiles/*/skeleton/paper.md"))
    marps = []
    skip_parts = {".git", "node_modules", ".venv", "venv"}
    for md in repo.rglob("*.md"):
        if skip_parts & set(md.parts):
            continue
        head = md.read_text(encoding="utf-8", errors="replace")[:400]
        if re.search(r"^marp:\s*true", head, re.M):
            marps.append(md)
    return skills, papers, sorted(set(marps))


# ============================================================
# 主程式
# ============================================================

def report(findings: list[Finding]) -> None:
    for f in sorted(findings, key=lambda x: (x.file, x.line)):
        tag = f"{C_RED}ERROR{C_NC}" if f.severity == "error" else f"{C_YEL}WARN {C_NC}"
        loc = f"{f.file}:{f.line}" if f.line else f.file
        print(f"  {tag} {loc}: {f.msg}", file=sys.stderr)


def main(argv: list[str]) -> int:
    args = [a for a in argv if not a.startswith("--")]
    strict = "--strict" in argv
    ci = "--ci" in argv

    findings: list[Finding] = []

    if ci:
        repo = Path(__file__).resolve().parent.parent
        skills, papers, marps = collect_ci_targets(repo)
        for s in skills:
            findings += lint_skill(s)
        for p in papers + marps:
            findings += lint_md(p)
        if not strict:
            # CI 只把 error 當關卡;warn(死引用、孤兒 label)留給互動式 build / 本機檢查顯示,不在 CI 製造噪音
            findings = [f for f in findings if f.severity == "error"]
    else:
        if not args:
            print("用法: lint.py <file.md> [...]  或  lint.py --ci", file=sys.stderr)
            return 1
        for a in args:
            p = Path(a)
            if not p.exists():
                print(f"  {C_RED}ERROR{C_NC} 找不到檔案:{a}", file=sys.stderr)
                return 1
            findings += lint_skill(p) if p.name == "SKILL.md" else lint_md(p)

    errors = [f for f in findings if f.severity == "error"]
    warns = [f for f in findings if f.severity == "warn"]

    if findings:
        report(findings)
        print(f"\n  {C_RED}{len(errors)} error{C_NC} / {C_YEL}{len(warns)} warn{C_NC}",
              file=sys.stderr)
    else:
        print(f"  {C_GRN}lint 通過,無問題{C_NC}", file=sys.stderr)

    if errors:
        return 1
    if warns and strict:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
