---
description: "把当前对话中有价值的内容归档到 wiki"
agent: "wiki"
---

将当前对话中的分析、发现或洞察归档为 wiki 页面：`$ARGUMENTS`

## 步骤

1. 读取 `__wiki__/SCHEMA.md` 确认页面模板
2. 回顾当前对话，提炼核心内容
3. 判断内容最适合的 wiki 类别：
   - 跨模块分析、调用链梳理、对比 → `__wiki__/queries/$ARGUMENTS.md`
   - 发现的设计模式或约定 → `__wiki__/concepts/$ARGUMENTS.md`
   - 架构决策讨论 → `__wiki__/decisions/{NNN}-$ARGUMENTS.md`（自动分配编号）
   - 发现的问题或风险 → `__wiki__/issues/$ARGUMENTS.md`
4. 按 `SCHEMA.md` 中对应类别的模板创建页面，**严格使用该类别的完整 frontmatter**：
   - queries → 必须有 `question`, `date`, `related_repos`, `source`
   - concepts → 必须有 `related_repos`, `tags`, `date`
   - decisions → 必须有 `status`, `date`, `related_repos`，编号自动递增
   - issues → 必须有 `severity`, `status`, `related_repos`, `date`
   - 提炼核心洞察，不是复制聊天记录
   - 添加 `[[wikilink]]` 链接到相关已有页面
5. 反向更新：在被引用的已有页面中补充对新页面的链接
6. 更新 `__wiki__/index.md`
7. 在 `__wiki__/log.md` 顶部追加（注意：最新记录在最前）：

```
## [YYYY-MM-DDTHH:MM] file | {页面名}
- 类别：{queries|concepts|decisions|issues}
- 来源：当前对话
- 链接到：{关联页面列表}
```

## 目的

对话是短暂的，wiki 是持久的。好的分析不该消失在聊天历史里。
