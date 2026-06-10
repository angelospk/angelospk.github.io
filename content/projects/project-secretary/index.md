+++
title = "Project Secretary"
description = "Smart Secretary for a GitHub Backlog"
date = "2026-03-01"
tags = ["Python", "SurrealDB", "Embeddings", "GitHub API", "Vector Search"]
categories = ["ai"]
weight = 9
+++

# Project Secretary

**Smart secretary for a GitHub backlog**

## Overview

Project Secretary is a library and tool that remembers everything in one or more GitHub
repos — issues, PRs, comments, Project items — connects related work even across repo
boundaries, and enriches a new issue with relevant history plus grounded codebase context.

### The Problem

In a busy backlog the same idea gets filed twice, the issue describing a feature lives in
one repo while the code that implements it lives in another, and nobody has time to wire
those connections by hand.

### The Approach

A memory backbone over SurrealDB syncs issues, PRs, comments, and Project v2 items into a
single graph store. A semantic layer using local embeddings (fastembed/ONNX, no torch) finds
candidates, and a reranker decides which are a duplicate, an overlap, prior context, or just
noise — using structure that's already there, like shared labels, edges, and milestones.

## Key Features

- **Cross-repo memory:** index several repos in one store so a frontend issue can surface
  the backend PR that implements it.
- **Semantic related work:** local embeddings plus a heuristic reranker, no hosted model
  required.
- **Grounded issue comments:** writes an idempotent, sticky comment with related history and
  DeepWiki file-level context to help resolve an issue.
- **Auto-labels & backlog help:** embeddings-based categorization to suggest labels and
  surface related issues and PRs.

## Links

- [GitHub](https://github.com/angelospk/project_secretary)
