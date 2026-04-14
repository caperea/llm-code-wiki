# __wiki__ Schema

> 本文件是 wiki 的结构约定。LLM 在执行任何 wiki 操作前应先读取本文件。

**schema_version: 1**
> 如果版本号变更，lint 时应检查现有页面是否需要迁移。

## 目录结构

```
__wiki__/
├── SCHEMA.md           # 本文件
├── overview.md         # 全局架构概览（跨 repo 协作关系）
├── index.md            # 内容目录
├── log.md              # 操作日志
├── repos/              # 仓库级页面，每个 repo 一个主页
├── modules/            # 模块/服务/包页面
├── interfaces/         # 跨 repo 接口页面
├── concepts/           # 概念/模式/约定页面
├── decisions/          # 架构决策记录 (ADR)
├── issues/             # 问题、矛盾、技术债
└── queries/            # 有价值的查询结果
```

## 命名约定

| 类别 | 路径格式 | 示例 |
|------|----------|------|
| 仓库 | `repos/{repo-name}.md` | `repos/alpha.md` |
| 模块 | `modules/{repo}--{module}.md` | `modules/alpha--auth.md` |
| 接口 | `interfaces/{描述性名称}.md` | `interfaces/alpha-beta-grpc.md` |
| 概念 | `concepts/{概念名}.md` | `concepts/error-handling.md` |
| 决策 | `decisions/{NNN}-{标题}.md` | `decisions/001-monorepo-split.md` |
| 问题 | `issues/{描述性名称}.md` | `issues/stale-api-v1.md` |
| 查询 | `queries/{描述性名称}.md` | `queries/auth-flow-analysis.md` |

双横线 `--` 分隔 repo 和模块名，因为单横线在模块名中太常见。

## 页面模板

### overview.md

全局架构概览页，描述所有 repo 的协作关系。由 `/ingest` 自动维护。

必含章节：系统全景、repo 职责一览（表格）、数据流、跨 repo 依赖图、关键接口汇总

### repos/{name}.md

```yaml
---
repo: {name}
path: {相对于工作区根的路径}
language: [主要语言]
last_synced: {YYYY-MM-DD}
last_synced_commit: {git short sha}
---
```

必含章节：职责、架构概览、对外接口、依赖、关键模块（链接到 modules/）、笔记来源

### modules/{repo}--{module}.md

```yaml
---
repo: {repo-name}
module: {module-name}
type: service | library | CLI | worker | config
last_synced: {YYYY-MM-DD}
last_synced_commit: {git short sha}
---
```

必含章节：做什么、代码结构、公共 API、内部逻辑摘要、依赖关系（上游/下游）

### interfaces/{name}.md

```yaml
---
between: [repo-a, repo-b]
protocol: gRPC | REST | event | shared-db | file
last_synced: {YYYY-MM-DD}
last_synced_commit: {各端 repo 的 git short sha}
---
```

必含章节：连接了什么、契约、数据流、脆弱点

### concepts/{name}.md

```yaml
---
related_repos: [涉及的 repo 列表]
tags: [标签]
date: {YYYY-MM-DD}
---
```

自由格式，但应包含：定义、在各 repo 中的体现、演化历史

### decisions/{NNN}-{name}.md

```yaml
---
status: proposed | accepted | deprecated | superseded
date: {YYYY-MM-DD}
related_repos: [涉及的 repo 列表]
superseded_by: {如适用}
---
```

必含章节：背景、决策、理由、后果

### issues/{name}.md

```yaml
---
severity: low | medium | high | critical
status: open | investigating | resolved
related_repos: [涉及的 repo 列表]
date: {YYYY-MM-DD}
resolved_date: {如适用}
---
```

必含章节：问题描述、发现方式、影响范围、建议修复

### queries/{name}.md

```yaml
---
question: {原始问题}
date: {YYYY-MM-DD}
related_repos: [涉及的 repo 列表]
source: query | discussion | investigation
---
```

自由格式，是提炼后的分析，不是聊天记录的复制。

## 写作约定

1. **引用源码用路径**：`见 repo-alpha/src/auth/middleware.go:L45-L80`，不粘贴代码
2. **用 wikilink 建立链接**：`[[repos/alpha]]`、`[[modules/alpha--auth]]`
3. **代码是事实**：当 wiki 与代码矛盾时，以代码为准
4. **标注不确定性**：如果信息来自旧文档且未与代码验证，标注 `[未验证]`
5. **摄入是升维**：从实现细节上升到架构理解，不是逐行翻译
