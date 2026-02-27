[English](./README_EN.md) | [中文](./README.md)

# Agent Teams Orchestration Playbook

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/KimYx0207/agent-teams-playbook?style=social)
![GitHub forks](https://img.shields.io/github/forks/KimYx0207/agent-teams-playbook?style=social)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/Claude_Code-2.1.39-green.svg)

**A Claude Code Skill for generating executable multi-agent (Agent Teams) orchestration strategies**

</div>

---

## Overview

`agent-teams-playbook` is a Claude Code-first Skill for generating executable multi-agent orchestration strategies.

> **Core Concept**: "Swarm" is the generic industry term; Claude Code's official concept is **Agent Teams**. Each teammate is an independent Claude Code instance with its own context window. Agent Teams = "parallel external brains + summarized compression", **not** "single brain expansion".

The core philosophy is "adaptive decision-making" rather than "hardcoded configuration", designed for real-world uncertainty:

- Skill/tool availability changes
- Multi-session or multi-window context forks
- Quality, speed, and cost objective conflicts

## Trigger Methods

**Natural Language Triggers:**
- agent teams, agent swarm, multi-agent, agent collaboration, agent orchestration, parallel agents
- multi-agent collaboration, swarm orchestration, agent team

**Skill Command:**
- `/agent-teams-playbook [task description]`

## Installation

### Option 1: CLI Installation (Recommended)

```bash
git clone https://github.com/KimYx0207/agent-teams-playbook.git
cd agent-teams-playbook
chmod +x scripts/install.sh
./scripts/install.sh
```

### Option 2: Manual Installation

```bash
mkdir -p ~/.claude/skills/agent-teams-playbook
cp SKILL.md ~/.claude/skills/agent-teams-playbook/
cp README.md ~/.claude/skills/agent-teams-playbook/
```

### Verify Installation

```bash
# Use Skill command
/agent-teams-playbook my task description

# Or use natural language
Help me build an Agent team to complete this task...
```

## Core Design Principles

1. Goals first, then organization — clarify the task before assembling a team
2. Team size depends on task complexity, parallel Agents recommended <=5
3. Skill fallback chain: local Skill scan → find-skills external search → general-purpose subagent
4. Model assignment: use Task tool's `model` parameter by complexity (opus/sonnet/haiku)
5. Never assume external tools are available — verify before execution
6. Critical milestones must have quality gates and rollback points
7. Cost is a constraint, not a fixed commitment
8. Skill Discovery is purely dynamic — scan available Skills from system-reminder, never hardcode

## Required Skill Dependencies

| Skill | Purpose | Stage |
|-------|---------|-------|
| **planning-with-files** | Manus-style file planning: task_plan.md, findings.md, progress.md | Stage 0 (mandatory) |
| **find-skills** | External skill search and discovery | Stage 1 (Skill fallback chain) |

## 5 Orchestration Scenarios

| # | Scenario | When to Use | Strategy |
|---|----------|------------|----------|
| 1 | Prompt Enhancement | Simple tasks, 1-2 steps | Optimize single agent prompt, no splitting |
| 2 | Direct Skill Reuse | Task solvable by a single Skill | Plan + search, then call matching Skill directly |
| 3 | Plan + Review | Medium/complex tasks (**default**) | Plan → user confirms → parallel execution → review |
| 4 | Lead-Member | Clear team division needed | Leader coordinates, Members execute in parallel |
| 5 | Composite Orchestration | Complex tasks, no fixed pattern | Dynamically combine above scenarios |

## 6-Stage Workflow

```
Stage 0: Planning Setup → Stage 1: Task Analysis + Skill Discovery → Stage 2: Team Assembly → Stage 3: Parallel Execution → Stage 4: Quality Gate → Stage 5: Delivery
```

> **Note**: Stage 0 (planning-with-files) and Stage 1 (Skill search, including find-skills) are **mandatory prerequisites** for all scenarios.

## Collaboration Modes

| Mode | Communication | Use Case | Launch |
|------|--------------|----------|--------|
| Subagent | One-way: child → coordinator | Parallel independent tasks | `Task` tool |
| Agent Team | Bidirectional (SendMessage) | Complex collaborative tasks | `TeamCreate` + `Task(team_name)` |

## Agent → Skill Delegation Patterns

| Pattern | Flow | Best For |
|---------|------|----------|
| Direct Call | Coordinator → `Skill` → result | Single-step Skill tasks |
| Delegated Call | Coordinator → `Task(prompt)` → subagent → `Skill` → report | Parallel Skills, long-running |
| Team Member Call | `TeamCreate` → assign → member → `Skill` → `SendMessage` | Complex coordinated tasks |

## Repository Structure

```text
agent-teams-playbook/
├── SKILL.md    # Runtime loaded (concise, ~170 lines)
└── README.md   # Developer documentation (full details)
```

## Compatibility

- **Primary platform**: Claude Code

### Context Mode (Optional)

Default: no `context: fork`. The 6-stage workflow runs in the main session. Add `context: fork` to SKILL.md frontmatter for isolated execution.

## Non-Goals

This Skill will NOT:
- Force fixed team structures
- Force single Skill dependencies
- Promise fixed speed/cost multipliers
- Claim capabilities beyond Claude Code's actual limits

---

**Version**: V4.5 | **Last Updated**: 2026-02-14 | **Maintainer**: KimYx0207
