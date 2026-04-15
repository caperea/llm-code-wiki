# __wiki__ Schema

> 本文件是 wiki 的结构约定。LLM 在执行任何 wiki 操作前应先读取本文件。

**schema_version: 2**
> 如果版本号变更，lint 时应检查现有页面是否需要迁移。
> v1 → v2 变更：新增 `domains/` 页面类型；`interfaces/`、`issues/`、`modules/` 增加可选字段。v1 页面在 v2 下仍然合法，lint 给出建议而非报错。

## 目录结构

```
__wiki__/
├── SCHEMA.md           # 本文件
├── overview.md         # 全局架构概览（跨 repo 协作关系）
├── glossary.md         # 业务词汇对照表（跨 repo 术语统一）
├── index.md            # 内容目录
├── log.md              # 操作日志
├── flows/              # 端到端业务流程（Event Storming 事件流）
├── domains/            # 业务领域页面（限界上下文）
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
| 流程 | `flows/{描述性名称}.md` | `flows/order-to-delivery.md` |
| 领域 | `domains/{domain-name}.md` | `domains/ordering.md` |
| 仓库 | `repos/{repo-name}.md` | `repos/alpha.md` |
| 模块 | `modules/{repo}--{module}.md` | `modules/alpha--auth.md` |
| 接口 | `interfaces/{描述性名称}.md` | `interfaces/alpha-beta-grpc.md` |
| 概念 | `concepts/{概念名}.md` | `concepts/error-handling.md` |
| 决策 | `decisions/{NNN}-{标题}.md` | `decisions/001-monorepo-split.md` |
| 问题 | `issues/{描述性名称}.md` | `issues/stale-api-v1.md` |
| 查询 | `queries/{描述性名称}.md` | `queries/auth-flow-analysis.md` |

双横线 `--` 分隔 repo 和模块名，因为单横线在模块名中太常见。

## 页面模板

### flows/{name}.md

```yaml
---
flow: {name}                       # e.g. "order-to-delivery", "user-registration"
trigger: {触发场景}                 # e.g. "用户点击下单按钮"
actors: [参与的角色]
domains: [经过的领域]
critical: true | false              # 是否核心业务流程
last_synced: {YYYY-MM-DD}
---
```

端到端业务流程——Event Storming 那面墙的 markdown 版本。一个 flow 跨越多个领域，描述从触发到完成的完整业务旅程。

必含章节：

- **流程概览**：一句话描述端到端旅程
- **流程图**：用 ASCII art 画出流程全景图，放在 markdown 代码块中（见下方格式要求）
- **步骤**：按时间线排列的步骤序列，每个步骤包含：
  - 角色（谁触发）→ 命令（做什么）→ 聚合/领域（谁处理）→ 领域事件（产出什么，过去时态）
  - 业务规则（什么条件下执行）
  - 外部系统（如涉及第三方）
- **热点问题**：流程中发现的业务分歧、技术风险、知识盲区
- **异常路径**：失败/取消/超时等非 happy path 的处理

#### 流程图格式要求

流程图必须用 ASCII box-drawing 风格绘制，放在 ``` 代码块中，确保人类一眼能读懂。规则：

1. **标题**：顶部用满宽方框居中显示流程名称
2. **步骤**：每个步骤用 `┌─┐│└─┘` 画方框，框内写步骤编号 + 简要说明，可用 `•` 列出关键子步骤
3. **连接线**：步骤之间用 `│` 和 `▼` 连接，表示执行顺序
4. **分支**：条件分支用 `──►` 标注分支条件和去向，在同一个方框内展示
5. **并行**：并行执行用水平分叉 `┌────┴────┐` 展开为多列，完成后用 `└────┬────┘` 汇合
6. **起止**：流程入口写在标题下方，出口写在最后一个步骤下方
7. **宽度**：方框统一宽度（约 37 个半角字符），保持视觉对齐

示例片段：

```
┌─────────────────────────────────────┐
│              流程名称                │
└─────────────────────────────────────┘
触发事件描述
     │
     ▼
┌─────────────────────────────────────┐
│ Step 1: 步骤名称                    │
│ • 子步骤 A                          │
│ • 子步骤 B                          │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│ Step 2: 条件判断                    │
│                                     │
│  条件 A ──► 结果 A                  │
│                                     │
│  条件 B ──► 进入下一步              │
└─────────────────┬───────────────────┘
                  │
                  ▼
         ┌────────┴────────┐
         │    并行执行      │
         ▼                 ▼
┌────────────────┐  ┌────────────────┐
│  分支 A        │  │  分支 B        │
└────────┬───────┘  └───────┬────────┘
         └────────┬─────────┘
                  │
                  ▼
         返回最终结果
```

flows/ 页面引用 domains/ 中定义的领域事件和命令，但不重复定义它们。

