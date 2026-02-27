# Gandalf Sentinel — Deploy Monitoring Skill Design

**Date:** 2026-02-26
**Author:** Diego Leon
**Status:** Approved

## Summary

New Gandalf skill for monitoring deployments of payment integration services. Provides pre-deploy risk analysis (code diff), live post-deploy monitoring with incremental dashboard, and consolidated health report with verdict.

## Approach

**Gandalf Sentinel** — Sequential 3-phase pipeline:

1. **PRE-DEPLOY**: Analyze code diff between deployed and new version, classify file changes by risk category, capture baseline metrics from Datadog
2. **WATCH**: Monitoring loop every ~2 min for configurable duration (default 10 min). Queries Datadog (logs, traces, metrics, monitors), Redash, Slack channels. Shows incremental dashboard each cycle
3. **POST-DEPLOY**: Consolidated report in Gandalf 3-block format with HEALTHY/DEGRADED/CRITICAL verdict

## Data Sources

- **Datadog**: Logs, APM traces, metrics (latency p99/p95, throughput, error rate), monitors
- **GitHub**: Commit history, file diffs between versions
- **Local codebase**: Static analysis of changed files
- **Redash**: Transaction success rates (if available)
- **Slack**: Alert channel scanning (if SLACK_BOT_TOKEN configured)
- **Kingdom**: Deploy info via API (if available)

## Activation

- **Native auto-detect**: "monitorea el deploy", "vigila el deploy", "watch deploy", "sentinel", "deploy monitor", "como va el deploy"
- **Explicit**: `/gandalf:sentinel <service> [env] [--duration=N] [--baseline=Nm]`
- **Grey Wizard quote** on implicit activation (Sentinel Mode variant)

## Anomaly Detection

Threshold-based comparison against pre-deploy baseline:
- Error count: WARNING >25%, CRITICAL >100%
- Latency p99: WARNING >30%, CRITICAL >100%
- Error rate: WARNING >50%, CRITICAL >200%
- Throughput drop: WARNING >20%, CRITICAL >50%
- New error types: WARNING 1-2, CRITICAL 3+

Early exit on 2 consecutive CRITICAL cycles.

## Output Format

- **Incremental dashboard** during WATCH phase (compact status per cycle)
- **Final report** in 3-block Gandalf format:
  - Block A: Verdict + recommended action + available commands
  - Block B: Deploy context (commits, files, risk score, data sources)
  - Block C: Full metric analysis, anomaly correlation, timeline

## Files Created

- `skills/sentinel/SKILL.md` — Full skill definition
- `commands/sentinel.md` — Command interface
- `claude-md-snippet.md` — Updated with Sentinel triggers
- `docs/plans/2026-02-26-gandalf-sentinel-design.md` — This document

## Constraints

- Read-only skill — never modifies files
- Spanish output (English for technical identifiers)
- Must complete at least 1 monitoring cycle before generating report
- Baseline comparison is mandatory — no absolute-only reporting
