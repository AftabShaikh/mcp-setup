# GitHub Copilot Customization Guide

## Table of Contents

- [Overview](#overview)
- [Instructions](#instructions)
  - [Workspace Instructions](#workspace-instructions)
  - [File-Specific Instructions](#file-specific-instructions)
- [Prompts](#prompts)
- [Agents](#agents)
- [Skills](#skills)
- [MCP Servers](#mcp-servers)
- [Comparison: When to Use What](#comparison-when-to-use-what)
  - [Quick Decision Matrix](#quick-decision-matrix)
  - [Key Differences](#key-differences)
  - [Decision Flowchart](#decision-flowchart)
  - [Common Edge Cases](#common-edge-cases)

---

## Overview

GitHub Copilot in VS Code supports five customization primitives that let you tailor AI behavior to your project, team, and workflow. Each serves a distinct purpose:

| Primitive | One-Line Summary |
|-----------|-----------------|
| **Instructions** | Persistent guidelines that shape how Copilot writes code |
| **Prompts** | Reusable task templates triggered on-demand |
| **Agents** | Custom personas with scoped tools and behaviors |
| **Skills** | On-demand workflows bundled with scripts and assets |
| **MCP Servers** | External tool/data integrations via the Model Context Protocol |

---

## Instructions

Instructions are persistent guidelines that influence how Copilot responds. They come in two flavors: **workspace-level** and **file-specific**.

### Workspace Instructions

Always-on rules that apply to every chat request across the entire workspace. Use these for project-wide coding standards, architecture decisions, and team conventions.

**File types (choose one — not both):**

| File | Location | Purpose |
|------|----------|---------|
| `copilot-instructions.md` | `.github/` | Project-wide standards (recommended, cross-editor) |
| `AGENTS.md` | Root or subfolders | Open standard with monorepo hierarchy support |

**Monorepo hierarchy with `AGENTS.md`:**

The closest file in the directory tree takes precedence, allowing different defaults per area:

```
/AGENTS.md              # Root defaults
/frontend/AGENTS.md     # Frontend-specific (overrides root for frontend/)
/backend/AGENTS.md      # Backend-specific (overrides root for backend/)
```

**Example — `copilot-instructions.md`:**

```markdown
# Project Guidelines

## Code Style
- Use TypeScript strict mode
- Prefer functional components with hooks over class components

## Architecture
- All API calls go through the `src/services/` layer
- State management uses Zustand — no Redux

## Build and Test
- Run tests: `npm test`
- Lint: `npm run lint`
```

**Use cases:**
- Enforcing coding standards across the team
- Declaring architecture decisions ("use Zustand, not Redux")
- Specifying build/test commands the agent should use

---

### File-Specific Instructions

Guidelines loaded on-demand when relevant to the current task, or automatically when files matching a glob pattern are in context.

**Location:** `.github/instructions/*.instructions.md`

**Frontmatter:**

```yaml
---
description: "Use when writing database migrations, schema changes, or data transformations"
applyTo: "**/*.sql"    # Optional: auto-attach for matching files
---
```

**Discovery modes:**

| Mode | Trigger | Best For |
|------|---------|----------|
| **On-demand** | Agent detects task relevance via `description` | Task-based: migrations, refactoring |
| **Explicit** | Files matching `applyTo` glob in context | File-based: language standards, framework rules |
| **Manual** | User selects via `Add Context → Instructions` | Ad-hoc attachment |

**Example — `react-components.instructions.md`:**

```markdown
---
description: "Use when creating or modifying React components. Covers component patterns, prop typing, and testing requirements."
applyTo: "src/components/**/*.tsx"
---
# React Component Standards

- All components must have TypeScript prop interfaces
- Use `React.FC` only for simple stateless components
- Co-locate tests: `Button.tsx` → `Button.test.tsx`
- Use CSS Modules for styling, never inline styles
```

**Use cases:**
- Language or framework-specific rules (e.g., Python docstrings, React patterns)
- Task-specific guidelines (e.g., migration safety checks)
- Folder-scoped conventions (e.g., API layer rules for `src/api/`)

---

## Prompts

Reusable task templates triggered on-demand in chat. A prompt defines a single focused task, optionally with parameterized inputs, a specific model, and tool restrictions.

**Location:** `.github/prompts/*.prompt.md`

**Frontmatter:**

```yaml
---
description: "Generate unit tests for selected code"
agent: "agent"                       # Optional: ask, agent, plan, or custom agent
model: "Claude Sonnet 4 (copilot)"   # Optional: preferred model
tools: [search, read]                # Optional: tool restrictions
argument-hint: "Paste the function"  # Optional: input hint in chat
---
```

**Invocation:**
- Type `/` in chat → select from the list (prompts and skills both appear here)
- Command Palette → `Chat: Run Prompt...`
- Open the `.prompt.md` file → click the play button

**Example — `generate-tests.prompt.md`:**

```markdown
---
description: "Generate comprehensive test cases for the provided code"
agent: "agent"
tools: [read, search]
---
Generate comprehensive test cases for the provided code:

- Include edge cases and error scenarios
- Follow existing test patterns found in the codebase
- Use descriptive test names that explain the expected behavior
- Mock external dependencies
```

**Example — `create-readme.prompt.md`:**

```markdown
---
description: "Create a README from a project specification"
agent: "agent"
argument-hint: "Path to the spec file"
---
Read the specification at the provided path and generate a README.md that includes:

1. Project overview and purpose
2. Installation instructions
3. Usage examples
4. API reference (if applicable)
5. Contributing guidelines
```

**Use cases:**
- Generating test cases for code
- Creating documentation from specs
- Performing one-off code generation tasks (boilerplate, configs)
- Standardizing recurring chat requests across the team

---

## Agents

Custom personas with specific tools, instructions, and behaviors. Agents provide **context isolation** (each runs as a subagent returning a single output) and **role-based tool restrictions**.

**Location:** `.github/agents/*.agent.md`

**Frontmatter:**

```yaml
---
description: "Use when reviewing code for security vulnerabilities and OWASP compliance"
tools: [read, search]               # Minimal tool set for the role
model: "Claude Sonnet 4 (copilot)"  # Optional model preference
user-invocable: true                # Show in agent picker (default: true)
agents: [helper-agent]              # Optional: restrict allowed subagents
---
```

**Tool aliases:**

| Alias | Purpose |
|-------|---------|
| `execute` | Run shell commands |
| `read` | Read file contents |
| `edit` | Edit files |
| `search` | Search files or text |
| `agent` | Invoke other agents as subagents |
| `web` | Fetch URLs and web search |
| `todo` | Manage task lists |

**Invocation:**
- Select from the agent picker dropdown in chat
- Automatically delegated to by a parent agent based on `description` match

**Example — `security-reviewer.agent.md`:**

```markdown
---
description: "Use when reviewing code for security vulnerabilities, OWASP Top 10 issues, and authentication/authorization patterns"
tools: [read, search]
---
You are a security review specialist. Your job is to analyze code for vulnerabilities.

## Constraints
- DO NOT modify any code — only report findings
- DO NOT run any shell commands
- ONLY focus on security-relevant issues

## Approach
1. Scan for OWASP Top 10 patterns (injection, broken auth, XSS, etc.)
2. Check authentication and authorization flows
3. Review data validation at system boundaries
4. Flag hardcoded secrets or credentials

## Output Format
Return a Markdown report with:
- **Critical**: Vulnerabilities that need immediate attention
- **Warning**: Potential issues to investigate
- **Info**: Best-practice suggestions
```

**Example — `db-migrator.agent.md`:**

```markdown
---
description: "Use when creating, reviewing, or running database migrations"
tools: [read, edit, execute]
---
You are a database migration specialist.

## Constraints
- ALWAYS create reversible migrations
- NEVER drop columns without a preceding release that removes code dependencies
- ALWAYS generate both up and down scripts

## Approach
1. Analyze the requested schema change
2. Check existing migration history
3. Generate migration files following project conventions
4. Validate rollback capability
```

**Use cases:**
- Context-isolated subtasks (security review returns a report, not side effects)
- Role-based workflows where different stages need different tool access
- Multi-agent orchestration (parent delegates to specialist subagents)
- Restricting what the AI can do (read-only reviewer, no terminal access)

---

## Skills

On-demand workflows bundled with scripts, templates, and reference docs. Skills are like agents but come with **assets** — executable scripts, boilerplate files, and documentation that the agent loads progressively.

**Location:** `.github/skills/<skill-name>/SKILL.md`

**Folder structure:**

```
.github/skills/webapp-testing/
├── SKILL.md           # Required — must match folder name
├── scripts/           # Executable code the skill invokes
│   └── run-tests.js
├── references/        # Docs loaded as needed
│   └── test-patterns.md
└── assets/            # Templates, boilerplate
    └── test-template.ts
```

**SKILL.md frontmatter:**

```yaml
---
name: webapp-testing
description: 'Test web applications using Playwright. Use for verifying frontend behavior, debugging UI issues, capturing screenshots.'
argument-hint: 'URL or component to test'
---
```

**Progressive loading:**

1. **Discovery** (~100 tokens): Agent reads `name` and `description` only
2. **Instructions** (<5,000 tokens): Loads `SKILL.md` body when relevant
3. **Resources**: Additional files load only when referenced in the body

**Invocation:** Type `/` in chat → select the skill (appears alongside prompts)

**Example — `webapp-testing/SKILL.md`:**

```markdown
---
name: webapp-testing
description: 'Test web applications using Playwright. Use for verifying frontend, debugging UI, capturing screenshots.'
---

# Web Application Testing

## When to Use
- Verify frontend functionality after changes
- Debug UI rendering issues
- Capture screenshots for visual regression

## Procedure
1. Start the web server: `npm run dev`
2. Run [test script](./scripts/run-tests.js) against target URL
3. Review screenshots in `./screenshots/`
4. Report pass/fail status with evidence

## Reference
See [test patterns](./references/test-patterns.md) for assertion examples.
```

**Use cases:**
- Repeatable workflows that need bundled scripts (deploy, test, scaffold)
- Procedures with step-by-step guidance and supporting assets
- Domain knowledge packages (testing strategies, migration playbooks)
- Tasks that benefit from templates and boilerplate generation

---

## MCP Servers

MCP (Model Context Protocol) servers give Copilot **live access to external tools and real-time data**. They are the bridge between the AI and the outside world — APIs, databases, cloud resources, third-party services.

**Configuration:** `.vscode/mcp.json` (workspace) or VS Code user settings (global)

**Example — `.vscode/mcp.json`:**

```json
{
  "servers": {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp-server"],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "${input:subscriptionId}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@github/mcp-server"]
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${input:dbUrl}"
      }
    }
  }
}
```

**How it works:**

1. VS Code starts MCP servers as background processes
2. Copilot discovers available tools from each server via the protocol
3. During a chat, Copilot calls the appropriate MCP tool when relevant
4. Results (live data from Azure, GitHub, databases, etc.) flow back into the conversation context

**Using MCP tools in agents/prompts:**

```yaml
# In an agent or prompt frontmatter
tools: [azure/*, read, search]   # Grant access to all Azure MCP tools
```

**Architecture:**

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   GitHub Copilot │────▶│  MCP Client  │────▶│   MCP Server    │
│   (MCP Host)     │◀────│  (VS Code)   │◀────│  (e.g., Azure)  │
└─────────────────┘     └──────────────┘     └─────────────────┘
                                                      │
                                               ┌──────▼──────┐
                                               │  External    │
                                               │  System      │
                                               │  (API/DB/...)│
                                               └─────────────┘
```

**Use cases:**
- Querying live Azure resources ("list my VMs in production")
- Searching GitHub issues and PRs from chat
- Running database queries against a real connection
- Accessing Terraform registry for latest provider versions
- Any integration where the AI needs **real-time, external data**

---

## Comparison: When to Use What

### Quick Decision Matrix

| Question | Answer → Use |
|----------|-------------|
| Need rules that apply to **every** chat request? | **Workspace Instructions** |
| Need rules only for **specific file types**? | **File Instructions** (`applyTo`) |
| Need a **reusable one-shot task** template? | **Prompt** |
| Need a **specialist persona** with restricted tools? | **Agent** |
| Need a **multi-step workflow** with scripts/templates? | **Skill** |
| Need **live data** from external systems? | **MCP Server** |

### Key Differences

| Aspect | Instructions | Prompts | Agents | Skills | MCP Servers |
|--------|-------------|---------|--------|--------|-------------|
| **Purpose** | Guide behavior | Task template | Persona + tool scope | Workflow + assets | External data/tools |
| **Activation** | Automatic or pattern-matched | On-demand (`/` or play button) | Agent picker or subagent delegation | On-demand (`/` command) | Always available once configured |
| **Scope** | Workspace or file-specific | Single task | Isolated context per invocation | Multi-step procedure | Cross-cutting (any agent/prompt can use) |
| **Has tools?** | No | Optional | Yes (restricted per role) | Inherited from agent | Provides tools to the ecosystem |
| **Has assets?** | No | No | No | Yes (scripts, templates, docs) | N/A (external systems) |
| **File location** | `.github/` or `.github/instructions/` | `.github/prompts/` | `.github/agents/` | `.github/skills/<name>/` | `.vscode/mcp.json` |
| **Shared via VCS?** | Yes | Yes | Yes | Yes | Yes (config), No (credentials) |
| **Deterministic?** | No (guides AI) | No (guides AI) | No (guides AI) | No (guides AI) | Yes (tool calls produce consistent outputs) |

### Decision Flowchart

```
START: What do you need?
│
├─▶ "I want Copilot to always follow certain rules"
│   ├─▶ For ALL files in the project? → Workspace Instructions
│   └─▶ Only for specific file types/folders? → File Instructions (applyTo)
│
├─▶ "I want a reusable task I can trigger in chat"
│   ├─▶ Single focused generation task? → Prompt
│   └─▶ Multi-step procedure with scripts/templates? → Skill
│
├─▶ "I want a specialist with limited capabilities"
│   └─▶ Custom Agent (restrict tools, define persona)
│
└─▶ "I need the AI to access live external data/APIs"
    └─▶ MCP Server
```

### Common Edge Cases

| Confusion | Resolution |
|-----------|-----------|
| **Instructions vs. Skill** | Does it apply to *most* work or *specific* triggered tasks? Most → Instructions. Specific → Skill. |
| **Skill vs. Prompt** | Both appear as `/` commands. Multi-step workflow with bundled scripts/templates → Skill. Single focused task → Prompt. |
| **Skill vs. Agent** | Same capabilities for all steps → Skill. Need context isolation or different tool restrictions per stage → Agent. |
| **Agent vs. Prompt** | Prompt is a single task template anyone triggers. Agent is a persistent persona with tool restrictions, often used as a subagent. |
| **MCP vs. Agent** | MCP provides *tools* (data access). Agents *use* tools (including MCP tools). They are complementary, not competing. |
| **Instructions vs. Prompt** | Instructions are passive (always loaded, shape behavior). Prompts are active (user triggers them for a specific task). |

### Combining Primitives

The real power comes from using these together:

```
┌─────────────────────────────────────────────────────┐
│  Workspace Instructions (copilot-instructions.md)   │  ← Always active
│  "Use TypeScript strict mode, prefer Zustand"       │
├─────────────────────────────────────────────────────┤
│  File Instructions (react.instructions.md)          │  ← Active for *.tsx
│  "Use CSS Modules, co-locate tests"                 │
├─────────────────────────────────────────────────────┤
│  Prompt (/generate-tests)                           │  ← User triggers
│  "Generate tests for this component"                │
│  → Uses agent: security-reviewer                    │
│  → Uses tools: [read, search, playwright/*]         │  ← MCP tools
├─────────────────────────────────────────────────────┤
│  Skill (/deploy-staging)                            │  ← User triggers
│  Runs bundled deploy scripts + validation           │
│  → Calls MCP server for live resource checks        │  ← MCP data
└─────────────────────────────────────────────────────┘
```

**Example workflow:** A developer types `/generate-tests` (prompt) which delegates to a `test-writer` agent (agent) that follows React testing conventions (file instructions) and project-wide TypeScript rules (workspace instructions), using Playwright MCP tools (MCP server) to verify the UI, and runs a bundled test scaffold script (skill).

---

## Summary

| Primitive | Think of it as... | File |
|-----------|-------------------|------|
| **Instructions** | A style guide pinned to the wall | `copilot-instructions.md` / `*.instructions.md` |
| **Prompt** | A form you fill out and submit | `*.prompt.md` |
| **Agent** | A team member with a specific role | `*.agent.md` |
| **Skill** | A runbook in a binder with checklists | `SKILL.md` + folder |
| **MCP Server** | A phone line to the outside world | `mcp.json` |
