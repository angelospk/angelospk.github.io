---
title: Nightshift
description: Autonomous Overnight Coding-Agent Orchestration
weight: 8
tags:
- Python
- Agent Orchestration
- Telegram Bot API
- systemd
- SQLite
categories:
- ai
---

Lets a coding agent work overnight without overspending the API budget or acting unsupervised. A scheduler reads live quota data, asks the operator before starting, and refuses to run when it cannot tell what the budget is. An append-only run ledger records every task transition.

## Implementation

- Fail-closed Budgeting: A quota watcher reads real usage APIs and computes each night's budget with reserves and per-night caps; unknown usage means no run.
- Auditable State: Every task transition goes through a state service with an immutable run ledger; chat notifications and reports are projections, never the source of truth.
- Human in the Loop: A Telegram bridge asks spec questions with inline buttons, sends a night digest for approval, and reports results in the morning.
