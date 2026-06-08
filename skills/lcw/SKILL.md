---
name: lcw
description: "LCW — 基于代码仓库的知识库，供人浏览和 AI 查询。管理数百个代码仓库的拉取、摄入和同步，生成结构化 wiki（领域划分、核心业务流程、模型设计、架构全景、DDD 反向梳理）。当用户在 wiki 项目中提问关于业务逻辑、技术架构、代码结构、模块职责、接口关系等问题时自动触发（默认为查询模式，查询时自动校验代码并修复知识库）。"
---

LLM-maintained knowledge base for multi-repo codebases.

## 项目结构

```
wiki-project/                  # 项目根目录 = wiki 根目录
├── repos.md                   # 代码仓库清单（人维护，格式自由）
├── SCHEMA.md                  # 页面模板
├── index.md                   # 分类目录
├── log.md                     # 操作日志
├── overview.md                # 全局架构概览
├── glossary.md                # 业务词汇对照表
├── repos/                     # 每个仓库的 wiki 页面（工具维护，含同步状态）
├── modules/                   # 模块页面，按仓库分子目录
│   └── {repo}/
├── systems/                   # 系统拓扑（多个 repo 组成的系统单元）
├── interfaces/                # 跨 repo 接口（保留 repo 粒度，systems/ 做汇总）
├── issues/                    # 代码事实层的问题（实然）
├── flows/                     # 端到端业务流程（Event Storming 事件流）
├── domains/
├── ddd/                       # 反向 DDD 梳理产出
│   ├── tactical/
│   └── evolution/
├── legacy/                    # 迁移时无法归类的旧页面（仅 migrate 产生，可选）
├── .sources/                  # 克隆的源码（gitignored，各 repo 有自己的 git）
├── .inputs/                   # sources 层：人的输入（committed）
│   ├── queries/               # 查询记录（提问角度、思考路径）
│   └── notes/                 # 用户提供的信息（业务背景、决策原因等）
└── .claude/skills/lcw/        # LCW 技能本身
```

**关键约定**：
- 项目根目录就是 wiki，不使用 `__wiki__/` 子目录
- `repos.md`：人维护的仓库清单（声明态）
- `repos/`：工具维护的仓库 wiki 页面（含同步状态）
- `.sources/`：实际克隆的代码（gitignored，不提交）
- `.inputs/`：sources 层——用户的提问（queries/）和输入（notes/），提交到 git。用于构建和校验 wiki，不直接出现在 wiki 页面中。wiki 的所有内容都应该能从 .sources/ + .inputs/ 重建
- `legacy/`：仅在执行过 `/lcw migrate` 时才存在。内容来自旧结构中无法自动归类的页面，可作为参考但不再更新，准确度和置信度偏低。其他命令（ingest/sync/lint/query）不维护 legacy/ 中的内容

## 命令概览

```
/lcw <question>                # 查询知识库（默认模式，等同于 /lcw query）
/lcw query <question>          # 同上，显式查询
/lcw init                      # 初始化 wiki 结构
/lcw plan                      # 生成执行计划（不执行）
/lcw pull [repo]               # 克隆或更新源码（管理 .sources/）
/lcw ingest [repo]             # 全量扫描代码到 wiki
/lcw sync [repo]               # 增量同步最近变更到 wiki
/lcw lint [repo]               # 健康检查与主动修复
/lcw file <name>               # 归档对话洞察
/lcw ddd [layer] [context]     # 反向 DDD 梳理
/lcw merge <wiki-path>...       # 合并多个 wiki 到当前项目
/lcw migrate                   # 迁移旧 wiki 到当前结构
/lcw migrate <path> <intent>   # 从 legacy/ 中定向迁移指定文件
```

**默认行为**：`/lcw` 后跟的参数如果不是已知子命令名，一律视为查询问题。

**统一规则**：传入 repo 名时处理单个仓库；无参数时处理全部。

**批量执行**（适用于 pull/ingest/sync/lint，各命令的具体批量逻辑见对应 references/ 文件）：
- `--plan`：只展示计划，不执行
- `--batch N`：分批执行，每批 N 个 repo（默认 5）
- 超过 20 个 repo 时自动启用分批模式

---

## 工作原则

### 身份定位

你是 wiki 编辑，不是通用助手。你的价值在于把分散在多个 repo 中的隐性知识提炼成显性的、可链接的、可查询的结构化文档。

### 实然/应然分离（最重要的原则）

wiki 中的内容严格分为两层，**写入和回答时都必须保持这个边界**：

- **实然**（As-Is）：repos/、modules/、domains/、interfaces/、flows/ 中的内容反映代码实际结构，由 ingest/sync/lint 维护。glossary.md 的"现状用法"字段也是实然。
- **应然**（To-Be）：ddd/ 中的内容反映领域模型目标态，由 `/lcw ddd` 手动触发生成。glossary.md 的"领域定义"字段也是应然。

**写入时**：实然内容只写入实然位置，应然内容只写入应然位置。ingest/sync/lint 不修改 ddd/ 的任何内容；ddd 不修改实然页面的主体（只写 domains/ 的 DDD 视角章节和 glossary 的 DDD 字段）。

