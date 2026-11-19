---
status: current # current | outdated | superseded by NNNN
date: 2026-11-19 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Ollama for transcription

## Question

Can Ollama transcribe speech, and could it be `scribe`'s local transcription provider instead of faster-whisper? Informs spec 0002.

## Recommendation

### Summary

Not now. Ollama gained an OpenAI-compatible transcription endpoint three weeks ago, but it runs general audio models rather than Whisper, accepts only WAV, and returns no word timestamps. faster-whisper stays the local provider for spec 0002. Ollama is a candidate for a later, separate transcription provider once it has matured and been compared on the same recordings.

### Details

Because the endpoint copies OpenAI's `/v1/audio/transcriptions`, an Ollama provider could later share much of the OpenAI provider's client code, pointed at a local URL.

## Findings

### Summary

| Option                    | Runs locally | Models                                    | Input                    | Timing detail          | Maturity                        | Verdict                     |
| ------------------------- | ------------ | ----------------------------------------- | ------------------------ | ---------------------- | ------------------------------- | --------------------------- |
| faster-whisper            | Yes          | Whisper (`large-v2` tuned for noisy English) | Most audio and video, via PyAV | Segments and words     | Stable; in use by the maintainer | Local provider for spec 0002 |
| Ollama transcription API  | Yes          | Audio-capable general models (LFM3 audio, Gemma 4), not Whisper | WAV only, up to 2 hours  | Segments only; no word timestamps | Added in late October 2026      | Later candidate             |

### Details

#### Ollama

- Ollama's OpenAI compatibility docs list `/v1/audio/transcriptions`, which "Transcribes speech with models that accept audio input". Supported fields include `file` ("WAV at up to 384 kHz; up to 512 MB and 2 hours"), `model`, `language`, `prompt`, `response_format` (`json`, `text`, `verbose_json`; not `srt` or `vtt`), `temperature` and `stream`. `timestamp_granularities` is not supported.
- Long audio "is split at pauses and transcribed piece by piece", 30 seconds at a time for current models.
- The server code for it first appears on 2026-10-27, in the commit adding Liquid AI's LFM3 models. The v0.40.12 release notes (2026-10-27) list `lfm3-audio` for "speech recognition, translation, and text-to-speech in 18 languages".
- The maintainer's machine runs Ollama 0.30.8, which predates the endpoint.
- Web guides from 2026 almost all run Whisper separately and use Ollama only for the language model step. One third-party blog describes Whisper models in Ollama; Ollama's own docs and release notes don't mention Whisper.

## Caveats

- Not tested: transcription quality of Ollama's audio models on noisy English recordings, and how they handle a custom vocabulary through `prompt`.
- Ollama ships often; this will age within months.

## Sources

- [Ollama OpenAI compatibility docs](https://github.com/ollama/ollama/blob/main/docs/api/openai-compatibility.mdx)
- [Ollama releases](https://github.com/ollama/ollama/releases)
- [Ollama v0.40.12 release](https://github.com/ollama/ollama/releases/tag/v0.40.12)
- [Third-party blog on Whisper in Ollama](https://jonnyzzz.com/blog/2026/02/28/voice-memos-local-ai-transcription/)
- [Example of the common Whisper plus Ollama setup](https://www.aimadetools.com/blog/local-voice-assistant-whisper-ollama/)
