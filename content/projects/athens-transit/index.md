---
title: Athens Transit
description: Live map, API and app for every bus and trolley in Athens
weight: 10
tags:
- Go
- GTFS-Realtime
- OpenAPI
- Svelte 5
- MapLibre
- Flutter
- Cloudflare
categories:
- data
---

Shows every OASA bus and trolley in Athens live on one map, with arrivals at every stop, a trip planner and alerts. One Go backend feeds a web map and an Android app.

**Live map:** [bus.haroldpoi.dev](https://bus.haroldpoi.dev) · **Public API, no key:** [reference](https://angelospk.github.io/athens-transit-rt/)

## The problem

OASA sends GPS positions for its buses, but the only live source is an undocumented endpoint that answers one route per request and times out for data-centre addresses. Nobody could see the whole network at once, and there was no stable API to build on.

## What I built

- **[athens-transit-rt](https://github.com/angelospk/athens-transit-rt)** (Go): polls every active route under one request budget (at most 6 per second in total), matches each vehicle to a scheduled GTFS trip and serves a keyless JSON API plus GTFS-Realtime feeds. It started as a Go port of [foivospro/athens-gtfs-realtime](https://github.com/foivospro/athens-gtfs-realtime).
- **[athens-transit-map](https://github.com/angelospk/athens-transit-map)** (Svelte 5, MapLibre): the whole city live, up to five followed lines in colourblind-safe colours, a trip planner, stop alerts by web push or Telegram bot, and the typical bus speed of each street.
- **[athens-transit-app](https://github.com/angelospk/athens-transit-app)** (Flutter): nearby stops, arrivals, a planner, alerts that keep running with the app closed, a lock-screen live card and home-screen widgets.

## Tradeoffs

- **Backend at home, not in the cloud.** OASA timed out for five cloud providers, so the backend runs in Docker on a home machine behind a Cloudflare Tunnel. The map shows a banner when it cannot reach it.
- **One cache for everyone.** Cloudflare keeps each answer until the line's next refresh, so more users add no load on OASA. Lines nobody watches can be up to about 2.5 minutes behind.
- **Static frontend.** The map is on GitHub Pages, with no server code to run or secure. The heavy GTFS processing (225 MB) runs in GitHub Actions; the server only downloads a ready snapshot.

## Results

- The GTFS-Realtime feeds pass the MobilityData validator with 0 errors.
- Buses move along their route between GPS fixes. On held-out recorded fixes, the chosen motion model cut the median position error from 225 m to 122 m.

## Links

- [Live map](https://bus.haroldpoi.dev)
- [API reference](https://angelospk.github.io/athens-transit-rt/)
- [Backend](https://github.com/angelospk/athens-transit-rt) · [Map](https://github.com/angelospk/athens-transit-map) · [App](https://github.com/angelospk/athens-transit-app)
