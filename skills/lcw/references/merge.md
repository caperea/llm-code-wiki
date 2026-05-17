# /lcw merge <wiki-path> [<wiki-path>...]

将多个独立 wiki 项目合并到当前 wiki。源 wiki 只读不修改。

**用法**：
```bash
mkdir ~/wiki-unified && cd ~/wiki-unified
~/.lcw/setup
/lcw merge ~/wiki-a ~/wiki-b ~/wiki-c
```

如果当前目录尚未初始化，自动先执行 init。

## 核心增值

merge 不是简单的文件拼接。它的独特价值是**跨 wiki 接口发现**——源 wiki 各自只看到接口的一端（wiki-A 知道 repo-X 调用了某个外部服务，wiki-B 知道 repo-Y 提供了那个服务），合并后才能看到两端并建立 interfaces/ 页面。

## 阶段一：扫描源 wiki

对每个源 wiki：

1. 验证是 LCW wiki（检查 index.md、SCHEMA.md 存在）
2. 读取 repos.md、index.md、SCHEMA.md（记录 schema_version）
3. 统计：repo 数、页面数、领域数、流程数
4. 检查 .sources/ 是否存在且可访问

产出：源 wiki 摘要表。

```
| 源 wiki | Repo 数 | 页面数 | 领域数 | Schema 版本 | .sources/ |
|---------|---------|--------|--------|-------------|-----------|
| wiki-a  | 45      | 230    | 8      | v4          | 可访问    |
| wiki-b  | 32      | 180    | 5      | v3          | 可访问    |
| wiki-c  | 28      | 150    | 6      | v4          | 部分缺失  |
```

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

产出：冲突报告。

## 阶段三：展示计划并确认

向用户展示：

1. **源 wiki 摘要**：各有多少 repo/页面/领域
2. **合并后预计**：总 repo 数（去重后）、预计页面数
3. **重叠处理方案**：逐项列出重叠 repo 和 domain 的处理决策
4. **词汇表冲突清单**：每个冲突术语的两边定义
5. **跨 wiki 接口候选**：新发现的接口关系
6. **Schema 兼容性**：如有版本差异，说明会按最新版本统一
7. **风险提示**：大规模合并可能需要较长时间，建议逐步验证

等用户确认后继续。用户可以调整计划（如"那两个 domain 其实应该合并"），按调整后的方案重新展示。

## 阶段四：执行合并

顺序：

1. 确保当前目录已初始化（未初始化则先 init）
2. **合并 repos.md**：汇总所有源 wiki 的 repo 清单，去重
3. **合并 .sources/**：对每个 repo，symlink 到源 wiki 的 .sources/（避免重复克隆）。如果源 wiki 的 .sources/ 不可访问，标记需要后续 `/lcw pull`
4. **合并 .inputs/**：复制所有源 wiki 的 queries/ 和 notes/，文件名加来源前缀（如 `wiki-a--query-name.md`）避免冲突
5. **合并 repos/ 页面**：
   - 无重叠：复制
   - 有重叠：合并两边内容（取更新的 last_synced_commit，合并分析发现）
6. **合并 modules/**：同上
7. **合并 domains/**：
   - 无重叠：复制
   - 有重叠：合并内容，冲突处标记 `[合并冲突: wiki-A vs wiki-B]`
8. **合并 interfaces/**：复制已有的 + 创建跨 wiki 接口候选页面（frontmatter 标记 `status: unverified`）
9. **合并 flows/**：复制 + 标记可能需要扩展的流程
10. **合并 glossary.md**：合并条目，冲突标记"不一致"
11. **合并 issues/**：复制，去重（同名文件按内容合并）
12. **合并 ddd/**（如有）：复制产出，在 ddd/status.md 中标注 scope 已扩大需要重新审视
13. **重建 overview.md**：基于合并后的全量数据重新生成
14. **重建 index.md**：以实际文件为准
15. **修复 wikilinks**：扫描所有页面，修复因合并导致的断链
16. **写 log.md**

## 阶段五：报告

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

### 待人工关注
- domains/risk-control.md: 合并冲突标记，两边领域边界定义不同
- glossary.md: 5 条术语标记"不一致"，需确认统一定义
- interfaces/: 7 个候选页面待 ingest 验证

### 建议后续操作
1. /lcw lint — 全面检查合并后的一致性
2. /lcw pull — 补全 .sources/ 中缺失的 repo
3. 对跨 wiki 接口候选跑 /lcw ingest 验证
4. 如有 ddd/ 产出，/lcw ddd audit 重新评估（scope 已扩大）
```
