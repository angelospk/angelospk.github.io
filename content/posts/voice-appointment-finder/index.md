+++
title = "Finding a doctor's appointment by voice, in Greek"
description = "A private voice front end for the Greek public e-appointment system: streaming speech-to-text, an LLM that extracts a structured intent, and a 64-utterance eval that found real routing bugs."
date = "2026-10-14"
tags = ["voice", "LLM", "speech-to-text", "evaluation", "latency", "Greek NLP", "Go", "TypeScript"]
categories = ["machine-learning"]
author = "Angelos Papamichail"
+++

Greece has a public system for booking appointments with doctors in public hospitals, health centres and doctors contracted with the national insurer (ΕΟΠΥΥ). It works, but finding the *earliest* free slot near you means filling in a form, picking a specialty from a long official list, choosing a region, and repeating the search for each kind of provider. On a phone, that is a lot of tapping.

I built a voice front end for it. You say something like *«πονάει το γόνατό μου, θέλω ραντεβού στη Θεσσαλονίκη την άλλη εβδομάδα»* ("my knee hurts, I want an appointment in Thessaloniki next week") and the app shows the nearest units and doctors with the earliest free dates. Booking still happens on the official portal.

The code is private, and the app runs only for me and a few people I share demo links with. Below is how it is built, how I measured it, and what the measurements changed.

{{< notice info "Demo video" >}}
**[PLACEHOLDER: 60-second demo video goes here.]** A spoken search from start to results, recorded on a phone.
{{< /notice >}}

## Architecture

{{< figure src="architecture.svg" width="460" alt="Pipeline: browser, streaming speech-to-text, intent extractor, deterministic engine, Go aggregator over the Ministry catalogue" caption="The pipeline. The LLM only fills in a structured intent; everything after it is ordinary code." >}}

