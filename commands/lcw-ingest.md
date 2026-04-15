---
description: "摄入代码仓库到 wiki — 首次接触时全量扫描，已有 wiki 时智能选择更新策略"
agent: "wiki"
---

摄入代码仓库到 wiki：`$ARGUMENTS`

**范围**：传入 repo 名时处理单个仓库；无参数时处理工作区所有仓库。

目的：把代码仓库从零变成结构化的 wiki 知识。代码告诉你系统是什么，文档告诉你为什么是这样，wiki 把两者编织在一起。

---

## 单 repo 模式（`/lcw-ingest repo-name`）

### 已有 wiki 的处理

检查 `repos/{repo-name}.md` 是否已存在：

- **不存在**：正常执行全量摄入。
- **已存在**：读取 `last_synced_commit`，用 `git log {sha}..HEAD --oneline` 检查是否有新提交。
  - 无新提交 → 报告"已是最新"，建议 `/lcw-lint {repo}` 做健康检查。
  - 有新提交 → 建议用户改用 `/lcw-diff`（增量更新更快更安全）。如果用户明确要求全量重建（如 wiki 页面损坏、模块结构大幅变化），告知将覆盖现有页面后继续执行。

为什么默认不直接覆盖：全量 ingest 会重新生成所有模块页面，手动编辑过的补充说明、已修正的交叉验证标记都会丢失。diff 只更新变化部分，保留人工积累的知识。

### 分析阶段（只读）

**扫描结构**：列出仓库目录结构（2-3 层），识别主要语言、框架、构建系统、入口点，划分模块边界。

**规模评估**：如果主要模块超过 15 个，切换为分批模式——先创建 repo 主页和模块清单，再逐批摄入（每批 3-5 个模块）。一次性处理太多模块会导致后半段质量下降。

**代码通道（提取 what）**：对每个主要模块：提取公共 API、依赖关系、关键数据类型。扫描路由、配置、proto/schema 文件。识别与其他 repo 的接口点。

提取业务词汇——从以下来源识别领域术语：
- **注释**（最重要）：文档注释中的自然语言往往直接包含业务含义
- **代码**：类型名、变量名、数据库表/字段名、proto 字段、API 路径
- **配置**：枚举值、常量名、错误码定义

为什么注释最重要：代码命名受技术约束（长度、语言习惯），注释是开发者用人类语言解释业务概念的地方。

**数据库 Schema 分析**（如存在迁移文件、DDL 或 ORM 模型）：
- 扫描迁移目录（Flyway、Liquibase、Alembic、Rails migrations 等）和 ORM 实体定义
- 识别"上帝表"（30+ 字段）→ 聚合边界不清的信号，记入 issues/
- 检测跨模块共享表（多个模块引用同一张表）→ 隐性耦合，记入 interfaces/
- 提取外键关系和索引作为实体关系线索

**状态机提取**：
- 扫描 status/state 相关的枚举、常量、字段定义
- 查找状态转换逻辑（switch/case on status、状态机框架、workflow 定义）
- 记录核心实体生命周期（如 Order: created → paid → shipped → delivered）
- 状态机是最浓缩的业务规则视角——实体能做什么、不能做什么都编码在里面

**领域模型识别**：
- 识别实体（有 ID 的持久化对象）与值对象（无 ID 的不可变对象）
- 检测聚合根线索：被外部引用的顶层实体、Repository/DAO 模式的操作目标
- 判断模型风格：rich（业务方法在实体上）vs anemic（数据容器 + Service 逻辑）vs procedural vs functional

**笔记通道（提取 why）**：读取 README、ARCHITECTURE、CONTRIBUTING、CHANGELOG 等文档。提取有价值的代码注释（TODO、HACK、FIXME、架构决策注释）。查看最近 20 条 commit message 了解变更趋势。

**基础设施通道（提取 how）**：

消息/事件流分析（如存在消息队列配置或事件处理代码）：
- 识别消息生产者和消费者（Kafka/RabbitMQ/SQS/RocketMQ 的 topic、handler、listener）
- 检测事件 payload "肥胖度"（15+ 字段 → 上游把整个模型推给下游，过度耦合）
- 追踪 topic 扇出（一个事件被多个消费者订阅 = 隐性契约，该事件是关键领域事件）

跨切面关注点扫描：
- 鉴权/授权模式：中间件、装饰器、注解（统一 or 各模块自行实现？）
- 日志模式：结构化 vs 自由文本，traceId/correlationId 是否在服务间传递
- 错误处理：统一错误码还是各模块自定义

**交叉验证**：对比文档描述与代码实际结构。这一步至关重要——文档经常过时。标记：
- phantom feature：文档说有但代码没有
- undocumented：代码有但文档没说
- stale docs：文档描述与代码行为不一致
- boundary violation：模块 A 直接操作模块 B 的数据库表（绕过 API）→ 领域边界被破坏
- implicit sharing：多个模块引用同一个 model/type 定义 → 潜在的共享内核

**领域综合**（交叉验证之后、写入之前执行——这是从"代码文档化"到"领域知识提炼"的关键一步）：

1. 基于已发现的模块、实体、词汇，**推断业务领域（限界上下文）边界**
   - 线索：模块聚类（共享实体/词汇的模块归为一个领域）、DB Schema 分组（共享表的模块）、API 路径前缀、目录组织结构
