# 代码导航策略

所有读取 `.sources/` 源码的命令（ingest / sync / lint / query / ddd / file）在动手前都先看这份指南，决定用 LSP 还是 grep。

## 核心原则

**代码用 LSP，文本用 grep。** 这两类工作本质不同，对应工具也不同。

- **代码（`.sources/{repo}/`）**：优先 LSP。LSP 理解符号的真实身份——它知道 `Order` 是哪一个 `Order`，能跨 import 别名、继承、接口实现追到正确位置；grep 只看字符串，在大代码库里同名符号、注释里的字面量、import 路径里的关键词都会污染结果。这对 wiki 的关键判断（聚合边界、调用链、接口契约）不是噪声多少的问题，而是对错的问题。
- **文本（wiki markdown、glossary、README、CHANGELOG、注释、`.inputs/`、log.md、配置文件）**：用 grep。这些内容没有符号语义，LSP 也无能为力。

## LSP 工具清单

LCW 用到的 LSP 操作及其用途：

| 操作 | 输入 | 输出 | 何时用 |
|------|------|------|--------|
| `workspaceSymbol` | 名字（必须非空） | 全工程匹配的符号列表 | 按名字找类/接口/函数定义，作为后续操作的入口 |
| `documentSymbol` | 文件路径 | 该文件的所有顶层和嵌套符号 + 层次 | 一次性拿模块的"公共 API 全貌"，比逐行 grep 函数定义快得多 |
| `goToDefinition` | 文件 + 行列 | 符号的定义位置 | 验证某个调用到底落在哪个实现上，区分同名 |
| `goToImplementation` | 文件 + 行列（接口/抽象类） | 所有实现位置 | 找接口的实现类，识别多态——grep 完全做不到 |
| `findReferences` | 文件 + 行列 | 所有引用位置 | 评估变更影响面、追踪一个实体被谁用、识别孤立代码 |
| `hover` | 文件 + 行列 | 类型信息 + 文档注释 | 快速看签名和文档，避免读整个文件 |
| `prepareCallHierarchy` | 文件 + 行列（函数/方法） | call hierarchy item | `incomingCalls`/`outgoingCalls` 的前置步骤 |
| `incomingCalls` | call hierarchy item | 调用此函数的所有位置 | 反向追调用链——识别业务流程入口、找触发某行为的源头 |
| `outgoingCalls` | call hierarchy item | 此函数调用的所有位置 | 正向追调用链——追踪一次请求的完整路径 |

## LCW 操作 → 推荐工具映射

| LCW 操作 | 推荐工具 | 说明 |
|---------|---------|------|
| ingest "扫描结构、划分模块边界" | `Glob` + 目录树 | 这一步只看目录形态，不读符号 |
| ingest "提取公共 API" | `documentSymbol`（按模块入口文件） | 一次拿全部公共符号 + 层次，比 grep 函数名快且准 |
| ingest "依赖关系" | `findReferences`（关键类型/接口） | grep import 漏掉重命名、动态导入；LSP 看符号真身 |
| ingest "关键数据类型" | `workspaceSymbol`（按命名约定，如 `*Entity`、`*Aggregate`） + `documentSymbol` | 先按名字找入口，再拿成员细节 |
| ingest "状态机提取" | `workspaceSymbol`（如 `*Status`、`*State`） + `findReferences` | 找 enum，再追用它的地方定位转换逻辑 |
| ingest "实体 vs 值对象 / 聚合根识别" | `workspaceSymbol` + `goToImplementation` + `findReferences` | 关键的 wiki 判断，grep 拿不到继承/接口关系 |
| sync "更新受影响的模块/接口" | `git diff` 得到文件 → `documentSymbol` 看符号级变化 → `findReferences` 评估影响面 | git 是文件级，符号级要靠 LSP |
| sync "接口变动" | 对变更的接口符号跑 `findReferences` | 看清谁是消费方 |
| lint drift 修复 | 同 sync | |
| lint "覆盖率检查"（找缺失模块页面） | `Glob` + 目录树 | 同 ingest 第一步 |
| lint "领域健康检查"（核心实体列表校验） | `workspaceSymbol`（按 domains 页面声明的实体名） + `documentSymbol` | 验证 wiki 里列的实体在代码里确实存在且形态一致 |
| query "验证 API 签名、调用关系" | `goToDefinition` + `hover` | 同名方法极易误判，必须落到真身 |
| query "追踪调用链" | `prepareCallHierarchy` → `incomingCalls` / `outgoingCalls` | 反复 grep+Read 是低效路径 |
| ddd-tactical "数据模型提取" | `documentSymbol`（按模块入口） | 拿全公共符号一次到位 |
| ddd-tactical "贫血检测" | `workspaceSymbol`（实体名）→ `findReferences` → 看哪些 Service/Manager 在动它 | 跨文件汇总操作分布 |
| ddd-tactical "领域事件提取" | `workspaceSymbol`（如 `*Event`） + `findReferences` | 找事件类，再看生产/消费两端 |
| ddd-tactical "防腐层"（外部交互点） | `goToImplementation`（接口） + `findReferences` | 找接口实现和实际调用点 |

