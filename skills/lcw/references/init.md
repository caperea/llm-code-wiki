# /lcw init

在当前目录初始化 wiki 项目结构。

**检查**：如果 `index.md` 已存在且包含内容，报告现有页面数量并结束。

**创建骨架**：

```
./
├── SCHEMA.md      # 页面模板（从 templates/SCHEMA.md 复制）
├── index.md       # 分类目录
├── log.md         # 操作日志
├── overview.md    # 全局架构概览
├── glossary.md    # 业务词汇对照表
├── repos.md       # 代码仓库清单（人维护）
├── repos/
├── modules/       # 按仓库分子目录：modules/{repo}/
├── systems/       # 系统拓扑（多 repo 组成的系统单元）
├── interfaces/    # 跨 repo 接口
├── issues/
├── flows/
├── domains/
├── ddd/           # 反向 DDD 梳理产出
│   ├── tactical/
│   └── evolution/
├── .sources/      # 克隆的源码（自动加入 .gitignore）
└── .inputs/       # sources 层（queries/ + notes/）
```

**初始化 .gitignore**：确保 `.sources/` 被忽略。

**读取 repos.md**：如果 `repos.md` 已存在，解析其中的仓库列表，生成初始的 `repos/` 页面（标记为"未拉取"）。如果不存在，创建空的 `repos.md` 并提示用户填写。

**收尾**：在 log.md 记录初始化操作，输出下一步指引。
