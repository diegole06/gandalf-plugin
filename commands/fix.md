---
description: Implement the fix from a Gandalf investigation — creates branch, writes tests first (TDD), implements changes, runs tests, commits
argument-hint: [ticket-id]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Gandalf Fix

Implement the fix identified by a Gandalf investigation. Follows TDD strictly: tests first, then implementation.

## Prerequisites

This command MUST be run after `/gandalf:analyze` has produced a report in the current conversation.
If no report exists in context, tell the user to run `/gandalf:analyze` first.

## Input

`$ARGUMENTS` — optional ticket ID to disambiguate if multiple investigations exist in context.
If empty, use the most recent report in the conversation.

## Step 1 — Extract Fix Plan from Report

From the report in the conversation context, extract:
- **Archivos afectados** (from Metadata section)
- **Solucion Tecnica** (the numbered steps)
- **Plan de Testing** (test cases to write)
- **Root Cause** (file, function, line)
- **Ticket ID** (from report header)
- **Service name** (from Datos de Entrada)

Determine the working directory:
- Check if current directory is the affected service repo
- If not, check `~/Documents/ms/{service-name}/`
- If the service repo is not found locally, tell the user and stop

## Step 2 — Create Branch

```bash
TICKET_ID="{extracted ticket ID}"
BRANCH_NAME="fix/$(echo $TICKET_ID | tr '[:upper:]' '[:lower:]')-$(echo '{short description}' | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
git checkout -b "$BRANCH_NAME"
```

## Step 3 — Write Tests FIRST (TDD)

Read the existing test file(s) for the affected package.
Based on the "Plan de Testing" section from the report:

1. Modify existing test cases that assert the wrong expected value
2. Add new test cases for edge cases identified in the report
3. Follow the existing test patterns (table-driven, black-box)
4. Use early returns, no nested ifs, no else statements

Run the tests — they MUST FAIL at this point (red phase of TDD):
```bash
go test ./...
```

Confirm the tests fail for the expected reason (wrong return value, not compilation error).

## Step 4 — Implement the Fix

Now implement the minimum change described in "Solucion Tecnica":

1. Read each affected file
2. Make ONLY the changes described in the report — nothing more
3. No refactoring, no cleanup, no extra improvements
4. Follow existing code patterns and style

## Step 5 — Run Tests (Green Phase)

```bash
go test ./...
```

ALL tests must pass. If any test fails:
1. Read the failure output
2. Fix the issue
3. Re-run until green

## Step 6 — Verify No Side Effects

Run the full test suite for the service:
```bash
go test ./...
```

Check that:
- All pre-existing tests still pass
- No other packages are broken
- The fix only changes what was planned

## Step 7 — Commit

Stage only the affected files (never `git add -A`):
```bash
git add {file1} {file2} ...
git commit -m "$(cat <<'EOF'
fix: {short description matching ticket}

{TICKET_ID}: {one-line summary of what was fixed and why}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

## Step 8 — Output Summary

Show the user:

```markdown
## Gandalf Fix Applied — {TICKET_ID}

**Branch**: `{branch_name}`
**Archivos modificados**: {list}
**Tests**: {N passed, 0 failed}
**Commit**: `{short SHA}` — {commit message first line}

**Siguientes pasos:**
- `git push -u origin {branch_name}` — Push al remoto
- Crear PR con `/commit` o `gh pr create`
- `/gandalf:summary` — Generar resumen para Slack
```
