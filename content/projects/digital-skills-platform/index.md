---
title: Interactive Digital Skills Platform
description: Practical digital-skills learning for older adults
weight: 9
tags:
- SvelteKit
- Svelte 5
- TypeScript
- SQLite / Turso
- Drizzle ORM
- Vitest
- Playwright
- inlang
categories:
- fullstack
---

Gives older adults a safe place to practise the phone and computer tasks they need, from scanning a QR code to spotting a scam SMS. 218 hands-on lessons across Windows, Mac, Android and iPhone, in Greek, with a home screen that says where they stopped last time.

## The problem

Digital training for this age group is usually a video of somebody else
clicking, which gives the learner nothing to do. And somebody who comes back
after three weeks meets a menu of two hundred lessons with no indication of
where they were.

## What I built

218 lessons across Windows, Mac, Android and iPhone tracks, each one an
interaction the learner performs, with the platform accepting the realities
of the audience: no password, deep links that survive login, progress that
cannot be demoted by adding content, and a home screen that answers "what
was I doing" before it offers anything else.

## Implementation

- Unplayable lessons cannot ship: Every seeded lesson's configuration is parsed by a contract test, including disabled ones, so a lesson whose config no longer matches its component fails CI rather than opening blank in front of a learner.
- A phone that behaves like a phone: Android and iOS tracks with working settings, camera QR scanning, a gov.gr link check, screenshots via the real button chord, and force-closing a stuck app; a Mac track built around the window-close versus quit distinction.
- Scam recognition as practice: 28 realistic Greek scenarios across email, SMS, Viber and voice calls, each one naming the specific signal that gives it away rather than marking the answer right or wrong.
- Built for coming back: The home page opens with where the learner stopped, how long ago in plain words, and two buttons: continue, or repeat the last one together with whoever is helping. There is no streak and no overdue notice; a three-week gap is stated and not scored.
- No password, and no way to lose your progress by waiting: Sign-in is a name and no password, sessions are HMAC-signed cookies, deep links survive the login step, and 'basic route completed' is recorded separately from 'all lessons completed' so adding lessons never demotes somebody who had finished.
