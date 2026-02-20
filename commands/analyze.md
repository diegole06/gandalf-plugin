---
description: Start a Gandalf structured investigation — accepts Jira ticket IDs, Jira URLs, Slack links, or raw descriptions
argument-hint: <jira-ticket | jira-url | slack-url | description> [--manual]
allowed-tools: Bash(curl:*), Bash(jq:*), Read, Grep, Glob, Task, WebFetch, mcp__plugin_yuno_datadog__get_logs, mcp__plugin_yuno_datadog__list_traces, mcp__plugin_yuno_datadog__query_metrics, mcp__plugin_yuno_datadog__get_monitors, mcp__jira__jira_get_issue, mcp__jira__jira_search_issues, mcp__jira__jira_get_comments, mcp__jira__jira_get_attachments, mcp__github__get_file_contents, mcp__github__search_code, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline
---

# Gandalf Analyze

Activate the Gandalf investigation protocol. Automatically detects input type and fetches context.

## Grey Wizard Personality

When Gandalf is implicitly triggered (auto-detected from user input, NOT via explicit `/gandalf:analyze`), BEFORE starting the investigation:
1. Display a famous Gandalf quote in English (from Lord of the Rings / The Hobbit)
2. Sign it as **[Grey Wizard]**
3. Then proceed with the investigation

Example:
> *"A wizard is never late, nor is he early. He arrives precisely when he means to."*
> — **[Grey Wizard]**

## Language Rule

The ENTIRE report MUST be in Spanish. Section titles, content, tables, verdicts — everything.
The only exceptions are: technical identifiers (file paths, function names, status constants, Jira IDs) and the verdict labels (CONFIRMED, PARTIALLY CORRECT, INCORRECT, UNVERIFIABLE) which stay in English for consistency with scoring.

## Execution Modes

Parse `$ARGUMENTS` for the `--manual` flag:

### Auto Mode (default)
No `--manual` flag present. Execute ALL states silently and output the full report at the end.

### Manual Mode (`--manual`)
When `--manual` is present, strip the flag from arguments and run the investigation interactively.
In manual mode, PAUSE after each state and show a brief summary of what was found, then ask the user for direction before proceeding to the next state.

Manual mode output per state:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  S{N}: {STATE_NAME}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Brief summary of findings at this stage — 3-5 bullet points max}

---
Opciones:
  [1] Continuar al siguiente paso
  [2] Profundizar en este paso (dame mas contexto)
  [3] Agregar informacion que tengo
  [4] Saltar directo al reporte final
```

Wait for user input before proceeding. If the user provides info at step [3], incorporate it into the investigation context before continuing.

## Input

`$ARGUMENTS` — one of:
- Jira ticket ID: `PAY-1234`, `INTEG-567`, `PLAT-890`
- Jira URL: `https://yuno-team.atlassian.net/browse/PAY-1234`
- Slack message link: `https://yuno.slack.com/archives/C.../p...`
- Raw text description of the incident
- Any of the above + `--manual` for interactive mode

## Step 1 — Input Detection and Data Fetch

Parse `$ARGUMENTS` and detect type:

### Type A: Jira Ticket ID
Pattern: `[A-Z]+-[0-9]+` (e.g., PAY-1234, INTEG-567)

```bash
TICKET_ID="$ARGUMENTS"
```

Fetch using the Jira REST API directly via curl (proven reliable — MCP tool has persistent access issues with many projects).
Extract: summary, description, labels, priority, status, assignee, comments.

**Jira Fetch Strategy (3-tier fallback):**

1. **Primary — Direct REST API with curl** (ALWAYS try this first):
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://yunopayments.atlassian.net/rest/api/3/issue/$TICKET_ID?expand=renderedFields"
```
For comments:
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://yunopayments.atlassian.net/rest/api/3/issue/$TICKET_ID/comment"
```

2. **Fallback — Service Desk API** (for projects like TST12/Yuno Support Hub where REST API returns 403):
Service Desk projects use a different API path. IMPORTANT: requires Basic auth via header, NOT `-u` flag.
```bash
AUTH_HEADER="Authorization: Basic $(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)"
curl -s -H "$AUTH_HEADER" \
  "https://yunopayments.atlassian.net/rest/servicedeskapi/request/$TICKET_ID?expand=participant,status,sla,requestType,serviceDesk,attachment,action,comment"
```
This returns: summary, status, reporter, SLA, comments, attachments — everything needed.
Known Service Desk projects: TST12 (Yuno Support Hub).

3. **Memory search** — try `mcp__plugin_claude-mem_mcp-search__search` for the ticket ID in past observations

