# /lcw ingest [repo]

摄入代码仓库到 wiki。

**代码来源**：从 `.sources/{repo-name}/` 读取代码（只读）。如果该 repo 尚未克隆到 `.sources/`，自动执行 pull 逻辑先克隆。

**目的**：把代码仓库从零变成结构化的 wiki 知识。代码告诉你系统是什么，文档告诉你为什么，wiki 把两者编织在一起。

## 单 repo 模式

**已有 wiki 的处理**：

- 不存在 `repos/{name}.md` → 全量摄入
- 已存在且无新提交 → 报告"已是最新"，建议 `/lcw lint`
- 已存在且有新提交 → 建议 `/lcw sync`（增量更快更安全）

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

**覆盖完整性检查**：

摄入前列出所有将被处理的目录，摄入后验证：
- 对比代码目录树与已创建的模块页面
- 输出覆盖报告：`已覆盖: X/Y 个目录`
- 如果有目录未覆盖，说明原因（测试目录、配置目录、或遗漏）

**忽略规则**（默认不摄入）：
- `test/`, `tests/`, `__tests__/` — 测试代码
- `vendor/`, `node_modules/` — 第三方依赖
- `.git/`, `.github/` — Git 相关
- `dist/`, `build/`, `target/` — 构建产物
- `docs/` — 文档（单独处理）

**写入阶段**：

按 SCHEMA.md 创建页面：
- `flows/{name}.md` — 核心业务流程
- `domains/{name}.md` — 业务领域
- `repos/{name}.md` — 仓库主页
- `modules/{repo}/{module}.md` — 模块页面
- `interfaces/` — 跨 repo 接口
- 更新 `overview.md`、`glossary.md`

**输出格式**：

```
## 摄入完成: {repo-name}

### 覆盖情况
- 代码目录: 15 个
- 模块页面: 15 个
- 覆盖率: 100%

### 创建页面
- repos/{name}.md
- modules/{name}--auth.md
- modules/{name}--order.md
- ...

### 未覆盖目录
- (无) 或列出并说明原因
```

## 批量模式（无参数）

**规划**：扫描所有 repo，分类为：
- 未摄入 → 全量 ingest
- 有新提交 → sync
- 无新提交 → 局部 lint

**执行**：展示计划 → 用户确认 → 串行写入（避免共享资源冲突）→ 跨 repo 整合（补全跨 repo 流程、审视领域边界、整理 interfaces/）

**log 记录**：
```
## [ISO时间] ingest | 批量同步完成
- 总 repo 数: N (ingest: A, sync: B, lint: C, 失败: D)
- 总页面数: X (新建: Y, 更新: Z)
```
