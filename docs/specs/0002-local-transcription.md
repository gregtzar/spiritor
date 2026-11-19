---
status: approved # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Local transcription

## Goal

`scribe` can transcribe with faster-whisper on the user's own machine, as one of the transcription providers the user chooses from; the OpenAI Whisper API becomes another (decision 0007). `scribe` replaces the maintainer's standalone faster-whisper script, and its faster-whisper transcripts match the structure of the OpenAI API path's as closely as possible.

## Scope

- In scope: choosing a transcription provider; a faster-whisper provider; moving today's OpenAI Whisper API code behind the same choice, working as it does now; a custom vocabulary; instructions for setting up faster-whisper.
- Out of scope: other providers, such as whisper.cpp (research 0003), Ollama (research 0002) or a local server; speaker identification; output formats besides `txt`; the list of supported formats, shared by both providers (spec 0003).

## Design

Not fully designed. Decided so far:

### Providers

- `scribe` has one set of options for every provider. Each provider is a separate path behind it, with its own dependencies and its own handling of the options, and an option a provider doesn't support has no effect on it.
- The user sets up the provider; Spiritor only locates it through configuration (decision 0008).
- `SPIRITOR_SCRIBE_PROVIDER` is the only choice of provider, and decides which other options are required. With it unset or unrecognized, `scribe` stops with an error telling the user to configure one, even if another provider's options are set. Spiritor never switches providers on its own (decisions 0007 and 0008).
- Configuration follows the repo's rule: every option is an environment variable, and a flag overrides it (see "Secrets and configuration" in `docs/conventions.md`). Options so far:

  | Environment variable           | Flag             | Meaning                                                              |
  | ------------------------------ | ---------------- | -------------------------------------------------------------------- |
  | `SPIRITOR_SCRIBE_PROVIDER`     | `--provider`     | `openai` or `faster-whisper`; required                               |
  | `SPIRITOR_SCRIBE_FASTER_WHISPER_PYTHON` | `--faster-whisper-python` | The faster-whisper provider's entry point: the `python` of an environment with faster-whisper installed; required for that provider |
  | `SPIRITOR_SCRIBE_CONCURRENCY`  | `--concurrency`  | Files transcribed at once; each provider has its own default         |
  | `SPIRITOR_SCRIBE_VOCABULARY`   | `--vocabulary`   | Path to a custom vocabulary file                                     |
  | `OPENAI_API_KEY`               | none             | OpenAI's own name for its key; replaces `API_KEY_OPENAI`, a breaking change for the release notes |

### OpenAI Whisper API provider

- Today's code path, unchanged: ffmpeg downsampling to fit the API's 25 MB upload limit, and the formats ffmpeg converts.
- Concurrency defaults to 6 files transcribed at once, today's hard-coded value. The 4 downsampling workers that feed them stay a preset.
- ffmpeg and `API_KEY_OPENAI` are required only when this provider is chosen.

### faster-whisper provider

- A direct integration: Spiritor runs `<entry point> <helper> <arguments>`, where the helper is a Python script that is part of Spiritor, so its version always matches Spiritor's, and the entry point is the Python command the user configures.
- The user sets up faster-whisper and its GPU libraries in a Python environment, following `README.md`, as they do for ffmpeg (decision 0008). The entry point is that environment's own `python`; no wrapper script is needed. Facts and quirks, such as CUDA 12, go in `docs/integrations/faster-whisper.md`.
- Before importing faster-whisper, the helper loads the CUDA libraries that faster-whisper's documented pip install puts in the environment (the `nvidia.cublas` and `nvidia.cudnn` packages), using Python's `ctypes`, so the user doesn't set `LD_LIBRARY_PATH`. When those packages aren't installed, it skips this step (decision 0008). Tested on the maintainer's setup: without it, faster-whisper fails to load `libcublas.so.12`; with it, GPU transcription works.
- The helper is embedded in the Spiritor binary with Go's `embed`, so users never copy or edit it. It receives the preset settings and the file list from Spiritor, and streams each transcribed segment back as a line of JSON. Choosing files, skipping and overwriting, dry runs, progress display, formatting and writing transcripts are done in Go.
- If the entry point can't run the helper or import faster-whisper, `scribe` stops with an error that says so and points to the setup instructions.
- One helper process per `scribe` run loads the model once. Concurrency defaults to 1, one file at a time: slower than the API, the trade-off for running locally.
- No ffmpeg and no downsampling: faster-whisper decodes audio and video itself, through PyAV.
- Settings are Spiritor's preset, not user options, starting from the maintainer's tuned settings for noisy English recordings: model `large-v2` at `float32` on CUDA, language `en`, `beam_size=5`, `best_of=5`, voice activity detection on, `condition_on_previous_text=False`.
- Transcripts match the OpenAI path's structure. Today that path splits the API's text into sentences with `neurosnap/sentences` and puts a blank line between sentences. Getting faster-whisper output to match is built by comparing the same recordings through both providers.

### Custom vocabulary

- Names and terms the engine should recognize, in a plain text file, one term per line, which Spiritor joins into the engine's prompt. Passed to providers that support it: faster-whisper's `initial_prompt`, the OpenAI API's `prompt`. Unverified: OpenAI documents that Whisper only uses the last 224 tokens of a prompt, which would cap the list's length.

### Output

- Transcripts keep Spiritor's naming, `<file>.<extension>.txt`, next to the source file.

## Open questions

None.

## Done when

- `scribe` transcribes with faster-whisper when it's the configured provider, one file at a time, sending nothing over the network.
- `scribe` uses the OpenAI API only when it's the configured provider, and only then requires ffmpeg and an API key.
- With no provider configured, `scribe` stops with an error saying how to configure one, even if another provider's options are set.
- A custom vocabulary reaches both providers.
- faster-whisper transcripts follow the OpenAI path's sentence and paragraph structure on the same recordings.
- `README.md` explains how to set up and choose each provider, and where each sends audio.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
