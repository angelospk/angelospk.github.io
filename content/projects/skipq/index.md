+++
title = "SkipQ"
description = "QR Ordering & Hospitality Operations Platform"
date = "2026-01-01"
tags = ["Go","Svelte","SPA","Local-first","Analytics","QR Ordering"]
categories = ["fullstack"]
weight = 10
+++

# SkipQ

**QR ordering and hospitality operations platform**

## Overview

QR ordering system for restaurants, beach bars, clubs, canteens, festivals, 
and fast-service food businesses. The goal is to reduce service friction, 
support self-ordering, and give venues live operational insights.

### The Problem
During peak hours, customers struggle to get served and staff spend too much 
time on order intake instead of preparation and service quality.

### The Solution
Designing a configurable ordering platform with customer self-ordering, live 
order tracking, waiter calls, menu analytics, stock-aware availability, and 
both cloud and local deployment options.


## Product Goals

- **Reduce Peak-Hour Pressure** - Let customers self-order when staff are overloaded
- **Improve Customer Clarity** - Show live menu availability and realistic preparation estimates
- **Support Different Venue Types** - Restaurants, clubs, beach bars, canteens, festivals, and quick-service food businesses
- **Keep Deployment Flexible** - Run hosted in the cloud or locally when internet reliability or ownership matters
- **Unlock Better Decisions** - Collect useful analytics around menu performance, customer preferences, demand, and operations

## Planned Features

- **QR Self-Ordering** - Customers order from their own phones without installing an app
- **Table Account Concept** - Multiple orders can belong to the same table/session
- **Live Order Tracking** - Customers can follow order state after submission
- **Waiter Call** - Simple customer request flow for staff attention
- **Configurable Store Rules** - Each venue controls safety measures, visible options, and customer actions
- **Live Menu Updates** - Availability and estimated delays can respond to stock, demand, and kitchen load
- **Reservations** - Optional reservation system for venues that need it
- **Occupancy Signals** - Potential public live occupancy view outside the venue
- **AI Voice Dictation** - Future assistant for quickly finding and ordering items by voice

## Technical Direction

| Area | Direction |
|------|-----------|
| Backend | Go |
| Frontend | Svelte SPA |
| Deployment | Cloud-hosted or local/on-premise |
| Operating Model | Configurable per venue |
| Data | Menu analytics, order flow metrics, preference signals |

The local-first option is important for venues that want operational control or need the system to keep working when internet connectivity is unreliable.

## Startup Context

SkipQ is being prepared as a startup idea and is planned for submission to the CapsuleT hospitality/startup competition.

## Status

Upcoming. No public live demo yet.
