+++
title = "RationVet"
description = "Veterinary Medicine Platform with Linear Optimization"
date = "2023-01-01"
tags = ["SvelteKit", "Pocketbase", "WebAssembly", "GLPK"]
categories = ["Full Stack", "Thesis"]
+++

# RationVet

**Veterinary Medicine Platform with Diet Optimization**

## Overview

RationVet is a web application developed as my thesis project at Aristotle University of Thessaloniki. It serves the veterinary medicine field by providing tools for optimizing animal nutrition through linear programming.

The platform combines a modern SvelteKit frontend with a WebAssembly-based mathematical solver, enabling complex diet calculations directly in the browser.

## Key Features

- **Diet Optimization** - Linear programming for optimal animal nutrition
- **WebAssembly Solver** - GLPK solver compiled to WASM for browser execution
- **Responsive Design** - Works across devices for field use
- **Data Management** - Pocketbase backend for storing formulations

## Technical Implementation

| Component | Technology |
|-----------|------------|
| Frontend | SvelteKit |
| Backend | Pocketbase |
| Solver | GLPK (WebAssembly) |
| Optimization | Linear Programming |

### The GLPK Solver

The GNU Linear Programming Kit (GLPK) was compiled to WebAssembly, allowing complex linear optimization problems to run entirely in the browser without server-side computation.

This approach provides:
- **Instant results** - No network latency
- **Offline capability** - Works without internet
- **Scalability** - No server load for calculations

## Links

- [Live Demo](https://rationvetauth.vercel.app/)

## Academic Context

Developed as a thesis project (2023) for the Electrical and Computer Engineering department at AUTH. The project demonstrates the application of linear optimization techniques to real-world veterinary challenges.
