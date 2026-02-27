---
description: Monitor a deploy — pre-deploy risk scan, live monitoring, and consolidated health report
argument-hint: <service-name> [environment] [--duration=N] [--baseline=Nm]
allowed-tools: Bash(curl:*), Bash(jq:*), Bash(git:*), Read, Grep, Glob, Task, WebFetch, mcp__plugin_yuno_datadog__get_logs, mcp__plugin_yuno_datadog__list_traces, mcp__plugin_yuno_datadog__query_metrics, mcp__plugin_yuno_datadog__get_monitors, mcp__plugin_yuno_datadog__list_hosts, mcp__plugin_yuno_datadog__get_active_hosts_count, mcp__plugin_yuno_github__list_commits, mcp__plugin_yuno_github__get_file_contents, mcp__plugin_yuno_github__get_pull_request_files, mcp__github__list_commits, mcp__github__get_file_contents, mcp__github__get_pull_request_files, mcp__jira__jira_create_issue, mcp__jira__jira_add_comment, mcp__jira__jira_search_issues, mcp__plugin_yuno_context7__resolve-library-id, mcp__plugin_yuno_context7__query-docs
---

# Gandalf Sentinel — Deploy Monitoring

Activate deploy monitoring protocol. Analyzes code changes for risks, monitors post-deploy metrics in real-time, and generates a consolidated health report.

## Grey Wizard Personality

When Sentinel is implicitly triggered (auto-detected from user input, NOT via explicit `/gandalf:sentinel`), BEFORE starting:
1. Display a famous Gandalf quote about vigilance or watching (Lord of the Rings / The Hobbit)
2. Sign it as **[Grey Wizard — Sentinel Mode]**
3. Then proceed with monitoring

Example:
> *"The board is set, the pieces are moving. We come to it at last."*
> — **[Grey Wizard — Sentinel Mode]**

## Language Rule

The ENTIRE output MUST be in Spanish. Section titles, content, tables, verdicts — everything.
Exceptions: technical identifiers (file paths, function names, service names, trace IDs, commit SHAs), status labels (HEALTHY, DEGRADED, CRITICAL), and metric names stay in English.

## Input

`$ARGUMENTS` — parsed as:

```
<service-name> [environment] [--duration=N] [--baseline=Nm]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `service-name` | YES | — | Service to monitor (e.g., `dlocal-int`) |
| `environment` | NO | `staging` | Target: dev, staging, sandbox, production |
| `--duration=N` | NO | `10` | Minutes of post-deploy monitoring |
| `--baseline=Nm` | NO | `30m` | Pre-deploy baseline window for comparison |

## Pre-Execution — Load Yuno Knowledge Base Context

Before starting the 3-phase pipeline, load service context from `yuno-payments/knowledge-base-lib`:

**Source 1 — Local KB** (if `~/Documents/ms/knowledge-base-lib/` exists):
1. Grep `SERVICE_CATALOG.md` for the service name to identify team and type
2. Read `teams/{team}/repositories/{service-name}.md` for service documentation
3. Read the relevant payment flow from `architecture/flows/` based on the service type
4. Read `architecture/dependencies/service-dependency-overview.md` for upstream/downstream context

**Source 2 — Context7 MCP** (if local not available):
1. `mcp__plugin_yuno_context7__resolve-library-id` with `libraryName: "yuno-payments/knowledge-base-lib"`
2. `mcp__plugin_yuno_context7__query-docs` with query: "{service-name} architecture dependencies payment flow"

**Source 3 — GitHub MCP** (if both unavailable):
1. `mcp__github__get_file_contents` from `yuno-payments/knowledge-base-lib` for the service doc and flow

This context is used in Phase 1 (risk classification of changed files with business context) and Phase 3 (anomaly correlation with architectural role).

## Execution

Invoke the `sentinel` skill from `skills/sentinel/SKILL.md` which executes the 3-phase pipeline:

1. **PRE-DEPLOY**: Code diff risk analysis + baseline metric capture
2. **WATCH**: Live monitoring loop with incremental dashboard updates every ~2 min
3. **POST-DEPLOY**: Consolidated report with verdict (HEALTHY / DEGRADED / CRITICAL)

## Post-Report Follow-up

After report, the user can:
- "investiga la anomalía" → launches `/gandalf:analyze` with anomaly context
- "rollback" → suggests `/yuno:redeploy`
- "resumen para slack" → Sentinel-specific Slack summary
- "crea un ticket" → Jira issue with anomaly findings
- "monitorea más" → extends monitoring with current state as new baseline
