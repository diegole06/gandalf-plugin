---
name: sentinel
description: |
  Gandalf Sentinel — Deploy monitoring and anomaly detection for payment integration services.
  Triggers: "monitorea el deploy", "vigila el deploy", "watch deploy", "sentinel",
  "deploy monitor", "como va el deploy", "monitorea {service}", "vigila {service}".
  Provides pre-deploy risk analysis (code diff), live post-deploy monitoring, and consolidated report.
  NATIVE: Auto-activates on deploy monitoring keywords.
allowed-tools: Bash(curl:*), Bash(jq:*), Bash(git:*), Read, Grep, Glob, Task, WebFetch, mcp__plugin_yuno_datadog__get_logs, mcp__plugin_yuno_datadog__list_traces, mcp__plugin_yuno_datadog__query_metrics, mcp__plugin_yuno_datadog__get_monitors, mcp__plugin_yuno_datadog__list_hosts, mcp__plugin_yuno_datadog__get_active_hosts_count, mcp__plugin_yuno_github__list_commits, mcp__plugin_yuno_github__get_file_contents, mcp__plugin_yuno_github__get_pull_request_files, mcp__github__list_commits, mcp__github__get_file_contents, mcp__github__get_pull_request_files, mcp__jira__jira_create_issue, mcp__jira__jira_add_comment, mcp__jira__jira_search_issues, mcp__plugin_yuno_context7__resolve-library-id, mcp__plugin_yuno_context7__query-docs
---

# Gandalf Sentinel — Deploy Monitoring Protocol

Deploy monitoring and anomaly detection protocol for payment integration services.
Executes a 3-phase pipeline: **PRE-DEPLOY Risk Scan → WATCH Live Monitoring → POST-DEPLOY Consolidated Report**.

## Activation

Sentinel activates NATIVELY on deploy monitoring keywords.

**Auto-detect patterns:**
- "monitorea el deploy de {service}" → `/gandalf:sentinel {service}`
- "vigila el deploy de {service}" → `/gandalf:sentinel {service}`
- "watch deploy {service}" → `/gandalf:sentinel {service}`
- "sentinel {service}" → `/gandalf:sentinel {service}`
- "deploy monitor {service}" → `/gandalf:sentinel {service}`
- "como va el deploy de {service}" → `/gandalf:sentinel {service}`

**Explicit invocation:** `/gandalf:sentinel {service} [environment] [--duration=N] [--baseline=Nm]`

### Grey Wizard Personality — Sentinel Mode
When implicitly triggered, BEFORE starting:
1. Display a famous Gandalf quote about vigilance or watching (Lord of the Rings / The Hobbit)
2. Sign as **[Grey Wizard — Sentinel Mode]**
3. Then execute

Preferred quotes for Sentinel:
- *"The board is set, the pieces are moving. We come to it at last."*
- *"All we have to decide is what to do with the time that is given us."*
- *"I will not say: do not weep; for not all tears are an evil."*
- *"There never was much hope. Just a fool's hope."*

## Language Rule

ALL output MUST be in Spanish. Section titles, content, tables, verdicts — everything.
Exceptions: technical identifiers (file paths, function names, service names, trace IDs, commit SHAs), status labels (HEALTHY, DEGRADED, CRITICAL), and metric names stay in English.

## Input Parsing

```
/gandalf:sentinel <service-name> [environment] [--duration=N] [--baseline=Nm]
```

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `service-name` | YES | — | Service name (e.g., `dlocal-int`, `stripe-int`) |
| `environment` | NO | `staging` | Target environment: dev, staging, sandbox, production |
| `--duration=N` | NO | `10` | Minutes of post-deploy monitoring |
| `--baseline=Nm` | NO | `30m` | Pre-deploy baseline window for comparison |

**Input extraction rules:**
1. Extract service name — first non-flag token after the trigger keyword
2. Extract environment — second non-flag token, or default to `staging`
3. Extract flags — `--duration=N` and `--baseline=Nm`
4. Validate service exists locally at `~/Documents/ms/{service-name}/`

If service directory not found locally, proceed anyway using only remote data sources (Datadog, GitHub).

## Phase 0: Load Yuno Knowledge Base Context

Before starting the monitoring pipeline, load architectural context for the service from `yuno-payments/knowledge-base-lib`.

**Triple-Source Strategy (try in order, use first available):**

