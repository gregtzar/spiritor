---
status: current # current | outdated | superseded by NNNN
date: 2026-11-21 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Open models for semantic search

## Question

Which open-weight models give the best results for Spiritor's semantic search (spec 0004)? There, a model reads one whole file at a time, decides which passages match a description, and answers with line ranges in a JSON schema. Two questions follow:

- Which model, at which version, gives the best results from a cloud host?
- Which is the smallest local size and quantization, run through Ollama, that still gives adequate results? Accuracy falls off sharply somewhere as models shrink. Where is that point?

Also: should reasoning ("thinking") models be avoided for this task? Informs spec 0004's examples and defaults, `README.md`'s model advice, and the OpenAI Chat Completions provider on the roadmap.

## Recommendation

### Summary

| Use | Recommendation | Why |
| --- | --- | --- |
| Best results, cloud | **Kimi K3.1 Pro** | Highest-scoring open model, best long-context reasoning score (AA-LCR 86%); also the most expensive, at a few dollars per megabyte of notes searched |
| Best value, cloud | **DeepSeek V4.1 Flash** or **GLM-5.3 Flash** | Next tier of quality at well under a dollar per megabyte of notes; the most-used open models on OpenRouter |
| Most private, cloud | **GLM-5.3** or **gpt-oss-120b** on an attested host (research 0005) | Tinfoil also offers Kimi K3.1 Pro and DeepSeek V4.1 Flash |
| Best local, 24 GB GPU | **Qwen3.8 27B** at Q4_K_M, or **Gemma 4 31B** QAT | Close to mid-tier cloud models on instruction following and long context |
| Smallest adequate local | **Qwen3.5 9B** at Q4_K_M (6.6 GB) | Matches models four times its size on instruction following and long-context benchmarks |
| Floor | **About 4B parameters**, for short files only | Below that, instruction following and long-context reading collapse |
| Reasoning | **Keep it, but run it at low effort or off by default**, and raise it for judgement-heavy searches | Evidence is mixed; reasoning multiplies output tokens and time |

### Details

- **The drop-off point is between 2B and 4B parameters, with 9B as the knee.** On Qwen3.5's own benchmarks, instruction following (IFBench) goes 21, 41, 59, 65 from 0.8B to 9B, and long-context reasoning (AA-LCR) goes 5, 26, 57, 63. The 35B-A3B mixture-of-experts model scores about the same as 9B. Above 9B the gains are steady but small, until the 27B–31B dense models, which improve most on long, many-match files.
- **Quantization:** Q4_K_M, Ollama's usual default, is adequate for note-sized files. Losses from 4-bit grow with input length, so prefer Q8_0 when memory allows and files run past roughly 32K tokens. Use Gemma's QAT builds where they exist. Avoid Q3 and below, especially on models under 14B. Leave Ollama's KV cache at `f16` or `q8_0`, not `q4_0`.
- **A larger model at Q4 beats a smaller one at Q8** within the same family: tolerance for quantization grows with size, and the size ladders below show bigger gaps between sizes than between quantizations.
- **Thinking:** start with it off (Qwen3.5, Granite and Nemotron) or at low effort (gpt-oss, Qwen3.8), measure, and turn it up only if matches are being missed. Current open models are almost all hybrids, so ruling out reasoning models would rule out nearly everything recent.
- **Measure on your own files.** Benchmarks stand in for this task only loosely. The reliable way to find the smallest adequate model is to search a small labelled set of files with each candidate and compare what each one misses. A repeatable evaluation script for this belongs in Spiritor's later work.
- **Cloud models need the OpenAI Chat Completions provider** (roadmap), because Ollama Cloud doesn't support structured outputs (spec 0004). OpenRouter lists `response_format` as supported for every model below.

## Findings

### Summary

#### What the task needs

| Need | Why | Evidence used |
| --- | --- | --- |
| Instruction following | The prompt's rules (smallest span, merging, include borderline matches) and the line-range answer | IFEval, IFBench |
| Reading a whole file | Every match in a file, not the first few | AA-LCR, LongBench v2, MRCR (many needles), RULER |
| Judgement | Searches like "all good business ideas" need understanding, not keyword matching | General indexes (Artificial Analysis Intelligence Index, MMLU-Pro) |
| Structured outputs | The answer must parse | Host support for JSON-schema `response_format` |

