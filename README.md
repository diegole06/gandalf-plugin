![Gandalf](./assets/gandalf-gopher.png)

# Gandalf

**Automated payment incident investigation plugin for Claude Code**

---

## What is Gandalf?

Gandalf is a Claude Code plugin that automates payment incident investigation. Give it a Jira ticket, a URL, or a description and it will:

1. Fetch the Jira ticket
2. Search logs and traces in Datadog
3. Analyze the source code
4. Report the **root cause** and **how to fix it**

---

## How it works

Gandalf replicates the same investigation workflow a backend integration engineer follows when resolving tickets:

| Step | Manual process | Gandalf equivalent |
|------|---------------|-------------------|
| 1 | Read the ticket, understand the reported issue | `[S0:AWAIT]` — Fetch Jira ticket, classify input |
| 2 | Cross-reference TAM report vs actual conversation | `[S1:DECOMPOSE]` — Extract atomic facts, compare claims vs data |
| 3 | Investigate traces in Datadog | `[S3:INVESTIGATE]` — Query logs, traces, APM in Datadog |
| 4 | Compare results against the report | `[S4:HYPOTHESIZE]` — 5 agents propose hypotheses based on evidence |
| 5 | Determine if the issue is in the integration or elsewhere | `[S5:DEBATE]` — Adversarial debate to eliminate false positives |
| 6 | Continue investigating until root cause is clear | `[S6:CONVERGE]` — Select winning hypothesis with strongest evidence |
| 7 | Technical proposal + implementation plan | Report Block C: technical solution + test plan |
| 8 | Implement using TDD | `/gandalf:fix` — Branch, tests first, then implementation |
| 9 | Test + gather evidence | Test execution + staging verification |
| 10 | Deploy to production | Your call |

Key principle: **investigation first, implementation after**. Gandalf never proposes a fix without fully understanding the problem.

---

## Installation

```bash
cd gandalf-plugin
chmod +x install.sh
./install.sh
```

Restart Claude Code after installing.

### Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

### Required environment variables

Add to your `~/.zshenv` or `~/.bashrc`:

```bash
export JIRA_EMAIL="you@y.uno"
export JIRA_API_TOKEN="your-token"
```

Get your token at: https://id.atlassian.net/manage-profile/security/api-tokens

---

## Commands

### 1. `/gandalf:analyze` — Investigate an incident

Main command. Accepts a ticket, URL, or description.

```
/gandalf:analyze TST12-3215
/gandalf:analyze https://yunopayments.atlassian.net/browse/PAY-1234
/gandalf:analyze "Unlimint payments failing with timeout"
```

**Manual mode** (step-by-step, interactive):
```
/gandalf:analyze TST12-3215 --manual
```

### 2. `/gandalf:fix` — Implement the fix

After investigation, implements the solution. Creates a branch, writes tests first, then the fix.

```
/gandalf:fix
```

### 3. `/gandalf:summary` — Generate a summary

After investigation, generates 3 summaries: Slack, standup, and Jira.

```
/gandalf:summary
```

### 4. `/gandalf:core-pr-plan` — Cross-team PR plan

When the fix requires changes in another team's repo, generates a PR plan.

```
/gandalf:core-pr-plan TST12-3054 propagate stored_credentials via webhook events
```

---

## Auto-detection

If you installed the native rules (`install.sh` prompts you), Gandalf activates automatically when it detects intent.

### Triggers

| You type... | Gandalf does... |
|---|---|
| `TST12-3215` | Investigates the ticket |
| `https://yunopayments.atlassian.net/browse/PAY-1234` | Investigates the URL |
| `investigate what happened with Unlimint` | Investigates the text |
| `analyze ticket PAY-456` | Investigates the ticket |
| `what happened with this payment?` | Investigates |
| `why did it fail?` | Investigates |
| `debug this` | Investigates |
| `TST12-3215 step by step` | Investigates in manual mode |
| `fix this` | Implements the fix |
| `give me the summary` | Generates summary |
| `plan for core` | Generates cross-team plan |

### Does NOT trigger

| You type... | Why not? |
|---|---|
| `how does unlimint-int work?` | Code question, not an incident |
| `deploy to staging` | Deployment, use `/yuno:deploy` |
| `show me logs for nequi-int` | Log query, use `/yuno:datadog` |

---

## Report structure

The report has 3 blocks:

```
BLOCK A: EXECUTIVE SUMMARY       <-- Read this first
  - Root cause
  - Severity
  - Before vs after the fix
  - Next steps

BLOCK B: CONTEXT                  <-- The data
  - Ticket source
  - Who is affected
  - Related tickets

BLOCK C: FULL ANALYSIS            <-- For engineers
  - Problem explained
  - Root cause with file references
  - Technical solution
  - Test plan
```

---

## Manual mode (step by step)

With `--manual`, Gandalf pauses at each step and asks for direction:

```
Step 0: Classify input
   |
Step 1: Decompose ticket into facts
   |
Step 2: Plan investigation steps
   |
Step 3: Investigate (code, Datadog, Jira, Git)
   |
Step 4: 5 agents propose hypotheses
   |
Step 5: Adversarial debate between agents
   |
Step 6: Select winning hypothesis
   |
Step 7: Generate final report
```

At each pause:
```
[1] Continue to next step
[2] Dig deeper into current step
[3] Add information I have
[4] Skip to final report
```

---

## Plugin files

```
gandalf-plugin/
  assets/
    gandalf-gopher.png
  .claude-plugin/
    plugin.json
  commands/
    analyze.md
    fix.md
    summary.md
    core-pr-plan.md
  skills/
    gandalf/SKILL.md
    fix/SKILL.md
    summary/SKILL.md
    core-pr-plan/SKILL.md
  claude-md-snippet.md
  install.sh
  uninstall.sh
  README.md
```

---

## License

MIT

Gopher artwork by [Ashley McNamara](https://github.com/ashleymcnamara/gophers) — CC BY-NC-SA 4.0
