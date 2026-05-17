# LCW Spec

> 本文件是 LCW 项目的需求基准，用于迭代时检查是否偏离原始目标。

## 产品定位

LCW 是一个**基于代码仓库的知识库**，同时服务人和 AI：
- **人**：浏览领域划分、核心业务流程、模型设计、架构全景
- **AI**：回答关于业务和技术的各种问题，并在回答过程中持续修正和增强 wiki

不是代码搜索工具，不是文档生成器。核心价值是把散落在几百个 repo 中的隐性知识编织成显性的、可链接的、可查询的结构化知识网络。

## 项目结构

项目根目录就是 wiki 本身，不使用子目录包装。

```
wiki-project/
├── repos.md          # 代码仓库清单（人维护，格式自由的 markdown）
├── repos/            # 每个仓库的 wiki 页面（工具维护，含同步状态）
├── .sources/         # 实际克隆的源码（gitignored）
├── .claude/skills/lcw/  # LCW 技能（通过 symlink 引入）
└── ...（wiki 页面目录）
```

三个同源概念用不同命名区分：
- `repos.md` — 声明态清单
- `repos/` — wiki 文档
- `.sources/` — 实际代码

Wiki 内容用 git 管理；`.sources/` 在 .gitignore 中，不提交。

## 规模设计

- 目标：支撑数百到上千个代码仓库
- 不能一次全拉取，按构建理解的顺序增量加载
- 三级状态：**未拉取 → 已探测（probe）→ 已摄入（ingest）**
- 默认浅克隆（`--depth 1`），需要历史时按需加深
- 工具能智能推荐下一批该拉什么（基于依赖关系分析）

## 命令体系

`/lcw` 是唯一的 skill 入口，子命令通过参数分发。

| 命令 | 触发方式 | 作用 |
|------|---------|------|
| `/lcw <question>` | **默认模式，可自动触发** | 查询知识库 |
| `/lcw init` | 手动 | 初始化 wiki 结构 |
| `/lcw plan` | 手动 | 生成执行计划 |
| `/lcw pull [repo]` | 手动 | 克隆或更新源码 |
| `/lcw ingest [repo]` | 手动 | 全量扫描代码到 wiki |
| `/lcw sync [repo]` | 手动 | 增量同步最近变更到 wiki |
| `/lcw lint [repo]` | 手动 | 健康检查与修复 |
| `/lcw file <name>` | 手动 | 归档对话洞察 |
| `/lcw activities <action>` | 手动 | 提交活动分析 |
| `/lcw ddd [layer] [context]` | 手动 | 反向 DDD 梳理 |

只有 query 需要自动触发，其他都是显式手动执行。

## 核心原则

### 实然/应然分离

这是最重要的原则，贯穿写入和回答全过程。

- **实然（As-Is）**：repos/、modules/、domains/、interfaces/、flows/ 反映代码实际结构。由 ingest/sync/lint 维护。
- **应然（To-Be）**：ddd/ 反映领域模型目标态。由 `/lcw ddd` 手动触发生成。
- **glossary.md** 是双视角文档："现状用法"是实然，"领域定义"是应然。

写入时不混、回答时标注来源、冲突时呈现差异。绝不把目标设计当成代码现状来描述。

### Query 是活的

query 不是只读操作。每次查询都回溯源码验证 wiki 描述是否正确，发现不一致立即修正。修正了 wiki 才写 log，纯查询不写 log。

### DDD 不独立拆分

DDD 是 `/lcw` 的子命令，不拆成独立 skill。理由：
- DDD 的 references 已经按需加载（ddd-core/strategic/tactical/evolution/audit），不浪费上下文
- DDD 读写 wiki 的方式与其他命令一致（共享项目结构、glossary 规则、wiki 集成约定）
- DDD 产出需要被 query 理解和引用，放在同一个 skill 内协调更简单

## Skill 架构

### 单 skill + 按需 references

```
skills/lcw/
├── SKILL.md           # ~250 行，共享原则 + 命令路由 + query 内联
└── （references 在项目根 references/ 下，通过 symlink 共享）

references/
├── init.md            # 各命令详情，按需加载
├── pull.md
├── ingest.md
├── sync.md
├── lint.md
├── file.md
├── activities.md
├── ddd-core.md        # DDD 共享基础
├── ddd-strategic.md   # DDD 各层详情
├── ddd-tactical.md
├── ddd-evolution.md
└── ddd-audit.md
```

SKILL.md 每次全量加载；references 只在对应命令执行时加载。这样 `/lcw 这个模块是干什么的` 只加载 ~250 行，而不是 800+ 行。

### 分发方式

当前使用 symlink 部署到各项目（`ln -s ~/.lcw .claude/skills/lcw`）。未来在以下任一条件满足时升级为 plugin：
- 需要分发给团队成员
- 需要 MCP server、hooks 等 plugin 专属能力
- 需要 marketplace 分发

## 不做的事

- 不做代码搜索（有专门的工具）
- 不做自动触发 ingest/sync/lint/ddd（这些是重操作，必须手动）
- 不做代码修改（`.sources/` 只读）
- 不做实时监控（wiki 是快照，通过 sync/lint 手动刷新）
- 不在 wiki 中粘贴源代码（只引用路径）
