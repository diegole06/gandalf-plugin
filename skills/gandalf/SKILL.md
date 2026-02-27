---
name: gandalf
description: |
  Gandalf — Deterministic adversarial investigation protocol for payment integration incidents.
  Triggers: Jira URLs (yunopayments.atlassian.net/browse/*), Jira IDs (TST12-*, PAY-*, INTEG-*, DEM-*, PLAT-*),
  Slack incident links, "investiga", "analiza", "que paso con", "revisa el ticket", "debug",
  "por que fallo", "investigate", "incident", "gandalf", "analyze incident", "debug payment".
  Accepts Jira tickets, Jira URLs, Slack links, or raw descriptions.
  NATIVE: Auto-activates on pattern match — user does NOT need to type /gandalf:analyze.
allowed-tools: Bash(curl:*), Bash(jq:*), Read, Grep, Glob, Task, WebFetch, mcp__plugin_yuno_datadog__get_logs, mcp__plugin_yuno_datadog__list_traces, mcp__plugin_yuno_datadog__query_metrics, mcp__plugin_yuno_datadog__get_monitors, mcp__jira__jira_get_issue, mcp__jira__jira_search_issues, mcp__jira__jira_get_comments, mcp__jira__jira_get_attachments, mcp__github__get_file_contents, mcp__github__search_code, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline, mcp__plugin_yuno_context7__resolve-library-id, mcp__plugin_yuno_context7__query-docs
---

# Gandalf Investigation Protocol

Deterministic adversarial investigation protocol for payment integration incidents.

## Activation

Gandalf activates NATIVELY — the user does NOT need to type `/gandalf:analyze`.

**Auto-detect patterns:**
- Jira URL pasted alone -> `/gandalf:analyze {url}`
- Jira ticket ID pasted alone -> `/gandalf:analyze {id}`
- Slack link + error context -> `/gandalf:analyze {link}`
- "investiga", "analiza el ticket", "que paso con", "revisa el ticket", "por que fallo" -> `/gandalf:analyze {input}`
- "paso a paso", "guiame", "de la mano" -> adds `--manual` flag
- After a report exists: "implementa el fix" -> `/gandalf:fix`, "resumen" -> `/gandalf:summary`

**Explicit invocation still works:** `/gandalf:analyze {input}` for users who prefer it.

### Grey Wizard Personality
Every time Gandalf is implicitly triggered (auto-detected), BEFORE executing the skill:
1. Display a famous Gandalf quote in English (from Lord of the Rings / The Hobbit)
2. Sign it as **[Grey Wizard]**
3. Then execute the corresponding `/gandalf:*` skill

This signals to the user that Gandalf is about to work his magic.

## Execution Modes

| Mode | Flag | Behavior |
|------|------|----------|
| **Auto** (default) | none | Run all states silently, output full report at the end |
| **Manual** | `--manual` | Pause after each state, show findings, ask for direction |

### Manual Mode
In manual mode, each investigation state pauses and shows a brief summary with options:
1. Continue to next step
2. Dig deeper into current step
3. Add information the user has
4. Skip to final report

This allows the user to guide the investigation interactively.

## Commands

| Command | Purpose |
|---------|---------|
| `/gandalf:analyze` | Run full investigation — produces 3-block report |
| `/gandalf:analyze --manual` | Interactive investigation — pause at each state |
| `/gandalf:fix` | Implement the fix from the report (TDD: tests first) |
| `/gandalf:summary` | Generate Slack/standup/Jira-ready summary |
| `/gandalf:core-pr-plan` | Generate cross-team PR plan when fix requires another team |

## Internal Protocol (executed silently in auto, shown in manual)

1. `[S0:AWAIT]` — Acknowledge input, classify source type
2. `[S0.5:CONTEXT]` — Load Yuno Knowledge Base context (service docs, flows, glossary, dependencies)
3. `[S1:DECOMPOSE]` — Parse fetched data into atomic facts (enriched with KB context)
4. `[S2:PLAN]` — Generate 5-8 investigation steps
5. `[S3:INVESTIGATE]` — Execute using Datadog, Jira, GitHub, codebase tools, memory, KB
6. `[S4:HYPOTHESIZE]` — Multi-agent adversarial (PaymentsDev/QA/Product/Security/TechLead)
7. `[S5:DEBATE]` — Adversarial debate with confidence adjustments
8. `[S6:CONVERGE]` — Select winner per dominance rules

## Report Format — 3-Block Layout

The report is organized into 3 clearly separated visual blocks for maximum readability:

### Block A: EXECUTIVE SUMMARY (appears FIRST)
The TL;DR for stakeholders and decision-makers:
- **Veredicto** — Root cause in plain language + confidence %
- **Risk/Complexity badges** — Quick-read table
- **Resultado Esperado** — Before/After flow in blockquotes
- **Siguientes Pasos** — Numbered action items with owners
- **Comandos disponibles** — Gandalf follow-up commands

### Block B: CONTEXTO
The data sources and scope used for the investigation:
- **Datos de Entrada** — Ticket info, reporter, service, traces
- **Alcance e Impacto** — Blast radius table (merchants, transactions, timeline)
- **Tickets Relacionados** — Similar/duplicate tickets

### Block C: ANALISIS COMPLETO
Deep technical dive for engineers:
- **El Problema** — Plain language description with analogies
- **Root Cause (detallado)** — Technical details with file references
- **Auditoria del Reporter** — Claims extraction, verdicts, accuracy score
- **Solucion Tecnica** — Numbered steps in plain language
- **Plan de Testing** — Unit tests, staging verification, edge cases, regression
- **Evaluacion de Riesgo** — Full risk matrix
- **Metadata** — Files, lines, dependencies, Datadog links

## Investigation Features

- **Yuno Knowledge Base**: Loads architectural context from `yuno-payments/knowledge-base-lib` (local → Context7 → GitHub MCP fallback)
- **Jira Fetch Strategy**: REST API (primary) -> Service Desk API -> Memory -> MCP (last resort)
- **Datadog Fallback**: MCP -> Direct URL generation -> /yuno:datadog skill
- **Multi-Service Tracing**: Traces data flow across repos when bug spans services
- **Related Tickets**: Searches Jira and memory for similar incidents
- **Auto-Persist**: Report is structured for automatic capture by claude-mem
- **Language**: Full Spanish report with English technical identifiers

## Conversational Follow-up

After report, supports:
- New tickets/links -> new investigation
- "show evidence" -> show S1 facts table
- "show debate" -> show S4-S6 adversarial analysis
- "show implementation" -> show exact code diff for the fix
- "drill into H{N}" -> focused investigation on hypothesis
- "check logs for {service}" -> targeted Datadog query
