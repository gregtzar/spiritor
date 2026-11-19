---
status: draft # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Local transcription

## Goal

`scribe` transcribes with a speech-to-text engine on the user's own machine by default, so audio never leaves it. The OpenAI Whisper API stays available as an explicit opt-in (see decision 0004).

## Scope

- In scope: a local transcription engine; choosing between it and the OpenAI API in `scribe`, local by default; reading `API_KEY_OPENAI` only when the API is chosen, rather than in `transcribe`'s `init` for every command.
- Out of scope: speaker identification, new output formats, new input formats (spec 0003).

## Design

Not designed yet. Constraints so far:

- Choosing the provider fails closed: if the local engine is missing or misconfigured, `scribe` stops with an error and never falls back to the API (decision 0004).
- The OpenAI client stays behind the same Spiritor interface as the local engine, so `scribe` doesn't depend on either (see "Structure" in `docs/conventions.md`).

## Open questions

- Which local engine, and how Spiritor calls it. Candidates: faster-whisper (a Python library, installed on the maintainer's machine), whisper.cpp (a C++ command-line tool and HTTP server), a local OpenAI-compatible server wrapping either, or Ollama if it now runs speech-to-text models. Needs research; blocks the design.
- Does the user install the engine, or does Spiritor install or manage it? Blocks the design.
- How the user chooses the provider and model: flags, environment variables or a config file. Blocks the design.
- Is downsampling still needed? It exists for the OpenAI API's 25 MB upload limit. Blocks the design of `avmedia`'s role.

## Done when

- `scribe` transcribes with the local engine when no provider is chosen, sending nothing over the network.
- `scribe` uses the OpenAI API only when explicitly chosen, and only then requires `API_KEY_OPENAI`.
- `README.md` explains both, including each one's data retention.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
