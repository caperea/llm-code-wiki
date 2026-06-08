# /lcw sync [repo]

增量同步最近变更到 wiki。

**与 ingest 的区别**：ingest 从零理解整个 repo，sync 只关注"什么变了"。

**前置条件**：repo 已存在于 `.sources/` 中（如果没有，提示先执行 `/lcw pull`）。sync 开始前会自动 `git pull` 更新 `.sources/{repo}/` 中的代码。

## 单 repo 模式

> 读 `.sources/` 时按 `references/code-navigation.md` 选工具。sync 的特点：`git diff` 给你**文件级**变化，但 wiki 是**符号级**组织的——拿到变更文件后用 `documentSymbol` 看符号增删，用 `findReferences` 评估影响面，才能落到正确的页面。

0. 读取 `.inputs/queries/` 和 `.inputs/notes/` 中与本 repo 相关的内容，关注历史问题涉及的模块和路径——如果这些区域有变更，优先同步
1. 读取 `repos/{name}.md` 的 `last_synced_commit`
2. 用 `git log {sha}..HEAD` 查看新提交，`git diff {sha}..HEAD --stat` 拿变更文件清单
3. 如果变更 >50 文件或大规模重构 → 建议 `/lcw ingest`
4. **符号级影响分析**（不是文件级）：
   - 对变更文件用 `documentSymbol` 对比新旧符号结构，识别新增/删除/改名
   - 对接口或公共类型的变更，跑 `findReferences` 看消费方影响面
   - 不要只看 diff 文本，diff 看不到"删了一个公共方法但内部还在用"这类问题
5. 更新受影响的模块、接口、问题页面
6. 更新 `last_synced` 和 `last_synced_commit`

**关注点**：
- 接口变动 → 更新 interfaces/（用 `findReferences` 确认双端都已更新）
- 新发现的问题 → 创建 issues/
- 业务词汇变动 → 更新 glossary.md
- 领域模型变更 → 更新 domains/

## 批量模式

**规划**：扫描所有已摄入的 repo，逐个检查新提交

**执行**：
1. 展示计划：列出有新提交的 repo 和 commit 数量
2. 用户确认
3. 逐个执行 sync，每个 repo 在独立 subagent 中处理
