---
description: "全量摄入工作区中所有仓库到 wiki（批量构建）"
agent: "wiki"
---

批量摄入工作区中所有代码仓库到 wiki。适用于首次构建多 repo 代码知识库。

## 第一阶段：规划

1. 如果 `__wiki__/` 不存在或为空，先执行 `lcw-init` 的初始化流程
2. 读取 `__wiki__/SCHEMA.md` 和 `__wiki__/index.md`
3. 扫描工作区根目录，列出所有子目录
4. 筛选代码仓库：包含 `.git/` 或主要代码文件的目录
5. 排除：`__wiki__/`、`.opencode/`、`.claude/`、`.codex/`、`node_modules/`、隐藏目录
6. 读取 `__wiki__/index.md`，标记哪些 repo 已被摄入（跳过或标记为需要 diff）
7. 生成执行计划并展示给用户：

```
## 执行计划

检测到 N 个代码仓库：

| # | Repo | 状态 | 预估规模 | 操作 |
|---|------|------|----------|------|
| 1 | repo-alpha | 未摄入 | ~12 模块 | ingest |
| 2 | repo-beta | 未摄入 | ~8 模块 | ingest |
| 3 | repo-gamma | 已摄入 (2026-04-10) | ~5 模块 | skip |

预计摄入顺序：先摄入规模较小的 repo（快速产出），再处理大型 repo。
跨 repo 接口将在所有 repo 摄入后统一整理。

确认执行？
```

8. 等待用户确认（用户可以调整顺序、排除某些 repo）

## 第二阶段：逐 repo 摄入

对每个待摄入的 repo，按以下流程执行（等同于 `/lcw-ingest` 的完整流程）：

9. **按计划顺序逐个处理**，每个 repo 执行：
   - 扫描结构与规模评估
   - 代码通道（提取 what）
   - 笔记通道（提取 why）
   - 交叉验证
   - 写入 wiki 页面
   - 更新 index.md 和 log.md

10. **每完成一个 repo 后**：
    - 输出进度：`[2/5] repo-beta 摄入完成 — 创建 8 个页面`
    - 更新 `__wiki__/overview.md` 中该 repo 的信息

11. **如果某个 repo 摄入失败**（目录损坏、不是有效代码库等）：
    - 记录错误到 log.md
    - 跳过该 repo，继续下一个
    - 在最终报告中标记

## 第三阶段：跨 repo 整合

所有 repo 摄入完成后：

12. 全面整理 `__wiki__/overview.md`：
    - 系统全景描述
    - 完整的 repo 职责一览表
    - 跨 repo 数据流
    - 依赖关系图

13. 检查所有跨 repo 接口：
    - 整理 `__wiki__/interfaces/` 目录
    - 确保接口两端的 repo 页面互相链接

14. 整合 `__wiki__/glossary.md`（业务词汇对照表）：
    - 跨 repo 对照：找出同一概念在不同 repo 中的命名差异
    - 合并同义条目，确定规范术语
    - 标记不一致项，记录各 repo 的具体用法

15. 在 `__wiki__/log.md` 顶部追加总结：

```
## [YYYY-MM-DDTHH:MM] ingest-all | 批量摄入完成
- 总 repo 数: N, 成功: M, 跳过: K, 失败: J
- 总页面数: X (repos: a, modules: b, interfaces: c, concepts: d, issues: e)
- 跨 repo 接口: {列表}
- 下一步建议: /lcw-lint 检查健康状态
```

16. 向用户展示完成报告。
