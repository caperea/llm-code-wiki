---
description: "全量摄入一个仓库到 wiki"
agent: "wiki"
---

全量摄入仓库 `$ARGUMENTS` 到 wiki。按以下步骤执行：

## 第一步：准备

1. 读取 `__wiki__/SCHEMA.md` 了解页面模板
2. 读取 `__wiki__/index.md` 了解已有页面（避免重复创建）
3. 确认目标仓库 `$ARGUMENTS` 存在

## 第二步：扫描结构与规模评估

4. 列出仓库的目录结构（2-3 层深度）
5. 识别：主要语言、框架、构建系统、入口点
6. 识别：模块/包/服务的边界划分
7. **规模评估**：统计主要模块数量
   - 如果 ≤ 15 个模块：继续下面的一次性摄入流程
   - 如果 > 15 个模块：切换为分批模式——先跳到第六步创建 repo 主页（含模块清单），再回来逐批摄入模块（每批 3-5 个），每批执行第三到五步后写入对应页面

## 第三步：代码通道（提取 what）

8. 对每个主要模块：
   - 提取公共 API（导出函数、类型、接口）
   - 提取依赖关系（import/require 分析）
   - 识别关键数据类型和结构
9. 扫描路由定义、配置文件、proto/schema 文件
10. 识别与其他 repo 的接口点（gRPC, REST, event, shared DB）
11. 提取业务词汇：从以下来源识别领域术语：
    - 代码：类型名、变量名、数据库表/字段名、proto 字段、API 路径
    - 注释：函数/类的文档注释中的自然语言描述（这是最重要的来源——注释里的人类语言往往包含术语的业务含义和上下文）
    - 配置：枚举值、常量名、错误码定义

## 第四步：笔记通道（提取 why）

12. 读取 README.md, ARCHITECTURE.md, CONTRIBUTING.md, CHANGELOG 等文档
13. 提取有意义的代码注释（TODO, HACK, FIXME, 架构决策注释）
14. 执行 `git log --oneline -20` 查看最近 commit message 了解变更趋势

## 第五步：交叉验证

15. 对比笔记描述与代码实际结构，标记差异：
    - 文档说有但代码没有 → phantom feature
    - 代码有但文档没说 → undocumented
    - 文档描述与代码行为不一致 → stale docs

## 第六步：写入 wiki

16. 创建或更新 `__wiki__/repos/$1.md`（仓库主页），frontmatter 中记录 `last_synced_commit`（当前 HEAD 的 short sha）
17. 为每个主要模块创建 `__wiki__/modules/$1--{module}.md`
18. 如发现跨 repo 接口，创建或更新 `__wiki__/interfaces/{name}.md`
19. 如发现值得记录的设计模式或约定，创建 `__wiki__/concepts/{name}.md`
20. 如发现问题或矛盾，创建 `__wiki__/issues/{name}.md`
21. 创建或更新 `__wiki__/overview.md`（全局架构概览：repo 间的协作关系、数据流、关键接口）
22. 更新 `__wiki__/glossary.md`：将本 repo 提取的业务词汇追加到词汇表，标注该术语在本 repo 中的具体用法（变量名、类名、表名等），如已有同义词条目则合并并标记不一致

## 第七步：收尾

23. 更新 `__wiki__/index.md`（添加所有新建/更新的页面条目）
24. 在 `__wiki__/log.md` 顶部追加本次操作记录（注意：最新记录在最前）：

```
## [YYYY-MM-DDTHH:MM] ingest | {repo名}
- 扫描结果：{语言}，{N} 个主要模块
- 创建：{页面列表}
- 更新：{页面列表}
- 发现：{问题/矛盾摘要}
```
