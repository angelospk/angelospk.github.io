---
title: photo2stitch
description: Photo-to-embroidery desktop workflow
weight: 10
tags:
- Python
- OpenCV
- NumPy
- scikit-learn
- PyInstaller
- Cloudflare Workers
categories:
- ai
---

Lets an embroidery operator turn a customer's photograph into a machine-ready stitch file without a designer or three separate tools. Colour reduction and directional fills produce the stitch plan, and a printable job sheet carries the thread order the DST format cannot store. Python desktop app for a non-technical user.

## The problem

An embroidery operator needs a usable stitch file and the correct thread order, without manually moving the design through several tools.

## What I built

Combined photo tracing, palette reduction, region consolidation and stitch export with a desktop interface. Added a printable colour sheet and packaging for macOS and Windows. Physical sew-out validation remains a separate acceptance step.

## Implementation

- Built a Python image-processing pipeline with colour quantisation, region merging and directional stitch fills.
- Added a printable job sheet with the thread order and colour information absent from DST files.
- Used paired-seed experiments to distinguish algorithm changes from k-means variation.
- Implemented desktop packaging, signed update manifests and a Cloudflare licence gate; physical output still needs sew-out validation.
