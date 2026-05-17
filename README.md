# LCW — LLM Code Wiki

LLM-maintained knowledge base for multi-repo codebases. The LLM reads your code (read-only), builds and maintains a structured wiki of markdown files, and keeps it current as your code evolves.

Based on the [LLM Wiki](llm-wiki.md) pattern by Andrej Karpathy.

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
                 source code
                 when wiki
                 isn't enough
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
| `/lcw migrate` | Migrate old wiki to current structure |
| `/lcw migrate <path> <intent>` | Recover specific files from `legacy/` to a target location |
| `/lcw plan` | Preview what needs to be done (no execution) |

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
├── legacy/                  # old pages that couldn't be migrated (optional)
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
│   └── agents/              # specialized agents (OpenCode)
├── SPEC.md                  # requirements baseline
├── README.md                # this file
└── llm-wiki.md              # original concept
```

## Design

See [llm-wiki.md](llm-wiki.md) for the original concept.
