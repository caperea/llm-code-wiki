# /lcw merge <wiki-path> [<wiki-path>...]

将多个独立 wiki 项目合并到当前 wiki。源 wiki 只读不修改。

**用法**：
```bash
mkdir ~/wiki-unified && cd ~/wiki-unified
~/.lcw/setup
/lcw merge ~/wiki-a ~/wiki-b ~/wiki-c
```

如果当前目录尚未初始化，自动先执行 init。

**中断恢复**：merge 的所有状态持久化在 `.merge-progress.md` 中。如果中断，重新执行 `/lcw merge` 会读取该文件从断点继续。

**独立校验**：`/lcw merge --verify` 不执行合并，只读取 `.merge-progress.md` 校验合并完整性。

## 核心增值

merge 不是简单的文件拼接。它的独特价值是**跨 wiki 接口发现**——源 wiki 各自只看到接口的一端（wiki-A 知道 repo-X 调用了某个外部服务，wiki-B 知道 repo-Y 提供了那个服务），合并后才能看到两端并建立 interfaces/ 页面。

## .merge-progress.md — 合并方案文档

这个文件是 merge 的核心控制文件，贯穿全流程。它不只是进度表，而是完整的方案文档：目标、决策、进度、备注全部维护在此。

### 文件结构

```markdown
# Merge 方案

## 元信息
- 创建时间: 2026-05-18T10:30:00
- 源 wiki: ~/wiki-a, ~/wiki-b, ~/wiki-c
- Schema 版本: v4
- 当前阶段: 执行中（阶段四）

## 源 wiki 摘要

| 源 wiki | 路径 | Repo 数 | 页面数 | 领域数 | .sources/ |
|---------|------|---------|--------|--------|-----------|
| wiki-a  | ~/wiki-a | 45 | 230 | 8 | 可访问 |
| wiki-b  | ~/wiki-b | 32 | 180 | 5 | 可访问 |

## 合并目标

| 指标 | 预计 | 实际 |
|------|------|------|
| Repo 总数（去重） | 67 | 67 |
| 页面总数 | 380 | — |
| 重叠 repo | 10 | — |
| 跨 wiki 接口候选 | 7 | — |
| 词汇表冲突 | 5 | — |

## 重叠决策

| Repo/Domain | 来源 | 决策 | 备注 |
|-------------|------|------|------|
| repo-alpha | wiki-a (abc123), wiki-b (def456) | 取 wiki-b（更新）+ wiki-a 独有发现 | |
| domains/risk | wiki-a, wiki-b | 合并（用户确认） | wiki-a 侧重规则引擎，wiki-b 侧重执行链路 |

## 词汇表冲突

| 术语 | wiki-a 定义 | wiki-b 定义 | 决策 | 状态 |
|------|------------|------------|------|------|
| 工单 | 用户投诉单 | SOP 处置任务 | 标记"多义" | done |

## 执行清单

### .sources/
- [x] repo-alpha (from wiki-b)
- [x] repo-beta (from wiki-a)
- [ ] repo-gamma (from wiki-a) ← 当前
- [ ] repo-delta (wiki-b, .sources/ 缺失，需后续 pull)

### repos/
- [x] repos/alpha.md (合并: wiki-a + wiki-b)
- [x] repos/beta.md (from wiki-a)
- [ ] repos/gamma.md (from wiki-a)

### modules/
- [x] modules/alpha/ (合并)
- [ ] modules/gamma/ (from wiki-a)

### domains/
- [x] domains/risk.md (合并: wiki-a + wiki-b, 有冲突标记)
- [ ] domains/payment.md (from wiki-b)

### interfaces/
- [x] interfaces/alpha-beta-grpc.md (from wiki-a)
- [ ] interfaces/alpha-gamma-event.md (跨 wiki 候选，待创建)

### flows/
- [x] flows/order-to-delivery.md (from wiki-a, 标记需扩展)

### 全局文件
- [x] repos.md
- [ ] glossary.md
- [ ] overview.md
- [ ] index.md
- [ ] wikilink 修复
- [ ] log.md

## 备注

- 2026-05-18 10:45: 用户确认 domains/risk 合并方案
- 2026-05-18 11:20: repo-delta 的 .sources/ 在 wiki-b 中缺失，标记后续 pull
- 2026-05-18 11:35: 中断（context window 接近上限），已完成到 modules/alpha
```

