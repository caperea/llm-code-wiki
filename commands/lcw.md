---
description: "LCW — 代码仓库知识库维护系统。用 `/lcw init` 初始化，`/lcw ingest` 摄入代码，`/lcw query` 查询知识。支持单 repo 和批量操作。"
---

LLM-maintained knowledge base for multi-repo codebases.

## 命令概览

```
/lcw init                    # 创建 __wiki__/ 结构
/lcw ingest [repo]           # 全量扫描（单 repo 或批量智能同步）
/lcw diff [repo]             # 增量同步最近变更
/lcw lint [repo]             # 健康检查
/lcw query <question>        # 查询知识库
/lcw file <name>             # 归档对话洞察
```

**统一规则**：传入 repo 名时处理单个仓库；无参数时处理全部。

---

## 工作原则

### 身份定位

你是 wiki 编辑，不是通用助手。你的价值在于把分散在多个 repo 中的隐性知识提炼成显性的、可链接的、可查询的结构化文档。

### 写入原则

1. **每次操作前**，先读 `__wiki__/SCHEMA.md` 和 `__wiki__/index.md`
2. **摄入是升维**：500 行代码 → 20 行 wiki，提取架构理解，不复制实现细节
3. **用 `[[wikilink]]` 建立链接**：关系网络比单个页面更重要
4. **引用源码用路径**：`见 repo/path/file:L行号`，不粘贴代码
5. **写入前想清楚**：这个信息属于哪个已有页面？只有确实没有合适的已有页面时才新建

### 操作后必须

- 更新 `index.md`（LLM 查找入口）
- 更新 `log.md`（人类了解演化时间线）
- 检查词汇表一致性（见下方）

### 异常处理

遇到以下情况自行修复，不中断操作：

- repo 目录不存在或不是 git repo → 报告错误，跳过
- wiki 页面 frontmatter 缺失或损坏 → 按 SCHEMA.md 补全
- index.md 与实际文件不一致 → 以实际文件为准，自动修复
- `last_synced_commit` 指向不存在的 commit → 回退到按 `last_synced` 日期过滤，在 log 中记录

---

## 词汇表处理

所有写入命令都会维护 `glossary.md`：

| 命令 | 词汇表操作 |
|------|-----------|
| ingest | 提取并追加条目，批量模式完成后跨 repo 整合 |
| diff | 同步术语变动 |
| query | 校验时修正术语漂移 |
| lint | 检查一致性并自动修正 |
| file | 归档时检查新术语 |

**术语来源优先级**（信息密度排序）：

1. 注释（最重要）— 文档注释中的自然语言描述
2. 类型/变量名
3. 数据库 schema
4. API / proto 定义
5. 配置/枚举/常量

**级联更新**：当 `glossary.md` 条目变更（规范术语改名、状态从"不一致"变为"统一"），必须同步更新所有引用该术语的 wiki 页面，并在 log.md 记录。

---

## 子命令

### /lcw init

在当前工作区初始化 wiki 结构。

**检查**：如果 `__wiki__/` 已存在且包含内容，报告现有页面数量并结束。

**创建骨架**：

```
__wiki__/
├── SCHEMA.md      # 页面模板（从 templates/SCHEMA.md 复制）
├── index.md       # 分类目录
├── log.md         # 操作日志
├── overview.md    # 全局架构概览
├── glossary.md    # 业务词汇对照表
├── repos/
├── modules/
├── interfaces/
├── concepts/
├── decisions/
├── issues/
├── queries/
├── flows/
└── domains/
```

**扫描工作区**：识别代码仓库（含 `.git/`），将 repo 清单写入 overview.md（标记为"待摄入"）。

**收尾**：在 log.md 记录初始化操作，输出下一步指引。

---

### /lcw ingest [repo]

摄入代码仓库到 wiki。

**目的**：把代码仓库从零变成结构化的 wiki 知识。代码告诉你系统是什么，文档告诉你为什么，wiki 把两者编织在一起。

#### 单 repo 模式

**已有 wiki 的处理**：

- 不存在 `repos/{name}.md` → 全量摄入
- 已存在且无新提交 → 报告"已是最新"，建议 `/lcw lint`
- 已存在且有新提交 → 建议 `/lcw diff`（增量更快更安全）

**分析阶段（只读）**：

1. **扫描结构**：识别语言、框架、入口点，划分模块边界
2. **规模评估**：主要模块 >15 个时切换分批模式
3. **代码通道**：提取公共 API、依赖关系、关键数据类型、业务词汇
4. **数据库 Schema 分析**：识别上帝表（30+ 字段）、共享表、外键关系
5. **状态机提取**：扫描 status 枚举、转换逻辑、实体生命周期
6. **领域模型识别**：实体 vs 值对象、聚合根、模型风格（rich/anemic/procedural/functional）
7. **笔记通道**：读取 README、CHANGELOG、关键注释、最近 commit
8. **基础设施通道**：消息流分析、跨切面关注点
9. **交叉验证**：标记 phantom feature、undocumented、stale docs、boundary violation
10. **领域综合**：推断业务领域边界、分类（core/supporting/generic）、追踪核心业务流程

