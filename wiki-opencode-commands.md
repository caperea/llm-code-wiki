# Multi-Repo Wiki：OpenCode 命令与配置方案

> **这是设计文档。** 规范实现见 `wiki-opencode-kit/`，以 kit 中的文件为准。

## 设计思路

根据 LLM Wiki 的原始思想，核心操作只有三个：**Ingest、Query、Lint**。
但在多 repo 代码库场景下，代码和笔记的区别要求我们做更细致的拆分。

最终提炼出 **5 个命令 + 1 个 Agent + 1 个 AGENTS.md**：

```
命令 (commands)          触发方式             本质
──────────────────────────────────────────────────────
/lcw ingest                  /lcw ingest repo-alpha   摄入：把 raw 变成 wiki 知识
/lcw diff                    /lcw diff repo-alpha     增量：只处理最近变更
/lcw query                   /lcw query 认证流程      查询：从 wiki 回答问题
/lcw lint                    /lcw lint                体检：wiki 健康检查
/lcw file                    /lcw file auth-deep-dive 归档：把对话内容存入 wiki
```

为什么是这 5 个？

- **ingest** 和 **diff** 分开，因为全量摄入和增量同步是完全不同的工作流——全量要扫描整个 repo 结构，增量只看 git diff
- **query** 是最常用的操作，需要一个专门入口而不是"直接问"——因为它有特定的工作流（先读 index → 定位页面 → 读页面 → 必要时回溯源码）
- **lint** 是维护操作，定期跑
- **file** 解决 LLM Wiki 的核心洞察：好的对话结果应该回流到 wiki，而不是消失在聊天历史里

---

## 文件结构

```
workspace/
├── .opencode/
│   ├── agents/
│   │   └── wiki.md            # wiki 维护专用 subagent
│   └── commands/
│       ├── ingest.md          # /lcw ingest 命令
│       ├── diff.md            # /lcw diff 命令
│       ├── query.md           # /lcw query 命令
│       ├── lint.md            # /lcw lint 命令
│       └── file.md            # /lcw file 命令
├── AGENTS.md                  # 项目级指令
├── opencode.json              # OpenCode 配置
│
├── repo-alpha/                # 代码仓库（raw，不改动）
├── repo-beta/
├── repo-gamma/
│
└── __wiki__/                  # LLM 维护的知识库
    ├── SCHEMA.md
    ├── index.md
    ├── log.md
    ├── repos/
    ├── modules/
    ├── interfaces/
    ├── concepts/
    ├── decisions/
    ├── issues/
    └── queries/
```

---

下面是每个文件的完整内容。

---

## AGENTS.md

```markdown
# 多 Repo 代码库 Wiki 系统

本工作区包含多个代码仓库和一个 LLM 维护的 wiki 知识库。

## 核心规则

1. **只写 `__wiki__/`**：所有 repo 目录是只读输入，绝不修改任何 repo 中的文件
2. **代码是事实**：当 wiki 描述与代码矛盾时，以代码为准，更新 wiki
3. **笔记需验证**：README、注释、文档提供上下文，但可能过时，需与代码交叉验证
4. **wiki 记录理解，不复制代码**：页面中不粘贴大段源码，用路径引用 `repo/path/lcw file.go:L10-L30`
5. **每次写操作后更新 `index.md` 和 `log.md`**

## 项目结构

- `repo-*/` — 代码仓库，只读输入（相当于 raw source）
- `__wiki__/` — LLM 维护的知识库，唯一可写区域
- `__wiki__/SCHEMA.md` — wiki 的结构约定和页面模板，操作前必读

## Wiki 操作

使用自定义命令操作 wiki：
- `/lcw ingest <repo>` — 首次全量摄入一个仓库
- `/lcw diff <repo>` — 增量同步最近变更
- `/lcw query <问题>` — 查询 wiki
- `/lcw lint` — wiki 健康检查
- `/lcw file <名称>` — 把当前对话内容归档到 wiki

## 代码 vs 笔记

操作 wiki 时始终区分两类输入：
- **代码**（.go, .py, .ts, .rs, ... 及配置文件）→ 结构化提取：模块边界、API、依赖图、数据类型
- **笔记**（README, ARCHITECTURE.md, CHANGELOG, 注释, commit message）→ 语义化整合：动机、决策、上下文

两者在 wiki 中交织——代码告诉你 what，笔记告诉你 why，wiki 编织两者。
```

---

## opencode.json

```jsonc
{
  "instructions": [
    "__wiki__/SCHEMA.md"
  ]
}
```

这让 OpenCode 在每次会话中自动加载 SCHEMA.md 作为上下文，LLM 始终知道 wiki 的结构约定。

---

## .opencode/agents/wiki.md

