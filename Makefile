# PaperForge Makefile
# 跨平台編譯入口（Linux/macOS；Windows 請用 scripts/build.ps1 / scripts/build-slides.ps1）

SHELL := /bin/bash
.PHONY: help build clean distclean watch test test-minimal test-full \
        slides slides-html slides-watch test-slides \
        list-profiles skill install install-marp check-env

# 預設輸入檔案
INPUT ?= paper.md
SLIDES ?= slides.md

help:
	@echo "PaperForge Make targets:"
	@echo ""
	@echo "  -- 論文 (Pandoc + XeLaTeX) --"
	@echo "  make build [INPUT=path/to/paper.md]   編譯論文（預設 paper.md）"
	@echo "  make clean [INPUT=path/to/paper.md]   清理中間檔"
	@echo "  make distclean                        清理所有產物（含 PDF）"
	@echo "  make watch                            監看模式"
	@echo "  make test                             編譯所有論文範例（minimal + full）"
	@echo "  make test-minimal                     編譯 minimal 論文範例"
	@echo "  make test-full                        編譯 full 論文範例"
	@echo ""
	@echo "  -- 口試簡報 (Marp) --"
	@echo "  make slides [SLIDES=path/to/slides.md]    編譯 PDF 簡報"
	@echo "  make slides-html [SLIDES=...]             編譯 HTML 簡報"
	@echo "  make slides-watch [SLIDES=...]            監看模式"
	@echo "  make test-slides                          編譯 slides-minimal 範例"
	@echo ""
	@echo "  -- 工具 --"
	@echo "  make list-profiles                    列出可用的 profile"
	@echo "  make skill                            安裝 Claude Code Skill"
	@echo "  make install                          執行完整安裝腳本"
	@echo "  make install-marp                     安裝 marp-cli"
	@echo "  make check-env                        檢查編譯環境"
	@echo ""
	@echo "用例："
	@echo "  make build INPUT=examples/minimal/paper.md"
	@echo "  make slides SLIDES=my-defense/slides.md"
	@echo "  make watch INPUT=my-thesis/paper.md"

build:
	@./scripts/build.sh $(INPUT)

clean:
	@./scripts/build.sh $(INPUT) --clean

distclean: clean
	@find . -name '*.pdf' -not -path './.git/*' -exec rm -f {} +
	@echo "Removed all PDF files."

watch:
	@./scripts/build.sh $(INPUT) --watch

test: test-minimal test-full

test-minimal:
	@./scripts/build.sh examples/minimal/paper.md

test-full:
	@./scripts/build.sh examples/full/paper.md

# -- Slides --
slides:
	@./scripts/build-slides.sh $(SLIDES) --pdf

slides-html:
	@./scripts/build-slides.sh $(SLIDES) --html

slides-watch:
	@./scripts/build-slides.sh $(SLIDES) --watch

test-slides:
	@./scripts/build-slides.sh examples/slides-minimal/slides.md --pdf

# -- 工具 --
list-profiles:
	@./scripts/build.sh --list-profiles

skill:
	@bash scripts/install-skill.sh

install:
	@bash scripts/install.sh

install-marp:
	@bash scripts/install-marp.sh

check-env:
	@bash scripts/check-env.sh
