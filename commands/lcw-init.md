---
description: "初始化 wiki — 在当前工作区创建 __wiki__/ 目录结构。首次使用 LCW 时执行一次。"
agent: "wiki"
---

在当前工作区初始化 LLM Code Wiki。

如果 `__wiki__/` 已存在且包含内容，报告现有页面数量并结束（不要覆盖）。如果为空或部分存在，补全缺失部分。

## 创建骨架

创建 `__wiki__/` 及子目录：repos/, modules/, interfaces/, concepts/, decisions/, issues/, queries/。

创建核心文件（已存在则跳过）：
- `SCHEMA.md` — 页面模板和命名约定（内容见 SCHEMA.md 模板，如果本命令是 symlink，可从 symlink 源目录的 `../templates/` 读取；否则按 SCHEMA.md 的约定自行生成）
- `index.md` — 空的分类目录
- `log.md` — 操作日志（倒序，最新在前）
- `overview.md` — 全局架构概览占位页
- `glossary.md` — 业务词汇对照表占位页

## 扫描工作区

列出当前工作区中的子目录，识别代码仓库（含 `.git/`）。将 repo 清单写入 overview.md（标记为"待摄入"）。这一步的目的是让用户和后续命令了解工作区里有什么，以便决定摄入顺序。

## 收尾

在 log.md 记录初始化操作，然后向用户输出下一步指引：

```
Wiki 已初始化。下一步：

  /lcw-ingest <repo>    摄入单个仓库
  /lcw-ingest           摄入所有仓库
```
