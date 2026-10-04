---
title: Aloud
description: Voice Assistant That Turns Speech into Actions
weight: 10
tags:
- Go
- TypeScript
- SvelteKit
- WebSocket
- Streaming STT
- LLM Integration
categories:
- ai
---

Lets someone book a Greek public-health appointment by speaking: streaming speech-to-text feeds a deterministic, fully tested engine that fills the real search form. It runs on top of the FindDoctors aggregator; two more demos cover legal intake and restaurant ordering. The orchestration behind the LLM front end is scripted code that can be tested, rather than another prompt.

## The problem

Voice interfaces usually stop at dictation. Turning "βρες μου καρδιολόγο κοντά
μου την άλλη εβδομάδα" into an actual search, with slots, areas, and dates
resolved correctly, needs a deterministic engine behind the microphone.

## What I built

Built a scripted, testable orchestration engine in TypeScript first, then ported
it to Go for production. The Go port is verified against the TypeScript
reference with a 32-scenario golden harness that produces byte-identical output.

## Implementation

- Deterministic Voice Engine: Intent extraction, specialty/area/date resolution, and form merging run scripted and fully testable, with no API key required.
- Go Port with Golden Parity: voice-core reimplements the TS engine in Go; parity is enforced by ported unit tests plus a 32-scenario golden harness, byte-identical to the reference.
- Resilient Sessions: Per-session actors with ordered turns, dedupe, bounded event logs, and reconnect-resume over a versioned WebSocket contract; go test -race clean.
- Real Data Behind the Voice: Plugs into the FindDoctors Go aggregator and soniox-core streaming STT, so the demo searches real availability.
- Optional LLM Layer: Claude can rephrase assistant replies into more natural Greek without touching the deterministic flow.

## Links

- [GitHub](https://github.com/angelospk)
