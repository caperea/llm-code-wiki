---
description: "增量同步仓库最近变更 — 代码有新提交后使用，只处理变化的部分而非全量重扫"
agent: "wiki"
---

增量同步仓库 `$ARGUMENTS` 的最近变更到 wiki。

与 `/lcw-ingest` 的区别：ingest 从零理解整个 repo，diff 只关注"什么变了"。这样更快，也避免重新处理未变化的模块。

## 确定变更范围

读取 `repos/$1.md` 的 `last_synced_commit`，用 `git log {sha}..HEAD` 查看新提交。如果 sha 缺失或无效（可能被 rebase），回退到按 `last_synced` 日期过滤。

如果没有新提交，报告"已是最新"并结束。如果变更超过 50 个文件或涉及大规模重构，建议用户改用 `/lcw-ingest` 全量重建——增量更新不适合结构性变化。

## 更新 wiki

对每个受影响的模块，读取变更文件，更新对应 wiki 页面。同时关注：
- 接口变动（新增/修改 API、proto、路由）→ 更新 `interfaces/`
- 架构级决策（新依赖、重大重构）→ 创建 `decisions/`
- 新问题 → 创建 `issues/`
- 业务词汇变动（类型重命名、新概念、注释中术语变化）→ 更新 `glossary.md`
- repo 间协作关系变化 → 更新 `overview.md`

更新所有受影响页面的 `last_synced` 和 `last_synced_commit`。

log.md 记录：
```
## [ISO时间] diff | {repo名}
- 新提交：{N} 个，涉及 {M} 个文件
- 更新/新建：{页面列表}
```
