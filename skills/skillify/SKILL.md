---
name: skillify
description: >
  Capture a repeatable workflow from the current conversation into a portable SKILL.md file.
  Analyzes conversation history, git artifacts, and tool usage to reconstruct context,
  then interviews the user and generates a complete skill definition.
  Use when the user wants to turn a session into a reusable skill, automate a repeated process,
  or save a workflow for later. Trigger phrases: 'skillify', 'turn this into a skill',
  'save this as a skill', 'make a skill from this', 'capture this workflow'.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(mkdir:*)
  - AskUserQuestion
argument-hint: "[description of the process to capture]"
arguments:
  - description
---

# Skillify

Capture a repeatable workflow from the current conversation into a reusable SKILL.md file.

This skill supports two modes:
- **Retrospective**: `/skillify [description]` — analyze the full conversation
- **Real-time recording**: `/skillify-start` → work → `/skillify` — analyze only from the marker

## Inputs

- `$description` (optional): A short description of the process to capture. If omitted, the skill infers it from conversation analysis.

## How Recording Mode Works

When invoked as `/skillify-start`, do NOT run the full workflow. Instead:
1. Acknowledge that recording mode is now active
2. Output a clear marker: `[SKILLIFY RECORDING STARTED]`
3. Tell the user to continue their work and call `/skillify` when done

When `/skillify` is called after a `/skillify-start` marker exists in the conversation, focus analysis only on messages after that marker.

---

## Phase 0: Context Reconstruction

Before asking any questions, silently analyze the conversation to build a complete picture of what happened.

### Step 1. Analyze Conversation History

Scan all messages (or post-marker messages in recording mode):

**From user messages, extract:**
- Intent and requirements — what they wanted to accomplish
- Correction events — places where the user steered you differently ("no, not that", "change it to...", "actually..."). These are critical: they reveal implicit rules the skill must encode.
- Input parameters — values the user provided that would vary across invocations (file paths, URLs, branch names, config values)

**From assistant messages, extract:**
- Tool calls in execution order — this becomes the skeleton of the skill's steps
- Tool types used — this informs the `allowed-tools` field
- Decision points — where the assistant chose between approaches
- Error recovery — how failures were handled

### Step 2. Collect Auxiliary Context (conditional)

Only collect what is available and relevant:

**Git artifacts** (if `.git` exists):
```bash
git diff --stat   # Changed files summary
git log --oneline -10   # Recent commits
```
Use this to understand what was produced, not just what was discussed.

**File operations**: If files were created or modified, note the patterns (file types, directory conventions, naming).

**External calls**: If WebFetch or curl was used, note URL patterns, authentication methods, request/response structures.

### Step 3. Detect Work Type

Classify the work based on what actually happened in the conversation, not just what files exist in the project:

| Signal | Work Type | Template |
|--------|-----------|----------|
| Java/Kotlin file creation, pom.xml/build.gradle edits, Spring annotations | Spring/Java Development | `references/templates/spring-java.md` |
| .ts/.js file work, package.json edits, npm/yarn commands | Node.js Development | `references/templates/nodejs.md` |
| .py file work, pip/poetry commands, requirements.txt | Python Development | `references/templates/python.md` |
| Dockerfile, CI/CD configs, shell scripts, infra-as-code | DevOps/Infrastructure | `references/templates/devops.md` |
| Repeated WebFetch/curl, JSON processing, API endpoints | API Automation | `references/templates/api-automation.md` |
| Document reading, summarization, format conversion | Document Processing | `references/templates/document-processing.md` |
| None of the above | General | `references/templates/general.md` |

If multiple types match, load all relevant templates. If no type matches, use the general template.

Read the detected template file(s) to inform Phase 2 — templates contain domain-specific patterns, common tool permissions, and best practices that help generate higher-quality skills.

---

## Phase 1: Structured Interview (4 Rounds)

Use AskUserQuestion for ALL questions. Never ask questions via plain text. The user always has a freeform option to type edits — do not add your own "needs tweaking" option.

### Round 1: High-Level Confirmation

Based on Phase 0 analysis, present:
- Suggested **skill name** and **one-line description**
- **Goal(s)**: what the skill achieves
- **Success artifacts**: concrete proof of completion (e.g., "an open PR with CI passing", "a formatted CSV saved to disk", "API responses logged to output file")

Ask the user to confirm or revise.

### Round 2: Structure and Options

- Present identified **steps as a numbered list** — tell the user you will dig into detail in Round 3
- Suggest **arguments** based on observed variable inputs (file paths, URLs, branch names, config values)
- Recommend **execution context**:
  - `inline` — when mid-process user input or judgment is needed
  - `fork` — when the task is self-contained and can run autonomously
  - Explain the tradeoff so the user can choose
