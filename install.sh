#!/usr/bin/env bash
set -euo pipefail

# LLM Code Wiki — installer
# Installs wiki commands and configuration for Claude Code, Codex, or OpenCode.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIT_DIR="${SCRIPT_DIR}/wiki-opencode-kit"

# ─── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${CYAN}▸${NC} %s\n" "$1"; }
ok()    { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
err()   { printf "${RED}✗${NC} %s\n" "$1" >&2; }

# ─── Usage ────────────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: install.sh <tool> [target-dir]

  tool:        claude | codex | opencode
  target-dir:  workspace to install into (default: current directory)

Examples:
  ./install.sh claude ~/workspace/my-repos
  ./install.sh opencode .
  ./install.sh codex /path/to/project
EOF
  exit 1
}

# ─── Args ─────────────────────────────────────────────────────────────────────

TOOL="${1:-}"
TARGET="${2:-.}"

if [[ -z "$TOOL" ]]; then
  usage
fi

TARGET="$(cd "$TARGET" && pwd)"

# ─── Shared: install __wiki__/ ────────────────────────────────────────────────

install_wiki() {
  info "Creating __wiki__/ directory structure"

  local wiki="${TARGET}/__wiki__"
  mkdir -p "$wiki"/{repos,modules,interfaces,concepts,decisions,issues,queries}

  for f in SCHEMA.md index.md log.md overview.md; do
    if [[ -f "${wiki}/${f}" ]]; then
      warn "__wiki__/${f} already exists, skipping"
    else
      cp "${KIT_DIR}/__wiki__/${f}" "${wiki}/${f}"
      ok "__wiki__/${f}"
    fi
  done
}

# ─── Shared: copy command files (with optional transform) ────────────────────

# Reads a command .md from kit, applies a transform function, writes to dest.
# $1 = source file (full path)
# $2 = dest file (full path)
# $3 = transform function name (receives stdin, writes stdout)
install_command() {
  local src="$1" dst="$2" transform="${3:-cat}"
  mkdir -p "$(dirname "$dst")"
  "$transform" < "$src" > "$dst"
  ok "$(basename "$dst")"
}

# ─── OpenCode ─────────────────────────────────────────────────────────────────

install_opencode() {
  info "Installing for OpenCode"

  # Commands
  local cmd_dir="${TARGET}/.opencode/commands"
  mkdir -p "$cmd_dir"
  for f in "${KIT_DIR}/.opencode/commands"/lcw-*.md; do
    cp "$f" "${cmd_dir}/$(basename "$f")"
    ok "$(basename "$f")"
  done

  # Agent
  local agent_dir="${TARGET}/.opencode/agents"
  mkdir -p "$agent_dir"
  cp "${KIT_DIR}/.opencode/agents/wiki.md" "${agent_dir}/wiki.md"
  ok "wiki.md agent"

  # AGENTS.md
  if [[ -f "${TARGET}/AGENTS.md" ]]; then
    warn "AGENTS.md already exists — appending wiki section"
    printf '\n' >> "${TARGET}/AGENTS.md"
    cat "${KIT_DIR}/AGENTS.md" >> "${TARGET}/AGENTS.md"
  else
    cp "${KIT_DIR}/AGENTS.md" "${TARGET}/AGENTS.md"
  fi
  ok "AGENTS.md"

  # opencode.json — merge instructions
  if [[ -f "${TARGET}/opencode.json" ]]; then
    warn "opencode.json already exists — please manually add \"__wiki__/SCHEMA.md\" to instructions"
  else
    cp "${KIT_DIR}/opencode.json" "${TARGET}/opencode.json"
    ok "opencode.json"
  fi
}

# ─── Claude Code ──────────────────────────────────────────────────────────────

# Transform: strip OpenCode-specific frontmatter fields (agent:), keep description
claude_transform() {
  sed '/^agent:/d'
}