1. **Local KB** (`~/Documents/ms/knowledge-base-lib/`):
   - Grep `architecture/SERVICE_CATALOG.md` for service name → get team, type, criticality tier
   - Read `teams/{team}/repositories/{service-name}.md` for service documentation
   - Read the matching payment flow from `architecture/flows/` based on service type
   - Read `architecture/dependencies/service-dependency-overview.md` for upstream/downstream services

2. **Context7 MCP** (if local not available):
   - `mcp__plugin_yuno_context7__resolve-library-id` with `libraryName: "yuno-payments/knowledge-base-lib"`
   - `mcp__plugin_yuno_context7__query-docs` with query: "{service-name} architecture dependencies payment flow"

3. **GitHub MCP** (if both unavailable):
   - `mcp__github__get_file_contents` from `yuno-payments/knowledge-base-lib` for service doc and relevant flow

**KB context is used for:**
- Phase 1: Enriching risk classification with business context (e.g., "this file handles 3DS challenge responses" vs just "ALTO risk")
- Phase 2: Understanding expected behavior vs anomalous behavior
- Phase 3: Correlating anomalies with the service's role in the payment chain

## Phase 1: PRE-DEPLOY — Risk Scan

**Objective:** Analyze what changed between the currently deployed version and the version being deployed.

### Step 1.1 — Identify Versions

Determine the diff range:

1. Check local repo at `~/Documents/ms/{service-name}/`:
```bash
cd ~/Documents/ms/{service-name} && git log --oneline -20
```

2. Identify current branch and recent commits:
```bash
git log --oneline master..HEAD 2>/dev/null || git log --oneline main..HEAD 2>/dev/null
```

3. If service not local, use GitHub MCP:
   - `mcp__plugin_yuno_github__list_commits` or `mcp__github__list_commits` for `yuno-payments/{service-name}`
   - Get last 20 commits on main/master branch

### Step 1.2 — Analyze Code Diff

For each changed file, classify the risk:

| Category | Files/Patterns | Risk | Why |
|----------|---------------|------|-----|
| Builders/Mappers | `builders.go`, `models.go`, `mapper*.go` | ALTO | Changes request/response payloads to provider API |
| Error Handling | `*error*.go`, status code mappings | ALTO | Changes payment outcome behavior |
| Service Logic | `service.go`, `payment.go`, `refund.go` | ALTO | Core business logic |
| Config/Constants | `flows.go`, `paymentmethods.go`, URLs | MEDIO | May require env configuration |
| DB/Migrations | GORM models, migration files | ALTO | Can break queries or data integrity |
| Dependencies | `go.mod`, `go.sum` | MEDIO | New deps may introduce issues |
| Handlers | `handler*.go` | MEDIO | HTTP layer changes |
| Tests | `*_test.go` | BAJO | Indicates coverage (positive signal) |
| Docs/Config | `*.md`, `*.yaml`, `*.json` | BAJO | Non-functional changes |

**Risk scoring:**
- Each ALTO file = 3 points
- Each MEDIO file = 2 points
- Each BAJO file = 0 points
- Total: 0-3 = LOW, 4-8 = MEDIUM, 9+ = HIGH

### Step 1.3 — Capture Baseline Metrics

Before deploy effects are visible, capture current state from Datadog:

1. **Error count** (last `--baseline` window):
```
service:{service-name} env:{environment} status:error
```
Use `mcp__plugin_yuno_datadog__get_logs` with time range = `--baseline` minutes ago to now.

2. **Latency metrics**:
Use `mcp__plugin_yuno_datadog__query_metrics` for:
- `trace.http.request.duration.by.service.p99{service:{service-name},env:{environment}}`
- `trace.http.request.duration.by.service.p95{service:{service-name},env:{environment}}`

3. **Throughput**:
- `trace.http.request.hits{service:{service-name},env:{environment}}.as_rate()`

4. **Current error rate**:
- Calculate from error count / total request count

5. **Error signatures** — capture unique error messages in baseline to compare later:
```
service:{service-name} env:{environment} status:error
```
Extract and deduplicate error message patterns.

**Datadog Fallback:** If MCP returns 403, generate direct Datadog URLs for manual verification:
- Logs: `https://app.datadoghq.com/logs?query=service:{service-name}%20env:{environment}%20status:error&from_ts={baseline_start}&to_ts={now}`
- APM: `https://app.datadoghq.com/apm/services/{service-name}?env={environment}`

### Step 1.4 — Output Pre-Deploy Report

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SENTINEL — PRE-DEPLOY RISK SCAN
  {service-name} → {environment}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commits: {N} ({old_hash}..{new_hash})