```markdown
---
description: "Wiki 维护专用 agent，处理 ingest/lcw diff/lcw lint/lcw file 等写操作"
mode: "subagent"
---

你是一个代码库知识库的维护者。你的职责是读取代码仓库（只读），
维护 `__wiki__/` 目录中的 markdown 知识库。

## 你的身份

你不是通用助手。你是一个 wiki 编辑，专注于：
- 准确提取代码结构（模块、API、依赖、数据流）
- 整合文档上下文（动机、决策、历史）
- 发现代码与文档的矛盾
- 维护跨 repo 的关系图谱

## 工作原则

1. 先读 `__wiki__/SCHEMA.md` 了解页面模板和命名约定
2. 先读 `__wiki__/index.md` 了解现有页面
3. 写入前思考：这个信息属于哪个页面？是新建还是更新？
4. 代码摄入 = 升维：从实现细节上升到架构理解
5. 笔记摄入 = 验证：与代码交叉核对，标记差异
6. 每次操作结束后更新 index.md 和 log.md
7. 使用 wikilink 语法 `[[page]]` 建立页面间链接
```

---

## .opencode/commands/lcw ingest.md

```markdown
---
description: "全量摄入一个仓库到 wiki"
agent: "wiki"
---

全量摄入仓库 `$ARGUMENTS` 到 wiki。按以下步骤执行：

## 第一步：准备

1. 读取 `__wiki__/SCHEMA.md` 了解页面模板
2. 读取 `__wiki__/index.md` 了解已有页面（避免重复创建）
3. 确认目标仓库 `$ARGUMENTS` 存在

## 第二步：扫描结构

4. 列出仓库的目录结构（2-3 层深度）
5. 识别：主要语言、框架、构建系统、入口点
6. 识别：模块/包/服务的边界划分

## 第三步：代码通道（提取 what）

7. 对每个主要模块：
   - 提取公共 API（导出函数、类型、接口）
   - 提取依赖关系（import/require 分析）
   - 识别关键数据类型和结构
8. 扫描路由定义、配置文件、proto/schema 文件
9. 识别与其他 repo 的接口点（gRPC, REST, event, shared DB）

## 第四步：笔记通道（提取 why）

10. 读取 README.md, ARCHITECTURE.md, CONTRIBUTING.md, CHANGELOG
11. 提取有意义的代码注释（TODO, HACK, FIXME, 架构决策注释）
12. 查看最近 20 条 commit message 了解变更趋势

## 第五步：交叉验证

13. 对比笔记描述与代码实际结构
14. 标记差异：文档说有但代码没有（phantom）、代码有但文档没说（undocumented）

## 第六步：写入 wiki

15. 创建或更新 `__wiki__/repos/{repo}.md`（仓库主页）
16. 为每个主要模块创建 `__wiki__/modules/{repo}--{module}.md`
17. 如发现跨 repo 接口，创建 `__wiki__/interfaces/{name}.md`
18. 如发现值得记录的设计模式，创建 `__wiki__/concepts/{name}.md`
19. 如发现问题或矛盾，创建 `__wiki__/issues/{name}.md`

## 第七步：收尾

20. 更新 `__wiki__/index.md`（添加所有新建/更新的页面）
21. 在 `__wiki__/log.md` 追加本次操作记录，格式：
    `## [ISO时间] ingest | {repo名} \n - 创建: ... \n - 更新: ... \n - 发现: ...`

## 注意

- 页面中不粘贴大段代码，用路径引用：`见 repo/path/lcw file:L行号`
- 使用 `[[wikilink]]` 链接相关页面
- 遵循 SCHEMA.md 中的页面模板格式
```

---

## .opencode/commands/lcw diff.md

```markdown
---
description: "增量同步仓库最近变更到 wiki"
agent: "wiki"
---

增量同步仓库 `$ARGUMENTS` 的最近变更到 wiki。

## 步骤

1. 读取 `__wiki__/SCHEMA.md` 和 `__wiki__/index.md`
2. 在仓库 `$ARGUMENTS` 中执行 `git log --oneline -20` 查看最近提交
3. 找到对应 wiki 页面的 `last_synced` 日期
4. 用 `git diff` 或 `git log --stat` 确定自上次同步以来的变更范围
5. 对每个受影响的模块：
   - 重新读取变更的文件
   - 更新对应的 `modules/` 页面
6. 如果变更涉及接口变动（新增/修改 API、proto、路由），更新 `interfaces/` 页面
7. 如果变更包含架构级决策，创建 `decisions/` 页面
8. 如果发现新问题，创建 `issues/` 页面
9. 更新所有受影响页面的 `last_synced` 字段
10. 更新 `index.md`，追加 `log.md`

## 注意

- 增量同步关注"什么变了"，不需要重新理解整个 repo
- 如果变更范围太大（如大规模重构），建议改用 `/lcw ingest` 全量重建
```

---

## .opencode/commands/lcw query.md

```markdown
---
description: "查询 wiki 知识库"
---

基于 wiki 知识库回答问题：`$ARGUMENTS`

## 步骤

1. 读取 `__wiki__/index.md` 扫描所有页面标题和摘要
2. 根据问题定位 3-8 个最相关的 wiki 页面
3. 读取这些页面内容
4. 如果 wiki 信息不足以回答：
   - 根据页面中的源码路径引用，回溯到原始代码补充细节
   - 在回答中标注哪些信息来自 wiki、哪些来自直接读码
