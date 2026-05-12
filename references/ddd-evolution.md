# 反向 DDD——演进层

> 前置依赖：先读 `references/ddd-core.md`。本文件覆盖演进层分析步骤 + 页面模板。

## 第三层：演进层

命令：`/lcw ddd evolution`

将战略层和战术层的产出落到工程节奏上。前置条件：战略层已完成，且至少一个核心上下文的战术层已完成。

### 输入

- 所有 `ddd/` 目录下的产出
- `__wiki__/issues/*.md` — 已知问题
- `__wiki__/activities/*.md` — 变更频率数据（如果有）

### 分析步骤

#### 1. 现状成熟度评估

对每个限界上下文评估：

| 维度 | 来源 | 评分标准 |
|------|------|---------|
| 烟囱程度 | `ddd/panorama.md` 烟囱报告章节 | 有多少重复实现？ |
| 耦合度 | `ddd/contexts.md` 映射关系章节 + `interfaces/*.md` | 跨上下文依赖有多紧？ |
| 模型健康度 | `ddd/tactical/*.md` | 贫血程度、聚合边界清晰度 |
| 变更频率 | `activities/*.md` | 过去 N 个月改动频率 |
| 问题密度 | `issues/*.md` | 该区域的问题数量和严重度 |

#### 2. 优先级排序

重构优先级 = 技术紧迫度 × 组织就绪度。

**技术紧迫度** = 耦合度高 × 变更频率高 × 问题密度高 的交集。不是按架构师偏好排序，而是按"不改的成本最高"排序。

**组织就绪度**——技术上最该改的不一定现在能改：
- 团队是否有足够的人力和能力执行这个重构？
- 是否处于变更冻结期或业务高峰期？
- 有没有业务侧的优先级约束（如正在进行的大需求会冲突）？
- 相关团队是否对重构方向有共识？

技术紧迫度决定"应该先改什么"，组织就绪度决定"能先改什么"。两者冲突时，向用户呈现冲突而非替他们做决定。明确标注排序依据，让用户可以挑战和调整。

#### 3. 迁移路径规划

对每个需要重构的上下文：

- **目标态**：DDD 模型中这个上下文应该是什么样？
- **过渡态**：中间态什么样？承认"过渡架构会存在很长时间"比假装"半年就能切完"更务实
- **步骤**：
  1. 先建 ACL 隔离新旧
  2. 在 ACL 后面长出新模型
  3. 逐步把流量从旧路径切到新路径
  4. 旧代码退役
- **灰度方案**：怎么逐步切流量？
- **回滚预案**：出问题怎么回退？

#### 4. 质量基线

定义重构期间不能退化的指标：

- 功能正确性（核心业务流程是否正常）
- 性能指标（延迟、吞吐）
- 可观测性覆盖（日志、监控、告警是否完备）
- 特定于业务领域的指标（例如治理类系统的：卡控有效性、决策延迟、误判率）

没有基线，重构后只能口头说"应该没退化"。

### 产出物

| 文件 | 内容 |
|------|------|
| `ddd/evolution/roadmap.md` | 重构路线图：优先级排序 + 依据 + 预估节奏 |
| `ddd/evolution/transition.md` | 过渡架构描述：每个中间态的架构图 |
| `ddd/evolution/migration-{context}.md` | 逐上下文的迁移指南、灰度方案、回滚预案 |
| `ddd/evolution/baseline.md` | 质量基线定义与回归指标 |

---

## 页面模板

### ddd/evolution/roadmap.md

```yaml
---
type: ddd-roadmap
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

必含章节：现状评估（表格含组织就绪度列）、优先级排序及依据、路线图（阶段/目标/上下文/工作量/前置依赖）、风险与假设。

### ddd/evolution/transition.md

```yaml
---
type: ddd-transition
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

每个阶段一个章节：架构图、新旧共存、切流策略。

### ddd/evolution/migration-{context}.md

```yaml
---
type: ddd-migration
context: {context-name}
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

必含章节：目标态、迁移步骤、灰度方案、回滚预案、验证方法。

### ddd/evolution/baseline.md

```yaml
---
type: ddd-baseline
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DD}
---
```

必含章节：通用指标、业务指标、测量方法、红线。