Archivos cambiados: {N}
Risk Level: {LOW / MEDIUM / HIGH}

Cambios detectados:
  [{ALTO/MEDIO/BAJO}]  {file_path} — {1-line description of change}
  [{ALTO/MEDIO/BAJO}]  {file_path} — {1-line description of change}
  ...

Riesgos identificados:
  1. {risk description — what could go wrong}
  2. {risk description}
  ...

Baseline capturado:
  Errors/min: {N}
  Latency p99: {N}ms
  Throughput: {N} req/min
  Error Rate: {N}%
  Error signatures: {N} patrones únicos

Iniciando monitoreo post-deploy ({duration} minutos)...
```

## Phase 2: WATCH — Live Monitoring Loop

**Objective:** Monitor metrics and logs at regular intervals after deploy.

### Monitoring Cycle

Execute a monitoring cycle every ~2 minutes for `--duration` minutes.
Total cycles = `duration / 2` (e.g., 10 min = 5 cycles).

Each cycle queries ALL available data sources in parallel (use Task tool for parallelism):

#### Source 1: Datadog Logs
Query: `service:{service-name} env:{environment} status:error`
Time range: last 2 minutes (since previous cycle).
Extract:
- Error count
- New error signatures (not in baseline)
- Top error messages

#### Source 2: Datadog Metrics
Query latency and throughput metrics for current 2-minute window.
Compare against baseline values captured in Phase 1.

#### Source 3: Datadog Traces
Query: `service:{service-name} env:{environment} -status:ok`
Time range: last 2 minutes.
Extract:
- Traces with errors
- Latency outliers (>2x baseline p99)
- New resource names with errors

#### Source 4: Datadog Monitors (first cycle only)
Check active monitors for the service:
- `mcp__plugin_yuno_datadog__get_monitors` with tag `service:{service-name}`
- Report any monitor in ALERT or WARN state

#### Source 5: Redash (if available)
If Redash MCP tools are available, query transaction success rates:
- Payment success rate by payment method for the service
- Compare against baseline period

#### Source 6: Slack Channels (if token available)
If `SLACK_BOT_TOKEN` env var exists:
- Scan alert channels for mentions of `{service-name}` in last 2 minutes
- Channels to scan: `#alerts`, `#monitoring`, `#deploys`, `#integrations-alerts`

```bash
if [ -n "$SLACK_BOT_TOKEN" ]; then
  for CHANNEL_ID in C_ALERTS C_MONITORING C_DEPLOYS; do
    curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
      "https://slack.com/api/conversations.history?channel=$CHANNEL_ID&oldest=$TWO_MIN_AGO&limit=10" | \
      jq -r '.messages[] | select(.text | test("{service-name}"; "i")) | .text'
  done
fi
```

### Anomaly Detection Thresholds

| Metric | NORMAL (✅) | WARNING (⚠️) | CRITICAL (🔴) |
|--------|-----------|-------------|--------------|
| Error count delta | <25% vs baseline | 25%-100% vs baseline | >100% vs baseline |
| Latency p99 delta | <30% vs baseline | 30%-100% vs baseline | >100% vs baseline |
| Error rate delta | <50% vs baseline | 50%-200% vs baseline | >200% vs baseline |
| Throughput drop | <20% vs baseline | 20%-50% vs baseline | >50% vs baseline |
| New error types | 0 new | 1-2 new | 3+ new |
| Monitor alerts | 0 ALERT | 1 WARN | 1+ ALERT |

### Cycle Output (Incremental Dashboard)

Each cycle outputs a compact status update:

