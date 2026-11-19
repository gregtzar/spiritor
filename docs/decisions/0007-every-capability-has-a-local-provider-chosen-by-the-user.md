---
status: accepted
date: 2026-11-19
---

# Every capability has a local provider, and the user chooses

## Context

Decision 0004 made Ollama Spiritor's primary model provider. Ollama doesn't cover every capability Spiritor needs: the strongest local transcription engine for noisy English recordings, faster-whisper, runs outside it. Users also mix where models run, for example a local Ollama install serving a model from Ollama Cloud. Supersedes decision 0004.

## Decision

- Every capability (transcription, embeddings, text generation) supports at least one provider that runs on the user's machine.
- The user chooses and configures the provider for each capability, local or remote. Spiritor never switches providers on its own: there is no fallback from one provider to another, and a missing or unrecognized provider setting stops with an error.
- Ollama is the local provider for language models (embeddings and text generation), including models it serves from Ollama Cloud.
- Providers sit behind one Spiritor interface per capability, so commands never depend on a specific provider.

## Reasons

- Always offering a local option keeps the privacy promise without limiting users to it.
- Each capability can use the best local engine for it, rather than only what Ollama runs.
- Where content goes is the user's decision, made explicitly. Never switching providers means content never reaches a provider the user didn't choose.

## Alternatives considered

- Ollama for everything (decision 0004) — rules out faster-whisper for transcription.
- Local providers only — excludes users who choose frontier models for quality.
- Falling back to another provider when the chosen one fails — content could reach a provider the user didn't choose.

## Consequences

- Each provider's facts and quirks are recorded in `docs/integrations/`, and `README.md` tells users where each provider sends their content and how long it's kept.
- Users set up local engines themselves, following the README's instructions, as they do for ffmpeg.
