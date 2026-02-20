---
name: summary
description: |
  Generate Slack-ready, standup, or Jira comment summaries from a Gandalf investigation report.
  Triggers: "summary", "resumen", "slack summary", "standup", "gandalf summary", "dame el resumen".
  Must be run after /gandalf:analyze has produced a report.
allowed-tools: Read, Grep, Glob
---

# Gandalf Summary

Generate compact summaries from a Gandalf investigation report for different audiences.

## When to use

- After `/gandalf:analyze` has produced a report
- When you need to communicate findings in Slack, standup, or Jira

## Output Formats

Generates three formats simultaneously:
1. **Slack Thread** — Emoji-rich, 5-line summary for Slack channels
2. **Standup One-Liner** — Single line for daily standup
3. **Jira Comment** — Structured comment to paste in the ticket

## Rules

- Extract ALL data from report — never re-investigate
- Each format is self-contained
- Spanish content, English Slack emoji names
- No code blocks in any format
