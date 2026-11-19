# Roadmap

The order of work. Each phase links to its spec in `docs/specs/`, which holds its design, status and open questions. A phase without a spec is not designed yet.

Spec numbers record creation order; the order of work is the order listed here.

## Phases

Unfinished work, in order. When a phase's spec is marked `done`, move its line to "Done" in the same change.

1. Local transcription — [spec](specs/0002-local-transcription.md)
2. More audio and video formats — [spec](specs/0003-more-audio-and-video-formats.md)
3. Semantic search — [spec](specs/0004-semantic-search.md)

## Done

Newest first, with the date each phase was completed.

- 2026-11-18 — Agent workflow setup — [spec](specs/0001-agent-workflow-setup.md)

## Later (unscheduled)

Not designed yet. Treat as direction, not commitments.

### Model providers

- Ollama for text generation, local and cloud, alongside frontier APIs the user can choose instead (see decision 0007).

### Transcription providers

- whisper.cpp, for local transcription without Python, on Nvidia, AMD, Apple and Vulkan GPUs (research 0003). Open: whether Spiritor calls the user's installed `whisper-cli` or binds whisper.cpp's shared library from Go without cgo through purego, keeping Spiritor's builds pure Go, and whether the user installs that library or Spiritor downloads or embeds it, which decision 0008 doesn't allow today.
- Ollama's transcription endpoint, once its audio models mature (research 0002).

### Writing pipeline

- Modular, AI-assisted steps from recorded ideas to written content: recomposing transcripts into essays, articles, books, scripts and marketing copy in the writer's own voice.

### Transcription

- Identifying multiple speakers.
- Files over 3 hours, by splitting combined with downsampling.
- Transcript-based editing of audio and video.
- Text-to-speech.

### CLI

- Windows support.
- Structured, readable console output with a debug mode, built on `log/slog`.
- Outputs besides `txt`: verbose JSON, SRT, VTT.
- A dependency check command (ffmpeg present, write access).
