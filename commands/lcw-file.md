---
description: "归档对话洞察到 wiki — 好的分析不该消失在聊天历史里，用这个命令把它变成持久知识"
agent: "wiki"
---

将当前对话中的分析、发现或洞察归档为 wiki 页面：`$ARGUMENTS`

## 为什么需要归档

对话是短暂的，wiki 是持久的。一次深度调试可能揭示了三个模块的隐藏耦合，一次架构讨论可能产生了关键决策——如果不归档，下次遇到同样问题还要从头分析。

## 判断类别

回顾当前对话，提炼核心内容（提炼，不是复制聊天记录），选择最合适的归档位置：

- 跨模块分析、调用链梳理、对比 → `queries/`
- 设计模式或约定 → `concepts/`
- 架构决策讨论 → `decisions/{NNN}-name.md`（自动分配编号）
- 问题或风险 → `issues/`

为什么要区分类别：不同类别有不同的生命周期。Decision 一旦确定很少变；issue 会被修复；query 的价值在于分析过程本身。类别决定了未来谁会找到它、怎么找到它。

## 写入

按 `SCHEMA.md` 中对应类别的模板创建页面，**严格使用该类别要求的完整 frontmatter**：

- queries → `question`, `date`, `related_repos`, `source`
- concepts → `related_repos`, `tags`, `date`
- decisions → `status`, `date`, `related_repos`
- issues → `severity`, `status`, `related_repos`, `date`

添加 `[[wikilink]]` 链接到相关已有页面。同时在被引用的已有页面中补充反向链接——单向链接等于半个链接，只有双向才能形成知识网络。

**词汇检查**：如果归档内容涉及业务术语（尤其是 concepts/ 和 queries/ 类型），检查 `glossary.md` 是否已收录。未收录的新术语追加条目，已有术语确保页面用词与规范术语一致。

更新 `index.md`。

log.md 记录：
```
## [ISO时间] file | {页面名}
- 类别：{queries|concepts|decisions|issues}
- 来源：当前对话
- 链接到：{关联页面列表}
```
