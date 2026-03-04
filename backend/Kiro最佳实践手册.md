# Kiro 最佳实践手册

> 通用配置指南，适用于任何项目。拿到即可照着配，节省 Token、减少错误、提升效率。
>
> **最后更新**：2026-02-17

---

## 目录

1. [核心理念](#一核心理念)
2. [Steering 文件配置](#二steering-文件配置)
3. [全局规则（Global Rules）](#三全局规则global-rules)
4. [Agent Hooks 配置](#四agent-hooks-配置)
5. [Kiro Powers](#五kiro-powers)
6. [MCP 配置](#六mcp-配置)
7. [子代理配置](#七子代理配置)
8. [Specs 功能规格](#八specs-功能规格)
9. [完整目录结构模板](#九完整目录结构模板)
10. [快速启动清单](#十快速启动清单)
11. [常见问题](#十一常见问题)

---

## 一、核心理念

### 1.1 三层规则体系

Kiro 的规则分三层，理解这个体系是配置的基础：

| 层级 | 位置 | 作用域 | 说明 |
|------|------|--------|------|
| 全局规则 | `~/.kiro/steering/*.md` | 所有项目 | AI 行为规范、工作模式、反思机制 |
| 工作区规则 | `.kiro/steering/*.md` | 当前项目 | 项目规则、安全规范、踩坑库 |
| Powers | `.kiro/powers/*/` | 按需激活 | 特定领域的 MCP + steering + hooks |

**优先级**：工作区规则 > 全局规则（冲突时工作区覆盖全局）

### 1.2 Token 节省核心原则

| 原则 | 说明 |
|------|------|
| always 只放 3 个 | 核心规则 + 项目记忆 + 安全规范 |
| fileMatch 按语言/目录 | 只在打开匹配文件时加载 |
| manual 按需引用 | 踩坑库、技能文件等用 `#文件名` 手动加载 |
| Powers 按需激活 | MCP 服务器不常驻，提到关键词才加载 |

### 1.3 闭环机制

配置的终极目标是形成自动化闭环：

```
做之前查（ai-persona 规则 → 检索踩坑库）
    ↓
做之中查（遇到不确定 → 立即检索文档）
    ↓
做之后验（self-reflection → 验证 + 反思）
    ↓
自动沉淀（Hook → 写入踩坑库 + 日志）
    ↓
下次复用（ai-persona 再次检索踩坑库）→ 闭环 ✅
```

---

## 二、Steering 文件配置

### 2.1 三种加载模式

| 模式 | front matter | 触发条件 | Token 消耗 |
|------|-------------|---------|-----------|
| always | `inclusion: always` | 每次对话自动加载 | 持续消耗 |
| fileMatch | `inclusion: fileMatch` | 打开匹配文件时加载 | 按需消耗 |
| manual | `inclusion: manual` | 用户输入 `#文件名` 时加载 | 手动消耗 |

#### front matter 格式

```markdown
---
inclusion: always
---

# 文件标题
内容...
```

```markdown
---
inclusion: fileMatch
fileMatchPattern: "src/**/*.py,tests/**/*.py"
---

# Python 代码规范
内容...
```

```markdown
---
inclusion: manual
---

# 踩坑经验库
内容...
```

### 2.2 always 文件（严格控制 3 个）

always 文件每次对话都消耗 Token，必须精简。推荐只保留 3 个：

#### ① core-rules.md — 核心工作规则

```markdown
---
inclusion: always
---

# 核心工作规则

## 工作流程

### 用户说"开始"前
- 只能提问、确认、列计划
- 分析任务，确认方向
- 列出预计改动的文件

### 用户说"开始"后
- 执行代码修改
- 每改一个文件，验证后再继续
- 完成后更新 session-status.md

## 🚨 红线（违反即失败）

- ❌ 用户没说"开始"就改代码
- ❌ 命令失败后自动尝试其他方法（先问用户）
- ❌ 用 workaround 绕过问题
- ❌ 写假测试（`assert True`）
- ❌ 空的 except / catch 块
- ❌ 硬编码 API Key
- ❌ 不确定就瞎改

## 🔥 高频踩坑速查（详见 #lessons-learned）

| 坑 | 解决 |
|----|------|
| （填入你项目的高频问题） | （填入解决方案） |

## ⚡ 关键规则（触发条件 → 必须执行）

| 触发条件 | 必须执行 |
|---------|---------|
| bug/修复/fix/报错 | Bug 修复四步法：复现 → 查踩坑库 → 最小改动 → 验证 |
| 涉及 3+ 文件 | 先用 context-gatherer 子代理了解全局 |
| 新功能/实现 | 问用户是否要 TDD |
| 复杂/重构 | 先列计划，分步执行 |
| 代码修改完成 | getDiagnostics 检查 |
| 反复失败 2+ 次 | 查 `#lessons-learned` → 无果则换思路 |
| 新方案实施前 | 先写最小 PoC 验证，不改主代码 |

## 任务完成后（由 Hook 自动辅助）

1. **验证**：运行 getDiagnostics 或测试
2. **更新**：session-status.md 记录进度
3. **总结**：简洁说明做了什么（3-5行）

## 简单任务例外

以下情况可以直接执行：
- 简单问答 / 单文件小修改 / 用户明确说"直接改" / 查看文件内容

## 📋 项目概述

- 项目：[你的项目名]
- 技术栈：[语言 + 框架]
- 核心功能：[一句话描述]
```

#### ② session-status.md — 项目记忆

这是跨会话记忆的核心。每次新对话自动加载，AI 立即知道项目当前状态。

```markdown
---
inclusion: always
---

# 项目记忆

> 新对话开始时自动加载。

---

## 📌 重要待办（永久保留）

- [ ] 功能A - 描述
- [x] 已完成的功能 ✅

---

## 📋 当前任务

**状态**: [当前进度]
**当前任务**: [正在做什么]

### 最近完成
- ✅ YYYY-MM-DD: [完成了什么]

---

## 🔧 快速参考

**项目**: [项目名]
**技术栈**: [语言 + 框架]
**启动命令**: `[启动命令]`
**测试命令**: `[测试命令]`
**详细上下文**: `#lessons-learned` | `#session-history`

**核心文件**:
| 功能 | 文件 |
|-----|------|
| [功能1] | `path/to/file1` |
| [功能2] | `path/to/file2` |

**已知陷阱（速查）**:
1. [陷阱1] → [解决方案]
2. 详细踩坑清单：`#lessons-learned`

---

## 📝 会话日志（最近5条）

- **YYYY-MM-DD**: [一句话描述本次工作]
```

> 设计要点：
> - 会话日志只保留最近 5 条，历史归档到 manual 模式的 `session-history.md`
> - 待办区域永久保留，完成的打 ✅ 但不删除
> - 快速参考区放最常用的命令和文件路径

#### ③ security.md — 安全规范

```markdown
---
inclusion: always
---

# 安全规范

## 🚨 绝对禁止
1. 硬编码敏感信息（API Key、密码、Token）
2. 敏感信息日志输出
3. 不安全的 CORS 配置（`origin: '*'`）
4. 明文存储密码

## 环境变量管理
- 敏感配置从环境变量或配置文件读取（不提交到 git）
- 配置文件加入 `.gitignore`

## 安全检查清单
- [ ] 无硬编码的密钥/密码
- [ ] 敏感信息使用环境变量
- [ ] 用户输入已验证和清理
- [ ] 文件路径已验证（防止路径遍历）
- [ ] API 响应不包含敏感信息

## 日志安全
- 不要 log 完整的 API Key
- 最多显示前 8 位：`api_key[:8]...`
```

### 2.3 fileMatch 文件（按语言/目录自动加载）

只在打开匹配文件时消耗 Token，适合语言规范、框架规范。

#### 常见 fileMatch 配置

| 文件 | fileMatchPattern | 用途 |
|------|-----------------|------|
| `python-rules.md` | `**/*.py` | Python 代码规范 |
| `typescript-rules.md` | `**/*.ts,**/*.tsx` | TypeScript 规范 |
| `frontend-rules.md` | `client/**/*.ts,client/**/*.tsx,client/**/*.css` | 前端规范 |
| `backend-rules.md` | `server/**/*.ts,api/**/*.ts` | 后端规范 |
| `test-rules.md` | `tests/**/*,**/*.test.*,**/*.spec.*` | 测试规范 |
| `ui-rules.md` | `src/ui/**/*.py` | UI 框架规范（如 PyQt6） |
| `design-agent.md` | `design_agent/**/*.py` | 特定模块规范 |

#### fileMatch 模板

```markdown
---
inclusion: fileMatch
fileMatchPattern: "**/*.py"
---

# Python 代码规范

## 类型提示
- 所有函数必须有类型提示
- 使用 `Optional[]` 处理可空值

## 错误处理
- 捕获具体异常，不要用裸 `except:`
- 记录错误日志

## 代码风格
- 函数不超过 50 行
- 必须有 docstring
```

### 2.4 manual 文件（按需 `#引用` 加载）

内容会持续增长或不常用的文件，全部设为 manual。

#### 推荐的 manual 文件

| 文件 | 用途 | 引用方式 |
|------|------|---------|
| `lessons-learned.md` | 踩坑经验库（Hook 自动写入） | `#lessons-learned` |
| `session-history.md` | 项目历史归档 | `#session-history` |
| `project-structure.md` | 项目文件结构说明 | `#project-structure` |
| `api-keys.md` | API 密钥汇总（不含明文） | `#api-keys` |
| `troubleshooting.md` | 已知问题和解决方案 | `#troubleshooting` |
| `tdd.md` | TDD 工作流 | `#tdd` |
| `knowledge-base-guide.md` | Knowledge Base 使用指南 | `#knowledge-base-guide` |

#### 踩坑经验库模板（lessons-learned.md）

```markdown
---
inclusion: manual
---

# 踩坑经验库

> 由 Hook 自动写入，手动用 `#lessons-learned` 引用
> 核心规则：反复失败 2+ 次必须查此文件

---

## [分类1]（如：前端 / Python / API）

| 问题简述 | 根因 | 解决方案 |
|---------|------|---------|
| 示例问题 | 示例根因 | 示例方案 |

## [分类2]

| 问题简述 | 根因 | 解决方案 |
|---------|------|---------|
```

> 分类建议按技术栈划分：前端 / 后端 / API / 测试 / 配置环境 / 打包部署

### 2.5 Skills 文件（技能手册）

Skills 放在 `.kiro/steering/skills/` 目录，可以是 fileMatch 或 manual 模式。

#### 推荐的 Skills

| 文件 | 模式 | 用途 |
|------|------|------|
| `api-integration.md` | fileMatch（services 目录） | API 集成规范 |
| `error-handling.md` | manual | 错误处理模式 |
| `code-review.md` | manual | 代码审查清单 |
| `plan-execute.md` | manual | 计划-执行分离流程 |
| `spec-driven.md` | manual | Spec 驱动开发 |
| `subagent-orchestration.md` | manual | 子代理编排 |
| `testing.md` | fileMatch（tests 目录） | 测试规范 |

#### Skill 文件引用

Steering 文件支持引用其他文件：
```markdown
详细信息见完整文档：
#[[file:docs/api-reference.md]]
```

这样可以把大型文档（如 OpenAPI spec、GraphQL schema）间接引入，而不是复制内容。

---

## 三、全局规则（Global Rules）

全局规则放在 `~/.kiro/steering/*.md`，对所有项目生效。适合放 AI 行为规范，不绑定任何具体项目。

### 3.1 推荐的全局规则（3 个）

#### ① work-mode.md — 工作模式

控制 AI 的工作流程：先分析 → 确认方向 → 再执行。

```markdown
# 工作模式规则（全局）

## 核心规则：先分析 → 确认方向 → 再执行

收到任何任务后，必须先分析并确认方向，用户确认后才能执行。

### 强制执行的三步流程

第一步：分析任务
→ 复述需求、列出可能方向、列出不清楚的点

第二步：用户确认
→ 用户选择方向或补充信息，说"开始"

第三步：执行任务
→ 开始实际操作

### 什么情况必须先问

| 任务类型 | 必须先问 | 可以直接做 |
|---------|---------|-----------|
| 新功能开发 | ✅ |  |
| Bug 修复 | ✅ |  |
| 代码重构 | ✅ |  |
| 文档更新 | ✅ |  |
| 简单查询 |  | ✅ |
| 解释概念 |  | ✅ |
| 继续之前的任务 |  | ✅ |

### 例外情况（可以直接执行）

1. 用户明确说"直接做"/"不用问"/"开始"
2. 是之前确认过的任务的延续
3. 是简单的信息查询或解释
4. 用户提供了完整的上下文和明确的指令
```

#### ② ai-persona.md — AI 行为规范

定义 AI 的角色、核心原则、禁止行为。

```markdown
# AI 开发助手 - 全局行为规范

## 角色定义
你是一个有 10 年经验的高级全栈工程师。诚实、严谨、注重细节。

## 知识检索优先（核心规则）

> 不确定就查，不要猜。

### 强制检索触发条件

| 触发条件 | 检索来源 |
|---------|---------|
| 涉及具体 API / 方法签名 | 官方文档 / web search |
| 涉及版本号 / 兼容性 | web search / changelog |
| 涉及项目已知坑 | `#lessons-learned` |
| 涉及配置 / 环境变量 | 项目文件 (.env, config) |
| 涉及第三方服务行为 | web search / 官方文档 |
| 不确定语法 / 用法 | web search / Context7 |

### 检索来源优先级

1. lessons-learned.md（项目踩坑库）
2. 项目内文件（现有代码、配置）
3. Context7 / 官方文档
4. Web Search

### 检索行为规范
- 做之前查：先查踩坑库
- 做之中查：遇到不确定立即检索
- 做之后写：发现新坑更新到 lessons-learned.md
- 标注不确定：检索后仍不确定，明确告知用户

## 核心原则
1. 诚实优先 — 不确定就说不确定
2. 完整执行 — 不要只做一半就说完成
3. 验证驱动 — 改完代码要验证
4. 自我纠错 — 发现错误停下来重新评估

## 禁止行为
- 凭记忆写 API 调用不查文档
- 编造不存在的方法、参数、配置项
- 写假测试（assert True）
- 反复尝试同一个失败方法超过 2 次
- 说"基本完成"这种模糊描述

## 沟通风格
- 简洁直接，不要啰嗦
- 不确定时说"我认为"而不是断言
- 不要道歉，直接修复问题

## 上下文管理
- 新对话开始时先检查 session-status.md
- 长对话时定期总结当前状态
- 重要信息写入文件保存
```

#### ③ self-reflection.md — 自我反思

任务完成后的验证和经验沉淀机制。

```markdown
# 自我反思与验证规则

> 全局规则：每次任务完成后强制执行。

## 任务完成检查（由 Hook 自动执行）

> 验证清单已由 task-completion-pipeline Hook 确定性执行，无需手动重复。

## 常见遗漏模式

| 场景 | 容易遗漏 | 检查方法 |
|------|---------|---------|
| 修改后端 API | 前端调用、类型定义 | 搜索 API 路径的引用 |
| 修改数据结构 | 序列化/反序列化、测试数据 | 搜索类型名的引用 |
| 添加依赖 | package.json / requirements.txt | 检查 import 来源 |
| 修改配置 | 环境变量、部署脚本 | 检查 .env 和 docker |
| 使用不熟悉的 API | 参数格式、返回值结构 | 查官方文档确认 |

## 反模式警告

如果发现自己在做以下事情，立即停下来：
1. 反复修复同一个问题 → 换思路
2. 只关注报错信息不看整体 → 退一步看全局
3. 假设"应该没问题" → 实际验证
4. 急于说"完成了" → 先跑验证清单
5. 凭记忆写 API 调用 → 先查文档

## 经验沉淀

反思中发现的教训，沉淀到 lessons-learned.md：
- Bug 修复花了 2+ 轮才搞定 → 必须记录
- 发现文档没提到的坑 → 必须记录
- API 行为与预期不符 → 必须记录
- 一次就修好的简单 Bug → 不用记录
```

### 3.2 全局规则 vs 工作区规则

| 对比项 | 全局规则 | 工作区规则 |
|--------|---------|-----------|
| 位置 | `~/.kiro/steering/` | `.kiro/steering/` |
| 作用域 | 所有项目 | 当前项目 |
| 适合放 | AI 行为规范、工作模式 | 项目规则、安全规范、踩坑库 |
| 冲突时 | 被工作区覆盖 | 优先生效 |

> 原则：全局放"怎么工作"，工作区放"这个项目怎么做"。

---

## 四、Agent Hooks 配置

### 4.1 Hook 基础

Hook 文件放在 `.kiro/hooks/` 目录，格式为 JSON（`.json` 扩展名）。

#### 触发类型

| 类型 | 触发条件 | 适用场景 |
|-----|---------|---------|
| `fileEdited` | 文件保存时 | Lint 检查、测试运行 |
| `fileCreated` | 文件创建时 | 自动添加文件头 |
| `fileDeleted` | 文件删除时 | 清理相关文件 |
| `userTriggered` | 手动点击按钮 | Commit 消息、代码审查 |
| `promptSubmit` | 提交 prompt 时 | 条件检查、上下文增强 |
| `agentStop` | Agent 完成时 | 自动总结、安全扫描 |
| `preToolUse` | 工具执行前 | 权限控制、写操作拦截 |
| `postToolUse` | 工具执行后 | 结果审查、日志记录 |

#### 动作类型

| 动作 | 说明 | 适用触发类型 |
|-----|------|-------------|
| `askAgent` | 让 AI 执行任务 | 所有类型 |
| `runCommand` | 运行 shell 命令 | `promptSubmit`, `agentStop`, `preToolUse`, `postToolUse` |

### 4.2 推荐 Hook 配置（5 个）

#### ① task-completion-pipeline.json — 任务完成 Pipeline（核心）

将安全扫描、模式识别、日志记录、session 更新合并为一个 Hook，避免多个 agentStop Hook 互相干扰。

```json
{
  "name": "Task Completion Pipeline",
  "version": "4.0.0",
  "description": "任务完成后统一执行：安全扫描 + 模式识别 + 日志记录 + session 更新",
  "when": {
    "type": "agentStop"
  },
  "then": {
    "type": "askAgent",
    "prompt": "任务完成 Pipeline（仅在本次任务有实质性工作时执行，纯闲聊/简单问答跳过）：\n\n1️⃣ 安全扫描（仅代码修改时）：\n   - 硬编码密钥、敏感信息、不安全配置\n   - getDiagnostics 检查修改过的文件\n\n2️⃣ 模式识别（仅出现错误/失败时）：\n   - 检测条件：同一问题修了2+次、命令失败、API参数错误\n   - 如果检测到：追加一行到 .kiro/steering/lessons-learned.md\n   - 格式：| 问题简述 | 根因 | 解决方案 |\n\n3️⃣ 日志记录（有实质工作就记录）：\n   - 写入 .kiro/daily-log/YYYY-MM-DD.md（用今天日期）\n   - 如果文件不存在，创建并添加表头：| 时间 | 类型 | 任务摘要 | 修改文件/备注 |\n   - 追加一行：| HH:MM | 类型 | 一句话摘要 | 文件/备注 |\n\n4️⃣ Session 更新（有重要进展时）：\n   - 更新 .kiro/steering/session-status.md 的会话日志\n\n没有问题则静默通过，发现问题简要提醒但不自动修改。"
  }
}
```

> 设计要点：
> - 合并优于拆分：之前用 3 个独立 agentStop Hook（post-task-check + pattern-recognition + daily-review），实践证明合并为 1 个更稳定
> - 条件执行：prompt 中写明"仅在 XX 时执行，否则跳过"，避免简单问答也触发
> - 静默通过：没问题时不输出，减少噪音

#### ② write-guard.json — 写入拦截（安全网）

防止 AI 在用户未确认时就修改代码，配合 core-rules 的"开始"机制。

```json
{
  "name": "Write Guard",
  "version": "1.0.0",
  "description": "代码修改前检查：是否已获得用户确认",
  "when": {
    "type": "preToolUse",
    "toolTypes": ["write"]
  },
  "then": {
    "type": "askAgent",
    "prompt": "写入拦截检查：\n检查本次对话中用户是否已说过「开始」「直接做」「直接改」「不用问」等确认词。\n\n例外情况（允许直接写入）：\n- 写入的是文档/笔记/日志文件（.md, .log, .txt）\n- 写入的是 session-status.md 或 daily-log\n- 写入的是 lessons-learned.md\n- 用户明确提供了完整指令和上下文\n\n如果不满足例外条件且用户未确认：\n回复「⚠️ 检测到代码修改操作，但用户尚未确认。请先确认方向后说"开始"。」\n并拒绝本次写入。"
  }
}
```

> 这是 preToolUse Hook 的典型用法：拦截写操作，确保流程合规。

#### ③ test-on-save.json — 保存时检查

保存代码文件后自动检查语法错误和安全问题。

```json
{
  "name": "Code Check on Save",
  "version": "2.0.0",
  "description": "保存代码文件后自动检查语法错误和安全问题",
  "when": {
    "type": "fileEdited",
    "patterns": ["**/*.py"]
  },
  "then": {
    "type": "askAgent",
    "prompt": "检查刚保存的文件：\n1. 使用 getDiagnostics 检查语法/类型错误\n2. 扫描是否有硬编码的 API Key 或敏感信息\n3. 如果是测试文件，运行该测试\n\n只在发现问题时输出，无问题则静默通过。"
  }
}
```

> 根据你的技术栈调整 `patterns`：
> - Python: `["**/*.py"]`
> - TypeScript: `["**/*.ts", "**/*.tsx"]`
> - 全栈: `["**/*.ts", "**/*.tsx", "**/*.py"]`

#### ④ commit-message.json — 生成提交消息

手动触发，根据 git diff 自动生成规范的提交消息。

```json
{
  "name": "Generate Commit Message",
  "version": "1.0.0",
  "description": "手动触发，根据 git diff 生成 Conventional Commit 格式的提交消息",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "分析当前 git diff，生成 Conventional Commit 格式的提交消息。格式：type(scope): description。类型包括：feat, fix, docs, style, refactor, test, chore。用中文描述，保持简洁。"
  }
}
```

#### ⑤ code-quality.json — 手动代码质量检查

手动触发，运行完整的代码质量分析。

```json
{
  "name": "Code Quality Check",
  "version": "1.0.0",
  "description": "手动触发完整代码质量检查",
  "when": {
    "type": "userTriggered"
  },
  "then": {
    "type": "askAgent",
    "prompt": "运行完整代码质量检查：\n1. 使用 getDiagnostics 检查所有代码文件的类型错误\n2. 检查是否有未使用的导入\n3. 检查是否有过长的函数（>50行）\n\n只报告问题，不自动修复。"
  }
}
```

### 4.3 Hook 设计原则

| 原则 | 说明 |
|------|------|
| agentStop 合并为 1 个 | 多个 agentStop Hook 容易互相干扰，合并为 pipeline 更稳定 |
| 条件执行 | prompt 中写明"仅在 XX 时执行，否则跳过"，避免无意义消耗 |
| 静默通过 | 没问题时不输出，减少噪音 |
| preToolUse 做拦截 | write-guard 拦截未确认的写操作，是安全网 |
| userTriggered 做手动任务 | commit-message、code-quality 等不需要自动触发的任务 |

### 4.4 日清复盘日志

task-completion-pipeline 会自动写入 `.kiro/daily-log/YYYY-MM-DD.md`：

```markdown
# 日清复盘 2026-02-17

| 时间 | 类型 | 任务 | 修改文件/备注 |
|------|------|------|---------------|
| 14:30 | 代码 | 修复登录验证逻辑 | auth.py, login.py |
| 16:00 | 分析 | 对比缓存方案 | Redis vs Memcached |
```

> 类型可选：`代码` `分析` `决策` `Bug发现` `调研` `重构` `配置`

---

## 五、Kiro Powers

### 5.1 什么是 Powers

Powers 将 MCP 服务器 + Steering 文件 + Hooks 打包成按需激活的单元，解决 MCP context 爆炸问题。

| 对比项 | 传统 MCP（settings/mcp.json） | Kiro Powers |
|--------|-------------------------------|-------------|
| 加载时机 | 启动时全部加载 | 按关键词激活 |
| Context 占用 | 始终占用 | 用时才占用 |
| 切换成本 | 需手动启用/禁用 | 自动切换 |

### 5.2 Power 目录结构

```
.kiro/powers/
└── my-power/
    ├── POWER.md      # 核心：定义关键词、行为规则、工具说明
    ├── mcp.json      # 可选：MCP 服务器配置
    ├── steering/     # 可选：额外 steering 文件
    └── hooks/        # 可选：额外 hooks
```

### 5.3 POWER.md 模板

```markdown
---
name: my-power
displayName: 我的 Power
description: 一句话描述这个 Power 做什么
keywords:
  - 关键词1
  - 关键词2
  - keyword-en
mcpServers:
  - server-name
---

# Power: [名称]

## Purpose
[一段话描述用途]

## Activation signals
- Keywords: [关键词列表]
- Typical prompts: "[典型用户输入]"

## Core Files
- `path/to/core/file1` - 说明
- `path/to/core/file2` - 说明

## Agent behavior
### Do:
- [应该做的事]
### Don't:
- [不应该做的事]

## Common issues
| 问题 | 原因 | 解决 |
|------|------|------|
| [问题] | [原因] | [解决] |
```

### 5.4 Power 设计示例

#### 纯 Steering Power（无 MCP）

适合为特定功能模块提供上下文和规则，不需要额外工具。

```
.kiro/powers/
├── ai-image-gen/          # AI 图片生成
│   └── POWER.md           # keywords: 生图、图片生成、AI图片、提示词
├── product-scraper/       # 产品爬虫
│   └── POWER.md           # keywords: 爬虫、爬取、1688、商品
└── erp-export/            # ERP 导出
    └── POWER.md           # keywords: 导出、ERP、excel、模板
```

#### 带 MCP 的 Power

适合需要额外工具能力的场景。

```
.kiro/powers/
└── file-tools/
    ├── POWER.md           # keywords: 文件、excel、word、pdf
    └── mcp.json           # filesystem MCP 服务器
```

mcp.json 示例：
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."],
      "disabled": false,
      "autoApprove": ["read_file", "list_directory", "directory_tree"]
    }
  }
}
```

### 5.5 常见 Power 场景

| Power | 关键词 | MCP | 用途 |
|-------|--------|-----|------|
| 文件工具 | 文件、excel、word、pdf | filesystem | 文件系统操作 |
| 浏览器自动化 | playwright、浏览器、e2e | playwright | 浏览器测试/爬虫 |
| 代码质量 | sonar、lint、依赖 | sonarqube | 代码分析 |
| 数据库 | sql、数据库、查询 | database | 数据库操作 |
| AI 图片生成 | 生图、图片、提示词 | — | 图片生成指导 |
| 爬虫 | 爬取、抓取、scrape | — | 爬虫开发指导 |

### 5.6 激活方式

自动激活：在对话中提到关键词即可
```
用户：帮我读取这个 Excel 文件
→ file-tools Power 自动激活，filesystem MCP 加载
```

手动激活：在 Kiro Powers 面板中点击

---

## 六、MCP 配置

### 6.1 配置层级

| 层级 | 位置 | 说明 |
|------|------|------|
| 用户级 | `~/.kiro/settings/mcp.json` | 全局，所有项目共享 |
| 工作区级 | `.kiro/settings/mcp.json` | 当前项目专用 |
| Power 级 | `.kiro/powers/*/mcp.json` | 按需激活 |

优先级：Power > 工作区 > 用户级

### 6.2 推荐策略

| 策略 | 说明 |
|------|------|
| 全局 MCP 尽量少 | 只放真正每个项目都用的（如 context7） |
| 项目专用放工作区 | 项目特有的 MCP 放 `.kiro/settings/mcp.json` |
| 不常用放 Power | 按需激活，不占用常驻 context |

### 6.3 配置模板

```jsonc
// .kiro/settings/mcp.json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "disabled": false,
      "autoApprove": ["resolve-library-id", "query-docs"]
    }
  }
}
```

### 6.4 常用 MCP 服务器

| 服务器 | 命令 | 用途 | 建议位置 |
|--------|------|------|---------|
| context7 | `npx -y @upstash/context7-mcp@latest` | 库文档查询 | 用户级 |
| github | `npx -y @modelcontextprotocol/server-github` | GitHub 操作 | 用户级 |
| markitdown | `uvx markitdown-mcp` | 读取 Word/Excel/PDF | Power |
| filesystem | `npx -y @modelcontextprotocol/server-filesystem .` | 文件系统操作 | Power |
| playwright | `npx @playwright/mcp@latest` | 浏览器自动化 | Power |

> 注意：`uvx` 需要先安装 `uv`（Python 包管理器）。安装方式见 [uv 官方文档](https://docs.astral.sh/uv/getting-started/installation/)。

### 6.5 autoApprove

`autoApprove` 列出不需要用户确认的工具名，减少交互中断：

```json
{
  "autoApprove": ["resolve-library-id", "query-docs", "read_file"]
}
```

> 只对只读操作开启 autoApprove，写操作保持手动确认。

---

## 七、子代理配置

### 7.1 什么是子代理

子代理是 Kiro 内置的 `context-gatherer` 和自定义代理，用于将复杂任务拆分给专门的执行者。

### 7.2 内置子代理

| 子代理 | 用途 | 触发条件 |
|--------|------|---------|
| `context-gatherer` | 分析仓库结构，识别相关文件 | 涉及 3+ 文件、不熟悉的代码区域 |
| `general-task-execution` | 通用任务执行 | 需要并行处理的独立子任务 |
| `custom-agent-creator` | 创建自定义代理 | 需要定义新的专用代理 |

### 7.3 自定义子代理（可选）

如果项目需要专门的子代理，可以在 `.kiro/agents/` 目录定义：

```
.kiro/agents/
├── frontend-dev.md      # 前端开发代理
├── backend-dev.md       # 后端开发代理
├── code-reviewer.md     # 代码审查代理
└── test-writer.md       # 测试编写代理
```

子代理行为模板放在 `.kiro/steering/agents/` 目录。

> 子代理是可选配置。小型项目不需要，中大型项目按需添加。

---

## 八、Specs 功能规格

### 8.1 什么是 Specs

Specs 是 Kiro 的结构化功能开发流程，包含需求 → 设计 → 任务三件套。

### 8.2 Spec 目录结构

```
.kiro/specs/
└── feature-name/
    ├── requirements.md    # 需求文档
    ├── design.md          # 设计文档
    └── tasks.md           # 实现任务清单
```

### 8.3 使用场景

| 场景 | 是否使用 Spec |
|------|-------------|
| 简单 bug 修复 | ❌ 直接修 |
| 新功能开发 | ✅ 先写 Spec |
| 复杂重构 | ✅ 明确目标 |
| API 设计 | ✅ 前后端对齐 |

### 8.4 Spec 中引用外部文件

Spec 文件支持引用其他文件，方便关联 API 文档、设计稿等：

```markdown
## 参考文档
#[[file:docs/api-spec.yaml]]
#[[file:docs/design-mockup.md]]
```

---

## 九、完整目录结构模板

```
.kiro/
├── hooks/                            # Agent Hooks
│   ├── task-completion-pipeline.json  # agentStop - 合并 Pipeline
│   ├── write-guard.json              # preToolUse - 写入拦截
│   ├── test-on-save.json             # fileEdited - 保存时检查
│   ├── commit-message.json           # userTriggered - 生成提交消息
│   └── code-quality.json             # userTriggered - 代码质量检查
│
├── powers/                           # Kiro Powers（按需激活）
│   ├── your-power-1/
│   │   ├── POWER.md                  # keywords 定义
│   │   └── mcp.json                  # 可选：MCP 服务器
│   └── your-power-2/
│       └── POWER.md
│
├── settings/
│   └── mcp.json                      # 工作区 MCP 配置
│
├── specs/                            # 功能规格（按需创建）
│   └── feature-name/
│       ├── requirements.md
│       ├── design.md
│       └── tasks.md
│
├── daily-log/                        # 日清复盘日志（Hook 自动生成）
│   └── YYYY-MM-DD.md
│
├── steering/                         # Steering 文件
│   ├── core-rules.md                 # always - 核心工作规则
│   ├── session-status.md             # always - 项目记忆
│   ├── security.md                   # always - 安全规范
│   ├── [language]-rules.md           # fileMatch - 语言规范
│   ├── lessons-learned.md            # manual - 踩坑经验库
│   ├── session-history.md            # manual - 项目历史归档
│   ├── project-structure.md          # manual - 项目文件结构
│   ├── troubleshooting.md            # manual - 已知问题
│   ├── tdd.md                        # fileMatch/manual - TDD 工作流
│   └── skills/                       # 技能文件
│       ├── api-integration.md        # fileMatch - API 集成规范
│       ├── error-handling.md         # manual - 错误处理模式
│       ├── code-review.md            # manual - 代码审查清单
│       ├── plan-execute.md           # manual - 计划-执行分离
│       ├── testing.md                # fileMatch - 测试规范
│       └── ...
│
└── agents/                           # 可选：自定义子代理
    └── ...

# 全局规则（用户级，所有项目共享）
~/.kiro/steering/
├── work-mode.md                      # 工作模式（先分析再执行）
├── ai-persona.md                     # AI 行为规范
└── self-reflection.md                # 自我反思与验证
```

---

## 十、快速启动清单

拿到一个新项目，按以下顺序配置：

### Step 1：创建基础目录

```
.kiro/
├── hooks/
├── powers/
├── settings/
├── steering/
│   └── skills/
└── daily-log/
```

### Step 2：配置 3 个 always 文件

1. `.kiro/steering/core-rules.md` — 复制模板，填入项目信息
2. `.kiro/steering/session-status.md` — 复制模板，填入待办和快速参考
3. `.kiro/steering/security.md` — 复制模板，根据项目调整

### Step 3：配置 5 个 Hooks

1. `task-completion-pipeline.json` — 直接复制，通用
2. `write-guard.json` — 直接复制，通用
3. `test-on-save.json` — 调整 `patterns` 匹配你的语言
4. `commit-message.json` — 直接复制，通用
5. `code-quality.json` — 调整 prompt 匹配你的技术栈

### Step 4：配置全局规则（首次使用 Kiro 时）

在 `~/.kiro/steering/` 创建 3 个文件：
1. `work-mode.md` — 工作模式
2. `ai-persona.md` — AI 行为规范
3. `self-reflection.md` — 自我反思

> 全局规则只需配置一次，所有项目共享。

### Step 5：按需添加

- fileMatch 文件：根据技术栈添加语言规范
- manual 文件：创建 `lessons-learned.md` 踩坑库
- Powers：根据项目需要创建
- Skills：根据团队规范添加
- MCP：根据需要的工具添加

### 配置优先级

```
P0（必须）：3 个 always + task-completion-pipeline + write-guard
P1（推荐）：test-on-save + commit-message + code-quality + lessons-learned
P2（按需）：fileMatch 规范 + Powers + Skills
P3（可选）：子代理 + Specs + 额外 MCP
```

---

## 十一、常见问题

### Q: Hook 没有触发？
A: 检查 `patterns` 是否匹配你的文件路径，使用 glob 语法（如 `**/*.py`）。Hook 文件必须是有效 JSON 格式。

### Q: Steering 文件没有加载？
A: 检查 front matter 格式是否正确，`---` 必须在文件最开头，`inclusion` 值必须是 `always`、`fileMatch` 或 `manual` 之一。

### Q: Power 没有激活？
A: 检查 POWER.md 中的 keywords 是否包含你提到的关键词。关键词越多越容易被激活。

### Q: MCP 服务器连接失败？
A:
1. 检查环境变量是否配置（如 `GITHUB_TOKEN`）
2. 检查 uvx/npx 是否安装
3. 在 Kiro MCP 面板查看日志
4. Powers 中的 MCP 需要 Power 激活后才会连接

### Q: manual 模式如何引用？
A: 在对话中输入 `#文件名`（不含 .md 后缀），如 `#lessons-learned`、`#troubleshooting`。

### Q: 为什么 agentStop Hook 要合并为 1 个？
A: 多个 agentStop Hook 会依次触发，每个都消耗一轮 AI 交互。合并为 pipeline 后只触发一次，在一个 prompt 中完成所有检查，更高效也更稳定。

### Q: write-guard 会不会太严格？
A: prompt 中定义了例外情况（文档、日志、session 文件可以直接写入），不会影响正常的自动化流程。只拦截未确认的代码修改。

### Q: 踩坑库怎么自动更新？
A: task-completion-pipeline Hook 在每次任务完成后自动检测反复错误，发现新模式时追加到 `lessons-learned.md`。core-rules 中配置了"反复失败 2+ 次必须查踩坑库"，形成闭环。

### Q: 全局规则和工作区规则冲突怎么办？
A: 工作区规则优先。如果全局 ai-persona 说"函数不超过 50 行"，工作区 core-rules 说"函数不超过 30 行"，以 30 行为准。

---

## 十二、效果预估

| 优化项 | 预期效果 |
|-------|---------|
| 只保留 3 个 always 文件 | 节省 70%+ 的 always Token 消耗 |
| Skills 全部 manual/fileMatch | 技能文件不再默认加载 |
| Powers 按需加载 MCP | 节省 80%+ MCP context |
| fileMatch 条件加载 | 不同语言规范互不干扰 |
| task-completion-pipeline 合并 | 1 个 Hook 替代 3 个，减少触发次数 |
| write-guard 拦截 | 防止未确认的代码修改 |
| 踩坑库闭环 | 减少重复踩坑，经验自动积累 |
| 全局规则分离 | AI 行为规范跨项目复用 |

---

*本手册为通用配置指南，适用于任何技术栈的项目。*
*根据你的项目需求调整模板中的占位符即可使用。*
*最后更新：2026-02-17*
