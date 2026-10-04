---
title: FindDoctors Aggregator Server
description: Public appointment discovery across health providers
weight: 10
tags:
- Go
- REST API
- Concurrent Workers
- TypeScript Types
- TDD
categories:
- backend
---

Finds the earliest public-health appointment in one search instead of one provider at a time, across hospitals and primary-care centres on finddoctors.gov.gr. A Go service ranks results by soonest slot and distance; booking stays on the official portal, and live searches need an authenticated upstream session.

## The problem

People need to compare availability across provider types and regions without repeating each search manually.

## What I built

A bounded worker pool searches providers concurrently. The response distinguishes failed checks from empty calendars, and the bundled interface links to the official booking portal. First-time setup still needs an end-to-end user trial.

## Implementation

- Built a concurrent Go API with bounded fan-out, retries and Prometheus metrics for upstream failures.
- Added a Greek search interface with specialty, location and distance filters, served directly from the Go binary.
- Kept failed availability checks visible with scanOk and a null date, so an outage is not reported as no appointments.
- Documented the session-bridge dependency and deprecated an endpoint whose upstream returned no useful results.

## Links

- [GitHub](https://github.com/angelospk/find_doctors_server)
