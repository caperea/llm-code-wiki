# /lcw activities

按自然月切片地分析多 repo 的提交活动，支持跨时间窗的功能视角与人员视角聚合查询。

**为什么独立成一条命令**：`ingest / sync / lint` 维护"系统当前是什么"，而 activities 维护"过去发生了什么"。两条链路解耦——activities 用日期窗口，与 `last_synced_commit` 无关；过去月幂等不可变，当月按需刷新；查询时聚合任意时间窗。

## 数据结构

```
activities/
├── _index.md                       # 桶目录：哪些 repo / 哪些月份已有桶 + 各桶 extracted_at
├── _aliases.yaml                   # （可选）作者归一化映射
└── {repo}--{YYYY-MM}.md            # 月度桶：每 (repo, 自然月) 一个
```

桶页面 schema 与必含章节见 SCHEMA.md 的 `activities/{repo}--{YYYY-MM}.md` 段落。

## 子动作

```
/lcw activities plan                                  # 展示将抓取/刷新哪些桶，不执行
/lcw activities sync [repo] [--months N]              # 抓取并写入桶
/lcw activities sync [repo] --from YYYY-MM --to YYYY-MM
/lcw activities ask <question> [--lens feature|people|both] [--months N]
/lcw activities ask <question> --from YYYY-MM --to YYYY-MM [--archive]
```

**统一时间参数**：

- `--months N`（默认 3）：回看最近 N 个自然月，含当月
- `--from YYYY-MM --to YYYY-MM`：显式区间，覆盖 `--months`
- 无 repo 参数 → 处理所有已 ingest 的 repo（即存在 `repos/{name}.md` 的）

## /lcw activities plan

输出待办矩阵——哪些 (repo, 月) 桶缺失、哪些当月需刷新、哪些已是 closed 跳过。不写文件。

## /lcw activities sync

抓取并写入月度桶。对每个 (repo × 月) 组合：

1. **判断是否需要写**
   - 桶不存在 → 抓取并写入
   - 桶已存在且 `month_status: closed` 且非当月 → 跳过（幂等）
   - 桶已存在且 `month_status: current` 或为当月 → 重新抓取并覆盖
2. **抓取原始数据**（在 `.sources/{repo}/` 中执行，只读）
   ```
   git log --since="{YYYY-MM-01}" --until="{下个月 01}" \
           --pretty=format:"%h|%ae|%an|%ad|%s" --date=short \
           --shortstat --no-merges
   git log --since=... --until=... --name-only --pretty=format:"%h|%ae|%an" --no-merges
   ```
3. **升维**（关键步骤，不是简单转写）
   - 文件路径 → 模块映射：用现有 `modules/{repo}--{module}.md` 中的 module 字段把文件归到模块
   - commit subject 前缀粗分类：feat / fix / refactor / chore / docs / test / perf / ci
   - 高影响提交识别：≥10 文件 或 ≥500 LOC（默认阈值，可在 frontmatter 注记）
   - 作者聚焦模块：每作者 ≥80% 提交落在哪些模块
   - 用一段叙事总结本月主旋律——LLM 写，不要模板填空
4. **作者归一化**
   - 若存在 `activities/_aliases.yaml` → 按其映射合并
   - 否则按 `(name, email)` 默认聚合，相同 email 算同一人
5. **写入** `activities/{repo}--{YYYY-MM}.md`，frontmatter + 6 个必含章节
6. **更新** `activities/_index.md`（桶清单 + extracted_at）
7. **写 log.md**：`## [ISO] activities sync | repo={repo} months={list} 写入={N} 跳过={M}`

**异常处理**：

- repo 缺失或非 git → 跳过 + 报告，不中断批量
- 该月该 repo 无提交 → 写一个 `commit_count: 0` 的占位桶（标 `month_status: closed`），避免下次 sync 重抓
- 该月该 repo 还未存在（首次 commit 在窗口之后） → 同上，标 0 + 备注
- 与 `repos/{name}.md` 的 `last_synced_commit` 不一致 → 不影响 activities（activities 用日期窗口而非 commit 范围）

**批量执行**：沿用"批量执行模式"约定（`--plan`、`--batch N`、超过 20 个 repo 自动分批）。

## /lcw activities ask

按时间窗回答问题，不抓新数据。

**流程**：

1. 解析时间窗 → 算出涉及哪些 (repo × 月) 桶
2. 读 `activities/_index.md`，确认所需桶都存在
   - 若缺失 → **不要隐式 sync**，直接提示用户先 `/lcw activities sync --from ... --to ...`
3. 加载相关桶的 frontmatter（廉价聚合）+ 必要章节
4. 按 `--lens` 输出：
   - `feature`（功能视角）：跨 repo 跨月汇总 top_modules，把每月主题串成时间线，高影响提交按 domain / module 分桶，集中输出风险信号
   - `people`（人员视角）：合并 frontmatter 的 `top_authors`（按 canonical_name），输出每人的主聚焦模块、跨 repo 广度、月度活跃度文字曲线（"2月↑ 3月→ 4月↓"）
   - `both`（默认）：先 feature 再 people
5. **关键纪律**：
   - 描述事实，不打分
   - 区分**信息来源**：哪些是从桶里直接读出的事实，哪些是 LLM 综合推断
   - 不泄漏作者邮箱
6. `--archive` → 把回答写入 `queries/activities-{from}--{to}.md`，并在 log.md 记录

## 与主线 wiki 的边界

- activities 操作**只写** `activities/`、`log.md`、`index.md`
- 不修改 `repos/`、`modules/`、`domains/`、`interfaces/`、`glossary.md`
- 例外：`ask` 时如发现明确的技术债 / 风险，**可以**新建 `issues/{name}.md`，但需在回答中明确告知用户
