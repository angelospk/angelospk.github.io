---
description: Sync changes from data/portfolio/projects.yaml to content/projects/*.md
---
# Project Sync Workflow

This workflow ensures that the website's content files remain the source of truth for detailed text while staying in sync with the structured data in `projects.yaml` and `portfolio_backup.yaml`.

## Smart Sync Workflow (Git-Aware)

### 1. Update Data & Commit
When the user provides new information:
1.  Update `data/portfolio/projects.yaml` (or other data files).
2.  Update `data/portfolio_backup.yaml` to include the same changes.
3.  **IMMEDIATELY** stage the change: `git add data/portfolio/projects.yaml data/portfolio_backup.yaml`.
4.  Check the diff to see what ID changed: `git diff --cached`.
5.  Commit the data update: `git commit -m "data: Enriched project [ID] context"`.

### 2. Targeted Content Sync
**Only** for the project IDs identified in Step 1 (the changed ones):

1.  **If New Config/Context**:
    -   Update the Frontmatter (Title, Date, Weight, Tags) in `content/projects/{id}/index.md`.
    -   Update the "Overview" text if the `description` or `context` in YAML changed.
2.  **If New Project**:
    -   Run the scaffolding command to create `content/projects/{id}/index.md`.

### 3. Verify & Commit Content
1.  Verify the MD file update.
2.  Commit the content update: `git commit -m "content: Sync [ID] with portfolio data"`.

## Why this is better?
-   **Precision**: We don't scan/rewrite 20 files every time. We only touch the 1 project that changed.
-   **History**: We have separate commits for "Data" (the truth) and "Content" (the presentation).
-   **Safety**: We use `git diff` to confirm exactly what changed before propagating it.

### 4. File Template (For New Projects)

```markdown
+++
title = "{title}"
description = "{subtitle}"
date = "{start_date}"
tags = [{technologies_list}]
categories = [{category}]
weight = {weight}
+++

# {title}

**{subtitle}**

## Overview

{description}

{context_problem}

{context_solution}

## Key Features

{highlights_list}

## Links

{links_list}
```

### 5. Verification
-   Check that new files appear in `content/projects/`.
-   Verify Hugo build (optional, if user wants).
