# /lcw sync [repo]

增量同步最近变更到 wiki。

**与 ingest 的区别**：ingest 从零理解整个 repo，sync 只关注"什么变了"。

**前置条件**：repo 已存在于 `.sources/` 中（如果没有，提示先执行 `/lcw pull`）。sync 开始前会自动 `git pull` 更新 `.sources/{repo}/` 中的代码。

## 单 repo 模式

1. 读取 `repos/{name}.md` 的 `last_synced_commit`
2. 用 `git log {sha}..HEAD` 查看新提交
3. 如果变更 >50 文件或大规模重构 → 建议 `/lcw ingest`
4. 更新受影响的模块、接口、问题页面
5. 更新 `last_synced` 和 `last_synced_commit`

**关注点**：
- 接口变动 → 更新 interfaces/
- 新发现的问题 → 创建 issues/
- 业务词汇变动 → 更新 glossary.md
- 领域模型变更 → 更新 domains/

## 批量模式

**规划**：扫描所有已摄入的 repo，逐个检查新提交

**执行**：
1. 展示计划：列出有新提交的 repo 和 commit 数量
2. 用户确认
3. 逐个执行 sync，每个 repo 在独立 subagent 中处理
