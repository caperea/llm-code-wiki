---
description: "Wiki 健康检查 — 定期运行，检查过时页面、断链、代码漂移、词汇不一致等问题"
agent: "wiki"
---

对 wiki 执行健康检查。

**范围**：传入 repo 名（如 `/lcw-lint alpha`）时只检查该 repo 相关的页面（`repos/alpha.md`、`modules/alpha--*.md`、引用了该 repo 的 interfaces/issues/concepts，以及 glossary 中该 repo 的条目）；无参数时检查整个 `__wiki__/`。

## 检查项

**时效性**：对比每个页面的 `last_synced` 与对应代码的最后修改时间（`git log -1 --format=%ci`）。落后超过 7 天的标记为 stale。这是最重要的检查——过时的 wiki 比没有 wiki 更危险，因为它给人虚假的信心。

**链接完整性**：扫描所有 `[[wikilink]]`，找出孤立页面（没有入链）和断链（被链接但不存在）。孤立页面意味着知识被隔离，断链意味着重构后没有清理引用。

**代码-文档一致性**：抽查 3-5 个模块页面，对比 wiki 描述与当前代码。重点检查 API 签名是否变了、模块是否被删除或重命名。

**跨 repo 接口验证**：读取 `interfaces/` 下所有页面，验证两端是否仍然兼容，检查是否有新增的跨 repo 调用未被记录。

**Issues 回顾**：检查 open 状态的 issue 是否已在代码中修复。已修复的更新为 resolved。

**覆盖率**：列出所有 repo 的主要模块，标记没有对应 wiki 页面的模块。

**业务词汇一致性**：读取 `glossary.md`，逐项检查并自动修正：
- "不一致"条目：检查代码是否已统一，如已统一则更新状态为"统一"
- 抽查代码中是否有新术语未收录——如有，自动追加条目（状态为"待定"）
- 已统一的术语出现了旧别名——修正 wiki 页面中的旧别名为规范术语
- 多义术语检查：扫描同一术语在不同领域代码中的含义是否有新变化，更新"多义术语"章节
- 词汇表发生变更后，按 SCHEMA.md 写作约定第 6 条执行级联更新

**领域健康检查**：
- `domains/` 页面的核心实体列表是否与代码匹配（实体被删除/重命名？）
- `domains/` 页面的模块引用是否仍然存在
- 新模块是否已分配到领域（覆盖率）——未分配的模块意味着领域边界不完整
- `interfaces/` 页面是否有未填写的 `relationship` 字段——建议补充 DDD 关系类型
- 领域分类（core/supporting/generic）是否仍然合理

**跨切面一致性检查**：
- 新代码中的鉴权模式是否与 `overview.md` 跨切面关注点章节记录的一致
- 新消息 topic 是否已记录在 `interfaces/`

**Schema 版本迁移**：检查 v1 → v2 迁移进度：
- `issues/` 页面缺少 `impact_scope`/`fix_effort`/`risk_type` → 建议补充
- `interfaces/` 页面缺少 `relationship`/`data_consistency` → 建议补充
- `modules/` 页面缺少 `domain` → 建议补充
- `overview.md` 缺少"业务能力地图"或"跨切面关注点"章节 → 建议补充
- 不存在任何 `domains/` 页面 → 建议执行 `/lcw-ingest` 生成

## 输出

生成健康报告：总页面数、stale 数、orphan 数、broken link 数。按优先级列出需要更新的页面。建议下一步操作（哪些 repo 需要 `/lcw-diff`，哪些需要 `/lcw-ingest`）。给出健康评分（0-10）。

log.md 记录：
```
## [ISO时间] lint | {范围} | 健康评分: X/10
- 检查页面: N, stale: N, orphan: N, broken: N
- 修正: {自动修正的内容}
- 需关注: {清单}
```