install_claude() {
  info "Installing for Claude Code"

  # Commands → .claude/commands/
  local cmd_dir="${TARGET}/.claude/commands"
  mkdir -p "$cmd_dir"
  for f in "${KIT_DIR}/.opencode/commands"/lcw-*.md; do
    install_command "$f" "${cmd_dir}/$(basename "$f")" claude_transform
  done

  # CLAUDE.md — project instructions (combines AGENTS.md + wiki agent identity)
  local claude_md="${TARGET}/CLAUDE.md"
  local wiki_section
  wiki_section="$(cat <<'WIKI_EOF'

# LLM Code Wiki

本工作区包含多个代码仓库和一个 LLM 维护的 wiki 知识库。

## 核心规则

1. **只写 `__wiki__/`**：所有 repo 目录是只读输入，绝不修改任何 repo 中的文件
2. **代码是事实**：当 wiki 描述与代码矛盾时，以代码为准，更新 wiki
3. **笔记需验证**：README、注释、文档提供上下文，但可能过时，需与代码交叉验证
4. **wiki 记录理解，不复制代码**：页面中不粘贴大段源码，用路径引用 `repo/path/file.go:L10-L30`
5. **每次写操作后更新 `index.md` 和 `log.md`**

## Wiki 命令

- `/lcw-init` — 初始化 wiki 目录结构（首次使用时执行一次）
- `/lcw-ingest <repo>` — 首次全量摄入一个仓库
- `/lcw-ingest-all` — 批量摄入工作区所有仓库（首次构建用）
- `/lcw-diff <repo>` — 增量同步最近变更
- `/lcw-query <问题>` — 查询 wiki
- `/lcw-lint` — wiki 健康检查
- `/lcw-file <名称>` — 把当前对话的有价值内容归档到 wiki

## Wiki 编辑身份

执行 wiki 写操作（lcw-init, lcw-ingest, lcw-ingest-all, lcw-diff, lcw-lint, lcw-file）时，切换为 wiki 编辑角色：
- 准确提取代码结构（模块、API、依赖、数据流）
- 整合文档上下文（动机、决策、历史）
- 发现代码与文档的矛盾
- 维护跨 repo 的关系图谱
- 先读 `__wiki__/SCHEMA.md` 了解页面模板和命名约定
- 先读 `__wiki__/index.md` 了解现有页面
- 使用 wikilink 语法 `[[page]]` 建立页面间链接
- 页面中引用源码用路径而非粘贴：`见 repo/path/file:L行号`

## 异常处理

- repo 目录不存在或不是 git repo → 报告错误，跳过，不要崩溃
- wiki 页面 frontmatter 缺失或损坏 → 按 SCHEMA.md 模板补全
- index.md 与实际文件不一致 → 以实际文件为准，自动修复 index
- `last_synced_commit` 指向不存在的 commit → 回退到按日期过滤

## 代码 vs 笔记

- **代码**（.go, .py, .ts, .rs 等）→ 结构化提取：模块边界、API、依赖图、数据类型
- **笔记**（README, CHANGELOG, 注释, commit message）→ 语义化整合：动机、决策、上下文

操作前必读 `__wiki__/SCHEMA.md`。
WIKI_EOF
)"

  if [[ -f "$claude_md" ]]; then
    warn "CLAUDE.md already exists — appending wiki section"
    printf '%s\n' "$wiki_section" >> "$claude_md"
  else
    printf '%s\n' "$wiki_section" > "$claude_md"
  fi
  ok "CLAUDE.md"
}

# ─── Codex ────────────────────────────────────────────────────────────────────

# Transform: strip agent field, replace /lcw- description to note it's for AGENTS.md workflow
codex_transform() {
  sed '/^agent:/d'
}

