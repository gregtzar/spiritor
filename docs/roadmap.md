# Roadmap

The order of work. Each phase links to its spec in `docs/specs/`, which holds its design, status and open questions. A phase without a spec is not designed yet.

Spec numbers record creation order; the order of work is the order listed here.

## Phases

Unfinished work, in order. When a phase's spec is marked `done`, move its line to "Done" in the same change.

None yet. The next phase gets a spec first.

## Done

Newest first, with the date each phase was completed.

- 2026-11-18 — Agent workflow setup — [spec](specs/0001-agent-workflow-setup.md)

## Later (unscheduled)

Not designed yet. Treat as direction, not commitments.

### Model providers

- Ollama as the primary provider, local and cloud, with frontier APIs as an explicit opt-in (see decision 0004).
- Local speech-to-text, so transcription no longer requires OpenAI.

### Writing pipeline

- Modular, AI-assisted steps from recorded ideas to written content: recomposing transcripts into essays, articles, books, scripts and marketing copy in the writer's own voice.

### Transcription

The feature list in `README.md` ("Roadmap Features") is the user-facing version of this list.

- Identifying multiple speakers.
- Files over 3 hours, by splitting combined with downsampling.
- More audio formats, and video files.
- Transcript-based editing of audio and video.
- Text-to-speech.

### CLI

- Windows support.
- Structured, readable console output with a debug mode, built on `log/slog`.
- Outputs besides `txt`: verbose JSON, SRT, VTT.
- A dependency check command (ffmpeg present, write access).