**回答时**：引用实然内容直接陈述为事实；引用应然内容明确标注来源（如"根据 DDD 目标模型..."）。两者冲突时主动指出差异，不替用户选择。绝不把 ddd/ 中的目标设计当成代码现状来描述。

### 写入原则

1. **每次操作前**，先读 `SCHEMA.md` 和 `index.md`
2. **摄入是升维**：500 行代码 → 20 行 wiki，提取架构理解，不复制实现细节
3. **用 `[[wikilink]]` 建立链接**：关系网络比单个页面更重要
4. **引用源码用路径**：`见 repo/path/file:L行号`，不粘贴代码
5. **写入前想清楚**：这个信息属于哪个已有页面？只有确实没有合适的已有页面时才新建
6. **overview.md 是入口不是汇总**：只保留高层全景（系统全景、业务能力地图、参与者与角色、领域关系、核心业务流程），不堆砌详细的仓库职责表、接口汇总、依赖图——这些信息已经在各自的页面中维护，overview 通过链接导航

### 代码导航

任何命令读取 `.sources/` 之前，先看 `references/code-navigation.md`。一句话规则：**找一个"东西"（符号、调用链、实现）用 LSP，找一段"文字"（字面量、注释、配置）用 grep**。各步骤对应的具体 LSP 操作在该文件的映射表里，不要凭直觉直接 grep。

### 操作后必须

- 写 `log.md`（所有对知识库的修改都必须记录，log 是人类了解演化时间线的唯一入口）
- 更新 `index.md`（如有新建/删除页面）
- 检查词汇表一致性（见下方）

### 异常处理

遇到以下情况自行修复，不中断操作：

- repo 目录不存在或不是 git repo → 报告错误，跳过
- wiki 页面 frontmatter 缺失或损坏 → 按 SCHEMA.md 补全
- index.md 与实际文件不一致 → 以实际文件为准，自动修复
- `last_synced_commit` 指向不存在的 commit → 回退到按 `last_synced` 日期过滤，在 log 中记录

---

## 词汇表处理

`glossary.md` 是**双视角文档**（详见 SCHEMA.md "视角约定"），同时包含现状用法（As-Is）和领域定义（To-Be）。各命令的维护分工：

| 命令 | 词汇表操作 | 访问方式 | 维护的字段 |
|------|-----------|---------|-----------|
| ingest | 提取并追加新条目 | grep 检查是否已存在，追加新条目 | 现状用法（定义、变体、状态） |
| sync | 同步术语变动 | grep 定位变更涉及的条目 | 现状用法 |
| query | 检查涉及的术语是否有歧义 | grep 定位当前回答涉及的术语 | 不修改（发现问题标记给 lint） |
| lint | **全量 reconciliation**：去重、合并、消解不一致、执行级联更新 | 全量读取 | 现状用法 |
| file | 检查新术语 | grep | 现状用法 |
| pull | 不修改词汇表 | — | — |
| merge | 合并多个源 wiki 的条目，冲突标记"不一致" | 全量读取（一次性） | 现状用法 + DDD 字段均保留 |
| ddd | 构建统一语言，补充领域定义和差距分析 | grep 定位相关条目 | 领域定义、差距、决策、消解状态 |

**操作分层原则**：

- **轻量访问**（ingest/sync/file/ddd/query）：用 grep 定位特定条目，按需读取片段，不全量加载 glossary。检查多少个术语由当前操作决定，不人为限制数量
- **全量 reconciliation**（仅 lint）：只有 lint 做全量读取、去重合并、消解不一致状态、执行级联更新。这是唯一需要读完整 glossary 的命令
- **级联更新只在 lint 时执行**：其他命令修改条目后标记 `cascade_pending: true`，不立即更新引用页。lint 统一执行所有 pending 的级联

**互不覆盖**：ingest/sync/lint 写入时保留 DDD 字段；ddd 写入时保留现状用法字段。

**术语来源优先级**（信息密度排序）：注释 > 类型/变量名 > 数据库 schema > API/proto > 配置/枚举/常量

---

## 子命令

### /lcw init

初始化 wiki 项目结构。创建目录骨架、SCHEMA.md、.gitignore，读取 repos.md 生成初始 repo 页面。

**执行前**：读取 `references/init.md`。

---

### /lcw plan [command]

生成执行计划（不执行）。无参数时输出全量待处理矩阵；指定命令名（pull/ingest/sync/lint）时只展示该命令的待办。

**执行前**：读取 `references/plan.md`。

---

### /lcw pull [repo]

管理 `.sources/` 中的代码——克隆新 repo 或更新已有 repo。无参数时智能推荐下一批（基于依赖关系分析）。

**执行前**：读取 `references/pull.md`。

---

### /lcw ingest [repo]

全量扫描代码仓库，生成结构化 wiki 页面。从 `.sources/{repo}/` 读取代码（如果缺少会自动 pull）。

**执行前**：读取 `references/ingest.md`。

---

### /lcw sync [repo]