install_codex() {
  info "Installing for Codex"

  # Codex doesn't have custom slash commands — put commands in .codex/commands/
  # and document them in AGENTS.md so the agent knows to look there
  local cmd_dir="${TARGET}/.codex/commands"
  mkdir -p "$cmd_dir"
  for f in "${KIT_DIR}/.opencode/commands"/lcw-*.md; do
    install_command "$f" "${cmd_dir}/$(basename "$f")" codex_transform
    done

  # AGENTS.md
  local agents_section
  agents_section="$(cat <<'AGENTS_EOF'

# LLM Code Wiki

本工作区包含多个代码仓库和一个 LLM 维护的 wiki 知识库。

## 核心规则

1. **只写 `__wiki__/`**：所有 repo 目录是只读输入，绝不修改任何 repo 中的文件
2. **代码是事实**：当 wiki 描述与代码矛盾时，以代码为准，更新 wiki
3. **笔记需验证**：README、注释、文档提供上下文，但可能过时，需与代码交叉验证
4. **wiki 记录理解，不复制代码**：页面中不粘贴大段源码，用路径引用 `repo/path/file.go:L10-L30`
5. **每次写操作后更新 `index.md` 和 `log.md`**

## Wiki 命令

Wiki 操作的详细流程定义在 `.codex/commands/` 目录下。当用户请求以下操作时，读取对应文件并执行：

| 用户请求 | 命令文件 |
|----------|----------|
| 初始化 wiki | `.codex/commands/lcw-init.md` |
| 全量摄入 repo | `.codex/commands/lcw-ingest.md` |
| 批量摄入所有 repo | `.codex/commands/lcw-ingest-all.md` |
| 增量同步 | `.codex/commands/lcw-diff.md` |
| 查询 wiki | `.codex/commands/lcw-query.md` |
| 健康检查 | `.codex/commands/lcw-lint.md` |
| 归档对话 | `.codex/commands/lcw-file.md` |

## Wiki 编辑身份

执行 wiki 写操作时，切换为 wiki 编辑角色：
- 准确提取代码结构（模块、API、依赖、数据流）
- 整合文档上下文（动机、决策、历史）
- 发现代码与文档的矛盾
- 维护跨 repo 的关系图谱
- 先读 `__wiki__/SCHEMA.md` 了解页面模板和命名约定
- 先读 `__wiki__/index.md` 了解现有页面
- 使用 wikilink 语法 `[[page]]` 建立页面间链接
- 页面中引用源码用路径而非粘贴：`见 repo/path/file:L行号`

## 异常处理

- repo 目录不存在或不是 git repo → 报告错误，跳过，不要崩溃
- wiki 页面 frontmatter 缺失或损坏 → 按 SCHEMA.md 模板补全
- index.md 与实际文件不一致 → 以实际文件为准，自动修复 index
- `last_synced_commit` 指向不存在的 commit → 回退到按日期过滤

## 代码 vs 笔记

- **代码**（.go, .py, .ts, .rs 等）→ 结构化提取：模块边界、API、依赖图、数据类型
- **笔记**（README, CHANGELOG, 注释, commit message）→ 语义化整合：动机、决策、上下文

操作前必读 `__wiki__/SCHEMA.md`。
AGENTS_EOF
)"

  if [[ -f "${TARGET}/AGENTS.md" ]]; then
    warn "AGENTS.md already exists — appending wiki section"
    printf '%s\n' "$agents_section" >> "${TARGET}/AGENTS.md"
  else
    printf '%s\n' "$agents_section" > "${TARGET}/AGENTS.md"
  fi
  ok "AGENTS.md"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

printf "\n${BOLD}LLM Code Wiki Installer${NC}\n"
printf "Tool:   ${CYAN}%s${NC}\n" "$TOOL"
printf "Target: ${CYAN}%s${NC}\n\n" "$TARGET"

# Validate kit exists
if [[ ! -d "$KIT_DIR" ]]; then
  err "Kit directory not found: ${KIT_DIR}"
  exit 1
fi

# Install __wiki__/ (shared across all tools)
install_wiki

# Install tool-specific config
case "$TOOL" in
  opencode)  install_opencode ;;
  claude)    install_claude ;;
  codex)     install_codex ;;
  *)
    err "Unknown tool: $TOOL (expected: claude, codex, opencode)"
    exit 1
    ;;
esac

printf "\n${GREEN}${BOLD}Done!${NC} Wiki installed for ${CYAN}%s${NC} in %s\n\n" "$TOOL" "$TARGET"

case "$TOOL" in
  opencode)
    printf "Next steps:\n"
    printf "  1. cd %s\n" "$TARGET"
    printf "  2. opencode\n"
    printf "  3. /lcw-init\n"
    ;;
  claude)
    printf "Next steps:\n"
    printf "  1. cd %s\n" "$TARGET"
    printf "  2. claude\n"
    printf "  3. /lcw-init\n"
    ;;
  codex)
    printf "Next steps:\n"
    printf "  1. cd %s\n" "$TARGET"
    printf "  2. codex\n"
    printf "  3. 请求: 初始化 wiki（codex 会读取 .codex/commands/lcw-init.md 执行）\n"
    ;;
esac

printf "\n"
