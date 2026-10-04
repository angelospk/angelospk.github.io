---
title: Project Secretary
description: Backlog retrieval and review queues across GitHub repositories
weight: 9
tags:
- Python
- SurrealDB
- Embeddings / fastembed
- GitHub API
- Vector Search
categories:
- ai
---

Stops maintainers from repeating work already discussed: a Python service finds related issues and pull requests across GitHub repositories. Local embeddings and a graph-aware reranker separate true duplicates from overlap and useful context.

## The problem

In a busy backlog the same idea gets filed twice, the issue describing a feature
lives in one repo while the code that implements it lives in another, and nobody
has time to wire those connections by hand.

## What I built

Built a memory backbone over SurrealDB that syncs issues, PRs, comments, and
Project v2 items, with a local-embeddings semantic layer and a reranker that
classifies items as duplicate, overlap, prior context, or noise.

## Implementation

- Indexed issues, pull requests, comments and Project items in SurrealDB using repository-scoped identifiers.
- Combined local embeddings with labels, milestones and graph relationships to classify related work.
- Added review queues, explained label suggestions and a read-only MCP interface for agent access.
- Made enrichment writes idempotent and backlog-maintenance commands dry-run by default; documented remaining recovery and deployment gaps.

## Links

- [GitHub](https://github.com/angelospk/project_secretary)
