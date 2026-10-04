---
title: Job-Search Automation Pipeline
description: Personal Job Aggregation, Tracking & Tailored Documents
weight: 9
tags:
- Python
- pytest
- launchd
- Typst
categories:
- backend
---

Built a personal job-search pipeline that collects listings, removes duplicates and tracks applications in one store. It generates tailored documents and reconciles unambiguous employer acknowledgements, while leaving application decisions and submission to the user.

## The problem

Job hunting means checking many boards daily, re-reading the same listings,
losing track of what was applied to, and rewriting the CV for every role.

## What I built

Built a stdlib-only Python pipeline: pluggable sources feed a single
deduplicated store, a relevance filter keeps only on-topic roles, a Kanban
board and daily digest surface what needs action, and tailored documents are
generated per application. A launchd job runs it every morning, catches up on
wake if the machine was asleep, and sends a desktop notification.

## Implementation

- Multi-Source Aggregation: Pluggable RSS and web sources normalize into one pipeline with stable-id deduplication across sources.
- Relevance Filtering & Tracking: Keyword relevance filter plus a status workflow (new → interested → applied → interview) with a generated Kanban board and daily digest.
- Tailored Documents: Per-role CV generation (Typst) and cover-letter scaffolding driven by the captured job description.
- Scheduled, Self-Reminding: launchd scheduling with wake catch-up, once-per-day guard, atomic storage, and native desktop notifications.
