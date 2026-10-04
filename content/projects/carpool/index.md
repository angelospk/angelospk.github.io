---
title: Carpool
description: Region-Scoped Ride Sharing, Self-Hosted
weight: 9
tags:
- Go
- PostgreSQL / PostGIS
- OSRM
- React Native
- Expo
- TypeScript
- Docker
- MapLibre
- Push Notifications
categories:
- mobile
---

Fills empty seats on commutes people in one Greek prefecture already drive: drivers publish their routes, passengers post where they need to be, and a driver whose route passes nearby gets asked. There is no dispatching and no in-app payment; the driver always accepts explicitly. Go backend and Expo app, in active development.

## The problem

Outside the big cities there is nothing to match a passenger with the
neighbour who drives that road every morning, and the platforms that exist
are built around a commission that makes a 40 km commute not worth listing.

## What I built

Built the whole stack to run on one small machine: Go, PostGIS and a local
OSRM extract in Docker, about 330 MiB for the lot, so the running cost of
a regional community is a mini PC rather than a routing API bill. Money is a
suggestion the app computes and caps, never something it moves.

## Implementation

- Two-Stage Geospatial Matching: A direction- and order-aware PostGIS filter narrows candidate routes, then OSRM computes the incremental detour against the driver's actual itinerary; matched drivers are asked sequentially by push, with timeouts, rather than auctioned.
- Cost the Car Actually Has: Consumption is derived from the vehicle's registration document (fuel, engine size, CO₂) instead of typed, and the suggested share is capped so a full car cannot turn a commute into a profit.
- Recurring Routes as Templates: A weekday commute is published once and materialises into occurrences; each departure carries the car it actually goes out in, so editing a route cannot silently change the plate a passenger is standing at the kerb looking for.
- Safety Decisions in the Schema: Age gate, moderated bios, closed preference vocabulary, per-trip chat, mutual ratings, plate revealed only after a seat is accepted, and retention periods enforced by scheduled jobs rather than by policy text.
- Verified End to End: vet, staticcheck and race-clean concurrency packages, 293 app tests, and a fourteen-step scenario that runs from a fresh database against real PostGIS and real OSRM: publish, request, ask, accept, chat, confirm, rate.