### 关键设计

- **每个待合并项都是一行 checkbox**：`- [ ]` pending / `- [x]` done / `- [!]` 跳过（附原因）
- **执行时逐项标记**：每完成一项立即更新文件，不攒批
- **中断安全**：重新执行 `/lcw merge` 时读取此文件，跳过已完成的 checkbox，从第一个 `- [ ]` 继续
- **备注区记录过程中的决策和异常**：不只是进度，也是审计日志

## 前置校验

所有源 wiki 的 schema_version 必须一致，否则拒绝合并。版本不一致时报错并提示用户先对落后的 wiki 执行 `/lcw migrate` 升级到最新版本。

## 阶段一：扫描源 wiki

对每个源 wiki：

1. 验证是 LCW wiki（检查 index.md、SCHEMA.md 存在）
2. 读取 SCHEMA.md 的 schema_version——**版本不一致则停止，报错并列出各 wiki 的版本**
3. 读取 repos.md、index.md
4. 统计：repo 数、页面数、领域数、流程数
5. 检查 .sources/ 是否存在且可访问

产出：写入 `.merge-progress.md` 的"元信息"和"源 wiki 摘要"。

## 阶段二：冲突分析

### 1. Repo 重叠检测

同一 repo 名出现在多个源 wiki 中：

- 对比 `repos/{name}.md` 的 `last_synced_commit`：确定哪边更新
- 对比页面内容差异：标记两边分析不同的部分
- **策略**：合并两边的分析取并集，冲突处取更新的版本，保留两边独有发现

### 2. 领域重叠检测

不同 wiki 可能识别了相同的业务领域：

- 按 domain 文件名匹配
- 按 repos/modules 覆盖范围匹配（不同名但覆盖相同 repo 的 domain 可能是同一领域）
- **策略**：同名的合并内容；覆盖范围重叠的标记让用户决策（合并 / 保留独立 / 重新划分）

### 3. 词汇表冲突检测

同一术语在不同 wiki 中定义不同：

- 按规范术语名匹配
- **策略**：合并时保留两边定义，标记状态为"不一致"并注明来源 wiki，后续由用户或 lint 统一

### 4. 跨 wiki 接口发现

这是 merge 的核心增值：

- 扫描所有 repos/ 和 modules/ 中的依赖引用（上游/下游）
- 找到"wiki-A 的 repo 引用了 wiki-B 的 repo"但 interfaces/ 中没有对应页面的情况
- **策略**：生成接口候选页面（标记 `status: unverified`），后续由 lint 或 ingest 验证补全

### 5. 流程扩展检测

源 wiki 的 flows/ 可能只覆盖了部分步骤：

- 检查 flow 中引用的 domain/repo 是否跨源 wiki
- 合并后流程可能变得更完整
- **策略**：标记可能需要扩展的流程，后续由 query 或 lint 补全

产出：写入 `.merge-progress.md` 的"合并目标"、"重叠决策"、"词汇表冲突"和完整的"执行清单"（所有 checkbox 初始为 `- [ ]`）。

## 阶段三：展示计划并确认

向用户展示 `.merge-progress.md` 的完整内容（此时所有 checkbox 都是 pending）：

1. **源 wiki 摘要**：各有多少 repo/页面/领域
2. **合并目标**：预计数字
3. **重叠处理方案**：逐项列出决策
4. **词汇表冲突清单**
5. **跨 wiki 接口候选**
6. **风险提示**：大规模合并可能需要较长时间

等用户确认后继续。用户可以调整决策（如"那两个 domain 其实应该合并"），调整后更新 `.merge-progress.md` 并重新展示。

## 阶段四：执行合并

按 `.merge-progress.md` 中的执行清单逐项执行。**每完成一项立即在文件中标记 `[x]`**。

顺序：

