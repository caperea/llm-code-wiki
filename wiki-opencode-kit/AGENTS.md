# 多 Repo 代码库 Wiki 系统

本工作区包含多个代码仓库和一个 LLM 维护的 wiki 知识库。

## 核心规则

1. **只写 `__wiki__/`**：所有 repo 目录是只读输入，绝不修改任何 repo 中的文件
2. **代码是事实**：当 wiki 描述与代码矛盾时，以代码为准，更新 wiki
3. **笔记需验证**：README、注释、文档提供上下文，但可能过时，需与代码交叉验证
4. **wiki 记录理解，不复制代码**：页面中不粘贴大段源码，用路径引用 `repo/path/file.go:L10-L30`
5. **每次写操作后更新 `index.md` 和 `log.md`**

## 项目结构

- `repo-*/` — 代码仓库，只读输入（等同于 raw source）
- `__wiki__/` — LLM 维护的知识库，唯一可写区域
- `__wiki__/SCHEMA.md` — wiki 的结构约定和页面模板，操作前必读

## Wiki 命令

- `/lcw-init` — 初始化 wiki 目录结构（首次使用时执行一次）
- `/lcw-ingest <repo>` — 首次全量摄入一个仓库
- `/lcw-ingest-all` — 批量摄入工作区所有仓库（首次构建用）
- `/lcw-diff <repo>` — 增量同步最近变更
- `/lcw-query <问题>` — 查询 wiki
- `/lcw-lint` — wiki 健康检查
- `/lcw-file <名称>` — 把当前对话的有价值内容归档到 wiki

## 代码 vs 笔记

操作 wiki 时始终区分两类输入：

- **代码**（.go, .py, .ts, .rs 等及配置文件）→ 结构化提取：模块边界、API、依赖图、数据类型
- **笔记**（README, ARCHITECTURE.md, CHANGELOG, 注释, commit message）→ 语义化整合：动机、决策、上下文

代码告诉你系统 **是什么**，笔记告诉你系统 **为什么** 是这样，wiki 把两者编织在一起。
