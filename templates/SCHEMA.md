# __wiki__ Schema

> 本文件是 wiki 的结构约定。LLM 在执行任何 wiki 操作前应先读取本文件。

## 视角约定

wiki 中的内容分为三个视角层次：

```
代码文件 → [ingest 升维] → 现状理解层 → [ddd 分析] → 目标设计层
                                                ↘ [diff] ↙
                                               差距层（治理清单）
```

| 层次 | 位置 | 维护者 | 含义 |
|------|------|--------|------|
| **现状理解** | `__wiki__/` 根目录（repos/, modules/, domains/, flows/, interfaces/, overview.md 等） | ingest / diff / lint | 代码中实际呈现的结构 |
| **目标设计** | `__wiki__/ddd/` | ddd 命令 | 领域模型应该是什么样 |
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

- ingest / diff / lint 写入 glossary.md 时，**保留** DDD 相关字段（领域定义、差距、决策、消解状态），只更新"现状用法"
- ingest / diff / lint 写入 domains/*.md 时，**保留**底部的"DDD 视角"章节
- ddd 命令写入 glossary.md 时，**保留**"现状用法"，只更新 DDD 相关字段
- ddd 命令可以写入 domains/*.md 的"DDD 视角"章节和 frontmatter 的 `ddd_context`/`ddd_status` 字段

---

**schema_version: 4**
> 如果版本号变更，lint 时应检查现有页面是否需要迁移。
> v1 → v2 变更：新增 `domains/` 页面类型；`interfaces/`、`issues/`、`modules/` 增加可选字段。v1 页面在 v2 下仍然合法，lint 给出建议而非报错。
> v2 → v3 变更：新增 `activities/` 目录与月度桶页面（按自然月切片，每 (repo, 月) 一个）。v2 页面在 v3 下仍然合法。
> v3 → v4 变更：新增 `ddd/` 目录与反向 DDD 梳理页面（战略层 / 战术层 / 演进层 / 漂移检测）。v3 页面在 v4 下仍然合法。

## 目录结构

```
__wiki__/
├── SCHEMA.md           # 本文件
├── overview.md         # 全局架构概览（跨 repo 协作关系）
├── glossary.md         # 业务词汇对照表（跨 repo 术语统一）
├── index.md            # 内容目录
├── log.md              # 操作日志
├── flows/              # 端到端业务流程（Event Storming 事件流）
├── domains/            # 业务领域页面（从代码中提取的领域结构，现状理解层）
├── repos/              # 仓库级页面，每个 repo 一个主页
├── modules/            # 模块/服务/包页面
├── interfaces/         # 跨 repo 接口页面
├── concepts/           # 概念/模式/约定页面
├── decisions/          # 架构决策记录 (ADR)
├── issues/             # 问题、矛盾、技术债
├── queries/            # 有价值的查询结果
├── activities/           # 提交活动月度桶（按自然月，每 (repo, 月) 一个）
└── ddd/                  # 反向 DDD 梳理产出
    ├── tactical/         # 战术层（每个上下文一组文件）
    └── evolution/        # 演进层（路线图、迁移指南）
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
| 活动桶 | `activities/{repo}--{YYYY-MM}.md` | `activities/alpha--2026-03.md` |
| DDD 战略 | `ddd/{产出类型}.md` | `ddd/panorama.md` |
| DDD 战术 | `ddd/tactical/{context-name}.md` | `ddd/tactical/risk-decision.md` |
| DDD 演进 | `ddd/evolution/{产出类型}.md` | `ddd/evolution/roadmap.md` |

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

`ddd_context` 和 `ddd_status` 由 `/lcw ddd` 命令维护，ingest/diff/lint 保留不覆盖。

必含章节：

- **业务能力**：该领域提供什么业务功能（从业务视角描述，不是技术视角）
- **核心实体与聚合**：代码中发现的实体、值对象、聚合根（包含代码路径引用）。标注"上帝表"（30+ 字段）和模型风格（rich/anemic）
- **状态机**：核心实体的生命周期状态及转换（从枚举、常量、状态转换逻辑中提取）
- **领域事件**：该领域产出的事件清单（过去时态，如 OrderCreated, OrderCancelled），标注事件的消费者和 topic
- **命令**：该领域接收的命令清单（祈使句，如 CreateOrder, CancelOrder），标注命令的来源（哪个角色/系统触发）
- **领域词汇**：该领域特有的术语，链接到 `[[glossary]]`
- **与其他领域的关系**：DDD 关系类型（Partnership / Customer-Supplier / Conformist / ACL / Shared Kernel / Open Host），标注上下游

可选章节：

- **DDD 视角**（由 `/lcw ddd` 维护，ingest/diff/lint 保留不覆盖）：该领域在 DDD 分析中的定位——所属限界上下文、分析状态、与目标模型的差异摘要。链接到 `[[ddd/contexts]]` 和 `[[ddd/tactical/{context-name}]]`。

领域页跨越多个 module 甚至多个 repo，是 module 页和 repo 页之间的"业务层"视角。一个 module 属于一个 domain，但一个 domain 可以跨多个 repo。

**视角定位**：domains/ 是**现状理解层**——从代码中提取的领域结构。DDD 分析可能会重新划分边界（拆分、合并、重新定义），目标态记录在 `ddd/contexts.md` 中。两者的差异汇总在 `ddd/gaps.md`。

### overview.md

全局架构概览页，描述所有 repo 的协作关系。由 `/ingest` 自动维护。

必含章节：业务能力地图（表格：能力/所属领域/实现 repo/状态）、领域关系图（领域间 DDD 关系类型）、参与者与角色（表格：角色/类型/触发的核心流程）、核心业务流程（表格：流程/触发者/经过的领域/关键事件，详情链接到 flows/）、系统全景、repo 职责一览（表格，含所属领域列）、数据流（标注同步/异步及一致性机制）、跨 repo 依赖图、关键接口汇总、跨切面关注点（鉴权/日志/序列化/错误处理的统一程度）

### glossary.md

业务词汇对照表——**双视角文档**，同时包含现状理解（As-Is）和目标设计（To-Be）。

**维护分工**：
- ingest / diff / lint / query / file：维护"现状用法"相关字段（规范术语、定义、各 repo 变体、状态）
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

### activities/{repo}--{YYYY-MM}.md

```yaml
---
type: activity-bucket
repo: {repo}
month: {YYYY-MM}                          # 自然月，例如 2026-02
month_status: closed | current            # 过去月 closed（幂等不再写），当月 current（每次 sync 刷新）
extracted_at: {ISO 时间戳}
commit_range: {first_short_sha}..{last_short_sha}   # 该月第一笔到最后一笔提交
commit_count: {N}
author_count: {N}
files_touched: {N}
loc_added: {N}
loc_removed: {N}
top_modules: [模块名, ...]                 # 改动最多的 3-5 个模块（与 modules/ 目录中的 module 字段对应）
top_authors:                              # 最多 5 人
  - name: {canonical_name}
    commits: {N}
    loc_net: {N}
schema_version: 1
---
```

提交活动月度桶——把一个 repo 一个自然月的所有提交升维成稳定的、可聚合的叙事 + 表格，供 `/lcw activities ask` 在任意时间窗口聚合查询。

**核心原则**：

- 摄入是升维：不存 commit 全文 / diff，只存路径、模块映射、作者归属、聚合指标
- 过去月的桶幂等：一旦写入并标记 `month_status: closed`，后续 sync 跳过；只有当月 (`current`) 会被重写
- 引用源码用路径，引用模块用 `[[wikilinks]]`
- 作者邮箱不写入正文，只在 frontmatter 的 `top_authors` 中以 canonical_name 出现（避免泄漏）

必含章节（每段叙事 ≤ 150 字）：

- **本月主题**：1-2 段叙事——这个月主要在做什么？是续作之前的工作还是新方向？
- **改动热区**：表格列出 模块 / 改动文件数 / 主要作者 / 关联 `[[modules/{repo}--{module}]]`
- **高影响提交**：默认阈值 ≥10 文件 或 ≥500 LOC 的提交清单——short sha, subject, author, 关联模块
- **作者贡献**：表格列出 作者 / 提交数 / LOC净 / 聚焦模块 / 与上月对比（↑↓→）
- **风险信号**：高 churn 文件、反复回退、bugfix 集中区——可触发 `[[issues/...]]`
- **关联 wiki**：本月触及的 `[[domains/...]]`、`[[interfaces/...]]`、`[[decisions/...]]`

`activities/_index.md` 为 LLM 查找入口，列出当前已存在的桶（按 repo / 月份）以及各桶的 `extracted_at`，供 `/lcw activities ask` 快速判断窗口完整性。

可选 `activities/_aliases.yaml`：作者归一化映射（`canonical / emails / github`），无该文件时按 `(name, email)` 默认聚合。

## DDD 分析页面

DDD 产出物属于**目标设计层**（To-Be），存放在 `__wiki__/ddd/` 目录下。根目录的代码事实页面属于**现状理解层**（As-Is）。两者的差异汇总在 `ddd/gaps.md` 和 `glossary.md` 的"差距"字段中。详见顶部"视角约定"。

统一语言不单独设 `ddd/vocabulary.md`，而是合并到 `glossary.md`（双视角文档）。

```
__wiki__/ddd/
├── decisions.md                    # 先决决策（架构定位、梳理范围与目标）
├── panorama.md                     # 领域全景图（子域分类、业务能力盘点）
├── contexts.md                     # 限界上下文定义
├── context-map.md                  # 上下文映射关系
├── silos.md                        # 烟囱报告
├── gaps.md                         # 双向校验差异报告
├── tactical/                       # 战术层（每个上下文一组文件）
│   ├── {context-name}.md           # 聚合根 + 实体 + 值对象 + 不变量
│   ├── {context-name}-events.md    # 领域事件目录
│   ├── {context-name}-acl.md       # 防腐层设计
│   └── {context-name}-services.md  # 领域服务清单
└── evolution/                      # 演进层
    ├── roadmap.md                  # 重构路线图
    ├── transition.md               # 过渡架构
    ├── migration-{context}.md      # 逐上下文迁移指南
    └── baseline.md                 # 质量基线与回归指标
```

### ddd/decisions.md

```yaml
---
type: ddd-decisions
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

先决决策记录。首次运行 `/lcw ddd` 时创建，后续可更新。

必含章节：

- **系统架构定位**：集中式平台 / 分布式框架 / 两层分离 / 不适用，附选择理由
- **梳理范围**：纳入梳理的 repo 清单
- **梳理目标**：理解现状 / 规划重构 / 支撑新需求 / 持续治理
- **输出偏好**：词汇表语言、图表格式

### ddd/panorama.md

```yaml
---
type: ddd-panorama
scope: [纳入梳理的 repo 列表]
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

领域全景图。

必含章节：

- **业务能力盘点**：表格列出所有业务能力（能力名 / 描述 / 暴露方式 / 所属子域 / 实现模块）
- **子域分类**：核心域 / 支撑域 / 通用域三类，每类列出包含的能力，标注分类依据
- **子域全景图**：ASCII art 或 Mermaid 图，展示子域之间的关系

### ddd/contexts.md

```yaml
---
type: ddd-contexts
context_count: {N}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

限界上下文定义。

每个上下文一个章节，包含：

- **职责边界**：做什么、不做什么
- **对外契约**：暴露的接口（命令 + 查询）
- **核心数据**：该上下文"拥有"的实体
- **所属子域**：核心 / 支撑 / 通用
- **实现现状**：当前由哪些 repo/module 承载（链接到 wiki 页面）
- **边界判据**：为什么这样划分（数据边界 / 语言边界 / 团队边界 / 变更频率）

### ddd/context-map.md

```yaml
---
type: ddd-context-map
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

上下文映射关系图。

必含章节：

- **映射全景图**：ASCII art 或 Mermaid 图，展示所有上下文及其关系
- **关系明细**：表格列出每对上下文关系（上游 / 下游 / 关系类型 / 集成方式 / 数据一致性 / 备注）
- **关系类型统计**：各类型的数量分布，辅助判断系统耦合程度

### 统一语言

不单独设 `ddd/vocabulary.md`，统一语言直接增强 `glossary.md`（见上方 glossary.md 章节的双视角条目结构）。DDD 分析时，对核心术语补充"领域定义""差距""决策""消解状态"字段。

### ddd/silos.md

```yaml
---
type: ddd-silos
silo_count: {N}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

烟囱报告——"实质上做同一件事"的多个实现。

每组烟囱一个章节：

- **烟囱名称**：这组重复实现在做什么
- **存在位置**：表格列出每个实现（模块 / 入口 / 实现方式）
- **差异分析**：各实现之间的差异是"有意的业务差异"还是"无意的重复"
- **合并建议**：统一抽象的方向、难度、阻碍因素

### ddd/gaps.md

```yaml
---
type: ddd-gaps
gap_count: {N}
last_audit: {YYYY-MM-DD}
---
```

双向校验差异报告。战略层完成时首次创建，每次 `/lcw ddd audit` 时更新。

每个差异一行或一节：

- **差异描述**
- **类型**：代码追上了模型（正面）/ 代码偏离了模型（关注）/ 模型需要更新（过时）
- **严重程度**：提示 / 警告 / 阻塞
- **相关页面**：链接到 wiki 代码事实页面和 DDD 模型页面
- **建议行动**

### ddd/tactical/{context-name}.md

```yaml
---
type: ddd-tactical
context: {context-name}
aggregate_count: {N}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

限界上下文的战术模型。

必含章节：

- **上下文概述**：一段话描述该上下文的核心职责（链接到 `[[ddd/contexts]]`）
- **聚合根清单**：每个聚合根一个子章节，包含：
  - 聚合根实体（名称、关键属性）
  - 聚合内实体
  - 值对象
  - 不变量约束（该聚合必须始终满足的业务规则）
  - 代码现状（当前实现位置、model_style、与目标模型的差距）
- **贫血检测结果**：被错放在 Service/Manager 中的实体行为清单，标注建议归属

### ddd/tactical/{context-name}-events.md

```yaml
---
type: ddd-events
context: {context-name}
event_count: {N}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

领域事件目录。

表格格式：事件名称（过去时态）/ 触发条件 / 生产者聚合 / 消费者 / 载荷摘要 / 持久化需求 / 当前实现方式

### ddd/tactical/{context-name}-acl.md

```yaml
---
type: ddd-acl
context: {context-name}
acl_count: {N}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

防腐层设计。

每个 ACL 一个章节：

- **隔离什么**：哪个外部接口 / 上下文
- **方向**：保护本上下文 / 保护外部 / 双向
- **转换规则**：外部模型 → 本上下文模型的映射
- **当前状态**：已有 ACL / 直接耦合 / 部分隔离

### ddd/tactical/{context-name}-services.md

```yaml
---
type: ddd-services
context: {context-name}
service_count: {N}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

领域服务清单。

每个服务一行或一节：

- **服务名称**
- **职责**：协调哪些聚合
- **杂物间风险**：低 / 中 / 高（方法数过多、职责过杂时标高）
- **当前实现**：代码位置

### ddd/evolution/roadmap.md

```yaml
---
type: ddd-roadmap
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

重构路线图。

必含章节：

- **现状评估**：表格（上下文 / 烟囱程度 / 耦合度 / 模型健康度 / 变更频率 / 问题密度 / 综合优先级）
- **优先级排序**：排序结果及依据说明
- **路线图**：按优先级排列的重构阶段（阶段 / 目标 / 涉及上下文 / 预估工作量 / 前置依赖）
- **风险与假设**：路线图依赖的前提条件

### ddd/evolution/transition.md

```yaml
---
type: ddd-transition
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

过渡架构描述。承认"过渡架构会存在很长时间"。

每个阶段一个章节：

- **架构图**：该阶段的系统架构（ASCII art 或 Mermaid）
- **新旧共存**：哪些组件是新的、哪些是旧的、ACL 在哪里
- **切流策略**：如何从上一阶段迁移到这个阶段

### ddd/evolution/migration-{context}.md

```yaml
---
type: ddd-migration
context: {context-name}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

逐上下文迁移指南。

必含章节：

- **目标态**：该上下文重构后的目标架构
- **迁移步骤**：有序的步骤清单
- **灰度方案**：流量切换策略
- **回滚预案**：每个步骤的回滚方法
- **验证方法**：如何确认迁移成功

### ddd/evolution/baseline.md

```yaml
---
type: ddd-baseline
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

质量基线与回归指标。

必含章节：

- **通用指标**：功能正确性、性能、可观测性覆盖
- **业务指标**：特定于该系统领域的质量指标
- **测量方法**：每个指标怎么测、数据从哪来
- **红线**：哪些指标绝对不能退化

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
