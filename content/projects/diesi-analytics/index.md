---
title: Diesi Analytics
description: Radio Station Analytics Platform
weight: 9
tags:
- SQL
- Python
- FastAPI
- Vue.js 3
- SQLite
- Redis
- Docker
- ECharts
categories:
- fullstack
---

Shows a radio station what it plays: dashboards over roughly 337,000 historical song plays expose rotation patterns by song, artist and time of day. SQL aggregations and predictive models explore what may play next.

## Implementation

- Queried roughly 337,000 play records by artist, song and time window for interactive dashboards.
- Used Redis caching for heavier aggregate queries and ECharts for exploration.
- Explored Markov-chain and time-aware next-song predictions alongside live now-playing data.

## Links

- [Live Demo](https://diesi.haroldpoi.click)
