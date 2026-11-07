---
title: Staseis (staseis.gr)
description: Live public-transport map, API and app for Greek cities
weight: 10
aliases:
- /projects/athens-transit/
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

Shows buses, trolleys, metro, tram and suburban rail live on one map, with arrivals at every stop, a trip planner and alerts. Live in Athens and Thessaloniki. One Go backend feeds a web map and an Android app. The project started in October 2026 as Athens Transit and became Staseis («Στάσεις», stops) when it grew past Athens.

**Live map:** [staseis.gr](https://staseis.gr) · **Public API, no key:** [reference](https://angelospk.github.io/staseis-rt/)

## The problem

Greek transit operators send GPS positions for their buses, but only through undocumented endpoints. In Athens, OASA's endpoint answers one route per request and times out for data-centre addresses. Nobody could see a whole network at once, and there was no stable API to build on.

## What I built

- **[staseis-rt](https://github.com/angelospk/staseis-rt)** (Go): one binary, one instance per city, so a problem in one city never stops another. It polls every active route under one request budget (in Athens, at most 6 per second in total), matches each vehicle to a scheduled GTFS trip and serves a keyless JSON API plus GTFS-Realtime feeds. The Athens part started as a Go port of [foivospro/athens-gtfs-realtime](https://github.com/foivospro/athens-gtfs-realtime).
- **[athens-transit-map](https://github.com/angelospk/athens-transit-map)** (Svelte 5, MapLibre): the web map at staseis.gr, with a page per city, stop and line, up to five followed lines in colourblind-safe colours, a trip planner, stop alerts by web push or Telegram bot, and per-city statistics.
- **[athens-transit-app](https://github.com/angelospk/athens-transit-app)** (Flutter): nearby stops, arrivals, a planner, alerts that keep running with the app closed, a lock-screen live card and home-screen widgets.

## Cities and sources

| City | Live sources |
| --- | --- |
| Athens | OASA telematics (buses, trolleys), STASY timetable (metro, tram), railway.gov.gr (Proastiakos) |
| Thessaloniki | OASTH telematics, OSETH as a second vehicle source, GTFS from data.gov.gr |

## Tradeoffs

- **Athens backend at home, not in the cloud.** OASA timed out for five cloud providers, so the Athens instance runs in Docker on a home machine behind a Cloudflare Tunnel. Thessaloniki runs on a VPS. The map shows a banner when it cannot reach a backend.
- **One cache for everyone.** Cloudflare keeps each answer until the line's next refresh, so more users add no load on the operator. Lines nobody watches can be up to about 2.5 minutes behind.
- **Static frontend.** The map is a static site, with no server code to run or secure. The heavy GTFS processing (225 MB for Athens) runs in GitHub Actions; the server only downloads a ready snapshot.

## Results

- The GTFS-Realtime feeds pass the MobilityData validator with 0 errors.
- Buses move along their route between GPS fixes. On held-out recorded fixes, the chosen motion model cut the median position error from 225 m to 122 m.
- Each city has public pages for arrival accuracy and the slowest lines.

## Links

- [Live map](https://staseis.gr)
- [API reference](https://angelospk.github.io/staseis-rt/)
- [Backend](https://github.com/angelospk/staseis-rt) · [Map](https://github.com/angelospk/athens-transit-map) · [App](https://github.com/angelospk/athens-transit-app)
