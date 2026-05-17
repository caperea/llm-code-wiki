# Wiki Schema

> 本文件是 wiki 的结构约定。LLM 在执行任何 wiki 操作前应先读取本文件。

## 视角约定

wiki 中的内容分为三个视角层次：

```
代码文件 → [ingest 升维] → 现状理解层 → [ddd 分析] → 目标设计层
                                                ↘ [对比] ↙
                                               差距层（治理清单）
```

| 层次 | 位置 | 维护者 | 含义 |
|------|------|--------|------|
| **现状理解** | 项目根目录（repos/, modules/, domains/, flows/, interfaces/, overview.md 等） | ingest / sync / lint | 代码中实际呈现的结构 |
| **目标设计** | `ddd/` | ddd 命令 | 领域模型应该是什么样 |
| **差距** | glossary.md 的"差距"列 + ddd/gaps.md | 两方共同维护 | 现状与目标的不一致 = 治理待办 |

**读者指引**：

- 看 `domains/risk-control.md` → 代码中实际的领域结构
- 看 `ddd/contexts.md` → DDD 分析认为应该的上下文划分
- 两者不一致 → 查 `ddd/gaps.md` 了解差异
- `glossary.md` 某条目有"差距" → 这是术语治理的待办项
- `ddd/` 目录下的所有内容都是目标态，不要与代码现状混淆

**双视角文档**：

- `glossary.md`：每个条目同时包含"现状用法"（ingest 维护）和"领域定义"（ddd 维护）和"差距"
- `domains/*.md`：主体是现状，底部可选的"DDD 视角"章节指向目标层

**维护规则**：

