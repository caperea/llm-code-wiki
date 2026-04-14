---
description: "Wiki 健康检查"
agent: "wiki"
---

对 `__wiki__/` 执行全面健康检查。

## 检查项

### 1. 时效性（stale）
- 读取每个 wiki 页面的 `last_synced` frontmatter
- 对比对应 repo/模块的最后修改时间：`git log -1 --format=%ci -- {path}`
- 标记 `last_synced` 落后超过 7 天的页面

### 2. 链接完整性
- 扫描所有页面中的 `[[wikilink]]`
- 孤立页面（orphan）：没有任何入链
- 断链（broken）：被链接但不存在的页面

### 3. 代码-文档一致性
- 抽查 3-5 个模块页面
- 对比 wiki 描述与当前代码：API 签名是否变了？模块是否被删除或重命名？

### 4. 跨 Repo 接口验证
- 读取 `interfaces/` 下所有页面
- 验证接口两端是否仍然兼容
- 检查是否有新增的跨 repo 调用未被记录

### 5. Issues 回顾
- 读取 `issues/` 下所有 open 状态的页面
- 检查对应问题是否已在代码中修复
- 已修复的更新状态为 resolved

### 6. 覆盖率
- 列出所有 repo 的主要模块
- 标记在 wiki 中没有对应页面的模块

### 7. 业务词汇一致性
- 读取 `glossary.md`，检查标记为"不一致"的条目
- 抽查代码中是否有新引入的术语未收录到词汇表
- 检查是否有已统一的术语在新代码中又出现了旧别名

### 8. Schema 版本检查
- 读取 `SCHEMA.md` 的 `schema_version`
- 检查是否有页面缺少新版本要求的字段（如 `last_synced_commit`、queries 的 `source`）
- 报告需要迁移的页面

## 输出

生成健康报告摘要，直接在对话中展示：

- 总页面数 / stale 数 / orphan 数 / broken link 数
- 需要更新的页面清单（按优先级排序）
- 建议的下一步操作（哪些 repo 需要 `/lcw-diff`，哪些需要 `/lcw-ingest`）
- 健康评分（0-10）

在 `__wiki__/log.md` 顶部追加（注意：最新记录在最前）：

```
## [YYYY-MM-DDTHH:MM] lint | 健康评分: X/10
- 总页面: N, stale: N, orphan: N, broken: N
- 需关注: {清单}
```
