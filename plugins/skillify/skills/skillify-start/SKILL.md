---
name: skillify-start
description: >
  Start recording a workflow session so that /skillify captures only the work done after this marker.
  Use when the user wants to record a specific portion of a session into a reusable skill, not the full history.
  Trigger phrases: 'skillify-start', 'start recording', 'start skill recording', 'begin skillify recording'.
allowed-tools: []
---

# Skillify Start

Mark the beginning of a recorded workflow session.

## Steps

### 1. Acknowledge and Mark

1. Tell the user: "Recording mode is now active."
2. Output the marker exactly as shown:

```
[SKILLIFY RECORDING STARTED]
```

3. Tell the user: "Continue your work normally. When you're done, call `/skillify` and it will capture only what happened after this point."

**Success criteria**: The `[SKILLIFY RECORDING STARTED]` marker appears in the conversation and the user knows to call `/skillify` when done.

## Rules

- Do NOT begin the skillify interview or any analysis — that happens when `/skillify` is called later.
- Do NOT ask any questions. Just acknowledge, emit the marker, and give the instruction.
