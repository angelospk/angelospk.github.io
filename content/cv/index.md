+++
title = "Curriculum Vitae"
description = "Angelos Papamichail — software engineering and applied AI"
+++

# Angelos Papamichail

[Email](mailto:angelos.papamichail@gmail.com) · [GitHub](https://github.com/angelospk) · [LinkedIn](https://www.linkedin.com/in/angelos-papamichail/)

## Summary

Software engineer and MEng Electrical and Computer Engineering graduate who builds tools for operational problems: travel bookings, repetitive data entry and transcript review. I work in Python, Go and TypeScript, from requirements and implementation through deployment. Google Summer of Code 2026 contributor and OpenCouncil maintainer.

## Experience

### AI Engineer (GSoC 2026) | OpenCouncil (Schema Labs / GFOSS)

2026-05 - Present

- Published a Greek Whisper LoRA model and built dataset review, training and reproducible ASR evaluation tooling.
- Compared adapters on 391 held-out windows from 117 meetings; documented lower deletion rates without claiming a conclusive overall WER improvement.
- Resolved Next.js hydration failures, improved Turbopack compilation and built unauthenticated platform workflows.

### Freelance Software Engineer | Independent: UniTrip.gr, Ardas Youth Festival

2026-03 - Present

- Delivered UniTrip.gr with trip discovery, group reservations, Viva payment verification and a back office for bookings, travellers and exports.
- Built shareable reservations that let additional travellers join after payment, and preserved QR/UTM attribution through checkout.
- Delivered EventLens for Ardas Youth Festival: browser-side image conversion, queued uploads during Wi-Fi interruptions and a manager-approved venue slideshow.

### Digital Skills Trainer | Social Inov

2025-11 - Present

- Teach older adults essential digital skills through guided, hands-on practice.

### Digital Marketing & Social Media Trainer | ΣΑΕΚ ΔΥΠΑ Ορεστιάδας

2025-10 - Present

- Develop practical teaching materials for digital marketing and social media classes.

### Data Entry & Process Automation | Agricultural Cooperative of Didymoteicho

2025-05 - 2025-10

- Built a Vue.js browser extension for batch entry and validation, with an estimated 40% reduction in data-entry time on frequently used workflows.
- Automated year-over-year data transfer, saving approximately five minutes per application.
- Translated ERP validation errors into practical instructions with an LLM and documented workflows in an internal wiki.

### Night Auditor | TUI Magic Life Plimmiri by Atlantica

2024-05 - 2024-11

- Developed 'Magic Life Hotel Map', a mobile-first PWA for guest navigation using Leaflet.js.
- Created Python automation scripts to speed up check-in data entry by 3x.
- Maintained 'Protel Vault', an Obsidian-based knowledge base for standardizing PMS procedures.

### Software Developer | VELTIO

2020-08 - 2020-10

- Configuration και optimization Docker containers
- Ticket management και bug resolution

## Selected projects

Professional delivery and personal projects are identified separately below.

### [UniTrip.gr](/projects/unitrip/)

Full-stack booking platform for organized youth trips, covering public trip 
discovery, multi-step bookings, payment flows, admin operations, referrals, 
QR/UTM campaigns, and booking sharing after the initial reservation.

Technologies: SvelteKit, Svelte 5, TypeScript, PocketBase, Viva Payments, Cloudflare, Tailwind CSS.

### [EventLens](/projects/eventlens/)

Pipeline for live events: a photographer uploads photos from the venue, a manager
reviews them, and a public wall (projector or TV) plays the confirmed photos of
the night in a loop together with sponsor messages. Built for the Ardas youth
festival and deployed.

Technologies: SvelteKit, Cloudflare Workers, D1, R2, IndexedDB, AVIF.

### [Greek Council Speech Recognition](/projects/greek-council-asr/)

Built Greek speech-recognition training and evaluation tooling for OpenCouncil through Google Summer of Code 2026. Published a Whisper LoRA model and compared adapters on held-out council recordings to guide transcription decisions. Submitted the GSoC deliverable in August; research continues separately.

Technologies: Python, Whisper, LoRA / PEFT, PyTorch, CTranslate2, Serverless GPU, Statistical evaluation.

### [photo2stitch](/projects/photo2stitch/)

Built a desktop workflow that converts photographs into machine-embroidery stitch files for a non-technical user. Colour reduction and directional fills produce the stitch plan; a printable job sheet carries the thread colours that the DST file cannot store.

Technologies: Python, OpenCV, NumPy, scikit-learn, PyInstaller, Cloudflare Workers.

### [FindDoctors Aggregator Server](/projects/find-doctors-server/)

Built a Go service and Greek search interface to compare public health appointment availability across hospitals and primary-care centres. Results are ordered by earliest availability and can be filtered by distance. Booking takes place on the official portal; live searches require an authenticated upstream session.

Technologies: Go, REST API, Concurrent Workers, TypeScript Types, TDD.

### [Interactive Digital Skills Platform](/projects/digital-skills-platform/)

Built an interactive learning platform for older adults to practise everyday computer and phone tasks safely. Simulated Windows, Mac, Android and iPhone workflows include Greek scam-recognition exercises, progress tracking and a clear way to resume after a break.

Technologies: SvelteKit, Svelte 5, TypeScript, SQLite / Turso, Drizzle ORM, Vitest, Playwright, inlang.

### [Carpool](/projects/carpool/)

A carpooling app for one Greek prefecture, currently in active development:
a Go backend and an Expo app for people who already drive the same route and
would rather take somebody with them. Drivers publish the commutes they drive
anyway, passengers post where they need to get to, and the backend asks a
driver whose route passes close enough. Not ride-hailing: no dispatching, no
in-app payments, and the driver always accepts explicitly.

Technologies: Go, PostgreSQL / PostGIS, OSRM, React Native, Expo, TypeScript, Docker, MapLibre, Push Notifications.

### [Project Secretary](/projects/project-secretary/)

Built a Python service that retrieves related issues and pull requests across GitHub repositories so maintainers can find prior work before repeating it. Local embeddings and a graph-aware reranker separate duplicate candidates from overlap and useful context.

Technologies: Python, SurrealDB, Embeddings / fastembed, GitHub API, Vector Search.

### [Roomly](/projects/roomly/)

Built a shared-household app that brings bills, chores and events into one place. Expense records name who paid, settlements require recipient confirmation, and filtered bills and a monthly calendar help housemates see what still needs attention.

Technologies: TypeScript, React, TanStack Start, Supabase / PostgreSQL, Row-Level Security, pg_cron, Tailwind CSS, i18next.

### [Brain](/projects/brain/)

A personal knowledge system where spoken brain-dumps and dropped files become
Markdown notes that stay the source of truth, readable in Obsidian, indexed with
local embeddings and queryable in natural language. It answers chronology-aware
questions like "what occupied me last week", extracts the tasks hiding inside a
ramble, and asks before it acts on any of them.

Technologies: Python, LanceDB, Local embeddings (Ollama), RAG, LLM routing, Telegram Bot API, pytest.

### [DictationBar + soniox-core](/projects/dictation-stack/)

A dictation stack I use every day: a native Swift menu-bar app captures the
microphone, streams audio to a concurrent Go server over WebSocket, and pastes
the cleaned transcript at the cursor. An LLM cleanup pass fixes punctuation and
phrasing per user-editable profile.

Technologies: Go, Swift, WebSocket, Streaming STT, LLM Cleanup.

## Education

- Master of Engineering, Electrical and Computer Engineering, Aristotle University of Thessaloniki (2014-2023); GPA 7.33.

- Smart Building Programming Technician (Level 1), IDEA Lifelong Learning Center (2024-2024).

## Technical skills

Python, Go, JavaScript/TypeScript, SQL; SvelteKit, React, Vue.js, Next.js; PostgreSQL/PostGIS, SQLite, Redis; Docker, Linux, Git, CI/CD, Cloudflare; speech recognition, LoRA fine-tuning, retrieval, embeddings and agent orchestration.

## Certifications

- [Back End Development and APIs](https://www.freecodecamp.org/certification/fcc9b8f8ac1-2559-429e-9ec5-7ba6d0a58c65/back-end-development-and-apis) — freeCodeCamp
- [Data Analysis with Python](https://www.freecodecamp.org/certification/fcc9b8f8ac1-2559-429e-9ec5-7ba6d0a58c65/data-analysis-with-python-v7) — freeCodeCamp
- [JavaScript Algorithms and Data Structures](https://www.freecodecamp.org/certification/fcc9b8f8ac1-2559-429e-9ec5-7ba6d0a58c65/javascript-algorithms-and-data-structures) — freeCodeCamp
- [Scientific Computing with Python](https://www.freecodecamp.org/certification/fcc9b8f8ac1-2559-429e-9ec5-7ba6d0a58c65/scientific-computing-with-python-v7) — freeCodeCamp
- [Data Scientist Professional Certification](https://www.codecademy.com/profiles/angelospk/certificates/7dec503730a448c8b22bb251ada403f3) — Codecademy
- [Front-End Engineer Professional Certification](https://www.codecademy.com/profiles/angelospk/certificates/2682884a0719474f96407efe432fdd87) — Codecademy

## Languages

Greek: native. English: C2. German: B2.

Last updated: 7 September 2026.
