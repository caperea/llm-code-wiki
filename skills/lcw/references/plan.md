# /lcw plan [command]

生成执行计划，不执行任何写入操作。

- `/lcw plan` — 全量矩阵：扫描所有 repo，输出每个 repo 该执行什么操作
- `/lcw plan ingest` — 只看哪些 repo 需要 ingest
- `/lcw plan sync` — 只看哪些 repo 需要 sync
- `/lcw plan pull` — 只看哪些 repo 需要 pull
- `/lcw plan lint` — 只看哪些 repo 需要 lint

**触发场景**：用户说"先看看要做什么"、"帮我规划一下"，或批量操作前自动展示。

## 扫描逻辑

1. 读取 `repos.md` 获取全量 repo 清单
2. 对每个 repo 检查状态：

| 信号 | 来源 | 判定 |
|------|------|------|
| `repos.md` 中有但 `.sources/` 中无 | 文件系统 | 需要 pull |
| `.sources/` 中有但无 `repos/{name}.md` | 文件系统 + repos/ | 需要 ingest |
| `last_synced_commit != HEAD` | repos/*.md frontmatter vs git | 需要 sync |
| `last_synced` 超过 14 天 | repos/*.md frontmatter | 建议 lint |
| 以上均无 | — | skip |

3. 分析依赖优先级：
   - 从 `interfaces/*.md` 和 `modules/` 中提取跨 repo 引用
   - 被多个已摄入 repo 引用但自身未摄入的 repo 优先级最高
   - `repos.md` 中标注为核心的 repo 优先

## 输出格式

### 无参数（全量矩阵）

```
## 执行计划

### 统计
- 总 repo 数: N
- 需要 pull: A
- 需要 ingest: B
- 需要 sync: C
- 建议 lint: D
- 跳过: E

### 待处理矩阵

| Repo | 操作 | 原因 | 优先级 |
|------|------|------|--------|
| alpha | ingest | 已拉取未摄入 | 高（被 3 个 repo 引用） |
| beta | sync | 落后 12 个 commit | 中 |
| gamma | pull + ingest | 未拉取，被 alpha 依赖 | 高 |
| delta | lint | 上次同步 21 天前 | 低 |
| epsilon | skip | 已是最新 | — |

### 建议执行顺序
1. pull: gamma, zeta（被已有 repo 引用的依赖）
2. ingest: gamma, alpha（新 repo）
3. sync: beta, eta（增量更新）
4. lint: delta（定期检查）
```

### 指定命令（过滤模式）

只展示该命令对应的 repo，省略其余。例如 `/lcw plan sync`：

```
## Sync 计划

| Repo | 落后 commit 数 | 变更范围 | 优先级 |
|------|---------------|---------|--------|
| beta | 12 | src/order/, src/payment/ | 中 |
| eta | 3 | src/config/ | 低 |

建议执行: /lcw sync beta && /lcw sync eta
```

plan 不写 log（只读操作）。