1. 确保当前目录已初始化（未初始化则先 init）
2. **合并 repos.md**：汇总所有源 wiki 的 repo 清单，去重
3. **合并 .sources/**：对每个 repo，从源 wiki 的 .sources/ 完整复制到新 wiki（确保新 wiki 自包含）。如果源 wiki 的 .sources/ 中某个 repo 不存在，标记需要后续 `/lcw pull`
4. **合并 .inputs/**：复制所有源 wiki 的 queries/ 和 notes/，文件名加来源前缀（如 `wiki-a--query-name.md`）避免冲突
5. **合并 repos/ 页面**：
   - 无重叠：复制
   - 有重叠：按"重叠决策"中的方案合并
6. **合并 modules/**：同上
7. **合并 domains/**：
   - 无重叠：复制
   - 有重叠：按决策合并，冲突处标记 `[合并冲突: wiki-A vs wiki-B]`
8. **合并 interfaces/**：复制已有的 + 创建跨 wiki 接口候选页面（frontmatter 标记 `status: unverified`）
9. **合并 flows/**：复制 + 标记可能需要扩展的流程
10. **合并 glossary.md**：合并条目，按"词汇表冲突"中的决策处理
11. **合并 issues/**：复制，去重（同名文件按内容合并）
12. **合并 ddd/**（如有）：复制产出，在 ddd/status.md 中标注 scope 已扩大需要重新审视
13. **重建 overview.md**：基于合并后的全量数据重新生成
14. **重建 index.md**：以实际文件为准
15. **修复 wikilinks**：扫描所有页面，修复因合并导致的断链
16. **写 log.md**
17. **更新 `.merge-progress.md`**：填入"合并目标"的"实际"列

## 阶段五：校验

合并完成后（或通过 `/lcw merge --verify` 独立执行）：

读取 `.merge-progress.md`，执行以下检查：

1. **清单完整性**：所有 checkbox 是否都已标记（`[x]` 或 `[!]`）？有 `- [ ]` 残留说明有遗漏
2. **页面计数**：对比"合并目标"中的预计值与实际值，差异超过 5% 则报警
3. **源页面覆盖**：逐个扫描每个源 wiki 的 index.md 条目，检查新 wiki 中是否有对应页面。缺失的列出清单
4. **repo 覆盖**：对比所有源 wiki 的 repos.md 与新 wiki 的 repos.md，确认无遗漏
5. **.sources/ 完整性**：repos.md 中的每个 repo，.sources/ 中是否存在（缺失的标记需要 pull）
6. **断链检查**：扫描所有 `[[wikilink]]`，找出指向不存在页面的链接
7. **冲突标记残留**：搜索 `[合并冲突` 和 `[!]` 标记，列出待人工处理的项

产出：校验报告，追加到 `.merge-progress.md` 底部。

```markdown
## 校验报告

- 校验时间: 2026-05-18T14:00:00
- 清单完整性: ✓ 全部完成（128/128）
- 页面计数: 预计 380, 实际 385 (+1.3%) ✓
- 源页面覆盖: ✓ 无遗漏
- repo 覆盖: 67/67 ✓
- .sources/: 65/67（repo-delta, repo-eta 需 pull）
- 断链: 2 处（已列出）
- 冲突标记残留: 1 处 domains/risk.md（待人工确认）

### 状态: 基本完成，2 项待处理
```

## 阶段六：报告

```
## 合并完成

### 来源
- wiki-a (45 repos, 230 pages)
- wiki-b (32 repos, 180 pages)
- wiki-c (28 repos, 150 pages)

### 合并结果
- 总 repo 数: 95 (去重后，原始 105)
- 总页面数: 520 (新建: 480, 合并: 40)
- 重叠 repo: 10 个（已合并分析）
- 重叠 domain: 3 个（已合并，1 个有冲突标记）
- 跨 wiki 接口候选: 7 个（待验证）
- 词汇表冲突: 5 条（待统一）

### 校验结果
见 .merge-progress.md 底部的校验报告

### 建议后续操作
1. /lcw merge --verify — 如果对完整性有疑虑，再跑一次校验
2. /lcw lint — 全面检查合并后的一致性
3. /lcw pull — 补全 .sources/ 中缺失的 repo
4. 对跨 wiki 接口候选跑 /lcw ingest 验证
5. 如有 ddd/ 产出，/lcw ddd audit 重新评估（scope 已扩大）
```

合并完成后 `.merge-progress.md` 保留在 wiki 根目录，提交到 git——它是这次合并的完整审计记录。