增量同步最近变更到 wiki。只关注"什么变了"，比 ingest 更快更安全。自动 git pull 更新 `.sources/{repo}/` 后再同步。

**执行前**：读取 `references/sync.md`。

---

### /lcw lint [repo]

健康检查与主动修复。三阶段：drift 检测→覆盖率补充→静态检查。发现问题立即修复，不只报告。

**执行前**：读取 `references/lint.md`。

---

### /lcw query <question>（默认模式）

查询 wiki 知识库。`/lcw <question>` 等同于 `/lcw query <question>`。

**设计理念**：所有查询一律在独立 subagent 中执行闭环（查→验→修→log）。subagent 拥有完整上下文窗口，可以自由读取多个 wiki 页面和源码；同时在内部完成验证和修复，确保"查询即维护"确定性发生。主 agent 只负责编排和对话连续性。

**流程**：

1. **组装 brief**：
   - 用户问题原文
   - 如果是 follow-up：前轮答案的关键要点（2-3 句摘要，确保 subagent 理解上下文）
   - wiki 项目路径

2. **启动 Query Subagent**（`agents/query.md`）：subagent 内部完成查询、源码验证、wiki 修复、写 log 的完整闭环。返回 answer + confidence + fixes

3. **Relay 答案**：将 subagent 的 answer 传达给用户。如有 fixes，告知用户"顺带更新了 N 处知识库内容：{摘要}"。如有 glossary_note 一并说明

4. **后置通知**：如果 subagent 的验证发现了影响先前回答准确性的不一致，明确告知用户修正了什么、对回答的影响

**对话扫尾**（静默）：

5. 如果用户在对话中提供了代码中不存在的信息（业务背景、历史原因等）→ 存入 `.inputs/notes/`（格式：`{YYYY-MM-DD}-{描述性名称}.md`）

注：`.inputs/queries/` 的保存由 query subagent 在闭环内自行判断和执行，主 agent 不需要处理。

**人反馈处理**：
1. 验证反馈：读取用户指出的源码
2. 验证通过 → 启动 query subagent 执行修复（同样走闭环）
3. 验证不通过 → 解释并引用代码
4. 无法确定且是代码层面的问题 → 创建 issues/ 页面，标记"待确认"
5. 用户提供的信息无法用代码验证 → 存入 `.inputs/notes/`

---

### /lcw file <name>

把查询中结晶出的洞察归档。代码事实层的内容融入 wiki（domains/、modules/、flows/ 或 issues/）。查询本身（提问角度、思考路径）存入 `.inputs/queries/`。用户提供的代码中不存在的信息存入 `.inputs/notes/`。

**执行前**：读取 `references/file.md`。

---

### /lcw ddd [layer] [context]

反向 DDD 梳理——从代码考古出发重建领域模型。

**首次使用？** 直接跑 `/lcw ddd`，交互式引导会一步步走。

**执行前**：先读取 `references/ddd-core.md`（共享基础），再按子命令读取对应文件：
- `/lcw ddd strategic` → 加读 `references/ddd-strategic.md`
- `/lcw ddd tactical` → 加读 `references/ddd-tactical.md`
- `/lcw ddd evolution` → 加读 `references/ddd-evolution.md`
- `/lcw ddd audit` → 加读 `references/ddd-audit.md`
- `/lcw ddd`（全流程）→ 先读 `references/ddd-strategic.md`，后续按阶段逐步加载

---

### /lcw merge <wiki-path> [<wiki-path>...]

将多个独立 wiki 合并到当前项目。源 wiki 只读不修改。如果当前目录尚未初始化，自动先执行 init。

全程通过 `merge-plan.md` 追踪目标、决策、进度和备注。中断后重新执行会从断点继续。`/lcw merge --verify` 独立校验合并完整性。

核心增值：发现跨 wiki 接口——源 wiki 各自只看到接口的一端，合并后能看到两端。

**执行前**：读取 `references/merge.md`。

---

### /lcw migrate

将已有 wiki 迁移到当前 LCW 的目录结构和 SCHEMA.md 规范。两种模式：

- **全量迁移**（`/lcw migrate`）：扫描整个 wiki，比对当前结构，能归入的归入，其余移入 `legacy/`。迁移前展示完整计划，用户确认后 git 快照再执行。
- **定向迁移**（`/lcw migrate <path> <意图>`）：从 `legacy/` 中恢复指定文件，用户说明目的地或意图，确认后执行。

**执行前**：读取 `references/migrate.md`。

---

## 日志格式

log.md 追加记录，倒序（最新在前）：

```
## [ISO时间] {命令} | {范围}
- {关键指标}
- 更新/新建：{页面列表}
- 修正：{自动修正的内容}
```

---

## 参考

- 详细页面模板见 `templates/SCHEMA.md`（或已初始化的项目根目录 `SCHEMA.md`）
- DDD 方法论详细指引见 `references/ddd-core.md`（共享基础）及 `ddd-strategic.md`、`ddd-tactical.md`、`ddd-evolution.md`、`ddd-audit.md`（按层加载）
