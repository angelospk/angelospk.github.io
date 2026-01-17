+++
title = "Order Local"
description = "Self-Hosted Restaurant Ordering System"
date = "2025-01-01"
tags = ["Go", "SQLite", "HTMX", "Alpine.js", "Tailwind CSS"]
categories = ["Full Stack", "Backend"]
+++

# Order Local

**Self-Hosted Restaurant Ordering System for Raspberry Pi**

## Overview

Order Local is a self-hosted restaurant ordering system designed to run on Raspberry Pi. Customers scan QR codes at their table to browse the menu and place orders directly from their mobile browsers—no app installation required.

The system prioritizes simplicity and reliability: a single Go binary with zero runtime dependencies, optimized to run on hardware as modest as a Raspberry Pi 3B+ with just 1GB of RAM.

## Key Features

- **Single Binary Deployment** - Pure Go executable with no CGO, no runtime dependencies
- **Low Resource Consumption** - Works within 1GB RAM, < 2 second startup time
- **Real-time Updates** - Server-Sent Events (SSE) for live order tracking
- **Mobile-first Design** - Responsive web UI optimized for customer ordering
- **Role-based Access** - Customer (anonymous), Waiter (PIN), Admin (email/password)
- **Clean Architecture** - TDD approach with 95%+ test coverage on core components

## Technical Implementation

### Architecture

The project follows clean architecture principles with distinct layers:

```
Domain → Repository → Handler
```

| Layer | Responsibility |
|-------|----------------|
| Domain | Business logic, models, interfaces |
| Repository | Data access via sqlc-generated code |
| Handler | HTTP handlers, SSE, middleware |

### Technologies

| Category | Stack |
|----------|-------|
| **Backend** | Go 1.22+, Chi Router, golang-jwt |
| **Database** | SQLite (modernc.org/sqlite - pure Go) |
| **Query Gen** | sqlc (type-safe SQL) |
| **Migrations** | goose |
| **Frontend** | templ + templui + HTMX + Alpine.js |
| **Styling** | Tailwind CSS via CDN |

### Order Status Flow

```
pending → confirmed → preparing → ready → completed
    ↘                                  ↗
      → cancelled ←←←←←←←←←←←←←←←←←←←
```

## Development Highlights

- **Test-Driven Development** - Tests written before implementation
- **Race Detection** - All tests pass with `-race` flag
- **Pre-commit Hooks** - Format → Test → Lint pipeline
- **Conventional Commits** - Structured git history

### Test Coverage

| Package | Coverage |
|---------|----------|
| internal/auth | 95.7% |
| internal/domain | 90.9% |
| internal/repository | 85.4% |
| internal/config | 100% |

## Project Status

| Phase | Status |
|-------|--------|
| Foundation | ✅ Complete |
| Core Backend | ✅ Complete |
| API Layer | ✅ Complete |
| Frontend | ✅ Complete |
| Testing | ✅ Complete |
| Raspberry Pi Deployment | ⏳ Pending |

## Lessons Learned

- SQLite with pure Go drivers enables truly portable single-binary deployments
- HTMX + templ provides an excellent developer experience for server-rendered apps
- SSE is simpler than WebSockets for unidirectional real-time updates
- Clean architecture pays dividends in testability and maintainability