4. **MCP tool** — try `mcp__jira__jira_get_issue` as last resort (known to return 403 on many projects)

5. If all fail, ask the user to paste the ticket content

Credentials are available as env vars `JIRA_EMAIL` and `JIRA_API_TOKEN`.
If env vars are not set, check `~/.claude/settings.local.json` for stored credentials.

**Why this order:** The standard REST API works for most projects. Service Desk projects (TST12) block the standard API but expose data via `/rest/servicedeskapi/request/`. The MCP Jira tool is least reliable across all project types.

### Type B: Jira URL
Pattern: `https://*.atlassian.net/browse/[A-Z]+-[0-9]+`

Extract ticket ID from URL path (use `-oE` not `-oP`, macOS grep lacks `-P`):
```bash
TICKET_ID=$(echo "$ARGUMENTS" | grep -oE '[A-Z]+-[0-9]+')
```

Then fetch exactly like Type A (including fallback chain).

### Type C: Slack Message Link
Pattern: `https://*.slack.com/archives/C[A-Z0-9]+/p[0-9]+`

Slack requires authentication. Do this:

1. Check if `SLACK_BOT_TOKEN` or `SLACK_TOKEN` env var exists:
```bash
if [ -n "$SLACK_BOT_TOKEN" ]; then
  CHANNEL=$(echo "$ARGUMENTS" | sed 's|.*archives/||' | sed 's|/.*||')
  TS_RAW=$(echo "$ARGUMENTS" | sed 's|.*/p||')
  TS="${TS_RAW:0:10}.${TS_RAW:10}"

  curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    "https://slack.com/api/conversations.replies?channel=$CHANNEL&ts=$TS&limit=20" | jq '.messages'

  curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    "https://slack.com/api/conversations.history?channel=$CHANNEL&latest=$TS&limit=5&inclusive=true" | jq '.messages'
fi
```

2. If NO Slack token exists, tell the user:
```
[S0:AWAIT] Slack link detected but no SLACK_BOT_TOKEN configured.
Paste the Slack message content here so I can proceed with the investigation.
```

Then WAIT for user to paste the message content before continuing.

### Type D: Raw Text
If none of the above patterns match, use `$ARGUMENTS` as-is — it's a direct incident description.

## Step 2 — Execute Gandalf State Machine (INTERNAL in auto mode, INTERACTIVE in manual mode)

Execute ALL states. States S0 through S6 are the investigation engine.
In AUTO mode: run silently, do NOT output these states to the user.
In MANUAL mode: pause after each state (see Execution Modes above).

### S0:AWAIT — Acknowledge input, classify source type

### S1:DECOMPOSE — Parse fetched data into atomic facts

### S2:PLAN — Generate 5-8 investigation steps
Include these mandatory investigation steps in the plan:
- Search for related Jira tickets (same service, same error, same merchant)
- Query Datadog for blast radius data (transaction volume, affected merchants count)
- Reconstruct timeline from git log and Datadog logs (when the bug was introduced, first occurrence)
- If the bug spans multiple services, trace the data flow across repos

### S3:INVESTIGATE — Execute investigation plan

Use Datadog, Jira, GitHub, codebase tools.

**Multi-Service Tracing:** If the investigation reveals the bug spans 2+ services:
1. Identify the data flow chain: publisher -> consumer -> processor
2. For each service in the chain, check `~/Documents/ms/{service-name}/` locally
3. Trace the affected struct/field through each hop
4. Note which services need changes and which are just pass-through

**Datadog Fallback Strategy:** When Datadog MCP returns 403:
1. Log that MCP credentials lack required scopes (logs_read_data, apm_read)
2. Generate the direct Datadog URL for the user to open in browser:
   - Logs: `https://app.datadoghq.com/logs?query=service:{service} {error_code}&from_ts={7d_ago}&to_ts={now}`
   - APM: `https://app.datadoghq.com/apm/traces?query=service:{service} resource_name:{endpoint}`
   - Trace: `https://app.datadoghq.com/apm/trace/{trace_id}`
3. Try the `/yuno:datadog` skill as alternative
4. If all fail, note "Datadog data unavailable" in the report and proceed with codebase analysis only

**Related Tickets Search:**
1. Search Jira via REST API (IMPORTANT: `/rest/api/3/search` was REMOVED — use `/rest/api/3/search/jql`):
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" -G \
  "https://yunopayments.atlassian.net/rest/api/3/search/jql" \
  --data-urlencode "jql=project = {project} AND text ~ \"{error_code}\" ORDER BY created DESC" \
  --data-urlencode "maxResults=10"