不在表内的步骤照常——表只是给"会读代码"的步骤指方向，不是穷举。

## grep 仍是首选的场景

下列内容用 grep（或 Read），不要走 LSP：

- `glossary.md`、`SCHEMA.md`、`index.md`、`log.md`、`overview.md` 等 wiki markdown
- `domains/`、`modules/`、`interfaces/`、`flows/`、`issues/`、`ddd/` 下的 wiki 页面
- 源码里的 README、CHANGELOG、文档注释、配置文件（yaml/json/toml）
- `.inputs/queries/`、`.inputs/notes/`
- 代码里按字符串字面量出现的内容（错误消息、日志关键字、URL pattern）
- 需要正则匹配（`grep -E`）才能表达的模式

## 回退规则

LSP 报错不等于"该用 grep"。先按这个顺序试：

1. **换一个 LSP 操作**：`findReferences` 拿不到 → 试 `workspaceSymbol` 重新拿位置再追；`documentSymbol` 空 → 试用 `Glob` 拿到入口文件再试
2. **换一个入口符号**：可能选的不是"真"的入口（如选了一个 wrapper），换更基础的类型再试
3. **确认整门语言不可用才退**：连续 2-3 次不同操作都返回错误或空，再判定该 repo / 语言服务器没起来，回退到 `grep + Read`
4. **回退时记录**：在 log.md 里写一行"`{repo}` LSP 不可用，本次用 grep 回退"，便于后续排查（不是每次都写，只在首次回退或长期不可用时写）

LSP 偶尔返回不完整结果（如某些 macro/动态生成的符号）也是正常的，这种时候 LSP + grep **互补**比纯 grep 更可信——LSP 给的是确定的真身，grep 补的是 LSP 看不到的字面量。

## 为什么这样分

- **LSP 知道符号身份，grep 只看字符串。** 一个 `Order` 类在 6 个 repo 里都叫 `Order`，grep `class Order` 会拿到 6 个无关结果；`workspaceSymbol("Order")` 会按真实定义返回，且 `findReferences` 只跟踪指向**这一个**定义的引用。这是 wiki "实体识别"、"聚合边界"判断的根基。
- **LSP 跨文件结构化导航，grep 只能逐文件文本扫描。** 追"谁调用了 `PolicyEvaluator.evaluate`"用 `incomingCalls` 一步到位；grep 要先找方法名，再 Read 每个命中文件确认上下文，效率差一个数量级。
- **LSP 给类型，grep 给字符串。** `hover` 直接看签名和返回类型；grep 只能拿到声明那一行的字面量，参数类型还要再 Read 一遍。

简单说：grep 适合**找一段文字**，LSP 适合**找一个东西**。wiki 摄入和 DDD 分析做的是后者。