1. Streaming speech-to-text: audio goes from the browser to [Soniox](https://soniox.com/) over a WebSocket. Partial transcripts show while you talk, and the end of speech triggers the next step.
2. Intent extractor: an LLM turns the Greek sentence into a JSON intent: specialty, place, date window, time of day, public or private provider, urgency, or a follow-up action such as "the first one" or "closer". Short navigation turns ("back", "the second one") go through a cheaper, faster classifier first.
3. Engine: plain TypeScript, no model. It maps the intent onto the Ministry's exact specialty names, geocodes the place, resolves dates against today in Athens, and decides what the screen does next: results, slots, a clarifying question, or the on-duty emergency hospitals.
4. Aggregator: a Go service I wrote earlier ([FindDoctors Aggregator](/projects/find-doctors-server/)) searches the Ministry catalogue concurrently and ranks results by earliest date and distance.

The LLM is good at reading messy speech and bad at knowing that the official name of an orthopaedist is spelled a particular way in a government database. So the model produces a small, typed intent, and deterministic code does the lookups. When a case fails, I can see whether the intent was wrong or the lookup was.

Server logs never contain what the user said.

## Measure

Before changing anything, I wrote an eval: 64 Greek utterances, written the way I expect people to say them.

- 41 single requests: symptoms, specialties, places, relative and explicit dates, times, public or private, urgency.
- 6 noisy or ambiguous ones: misspellings, two symptoms at once, a bare «θέλω γιατρό» ("I want a doctor").
- 12 follow-ups on a results screen: corrections, "the first one", "closer".
- 5 follow-ups on a slots screen: "at 12", "on Friday".

Each case lists the fields the user should end up seeing after the engine has run: the exact Ministry specialty, the place, the date window, the outcome, the selected unit, and so on. That is 192 scored checks. The eval runs the same extractor and engine as production, with real geocoding and the real Ministry specialty list. Only the Ministry search itself is stubbed, so runs are repeatable and don't load the live service.

The baseline was 168/192 fields correct (87.5%), with 45 of 64 cases fully right. Intent latency (end of speech to intent) was p50 626 ms, p95 1.3 s.

The specialty field was the worst, at 39/49, and several of its misses were bugs I had already seen in production:

- Sore throat or ear went to internal medicine. The extractor produced the common Greek abbreviation for ENT, and that abbreviation doesn't appear in the Ministry's list, so matching fell through to the default, a general internist.
- Knee or back pain also went to internal medicine. Greek has two spellings of "orthopaedic", and the model used the one the Ministry doesn't.
- "Nephrologist" and "thoracic surgeon" went to urology.
- "Family doctor" and "endocrinologist" also landed on internal medicine.

A demo where I say "cardiologist in Athens" would never hit these, and each of them points a person at the wrong specialty.

## Fix

The fixes were small:

- Specialties are now matched by word stems against the real Ministry names, so the model's abbreviation or spelling no longer decides the result. In the eval, this fixed all ten specialty misses.
- The extractor now gets today's date in Athens and the current screen. "The first one" means something only when the model knows a results list is showing, and "next Tuesday" needs a today.
- New prompt rules: "after six" means 18:00, how people say public versus private, place-name spelling, "the week after", references copied verbatim, and "which hospital is on duty" as an action of its own.

I also changed how providers are called. The extractor used to try LLM providers one after another, and a hanging provider cost the full timeout before the next one started. Now it hedges: the next provider starts after 800 ms without an answer, or at once if one fails, the first valid answer wins, and the others are cancelled. A unit test pins this down: a primary that never answers loses to the backup in under 1.5 s, where the old code needed the full 3 s timeout first.

## Re-measure

| Run | Fields | Cases fully right | Intent p50 / p95 |
|---|---|---|---|
| Baseline | 168/192 (87.5%) | 45/64 | 626 / 1328 ms |
| After the fixes | **188/192 (97.9%)** | **61/64** | 639 / 1242 ms |

Specialty went from 39/49 to 49/49. Latency stayed about the same, as expected: the fixes were in the prompt and the matching, not the call path. The engine adds 3 ms at p50.

Three cases still fail, and I'm keeping them in the set:

- "Which hospitals are on duty today in Thessaloniki" gets a normal search instead of the on-duty list.
- "On Tuesday, no, Wednesday morning" keeps Tuesday and drops the morning. Corrections inside one sentence are hard.
- "My stomach and my head hurt, in Athens" correctly asks which specialty, but forgets the place.

## Where the time goes

Intent extraction takes about 0.6 seconds, so it isn't the slow part. I pulled 14 days of aggregator logs (534 calls) to find out what is:

| Call | p50 | p90 | max |
|---|---|---|---|
| Unit search (hospitals and health centres) | 3.5 s | 10.0 s | 26.4 s |
| Doctor search | 0.2 s | 2.4 s | 5.7 s |

The unit search was the slow part, and the cause was in my own aggregator. To find the earliest date, it probed every unit in the whole prefecture, 20 at a time, and only *then* applied the user's radius. Unit dates weren't cached (doctor dates were), and when a search widened its radius it repeated the full scan at each step. A search with no radius over all of Attica hit the 30-second timeout.

The fix applies the radius before probing, probes at most the 60 nearest units, and caches unit dates for 15 minutes, as doctor dates already were. It also recovers from a stalled upstream connection without a restart. It shipped, but I haven't yet repeated the 14-day latency measurement with it, so I don't have an "after" number to show for this part.

While I worked on this, the voice bar also started saying what it is doing: "I heard you…", "Understanding…", "Searching N units…".

## Trade-offs

- The backend runs on free tiers, and that makes it fragile. During the eval, one provider started asking for payment, another refused free-tier access to its classifier model, and Groq's free tier allows about three calls a minute. Groq ended up answering almost every turn. A second user in the same minute falls through to Gemini, whose daily quota ran out after about 150 eval calls. The hedge helps with a slow provider, not with a missing one. A full eval run costs about 150k Groq tokens, so I run it at most once a day, or the live demo loses its LLM.
- One of my benchmark comparisons is invalid. I tried to measure the hedge against a deliberately hanging provider, but the backup provider's daily quota ran out halfway through, so the "after" run had nothing to fall back to. The unit test covers the mechanism. The end-to-end number has to wait for a day with quota.
- The eval is synthetic. I wrote the 64 utterances myself, because there is no recorded traffic to draw from: the server doesn't log what people say. So the set reflects my guesses about how people phrase things.
- Using an LLM only for extraction costs one model call per turn, but most failures show up as a specific wrong field that the eval can check.

## What's next

- A fast path for navigation has just shipped: short turns like "back" or "the second one" now go to a small classifier first. On a 39-phrase bench it got 37 right, and at confidence ≥ 0.7 it got 32 of 32. It answers in about 0.3 s, against about 0.6 s for the LLM.
- Re-measure the unit search on two weeks of logs with the aggregator fix.
- Pay for capacity on one LLM provider, so the whole voice search no longer depends on one free API key.
- Small latency wins: load the engine's dependencies while the extractor runs, and cancel the Ministry call when the user leaves the page.
- Fix the three remaining failures, starting with corrections inside a sentence.
