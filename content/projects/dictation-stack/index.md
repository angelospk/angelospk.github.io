---
title: DictationBar + soniox-core
description: macOS Live Dictation with AI Cleanup
weight: 9
tags:
- Go
- Swift
- WebSocket
- Streaming STT
- LLM Cleanup
categories:
- ai
---

Turns speech into clean text at the cursor in any macOS app, used every day for real work. A Swift menu-bar app streams audio to a concurrent Go server over WebSocket, and an LLM pass fixes punctuation and phrasing per user-editable profile.

## Implementation

- Native macOS Client: Swift menu-bar app with a global hotkey, live status states, transcript history, and auto-paste into whichever app was active.
- Concurrent Go Core: Streams to real-time STT over WebSocket and also transcribes uploaded audio/video files up to 512 MB.
- Tunable LLM Cleanup: Cleanup prompts and profiles are plain files, applied per request with no restart, and tuned against real transcripts with an evaluation command.
- Daily-driver Reliability: Reconnecting sessions, cleanup-failure advisories, and per-session JSONL logs, because a tool you dictate emails with cannot silently drop text.

## Links

- [soniox-core](https://github.com/angelospk/soniox-core)
- [DictationBar](https://github.com/angelospk/dictation-bar)
