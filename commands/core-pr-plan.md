---
description: Generate a concise cross-team PR plan document — maps data flow, identifies exact code changes needed in other team's repos
argument-hint: <ticket-id> <brief description of what you need>
allowed-tools: Read, Grep, Glob, Task, Bash(ls:*), Bash(git:*)
---

# Core PR Plan

Generate an actionable plan document for requesting code changes from another team.

## Input

`$ARGUMENTS` — a ticket ID and/or brief description of the cross-team change needed.

Examples:
- `TST12-3054 propagate stored_credentials via webhook events`
- `PAY-456 add refund callback field to event publisher`
- `need core to persist a new field from our webhook events`

## Step 1 — Understand the Context

Read the current conversation context and any referenced files. Identify:
- **Source repo**: Where the change originates (usually the current working directory)
- **Target repos**: Which repos need changes from other teams
- **The gap**: What field/data/behavior is missing

If a proposal document already exists in `docs/proposals/`, read it for context.

## Step 2 — Map the Data Flow

Trace how data flows from the source repo to the target repos:

1. Find the publisher/client that sends data to the target service
2. Identify the struct/model being sent
3. Find the controller/handler in the target repo that receives it
4. Trace the request model through the service chain
5. Find where the data would ultimately be persisted

For each hop, note:
- The file and model/struct name
- Whether the needed field already exists or must be added
- Whether supporting types (DTOs, enums) already exist

Check target repos locally at `~/Documents/ms/{repo-name}/`. If not available, note it.

## Step 3 — Read Target Repo Code

For each target repo found locally:

1. Search for the relevant models/request classes
2. Check if the field or type already exists
3. Identify the exact files that need modification
4. Note the language and patterns used (Kotlin data classes, Go structs, etc.)

## Step 4 — Generate the Plan

Follow the template from the skill definition strictly:

1. **Why** — 2-3 sentences, reference existing PRs
2. **What we need from {Team}** — numbered list, one file per item, real code snippets
3. **What {our team} does** — bullet list of our side
4. **Execution table** — steps, teams, dependencies

## Step 5 — Output

1. Show the full plan in chat first
2. Save to `docs/proposals/{TICKET-ID}-core-team-plan.md`
3. Ask if the user wants adjustments
