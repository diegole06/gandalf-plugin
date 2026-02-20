---
name: core-pr-plan
description: |
  Generate a concise cross-team PR plan document when Integrations needs changes from Core (or another team).
  Triggers: "core pr plan", "cross-team plan", "core-pr-plan", "plan for core", "plan para core".
  Outputs a focused Markdown document with: why, what code to change, and execution order.
allowed-tools: Read, Grep, Glob, Task, Bash(ls:*), Bash(git:*)
---

# Core PR Plan Generator

Generate a concise, actionable plan document for requesting changes from another team (typically Core/Platform).

## When to use

- You need another team to make code changes in their repos to support your feature/fix
- You want a clean document to share in Slack/Jira/PR that explains the why and the what
- You need to map the data flow across multiple repos and identify exactly what fields/files to change

## Output Format

The document MUST follow this exact structure. Keep it short. No over-context.

```markdown
# {Title — short, descriptive}

**Ticket:** {JIRA-ID} | **{Source Team} -> {Target Team}**

---

## Why

{2-3 sentences max. What doesn't work today and why. Reference the PR or feature that creates the need.
If there's already a PR open, mention it. No deep technical history — just the gap.}

---

## What we need from {Target Team}

### Repo: `{repo-name-1}`

{For each file that needs changes:}

1. `{FileName.ext}` — {one-line description of the change}:
```{language}
{exact code snippet showing the change — keep it minimal}
```

{If a type/class already exists that can be reused, mention it:}
(`{TypeName}` already exists in `{package.path}`)

### Repo: `{repo-name-2}`

{Same pattern. Number continues from previous repo.}

{End with a note about what likely needs NO changes:}
`{repo-name}` likely needs no changes — {reason}.

---

## What {Source Team} does

- **{repo-1}**: {one-line description of the change and its status}
- **{repo-2}**: {one-line description of the change and its status}

---

## Execution

| Step | Team | What | Can start |
|------|------|------|-----------|
| 1 | {team} | {description} | {Now / After step N} |

{One-line note about parallelism if relevant.}
{One-line note about affected providers/services if relevant.}
```

## Rules

1. **No over-context.** No history, no timing gaps, no architecture diagrams unless asked. Just the WHY and the WHAT.
2. **Code snippets must be real.** Read the actual files in the target repos before writing snippets. Never guess field names, class names, or file paths.
3. **Mention what already exists.** If a DTO, field, or type already exists in the target repo, call it out — it reduces the perceived effort for the other team.
4. **One sentence per change.** Each numbered item is one file, one change, one sentence + code snippet.
5. **Use the target team's language.** If the repo is Kotlin, show Kotlin. If Go, show Go.
6. **Always verify repos locally first.** Check `~/Documents/ms/{repo}` for the actual code before writing the plan.

## Process

1. **Understand the need.** Read the user's context — what feature/fix drives the request.
2. **Map the data flow.** Trace how data moves from the source repo to the target repos. Identify the exact structs/classes/fields involved.
3. **Read target repo code.** Find the actual files, types, and patterns used. Note what already exists.
4. **Write the plan.** Follow the template strictly. Keep it concise.
5. **Output both:** Show the plan in chat AND save to `docs/proposals/{TICKET-ID}-core-team-plan.md`.