5. 综合生成回答，引用具体的 wiki 页面 `[[page]]`
6. 评估：这个回答是否有长期复用价值？
   - 如果是（跨模块分析、架构洞察、流程梳理）→ 建议用户 `/lcw file` 归档
   - 如果否（简单事实查询）→ 直接结束

## 回答风格

- 先给结论，再展开细节
- 用 wiki 页面链接代替冗长解释："详见 [[modules/alpha--auth]]"
- 如果发现 wiki 中的信息可能过时，明确标注
```

---

## .opencode/commands/lcw lint.md

```markdown
---
description: "Wiki 健康检查"
agent: "wiki"
---

对 `__wiki__/` 执行健康检查。

## 检查项

### 1. 时效性检查
- 读取每个 wiki 页面的 `last_synced` frontmatter
- 对比对应 repo/模块的最后修改时间（`git log -1 --format=%ci -- path`）
- 标记所有 `last_synced` 落后超过 7 天的页面为 **stale**

### 2. 孤立页面检查
- 扫描所有 wiki 页面中的 `[[wikilink]]`
- 找出没有任何入链的页面（orphan）
- 找出被链接但不存在的页面（broken link）

### 3. 代码-文档一致性
- 抽查 3-5 个模块页面，对比其描述与当前代码是否一致
- 重点检查：API 签名是否变了、模块是否被删除或重命名

### 4. 跨 Repo 接口验证
- 读取 `interfaces/` 下的所有页面
- 验证接口两端的 repo 是否仍然兼容
- 检查是否有新增的跨 repo 调用未被记录

### 5. Issues 回顾
- 读取 `issues/` 下的所有 open 状态页面
- 检查对应问题是否已在代码中修复
- 如已修复，更新状态为 resolved

### 6. 覆盖率评估
- 列出所有 repo 的主要模块
- 检查哪些模块在 wiki 中没有对应页面（undocumented）

## 输出

生成健康报告，包含：
- 总页面数、stale 数、orphan 数
- 需要更新的页面清单（按优先级）
- 建议的下一步操作（哪些 repo 需要 `/lcw diff`）
- 健康评分（0-10）

将报告追加到 `__wiki__/log.md`，格式：
`## [ISO时间] lint | 健康评分: X/10`
```

---

## .opencode/commands/lcw file.md

```markdown
---
description: "把当前对话中有价值的内容归档到 wiki"
agent: "wiki"
---

将当前对话中的内容归档为 wiki 页面：`$ARGUMENTS`

## 步骤

1. 读取 `__wiki__/SCHEMA.md` 确认页面类型和模板
2. 回顾当前对话中的分析、发现或洞察
3. 判断内容属于哪个 wiki 类别：
   - 跨模块分析 → `queries/{name}.md`
   - 发现的设计模式 → `concepts/{name}.md`
   - 架构决策讨论 → `decisions/{NNN}-{name}.md`
   - 发现的问题 → `issues/{name}.md`
4. 按对应模板创建页面，内容要：
   - 提炼核心洞察，不是复制聊天记录
   - 补充 wiki 链接到相关页面
   - 添加 frontmatter（date, sources, tags）
5. 更新相关已有页面中的交叉引用
6. 更新 `index.md`，追加 `log.md`

## 目的

对话是短暂的，wiki 是持久的。
好的分析不应该消失在聊天历史里——它们应该被提炼、链接、成为知识库的一部分。
```

---

## 命令之间的关系

```
                    代码仓库（只读）
                    ┌─────────────┐
                    │ repo-alpha  │
                    │ repo-beta   │
                    │ repo-gamma  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         /lcw ingest        /lcw diff       (直接读)
        (全量首次)    (增量同步)        │
              │            │            │
              ▼            ▼            │
        ┌─────────────────────────┐    │
        │       __wiki__/         │    │
        │                         │    │
        │  repos/  modules/       │    │
        │  interfaces/ concepts/  │◄───┘ /lcw query 必要时回溯源码
        │  decisions/ issues/     │
        │  queries/               │
        │                         │
        │  index.md  log.md       │
        └────────┬────────────────┘
                 │
          ┌──────┼──────┐
          │      │      │
       /lcw query  /lcw lint  /lcw file
       (读取)  (体检) (回填)
          │      │      │
          ▼      ▼      ▼
        回答   健康报告  新 wiki 页面
                         (从对话→知识)
```

## 典型工作流

```bash
# 第一天：初始化
/lcw ingest repo-alpha
/lcw ingest repo-beta
/lcw ingest repo-gamma

# 日常：探索和查询
/lcw query 用户从登录到下单的完整调用链是什么？
# → 觉得回答很好 →
/lcw file login-to-order-flow

# 有新代码合入后
/lcw diff repo-alpha

# 每周一次
/lcw lint

# 讨论中发现了架构问题
/lcw file 003-cache-inconsistency
```
