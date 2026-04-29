---
name: agent-teams-playbook
version: "4.7"
description: |
  Cross-runtime Agent Teams orchestration playbook for Claude Code, Codex, OpenClaw, and Cursor. This skill should be used when the user asks to "create agent teams", "use agent swarm", "setup multi-agent collaboration", "orchestrate agents", "coordinate parallel agents", "organize team collaboration", "build agent teams", "implement swarm orchestration", "setup multi-agent system", "coordinate agent collaboration", or needs guidance on adaptive team formation, quality gates, skill discovery, task distribution, team coordination strategies, or Agent Teams best practices. 或者当用户说"多agent"、"agent协作"、"agent编排"、"并行agent"、"分工协作"、"拉团队"、"拉个团队"、"多代理协作"、"swarm编排"、"agent团队"时也应使用此技能。Note: "swarm/蜂群" is a generic industry term; Claude Code's official concept is "Agent Teams"; Codex, OpenClaw, and Cursor should map this playbook to their native or host-provided agent capabilities without deleting any workflow stage.
---

# Agent Teams 编排手册

作为 Agent Teams 协调器，你的职责包括：明确每个角色的职责边界、把控执行过程、对最终产品质量负责。

> **核心理解（铁律）**：Agent Teams 是"并行处理 + 结果汇总"模式，不是扩大单个 agent 的上下文窗口。每个 teammate 是独立的执行单元，拥有独立上下文，可以并行处理大量信息，但最终需要将结果汇总压缩后返回主会话。

## 跨平台兼容层（新增，不替代原流程）

本 Skill 的完整 6 阶段工作流、Skill 回退链、Agent → Skill 委派模式、质量把关和故障处理规则仍然保留。四个平台的差异只影响"用什么工具执行"，不影响"是否执行这些阶段"。

先识别当前平台，再把下列抽象动作映射到平台原生能力。不要在非 Claude Code 平台原样承诺 `Task`、`TeamCreate`、`SendMessage` 或 `Skill(...)` 一定存在；也不要因为平台工具名不同而跳过阶段0-5。

| 抽象动作 | Claude Code | Codex | OpenClaw | Cursor |
|------|------|------|------|------|
| 调用 Skill | `Skill(skill="name", args="...")` 或 slash skill | 读取并遵循本地 skill 指令；只有宿主暴露 skill 工具时才称为"调用" | 读取并遵循 `openclaw/skills` 或全局 skill；按 OpenClaw 当前工具执行 | 读取并遵循 `.cursor/skills` 或全局 skill；按 Cursor 当前 agent 能力执行 |
| 启动独立 Subagent | `Task(...)` | 宿主提供的 custom-agent / subagent dispatch；不可用则主线程分阶段执行 | workspace / agent 调度能力；不可用则主线程分阶段执行 | background agent / agent mode；不可用则主线程分阶段执行 |
| 组建 Agent Team | `TeamCreate` + `Task(team_name)` | 多个独立 subagent + 主线程汇总；无共享团队总线承诺 | team / workspace 能力存在时使用；否则多个任务或主线程 | background agents / team-like workflow 存在时使用；否则多个任务或主线程 |
| 成员通信/进度 | `SendMessage` 或 task result | 子任务结束汇报；有 agent I/O 工具才可中途交互 | 平台消息/日志；不可用时用阶段性文本汇报 | IDE/agent 日志；不可用时用阶段性文本汇报 |
| 规划文件 | `planning-with-files` skill | 若本地 skill/tool 存在则使用；否则使用内联计划或平台计划工具 | 若本地 planning skill 存在则使用；否则维护可见计划记录 | 若本地 planning skill 存在则使用；否则维护可见计划记录 |

**平台适配底线**：
1. 写计划时使用抽象动作名；执行时使用当前平台真实工具名。
2. 只有 Claude Code 可以承诺官方 `Task` / `TeamCreate` / `SendMessage` 语义。
3. Codex 中只有宿主实际暴露并调用了 subagent/custom-agent 工具，才代表真的触发后台 agent；没有真实工具调用就不能说 agent 群已启动。
4. OpenClaw/Cursor 的 team 能力可能来自项目插件、workspace 或 IDE 能力；先探测，再承诺。
5. 若平台不支持真正并行或团队通信，明确降级为"主线程分阶段执行"，但仍执行阶段0-5的治理流程。

