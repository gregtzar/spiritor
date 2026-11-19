# Architecture

What exists and runs today. Nothing in this file is planned: designs for upcoming work live in `docs/specs/` (ordered in `docs/roadmap.md`), and the reasons behind decisions live in `docs/decisions/`.

When a change implements part of a spec, describe the result here in the same change, matching what was actually built.

Last reviewed: 2026-11-18.

## Current state

A Go CLI, `spiritor`, with one command, `scribe`, which batch-transcribes audio files through the OpenAI Whisper API. The same code is importable as the Go module `github.com/gregtzar/spiritor`. Releases since `v0.2.0` use this path; `v0.1.0` was published under the earlier path `github.com/spiritorai/spiritor` (see decision 0005). No Ollama or other model provider is integrated yet.

## Repo layout

- `spiritor.go`: package `main`. Parses the CLI with Kong (`--debug`, and the `scribe` command), validates file arguments, and runs the `scribe` worker pools: 4 downsample workers feed 6 transcription workers. Writes each transcript next to its source file as `<file>.<format>`, skipping files that already have one unless `-f` is given.
- `avmedia/`: the `Media` type (path, size, duration, bitrate, probed through `ffmpeg`), downsampling to Ogg Opus under a size cap, and typed errors.
- `ffmpeg/`: runs the `ffmpeg` and `ffprobe` binaries installed on the user's machine.
- `transcribe/`: the OpenAI Whisper client. Uploads a file to `https://api.openai.com/v1/audio/transcriptions`, parses the transcript, and formats it. Only `txt` output is supported. It reads `API_KEY_OPENAI` in `init` and exits if it is missing.
- `scribe/`: the downsample and transcription workers.
- `utils/`: sentence splitting, using `github.com/neurosnap/sentences`.
- `neurosnaptrainingdata/`: the English training data for the sentence splitter, embedded with `embed`.
- `build/build_go.sh`: cross-compiles release binaries for Linux, macOS and Windows into the current folder or a given one, with `-trimpath` so they carry no build machine paths. Binaries written into `build/` are ignored by Git.
- `build/check.sh`: the check command (see "Code checks").
- `tools/`: one module file per developer tool, golangci-lint and govulncheck, run with `go tool` (see decision 0006).
- Dependencies (Kong, sentences) are pinned in `go.mod` and `go.sum` and not vendored. `go.mod` requires Go 1.26 or newer.

## External dependencies at run time

- `ffmpeg` and `ffprobe` on the user's `PATH`.
- An OpenAI API key in `API_KEY_OPENAI`, for every command (because of the `init` above).

## Code checks

- `build/check.sh` defines what passes: tidy `go.mod` and `go.sum`, formatting and lint through golangci-lint (configured in `.golangci.yml`), `go test`, release builds for every platform, and `govulncheck`. It never changes files. There are no tests yet.
- GitHub Actions runs it as the `check` job on every pull request and push to `main` (`.github/workflows/ci.yml`), installing the latest patch release of the Go version in `go.mod`.
- A Claude Code hook script, `.claude/hooks/format_and_lint_edited_file.sh`, formats each Go file an agent edits and reports lint issues in its package. It runs once it is added to `.claude/settings.json`.
- There is no Git hook (see spec 0001).

## Source control and access

- Public GitHub repo `gregtzar/spiritor`, moved from the `spiritorai` organization (see decision 0005); GitHub redirects the old URL. Default branch `main`.
- Pull requests merge by squash only; the squashed commit takes the pull request's title and description.
- Rulesets: `main` blocks deletion and force pushes; `release-tags` blocks updating or deleting `v*` tags, so a published version never changes under the Go module proxy. `main` also requires CI's `check` to pass on an up-to-date branch. Both rulesets are kept in `.github/rulesets/` in GitHub's import format.
- Each release is a semver tag and a GitHub release with notes and the binaries from `build/build_go.sh` (see decision 0002). The latest is `v0.2.0`.
- https://spiritor.ai redirects to the repo.
- Maintainers' agents work as the GitHub App `micromason-agent-prime`, installed on this repo with Contents, Pull requests and Workflows read/write, and Actions, Checks and Commit statuses read (see decision 0001).
- `.claude/settings.json` stops Claude Code skipping Git hooks, and allows force pushes only with `--force-with-lease`.
