---
status: draft # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# More audio and video formats

## Goal

`scribe` accepts the common audio and video formats writers record in, not only `mp3`, `aac` and `wav`, transcribing a video's audio track.

## Scope

- In scope: more audio formats; video files, transcribed from their audio track; recognizing a file's format.
- Out of scope: transcript-based editing of audio or video; files over 3 hours.

## Design

Not designed yet. Known so far:

- `avmedia/transform.go` already names `ogg`, `flac`, `mp4`, `mpeg`, `mpga`, `m4a` and `webm`, but only `mp3`, `aac` and `wav` are allowed.
- `ffmpeg` is already a run-time dependency, and it can read nearly every common format and extract a video's audio track.

## Open questions

- Which formats to support. Blocks the design.
- How a file's format is recognized: by its extension, as now, or by probing its contents with `ffprobe`, which validates the input at the boundary. Blocks the design.
- Whether files still go through `ffmpeg` before transcription depends on the engine spec 0002 chooses. Blocked by spec 0002.

## Done when

- `scribe` transcribes every supported format, including video files.
- `README.md` lists the supported formats.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