```markdown
━━━ SENTINEL WATCH — Ciclo {N}/{total} (min {elapsed} de {duration}) ━━━

  Errors:     {N} (baseline: {N})  → {+/-}% {✅/⚠️/🔴}
  Latency p99: {N}ms (baseline: {N}ms) → {+/-}% {✅/⚠️/🔴}
  Throughput: {N} req/min (baseline: {N} req/min) → {+/-}% {✅/⚠️/🔴}
  Error Rate: {N}% (baseline: {N}%) → {+/-}% {✅/⚠️/🔴}

  {If new errors detected:}
  Nuevos errores detectados:
    → "{error_message}" (x{count}, últimos 2 min)
    → Trace: {trace_id} — {description}

  {If monitor alerts:}
  Monitores:
    → {monitor_name}: {ALERT/WARN} — {message}

  {If Slack mentions:}
  Slack:
    → #{channel}: "{message_preview}"

  Tendencia: {STABLE ➡️ / IMPROVING ↗️ / DEGRADING ↘️}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Trend Calculation

Track metric deltas across cycles to determine trend:
- **STABLE**: metrics within ±10% of previous cycle
- **IMPROVING**: error rate or latency decreasing for 2+ consecutive cycles
- **DEGRADING**: error rate or latency increasing for 2+ consecutive cycles

### Early Exit Conditions

If **CRITICAL** threshold is breached for **2 consecutive cycles**:
1. Immediately stop the monitoring loop
2. Output early exit warning:
```markdown
🔴 SENTINEL EARLY EXIT — Anomalía crítica persistente detectada

  Métrica crítica: {metric_name}
  Valor actual: {value} (baseline: {baseline_value})
  Ciclos consecutivos en CRITICAL: 2

  Acción recomendada: ROLLBACK INMEDIATO
  Comando: /yuno:redeploy
```
3. Proceed directly to Phase 3 (Consolidated Report) with CRITICAL verdict.

### User Interruption

During the WATCH loop, the user can:
- "para" / "stop" / "detener" → Stop monitoring, generate report with data so far
- "más tiempo" / "extend" → Add 5 more minutes to duration
- "rollback" / "revertir" → Stop monitoring + suggest rollback command

## Phase 3: POST-DEPLOY — Consolidated Report

**Objective:** Generate a final report with overall deploy health verdict.

### Verdict Determination

Calculate overall verdict from all monitoring cycles:

| Condition | Verdict |
|-----------|---------|
| All metrics NORMAL across all cycles | ✅ **HEALTHY** |
| Any metric WARNING but none CRITICAL, or CRITICAL in only 1 cycle | ⚠️ **DEGRADED** |
| Any metric CRITICAL for 2+ cycles, OR early exit triggered | 🔴 **CRITICAL** |

**Confidence calculation:**
- Base confidence = 50%
- +10% per cycle completed without anomalies
- +5% per data source successfully queried
- -10% per data source unavailable (e.g., Datadog 403)
- -5% per WARNING anomaly detected
- -15% per CRITICAL anomaly detected
- Cap at 95% max, floor at 20% min

### Report Structure (3 Blocks)

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  GANDALF SENTINEL — REPORTE FINAL
  {service-name} → {environment}
  Deploy: {commit_hash} | {timestamp}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BLOQUE A: VEREDICTO

  Estado: {✅ HEALTHY / ⚠️ DEGRADED / 🔴 CRITICAL}
  Confianza: {N}%

  Resumen: {1-2 oraciones del estado del deploy en lenguaje plano}

  Acción Recomendada:
    {Based on verdict:}
    ✅ HEALTHY → Deploy estable. No se requiere acción.
    ⚠️ DEGRADED → Anomalías detectadas. Investigar antes de promover a producción.
    🔴 CRITICAL → Rollback recomendado. Anomalías críticas persistentes.

  Comandos disponibles:
  | Comando | Acción |
  |---------|--------|
  | `/gandalf:analyze {ticket}` | Investigar anomalía específica |
  | `/gandalf:summary` | Generar resumen para Slack |
  | `/yuno:redeploy` | Rollback a versión anterior |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CONTEXTO DEL DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BLOQUE B: CONTEXTO

  | Campo | Valor |
  |-------|-------|
  | Servicio | {service-name} |
  | Ambiente | {environment} |
  | Commits | {N} ({old_hash}..{new_hash}) |
  | Archivos cambiados | {N} |
  | Risk Score Pre-deploy | {LOW / MEDIUM / HIGH} |
  | Duración monitoreo | {N} minutos ({M} ciclos) |
  | Baseline window | {N} minutos |
  | Fuentes consultadas | {list: Datadog, GitHub, Redash, Slack, Local} |
  | Fuentes no disponibles | {list or "Ninguna"} |

  Cambios clave:
    [{risk}] {file_path} — {description}
    ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ANÁLISIS DE MÉTRICAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BLOQUE C: ANÁLISIS COMPLETO

  Métricas Comparativas:
  | Métrica | Baseline | Post-deploy (avg) | Post-deploy (max) | Delta (avg) | Estado |
  |---------|----------|-------------------|-------------------|-------------|--------|
  | Errors/min | {N} | {N} | {N} | {+/-}% | {✅/⚠️/🔴} |
  | Latency p99 | {N}ms | {N}ms | {N}ms | {+/-}% | {✅/⚠️/🔴} |
  | Throughput | {N}/min | {N}/min | {N}/min | {+/-}% | {✅/⚠️/🔴} |
  | Error Rate | {N}% | {N}% | {N}% | {+/-}% | {✅/⚠️/🔴} |

  Evolución por Ciclo:
  | Ciclo | Min | Errors | Latency p99 | Throughput | Error Rate | Tendencia |
  |-------|-----|--------|-------------|------------|------------|-----------|
  | 1 | 0-2 | {N} | {N}ms | {N}/min | {N}% | {➡️/↗️/↘️} |
  | 2 | 2-4 | {N} | {N}ms | {N}/min | {N}% | {➡️/↗️/↘️} |
  | ... | ... | ... | ... | ... | ... | ... |

  {If anomalies detected:}
  Anomalías Detectadas:
    1. {Tipo}: {descripción} — Primera aparición: ciclo {N}
       Evidencia: {error message, trace ID, log entry}
       Correlación con código: {file changed} → {posible relación}
    2. ...

  {If new error types found:}
  Nuevos Tipos de Error (no existían en baseline):
    1. "{error_signature}" — {count} ocurrencias, primer trace: {trace_id}
    2. ...

  Correlación Código ↔ Anomalías:
  | Archivo Cambiado | Riesgo Pre-deploy | Anomalía Relacionada | Correlación |
  |------------------|-------------------|----------------------|-------------|
  | {file_path} | {ALTO/MEDIO/BAJO} | {anomaly or "Ninguna"} | {CONFIRMADA/POSIBLE/DESCARTADA} |

  Timeline:
    {HH:MM} — Baseline capturado ({baseline} min window)
    {HH:MM} — Monitoreo iniciado
    {HH:MM} — Ciclo 1: {status}
    {HH:MM} — {Notable event if any}
    {HH:MM} — Monitoreo finalizado — Veredicto: {verdict}

  {If Datadog was inaccessible:}
  Datadog Links (verificación manual):
    - Logs: {url}
    - APM: {url}
    - Dashboard: {url}

  Monitores Activos:
  | Monitor | Estado | Desde |
  |---------|--------|-------|
  | {monitor_name} | {OK/WARN/ALERT} | {timestamp} |
```

