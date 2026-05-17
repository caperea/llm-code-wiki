# LCW — LLM Code Wiki

[English](#english) | [中文](#中文)

---

<a id="english"></a>

## What is LCW

LCW is an LLM-maintained knowledge base for multi-repo codebases. The LLM reads your code (read-only), builds a structured wiki of interlinked markdown files, and keeps it current as your code evolves.

It turns implicit knowledge scattered across hundreds of repos into an explicit, queryable, linkable knowledge network — serving both humans (browsing in Obsidian) and AI (answering questions and self-correcting).

Based on the [LLM Wiki](llm-wiki.md) pattern by Andrej Karpathy.

## Core ideas

### The wiki is a living artifact, not a static snapshot

Unlike RAG systems that re-derive knowledge from scratch on every query, LCW **compiles knowledge once and keeps it current**. Cross-references are already built. Contradictions are already flagged. Every query and every sync makes the wiki more accurate, not less.

### Query is maintenance

Queries are not read-only. Every question triggers source code validation — if the wiki says something that the code contradicts, the wiki gets fixed on the spot. The more you ask, the more accurate the wiki becomes.

### The wiki gets smarter with every conversation

Three silent feedback loops run after every interaction:

1. **New insights → wiki**: discoveries from the conversation update wiki pages automatically
2. **Valuable queries → .inputs/queries/**: questions that revealed blind spots are saved as seeds for future ingest/sync
3. **User feedback → .inputs/notes/**: business context and decisions that can't be found in code are saved as source material

None of this requires the user to do anything — it happens transparently.

### As-is / To-be separation

The most important structural principle. Wiki content is strictly divided into two layers:

- **As-is** (repos/, modules/, domains/, flows/, interfaces/) — what the code actually looks like, maintained by ingest/sync/lint
- **To-be** (ddd/) — what the domain model should look like, maintained by `/lcw ddd`

The two layers are never mixed. When they conflict, the difference is shown to the user, not resolved by the tool.

### The wiki is derived; sources are the foundation

Everything in the wiki can be rebuilt from sources (`.sources/` + `.inputs/`). Code repos are the primary source of truth. User-provided information (business context, historical decisions) is secondary source material — it informs wiki construction but never appears directly in wiki pages.

## Install

```bash
git clone https://github.com/caperea/llm-code-wiki.git ~/.lcw
```

Then, in the project where you want to use LCW:

```bash
~/.lcw/setup                              # Claude Code (default)
~/.lcw/setup --host codex                 # Codex
~/.lcw/setup --host claude --host codex   # multiple hosts
```

This creates a symlink from your project's skill directory to `~/.lcw/skills/lcw/`. Only project-level installation is supported — no global install.

Update: `cd ~/.lcw && git pull` — symlinks pick up changes automatically.

## Usage

```
/lcw init                    # create wiki structure
/lcw pull repo-alpha         # clone a repo into .sources/
/lcw ingest repo-alpha       # full scan of a single repo
/lcw sync repo-alpha         # sync recent changes for one repo
/lcw sync                    # sync all repos with new commits
/lcw lint                    # health check for entire wiki
/lcw query how does auth work across repos?
/lcw file auth-flow-analysis # save an insight to the wiki
/lcw ddd strategic           # reverse DDD: strategic layer
/lcw plan                    # preview what needs to be done
/lcw migrate                 # migrate old wiki to current structure
```

## How it works

```
  Code repos (read-only)          wiki-project/ (LLM writes)
  ┌──────────────────┐           ┌──────────────────────┐
  │ .sources/        │──ingest──▶│ repos/  modules/     │
  │   repo-alpha/    │──sync────▶│ domains/ interfaces/ │
  │   repo-beta/     │           │ flows/  issues/      │
  └──────────────────┘           │ index.md  log.md     │
           ▲                     └──────────┬───────────┘
           └──── query reads ───────────────┘
                 source code        │
                 when wiki          ▼
                 isn't enough   .inputs/
                              queries/ notes/
                              (feedback loop)
```

The LLM extracts two things from each repo:

- **Code** (.go, .py, .ts, ...) — structure: modules, APIs, dependencies, data types
- **Notes** (README, CHANGELOG, comments, commits) — context: motivation, decisions, history

It cross-validates both, flags contradictions, and weaves them into wiki pages linked with `[[wikilinks]]`.

## Commands

All commands follow a unified pattern: `/lcw <action> [repo]` — with a repo name, process that repo; without, process all.

| Command | What it does |
|---------|-------------|
| `/lcw init` | Create wiki directory structure and template files |
| `/lcw pull [repo]` | Clone or update repos in `.sources/` |
| `/lcw ingest [repo]` | Full scan of a repo into wiki pages |
| `/lcw sync [repo]` | Incremental sync of recent changes |
| `/lcw lint [repo]` | Health check: detect drift, fix issues |
| `/lcw query <question>` | Search wiki, answer, validate against source code, fix wiki if stale |
| `/lcw file <name>` | Distill conversation insights into wiki pages |
| `/lcw ddd [layer] [context]` | Reverse DDD from code (strategic, tactical, evolution, audit) |
| `/lcw plan [command]` | Preview what needs to be done; optionally filter by command |
| `/lcw migrate` | Migrate old wiki to current structure |

Default: `/lcw <anything>` that isn't a known subcommand is treated as a query.

## Wiki structure

```
wiki-project/                # project root = wiki root
├── repos.md                 # repo registry (human-maintained)
├── SCHEMA.md                # page templates
├── index.md                 # page catalog
├── log.md                   # operation log
├── overview.md              # cross-repo architecture overview
├── glossary.md              # business glossary (as-is + to-be)
├── repos/                   # one page per repo
├── modules/{repo}/          # module pages, grouped by repo
├── domains/                 # business domains
├── interfaces/              # cross-repo integration points
├── flows/                   # end-to-end business flows
├── issues/                  # code-level problems and tech debt
├── ddd/                     # reverse DDD output (strategic/tactical/evolution)
├── .sources/                # cloned source code (gitignored)
├── .inputs/                 # sources layer (committed)
│   ├── queries/             # query records (questions, thinking paths)
│   └── notes/               # human input (business context, decisions)
└── .claude/skills/lcw/      # LCW skill (symlink)
```

## Supported tools

| Tool | Skill location | Setup |
|------|---------------|-------|
| Claude Code | `.claude/skills/lcw/` | default |
| Codex | `.codex/skills/lcw/` | `--host codex` |
| OpenCode | `.opencode/skills/lcw/` | `--host opencode` |
| Windsurf | `.windsurf/skills/lcw/` | `--host windsurf` |

## LCW repo structure

```
~/.lcw/                      # this repo
├── setup                    # project-level installer
├── skills/lcw/              # self-contained skill
│   ├── SKILL.md             # main skill definition
│   ├── references/          # per-command details (loaded on demand)
│   ├── templates/           # wiki scaffolding for /lcw init
│   └── agents/              # specialized agents
├── SPEC.md                  # requirements baseline
├── README.md                # this file
└── llm-wiki.md              # original concept
```

## Design

See [SPEC.md](SPEC.md) for the full requirements baseline. See [llm-wiki.md](llm-wiki.md) for the original concept.

---

<a id="中文"></a>

## 什么是 LCW

LCW 是一个由 LLM 维护的多仓库代码知识库。LLM 读取你的代码（只读），构建结构化的 markdown wiki，并随着代码演进持续保持更新。

它把散落在数百个 repo 中的隐性知识编织成显性的、可查询的、可链接的结构化知识网络——同时服务人类（通过 Obsidian 浏览）和 AI（回答问题并自我修正）。

基于 Andrej Karpathy 的 [LLM Wiki](llm-wiki.md) 概念。

## 核心思想

### Wiki 是活的，不是静态快照

与 RAG 系统每次查询都从头推导知识不同，LCW **一次编译知识并持续维护**。交叉引用已经建好，矛盾已经标记。每次查询和同步都让 wiki 更准确，而不是更过时。

### 查询即维护

查询不是只读操作。每个问题都会触发源码校验——如果 wiki 的描述与代码矛盾，wiki 会当场修正。问得越多，wiki 越准确。

### 越用越聪明

每次对话后自动执行三个静默反馈环：

1. **新认知 → wiki**：对话中的发现自动更新 wiki 页面
2. **有价值的 query → .inputs/queries/**：暴露了知识盲区的问题被保存为未来 ingest/sync 的种子
3. **用户反馈 → .inputs/notes/**：代码中找不到的业务背景和决策被保存为 source 原料

这一切不需要用户做任何操作——完全透明执行。

### 实然/应然分离

最重要的结构性原则。Wiki 内容严格分为两层：

- **实然**（repos/、modules/、domains/、flows/、interfaces/）——代码实际的样子，由 ingest/sync/lint 维护
- **应然**（ddd/）——领域模型应该的样子，由 `/lcw ddd` 维护

两层绝不混淆。当两者冲突时，向用户展示差异，不替用户做判断。

### Wiki 是派生物，Sources 是基底

Wiki 的所有内容都可以从 sources（`.sources/` + `.inputs/`）重建。代码仓库是首要事实来源。用户提供的信息（业务背景、历史决策）是辅助 source 原料——它指导 wiki 构建，但不直接出现在 wiki 页面中。

## 安装

```bash
git clone https://github.com/caperea/llm-code-wiki.git ~/.lcw
```

然后在你想使用 LCW 的项目中：

```bash
~/.lcw/setup                              # Claude Code（默认）
~/.lcw/setup --host codex                 # Codex
~/.lcw/setup --host claude --host codex   # 多宿主
```

这会从项目的技能目录创建到 `~/.lcw/skills/lcw/` 的 symlink。只支持项目级安装，不支持全局安装。

更新：`cd ~/.lcw && git pull`——symlink 自动生效。

## 用法

```
/lcw init                    # 创建 wiki 结构
/lcw pull repo-alpha         # 克隆一个 repo 到 .sources/
/lcw ingest repo-alpha       # 全量扫描一个 repo
/lcw sync repo-alpha         # 增量同步最近变更
/lcw sync                    # 同步所有有新提交的 repo
/lcw lint                    # 全 wiki 健康检查
/lcw query 认证在各 repo 之间怎么工作的？
/lcw file auth-flow-analysis # 归档洞察到 wiki
/lcw ddd strategic           # 反向 DDD：战略层
/lcw plan                    # 预览待办事项
/lcw migrate                 # 迁移旧 wiki 到当前结构
```

## 工作原理

```
  代码仓库（只读）               wiki 项目（LLM 写入）
  ┌──────────────────┐           ┌──────────────────────┐
  │ .sources/        │──ingest──▶│ repos/  modules/     │
  │   repo-alpha/    │──sync────▶│ domains/ interfaces/ │
  │   repo-beta/     │           │ flows/  issues/      │
  └──────────────────┘           │ index.md  log.md     │
           ▲                     └──────────┬───────────┘
           └──── query 时回溯 ──────────────┘
                 源码验证            │
                 wiki 不够          ▼
                 时补充         .inputs/
                              queries/ notes/
                              （反馈环）
```

LLM 从每个 repo 中提取两类信息：

- **代码**（.go, .py, .ts, ...）——结构：模块、API、依赖关系、数据类型
- **笔记**（README、CHANGELOG、注释、提交记录）——上下文：动机、决策、历史

两者交叉验证，标记矛盾，编织成用 `[[wikilinks]]` 互联的 wiki 页面。

## 命令

所有命令遵循统一模式：`/lcw <动作> [repo]`——指定 repo 名处理单个仓库，不指定则处理全部。

| 命令 | 功能 |
|------|------|
| `/lcw init` | 创建 wiki 目录结构和模板文件 |
| `/lcw pull [repo]` | 克隆或更新 `.sources/` 中的 repo |
| `/lcw ingest [repo]` | 全量扫描 repo 生成 wiki 页面 |
| `/lcw sync [repo]` | 增量同步最近变更 |
| `/lcw lint [repo]` | 健康检查：检测漂移，修复问题 |
| `/lcw query <问题>` | 搜索 wiki 回答问题，同时校验源码，过时则修正 |
| `/lcw file <名称>` | 把对话洞察归档到 wiki |
| `/lcw ddd [层] [上下文]` | 反向 DDD（战略层、战术层、演进层、漂移检测） |
| `/lcw plan [命令]` | 预览待办事项，可按命令过滤 |
| `/lcw migrate` | 迁移旧 wiki 到当前结构 |

默认行为：`/lcw <任意内容>` 如果不是已知子命令，一律视为查询。

## Wiki 结构

```
wiki-project/                # 项目根目录 = wiki 根目录
├── repos.md                 # 代码仓库清单（人维护）
├── SCHEMA.md                # 页面模板
├── index.md                 # 内容目录
├── log.md                   # 操作日志
├── overview.md              # 跨 repo 架构概览
├── glossary.md              # 业务词汇表（实然 + 应然）
├── repos/                   # 每个仓库一页
├── modules/{repo}/          # 模块页面，按仓库分组
├── domains/                 # 业务领域
├── interfaces/              # 跨 repo 接口
├── flows/                   # 端到端业务流程
├── issues/                  # 代码事实层的问题和技术债
├── ddd/                     # 反向 DDD 产出（战略/战术/演进）
├── .sources/                # 克隆的源码（gitignored）
├── .inputs/                 # sources 层（提交到 git）
│   ├── queries/             # 查询记录（问题、思考路径）
│   └── notes/               # 人类输入（业务背景、决策原因）
└── .claude/skills/lcw/      # LCW 技能（symlink）
```

## 支持的工具

| 工具 | 技能位置 | 安装方式 |
|------|---------|---------|
| Claude Code | `.claude/skills/lcw/` | 默认 |
| Codex | `.codex/skills/lcw/` | `--host codex` |
| OpenCode | `.opencode/skills/lcw/` | `--host opencode` |
| Windsurf | `.windsurf/skills/lcw/` | `--host windsurf` |

## LCW 仓库结构

```
~/.lcw/                      # 本仓库
├── setup                    # 项目级安装脚本
├── skills/lcw/              # 自包含技能
│   ├── SKILL.md             # 主技能定义
│   ├── references/          # 各命令的详细说明（按需加载）
│   ├── templates/           # wiki 初始化骨架
│   └── agents/              # 专用 agent
├── SPEC.md                  # 需求基准
├── README.md                # 本文件
└── llm-wiki.md              # 原始概念
```

## 设计

详见 [SPEC.md](SPEC.md)（完整需求基准）和 [llm-wiki.md](llm-wiki.md)（原始概念）。