2. **分类领域**：core（差异化能力，通常代码最复杂）/ supporting（支撑核心但不差异化）/ generic（通用功能如认证/通知，通常第三方库使用最多）
3. **推断领域间关系类型**：
   - 适配器/转换器代码 → ACL（反腐败层）
   - 共享 proto/model 包 → Shared Kernel（共享内核）
   - 单向调用链、上游不关心下游 → Customer-Supplier
   - 下游完全复制上游数据结构 → Conformist
4. 标注推断置信度（high/medium/low）——领域边界推断是主观判断，不确定时如实标注

### 写入阶段（修改 wiki）

按 SCHEMA.md 的模板创建页面：
- `domains/{name}.md`（每个推断出的业务领域，含实体、状态机、领域关系）
- `repos/{name}.md`（仓库主页，frontmatter 含 `last_synced_commit`）
- `modules/{name}--{module}.md`（每个主要模块，frontmatter 含 `domain` 和 `model_style`）
- `interfaces/`（跨 repo 接口，frontmatter 含 `relationship` 和 `data_consistency`）
- `concepts/`（设计模式或约定，如发现）
- `issues/`（问题或矛盾，frontmatter 含 `impact_scope`/`fix_effort`/`risk_type`）
- 更新 `overview.md`（含业务能力地图、领域关系图、跨切面关注点）

**词汇表更新**：将代码通道提取的业务词汇写入 `glossary.md`。对每个术语：如果已有条目，补充本 repo 的用法、领域上下文和引用页面；如果是新术语，新增条目并标注领域上下文。如果发现本 repo 用法与已有规范术语不一致，标记状态为"不一致"。如果发现同一术语在不同领域含义不同（如"订单"在交易领域和结算领域含义不同），标记状态为"多义"并在"多义术语"章节记录差异和风险。词汇表变更后，按 SCHEMA.md 写作约定第 6 条执行级联更新。

log.md 记录：
```
## [ISO时间] ingest | {repo名}
- 扫描结果：{语言}，{N} 个主要模块
- 创建/更新：{页面列表}
- 发现：{问题摘要}
```

---

## 批量模式（`/lcw-ingest`，无参数）

### 规划

如果 `__wiki__/` 不存在，先执行 lcw-init 的初始化流程。

扫描工作区，识别代码仓库（排除 `__wiki__/`、`.opencode/`、`.claude/`、`.codex/`、`node_modules/`、隐藏目录）。对每个 repo 检查 wiki 状态，分为三类：

- **未摄入**（无 `repos/{name}.md`）→ 全量 ingest
- **已摄入且有新提交**（`git log {sha}..HEAD` 非空）→ diff 增量更新
- **已摄入且无新提交** → 局部 lint

为什么无新提交也不跳过：代码没变不代表 wiki 是对的。之前的 ingest/diff 可能遗漏了术语、链接可能断了、wiki 描述可能与代码有微妙偏差。局部 lint 成本很低，但能修正这些累积的小问题。

生成执行计划并展示给用户确认，明确标注每个 repo 的操作类型（ingest / diff / lint）。先处理小 repo（快速产出可见结果），再处理大 repo。用户可以调整顺序、强制全量重建、或排除某些 repo。

### 执行

**为什么每个 repo 需要独立上下文**：每个 repo 的处理需要读取大量代码，如果在同一个上下文中逐个处理，3-4 个大 repo 后上下文就会耗尽，后续 repo 的质量会严重下降。

**分析并行、写入串行**：

1. **并行分析**：为每个需要 ingest 或 diff 的 repo 启动独立 subagent 执行分析阶段。每个 subagent 有独立上下文，互不挤占，返回结构化结果（模块清单、API 摘要、业务词汇、发现的问题），不写入任何文件。并行粒度：3-5 个 repo 全部并行；超过 5 个分批执行。

2. **串行写入**：收集所有分析结果后，逐个写入 wiki 页面。为什么必须串行：`glossary.md`、`index.md`、`overview.md`、`interfaces/` 是共享资源，串行写入时每个 repo 能看到前面 repo 已追加的条目，正确标记术语冲突。每完成一个 repo 输出进度（如 `[2/5] repo-beta — 创建 8 个页面`）。

3. **局部 lint**：对无新提交的 repo 执行 `/lcw-lint {repo}`，可与上述分析并行。

如果某个 repo 失败，记录错误到 log.md，跳过继续。

**降级策略**：如果运行环境不支持并行 subagent，回退为逐 repo 串行执行，每个 repo 仍在独立 subagent 中以隔离上下文。

### 跨 repo 整合

所有 repo 处理完成后——这是批量模式最有价值的一步，单 repo 模式看不到 repo 之间的关系：

- 整理 `domains/`：跨 repo 审视领域边界是否合理（一个领域可能横跨多个 repo），调整 domain 分类（core/supporting/generic），补充领域间关系
- 整理 `overview.md`：业务能力地图、领域关系图、系统全景、repo 职责、跨 repo 数据流（标注一致性机制）、依赖图、跨切面关注点（比较各 repo 的鉴权/日志/错误处理一致程度）
- 整理 `interfaces/`：确保接口两端互相链接，补充 relationship 和 data_consistency 字段
- 整合 `glossary.md`：跨 repo 对照术语，合并同义条目，标记不一致，识别多义术语（同一术语在不同领域含义不同），执行级联更新

log.md 记录：
```
## [ISO时间] ingest | 批量同步完成
- 总 repo 数: N (ingest: A, diff: B, lint: C, 失败: D)
- 总页面数: X (新建: Y, 更新: Z)
- 下一步建议: /lcw-lint
```
