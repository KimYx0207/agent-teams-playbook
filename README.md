# Agent Teams 编排手册

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/KimYx0207/agent-teams-playbook?style=social)
![GitHub forks](https://img.shields.io/github/forks/KimYx0207/agent-teams-playbook?style=social)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/Claude_Code-2.1.39-green.svg)

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

`agent-teams-playbook` 是一个以 Claude Code 为优先目标的 Skill，用于生成可执行的多代理（Agent Teams）编排策略。

> **核心理解**："swarm/蜂群"是通用行业说法，Claude Code的官方概念是 **Agent Teams**。每个teammate是独立Claude Code实例，各自有上下文窗口。Agent Teams是"并行外脑 + 汇总压缩"，**不是**"单脑扩容"——并行读取/处理的总量可以很大，但回到主会话仍需总结压缩。

核心思想是"自适应决策"，而不是"写死配置"。面向真实运行环境中的不确定性：

- Skill/工具可用性变化
- 多会话或多窗口上下文分叉
- 质量、速度、成本目标冲突

## 触发方式

**自然语言触发词：**

- agent teams、agent swarm、多agent、agent协作、agent编排、并行agent
- 分工协作、拉团队、多代理协作、swarm编排、agent团队
- multi-agent、orchestration、agent team

**Skill命令：**

- `/agent-teams-playbook [任务描述]`

## 安装方式

### 方式一：命令行安装（推荐）

```bash
# 克隆仓库
git clone https://github.com/KimYx0207/agent-teams-playbook.git

# 运行安装脚本
cd agent-teams-playbook
chmod +x scripts/install.sh
./scripts/install.sh
```

### 方式二：手动安装

```bash
# 创建 Skill 目录
mkdir -p ~/.claude/skills/agent-teams-playbook

# 复制文件
cp SKILL.md ~/.claude/skills/agent-teams-playbook/
cp README.md ~/.claude/skills/agent-teams-playbook/
```

### 验证安装

安装完成后，你可以通过以下方式使用：

```bash
# 使用 Skill 命令
/agent-teams-playbook 我的任务描述

# 或使用自然语言
帮我组建一个Agent团队来完成这个任务...
```

## 核心设计原则

1. 先目标，后组织结构——任务不清晰时先澄清，不急着组队
2. 队伍规模由任务复杂度决定，并行Agent建议不超过5个
3. Skill回退链：本地Skill扫描 → find-skills搜索外部 → 通用subagent
4. 模型分工：通过Task工具的 `model`参数按复杂度分配（opus/sonnet/haiku）
5. 不默认任何外部工具可用，执行前先验证
6. 关键里程碑必须有质量闸门和回滚点
7. 成本只是约束，不是固定承诺
8. Skill Discovery 纯动态——从 system-reminder 扫描可用 Skills，不硬编码任何项目特定 Skill

## 必要Skills依赖

本skill依赖以下两个通用skill作为强制前置步骤：

| Skill                         | 用途                                                              | 调用阶段              |
| ----------------------------- | ----------------------------------------------------------------- | --------------------- |
| **planning-with-files** | Manus风格文件规划系统，创建task_plan.md、findings.md、progress.md | 阶段0（所有场景必经） |
| **find-skills**         | 外部skill搜索和发现，扩展本地skill库                              | 阶段1（Skill回退链）  |

**Token优化说明**：这些skill的具体调用方式和参数已在SKILL.md的执行流程中详细说明，此处不重复以节省token消耗。用户在使用本skill时，系统会自动按照阶段0和阶段1的要求调用这些依赖skill。

## 5大编排场景

| # | 场景          | 适用条件                        | 核心策略                                                        |
| - | ------------- | ------------------------------- | --------------------------------------------------------------- |
| 1 | 提示增强      | 简单任务，1-2步                 | 优化单agent提示词，不拆分不组队                                 |
| 2 | Skill直接复用 | 任务可由单个Skill完全解决       | 执行规划和Skill搜索后，直接调用匹配的Skill，无需组建Agent Teams |
| 3 | 计划+评审     | 中等/复杂任务（**默认**） | 出计划 → 用户确认 → 并行执行 → Review验收                    |
| 4 | Lead-Member   | 需要明确团队分工                | Leader协调分配，Member并行执行                                  |
| 5 | 复合编排      | 复杂任务，无固定模式            | 动态组合上述场景，按阶段切换策略                                |

## 6阶段工作流

```
阶段0：规划准备 → 阶段1：任务分析+Skill发现 → 阶段2：团队组建 → 阶段3：并行执行 → 阶段4：质量把关 → 阶段5：结果交付
```

> **注意**：阶段0（planning-with-files）和阶段1（Skill搜索，包含 find-skills）是所有场景的**强制前置步骤**

每个阶段：输出计划 → 执行 → 输出结果。任务拆分计划必须经用户确认后再执行。

## 协作模式

| 模式       | 通信方式                      | 适用场景           | 启动方式                             |
| ---------- | ----------------------------- | ------------------ | ------------------------------------ |
| Subagent   | 子agent → 主协调器单向汇报   | 并行独立任务       | `Task`工具                         |
| Agent Team | 成员间可双向通信(SendMessage) | 需要协作的复杂任务 | `TeamCreate` + `Task(team_name)` |

## Agent → Skill 委派

子Agent调用Skill有3种模式，核心洞察：`general-purpose`类型的subagent拥有所有工具权限，包括 `Skill`工具。

### Pattern 1：协调器直接调用（Direct Skill Call）

协调器自己调用Skill工具，不经过子Agent。适合单步Skill任务、不需要并行的场景。

```
用户 → 协调器 → Skill tool → 结果返回给用户
```

### Pattern 2：委派式调用（Delegated Skill Call）

协调器通过Task工具生成子Agent，在Task prompt中注入Skill调用指令，子Agent执行Skill并汇报结果。适合需要并行多个Skill、或Skill执行耗时较长的场景。

```
协调器 → Task(prompt="请使用 /skill-name 完成 X") → subagent → Skill tool → 结果汇报
```

**关键点**：Task prompt中写明要调用的Skill名称和参数，subagent会自动识别并调用。

### Pattern 3：团队成员调用（Team Member Skill Call）

通过TeamCreate组建团队，成员在协作过程中按需调用Skill。适合长期运行、需要成员间协调的复杂任务。

```
协调器 → TeamCreate → 分配任务(TaskUpdate) → member → Skill tool → SendMessage汇报
```

### 选择建议

| 场景                    | 推荐Pattern | 原因                      |
| ----------------------- | ----------- | ------------------------- |
| 单个Skill任务           | Pattern 1   | 最简单，无额外开销        |
| 并行多个Skill           | Pattern 2   | Task天然支持并行          |
| 需要成员间协作          | Pattern 3   | SendMessage双向通信       |
| Skill执行后需要后续处理 | Pattern 2/3 | subagent可以处理Skill输出 |

## 仓库结构

```text
agent-teams-playbook/
├── SKILL.md    # 运行时加载（精简，~170行）
└── README.md   # 开发者文档（完整说明）
```

**关键区别：**

- `SKILL.md` 运行时加载，必须精简，避免不必要 token 消耗
- `README.md` 给人看的文档，可以写完整说明

## 兼容性

- **主目标平台**：Claude Code

### Context模式（可选配置）

默认**不设置** `context: fork`，6阶段工作流在主会话中执行，用户可以看到每个阶段的完整输出，并在阶段1确认计划后再执行。

如果你希望隔离上下文（避免编排过程占用主会话上下文窗口），可以手动在SKILL.md的frontmatter中添加：

```yaml
---
name: agent-teams-playbook
version: "4.5"
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

**版本**：V4.5
**最后更新**：2026-02-14
**维护者**：老金