- ingest / sync / lint 写入 glossary.md 时，**保留** DDD 相关字段（领域定义、差距、决策、消解状态），只更新"现状用法"
- ingest / sync / lint 写入 domains/*.md 时，**保留**底部的"DDD 视角"章节
- ddd 命令写入 glossary.md 时，**保留**"现状用法"，只更新 DDD 相关字段
- ddd 命令可以写入 domains/*.md 的"DDD 视角"章节和 frontmatter 的 `ddd_context`/`ddd_status` 字段

---

**schema_version: 4**
> 如果版本号变更，lint 时应检查现有页面是否需要迁移。
> v1 → v2 变更：新增 `domains/` 页面类型；`interfaces/`、`issues/`、`modules/` 增加可选字段。v1 页面在 v2 下仍然合法，lint 给出建议而非报错。
> v2 → v3 变更：新增 `ddd/` 目录与反向 DDD 梳理页面（战略层 / 战术层 / 演进层 / 漂移检测）。v2 页面在 v3 下仍然合法。
> v3 → v4 变更：新增 `.inputs/` sources 层（queries/ + notes/）及自动反馈环；overview.md 精简为五个索引性章节（系统全景、业务能力地图、参与者与角色、领域关系图、核心业务流程）；glossary.md 明确双视角条目格式（As-Is + To-Be）。v3 页面在 v4 下仍然合法。

## 目录结构

```
wiki-project/               # 项目根目录 = wiki 根目录
├── repos.md                # 代码仓库清单（人维护，格式自由）
├── SCHEMA.md               # 本文件
├── overview.md             # 全局架构概览（入口页，链接到各领域和仓库）
├── glossary.md             # 业务词汇对照表（跨 repo 术语统一）
├── index.md                # 内容目录
├── log.md                  # 操作日志
├── flows/                  # 端到端业务流程（Event Storming 事件流）
├── domains/                # 业务领域页面（从代码中提取的领域结构，现状理解层）
├── repos/                  # 仓库级 wiki 页面（工具维护，含同步状态）
├── modules/                # 模块页面，按仓库分子目录
│   └── {repo}/             # 每个仓库一个子目录
├── systems/                # 系统拓扑（多个 repo 组成的系统单元，AI 推断并维护）
├── interfaces/             # 跨 repo 接口页面（保留 repo 粒度，systems/ 做系统间汇总）
├── issues/                 # 代码事实层发现的问题和技术债（实然）
├── ddd/                    # 反向 DDD 梳理产出（应然）
│   ├── tactical/           # 战术层（每个上下文一组文件）
│   └── evolution/          # 演进层（路线图、迁移指南）
├── .sources/               # 克隆的源码（gitignored）
└── .inputs/                # sources 层：queries/（查询记录）+ notes/（人类输入）
```

## 命名约定

| 类别 | 路径格式 | 示例 |
|------|----------|------|
| 流程 | `flows/{描述性名称}.md` | `flows/order-to-delivery.md` |
| 领域 | `domains/{domain-name}.md` | `domains/ordering.md` |
| 仓库 | `repos/{repo-name}.md` | `repos/alpha.md` |
| 模块 | `modules/{repo}/{module}.md` | `modules/alpha/auth.md` |
| 系统 | `systems/{system-name}.md` | `systems/payment.md` |
| 接口 | `interfaces/{描述性名称}.md` | `interfaces/alpha-beta-grpc.md` |
| 问题 | `issues/{描述性名称}.md` | `issues/stale-api-v1.md` |
| DDD 战略 | `ddd/{产出类型}.md` | `ddd/panorama.md` |
| DDD 战术 | `ddd/tactical/{context-name}.md` | `ddd/tactical/risk-decision.md` |
| DDD 演进 | `ddd/evolution/{产出类型}.md` | `ddd/evolution/roadmap.md` |

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
type: core | supporting | generic  # 基于代码分析的领域分类（ingest 推断，DDD 分析可能重新分类）
capabilities: [业务能力列表]
repos: [实现该领域的 repo]
modules: [属于该领域的模块]
confidence: high | medium | low    # 边界推断置信度
last_synced: {YYYY-MM-DD}
ddd_context: {context-name}        # 可选，由 /lcw ddd 维护。指向 ddd/contexts.md 中的上下文
ddd_status: pending | analyzed     # 可选，由 /lcw ddd 维护。DDD 分析状态
---
```

注意：domains/ 页面没有 `last_synced_commit`，因为一个领域可能横跨多个 repo。领域页的时效性通过其包含的 modules/ 页面的 `last_synced_commit` 间接判断——如果任一模块过时，领域页也需要审视。

`ddd_context` 和 `ddd_status` 由 `/lcw ddd` 命令维护，ingest/sync/lint 保留不覆盖。

必含章节：

- **业务能力**：该领域提供什么业务功能（从业务视角描述，不是技术视角）
- **核心数据模型**：代码中发现的主要数据结构（包含代码路径引用）。标注"上帝表"（30+ 字段）和模型风格（rich/anemic/procedural）
- **状态机**：核心实体的生命周期状态及转换（从枚举、常量、状态转换逻辑中提取）
- **对外通知/消息**：该领域向外发出的异步消息或事件，标注消费者和 topic
- **对外接口**：该领域暴露的 API / RPC，标注调用方
- **领域词汇**：该领域特有的术语，链接到 `[[glossary]]`
- **与其他领域的依赖**：上游依赖谁、下游谁依赖它、依赖方式（同步调用/异步消息/共享数据库）

可选章节：

- **DDD 视角**（由 `/lcw ddd` 维护，ingest/sync/lint 保留不覆盖）：该领域在 DDD 分析中的定位——所属限界上下文、分析状态、与目标模型的差异摘要。链接到 `[[ddd/contexts]]` 和 `[[ddd/tactical/{context-name}]]`。

领域页跨越多个 module 甚至多个 repo，是 module 页和 repo 页之间的"业务层"视角。一个 module 属于一个 domain，但一个 domain 可以跨多个 repo。

**视角定位**：domains/ 是**现状理解层**——从代码中提取的领域结构。DDD 分析可能会重新划分边界（拆分、合并、重新定义），目标态记录在 `ddd/contexts.md` 中。两者的差异汇总在 `ddd/gaps.md`。

### overview.md

全局架构概览页——知识库的导航入口，不是所有信息的汇总。详细信息在各仓库页面、接口页面、领域页面中维护，overview 通过链接指向它们。

必含章节：
- **系统全景**：一段话 + 图，描述整体定位、架构风格和关键技术选型
- **业务能力地图**：表格（能力/所属领域/实现 repo/状态），链接到 `[[domains/...]]`。按业务能力组织，不按 repo 组织
- **参与者与角色**：表格（角色/类型/触发的核心流程），从 auth 注解、角色检查、API 注释、定时任务配置中推断。类型：用户角色 / 系统角色 / 外部系统 / 定时任务
- **领域关系图**：领域间的依赖方向全景（ASCII art 或 Mermaid），只画拓扑，不标注协议和字段细节
- **核心业务流程**：表格（流程/触发者/经过的领域），详情链接到 `[[flows/...]]`

### glossary.md

业务词汇对照表——**双视角文档**，同时包含现状理解（As-Is）和目标设计（To-Be）。

**维护分工**：
- ingest / sync / lint / query / file：维护"现状用法"相关字段（规范术语、定义、各 repo 变体、状态）
- ddd 命令：维护"领域定义"相关字段（领域定义、差距、决策、消解状态）
- 各方写入时**保留**对方维护的字段

**条目结构**（核心术语的完整结构）：

```markdown
### {术语名}

**现状用法（As-Is）：**
- 定义：{从代码中观察到的含义}
- 领域上下文：{出现在哪些领域}
- 各 repo 变体：{变量名/类名/表名/proto 字段名}
- 状态：统一 / 不一致 / 待定 / 多义

**领域定义（To-Be）：**（由 /lcw ddd 维护）
- {该术语在领域模型中的精确定义}
- {如果需要拆分为多个概念，列出每个概念的名称和定义}

**差距：** {现状与领域定义之间的不一致描述}
**决策：** {消解差距的行动方向}
**消解状态：** 未开始 / 进行中 / 已消解
```

简单术语（无歧义、无 DDD 分析需求）可省略"领域定义"以下的字段。DDD 分析时按需补充。

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

### modules/{repo}/{module}.md

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

### systems/{name}.md

```yaml
---
system: {name}                     # e.g. "payment", "risk-control"
repos: [组成该系统的 repo 列表]
domains: [该系统服务的业务领域]       # 链接到 domains/
confidence: high | medium | low    # 系统边界推断置信度
last_synced: {YYYY-MM-DD}
---
```

系统拓扑页——介于 overview（全局）和 repos/（单仓库）之间的中间层。一个 system = 一组紧密协作的 repo，对外表现为一个整体。

**划分由 AI 在 ingest 时推断**（基于 repo 间调用密度、共享数据、部署耦合等信号），query 和 lint 持续审视并调整。

**与 domains/ 的关系**：domains/ 是业务视角（"支付领域处理计费、开票、退款"），systems/ 是系统视角（"支付系统 = 3 个 repo，内部用 event bus，对外暴露 gRPC"）。两者有时重合，有时不重合（一个领域跨多个系统，或一个系统服务多个领域）。

必含章节：

- **职责**：一句话描述这个系统整体做什么
- **内部架构**：包含哪些 repo、repo 之间怎么连接（内部拓扑图 + 数据流）。链接到 `[[repos/...]]` 和 `[[modules/...]]`
- **对外接口**：该系统暴露什么能力、被哪些系统调用。链接到 `[[interfaces/...]]`
- **依赖的外部系统**：调用了哪些其他系统。链接到 `[[systems/...]]` 和 `[[interfaces/...]]`
- **数据一致性**：系统内部和跨系统的一致性机制概述

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

### issues/{name}.md

代码事实层发现的问题（实然）——技术债、接口矛盾、覆盖缺失。由 ingest/sync/lint 发现。

注意与 `ddd/gaps.md` 的区别：issues 是"代码本身有问题"，gaps 是"代码跟目标模型不一致"。

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

## DDD 分析页面

DDD 产出物属于**目标设计层**（To-Be），存放在 `ddd/` 目录下。详见顶部"视角约定"。

统一语言不单独设文件，直接增强 `glossary.md`（双视角文档）。

```
ddd/
├── status.md                       # 状态总览（DDD 分析仪表盘）
├── decisions.md                    # 先决决策（架构定位、梳理范围与目标）
├── panorama.md                     # 领域全景图（能力盘点 + 子域分类 + 烟囱报告）
├── contexts.md                     # 限界上下文（定义 + 映射关系）
├── gaps.md                         # 初始差异报告（战略层发现）
├── audit-{YYYY-MM-DD}.md           # 增量漂移报告（每次审计独立文件）
├── tactical/                       # 战术层（每个上下文一个文件）
│   └── {context-name}.md           # 聚合根 + 事件 + ACL + 服务 + 跨聚合协调
└── evolution/                      # 演进层
    ├── roadmap.md                  # 重构路线图
    ├── transition.md               # 过渡架构
    ├── migration-{context}.md      # 逐上下文迁移指南
    └── baseline.md                 # 质量基线与回归指标
```

**完整的 DDD 页面模板**（frontmatter + 章节约定）定义在各层参考文件的"页面模板"章节中（`references/ddd-strategic.md`、`ddd-tactical.md`、`ddd-evolution.md`、`ddd-audit.md`）。DDD 命令执行时只需读取对应的参考文件，不需要读取本文件。

## Sources 层（.inputs/）

`.inputs/` 是 source 层，不是 wiki 层。存放用户的提问记录和反馈信息，供 ingest/sync/query 读取利用。提交到 git。

### .inputs/queries/{YYYY-MM-DD}-{name}.md

查询记录——能激发出新知识的问题和发现路径。由 query 的对话扫尾步骤自动写入。

```yaml
---
date: {YYYY-MM-DD}
repos: [涉及的 repo]
domains: [涉及的领域]
covered_by_ingest: false
---
```

必含内容：问题原文、发现路径（思考过程）、产出（更新了哪些 wiki 页面、发现了什么）。

ingest 完成后会标注 `covered_by_ingest: true`，表示该问题涉及的知识已被系统性覆盖。

### .inputs/notes/{YYYY-MM-DD}-{name}.md

用户提供的非代码信息——业务背景、历史决策原因、团队约定。由 query 的对话扫尾步骤或人反馈处理自动写入。

```yaml
---
source: {谁提供的，如 "用户口述"、"团队会议"}
date: {YYYY-MM-DD}
related_repos: [涉及的 repo]
related_domains: [涉及的领域]
status: unverified | verified | stale
---
```

验证流程：ingest/sync/query 中如能用代码确认，将信息融入 wiki 页面并标记 `verified`；无法验证的保留为 `unverified`。

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
