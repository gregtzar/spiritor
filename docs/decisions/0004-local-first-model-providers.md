---
status: accepted
date: 2026-11-18
---

# Local-first model providers through Ollama

## Context

Spiritor processes a writer's own voice recordings and drafts, which are often private and unpublished. The first version sends audio to OpenAI's Whisper API. The project's aim is a privacy-centric toolkit that writers can trust with unpublished work.

## Decision

- Ollama is the primary model provider: local models first, and Ollama Cloud for larger models.
- Frontier model APIs (such as OpenAI and Anthropic), by API key or subscription, are supported as an explicit opt-in, never a default or a fallback.
- No user content leaves the machine unless the user has configured a remote provider for that task. A missing or unrecognized provider setting fails closed: Spiritor stops with an error rather than choosing a remote provider.

## Reasons

- Running locally keeps user content on the user's machine, which is the project's main promise.
- Ollama runs many open models behind one API and also offers cloud models through the same API, so one integration covers local and larger hosted models.
- Frontier models remain useful for quality-sensitive tasks, so they stay available to users who choose them.

## Alternatives considered

- Frontier APIs as the default — simplest to build and often the best quality, but sends user content to a third party by default.
- Embedding inference in the binary — avoids a separate install, but duplicates what Ollama already does well and ties Spiritor to one runtime.

## Consequences

- Each provider is integrated behind one Spiritor interface, so commands don't depend on a specific provider (see "Structure" in `docs/conventions.md`).
- The existing Whisper transcription, which requires OpenAI, is the exception until a local speech-to-text option is added; its data retention is stated in `README.md`.
- Each provider's data retention terms are recorded in `docs/integrations/` and summarized for users in `README.md`.
