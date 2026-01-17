+++
title = "Trading Automation Toolkit"
description = "Portfolio Management Server"
date = "2026-01-01"
tags = ["Go", "REST API", "WebSocket", "Chi Router"]
categories = ["Backend", "Automation"]
+++

# Trading Automation Toolkit

**Go-based HTTP API Server for Programmatic Trading**

## Overview

A Go-based trading automation toolkit that provides an authenticated HTTP API server for programmatic stock trading. The system supports market, limit, stop, and stop-limit orders while carefully mimicking browser behavior to ensure reliability.

The project evolved from a CLI tool into a full HTTP API server, enabling integration with other systems and automated trading strategies.

## Key Features

- **Authenticated HTTP API** - Bearer token authentication with Chi router
- **Multiple Order Types** - Market, Limit, Stop, and Stop-Limit orders
- **Browser Mimicry** - Matches browser headers and follows validate → order sequence
- **Real-time Data** - WebSocket integration for live market data
- **Fractional Shares** - Support for fractional share quantities

## Technical Implementation

### Architecture

| Component | Technology |
|-----------|------------|
| **Language** | Go 1.22+ |
| **Router** | github.com/go-chi/chi/v5 |
| **WebSocket** | github.com/gorilla/websocket |
| **Auth** | Bearer token (API_KEY) |
| **Config** | godotenv for environment management |

### API Endpoints

The server exposes RESTful endpoints for trading operations:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/orders/market/buy` | POST | Place market buy order |
| `/api/orders/market/sell` | POST | Place market sell order |
| `/api/orders/limit/buy` | POST | Place limit buy order |
| `/api/orders/limit/sell` | POST | Place limit sell order |
| `/api/orders/stop/*` | POST | Stop/Stop-limit orders |

### Security Model

- **Internal Auth** - Static API_KEY in Authorization header
- **External Auth** - Session cookies (refreshed periodically)
- **Request Mimicry** - Headers match browser exactly
- **Validation** - Follows platform's validate → order flow

### Client Pattern

Separate clients for each integration:
- `TradingClient` - Order execution
- `FinnhubClient` - Real-time market data via WebSocket

## Development Approach

- **TDD** - Test-driven development for reliability
- **Integration Tests** - API clients with mocked HTTP responses
- **Validation Testing** - Ensures browser behavior is mimicked correctly

## Constraints

- **Authentication** - Session cookies require periodic refresh
- **Rate Limiting** - Respects platform rate limits
- **Fractional Quantities** - Handles decimal share amounts (e.g., 0.1 shares)

## Use Case

This toolkit enables automated portfolio management and trading strategies that would be tedious to execute manually. All operations are performed through a secure, local API server.
