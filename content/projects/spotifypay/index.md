+++
title = "SpotifyPay"
description = "Spotify Family Cost Splitter"
date = "2024-01-01"
tags = ["React", "Google Apps Script", "GitHub API"]
categories = ["Full Stack", "Personal"]
+++

# SpotifyPay

**Automated Cost Splitting for Spotify Family Subscriptions**

## Overview

SpotifyPay automates the calculation of how much each member of a Spotify Family plan owes. It handles price changes over time and sends email notifications to family members, eliminating the awkwardness of manually tracking and requesting payments.

## Key Features

- **Automatic Cost Calculation** - Accounts for subscription price changes
- **Email Notifications** - Reminds members of outstanding balances
- **Secure Architecture** - Separates sensitive data from public data
- **Auto-sync** - Commits data changes automatically to GitHub

## Technical Implementation

### Architecture

The project uses a split-data architecture for security:

| Data Type | Storage | Access |
|-----------|---------|--------|
| Emails | Private Google Sheet | Script only |
| Names, Amounts | Public GitHub JSON | React app |

This ensures email addresses remain private while allowing the React frontend to display balances.

### Data Flow

1. **Google Sheet** - Master data entry (prices, members)
2. **Google Apps Script** - Processes data, sends emails
3. **GitHub API** - Commits sanitized JSON
4. **React App** - Displays current balances

### Technologies

| Component | Technology |
|-----------|------------|
| Frontend | React |
| Backend | Google Apps Script |
| Storage | Google Sheets + GitHub JSON |
| Automation | Apps Script Triggers |

## How It Works

1. When Spotify changes prices, I update the Google Sheet
2. The script calculates each member's new balance
3. Data is committed to GitHub as JSON (without emails)
4. Members can view their balance on the React app
5. Email reminders are sent periodically

## Links

- [GitHub](https://github.com/angelospk/spotifypay)

## Use Case

Managing a Spotify Family plan among friends can be awkward. Who paid how much? When did the price change? This project automates all the tracking, making it painless to split costs fairly.
