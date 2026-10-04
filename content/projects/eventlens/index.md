---
title: EventLens
description: Event Photos, from Camera to the Venue Screen
weight: 8
tags:
- SvelteKit
- Cloudflare Workers
- D1
- R2
- IndexedDB
- AVIF
categories:
- fullstack
---

Gets a festival's photos from the photographer's camera to the venue screen the same night, with a manager approving each one first. Photos are converted and watermarked in the browser, uploads queue through Wi-Fi drops, and a public wall loops the approved set with sponsor messages. Built for the Ardas Youth Festival and deployed.

## Implementation

- In-browser Processing: Photos are converted to AVIF, watermarked with the event logo, and color-graded in the browser before upload.
- Offline-tolerant Uploads: An IndexedDB queue holds photos when the venue Wi-Fi drops and retries when it comes back.
- Live Public Wall: Full-screen slideshow that picks up newly confirmed photos automatically, mixed with sponsor slides.
- Small, Cheap Infrastructure: Static SvelteKit app on GitHub Pages plus one Cloudflare Worker with D1 and R2.
