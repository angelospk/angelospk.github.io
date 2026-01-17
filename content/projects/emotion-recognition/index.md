+++
title = "Emotion Recognition Addon"
description = "Real-time Emotion Detection with Machine Learning"
date = "2021-01-01"
tags = ["Python", "OpenCV", "scikit-learn", "Machine Learning", "SVM"]
categories = ["AI", "Academic"]
+++

# Emotion Recognition Addon

**Real-time Emotion Detection for Video Conferencing**

## Overview

This academic project presents the design and implementation of a machine learning model for recognizing human emotions from continuous video streams. The ultimate goal was to create a tool that could be used in video conferencing platforms for real-time emotion analysis.

Developed as a university project in 2021, the system divides the problem into two stages: face detection and emotion classification.

## Problem Decomposition

1. **Face Detection** - Locate the face within an image frame
2. **Emotion Classification** - Classify the detected face into an emotion category

## Technical Implementation

### Face Detection

- **Cascade Classifier** - Haar cascade for face localization
- **Preprocessing** - Resize to 48px, Gaussian blur, grayscale conversion

### Feature Extraction

- **Local Binary Patterns (LBP)** - Texture descriptor for facial features
- **Bag of Words (BoW)** - Alternative approach studied in literature review

### Classification

| Component | Technology |
|-----------|------------|
| **Algorithm** | SVM/LinearSVC |
| **Optimization** | Grid Search CV |
| **Categories** | Positive, Neutral, Negative |

### Real-time Integration

The system was integrated with the IRC protocol for real-time result display during video sessions, demonstrating practical application in communication platforms.

## Dataset

Training used an extensive, commonly accepted dataset for emotion recognition:
- Standardized facial expressions
- Multiple subjects
- Three-category classification (positive/neutral/negative)

## Technologies Used

| Technology | Purpose |
|------------|---------|
| Python | Core implementation |
| OpenCV | Face detection, image processing |
| scikit-learn | SVM, Grid Search, model evaluation |
| IRC Protocol | Real-time result streaming |

## Links

- [GitHub](https://github.com/beyondTheMyth/Emotion-Recognition-Addon)

## Academic Context

This project was developed as part of my studies at Aristotle University of Thessaloniki. It explored machine learning approaches to emotion recognition, comparing methods like LBP and Bag of Words, and implementing a practical solution using SVMs.

The research included a comprehensive literature review of existing approaches, detailed methodology documentation, and evaluation of results across all stages of development.
