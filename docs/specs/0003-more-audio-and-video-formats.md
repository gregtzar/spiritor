---
status: approved # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# More audio and video formats

## Goal

`scribe` accepts the common audio and video formats writers record in, not only `mp3`, `aac` and `wav`, transcribing a video's audio track, with the same formats for every transcription provider. It also adds Spiritor's first automated tests.

## Scope

- In scope: one list of supported formats shared by both providers in spec 0002; recognizing and checking files before transcription; video files, through their audio track; tests for both.
- Out of scope: choosing among several audio tracks; transcript-based editing of audio or video; files over 3 hours.

## Design

### Supported formats

One list in `scribe`, shared by both providers, matching the maintainer's faster-whisper script: `mp3`, `wav`, `m4a`, `flac`, `aac`, `ogg`, `wma`, `mp4`, `mkv`, `avi`, `mov`, `flv` and `webm`. It replaces the OpenAI path's list of three. Each provider must handle every format on it: the OpenAI provider through ffmpeg, the faster-whisper provider through PyAV.

### Recognizing a file

1. The extension selects candidates, as now, so a pattern such as `scribe *.*` skips files that aren't media.
2. Before a candidate is processed, `ffprobe` confirms it has an audio track, validating the input at the boundary. A file that fails is reported and skipped; the rest of the batch continues.

### Video files

- The OpenAI path's ffmpeg conversion already drops video (`-vn`) and mixes audio to one channel, so a video becomes Ogg Opus like any audio file.
- With several audio tracks, ffmpeg's default choice is used.
- The downsampling chooses its target from the source's bitrate. For a video, `ffprobe` currently reports the whole file's bitrate, video included; it must use the audio track's bitrate instead. Untested until built.

### Tests

- Go's standard `testing` package, run by `go test` in `build/check.sh`.
- Tests generate a short sample of each format with ffmpeg at run time, so no media files are committed, and check recognition (including a renamed non-media file failing the probe) and the OpenAI path's conversion to Ogg Opus within the size cap.
- CI needs ffmpeg; the workflow installs it if GitHub's runner doesn't already have it.
- The faster-whisper path's decoding of each format can't run in CI, which has no faster-whisper environment. The maintainer checks it on their machine, through a test that runs only when `SPIRITOR_SCRIBE_FASTER_WHISPER_PYTHON` is set and is skipped otherwise.

## Open questions

None.

## Done when

- `scribe` recognizes every format on the list and transcribes it with both providers, including video files.
- A file with no audio track, or a renamed non-media file, is reported and skipped without stopping the batch.
- The tests above run in `build/check.sh` and CI, and the faster-whisper format test passes on the maintainer's machine.
- `README.md` lists the supported formats.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
