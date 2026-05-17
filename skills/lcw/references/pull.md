# /lcw pull [repo]

管理 `.sources/` 目录中的代码仓库——克隆新 repo 或更新已有 repo。

pull 是 ingest/sync 的前置步骤：先有代码，才能摄入知识。但 ingest 在发现 `.sources/` 中缺少代码时也会自动触发 pull，所以大多数时候不需要手动执行。pull 的独立价值在于**批量管理代码**和**智能推荐下一批该拉什么**。

## 单 repo 模式

`/lcw pull <repo-name>`

1. 从 `repos.md` 中查找该 repo 的 git 地址
2. 如果 `.sources/{repo-name}/` 不存在 → `git clone --depth 1` 浅克隆
3. 如果已存在 → `git pull`（如果是浅克隆且需要历史，先 `git fetch --unshallow`）
4. 更新 `repos/{repo-name}.md` 的 frontmatter：`clone_status`、`last_fetched`、`head_commit`

## 无参数模式（智能推荐）

`/lcw pull`

不带参数时，自动发现最值得拉取的 repo：

1. 读取 `repos.md` 获取全量清单
2. 对比 `repos/` 中每个 repo 的 `clone_status`，分为三组：
   - **未拉取**：`repos.md` 中有但 `.sources/` 中没有
   - **已过期**：`.sources/` 中有但 `last_fetched` 超过指定天数（默认 7 天）
   - **已最新**：最近拉取过
3. **推荐下一批**（优先级从高到低）：
   - 被已摄入的 repo 引用但尚未拉取的依赖（从 `interfaces/*.md` 和 `modules/*.md` 的依赖关系中提取）
   - `repos.md` 中标注为核心/高优先级的 repo
   - 已过期的 repo（按过期时间排序）
   - 其余未拉取的 repo
4. 展示推荐列表，用户确认后批量执行

## 克隆策略

- 默认**浅克隆**（`--depth 1`）：节省空间，够 ingest 用
- 当 sync 或 DDD 需要历史时，自动 `git fetch --unshallow` 加深
- `repos/{name}.md` 的 frontmatter 记录 `clone_depth: shallow | full`

## 输出格式

```
## pull 完成

### 本次操作
- 新克隆: 3 (alpha, beta, gamma)
- 已更新: 5
- 失败: 1 (delta — 权限不足)

### 总览
- 已拉取: 28/150 (19%)
- 推荐下一批: epsilon, zeta, eta（被 alpha 和 beta 引用）
```
