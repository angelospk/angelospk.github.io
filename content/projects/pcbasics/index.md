+++
title = "PC Basics"
description = "Digital Literacy Training Platform"
date = "2025-01-01"
tags = ["SvelteKit", "Svelte 5", "SQLite", "Drizzle ORM", "Tailwind CSS"]
categories = ["Full Stack", "Education"]
+++

# PC Basics

**Digital Literacy Training Platform for Beginners**

## Overview

PC Basics is an educational platform designed to teach elderly users and complete beginners essential digital skills. The application runs in the browser and provides interactive lessons with progress tracking, making it easy for users to learn at their own pace.

It has since grown into a detailed digital-skills curriculum based on the Greek ministry's guide, with extra challenges focused on internet safety and fraud prevention — the parts that matter most for people who are easy targets for online scams. Originally built to support digital skills training workshops, the platform has bilingual support (English/Greek).

## Key Features

- **Ministry-aligned curriculum** - Structured, level-based digital skills guide
- **Internet safety & anti-fraud challenges** - Practice spotting scams and staying safe online
- **Interactive Lessons** - Drag & drop, click, hover, and typing exercises
- **Multi-level Difficulty** - Beginner, Intermediate, and Advanced tracks
- **Progress Tracking** - Per-user progress saved and resumable
- **Bilingual Support** - Full English and Greek translations via inlang
- **Admin Panel** - Content management, lesson enabling/disabling, statistics

## Technical Implementation

### Architecture

| Component | Technology |
|-----------|------------|
| **Framework** | SvelteKit + Svelte 5 (runes) |
| **Database** | SQLite (dev) / Turso (production) |
| **ORM** | Drizzle ORM |
| **UI** | shadcn-svelte + Tailwind CSS v4 |
| **i18n** | inlang/paraglide |
| **Auth** | Simple username-based + Admin PIN |

### Lesson System

Lessons are structured with:
- **Categories** - Mouse, Keyboard, Files, Security, E-banking
- **Steps** - Individual exercises within each lesson
- **Types** - Click, Drag, Hover, Type interactions
- **Feedback** - Immediate visual feedback on actions

### Progress Persistence

```
User → Session → Progress (per lesson/step)
```

Progress is saved to the database, allowing users to:
- Resume where they left off
- Track completed lessons
- See overall advancement

## Development Approach

- **TDD** - Tests written before implementation
- **Unit Tests** - Vitest for component testing
- **E2E Tests** - Playwright for user flow testing
- **Hot Reload** - Bun for fast development cycles

## Deployment

### Local Development
```bash
bun install
bun run db:init
bun run dev
```

### Production (Vercel + Turso)
- Uses Turso for distributed SQLite
- Automatic deployments via Vercel
- Environment variables for database credentials

## Links

- [Live Demo](https://pcbasics.vercel.app/)

## Use Case

This platform was developed to support digital skills training workshops I conduct with a local NGO. It provides a safe, interactive environment for elderly users to practice computer skills without fear of making mistakes on a real system.
