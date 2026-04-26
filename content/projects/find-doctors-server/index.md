+++
title = "FindDoctors Aggregator Server"
description = "Unified backend search for Greek public health appointments"
date = "2026-01-01"
tags = ["Go", "REST API", "Concurrency", "Healthcare", "TypeScript", "TDD"]
categories = ["Backend", "Healthcare"]
weight = 10
+++

# FindDoctors Aggregator Server

**Unified search backend for Greek public health appointments**

## Overview

FindDoctors Aggregator Server is a Go backend that makes appointment availability easier to discover across the Greek public health appointment system.

The project addresses a practical limitation of `finddoctors.gov.gr`: patients often need to search across different entities, regions, and health units manually before they can understand whether there is an available appointment. This server aggregates that discovery step into a faster API that can power a patient-facing UI.

The goal for the next stage is a simple interface where a patient can find whether, when, and where an appointment exists near them, or farther away if they are willing to travel, and move toward booking without fighting the public platform.

## Key Features

- **Unified Smart Search** - A single `/api/search` endpoint for soonest appointments with optional distance and region filters
- **Cross-Entity Search** - Searches public hospitals and primary health centers concurrently
- **Distance-Aware Results** - Supports location-based filtering and proximity sorting
- **Capacity Reports** - Shows fill rates and earliest availability per specialty for a hospital
- **Granular Slots** - Fetches appointment times, doctor names, clinic metadata, and unit details
- **Type Safety** - Generates TypeScript types from Go models with `tygo`
- **TDD-Backed Core** - Tests cover the search and sorting logic

## Technical Implementation

### Architecture

The backend works as a read-only aggregator in front of the official appointment system. It does not store user cookies or appointment session data; it focuses on stateless discovery.

| Area | Implementation |
|------|----------------|
| Backend | Go HTTP server |
| Search | Concurrent worker pool |
| Entities | Public hospitals and primary care centers |
| API | REST endpoints |
| Types | Go to TypeScript generation via `tygo` |
| Testing | Go tests with race detection |

### Core Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/api/search` | Find the soonest available appointment by specialty, region, and distance |
| `/api/hospitals/{hunitId}/capacity` | Inspect hospital specialty capacity and first available dates |
| `/api/hospitals/{hunitId}/slots` | Fetch detailed appointment slots for a unit, specialty, and date |
| `/api/specialties` | Discover available medical specialties |

## Product Direction

The backend is designed as the foundation for a UI that helps patients answer the question that matters most:

> Is there an appointment available, where is it, and how soon can I book it?

The intended user experience is fast, practical, and patient-centered: enter a specialty and location, see the nearest or soonest useful options, and avoid repeated manual searches across the public platform.

## Links

- [GitHub](https://github.com/angelospk/find_doctors_server)