## 适用 vs 不适用

| 适用 | 不适用 |
|------|--------|
| 跨文件重构、多维度审查 | 单文件小修改 |
| 大规模代码生成、并行处理 | 简单问答、线性顺序任务 |
| 需要多角色协作的复杂任务 | 单agent可完成的任务 |

**边界处理**：用户输入模糊时，先引导明确任务再决策；任务太简单时，主动建议使用单agent而非组建团队。

## 用户可见性铁律

1. 每个阶段启动前输出计划，完成后输出结果
2. 子agent在后台执行，但进度必须汇报给用户
3. 任务拆分计划必须经用户确认后再执行；若宿主平台或项目指令要求直接执行，则说明采用的默认假设
4. 失败时立即通知：`❌ [角色名] 失败: [原因]`，提供重试/跳过/终止选项
5. 全部完成后输出汇总报告（见阶段5格式），并说明真实使用的平台工具和任何降级路径

## 场景决策树

**执行顺序**：先执行阶段0和阶段1（强制），再根据任务复杂度选择场景（影响阶段2-5）。

| 问题 | 路径 |
|------|------|
| Q0: 阶段1找到完全匹配的Skill？ | 是 → 场景2 / 否 → Q1 |
| Q1: 任务复杂度？ | 简单(1-2步) → 场景1 / 中等(3-5步) → 场景3 / 复杂(6+步) → Q2 |
| Q2: 需要明确团队分工？ | 是 → 场景4 / 否 → 场景5 |

- 用户直接指定场景编号时,跳过决策树直接执行
- 未指定场景时，默认用**场景3（计划+评审）**
- **注意**：阶段0（planning-with-files）和阶段1（Skill搜索，包含 find-skills）是所有场景的强制前置步骤

## 5大编排场景

| # | 场景 | 适用条件 | 核心策略 |
|---|------|---------|---------|
| 1 | 提示增强 | 简单任务，1-2步 | 优化单agent提示词，不拆分不组队 |
| 2 | Skill直接复用 | 任务可由单个Skill完全解决 | 执行规划和Skill搜索后，直接调用匹配的Skill，无需组建Agent Teams |
| 3 | 计划+评审 | 中等/复杂任务（**默认**） | 出计划 → 用户确认 → 并行执行 → Review验收 |
| 4 | Lead-Member | 需要明确团队分工 | Leader协调分配，Member并行执行，通过TaskList协同 |
| 5 | 复合编排 | 复杂任务，无固定模式 | 动态组合上述场景，按阶段切换策略 |


**模型分工**（所有场景通用）：通过平台支持的模型选择能力按任务复杂度分配；Claude Code 可通过 Task 工具的 `model` 参数分配——`opus`处理复杂推理，`haiku`处理简单任务，`sonnet`处理常规任务。平台不支持模型选择时，不要写死模型承诺。

## 协作模式

| 模式 | 通信方式 | 适用场景 | Claude Code 启动方式 | Codex 启动方式 | OpenClaw / Cursor 启动方式 |
|------|---------|---------|---------|---------|---------|
| Subagent | 子agent → 主协调器单向汇报 | 并行独立任务 | `Task`工具 | 宿主提供的 subagent/custom-agent dispatch；不可用则主线程分阶段执行 | 平台 agent/background/workspace 能力；不可用则主线程分阶段执行 |
| Agent Team | 成员间可双向通信(SendMessage) | 需要协作的复杂任务 | `TeamCreate` + `Task(team_name)` | 多个独立 subagent + 主线程协调；仅在宿主暴露 agent I/O 时中途交互 | 平台 team/workspace/background-agent 能力；没有则降级 |

选择原则：任务间无依赖用Subagent（简单高效），任务间需要协调用Agent Team（功能更强但成本更高）。如果当前平台没有真正的 team bus，只能称为"多个独立 subagent + 主线程汇总"，不能伪装成成员间双向协作。

## 6阶段工作流（含强制规划和Skill搜索）

**重要说明**：阶段0和阶段1是**所有场景的强制前置步骤**，场景选择（1-5）只影响阶段2-5的执行方式。

### 阶段0：规划准备（Planning Setup）**【硬性标准 - 所有场景必经】**

**优先使用当前平台的 Skill 工具调用 planning-with-files**：
```
Skill(skill="planning-with-files")
```

