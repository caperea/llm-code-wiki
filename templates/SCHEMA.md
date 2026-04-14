# __wiki__ Schema

> 本文件是 wiki 的结构约定。LLM 在执行任何 wiki 操作前应先读取本文件。

**schema_version: 1**
> 如果版本号变更，lint 时应检查现有页面是否需要迁移。

## 目录结构

```
__wiki__/
├── SCHEMA.md           # 本文件
├── overview.md         # 全局架构概览（跨 repo 协作关系）
├── glossary.md         # 业务词汇对照表（跨 repo 术语统一）
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

### glossary.md

业务词汇对照表。记录代码中出现的领域术语，跨 repo 对照。由 `/lcw-ingest` 追加条目，`/lcw-ingest-all` 整合对照，`/lcw-lint` 检查一致性。

每个词条包含：规范术语、定义、各 repo 中的变体（变量名/类名/表名/proto 字段名）、状态（统一/不一致/待定）。

术语来源（按信息密度排序）：
1. **注释**（最重要）— 文档注释中的自然语言描述往往直接包含业务含义
2. **类型/变量名** — 命名反映开发者对概念的理解
3. **数据库 schema** — 表名和字段名是持久化的业务模型
4. **API / proto 定义** — 对外契约中的术语
5. **配置/枚举/常量** — 业务状态和分类

重点关注：
- 同一概念在不同 repo 中的命名差异（如 `user` vs `account` vs `member`）
- 缩写与全称不统一（如 `txn` vs `transaction`）
- 注释中的业务描述与代码命名的偏差（如注释说"订单"但变量叫 `request`）
- 数据库字段名、API 字段名、代码变量名之间的映射

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
6. **词汇表级联更新**：当 `glossary.md` 中的条目发生变更（规范术语改名、定义修正、状态从"不一致"变为"统一"），必须同步更新所有引用该术语的 wiki 页面。具体流程：
   - 在 glossary.md 中搜索被修改的术语
   - 用 `[[glossary]]` 中的旧术语在所有 wiki 页面中搜索
   - 将旧术语替换为新的规范术语，或补充术语映射说明
   - 在 log.md 中记录级联更新涉及的页面