```
2. Search memory: `mcp__plugin_claude-mem_mcp-search__search` for the error code or service name
3. Note any related tickets found — they may reveal patterns or prior fixes

**Blast Radius Data Collection:**
1. Query Datadog for transaction count with the error in last 7 days
2. Identify unique merchants affected
3. Identify unique countries affected
4. Calculate percentage of total transactions for the service

**Timeline Reconstruction:**
1. `git log --all --oneline --grep="{relevant_keyword}"` in the affected repo to find when the bug was introduced
2. Query Datadog logs for first occurrence of the error pattern
3. Check if the bug was introduced in a specific PR/commit

### S4:HYPOTHESIZE — Multi-agent adversarial debate
Agents: PaymentsDev, QA, Product, Security, TechLead
Each proposes a hypothesis with initial confidence (0-100%)

### S5:DEBATE — Adversarial debate with confidence adjustments
- CONFIRMED = +10%, PARTIALLY CORRECT = +5%, INCORRECT = -15%, UNVERIFIABLE = 0%

### S6:CONVERGE — Select winner per dominance rules
- Winner = highest confidence after debate
- If winner < 60%, flag as LOW CONFIDENCE investigation

## Step 3 — Generate Report (USER-FACING OUTPUT)

The report is split into 3 clearly separated visual blocks.
Use box-drawing characters and whitespace for maximum readability.

### BLOCK A: EXECUTIVE SUMMARY (FIRST THING THE USER READS)

This block gives the TL;DR — the conclusion, the risk, and the action items.
It MUST appear FIRST so stakeholders can make decisions without reading the full analysis.

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  GANDALF — {TICKET_ID}
  {ticket summary in one line}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Veredicto

**Root Cause**: {1-2 oraciones describiendo la causa raiz en lenguaje plano}

| | |
|---|---|
| **Confidence** | {X}% |
| **Riesgo del cambio** | {BAJO / MEDIO / ALTO} — {1 frase de justificacion} |
| **Complejidad** | {BAJA / MEDIA / ALTA} — {N archivos, N lineas} |
| **Deploy coordinado** | {NO / SI — lista de servicios} |

### Resultado Esperado

**ANTES**
> {flujo actual con el bug — usar > blockquote para visibilidad}

**DESPUES**
> {flujo corregido — usar > blockquote para visibilidad}

### Siguientes Pasos

{Lista numerada de acciones concretas. Cada paso indica QUIEN y QUE.
Si hay un PR existente, mencionarlo. Si hay comandos Gandalf disponibles, listarlos.}

1. {paso 1 — ej: "Aprobar y mergear PR #102 en unlimint-int"}
2. {paso 2 — ej: "Deploy a staging y verificar con transaccion 3DS Mastercard"}
3. {paso 3 — ej: "Deploy a produccion"}

**Comandos disponibles:**
| Comando | Accion |
|---------|--------|
| `/gandalf:fix` | Implementar el fix (branch, TDD, tests, commit) |
| `/gandalf:summary` | Generar resumen para Slack/standup |
{| `/gandalf:core-pr-plan` | Generar plan cross-team (si aplica) |}
```

### BLOCK B: CONTEXTO DE INVESTIGACION

This block contains the input data, sources, and scope. It's what was used to investigate.
Separated from Block A by a clear visual divider.

```markdown

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CONTEXTO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Datos de Entrada

| Campo | Valor |
|-------|-------|
| **Fuente** | {Jira Ticket / Slack / Raw} |
| **Reporter** | {nombre} |
| **Servicio** | {service} |
| **Estado** | {status} |
| **Prioridad** | {priority} |
| **SLA** | {deadline si existe} |
| **Trace ID** | `{trace_id}` |
| **Payment ID** | `{payment_id si existe}` |

### Alcance e Impacto

| Dimension | Valor |
|-----------|-------|
| **Merchants afectados** | {N merchants o "no determinado"} |
| **Transacciones afectadas (7d)** | {N transacciones o estimacion} |
| **Paises** | {lista o "todos"} |
| **% del trafico del servicio** | {X% o "no determinado"} |
| **Primera ocurrencia** | {fecha o "no determinado"} |
| **Commit que introdujo el bug** | `{SHA}` — {fecha} |
| **Tiempo en produccion** | {N dias/semanas/meses} |

{Si Datadog fue inaccesible:}
> **Datadog inaccesible** (MCP 403). Links para verificacion manual:
> - Logs: `{url}`
> - APM: `{url}`

### Tickets Relacionados

| Ticket | Relacion | Estado |
|--------|----------|--------|
| {TICKET-ID} | {Duplicado / Similar / Causa raiz compartida} | {Open / Closed} |

{Si no se encontraron:}
No se encontraron tickets relacionados.
```

