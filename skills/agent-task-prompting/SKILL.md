---
name: agent-task-prompting
description: Use when composing or refining a task prompt to delegate investigation, implementation, or verification to an external agent. Defines the task, context, boundaries, success criteria, and handoff; use the relevant external-agent skill for dispatch and session management.
---

# Agent Task Prompting

You are the main agent, responsible for assembling the **task contract** with the delegated agent.

State a clear task contract while leaving the agent room to exercise judgment. Keep prompts compact and block-structured. State the task, the output contract, the follow-through defaults, and the small set of extra constraints that matter.

Core rules:
- Prefer one clear task per agent run. Split unrelated asks into separate runs.
- Tell the agent what done looks like. Do not assume it will infer the desired end state.
- Add explicit grounding and verification rules for any task where unsupported guesses would hurt quality.
- Use the default XML structure consistently unless the user or host protocol requires another format.

## Task Prompt Template

For a new Task Prompt, use the [Task Prompt Template](./references/task-prompt-template.md) by default. If the user or host tool or skill requires another format, follow that requirement while preserving the necessary goal, context, constraints, acceptance conditions, and handoff information.

Use these five sections as the default checklist. Omit sections that add no useful information, but keep the task, scope, and completion standard clear and preserve host-required fields. Keep top-level sections flat by default; nested content is allowed when inputs have a natural hierarchy.

| Tag | What to write |
|---|---|
| `<task>` | What to do and the intended result; explain the purpose when it affects decisions. |
| `<context>` | Working directory, relevant background, accessible source paths, confirmed facts, and clearly labeled assumptions. |
| `<constraints>` | File and operation scope, authorization, behavior to preserve, prohibitions, and stop conditions. |
| `<success_criteria>` | Observable completion conditions and proportionate verification methods or evidence. State how to report checks that cannot be performed. |
| `<output>` | The minimum handoff needed to review the result: conclusions, key evidence, changes, and unresolved items as applicable. This does not require machine-readable output unless the host does. |

Leave execution choices to the agent. Provide known test commands, reproduction steps, or ordered procedures when their sequence is necessary for correctness; do not prescribe an unnecessary full execution plan. Success criteria define what must be achieved and verified; output requirements define which results and evidence must be returned.

Do not rely on implicit conversation history. State critical decisions and authorization directly; provide accessible paths or evidence pointers for larger materials instead of copying them in full. Distinguish confirmed facts from assumptions.

Allow investigation of unknown facts within scope. Stop the affected work only when a missing prerequisite prevents reliable progress or the next action would exceed authorization; an uninvestigated question is not itself a blocker.

## Common mistakes

- Leaving scope ambiguous, or prescribing unnecessary implementation steps instead of a clear result.
- Writing only authorization prohibitions into `<constraints>`, or only the exact scope (or the reverse).
- Stating an outcome in `<success_criteria>` without the evidence that proves it.
- Omitting completed work, external effects, the reason for a blocker, or what is needed to continue when a task is blocked.
- Omitting the host-side stop conditions and handoff fields required by the host skill (`BLOCKED` marker, `agent_session_id`, and similar).
- Re-sending the whole Task Prompt when continuing an existing session instead of sending only the delta.
