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

OpenCouncil transcribes Greek municipal council meetings with ASR (Automatic Speech Recognition), and then someone fixes the AI's mistakes by hand. The team spends several hours on each meeting to get those corrections right, so the final transcript matches the audio. That led us to a question: can we fine-tune an open ASR model on OpenCouncil's own data and cut down the time spent on manual corrections? I'm Angelos, and this is the problem I'm working on for my Google Summer of Code project.

[Google Summer of Code](https://summerofcode.withgoogle.com/) lets students and early-career developers spend a summer working on an open-source project. Applicants choose up to three participating organizations and submit a project proposal explaining what they want to build and how they'll approach it. The org decides which candidates it wants to work with, and Google approves the final projects. My proposal was accepted, so I'm spending three months working remotely on OpenCouncil, with the project's maintainers as my mentors.

## What already exists

There are open and closed models you can use for ASR. We benchmarked several of them on older council meetings for which we already had carefully corrected, audio-aligned transcripts. The team settled on a closed model, Scribe v2 from ElevenLabs. It performed best, producing the fewest transcription errors on real OpenCouncil data. I'll explain further down how that error rate is measured.

{{< figure src="01-benchmark-wer.png" alt="Benchmarking results on OpenCouncil data" caption="Benchmarking results on OpenCouncil data" >}}

The best open ASR model is called Whisper, from OpenAI. Out of the box, with no special Greek training, it gives a middling result. One Whisper model fine-tuned for Greek performed particularly poorly on our recordings: its error rate was roughly three times as high as the original Whisper model's.

In our benchmark, Whisper got roughly 15 words wrong out of every 100, compared with 13 for the best closed model. That's the small gap we want to close. It isn't that Whisper doesn't know Greek. What it struggles with is the reality of council meetings: background noise, overlapping speech, legal terminology, names, decision numbers, and references to the Government Gazette. That's where every general-purpose system trips, and that's where my project comes in: fine-tuning an open model on real speech from Greek municipal councils.

## How OpenCouncil transcribes

{{< figure src="02-pipeline.png" alt="How the project works" caption="How the project works" >}}

OpenCouncil takes a meeting recording and produces a transcript, identifies the speakers, and organizes the discussion by topic, so you can search what was said and who said it. It goes through three stages:

1. **ASR model:** produces the initial transcript.

2. **Cleanup with a language model (LLM, like ChatGPT):** catches common grammar, syntax, and punctuation mistakes, fixes homophones, and corrects council members' names when the previous model got them wrong, while preserving the original meaning.

3. **Human correction:** at the end, a person listens to the whole meeting and fixes whatever slipped through.

The LLM cleanup helps, but it has a limit that bothered me from the start: it never hears the recording; it only sees the ASR output. If the ASR misheard a name and wrote something unrelated, the LLM has nothing to go on. The real win is improving the "ear" itself.

And here's the nice part: all those changes, from the LLM and from people, get saved. Over time, OpenCouncil has accumulated around 300,000 corrections. We decided to try training the existing open model on them, so it learns to get them right on its own. That's why we're building our own dataset.

## How the models are scored

To know whether anything actually improved, we want a single number we can compare. That's WER (Word Error Rate): the share of words that come out wrong, where lower is better.

It's a blunt instrument. It treats a minor function-word slip as seriously as getting someone's surname wrong. But it's used everywhere in the literature, so we can compare any model or provider directly. And since each evaluation uses newer council meetings the model hasn't seen before, the raw score naturally shifts from one test set to the next. So the honest metric isn't a bare score. It's how much the fine-tuned model improves over the original.

{{< figure src="04-review-tool.png" alt="Review tool" caption="The tool for picking corrections to train on" >}}

## How we'll train the model

To train, you need lots of clean audio-text pairs: a clip of audio and the text that tells the model "this is how I want you to write it." We already have those inside OpenCouncil, just mixed together.

Along the way, the team and I built a small tool: a web app where we listen to a short audio clip while viewing the original transcription and the corrected version side by side. For each audio-text pair, we mark it Include or Exclude. This lets us narrow hundreds of thousands of stored corrections down to a smaller set that's genuinely useful for fine-tuning.

{{< figure src="03-error-distribution.png" alt="Error distribution" caption="The error distribution: selected utterances vs. the whole dataset" >}}

Rather than treat every correction as the same, we sorted them into groups:

* **Pure acoustic errors:** the model heard one word as another, dropped a word, or wrote one that was never said.

* **Names:** people, places, bodies, acronyms like DEYA. These matter especially in council meetings, where the same names and terms come up again and again.

* **"Cosmetic" corrections:** punctuation, capitalization, small style tweaks that don't change what was said.

**Note:** the first two groups teach the model to hear better. The cosmetic ones don't, and about a third of the corrections were punctuation or capitalization, so we weighted them down. They teach the "ear" nothing.

Some corrections were slightly out of sync, so we also did small manual fixes to the timing, so the audio lines up exactly with the text. While fixing the alignment, we also found several tricky pronunciation cases that should help the model.

### What we gathered in the first month

* For a month, we reviewed corrections every day. More than 10,000 corrections were manually reviewed.

* We kept the best, around 5,000.

* The dataset includes speech from 544 speakers across ten cities.

Unlike many speech datasets built from scripted or crowdsourced recordings, ours comes from real municipal meetings and includes corrections made by people who listened to the original audio. We'd love to publish it on Hugging Face, but we're still working out how to do that responsibly, given the privacy constraints.

## Spoiler: a first, early fine-tune

We've already run a first, deliberately rough fine-tuning experiment: Whisper large-v3 with LoRA, which updates only around 0.5% of the model's parameters and lets us train on a single GPU, on the selected corrections, with two whole cities held out for testing.

The early signs were encouraging enough to keep going. I won't share numbers yet, since the sample was small, but the first signal is positive. In July I'm focused on the fine-tuning process itself.

## What's next

* **Data split:** the final test set will be recent council meetings (from June onward, while the project started in May). That keeps the test clean, with no risk of the model seeing something it already saw in training.

* **Dataset balance:** to the 5,000 selected difficult corrections we'll add another 5,000 examples sampled from the broader dataset, plus around 20,000 correctly transcribed utterances that needed no correction, so the model doesn't "forget" everyday speech.

* **Diarization ("who speaks when"):** we're looking into whether better speaker separation also helps the transcription itself.

* **Overlapping speech:** we're adding a label for segments where another person can be heard speaking in the background. How do you train Whisper for that? It's an open question.

* **Alternatives:** if there's time left, we want Whisper to generate two or three alternative transcriptions for uncertain words, each with a confidence score, so the next stage (the LLM) knows where to look.

---

[1] The benchmark is an internal run from June 10, 2026.
