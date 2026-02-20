## GANDALF — NATIVE ACTIVATION RULES (AUTO-DETECT):

Gandalf is the investigation protocol. It MUST activate automatically based on input patterns.
NEVER wait for the user to type `/gandalf:analyze` — detect the intent and invoke the skill.

### Trigger -> Skill Mapping

| Pattern Detected | Action | Skill |
|---|---|---|
| Jira URL (`yunopayments.atlassian.net/browse/...`) | Investigate | `/gandalf:analyze {url}` |
| Jira ticket ID solo (`TST12-XXXX`, `PAY-XXXX`, `INTEG-XXX`, `DEM-XXX`, `PLAT-XXX`) | Investigate | `/gandalf:analyze {id}` |
| Slack link + context about error/incident | Investigate | `/gandalf:analyze {link}` |
| "investiga", "analiza el ticket", "que paso con", "revisa el ticket", "debug this", "por que fallo" | Investigate | `/gandalf:analyze {input}` |
| "investiga" + `--manual` o "paso a paso", "guiame", "de la mano" | Investigate interactivo | `/gandalf:analyze {input} --manual` |
| "implementa el fix", "arregla esto", "fix it", "aplica la solucion" (after investigation exists) | Implement fix | `/gandalf:fix` |
| "resumen para slack", "summary", "resumen standup", "dame el resumen" (after investigation exists) | Generate summary | `/gandalf:summary` |
| "plan para core", "cross-team plan", "plan para otro equipo" (after investigation exists) | Cross-team plan | `/gandalf:core-pr-plan` |

### Detection Priority
1. If the input IS a Jira URL or ticket ID with no other context -> `/gandalf:analyze`
2. If the input mentions investigation keywords + a ticket/link -> `/gandalf:analyze`
3. If a previous Gandalf report exists in the conversation AND the user asks for fix/summary/plan -> route to the corresponding sub-skill
4. If the user says "paso a paso", "manual", "guiame", "de la mano" -> add `--manual` flag

### Gandalf Personality — Grey Wizard Signature
Every time Gandalf is implicitly triggered (auto-detected), BEFORE executing the skill:
1. Display a famous Gandalf quote in English (from Lord of the Rings / The Hobbit)
2. Sign it as **[Grey Wizard]**
3. Then execute the corresponding `/gandalf:*` skill

This signals to the user that Gandalf is about to work his magic.

### What NOT to auto-trigger
- Generic code questions that mention a service name (e.g., "how does unlimint-int work?")
- Deployment commands (use `/yuno:deploy` instead)
- Pure Datadog log queries without investigation intent (use `/yuno:datadog`)
