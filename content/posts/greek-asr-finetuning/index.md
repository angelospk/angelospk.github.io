+++
title = "Teaching a machine to hear a Greek municipal council"
description = "OpenCouncil's dataset, the open ASR model we're building, Google Summer of Code, and why any of it matters."
date = "2026-07-21"
tags = ["ASR", "Whisper", "fine-tuning", "GSoC", "OpenCouncil", "Greek NLP"]
categories = ["machine-learning"]
author = "Angelos Papamichail"
+++

*This is an English adaptation of a post I originally wrote in Greek for the Schema Labs Substack. The original is here: [Μαθαίνοντας μια μηχανή να ακούει ένα ελληνικό δημοτικό συμβούλιο](https://schemalabs.substack.com/p/asr-finetuning).*

---

OpenCouncil transcribes Greek municipal council meetings with ASR (Automatic Speech Recognition), and then someone fixes the AI's mistakes by hand. The team spends several hours per council to get those corrections right, so the final transcript actually matches the audio. That's where the question comes from: can we fine-tune, meaning take an open ASR model and let it learn from OpenCouncil's own data, so the correction step gets shorter? I'm Angelos, and this is the problem I'm working on for my Google Summer of Code project.

[Google Summer of Code](https://summerofcode.withgoogle.com/) lets students and early-career developers spend a summer working on an open-source project. You pick up to three organizations from the list of partners and send a written proposal for how you'd solve one of their problems. The org decides which candidates it wants to work with, and Google approves the final projects. Mine got accepted, so I have a three-month remote internship, with the OpenCouncil maintainers as my mentors.

## What already exists

There are open and closed models you can use for ASR. After benchmarking them on older council meetings, ones where we already have the corrected, audio-faithful text, the OpenCouncil team settled on a closed model, Scribe v2 from ElevenLabs. It did best: fewest transcription errors on OpenCouncil's real data. I'll explain further down how that error rate is measured.

{{< figure src="01-benchmark-wer.png" alt="Benchmarking results on OpenCouncil data" caption="Benchmarking results on OpenCouncil data" >}}

The best open ASR model is called Whisper, from OpenAI. Out of the box, with no special Greek training, it gives a middling result. One Greek fine-tune we tried didn't cope with our audio at all. It did 3x worse than plain Whisper.

On the test we ran, Whisper got 15 words wrong out of 100; the best closed model, 13. That's the small gap we want to close. It isn't that Whisper doesn't know Greek. What it's missing is tolerance for the room's noise, for people talking over each other, for legal jargon, names, decision numbers, and gazette references. That's where every general-purpose system trips, and that's where my project comes in: fine-tuning an open model on real speech from Greek municipal councils.

## How OpenCouncil transcribes

{{< figure src="02-pipeline.png" alt="How the project works" caption="How the project works" >}}

OpenCouncil takes the audio of a meeting and produces a transcript, speakers, and topics, so you can search what was said and who said it. It goes through three stages:

1. **ASR speech recognition model:** writes the first draft of the text.

2. **Cleanup with a language model (LLM, like ChatGPT):** catches common grammar, syntax, and punctuation mistakes, fixes homophones, and corrects council members' names when the previous model got them wrong, all without changing the meaning.

3. **Human correction:** at the end, a person listens to the whole meeting and fixes whatever slipped through.

The LLM cleanup helps, but it has a limit that bothered me from the start: it doesn't hear the audio, it sees the text the ASR produced and edits that. If the ASR misheard a name and wrote something unrelated, the LLM has nothing to go on. The real win is improving the "ear" itself.

And here's the nice part: all those changes, from the LLM and from people, get saved. About 300,000 corrections have piled up. We decided to try training the existing open model on them, so it learns to get them right on its own. That's why we're building our own dataset.

## How the models are scored

To know whether anything actually improved, we want a single number we can compare. That's WER (Word Error Rate): the share of words that come out wrong, where lower is better.

It's a blunt instrument. It counts writing "and" for "an" as heavily as a wrong surname. But it's used everywhere in the literature, so we can compare any model or provider directly. And since each run tests the model on newer councils it hasn't seen, the raw number is expected to shift every time. So the honest metric isn't a bare score. It's how much the fine-tuned model improves over the original.

{{< figure src="04-review-tool.png" alt="Review tool" caption="The tool for picking corrections to train on" >}}

## How we'll train the model

To train, you need lots of clean audio-text pairs: a clip of audio and the text that tells the model "this is how I want you to write it." We already have those inside OpenCouncil, just mixed together.

Along the way, the team and I built a small tool: a web app where we listen to a few seconds of audio while the before and after of a correction sit side by side. For each audio-text pair we choose Include or Exclude, filtering the hundreds of thousands of pairs OpenCouncil keeps down to a smaller set we think is more "instructive" for fine-tuning.

{{< figure src="03-error-distribution.png" alt="Error distribution" caption="The error distribution: selected utterances vs. the whole dataset" >}}

Rather than treat every correction as the same, we sorted them into groups:

* **Pure acoustic errors:** the model heard one word as another, dropped a word, or wrote one that was never said.

* **Names:** people, places, bodies, acronyms like DEYA. For a council these matter and repeat.

* **"Cosmetic" corrections:** punctuation, capitalization, small style tweaks that don't change what was said.

**Note:** the first two groups teach the model to hear better. The cosmetic ones don't, and about a third of the corrections were punctuation or capitalization, so we weighted them down. They teach the "ear" nothing.

Some corrections were slightly out of sync, so we also did small manual fixes to the timing, so the audio lines up exactly with the text. That's how we turned up various pronunciation cases that will definitely help the model.

### What we gathered in the first month

* The review ran daily for a month. More than 10,000 corrections have gone through human judgment.

* We kept the best, around 5,000.

* The material covers 544 speakers across 10 different cities.

The dataset has something you don't often find open: real human corrections, not crowd-sourced studio readings. We'd love to have published it on Hugging Face, but for privacy reasons we're still working out the right way to do that.

## Spoiler: a first, early fine-tune

We already ran a first fine-tune, early and rough: whisper-large-v3 with LoRA (which trains just 0.5% of the weights and fits on a single GPU), on the selected corrections, with two whole cities held out for testing.

The early signs were encouraging enough to keep going. I won't share numbers yet, since the sample was small, but the first signal is positive. In July I'm focused on the fine-tuning process itself.

## What's next

* **Data split:** the final test will be the recent councils (from June on, while the project started in May). That keeps the test clean, with no risk of the model seeing something it already saw in training.

* **Dataset balance:** to the 5,000 selected hard corrections we'll add as many again drawn from across the sample, plus around 20,000 ordinary utterances that had no errors, so the model doesn't "forget" everyday speech.

* **Diarization ("who speaks when"):** we're looking into whether better speaker separation also helps the transcription itself.

* **Overlapping speech:** we're adding a field for the moments when a second person is heard in the background. How do you train Whisper for that? It's an open question.

* **Alternatives:** if there's time left, we want Whisper to keep two or three alternative versions of what it heard on a hard word, along with a confidence score, so the next stage (the LLM) knows where to look.

---

[1] The benchmark is an internal run from June 10, 2026.
