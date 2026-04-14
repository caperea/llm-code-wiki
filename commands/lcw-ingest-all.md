---
description: "批量摄入工作区所有仓库 — 首次构建多 repo wiki 时使用，自动规划摄入顺序并逐个执行"
agent: "wiki"
---

批量摄入工作区中所有代码仓库到 wiki。

## 规划

如果 `__wiki__/` 不存在，先执行 lcw-init 的初始化流程。

扫描工作区，识别代码仓库（排除 `__wiki__/`、`.opencode/`、`.claude/`、`.codex/`、`node_modules/`、隐藏目录）。检查哪些已被摄入（跳过或标记为需要 diff）。

生成执行计划并展示给用户确认。先摄入小 repo（快速产出可见结果），再处理大 repo。用户可以调整顺序或排除某些 repo。

为什么要先展示计划：批量摄入是耗时操作，用户需要知道范围和预期，也可能想排除测试仓库或已废弃的 repo。

## 逐 repo 摄入

按确认后的顺序逐个执行 `/lcw-ingest` 的完整流程。每完成一个 repo 输出进度（如 `[2/5] repo-beta — 创建 8 个页面`）。

如果某个 repo 失败，记录错误到 log.md，跳过继续。不要因为一个 repo 而中断整个批量操作。

## 跨 repo 整合

所有 repo 摄入完成后，这是最有价值的一步——单独 ingest 只看到 repo 内部，这一步才能看到 repo 之间的关系：

- 整理 `overview.md`：系统全景、repo 职责、跨 repo 数据流、依赖图
- 整理 `interfaces/`：确保接口两端互相链接
- 整合 `glossary.md`：跨 repo 对照术语，合并同义条目，标记不一致

log.md 记录：
```
## [ISO时间] ingest-all | 批量摄入完成
- 总 repo 数: N, 成功: M, 跳过: K, 失败: J
- 总页面数: X
- 下一步建议: /lcw-lint
```