Typical notes are a few thousand tokens, and the largest tens of thousands (research 0004), so most requests sit well inside every model's context. Long-context scores matter most for the largest files and for files with many matches.

#### Cloud models

Prices are per million tokens, input / output. Ollama Cloud prices are standard hours, with off-peak about half. "Per MB" estimates searching one megabyte of notes, roughly 0.4 million input tokens with the prompt and line numbers. The low end assumes little reasoning (about 0.05 million output tokens) and the high end moderate reasoning (about 0.25 million).

| Model | Maker | Size (total / active) | AA index | AA-LCR | Ollama Cloud | OpenRouter range | Est. per MB | Attested hosts | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Kimi K3.1 Pro | Moonshot AI | 2.8T / 104B | 46 | 86% | $2.00 / $10.00 | $0.24–4.40 / $8.40–22 | $1.30–3.30, more at max reasoning | Tinfoil | Best results |
| Tencent Hy4 | Tencent | 774B / 50B | 35 | n/a | $0.83 / $2.50 | $0.42–0.83 / $1.25–2.50 | $0.45–0.95 | None found | Strong, new |
| DeepSeek V4.1 Flash | DeepSeek | 552B / 16B | 33 | n/a | $0.30 / $1.20 | $0.05–1.50 / $0.20–6 | $0.18–0.42 | Tinfoil | Best value |
| GLM-5.3 | Z.ai | 753B / 40B | 32 | n/a | $1.40 / $4.40 | $0.07–2.10 / $1.40–6.60 | $0.80–1.70 | Tinfoil, Privatemode | Strong; most private |
| MiniMax M3.1 Flash | MiniMax | n/a | 29 | n/a | $0.15 / $0.60 | $0.14–0.17 / $0.54–0.60 | $0.09–0.21 | None found | Good value |
| GLM-5.3 Flash | Z.ai | n/a | 28 | n/a | $0.15 / $0.50 | $0.04–0.23 / $0.08–0.75 | $0.09–0.19 | Privatemode | Best value; private option |
| Mistral Large 4 | Mistral | 1.1T / 52B | 26 | n/a | $0.70 / $2.10 | $0.70–0.77 / $2.10–2.31 | $0.40–0.80 | None found | EU maker |
| Muse Spark Open | Meta | 816B / 42B | 25 | n/a | $1.25 / $4.25 | not on OpenRouter | $0.70–1.60 | None found | Middling for the price |
| Qwen3.8 27B | Alibaba | 27B dense | 20 | n/a | not offered | $0.04–0.99 / $1.25–3.20 | $0.08–1.20, by host | None found | Also runs locally |
| gpt-oss-120b | OpenAI | 117B / 5.1B | 4 | 51% (Qwen's figure) | $0.15 / $0.60 | $0.03–0.35 / $0.15–0.95 | $0.09–0.21 | Tinfoil, Privatemode | Cheap, private; weaker on long files |

#### Local models through Ollama

Sizes are Ollama's download size at the listed quantization; add memory for the context (KV cache), which grows with file length. "Fit" is the smallest GPU memory that holds the model and a moderate context. Mixture-of-experts (MoE) models use only their active parameters per token, so they run faster than their size suggests, and run tolerably with part of the model in system memory.

"Expected" grades the size for this task from the size-ladder benchmarks below: **poor** (misses or garbles much), **marginal** (short, simple files only), **adequate** (the smallest worth using), **good**, **best local**.

| Family | Small | Medium | Large | Thinking control | Notes |
| --- | --- | --- | --- | --- | --- |
| Qwen3.5 / 3.8 (Alibaba) | `qwen3.5:4b` Q4_K_M, 3.3 GB, 6 GB GPU: marginal | `qwen3.5:9b` Q4_K_M, 6.6 GB, 8 GB GPU: **adequate, the recommended floor** | `qwen3.8:27b` Q4_K_M, 18 GB, 24 GB GPU: best local; `qwen3.5:35b-a3b` 22 GB MoE: good, fast | Off with `enable_thinking: false`; 3.8 adds `reasoning_effort` | Strongest small-size results; 256K context |
| Gemma 4 (Google) | `gemma4:e4b` QAT, 6.1 GB, 8 GB GPU: marginal | `gemma4:12b` QAT, 7.2 GB, 12 GB GPU: adequate | `gemma4:31b` QAT, 19 GB, 24 GB GPU: best local; `gemma4:26b` MoE, 16 GB: good | On or off through the system prompt | QAT builds keep quality at 4-bit; 31B leads its family by far on many-match files |
| gpt-oss (OpenAI) | none | `gpt-oss:20b` MXFP4, 14 GB, 16 GB GPU: adequate | `gpt-oss:120b` MXFP4, 65 GB, 80 GB GPU or unified memory: good | Effort low, medium or high; can't be turned off | MoE; fast for its size; 128K context |
| Granite 4.2 (IBM) | `granite4.2:3b` Q4_K_M, 2.2 GB, 4 GB GPU: marginal | `granite4.2:8b` Q4_K_M, 5.3 GB, 8 GB GPU: adequate | `granite4.2:30b` Q4_K_M, 18 GB, 24 GB GPU: good | Off, or effort low or high | Dense; strong instruction following for its size; lower general scores |
| Ministral 3 and Mistral Small (Mistral) | `ministral-3:3b` Q4_K_M, 3.0 GB: poor to marginal | `ministral-3:8b`, 6.0 GB: marginal to adequate; `ministral-3:14b`, 9.1 GB, 12 GB GPU: adequate | `mistral-small3.2:24b` Q4_K_M, 15 GB, 16–24 GB GPU: good | No thinking: instruction-tuned models | The main current non-reasoning family; no comparable long-context scores published |
| Nemotron 3.5 (Nvidia) | `nemotron-3.5-bolt:e4b` Q4_K_M, 7.9 GB: marginal | none | `nemotron-3.5-lightning:30b` (30B-A3B MoE) Q4_K_M, 25 GB: unclear | On or off | 1M context, but low general scores (AA index 6) |
| GLM (Z.ai) | none | none | `glm-4.7-flash` (30B-A3B MoE) Q4_K_M, 19 GB: good, unmeasured | Thinking | GLM-5.3 itself is cloud only |
| Meta | none | none | `muse-glimmer:30b` Q4_K_M, 18 GB: good (IFBench 77, Qwen's figure) | Effort levels | Muse Spark Open is cloud only |

DeepSeek V4.1 Flash, Kimi K3.1 Pro, GLM-5.3, Hy4, MiniMax M3 and Mistral Large 4 are open-weight but need hundreds of gigabytes of memory, so in practice they run in the cloud.

### Details

#### Size ladders: where accuracy falls off

Vendor-reported scores; each vendor runs its own evaluation, so compare within a family, not across.

Qwen3.5 (thinking mode, the default):

| Benchmark | 0.8B | 2B | 4B | 9B | 35B-A3B | 27B |
| --- | --- | --- | --- | --- | --- | --- |
| IFEval | 44.0 | 78.6 | 89.8 | 91.5 | 91.9 | 95.0 |
| IFBench | 21.0 | 41.3 | 59.2 | 64.5 | 70.2 | 76.5 |
| AA-LCR | 4.7 | 25.6 | 57.0 | 63.0 | 58.5 | 66.1 |
| LongBench v2 | 26.1 | 38.7 | 50.0 | 55.2 | 59.0 | 60.6 |

The cliff is between 2B and 4B: long-context reasoning more than doubles. From 4B to 9B every score still rises; beyond 9B, the dense 27B is the next real step. Qwen3.8 27B raises IFBench to 79.5 against 3.6 27B's 69.1 (Qwen's figures).

Gemma 4, MRCR v2 at 128K with 8 needles (finding several items spread through a long input, the closest benchmark to this task):

| E2B | E4B | 12B | 26B-A4B | 31B |
| --- | --- | --- | --- | --- |
| 19.1% | 25.4% | 43.4% | 44.1% | 66.4% |

Granite 4.2, RULER (dense models):

| Context | 3B | 8B | 30B |
| --- | --- | --- | --- |
| 64K | 67.5 | 81.0 | 90.0 |
| 128K | 55.3 | 71.4 | 81.4 |

Granite's instruction following barely changes with size (IFBench 74, 79, 77), which suggests its small sizes follow the prompt's rules but miss more in long files.

Ministral 3 publishes no instruction-following or long-context scores. Its Arena Hard scores (3B 0.31, 8B 0.51, 14B 0.55) show the same cliff below 8B.

#### Reasoning

- Studies disagree, by task. In a multi-image attribute extraction benchmark, thinking raised recall by 9.2 points, most of its gain. In a legal clause-identification benchmark with small Qwen3 models, thinking improved overlap with the right spans but lowered F1. In a classification task (prompt-attack detection), non-thinking configurations beat thinking ones at every size.
- Exhaustive search is part enumeration (where thinking helps recall) and part exact span-finding (where it can hurt), so neither mode wins on evidence. The spec's preference for borderline matches leans towards recall.
- Thinking costs far more output: in one benchmark, the median answer was 618 tokens with thinking against 5 without. For a cloud search, output is most of the bill; locally, it's most of the time.
- Controls: Qwen3.5 turns thinking off with `enable_thinking: false` (its 2B and smaller default to off); Qwen3.8 and Granite 4.2 also take a reasoning effort; gpt-oss takes low, medium or high and can't be turned off; Gemma 4 switches it through the system prompt; Ministral 3 and Mistral Small 3.2 don't think. Privatemode runs GLM-5.3 at maximum reasoning effort by default.

#### Quantization

- **8-bit is close to lossless, even at long context:** averages of 0.2% (FP8) and 0.8% (GPTQ int8) lost on inputs of 64K tokens and more (arXiv 2505.20276, EMNLP 2025).
- **4-bit loses more as inputs grow:** average losses of 1.8% to 6.9% by method, "up to 23% across models at 128K tokens" on retrieval, and worse in some model and method pairs. Qwen2.5 32B and 72B held up far better than Llama 3.1. The study didn't test llama.cpp's K-quants, such as Q4_K_M, which Ollama uses.
- **Below 4-bit, small models fall off:** at 3-bit "there is a noticeable decline in the performance of small models across all model families", and at 2-bit "the majority of models experience a significant performance loss" (arXiv 2402.18158, ICML 2024). The same study: "the larger the model size, the higher the tolerance for Weight Quantization."
- **At short context, K-quants are near lossless:** on Gemma 3 27B, 5-shot MMLU was 71.2 at Q4_K_M, 71.8 at Q5_K_M, 71.9 at Q6_K and 71.6 at Q8_0, against 71.5 unquantized (Unsloth's measurements).
- **QAT:** Google's quantization-aware training "reduce[s] the perplexity drop by 54%" at Q4_0 for Gemma 3. Ollama offers QAT builds of every Gemma 4 size.
- **KV cache:** Ollama's `OLLAMA_KV_CACHE_TYPE` defaults to `f16`; `q8_0` halves its memory "with a very small loss in precision", and `q4_0` has "a small-medium loss in precision that may be more noticeable at higher context sizes". Research finds KV cache quantization hurts long inputs more than weight quantization.

#### Cloud hosts

- Ollama Cloud doesn't support structured outputs, so it can't serve this search as designed; the same models are on OpenRouter and other hosts. Qwen and Mistral Small models aren't on Ollama Cloud.
- OpenRouter lists `response_format` as supported for every model in the cloud table; whether each host behind it enforces a JSON schema varies, and wasn't tested.
- DeepSeek's models through a third-party host avoid DeepSeek's own service and its data handling (research 0005).

## Caveats

- Benchmarks stand in for this task loosely. No benchmark measures exhaustive passage extraction with line ranges, and most scores are vendor-reported. The "expected" grades are judgement from the size ladders, not measurements of this task.
- No source paired thinking and non-thinking scores for the same model, except Qwen3.5 2B and 0.8B. The effect of turning thinking off at 9B and above is unmeasured.
- Artificial Analysis's index puts gpt-oss-120b and Gemma 4 31B low (4 each) against vendor figures that put them higher; its scale and settings weren't checked.
- Missing: long-context scores for Ministral 3, Mistral Small 3.2, Nemotron 3.5, GLM-4.7-Flash and Muse Glimmer; AA-LCR for most cloud models; whether Ollama honours `enable_thinking` and reasoning effort for every family (Ollama's `think` request field is documented on the Granite page only).
- Cost estimates depend mostly on how much a model reasons, which is the least certain part. One measured search would replace them.
- Open models change monthly. Several in these tables are under three months old.

## Sources

- Ollama: [library](https://ollama.com/library), [cloud models](https://ollama.com/search?c=cloud), [pricing](https://ollama.com/pricing), [FAQ (context and KV cache)](https://docs.ollama.com/faq), model pages for [qwen3.5](https://ollama.com/library/qwen3.5/tags), [qwen3.8](https://ollama.com/library/qwen3.8/tags), [gemma4](https://ollama.com/library/gemma4/tags), [gpt-oss](https://ollama.com/library/gpt-oss), [granite4.2](https://ollama.com/library/granite4.2/tags), [ministral-3](https://ollama.com/library/ministral-3/tags), [mistral-small3.2](https://ollama.com/library/mistral-small3.2/tags), [nemotron-3.5-bolt](https://ollama.com/library/nemotron-3.5-bolt), [nemotron-3.5-lightning](https://ollama.com/library/nemotron-3.5-lightning), [glm-4.7-flash](https://ollama.com/library/glm-4.7-flash), [muse-glimmer](https://ollama.com/library/muse-glimmer)
- Model cards: [Qwen3.5 9B and 4B](https://huggingface.co/Qwen/Qwen3.5-9B), [Qwen3.5 2B](https://huggingface.co/Qwen/Qwen3.5-2B), [Qwen3.5 27B](https://huggingface.co/Qwen/Qwen3.5-27B), [Qwen3.5 35B-A3B](https://huggingface.co/Qwen/Qwen3.5-35B-A3B), [Qwen3.8 27B](https://huggingface.co/Qwen/Qwen3.8-27B), [Gemma 4](https://gemma.ai/models/gemma-4/model-card/), [gpt-oss](https://openai.com/index/introducing-gpt-oss/), [Ministral 3 14B](https://huggingface.co/mistralai/Ministral-3-14B-Instruct-2512), [Granite 4.2 8B](https://huggingface.co/ibm-granite/granite-4.2-8b)
- Independent benchmarks: [Artificial Analysis open models](https://artificialanalysis.ai/models/open-source), [AA-LCR](https://artificialanalysis.ai/evaluations/artificial-analysis-long-context-reasoning), [IFBench](https://artificialanalysis.ai/evaluations/ifbench), [OpenRouter open-model rankings](https://openrouter.ai/rankings?models=open)
- OpenRouter model pages: [DeepSeek V4.1 Flash](https://openrouter.ai/deepseek/deepseek-v4.1-flash), [GLM-5.3](https://openrouter.ai/z-ai/glm-5.3), [GLM-5.3 Flash](https://openrouter.ai/z-ai/glm-5.3-flash), [Kimi K3.1 Pro](https://openrouter.ai/moonshotai/kimi-k3.1-pro), [Qwen3.8 27B](https://openrouter.ai/qwen/qwen3.8-27b), [gpt-oss-120b](https://openrouter.ai/openai/gpt-oss-120b), [Mistral Large 4](https://openrouter.ai/mistralai/mistral-large-4-0), [Hy4](https://openrouter.ai/tencent/hy4), [MiniMax M3.1 Flash](https://openrouter.ai/minimax/minimax-m3.1-flash)
- Attested hosts: [Tinfoil models](https://docs.tinfoil.sh/models/chat.md), [Privatemode models](https://docs.privatemode.ai/models/overview/), [Privatemode pricing](https://www.privatemode.ai/pricing)
- Quantization: [Does quantization affect models' performance on long-context tasks? (EMNLP 2025)](https://arxiv.org/html/2505.20276v3), [Evaluating Quantized Large Language Models (ICML 2024)](https://arxiv.org/html/2402.18158v2), [Unsloth dynamic GGUFs](https://unsloth.ai/docs/basics/dynamic-3.0-ggufs) (vendor), [Gemma 3 QAT](https://developers.googleblog.com/en/gemma-3-quantized-aware-trained-state-of-the-art-ai-to-consumer-gpus/)
- Reasoning: [IndustryBench-MIPU](https://arxiv.org/pdf/2606.14383), [ContractEval](https://arxiv.org/pdf/2508.03080), [Prompt attack detection with LLM-as-a-judge](https://arxiv.org/pdf/2603.25176)