跨平台适配：
- Claude Code：优先使用 `Skill(skill="planning-with-files")`
- Codex：若本地 skill/tool 可用则使用；否则使用平台计划工具或内联计划，并明确说明没有创建 planning files
- OpenClaw/Cursor：若本地 planning skill 可用则使用；否则维护平台可见计划记录

这将在项目目录创建三个核心文件（当 planning-with-files 可用时）：
- `task_plan.md` - 任务计划和阶段追踪
- `findings.md` - 研究发现和知识积累
- `progress.md` - 执行日志和进度记录

**关键规则**（规划文件创建后遵循）：
- 每个阶段开始前读取task_plan.md，完成后更新状态
- 每2次搜索/浏览操作后立即保存发现到findings.md
- 所有错误必须记录到task_plan.md的"Errors Encountered"表格
- 3次失败后升级给用户

> **铁律**：复杂任务不能没有计划就开始执行。若平台没有 planning-with-files，也必须使用等价计划记录或内联计划，不能跳过规划阶段。

### 阶段1：任务分析 + Skill发现（Discovery）**【硬性标准 - 所有场景必经】**

先质疑再执行：
- 需求不合理时主动挑战假设，建议更好的方案
- 区分"现在必须做"和"以后再说"，排除非核心范围
- 任务太大时建议更聪明的起点
- 先描述所需能力，再匹配 agent / skill / tool，避免 name-first 调度

输出任务总览：

| 字段 | 内容 |
|------|------|
| 任务目标 | [一句话描述] |
| 预期结果 | [具体交付物] |
| 验收标准 | [可量化的通过条件] |
| 范围界定 | [must-have vs add-later] |
| 当前平台 | [Claude Code / Codex / OpenClaw / Cursor / Unknown] |
| 预计Agent数 | [N个，建议≤5] |
| 选定场景 | [场景编号+名称] |
| 协作模式 | [Subagent/Agent Team/Degraded] |

**Skill完整回退链**（强制执行，不可跳过）：

对每个子任务执行以下3步fallback chain：

1. **本地Skill扫描**：
   - 读取当前运行时可见的 available skills / agents / tools / capability index
   - 提取每个skill的名称和触发词/描述
   - 将子任务关键词与skill触发词比对
   - 匹配成功 → 标注`[Skill: skill-name]`，进入阶段2直接调用

2. **外部Skill搜索**（本地无匹配时）：
   - 平台提供 Skill 工具时调用 find-skills：
   ```
   Skill(skill="find-skills", args="子任务关键词")
   ```
   - 平台没有 Skill 工具时，使用可用的外部能力搜索方式；没有搜索能力时向用户说明降级
   - 搜索到 → 向用户推荐：`npx skills add <owner/repo@skill-name> -g -y`
   - 用户确认安装 → 标注新skill，进入阶段2调用
   - 用户拒绝或平台无法安装 → 继续第3步

3. **通用Subagent回退**（外部也无匹配时）：
   - 平台支持 subagent 时，该角色改用通用subagent
   - 平台不支持 subagent 时，该角色改用主线程分阶段执行
   - 在团队蓝图中标注`[Type: general-purpose]`或`[Degraded: main-thread staged execution]`

> **铁律**：这3步必须全部执行完才能进入阶段2。不允许跳过find-skills搜索；若平台没有 find-skills 或 Skill 工具，必须显式记录降级原因。

### 阶段2：团队组建

输出团队蓝图：

| 编号 | 角色 | 职责 | 模型 | subagent_type | Skill/Type | 平台工具/降级 |
|------|------|------|------|---------------|------------|---------------|
| 1 | [角色名] | [具体职责] | [opus/sonnet/haiku/平台默认] | [agent类型] | [Skill: name] 或 [Type: general-purpose] | [Task/spawn/custom-agent/main-thread] |

> **说明**：最后两列标注该角色使用的Skill名称（阶段1已匹配）或通用类型（fallback），以及当前平台真实使用的工具或降级路径。

### 阶段3：并行执行

- **Skill任务**：用当前平台的 Skill 调用机制调用本地已安装的skill；Claude Code 示例：`Skill(skill="skill-name", args="任务描述")`
- **通用任务**：用当前平台 subagent 工具生成subagent；Claude Code 对应 `Task`，Codex/OpenClaw/Cursor 使用宿主实际暴露的 agent dispatch
- 混合编排时skill和subagent可并行运行；平台不支持并行时按阶段顺序执行并说明降级
- 每个agent/skill完成后汇报：`✅ [角色名] 完成: [一句话结果]`
- 遇到问题时给用户选项，而不是自己默默选一个

