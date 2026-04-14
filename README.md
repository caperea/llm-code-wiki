# LCW — LLM Code Wiki

LLM-maintained knowledge base for multi-repo codebases. The LLM reads your code (read-only), builds and maintains a structured wiki of markdown files, and keeps it current as your code evolves.

Based on the [LLM Wiki](llm-wiki.md) pattern by Andrej Karpathy.

## Install

```bash
git clone https://github.com/caperea/llm-code-wiki.git ~/.lcw && cd ~/.lcw && ./setup
```

`setup` auto-detects your tool (Claude Code, Codex, or OpenCode) and symlinks the commands. To specify manually:

```bash
./setup --host codex
```

Update: `cd ~/.lcw && git pull` — symlinks pick up changes automatically.

## Usage

In any multi-repo workspace:

```
/lcw-init                    # create __wiki__/ structure
/lcw-ingest repo-alpha       # full scan of a single repo
/lcw-ingest                  # smart sync all repos (ingest / diff / lint per repo)
/lcw-diff repo-alpha         # sync recent changes for one repo
/lcw-diff                    # sync all repos with new commits
/lcw-query how does auth work across repos?
/lcw-file auth-flow-analysis # save a good answer to the wiki
/lcw-lint repo-alpha         # health check for one repo
/lcw-lint                    # health check for entire wiki
```

## How it works

```
  Code repos (read-only)          __wiki__/ (LLM writes)
  ┌──────────────────┐           ┌──────────────────────┐
  │ repo-alpha/      │──ingest──▶│ repos/  modules/     │
  │ repo-beta/       │──diff────▶│ interfaces/ concepts/ │
  │ repo-gamma/      │           │ decisions/ issues/    │
  └──────────────────┘           │ queries/              │
           ▲                     │ index.md  log.md      │
           │                     └──────────┬────────────┘
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

All commands follow a unified pattern: **with a repo name, process that repo; without, process all**.

| Command | What it does |
|---------|-------------|
| `/lcw-init` | Create `__wiki__/` directory and template files, scan workspace for repos |
| `/lcw-ingest [repo]` | Full scan of one repo, or smart batch sync all repos (ingest / diff / lint per repo) |
| `/lcw-diff [repo]` | Incremental sync of one repo, or all repos with new commits |
| `/lcw-lint [repo]` | Health check for one repo, or entire wiki |
| `/lcw-query <question>` | Search wiki, synthesize answer, validate against source code |
| `/lcw-file <name>` | Distill a conversation into a wiki page (analysis, decision, issue) |

## File structure

```
~/.lcw/                  # this repo
├── setup                # one-time install
├── commands/            # slash command definitions (symlinked to tool)
├── agents/              # wiki editor agent (OpenCode)
└── templates/           # __wiki__/ scaffolding for /lcw-init

your-workspace/
├── repo-alpha/          # code repo (read-only)
├── repo-beta/           # code repo (read-only)
└── __wiki__/            # LLM-maintained wiki
    ├── SCHEMA.md        # structure conventions and page templates
    ├── overview.md      # cross-repo architecture overview
    ├── index.md         # page catalog (LLM reads this first)
    ├── log.md           # chronological operation log
    ├── repos/           # one page per repo
    ├── modules/         # one page per major module
    ├── interfaces/      # cross-repo integration points
    ├── concepts/        # patterns, conventions, shared abstractions
    ├── decisions/       # architecture decision records
    ├── issues/          # problems, contradictions, tech debt
    └── queries/         # saved analysis from conversations
```

## Supported tools

| Tool | Commands location | Setup |
|------|-------------------|-------|
| Claude Code | `~/.claude/commands/` | auto-detected |
| Codex | `~/.codex/commands/` | `--host codex` |
| OpenCode | `~/.opencode/commands/` + agent | `--host opencode` |

## Design

See [llm-wiki.md](llm-wiki.md) for the original concept and [wiki-opencode-commands.md](wiki-opencode-commands.md) for design notes on the multi-repo adaptation.
