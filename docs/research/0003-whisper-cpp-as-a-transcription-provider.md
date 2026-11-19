---
status: current # current | outdated | superseded by NNNN
date: 2026-11-19 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# whisper.cpp as a transcription provider

## Question

Could whisper.cpp give Spiritor local transcription without a Python environment, possibly embedded in Spiritor itself, and what would faster-whisper still offer over it? Informs spec 0002 and a later whisper.cpp provider on the roadmap.

## Recommendation

### Summary

Keep faster-whisper for spec 0002, and add whisper.cpp later as a separate provider. whisper.cpp matches faster-whisper's speed and decoding settings without Python and runs on more GPUs, but faster-whisper has the maintainer's tested settings, mature word timestamps, batching and a path to speaker identification. For the later provider, calling whisper.cpp's shared library through purego keeps Spiritor's builds pure Go.

### Details

The later spec has to decide how users get whisper.cpp's native library and models: installed by the user, as decision 0008 requires today, or downloaded or embedded by Spiritor, which would need a new decision.

## Findings

### Summary

| Option                                    | Python | C toolchain to build Spiritor | Native library at run time            | GPUs                                   | Maturity                       | Verdict                     |
| ----------------------------------------- | ------ | ----------------------------- | ------------------------------------- | -------------------------------------- | ------------------------------ | --------------------------- |
| faster-whisper (spec 0002)                | Yes    | No                            | In the user's Python environment       | Nvidia (CUDA); CPU elsewhere           | Mature; in use by the maintainer | Provider for spec 0002      |
| whisper.cpp program (`whisper-cli`)       | No     | No                            | Installed by the user                  | Nvidia, AMD, Apple Metal, Vulkan, CPU  | Mature                         | Simplest later provider     |
| whisper.cpp official Go bindings (cgo)    | No     | Yes, per platform             | Linked into the binary                 | Chosen at build time                   | Mature                         | Ends pure-Go releases       |
| whisper.cpp through purego (as in bucky)  | No     | No                            | Shared library, per OS and GPU backend | Nvidia, Apple Metal, Vulkan, CPU       | purego mature; bucky six months old | Best fit for a later provider |
| whisper.cpp compiled to WebAssembly, run by wazero | No | No                       | None; fully self-contained             | CPU only                               | No existing binding found      | Too slow for `large-v2`     |

### Details

#### faster-whisper compared with whisper.cpp

- No C++ port of faster-whisper exists. It is Python built on CTranslate2, a C++ engine; its decoding, silence filtering, word timestamps and batching are Python. The only Python-free builds are third-party packaged executables, such as Purfview's for Windows.
- whisper.cpp's C API (`whisper.h`) covers the faster-whisper preset in spec 0002: `beam_size`, `best_of`, `initial_prompt`, `no_context` (faster-whisper's `condition_on_previous_text=False`), temperature fallback, and Silero voice activity detection with threshold, minimum speech, minimum silence and padding settings.
- faster-whisper's own benchmark (13 minutes of audio, `large-v2`, GPU, fp16, beam 5, RTX 3070 Ti, against whisper.cpp v1.7.2): whisper.cpp with Flash Attention 1m05s, faster-whisper 1m03s, faster-whisper with `batch_size=8` 17s.
- whisper.cpp's word-level timestamps are marked "experimental"; faster-whisper's are an established feature.
- Speaker identification: WhisperX builds on faster-whisper; whisper.cpp has only a speaker-turn marker with one special small model.
- whisper.cpp's published models are f16 or quantized; the maintainer's `float32` choice would need a converted model. Unverified.
- Neither project publishes accuracy on noisy recordings; comparing the same recordings is the only measure.

#### Running whisper.cpp from Go without cgo

- purego (`ebitengine/purego`, Apache-2.0, about 4,100 stars) calls C functions in shared libraries loaded at run time, without cgo, so Go programs using it still cross-compile with no C toolchain.
- `ardanlabs/bucky` (Apache-2.0, created May 2026, about 26 stars, pinned to whisper.cpp v1.9.5) binds whisper.cpp through purego and JupiterRider/ffi. Its `install` command downloads checksum-verified shared-library bundles: Linux CPU, CUDA 12.9, CUDA 13.0 or Vulkan; macOS Metal; Windows CPU or CUDA 12.4. Its README notes that whisper.cpp releases sometimes require bucky updates.
- Embedding those libraries in Spiritor's binary with `go:embed`, written to disk and loaded at run time, would avoid a download, at the cost of one library per platform and GPU backend in every release. Size not checked.

## Caveats

- The benchmark is faster-whisper's own, against an older whisper.cpp release.
- bucky's reliability over whisper.cpp version changes is untested.
- A search result claimed purego will need cgo on fewer architectures from Go 1.27; not checked against Go's release notes.

## Sources

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
- [whisper.cpp C API](https://github.com/ggml-org/whisper.cpp/blob/master/include/whisper.h)
- [whisper.cpp Go bindings](https://github.com/ggml-org/whisper.cpp/tree/master/bindings/go)
- [faster-whisper and its benchmarks](https://github.com/SYSTRAN/faster-whisper)
- [purego](https://github.com/ebitengine/purego)
- [ardanlabs/bucky](https://github.com/ardanlabs/bucky)
- [wazero](https://github.com/wazero/wazero)
- [Purfview standalone faster-whisper builds](https://github.com/Purfview/whisper-standalone-win/releases)
- [Third-party whisper.cpp and faster-whisper comparison](https://www.promptquorum.com/power-local-llm/local-whisper-stt-comparison-2026)
