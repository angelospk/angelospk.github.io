---
title: Brain
description: Local-first second brain with retrieval over your own notes
weight: 9
tags:
- Python
- LanceDB
- Local embeddings (Ollama)
- RAG
- LLM routing
- Telegram Bot API
- pytest
categories:
- ai
---

A personal knowledge system where spoken brain-dumps and dropped files become Markdown notes that stay the source of truth, readable in Obsidian and queryable in natural language. Local embeddings index the notes. It answers chronology-aware questions like "what occupied me last week", extracts the tasks hiding inside a ramble, and asks before it acts on any of them.

## The problem

Note apps store text but cannot answer questions about it, and cloud assistants
that can answer want the whole private archive uploaded first. Neither reads a
voice transcript and turns it into what actually needs doing.

## What I built

Built a Python system where capture, extraction, retrieval and dispatch are
separate stages over plain Markdown. Embeddings run locally against a LanceDB
index; the chat layer routes through a fallback chain of cloud backends so a
low-RAM machine is never forced to load a local model. Extracted actions are
proposed, not executed, and reach Apple Reminders or Telegram only after
approval.

## Implementation

- Your files stay yours: Markdown notes in a normal folder are the source of truth. The index is derived and can be rebuilt from scratch.
- Retrieval that knows about time: Local embeddings plus contextual retrieval and generated maps of content, so questions about a period answer from what was actually written then.
- Voice to task, with a human gate: Transcripts are cleaned, actions are extracted with due dates, and each one is approved through a Telegram bot before it becomes a real reminder.
- Claims get checked: Factual claims pulled from entries are verified against live web sources and recorded with a verdict, instead of being trusted because they were said out loud.
- Built to be maintained: 111 test modules, an entity and person graph, and 15 shipped phases planned as a decision register rather than a backlog.
