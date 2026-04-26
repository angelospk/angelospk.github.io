+++
title = "UniTrip.gr"
description = "SvelteKit booking platform for organized youth travel"
date = "2026-01-01"
tags = ["SvelteKit", "Svelte 5", "TypeScript", "PocketBase", "Viva Payments", "Cloudflare", "Tailwind CSS"]
categories = ["Full Stack", "Travel"]
weight = 10
+++

# UniTrip.gr

**Booking platform for organized youth trips**

## Overview

UniTrip.gr is a full-stack web application for discovering and booking organized youth trips. It covers the public website, the booking funnel, booking management, payments, referrals, QR/UTM campaigns, and admin operations.

One of its key product features is shareable group booking: after a booking is created, it can be shared so another traveler can join later as an additional participant. This supports real-world group travel behavior, where not everyone commits at the same moment.

## Key Features

### Public Booking Experience

- **Trip Discovery** - Homepage, trip listing, and detail pages for available trips
- **Multi-Step Booking Flow** - Departure city, traveler count, participant details, and dynamic pricing
- **Shareable Bookings** - Additional travelers can join an existing booking after the initial reservation
- **Booking Page** - Persistent booking route with trip, traveler, and payment information
- **PDF Confirmation** - Booking confirmation generation for travelers
- **Informational Pages** - FAQ, contact, terms, privacy policy, passenger rights, and participation terms

### Payments and Operations

- **Viva Payments Integration** - Online payment flow for bookings
- **Payment Verification** - Booking page checks payment state after user return to avoid sync issues
- **Youth Pass Support** - Special handling for Youth Pass payment amounts
- **Discord Notifications** - Contact forms, confirmed bookings, referral channels, city channels, and daily pending-payment summaries

### Admin Experience

- **Realtime Admin Panel** - Trips, bookings, travelers, payments, referrals, campaigns, and exports
- **Trip Dashboard** - Fully paid traveler count and departure-city breakdown per trip
- **Campaign Management** - QR campaign links under `/c/<slug>` with UTM attribution
- **Local Admin Cache** - Fast navigation and responsive admin state using Svelte state and PocketBase subscriptions

## Technical Implementation

| Area | Stack |
|------|-------|
| Frontend | Svelte 5, SvelteKit 2, TypeScript |
| Styling | Tailwind CSS 4, lucide-svelte, GSAP |
| Backend/Data | SvelteKit server routes, PocketBase |
| Validation | Zod |
| Payments | Viva Payments |
| Documents/Utilities | jsPDF, qrcode, xlsx, isomorphic-dompurify |
| Testing | Vitest, Testing Library, jsdom |
| Runtime | Cloudflare adapter, service worker static asset caching |

## Performance and Reliability

The application uses a service worker for safe static asset caching while deliberately avoiding runtime caching for booking and admin data. That keeps repeat visits fast without risking stale operational data in sensitive flows.

Admin state is kept live with PocketBase realtime subscriptions, so operators can work with bookings and payments without manual refreshes.

## Links

- [Live Site](https://unitrip.gr)
