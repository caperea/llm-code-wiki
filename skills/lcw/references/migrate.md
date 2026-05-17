# /lcw migrate

将已有 wiki 迁移到当前 LCW 的目录结构和 SCHEMA.md 规范。

## 为什么需要 migrate

LCW 的目录结构和页面模板会随版本演化（比如新增 `notes/` 目录、移除 `concepts/`、模块改为按仓库分子目录）。已有的 wiki 可能基于旧版结构创建，手动调整既繁琐又容易遗漏。migrate 自动完成这个对齐。

## 核心原则

- **不假设旧结构**：不硬编码"从 v1 到 v2"的映射表，而是现场扫描实际文件，与当前 SCHEMA.md 和 SKILL.md 中定义的目标结构做比对
- **能归入就归入，其余不勉强**：无法映射到当前分类体系的内容（无对应分类、不再相关、用途不明等）统一移入 `legacy/`，保留原始内容不丢失
- **计划先行**：所有操作前先展示完整计划，用户确认后才执行
- **安全网**：迁移前提交 git，确保可以一键回滚

## 流程

### 阶段一：分析

1. 读取当前 SKILL.md 中定义的目标目录结构和 SCHEMA.md 中的页面模板
2. 扫描 wiki 根目录下的所有文件和目录（排除 `.sources/`、`.claude/`、`.git/` 等）
3. 逐项比对，产生分析报告：

**报告内容**：

| 类别 | 说明 |
|------|------|
| 可直接保留 | 已经符合当前结构的文件，不需要动 |
| 需要移动 | 文件存在但位置不对（如 `concepts/x.md` → 应融入 `domains/` 或 `modules/`） |
| 需要重命名/重组 | 目录结构变化（如 `modules/x.md` → `modules/{repo}/x.md`） |
| 需要格式更新 | 页面存在但 frontmatter 或结构不符合当前 SCHEMA.md |
| 缺失的目录 | 当前结构要求但 wiki 中不存在的目录（如 `notes/`） |
| 无法归类 | 不属于当前结构中任何已知分类的文件 |
| 冲突 | 移动会覆盖已有文件等情况 |

### 阶段二：展示计划并确认

向用户展示：

1. **迁移计划摘要**：各类别的文件数量
2. **具体操作列表**：每个文件会被怎样处理（保留/移动/格式更新/移入 legacy）
3. **风险提示**：冲突、无法自动处理的点、可能丢失链接关系的地方
4. **legacy 清单**：哪些文件会被移入 legacy/，原因是什么

等用户确认后继续。如果用户想调整计划（比如"那个文件其实应该放到 domains/ 而不是 legacy"），按用户指示修改计划后重新展示。

### 阶段三：Git 快照

询问用户是否先提交当前状态（推荐）。用户确认后：

- `git add -A && git commit -m "snapshot: pre-migrate state"`
- 告诉用户：如果迁移效果不满意，可以 `git reset --hard HEAD~1` 回滚

用户如果选择不提交（比如已经有未完成的工作不想混在一起），尊重选择但提醒风险。

### 阶段四：执行迁移

按计划执行，顺序：

1. 创建缺失的目录（`notes/`、`ddd/` 等）
2. 移动文件到正确位置
3. 更新页面 frontmatter 和结构（按 SCHEMA.md）
4. 将无法归类的文件移入 `legacy/`（保持原始目录结构，如 `legacy/concepts/x.md`）
5. 修复 `[[wikilink]]` 引用（文件移动后链接会断）
6. 重建 `index.md`（以迁移后的实际文件为准）
7. 检查 `glossary.md` 格式是否符合当前 SCHEMA.md 的双视角要求
8. 写 `log.md`

### 阶段五：报告

迁移完成后输出：

- 迁移统计（移动/更新/legacy 各多少）
- 需要人工关注的点（断链未能自动修复、legacy 中值得手动处理的文件等）
- 建议的后续操作（比如"建议跑一次 `/lcw lint` 做全面检查"）

## legacy 目录

`legacy/` 位于 wiki 根目录，gitignored 可选。内部保持文件的原始相对路径结构：

```
legacy/
├── concepts/          # 旧 concepts/ 中无法自动归类的页面
│   └── some-old-page.md
├── queries/           # 旧 queries/ 中的内容
│   └── old-query.md
└── _unknown/          # 完全无法识别的文件
    └── mystery.md
```

每个 legacy 文件顶部追加一个注释块说明迁移时间和原因：

```markdown
<!-- migrate: 2026-05-17, reason: concepts/ 分类已移除，内容未能自动映射到现有分类 -->
```

## 定向迁移：从 legacy 中恢复

全量迁移后，用户可以针对 legacy 中的具体文件做定向迁移：

```
/lcw migrate legacy/concepts/some-old-page.md → domains/
/lcw migrate legacy/queries/ 这些是历史查询记录，融入对应的 domains 页面
```

**语法**：`/lcw migrate <legacy 中的文件或目录> <目的地或意图说明>`

**流程**：

1. 读取指定的 legacy 文件内容
2. 根据用户提供的目的地或意图，制定迁移方案（移动到哪、是否需要格式适配、是否融入已有页面而非独立存放）
3. 展示方案，用户确认后执行
4. 移动/融入 + 适配 SCHEMA.md 格式 + 修复 wikilink + 更新 index.md + 写 log
5. 从 legacy/ 中删除已迁移的文件（如果目录变空则删除空目录）

定向迁移不需要 git 快照（改动范围小，git diff 即可回滚）。