**Agent → Skill 委派**（子agent调用skill的3种模式）：

`general-purpose`类型的subagent在 Claude Code 中通常拥有所有工具权限，包括`Skill`工具；其他平台必须先确认当前宿主是否给子agent开放等价 skill/tool 权限。

| 模式 | 流程 | 适用场景 |
|------|------|---------|
| 协调器直调 | 协调器 → `Skill(skill="name")` 或平台等价调用 → 结果 | 单步Skill任务，无需并行 |
| 委派式调用 | 协调器 → subagent prompt="请使用 /skill-name 完成 X" → subagent → Skill/tool 或内联执行 → 汇报 | 并行多个Skill，或Skill耗时较长 |
| 团队成员调用 | team/subagents → 分配任务 → member → Skill/tool 或内联执行 → 汇报 | 需要成员间协调的复杂任务 |

委派式调用关键点：Task/subagent prompt 中写明要调用的Skill名称和参数；只有平台支持 skill 工具时才承诺自动调用，否则按 Skill 文档内联执行并说明。

### 阶段4：质量把关 & 产品打磨

**验收检查**：对照阶段1的验收标准逐项检查。

**产品打磨**（不仅功能完整，更要用户体验优秀）：
- 边界处理：异常输入、空值、极端情况是否覆盖
- 专业度：命名规范、代码风格、错误提示是否友好
- 完整性：文档、配置说明、使用示例是否齐全
- 平台诚实性：是否准确说明了真实调用的工具和降级行为

全部通过 → 进入阶段5。不通过 → 打回修改，最多2轮，仍不通过则通知用户人工介入。

### 阶段5：结果交付 & 部署移交

输出执行报告：

| 项目 | 内容 |
|------|------|
| 总任务数 | X个，成功Y个，失败Z个 |
| 实际平台工具 | 使用了哪些真实工具 / 是否降级 |
| 各Agent结果 | [角色]: [状态] - [关键产出] |
| 汇总结论 | [综合所有结果的最终结论] |
| 后续建议 | [当前未覆盖但值得做的改进方向] |

**部署移交**（按需提供）：
- 运行方式：启动命令、环境要求、配置说明
- 验证步骤：用户可自行验证的操作清单
- 已知限制：当前版本的边界和约束

## 执行底线

**【硬性标准】**：
0. **强制使用 planning-with-files 或平台等价计划机制**：任何复杂任务必须先创建/维护 task_plan.md、findings.md、progress.md，或显式说明使用了平台等价计划记录
1. **强制执行Skill完整回退链**：本地扫描 → `Skill(skill="find-skills", args="...")` 或平台等价搜索 → 通用subagent/主线程降级，不允许跳过任何步骤

**【其他原则】**：
2. 先目标，后组织结构——任务不清晰时先澄清，再决定是否组建团队
3. 队伍规模由任务复杂度决定，并行Agent建议不超过5个
4. 关键里程碑必须有质量闸门和回滚点
5. 不默认任何外部工具可用，执行前先验证（含find-skills）
6. 浏览器多窗口默认互相独立，不共享上下文
7. 成本只是约束，不是固定承诺——不做不切实际的成本预估
8. 危险操作、大规模变更必须先获得用户确认或遵守宿主平台审批规则
9. 不承诺平台没有的能力；尤其不要在 Codex/OpenClaw/Cursor 中直接承诺 Claude Code 的 `TeamCreate`

## 故障处理

| 故障类型 | 处理策略 |
|---------|---------|
| Agent执行失败 | 通知用户，提供重试/跳过/终止/降级选项 |
| Skill不可用 | 按回退链降级：本地Skill → find-skills/平台等价搜索 → 通用subagent → 主线程分阶段执行 |
| 平台工具缺失 | 改用该平台可用工具，并明确说明降级路径 |
| 模型超时 | 调整任务复杂度或拆分为更小的子任务 |
| 质量不达标 | 打回修改最多2轮，仍不通过则人工介入 |
| 上下文溢出 | 拆分为更小的子任务，分批执行 |
