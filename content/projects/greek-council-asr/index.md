---
title: Greek Council Speech Recognition
description: Greek speech recognition with reproducible evaluation
weight: 10
tags:
- Python
- Whisper
- LoRA / PEFT
- PyTorch
- CTranslate2
- Serverless GPU
- Statistical evaluation
categories:
- ai
---

Fewer hand corrections for the volunteers who review Greek council transcripts: a Whisper LoRA model trained and published for OpenCouncil during Google Summer of Code 2026. Built the evaluation that decides whether a new model earns its place in production. Deliverable submitted in August 2026; research continues.

## The problem

Council transcripts need human correction. Model changes must preserve speech and be evaluated consistently before they can justify a change to the transcription workflow.

## What I built

Curated correction pairs, trained Whisper LoRA adapters, built a review interface and compared systems on fixed audio through a controlled decoder. The August 23 held-out evaluation covered 391 windows from 117 meetings. The newer adapter reduced deletion rate from 0.0525 to 0.0313, but its WER difference of -0.0040 had a 95% confidence interval crossing zero, so it was not promoted.

## Implementation

- Published a Whisper LoRA model and built reproducible evaluation with fixed audio, model hashes and meeting-clustered confidence intervals.
- Evaluated two adapters on 391 held-out windows from 117 meetings; reduced deletion rate from 5.25% to 3.13%, while the overall WER change remained inconclusive.
- Kept the incumbent adapter when the replacement failed its predeclared promotion rule; documented the tradeoff between deletions, insertions and substitutions.
- Built dataset review tooling and a GPU serving path with word timestamps and model-version metadata.

## Links

- [Model](https://huggingface.co/opencouncil/whisper-large-v3-el-council-lora)
- [GitHub](https://github.com/eellak/gsoc2026-opencouncil-stt)
