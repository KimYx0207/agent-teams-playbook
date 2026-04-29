[中文](./README.md) | [English](./README_EN.md)

# Agent Teams 编排手册

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/KimYx0207/agent-teams-playbook?style=social)
![GitHub forks](https://img.shields.io/github/forks/KimYx0207/agent-teams-playbook?style=social)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-4.7-green.svg)
![Runtime](https://img.shields.io/badge/runtimes-Claude%20Code%20%7C%20Codex%20%7C%20OpenClaw%20%7C%20Cursor-blue.svg)

</div>

> 老金的开源知识库，实时更新群二维码：https://my.feishu.cn/wiki/OhQ8wqntFihcI1kWVDlcNdpznFf

## 📞 联系方式

<div align="center">
  <img src="images/二维码基础款.png" alt="联系方式" width="600"/>
  <p><strong>获取更多AI资讯和技术支持</strong></p>
  <p>微信公众号：获取AI第一信息 | 个人微信号：备注'AI'加群交流</p>
</div>

### ☕ 请我喝杯咖啡

<div align="center">
  <p><strong>如果这个教程对你有帮助，欢迎打赏支持！</strong></p>
  <table align="center">
    <tr>
      <td align="center">
        <img src="images/微信.jpg" alt="微信收款码" width="300"/>
        <br/>
        <strong>微信支付</strong>
      </td>
      <td align="center">
        <img src="images/支付宝.jpg" alt="支付宝收款码" width="300"/>
        <br/>
        <strong>支付宝</strong>
      </td>
    </tr>
  </table>
</div>

---

## 概述

`agent-teams-playbook` 是一个跨运行时 Skill，用于生成可执行的多代理（Agent Teams）编排策略，兼容 Claude Code、Codex、OpenClaw、Cursor 四个平台。

> **核心理解**："swarm/蜂群"是通用行业说法，Claude Code的官方概念是 **Agent Teams**。其他运行时不一定有同名工具，但可以用各自的 subagent/background-agent/workspace 能力实现同一套"并行外脑 + 汇总压缩"编排合同。Agent Teams **不是**"单脑扩容"——并行读取/处理的总量可以很大，但回到主会话仍需总结压缩。

核心思想是"自适应决策"，而不是"写死配置"。面向真实运行环境中的不确定性：

- Skill/工具/agent 能力可用性变化
- 四个平台工具名不同、能力不完全等价
- 多会话或多窗口上下文分叉
- 质量、速度、成本目标冲突

## 触发方式

**自然语言触发词：**

- agent teams、agent swarm、多agent、agent协作、agent编排、并行agent
- 分工协作、拉团队、多代理协作、swarm编排、agent团队
- multi-agent、orchestration、agent team

**Skill命令（Claude Code 或支持 slash skill launcher 的运行时）：**

- `/agent-teams-playbook [任务描述]`

## 安装方式

### 方式一：命令行安装（推荐）

```bash
# 克隆仓库
git clone https://github.com/KimYx0207/agent-teams-playbook.git

# 运行安装脚本（Unix / Git Bash / WSL）
cd agent-teams-playbook
chmod +x scripts/install.sh

# 安装到 Claude Code（默认）
./scripts/install.sh

# 安装到指定平台
./scripts/install.sh --target codex
./scripts/install.sh --target openclaw
./scripts/install.sh --target cursor

# 一次安装到四个平台
./scripts/install.sh --target all

# 从 GitHub main 下载安装，而不是复制当前本地 checkout
./scripts/install.sh --target all --from-github
```

### 方式二：手动安装

```bash
# Claude Code
mkdir -p ~/.claude/skills/agent-teams-playbook
cp SKILL.md ~/.claude/skills/agent-teams-playbook/
cp README.md ~/.claude/skills/agent-teams-playbook/

# Codex
mkdir -p ~/.codex/skills/agent-teams-playbook
cp SKILL.md ~/.codex/skills/agent-teams-playbook/
cp README.md ~/.codex/skills/agent-teams-playbook/

# OpenClaw（默认全局 skill 根目录；项目也可使用 openclaw/skills/）
mkdir -p ~/.agents/skills/agent-teams-playbook
cp SKILL.md ~/.agents/skills/agent-teams-playbook/
cp README.md ~/.agents/skills/agent-teams-playbook/

# Cursor
mkdir -p ~/.cursor/skills/agent-teams-playbook
cp SKILL.md ~/.cursor/skills/agent-teams-playbook/
cp README.md ~/.cursor/skills/agent-teams-playbook/
```

安装脚本支持通过环境变量覆盖目标根目录：

| 平台 | 环境变量 | 默认目录 |
| ---- | -------- | -------- |
| Claude Code | `CLAUDE_SKILLS_DIR` | `~/.claude/skills` |
| Codex | `CODEX_SKILLS_DIR` | `~/.codex/skills` |
| OpenClaw | `OPENCLAW_SKILLS_DIR` | `~/.agents/skills` |
| Cursor | `CURSOR_SKILLS_DIR` | `~/.cursor/skills` |

### 验证安装

安装完成后，你可以通过以下方式使用：

```bash
# Claude Code 使用 Skill 命令
/agent-teams-playbook 我的任务描述

# 或使用自然语言
帮我组建一个Agent团队来完成这个任务...

# Codex / OpenClaw / Cursor
# 使用自然语言触发；运行时会按各自平台工具映射执行
帮我拉一个 agent team 来审查这个重构方案
```

## 核心设计原则

1. 先目标，后组织结构——任务不清晰时先澄清，不急着组队
2. 队伍规模由任务复杂度决定，并行Agent建议不超过5个
3. 能力回退链：本地 Skill/Agent 扫描 → 外部能力搜索（如可用）→ 通用 subagent → 主线程降级
4. 平台适配：先用抽象动作描述编排，再映射到当前平台的原生工具
5. 模型分工：只在平台支持模型选择时指定模型；不支持时不要写死
6. 不默认任何外部工具可用，执行前先验证
7. 关键里程碑必须有质量闸门和回滚点
8. 成本只是约束，不是固定承诺
9. Skill Discovery 纯动态——从当前运行时可见的 skills / agents / capability index 扫描，不硬编码任何项目特定 Skill

## 推荐 Skills 依赖

本 skill 优先复用以下通用 skill，但不再把它们写成所有平台的硬依赖。原因是 Codex、OpenClaw、Cursor 的 skill 调用机制和可见目录可能不同；当依赖不可用时，应使用该平台的计划工具或主线程降级执行。

| Skill                         | 用途                                                              | 调用阶段              |
| ----------------------------- | ----------------------------------------------------------------- | --------------------- |
| **planning-with-files** | Manus风格文件规划系统，创建task_plan.md、findings.md、progress.md | 阶段0（所有场景必经） |
| **find-skills**         | 外部skill搜索和发现，扩展本地skill库                              | 阶段1（Skill回退链）  |

**降级原则**：依赖存在就调用；不存在就显式说明降级方式，继续用当前平台可用的 plan / search / agent 工具完成编排。

## 5大编排场景

| # | 场景          | 适用条件                        | 核心策略                                                        |
| - | ------------- | ------------------------------- | --------------------------------------------------------------- |
| 1 | 提示增强      | 简单任务，1-2步                 | 优化单agent提示词，不拆分不组队                                 |
| 2 | Skill直接复用 | 任务可由单个Skill完全解决       | 执行规划和Skill搜索后，直接调用匹配的Skill，无需组建Agent Teams |
| 3 | 计划+评审     | 中等/复杂任务（**默认**） | 出计划 → 按宿主审批规则执行 → Review验收                    |
| 4 | Lead-Member   | 需要明确团队分工                | Leader协调分配，Member并行执行                                  |
| 5 | 复合编排      | 复杂任务，无固定模式            | 动态组合上述场景，按阶段切换策略                                |

## 6阶段工作流

```
阶段0：规划准备 → 阶段1：任务分析+Skill发现 → 阶段2：团队组建 → 阶段3：并行执行 → 阶段4：质量把关 → 阶段5：结果交付
```

> **注意**：阶段0（规划准备）和阶段1（能力发现）是所有场景的**强制前置步骤**。优先调用 `planning-with-files` / `find-skills`，但如果当前平台没有对应 skill/tool，必须明确降级而不是假装已经调用。

每个阶段：输出计划 → 执行 → 输出结果。任务拆分计划按宿主审批规则和用户指令执行；需要确认时先确认。

## 协作模式

| 模式       | 通信方式                      | 适用场景           | Claude Code | Codex | OpenClaw / Cursor |
| ---------- | ----------------------------- | ------------------ | ----------- | ----- | ----------------- |
| Subagent   | 子agent → 主协调器单向汇报   | 并行独立任务       | `Task` | 宿主提供的 subagent/custom-agent dispatch；否则降级 | 平台 agent/background 能力 |
| Agent Team | 成员间可双向通信              | 需要协作的复杂任务 | `TeamCreate` + `Task(team_name)` | 多个独立 subagent + 主线程协调；仅在宿主暴露 agent I/O 时中途交互 | 平台 team/workspace 能力；没有则降级 |

## Agent → Skill 委派

子 Agent 调用 Skill 有3种模式。Claude Code 可直接使用 `Skill` 工具；Codex、OpenClaw、Cursor 需要先确认当前运行时是否提供等价 skill 调用能力。没有等价工具时，按 skill 文档内联执行或降级为主线程处理。

### Pattern 1：协调器直接调用（Direct Skill Call）

协调器自己调用Skill工具，不经过子Agent。适合单步Skill任务、不需要并行的场景。

```
用户 → 协调器 → Skill tool → 结果返回给用户
```

### Pattern 2：委派式调用（Delegated Skill Call）

协调器通过当前平台 subagent 工具生成子 Agent，在任务说明中注入 Skill 调用指令，子 Agent 执行 Skill 并汇报结果。适合需要并行多个 Skill、或 Skill 执行耗时较长的场景。

```
协调器 → subagent(prompt="请使用 /skill-name 完成 X") → subagent → Skill/tool 或内联执行 → 结果汇报
```

**关键点**：任务说明中写明要调用的 Skill 名称和参数；只有平台支持 skill 工具时才承诺自动调用。

### Pattern 3：团队成员调用（Team Member Skill Call）

通过当前平台团队能力组建团队，成员在协作过程中按需调用 Skill。适合长期运行、需要成员间协调的复杂任务。Claude Code 使用 `TeamCreate`；Codex 使用宿主提供的 subagent/custom-agent 能力加主线程协调；OpenClaw/Cursor 使用各自 team/workspace/background-agent 能力，不可用时降级。

```
协调器 → team/subagents → 分配任务 → member → Skill/tool 或内联执行 → 汇报
```

### 选择建议

| 场景                    | 推荐Pattern | 原因                      |
| ----------------------- | ----------- | ------------------------- |
| 单个Skill任务           | Pattern 1   | 最简单，无额外开销        |
| 并行多个Skill           | Pattern 2   | 平台提供并发 subagent 时可并行 |
| 需要成员间协作          | Pattern 3   | 平台提供 team messaging 时可双向通信 |
| Skill执行后需要后续处理 | Pattern 2/3 | subagent可以处理Skill输出 |

## 仓库结构

```text
agent-teams-playbook/
├── SKILL.md    # 运行时加载（完整执行协议 + 跨平台适配层）
└── README.md   # 开发者文档（完整说明）
```

**关键区别：**

- `SKILL.md` 运行时加载，必须精简，避免不必要 token 消耗
- `README.md` 给人看的文档，可以写完整说明

## 兼容性

| 平台 | 支持级别 | 说明 |
| ---- | -------- | ---- |
| Claude Code | 原生 | 可使用 `Skill`、`Task`、`TeamCreate`、`SendMessage` 等 Agent Teams 语义 |
| Codex | 适配 | 使用宿主提供的 subagent/custom-agent dispatch 与 agent I/O；不可用时降级为主线程分阶段执行，没有真正 `TeamCreate` 总线 |
| OpenClaw | 适配 | 使用 OpenClaw workspace/team/skill 能力；能力缺失时降级为分阶段执行 |
| Cursor | 适配 | 使用 Cursor agent/background-agent 和 `.cursor/skills`；能力缺失时降级为分阶段执行 |

**重要边界**：四个平台能力不完全等价。本 skill 的稳定部分是"编排合同"：先澄清目标、再能力发现、再团队蓝图、再执行/评审/验证。具体工具名必须由运行时适配层决定。

### Context模式（可选配置）

Claude Code 默认**不设置** `context: fork`，6阶段工作流在主会话中执行，用户可以看到每个阶段的完整输出，并在阶段1确认计划后再执行。

如果你希望隔离上下文（避免编排过程占用主会话上下文窗口），可以手动在SKILL.md的frontmatter中添加：

```yaml
---
name: agent-teams-playbook
version: "4.7"
context: fork    # 添加这行启用隔离模式
---
```

| 模式           | 6阶段可见         | 用户可确认计划 | 上下文隔离    | 适合场景                        |
| -------------- | ----------------- | -------------- | ------------- | ------------------------------- |
| 默认（无fork） | ✅ 完全可见       | ✅ 可以        | ❌ 共享主会话 | 需要看到完整流程、需要确认计划  |
| fork模式       | ❌ 仅看到最终结果 | ❌ 自动执行    | ✅ 隔离执行   | 信任Skill决策、节省主会话上下文 |

## 非目标（明确不做）

本 Skill 不会：

- 强制固定团队结构
- 强制单一 Skill 依赖
- 承诺固定速度/成本倍数
- 声称能做 Claude Code 实际做不到的事

## 维护建议

更新本 Skill 时：

1. `SKILL.md` 保持精简、只保留执行必需信息
2. 行为发生变化时同步更新本 README
3. 保持两个文件的版本号一致

---

**版本**：V4.7
**最后更新**：2026-04-30
**维护者**：老金