## Post-Report Actions

### Auto-Persist
Report content is automatically captured by session memory for future recall.

### Conversational Follow-up

After the report, the user can:
- "investiga la anomalía {N}" → launches `/gandalf:analyze` with the anomaly context
- "rollback" / "revertir" → suggests `/yuno:redeploy`
- "resumen para slack" → generates Sentinel-specific Slack summary
- "crea un ticket" → creates Jira issue with anomaly findings
- "monitorea {N} minutos más" → extends monitoring with fresh baseline from current state

### Sentinel Slack Summary Format

When user asks for summary after a Sentinel report:

```
{emoji} *SENTINEL — {service-name}* ({environment})
Deploy: `{commit_hash}` | {timestamp}
Estado: *{HEALTHY/DEGRADED/CRITICAL}* ({confidence}%)

{If anomalies:}
Anomalías: {count}
  → {top anomaly description}

Métricas: Errors {+/-}% | Latency {+/-}% | Throughput {+/-}%

{If CRITICAL:}
:rotating_light: Acción: Rollback recomendado
{If DEGRADED:}
:warning: Acción: Investigar antes de promover
{If HEALTHY:}
:white_check_mark: Acción: Safe to promote
```

Emoji mapping:
- HEALTHY → `:white_check_mark:`
- DEGRADED → `:warning:`
- CRITICAL → `:rotating_light:`

## Rules (HARD CONSTRAINTS)

1. NEVER skip Phase 1 (Pre-deploy scan) — it provides context for anomaly correlation
2. NEVER generate a report without at least 1 monitoring cycle completed
3. ALWAYS compare against baseline — never report absolute values without context
4. ALWAYS show the incremental dashboard during WATCH phase — this IS the live dashboard
5. ALWAYS include correlation between code changes and detected anomalies in the final report
6. If Datadog MCP returns 403, generate manual URLs — NEVER silently skip data collection
7. Early exit ONLY on 2 consecutive CRITICAL cycles — never on a single spike
8. Report MUST be in Spanish (except technical identifiers)
9. Use Task tool for parallel data source queries within each monitoring cycle
10. NEVER modify any files during Sentinel execution — this is a read-only monitoring skill
