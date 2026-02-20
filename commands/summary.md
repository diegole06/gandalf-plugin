---
description: Generate a Slack-ready summary from a Gandalf investigation report
argument-hint: [ticket-id]
allowed-tools: Read, Grep, Glob
---

# Gandalf Summary

Generate a compact, Slack-ready summary from the most recent Gandalf investigation report.

## Prerequisites

This command MUST be run after `/gandalf:analyze` has produced a report in the current conversation.
If no report exists in context, tell the user to run `/gandalf:analyze` first.

## Input

`$ARGUMENTS` — optional ticket ID to disambiguate if multiple investigations exist in context.
If empty, use the most recent report in the conversation.

## Output Formats

Generate THREE formats — show all three so the user can pick:

### Format 1: Slack Thread Summary (para pegar en Slack)

```
:mag: *{TICKET_ID}*: {El Problema en 1 oracion}
:dart: *Root Cause*: {causa raiz en 1 oracion} ({confidence}%)
:wrench: *Fix*: {solucion en 1 oracion} | {N} archivos, {M} lineas
:warning: *Riesgo*: {BAJO/MEDIO/ALTO} | *Reporter Accuracy*: {X}%
:bar_chart: *Alcance*: {merchants afectados} merchants, {transacciones} txns (7d)
```

### Format 2: Standup One-Liner (para daily standup)

```
{TICKET_ID}: {problema en <10 palabras} — fix ready, {confidence}% confidence, {riesgo} risk
```

### Format 3: Jira Comment (para pegar en el ticket como comentario)

```
h3. Investigacion Gandalf

*Root Cause:* {causa raiz en 1-2 oraciones con referencia a archivo y linea}
*Confidence:* {X}%
*Fix:* {solucion en 1-2 oraciones}
*Archivos:* {lista}
*Riesgo:* {nivel} — {detalle breve}
*Reporter Accuracy:* {X}% ({assessment})

{Si hay discrepancias con el reporter:}
*Nota:* El reporter indico "{claim incorrecto}" — la investigacion encontro que {correccion}.
```

## Rules

1. Extract ALL data from the report in context — do NOT re-investigate
2. Keep each format self-contained (someone reading it should understand without the full report)
3. Use Spanish for content, English for Slack emoji names
4. Never include code blocks in any format
5. If blast radius data was unavailable, omit the Alcance line in Format 1