- Ask **save location**:
  - **This project** (`.claude/skills/<name>/SKILL.md`) — for project-specific workflows
  - **Personal** (`~/.claude/skills/<name>/SKILL.md`) — for cross-project reuse

### Round 3: Step-by-Step Detail

For each major step, ask:
- **Success criteria**: What proves this step is done? (Required for every step)
- **Artifacts**: What data/files does this step produce that later steps need?
- **Human checkpoint**: Should the user confirm before proceeding? (especially for irreversible actions: merge, deploy, send messages, delete files)
- **Parallel potential**: Can any steps run concurrently? (independent steps become 3a, 3b)
- **Execution method**: Direct (default), Task agent, Teammate, or [human]
- **Hard rules**: Constraints that must always hold — pay special attention to correction events from Phase 0

If there are 3 or fewer steps, ask about all of them in one round. If more than 3, break into multiple rounds (one per step or logical group).

### Round 4: Triggers and Edge Cases

- **When to invoke**: Confirm trigger conditions and suggest example phrases (e.g., "Use when the user wants to create a new Spring Batch job. Examples: 'create batch job', 'new scheduled task', 'batch processing'")
- **Edge cases**: What happens on failure? What are sensible defaults for missing inputs? Can the skill resume from a partial run?
- **Domain confirmation**: "I detected this as a [Spring/Java] workflow — does that match?"

Stop interviewing once you have enough information. Do not over-ask for simple processes.

---

## Phase 2: Generate SKILL.md

Combine interview results with domain template knowledge to produce the skill file.

### Frontmatter

```yaml
---
name: <lowercase-hyphenated, max 64 chars>
description: >
  <What the skill does. Start trigger info with "Use when..." and include
  example trigger phrases. Keep under 1024 chars. Be slightly "pushy" in
  description to encourage triggering — skills tend to under-trigger.>
allowed-tools:
  - <Granular tool patterns from Phase 0 analysis>
  - <e.g., Bash(./gradlew:*), Bash(gh:*), not blanket Bash>
argument-hint: "<placeholder showing expected arguments>"
arguments:
  - <list of argument names>
context: <fork — only if self-contained; omit for inline>
---
```

### Body Structure

```markdown
# <Skill Title>
<Brief description of what this skill automates>

## Inputs
- `$arg_name`: Description and expected format

## Goal
<Clearly stated goal with specific success artifacts>

## Steps

### 1. Step Name
<Specific, actionable instructions. Include commands when appropriate.>

**Success criteria**: <Required. What proves this step is done.>
```

### Per-Step Annotations (include where relevant)

- **Success criteria** — REQUIRED on every step
- **Execution**: Direct (default), Task agent, Teammate, [human] — only specify if not Direct
- **Artifacts**: Data this step produces for later steps — only if dependencies exist
- **Human checkpoint**: When to pause for user confirmation — for irreversible actions
- **Rules**: Hard constraints from user corrections

### Step Structure Conventions

- Concurrent steps use sub-numbers: `3a`, `3b`
- Steps requiring user action get `[human]` in the title
- Keep simple skills simple — a 2-step skill does not need annotations on every step

### Domain Template Application

Merge relevant patterns from the detected template:
- Build/test commands specific to the domain
- Directory structure conventions
- Tool permissions typical for the domain
- Common pitfalls and warnings

User's actual conversation always takes precedence over template defaults. If the user did something differently than the template suggests, follow the user's approach.

---

## Phase 3: Review and Save

### Step 1. Present for Review

Output the complete SKILL.md as a **yaml code block** so the user can review it with syntax highlighting.

### Step 2. Confirm

Ask using AskUserQuestion: "Does this SKILL.md look good to save?" — keep the question concise, no body field.

If the user requests changes, revise and re-present. Iterate until approved.

### Step 3. Save

Write the file to the location chosen in Round 2:
- Project: `.claude/skills/<name>/SKILL.md`
- Personal: `~/.claude/skills/<name>/SKILL.md`

Create the directory if it does not exist.

### Step 4. Confirm Completion

Tell the user:
- Where the skill was saved (full path)
- How to invoke it: `/<skill-name> [arguments]`
- That they can edit the SKILL.md directly to refine it
- If recording mode was used, note that `[SKILLIFY RECORDING STARTED]` markers in the conversation have no lasting effect

---

## Rules

- All questions to the user MUST use AskUserQuestion — never ask via plain text
- Correction events from the conversation are high-signal — always encode them as Rules in the generated skill
- Generated skills must be self-contained — they must not reference or depend on skillify's templates at runtime
- Respect the agentskills.io naming convention: lowercase, hyphens only, max 64 characters
- Keep generated SKILL.md files focused — if approaching 500 lines, suggest splitting into SKILL.md + references/
- When detecting work type, prioritize what was done over what files exist — a Python script in a Java project means the task was Python-related
