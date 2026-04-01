# General Domain Guide

This template is used when no specific domain is detected. It provides universal patterns applicable to any workflow.

## Universal Step Patterns

- **Input validation step**: Verify required inputs exist and are in expected format
- **Execution step**: Perform the core action with clear success/failure criteria
- **Verification step**: Confirm the action produced the expected result
- **Output step**: Present or save results in the agreed format
- **Cleanup step**: Remove temporary files or resources if created

## Tool Selection Guide

Choose the minimal set of tools needed:

| Task | Tools |
|------|-------|
| File reading/editing | Read, Edit, Write |
| File search | Glob, Grep |
| Shell commands | Bash (with specific patterns) |
| Web requests | WebFetch, Bash(curl:*) |
| Subagent work | Agent |

Always prefer granular tool patterns over blanket access:
- `Bash(git:*)` instead of `Bash`
- `Bash(npm:*)` instead of `Bash`

## General Best Practices for Generated Skills

- Every step needs a **success criteria** — "it ran without errors" is a minimum, prefer observable proof
- Arguments should have **sensible defaults** where possible
- **Irreversible actions** (delete, send, deploy, merge) always get a human checkpoint
- If a step might fail, describe **what to do on failure** — not just "handle errors"
- Keep the skill focused on one workflow — if it does two different things, it should be two skills

## Recommended Baseline allowed-tools

```yaml
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
```

Add Bash patterns only for specific commands the skill actually needs.

## Common Pitfalls

- **Over-engineering**: Simple workflows don't need complex step structures — match complexity to the task
- **Missing context**: If the skill needs project-specific knowledge, make it an argument rather than hardcoding
- **Assumed environment**: Don't assume tools are installed — check or document prerequisites