### domains/{name}.md

```yaml
---
domain: {name}                     # e.g. "ordering", "pricing", "identity"
type: core | supporting | generic  # DDD 战略分类
capabilities: [业务能力列表]
repos: [实现该领域的 repo]
modules: [属于该领域的模块]
confidence: high | medium | low    # 边界推断置信度
last_synced: {YYYY-MM-DD}
---
```

注意：domains/ 页面没有 `last_synced_commit`，因为一个领域可能横跨多个 repo。领域页的时效性通过其包含的 modules/ 页面的 `last_synced_commit` 间接判断——如果任一模块过时，领域页也需要审视。

必含章节：

- **业务能力**：该领域提供什么业务功能（从业务视角描述，不是技术视角）
- **核心实体与聚合**：代码中发现的实体、值对象、聚合根（包含代码路径引用）。标注"上帝表"（30+ 字段）和模型风格（rich/anemic）
- **状态机**：核心实体的生命周期状态及转换（从枚举、常量、状态转换逻辑中提取）
- **领域事件**：该领域产出的事件清单（过去时态，如 OrderCreated, OrderCancelled），标注事件的消费者和 topic
- **命令**：该领域接收的命令清单（祈使句，如 CreateOrder, CancelOrder），标注命令的来源（哪个角色/系统触发）
- **领域词汇**：该上下文特有的术语，链接到 `[[glossary]]`
- **与其他领域的关系**：DDD 关系类型（Partnership / Customer-Supplier / Conformist / ACL / Shared Kernel / Open Host），标注上下游

领域页跨越多个 module 甚至多个 repo，是 module 页和 repo 页之间的"业务层"视角。一个 module 属于一个 domain，但一个 domain 可以跨多个 repo。

### overview.md

全局架构概览页，描述所有 repo 的协作关系。由 `/ingest` 自动维护。

必含章节：业务能力地图（表格：能力/所属领域/实现 repo/状态）、领域关系图（领域间 DDD 关系类型）、参与者与角色（表格：角色/类型/触发的核心流程）、核心业务流程（表格：流程/触发者/经过的领域/关键事件，详情链接到 flows/）、系统全景、repo 职责一览（表格，含所属领域列）、数据流（标注同步/异步及一致性机制）、跨 repo 依赖图、关键接口汇总、跨切面关注点（鉴权/日志/序列化/错误处理的统一程度）

### glossary.md

业务词汇对照表。记录代码中出现的领域术语，跨 repo 对照。所有写入命令都会维护词汇表：`/lcw-ingest` 提取并追加条目（批量模式完成后跨 repo 整合），`/lcw-diff` 同步术语变动，`/lcw-query` 校验时修正术语漂移，`/lcw-lint` 检查一致性并自动修正，`/lcw-file` 归档时检查新术语。

每个词条包含：规范术语、定义、领域上下文、各 repo 中的变体（变量名/类名/表名/proto 字段名）、状态（统一/不一致/待定/多义）。

同一术语在不同领域含义不同时，产生多行（每个上下文一行），状态标记为"多义"。例如"订单"在交易领域指用户下单请求，在结算领域指财务凭证，这是两个不同的概念，需要分行记录。

另设"多义术语"章节集中展示此类术语的领域差异和风险。每个领域一行（术语列合并阅读），支持三个及以上领域的多义情况。

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
domain: {domain-name}           # 可选，所属业务领域
model_style: rich | anemic | procedural | functional  # 可选，领域模型风格
last_synced: {YYYY-MM-DD}
last_synced_commit: {git short sha}
---
```

必含章节：做什么、代码结构、公共 API、内部逻辑摘要、依赖关系（上游/下游）

可选章节：领域模型笔记（聚合边界、实体 vs 值对象、贫血模型警告）

### interfaces/{name}.md

```yaml
---
between: [repo-a, repo-b]
protocol: gRPC | REST | event | shared-db | file
relationship: partnership | customer-supplier | conformist | acl | shared-kernel | open-host | none  # 可选，DDD 关系类型
upstream: {repo}               # 可选，上游方
downstream: {repo}             # 可选，下游方
data_consistency: sync | async-eventual | async-saga | manual | unknown  # 可选，一致性机制
last_synced: {YYYY-MM-DD}
last_synced_commit: {各端 repo 的 git short sha}
---
```

必含章节：连接了什么、契约、数据流与一致性（同步/异步、数据冗余、一致性机制）、脆弱点

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
impact_scope: local | service-chain | cross-domain  # 可选，影响范围
fix_effort: local | cross-team | redesign            # 可选，修复难度
risk_type: active-failure | degrading | latent        # 可选，风险类型
related_repos: [涉及的 repo 列表]
related_domains: [涉及的领域列表]                      # 可选
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
