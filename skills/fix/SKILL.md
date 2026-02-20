---
name: fix
description: |
  Implement the fix from a Gandalf investigation report using TDD (tests first, then implementation).
  Triggers: "fix", "implement fix", "apply fix", "gandalf fix", "implementa el fix", "arregla esto".
  Must be run after /gandalf:analyze has produced a report.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

# Gandalf Fix

Implement the fix identified by a Gandalf investigation. Follows TDD strictly.

## When to use

- After `/gandalf:analyze` has produced a report
- When you want to go from investigation to implementation in one step

## Process

1. Extract fix plan from report (files, changes, test cases)
2. Create git branch (`fix/{ticket-id}-{short-description}`)
3. Write/modify tests FIRST — they must fail (red phase)
4. Implement the minimum change — tests must pass (green phase)
5. Run full test suite to verify no side effects
6. Commit with conventional commit format

## Rules

- NEVER implement without a report in context
- ALWAYS write tests before implementation (TDD)
- ONLY change what the report describes — no extras
- Use early returns, no nested ifs, no else
- Stage specific files only — never `git add -A`
