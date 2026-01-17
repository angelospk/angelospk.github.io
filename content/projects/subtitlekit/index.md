+++
title = "SubtitleKit"
description = "AI-Enhanced Subtitle Processing Toolkit"
date = "2025-01-01"
tags = ["Python", "AI/LLM", "PyPI", "Desktop App"]
categories = ["Data", "Tools"]
+++

# SubtitleKit

**Comprehensive Python Library for Subtitle Processing and Correction**

[![PyPI version](https://badge.fury.io/py/subtitlekit.svg)](https://badge.fury.io/py/subtitlekit)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)

## Overview

SubtitleKit is a comprehensive Python library and desktop application for subtitle processing, synchronization, and correction. It's designed to streamline subtitle workflows, particularly for translation projects involving LLM integration.

Available as a PyPI package, CLI tool, desktop application, and Google Colab notebook.

## Key Features

- **Merge & Sync** - Combine subtitle files with automatic synchronization
- **Fix Overlaps** - Detect and correct timing issues and overlaps
- **Apply Corrections** - Apply text corrections from JSON files
- **LLM Integration** - Generate optimized JSON for translation workflows
- **Cross-Platform** - Desktop GUI for Windows, macOS, Linux
- **Colab Ready** - Works seamlessly in Google Colab notebooks
- **Bilingual UI** - English and Greek interface support

## Installation

```bash
pip install subtitlekit
```

## Usage

### As a Library

```python
from subtitlekit import merge_subtitles, fix_overlaps, apply_corrections

# Merge subtitle files
merge_subtitles("original.srt", ["helper.srt"], "output.json")

# Fix timing overlaps
fix_overlaps("input.srt", "reference.srt", "fixed.srt")

# Apply corrections from JSON
apply_corrections("input.srt", "corrections.json", "output.srt")
```

### CLI Usage

```bash
# Merge subtitles
subtitlekit merge --original original.srt --helper helper.srt --output output.json

# Fix overlaps
subtitlekit overlaps --input input.srt --reference ref.srt --output fixed.srt

# Apply corrections
subtitlekit corrections --input input.srt --corrections fixes.json --output corrected.srt
```

### Google Colab

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/drive/1lvdSX7aNhNknLs9laxfTeKdK_xNUvLOY?usp=sharing)

```python
from subtitlekit.ui import show_ui
show_ui(lang='en')  # or 'el' for Greek
```

## Technical Details

### Merge Output Format

Optimized JSON format for LLM translation workflows:

```json
{
  "id": 1,
  "t": "00:00:11,878 --> 00:00:16,130",
  "trans": "Original text to translate",
  "h1": "Helper text (language 1)",
  "h2": "Helper text (language 2)"
}
```

### Corrections JSON Format

```json
[
  {
    "id": 1,
    "rx": "text to find",
    "sb": "replacement text",
    "rate": 8,
    "type": "grammar"
  }
]
```

## Links

- [GitHub](https://github.com/angelospk/SubtitleKit)
- [PyPI](https://pypi.org/project/subtitlekit/)

## Use Case

This project grew out of my hobby of subtitling. SubtitleKit automates the tedious parts of subtitle work—fixing timing issues, merging helper tracks, and applying AI-generated corrections—letting me focus on the creative aspects of translation.
