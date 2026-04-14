---
description: "批量摄入工作区所有仓库 — 首次构建多 repo wiki 时使用，自动规划摄入顺序并逐个执行"
agent: "wiki"
---

批量摄入工作区中所有代码仓库到 wiki。

## 第一阶段：规划

如果 `__wiki__/` 不存在，先执行 lcw-init 的初始化流程。

扫描工作区，识别代码仓库（排除 `__wiki__/`、`.opencode/`、`.claude/`、`.codex/`、`node_modules/`、隐藏目录）。对每个 repo 检查 `repos/{name}.md` 是否存在及 `last_synced_commit`，分为三类：

- **未摄入**（无 `repos/{name}.md`）→ 执行全量 ingest
- **已摄入且有新提交**（`git log {sha}..HEAD` 非空）→ 执行 diff 增量更新
- **已摄入且无新提交** → 跳过

生成执行计划并展示给用户确认，明确标注每个 repo 的操作类型（ingest / diff / skip）。用户可以调整：强制某个 repo 全量重建，或排除某些 repo。

为什么要先展示计划：批量摄入是耗时操作，用户需要知道范围和预期，也可能想排除测试仓库或已废弃的 repo。

## 第二阶段：逐 repo 执行

按规划的操作类型分别处理：未摄入的执行全量 ingest，有新提交的执行 diff，已是最新的跳过。

**为什么不在单个上下文中处理所有 repo**：每个 repo 的处理需要读取大量代码，如果在同一个上下文中逐个处理，3-4 个大 repo 后上下文就会耗尽，后续 repo 的质量会严重下降。

**执行策略——分析并行、写入串行**：

1. **并行分析**：为每个需要处理的 repo 启动独立的 subagent（ingest 的执行分析阶段，diff 的执行变更范围分析）。每个 subagent 有独立上下文，互不挤占。subagent 返回结构化的分析结果（模块清单、API 摘要、业务词汇、发现的问题），不写入任何文件。

   为什么分析可以并行：分析阶段是对各自 repo 的只读操作，repo 之间没有依赖。

   并行粒度：根据 repo 数量控制并发。3-5 个 repo 可以全部并行；超过 5 个分批（每批 3-5 个），避免同时启动过多 subagent。

2. **串行写入**：收集所有 subagent 的分析结果后，在主 agent 中逐个写入 wiki 页面。

   为什么写入必须串行：`glossary.md`、`index.md`、`overview.md`、`interfaces/` 是跨 repo 共享资源。并行写入会导致冲突——后写的覆盖先写的。串行写入时，每个 repo 的词汇表更新能看到前面 repo 已追加的条目，从而正确标记"不一致"。

   每完成一个 repo 的写入，输出进度（如 `[2/5] repo-beta — 创建 8 个页面`）。

如果某个 repo 的分析 subagent 失败，记录错误到 log.md，跳过该 repo 继续。不要因为一个 repo 而中断整个批量操作。

**降级策略**：如果运行环境不支持并行 subagent（如某些 LLM 工具没有 agent 并行能力），回退为逐 repo 串行执行完整的 `/lcw-ingest`。此时每个 repo 仍应在独立的 subagent 中执行，以隔离上下文。

## 第三阶段：跨 repo 整合

所有 repo 摄入完成后，这是最有价值的一步——单独 ingest 只看到 repo 内部，这一步才能看到 repo 之间的关系：

- 整理 `overview.md`：系统全景、repo 职责、跨 repo 数据流、依赖图
- 整理 `interfaces/`：确保接口两端互相链接
- 整合 `glossary.md`：跨 repo 对照术语，合并同义条目，标记不一致，执行级联更新

log.md 记录：
```
## [ISO时间] ingest-all | 批量同步完成
- 总 repo 数: N (ingest: A, diff: B, skip: C, 失败: D)
- 总页面数: X (新建: Y, 更新: Z)
- 下一步建议: /lcw-lint
```
