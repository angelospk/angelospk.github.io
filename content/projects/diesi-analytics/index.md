+++
title = "Diesi Analytics"
description = "Radio Station Analytics Platform"
date = "2026-01-01"
tags = ["Python", "FastAPI", "Vue.js", "SQLite", "Redis", "Docker", "Machine Learning"]
categories = ["Full Stack", "Data", "AI"]
+++

# Diesi Analytics

**Radio Station Analytics Platform with ML Predictions**

## Overview

Analytics platform for Diesi FM, a Greek radio station. The system analyzes 3 years of song play history (approximately 337,000 records) to provide comprehensive insights and predictions.

The platform combines traditional analytics dashboards with machine learning to predict what song will play next, adapting its model based on actual plays versus predictions.

## Key Features

- **Analytics Dashboards** - Top artists, songs, time patterns, and trends
- **ML Predictions** - Markov Chain + time-aware model predicts next song
- **Real-time Learning** - Model adapts based on actual vs predicted plays
- **Now Playing** - Live display with persistent audio player
- **Interactive Charts** - ECharts visualizations for all metrics

## Technical Implementation

### Architecture

| Component | Technology |
|-----------|------------|
| **Frontend** | Vue.js 3 (Composition API), Tailwind CSS, Vite |
| **Backend** | Python 3.11+, FastAPI, SQLAlchemy |
| **Database** | SQLite (local-first, lightweight) |
| **ML** | Markov Chain + time-aware features |
| **Caching** | Redis with smart TTLs |
| **Deployment** | Docker |
| **Charts** | ECharts |

### ML Model

The prediction model combines:
- **Markov Chain** - Probability of song B following song A
- **Time-aware features** - Different patterns for morning/afternoon/night
- **Real-time learning** - Updates weights based on prediction accuracy

The model was trained on Google Colab and exported as a pickle file for production use.

### Caching Strategy

Smart Redis caching optimizes performance:
- **Daily data** - Cached until midnight
- **Historical data** - Long TTL (data doesn't change)
- **Today's data** - 5 minute TTL (refreshes frequently)

## Development Highlights

- **TDD Approach** - pytest with minimum 80% coverage target
- **Local-first** - Works on limited hardware (old Ubuntu laptop)
- **Greek Text** - Proper UTF-8 handling for Greek song titles/artists
- **Repository Pattern** - Clean separation of data access and business logic

## Project Conventions

| Aspect | Convention |
|--------|------------|
| Python | Black formatter, isort, type hints |
| Vue/JS | ESLint + Prettier, Composition API |
| Naming | snake_case (Python), camelCase (JS) |
| Commits | Conventional commits |

## Links

- [Live Demo](https://diesi.haroldpoi.click)

## Data Context

- **Source**: CSV export from radio station playout system
- **Format**: `title, artist, datetime` (MM/DD/YYYY HH:MM:SS)
- **Volume**: ~337,000 records over 3 years
- **Language**: Mix of Greek and English
