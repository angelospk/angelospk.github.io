---
title: Codex Bridge
description: Safe orchestration layer for a second coding agent
weight: 8
tags:
- Python
- SQLite
- Job queue / worker
- Sandboxing
- Agent orchestration
- pytest
categories:
- automation
---

Infrastructure that lets one coding agent hand work to another without either of
them being able to reach past the boundary it was given. A queue, a worker and a
single policy module decide which model runs, what it is allowed to write, how
long it gets and whether the budget can afford it. Over 1,000 jobs have gone
through it.

## The problem

Calling a second agent directly from a shell means an unbounded process that can
hang the session, write wherever the config happens to allow, and burn quota
with nobody watching. A review job that silently gained write access to the repo
it was reviewing is the failure that started this.

## What I built

Every job goes through a client that enqueues and a worker that runs it under an
explicitly passed sandbox. Reasoning effort selects the model and the time budget
together, so no caller can assemble a combination nobody designed. Write access
exists only inside a declared lane, arguments are an allowlist rather than a
denylist, and what the job touched is verified against a git baseline taken at
enqueue time.

## Implementation

- Fails closed by design: Read-only sandbox is passed explicitly on every job, since inheriting it from config is how a review once wrote to disk. Unknown flags reject the job instead of being forwarded.
- Never hangs the caller: Two-phase waiting that only times out when the queue stops moving, bounded concurrency of three reads and one write, and a stop hook that refuses to end a session with its own job still running.
- Spends nothing it should not: A usage gate reads the live quota windows before enqueueing and refuses on unclassified or incomplete usage data rather than guessing there is room.
- Scope is measured, not promised: Post-job verification compares the changed files against the declared allowlist using a baseline from the enqueue moment, so concurrent human edits are never blamed on the agent.
- 4,800 lines of tests: Eight test modules covering policy resolution, sandbox confinement, offload gating, watch delivery and the pending-work hook.