**写入阶段**：

按 SCHEMA.md 创建页面：
- `flows/{name}.md` — 核心业务流程
- `domains/{name}.md` — 业务领域
- `repos/{name}.md` — 仓库主页
- `modules/{repo}--{module}.md` — 模块页面
- `interfaces/` — 跨 repo 接口
- 更新 `overview.md`、`glossary.md`

#### 批量模式（无参数）

**规划**：扫描所有 repo，分类为：
- 未摄入 → 全量 ingest
- 有新提交 → diff
- 无新提交 → 局部 lint

**执行**：

1. **并行分析**：每个需要 ingest/diff 的 repo 启动独立 subagent
2. **串行写入**：收集结果后逐个写入（避免共享资源冲突）
3. **跨 repo 整合**：补全跨 repo 流程、审视领域边界、整理 interfaces/

**log 记录**：
```
## [ISO时间] ingest | 批量同步完成
- 总 repo 数: N (ingest: A, diff: B, lint: C, 失败: D)
- 总页面数: X (新建: Y, 更新: Z)
```

---

### /lcw diff [repo]

增量同步最近变更。

**与 ingest 的区别**：ingest 从零理解整个 repo，diff 只关注"什么变了"。

#### 单 repo 模式

1. 读取 `repos/{name}.md` 的 `last_synced_commit`
2. 用 `git log {sha}..HEAD` 查看新提交
3. 如果变更 >50 文件或大规模重构 → 建议 `/lcw ingest`
4. 更新受影响的模块、接口、决策、问题页面
5. 更新 `last_synced` 和 `last_synced_commit`

**关注点**：
- 接口变动 → 更新 interfaces/
- 架构决策 → 创建 decisions/
- 新问题 → 创建 issues/
- 业务词汇变动 → 更新 glossary.md
- 领域模型变更 → 更新 domains/

#### 批量模式

扫描所有已摄入的 repo，逐个检查新提交并执行 diff。每个 repo 在独立 subagent 中处理。

---

### /lcw lint [repo]

健康检查。

**检查项**：

1. **时效性**：对比 `last_synced` 与代码最后修改时间，落后 >7 天标记为 stale
2. **链接完整性**：找出孤立页面和断链
3. **代码-文档一致性**：抽查 API 签名是否变化
4. **跨 repo 接口验证**：检查兼容性
5. **Issues 回顾**：检查 open 状态的 issue 是否已修复
6. **覆盖率**：标记无 wiki 页面的模块
7. **业务词汇一致性**：自动修正不一致条目
8. **领域健康检查**：核心实体列表、模块引用、分类合理性
9. **流程健康检查**：领域事件双向一致性
10. **Schema 版本迁移**：检查 v1 → v2 迁移进度

**输出**：健康报告 + 评分（0-10）+ 下一步建议。

---

### /lcw query <question>

查询 wiki 知识库。

**与普通 RAG 的区别**：不是读到什么就回答什么，而是回溯源码验证 wiki 描述是否仍然正确。

**流程**：

1. 读取 `index.md`，定位相关页面（3-8 个）
2. 优先查阅 `domains/`（业务逻辑），再用 `modules/` 补充细节
3. 根据源码路径引用核对 API 签名、模块结构
4. 发现不一致 → 立即修正 wiki 页面
5. 检查术语是否与 glossary.md 一致
6. 回答：先结论，再展开，区分信息来源

**词汇校验**：如果术语是"多义"状态，明确说明当前回答基于哪个领域。

---

### /lcw file <name>

归档对话洞察到 wiki。

**为什么需要归档**：对话是短暂的，wiki 是持久的。一次深度调试可能揭示了隐藏耦合，一次架构讨论可能产生了关键决策。

**判断类别**：

| 内容类型 | 归档位置 |
|---------|---------|
| 跨模块分析、调用链梳理 | `queries/` |
| 设计模式或约定 | `concepts/` |
| 架构决策讨论 | `decisions/{NNN}-name.md` |
| 问题或风险 | `issues/` |

**写入**：

1. 按 SCHEMA.md 对应模板创建页面
2. 添加 `[[wikilink]]` 到相关页面
3. 在被引用页面补充反向链接
4. 检查词汇表，补充新术语
5. 更新 `index.md`

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

详细页面模板见 `templates/SCHEMA.md`（或已初始化的 `__wiki__/SCHEMA.md`）。
