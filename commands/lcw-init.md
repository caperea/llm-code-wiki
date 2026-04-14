---
description: "初始化 __wiki__/ 目录结构和所有模板文件"
agent: "wiki"
---

在当前工作区初始化 LLM Code Wiki。

## 前置检查

1. 检查 `__wiki__/` 是否已存在
   - 如果已存在且包含内容 → 报告"wiki 已初始化"，列出现有页面数量，结束
   - 如果已存在但为空或只有 SCHEMA.md → 继续初始化，保留已有文件
   - 如果不存在 → 继续

## 创建目录结构

2. 创建以下目录：

```
__wiki__/
├── repos/
├── modules/
├── interfaces/
├── concepts/
├── decisions/
├── issues/
└── queries/
```

## 创建核心文件

3. 读取 `~/.lcw/templates/` 下的模板文件，复制到 `__wiki__/`（如已存在则跳过）：
   - `SCHEMA.md` — wiki 结构约定和页面模板
   - `index.md` — 内容目录
   - `log.md` — 操作日志
   - `overview.md` — 全局架构概览

## 扫描工作区

4. 列出当前工作区中的所有子目录
5. 识别哪些是代码仓库（包含 `.git/` 或有代码文件）
6. 生成一份 repo 清单，写入 `__wiki__/overview.md` 的 repo 职责表格（标记为"待摄入"）

## 收尾

7. 在 `__wiki__/log.md` 顶部写入初始化记录：

```
## [YYYY-MM-DDTHH:MM] init | wiki 初始化
- 创建目录结构和模板文件
- 检测到 repo: {repo 列表}
- 下一步: 对每个 repo 执行 /lcw-ingest
```

8. 向用户输出使用指引：

```
Wiki 已初始化。建议的下一步：

1. /lcw-ingest <repo-name>   — 逐个摄入你的代码仓库
2. /lcw-ingest-all            — 或一次性摄入所有仓库
3. /lcw-query <问题>          — 查询已摄入的知识
4. /lcw-lint                  — 定期检查 wiki 健康状态
```
