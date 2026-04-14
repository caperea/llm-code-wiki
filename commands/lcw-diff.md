---
description: "增量同步仓库最近变更到 wiki"
agent: "wiki"
---

增量同步仓库 `$ARGUMENTS` 的最近变更到 wiki。

## 步骤

1. 读取 `__wiki__/SCHEMA.md` 和 `__wiki__/index.md`
2. 读取 `__wiki__/repos/$1.md` 的 `last_synced_commit` frontmatter 字段
3. 在仓库 `$ARGUMENTS` 中执行 `git log --oneline {last_synced_commit}..HEAD` 查看新提交
   - 如果 `last_synced_commit` 缺失，回退到 `git log --oneline --since="{last_synced}"` 按日期过滤
4. 如果没有新提交，报告"已是最新"并结束
5. 用 `git diff {last_synced_commit}..HEAD --stat` 确定变更文件范围
6. 对每个受影响的模块：
   - 读取变更的文件
   - 更新对应的 `__wiki__/modules/` 页面
7. 如果变更涉及接口变动（新增/修改 API、proto、路由），更新 `__wiki__/interfaces/` 页面
8. 如果变更包含架构级决策（新依赖、重大重构），创建 `__wiki__/decisions/` 页面
9. 如果发现新问题，创建 `__wiki__/issues/` 页面
10. 检查变更是否涉及业务词汇变动（类型重命名、新增领域概念、注释中术语变化），如有则更新 `__wiki__/glossary.md`
11. 更新所有受影响页面的 `last_synced` 和 `last_synced_commit`（当前 HEAD 的 short sha）
12. 如果变更影响了 repo 间的协作关系，更新 `__wiki__/overview.md`
13. 更新 `__wiki__/index.md`
14. 在 `__wiki__/log.md` 顶部追加记录（注意：最新记录在最前）：

```
## [YYYY-MM-DDTHH:MM] diff | {repo名}
- 新提交：{N} 个，涉及 {M} 个文件
- 更新：{页面列表}
- 新建：{页面列表}（如有）
```

## 注意

- 增量同步关注"什么变了"，不重新理解整个 repo
- 如果变更范围超过 50 个文件或涉及大规模重构，建议用户改用 `/lcw-ingest` 全量重建
