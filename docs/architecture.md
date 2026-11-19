# Architecture

What exists and runs today. Nothing in this file is planned: designs for upcoming work live in `docs/specs/` (ordered in `docs/roadmap.md`), and the reasons behind decisions live in `docs/decisions/`.

When a change implements part of a spec, describe the result here in the same change, matching what was actually built.

Last reviewed: 2026-11-18.

## Current state

A Go CLI, `spiritor`, with one command, `scribe`, which batch-transcribes audio files through the OpenAI Whisper API. The same code is importable as the Go module `github.com/gregtzar/spiritor`. One release exists, `v0.1.0`, published under the earlier module path `github.com/spiritorai/spiritor` (see decision 0005). No Ollama or other model provider is integrated yet.

## Repo layout

- `spiritor.go`: package `main`. Parses the CLI with Kong (`--debug`, and the `scribe` command), validates file arguments, and runs the `scribe` worker pools: 4 downsample workers feed 6 transcription workers. Writes each transcript next to its source file as `<file>.<format>`, skipping files that already have one unless `-f` is given.
- `avmedia/`: the `Media` type (path, size, duration, bitrate, probed through `ffmpeg`), downsampling to Ogg Opus under a size cap, and typed errors.
- `ffmpeg/`: runs the `ffmpeg` and `ffprobe` binaries installed on the user's machine.
- `transcribe/`: the OpenAI Whisper client. Uploads a file to `https://api.openai.com/v1/audio/transcriptions`, parses the transcript, and formats it. Only `txt` output is supported. It reads `API_KEY_OPENAI` in `init` and exits if it is missing.
- `scribe/`: the downsample and transcription workers.
- `utils/`: sentence splitting, using `github.com/neurosnap/sentences`.
- `neurosnaptrainingdata/`: the English training data for the sentence splitter, embedded with `embed`.
- `vendor/`: vendored dependencies (Kong, sentences).
- `build/build_go.sh`: cross-compiles release binaries for Linux, macOS and Windows into `build/`; the binaries are ignored by Git.

## External dependencies at run time

- `ffmpeg` and `ffprobe` on the user's `PATH`.
- An OpenAI API key in `API_KEY_OPENAI`, for every command (because of the `init` above).

## Code checks

None are automated yet: no tests, no linter, no Git hook and no CI (see spec 0001).

## Source control and access

- Public GitHub repo `gregtzar/spiritor`, moved from the `spiritorai` organization (see decision 0005); GitHub redirects the old URL. Default branch `main`; no rulesets.
- https://spiritor.ai redirects to the repo.
- Maintainers' agents work as the GitHub App `micromason-agent-prime`, installed on this repo with Contents, Pull requests and Workflows read/write, and Actions, Checks and Commit statuses read (see decision 0001).
- `.claude/settings.json` stops Claude Code skipping Git hooks, and allows force pushes only with `--force-with-lease`.