### BLOCK C: ANALISIS COMPLETO

This block is the deep dive — technical details, reporter audit, testing plan.
It's for engineers who want the full picture. Collapsed by default in the reader's mind
because Blocks A and B already gave them what they need.

```markdown

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ANALISIS COMPLETO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### El Problema

{Descripcion del problema en maximo 3 parrafos usando lenguaje plano.
Debe ser entendible por un PM o TechLead que no conoce el codigo.
Usar analogias simples cuando el concepto tecnico sea complejo.
NO incluir codigo. NO incluir nombres de funciones o variables.}

### Root Cause (detallado)

{Descripcion tecnica completa de la causa raiz. Archivos, funciones, lineas.
Sin bloques de codigo — solo referencia textual.
Incluir la cadena completa: donde se genera el dato, donde se pierde, donde deberia llegar.}

**Confidence**: {X}%

### Auditoria del Reporter

#### Claims Textuales

| # | Claim Exacto del Reporter | Tipo |
|---|---------------------------|------|
| C1 | "{cita textual}" | Diagnostico / Localizacion / Prescripcion / Impacto / Criterio |

#### Veredicto por Claim

| # | Claim | Veredicto | Score | Evidencia |
|---|-------|-----------|-------|-----------|
| C1 | {resumen} | CONFIRMED / PARTIALLY CORRECT / INCORRECT / UNVERIFIABLE | {100/50/0/N-A}% | {evidencia breve} |

#### Asertividad Global

| Metric | Value |
|--------|-------|
| **Score Global** | {X}% |
| **Assessment** | ACCURATE / MOSTLY ACCURATE / PARTIALLY ACCURATE / INACCURATE / MISLEADING |
| **Diagnostico** | {X}% — {N}/{M} confirmed |
| **Prescripcion** | {X}% — {N}/{M} confirmed |
| **Impacto** | {X}% — {N}/{M} confirmed |

#### Discrepancias

| Aspecto | Reporter dijo | Investigacion encontro |
|---------|---------------|------------------------|
| {aspecto} | "{cita}" | {hallazgo real} |

{Si no hay discrepancias:}
El reporter fue preciso en todos los aspectos.

### Solucion Tecnica

{Pasos numerados. Cada paso en 1-2 oraciones.
NO incluir bloques de codigo.
Describir el cambio en terminos de comportamiento, no de implementacion.}

### Plan de Testing

**Tests unitarios requeridos:**
1. {Caso de test — que escenario cubre}
2. {Caso de test — ...}

**Verificacion local:**
1. {Paso}
2. {Paso}

**Verificacion en staging:**
1. {Paso}
2. {Paso}

**Edge cases:**
- {Edge case 1}
- {Edge case 2}

**Regression:**
- {Test de regresion 1}
- {Test de regresion 2}

### Evaluacion de Riesgo

| Factor | Nivel | Detalle |
|--------|-------|---------|
| **Complejidad** | {BAJA/MEDIA/ALTA} | {detalle} |
| **Radio de explosion** | {BAJO/MEDIO/ALTO} | {detalle} |
| **Side effects** | {NINGUNO/BAJO/MEDIO} | {detalle} |
| **Reversibilidad** | {FACIL/MEDIA/DIFICIL} | {detalle} |
| **Deploy coordinado** | {SI/NO} | {detalle} |

### Metadata

| Campo | Valor |
|-------|-------|
| **Archivos afectados** | {lista con rutas relativas} |
| **Lineas a cambiar** | {N} |
| **Dependencias** | {ninguna / lista} |
| **Servicios** | {lista} |
| **Trace ID** | `{trace}` |
| **Datadog Links** | {URLs o N/A} |
| **PR** | {link si existe} |
```

## Step 4 — Post-Report Actions (INTERNAL)

After generating report, execute these silently:

### Auto-Persist
The report content is automatically captured by claude-mem through session observation.
Ensure the report is complete and well-structured so future sessions can recall it via memory search.

## Step 5 — Conversational Follow-up

After report, the user can:
- Paste another Slack link or Jira ticket -> new investigation with accumulated context
- Provide additional evidence -> restart from S1
- "drill into H2" -> focused investigation on that hypothesis
- "check logs for [service]" -> targeted S3 step
- "show evidence" -> show the full S1:DECOMPOSE facts table
- "show debate" -> show the full S4-S6 adversarial analysis
- "show implementation" -> show the exact code diff (files, old lines, new lines) for the fix
- Share a thread screenshot -> read and integrate
