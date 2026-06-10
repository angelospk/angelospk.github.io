+++
title = "OpenCouncil"
description = "Active Maintainer & GSoC 2026 Contributor"
date = "2026-02-01"
tags = ["Python", "Whisper / ASR", "PyTorch", "Next.js", "React", "TypeScript"]
categories = ["fullstack"]
weight = 10
+++

# OpenCouncil

**Active Maintainer & Google Summer of Code 2026 Contributor**

## Overview

Active maintainer on OpenCouncil by Schema Labs (schemalabz/opencouncil), the open-source
platform that makes Greek municipal council meetings searchable and accountable. As a Google
Summer of Code 2026 contributor, I'm fine-tuning an open-source Greek speech-to-text model so
the people who review council transcripts have fewer errors to fix by hand.

### The Problem

Council meeting transcripts are produced by automatic speech recognition, and reviewers
spend a lot of time correcting the same recurring errors before the text is usable.

### The Approach

Fine-tune an open-source ASR model (Whisper) on municipal council speech, add LLM
post-correction, and measure the error rate before and after, alongside ongoing maintenance
work on the Next.js platform.

## Key Work

- **GSoC 2026 — Greek ASR fine-tuning:** fine-tuning Whisper on council speech with LLM
  post-correction to lower transcription error rates and manual review effort.
- **Platform maintenance:** resolved severe Next.js hydration errors, improved Turbopack
  compile times, and shipped UI for unauthenticated workflows.
- **Review tooling:** built a dataset-exploration and review-UI prototype to compare error
  rates before and after fine-tuning.

## Links

- [GSoC Repo](https://github.com/eellak/gsoc2026-opencouncil-stt)
- [Platform Repo](https://github.com/schemalabz/opencouncil)
