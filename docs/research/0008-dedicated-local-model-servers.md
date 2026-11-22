---
status: current # current | outdated | superseded by NNNN
date: 2026-11-22 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Dedicated local model servers

## Question

What hardware can a user buy to run open models on a dedicated machine of their own, at three sizes: **small**, for models up to about 32B (Qwen3.8 27B, Gemma 4 31B); **medium**, up to about 70B dense or about 120B mixture-of-experts (gpt-oss-120b); and **large**, for the biggest open models a desktop can hold? What does each cost, and can it be bought now? Covers Apple's unified memory Macs, NVIDIA's desktop AI computers, AMD's unified memory mini PCs and self-built GPU machines. Informs `README.md`'s hardware advice for local providers (decision 0007), and compares with renting GPUs (research 0007).

## Recommendation

### Summary

| Size | Models | Recommendation | Price | Why |
| --- | --- | --- | --- | --- |
| Small | Qwen3.8 27B, Gemma 4 31B at Q4 | **Self-built PC with a used RTX 3090** (24 GB) | About $2,500–3,200 | Reads input about 3 times as fast as any unified memory machine at this size; cheapest |
| Small, appliance | Same | **Mac Studio M5 Max, 64 GB** | $3,499 | In stock, quiet and low power; slower to read input |
| Medium | gpt-oss-120b, 70B dense at Q4 | **Mac Studio M5 Max, 128 GB** | About $5,100 | The best-balanced appliance: fast generation, good input speed, in stock |
| Medium, lowest cost | Same | **AMD Ryzen AI Max+ 395 mini PC, 128 GB** | About $3,300–3,800 | Cheapest 128 GB machine; reads input 3 to 5 times slower |
| Medium, fastest input | Same | **NVIDIA DGX Spark, 128 GB** | $6,950 list; often out of stock | Fastest input reading of the appliances; the price rose 74% in a year |
| Large | DeepSeek V4.1 Flash, GLM-5.3 at 4-bit | **Mac Studio M5 Ultra, 512 GB** | About $22,300 | The only single machine under $60,000 that holds a 300–450 GB model |
| Out of reach | Kimi K3.1 Pro (about 1.5 TB at 4-bit) | Rent it (research 0007) | — | No desktop holds it |

### Details

- **2026 is a bad year to buy.** A DRAM shortage has repriced everything with a lot of memory. The DGX Spark went from $3,999 at launch (October 2025) to $6,950; 128 GB Ryzen AI Max+ 395 mini PCs from about $1,999 to $3,300–3,800; the RTX 5090 sells for $6,200–7,350 against a $1,999 list price; the RTX PRO 6000 from $8,565 to $16,000; used RTX 3090s rose 29% in 90 days. Apple's prices rose least (the M5 Max Mac Studio base went from $2,000 to $2,500).
- **This workload is mostly reading input.** A search sends whole files and gets short answers, so input reading speed (prompt processing, or prefill) matters more than generation speed, the figure most reviews lead with. Prefill is compute-bound, where discrete NVIDIA GPUs lead. Unified memory machines (Macs, DGX Spark, AMD Halo) win on memory capacity, not compute. Inferred searches, with reasoning on, lean more on generation, where the Macs' bandwidth helps.
- **Spiritor reaches any of them through spec 0004's Ollama provider**, by setting `SPIRITOR_SEARCH_OLLAMA_URL` to the machine's address on the local network. The server keeps local inference's trust score of 10 (research 0005) as long as it is reached only on the local network or through the user's own VPN. On a Mac, MLX runs faster than llama.cpp, which Ollama is built on. MLX's servers (LM Studio, `mlx-lm`) speak the OpenAI Chat Completions API, so they need the OpenAI Chat Completions provider on the roadmap.
- **Buying rarely beats renting for occasional searches.** At research 0007's prices, the $22,300 M5 Ultra costs as much as about 1,300 large (40 MB) inferred searches with DeepSeek V4.1 Flash billed per token, or about 2,500 on rented GPUs. A machine pays for itself through frequent use, privacy, or other work, not search alone.

## Findings

### Summary

Prices are US, read 2026-11-22 from the sources listed; most come from third-party trackers and reviews, because Apple's and NVIDIA's store pages didn't render prices. "Input" is prompt processing in tokens/s; "output" is single-request generation in tokens/s; both from the benchmarks under "Details".

#### Small: up to about 32B

| Option | Memory | Price | Availability | Input / output, 27B dense at Q4 | Verdict |
| --- | --- | --- | --- | --- | --- |
| Self-built, used RTX 3090 | 24 GB | GPU $1,425–1,650 used; about $2,500–3,200 built | Plentiful used; prices rising | About 1,300 (estimated) / about 40 | **Best value and fastest input**; 24 GB leaves little room for long files |
| Self-built, Radeon AI PRO R9700 | 32 GB | GPU $1,299 list; about $2,500–3,000 built | Often out of stock | Not measured | Room for longer files; ROCm, not CUDA |
| Self-built, RTX 5090 | 32 GB | GPU $6,200–7,350 street | In stock above list; Founders Edition sold out | About 3,800 / about 60 | Fastest, but three times its list price |
| Mac Studio M5 Max | 36 GB or 64 GB | $2,499 or $3,499 | In stock | Not measured; about 400–600 estimated / about 31 | **Simplest**; 36 GB is tight once macOS's default GPU memory limit (about 75%) applies |
| Ryzen AI Max+ 395 mini PC | 64 GB | $2,150–2,400 | In stock | About 200–300 estimated / about 13 | Too slow for dense 27B models |

#### Medium: up to about 70B dense or 120B mixture-of-experts

| Option | Memory | Price | Availability | Input / output, gpt-oss-120b | Verdict |
| --- | --- | --- | --- | --- | --- |
| Mac Studio M5 Max | 128 GB | About $5,000–5,200 | In stock | 1,325 at 4K, 2,710 at 16K (MLX, on a MacBook Pro with the same chip) / 88 | **Best balance** |
| Ryzen AI Max+ 395 mini PC (Framework Desktop, GMKtec EVO-X2, Minisforum MS-S1 Max) | 128 GB | $3,299–4,700, median $3,800 | Framework often out of stock; others available | 459–589 / 49–55 | **Cheapest**; slow input |
| NVIDIA DGX Spark (and partner versions: Dell, HP ZGX Nano, ASUS and others) | 128 GB | $6,950 list; partners $6,900–7,200; 64 GB from $4,999 through partners | Out of stock at NVIDIA (October 2026); no restock date | 2,444 at 0K, 1,567 at 32K (llama.cpp) / 59 | **Fastest input**, slower output; 70B dense only 4.4 output |
| Gorgon Halo mini PC (Ryzen AI Max+ PRO 495) | 192 GB | $6,399–9,249 | Pre-order | Not measured | New; costs as much as a Spark |
| Self-built, 2× RTX 3090 | 48 GB | About $4,500–5,500 | Used | Fast for 70B dense at Q4 | Doesn't hold gpt-oss-120b (65 GB) without offloading |
| Self-built, RTX PRO 6000 Blackwell | 96 GB | GPU $15,000–18,000; about $19,000–22,000 built | In stock | About 2,400 at Q8_0 on an older build (faster expected at MXFP4) / about 170–196 | Fastest by far; four times the price of the Mac |

#### Large: the biggest open models that fit a desktop

DeepSeek V4.1 Flash (552B, 16B active) needs about 300 GB at 4-bit, and GLM-5.3 (753B) about 420 GB, plus room for context.

| Option | Memory | Price | Availability | Input / output, DeepSeek V4.1 Flash | Verdict |
| --- | --- | --- | --- | --- | --- |
| Mac Studio M5 Ultra | 512 GB | About $22,300 (80-core GPU required) | Shipping since late October 2026 | 1,100–3,100 / 54–64 (users' reports) | **The practical large option** |
| Mac Studio M5 Ultra | 256 GB | About $9,400–11,300 | In stock | Holds DeepSeek V4.1 Flash only below 4-bit | Too small for this tier at full quality |
| 2× DGX Spark, linked | 256 GB | About $13,900 | As for the Spark | A 32K prompt in about 17 s against the M5 Ultra's 44–50 s, on DeepSeek V4 Flash (one source) | Faster input, but too small for 4-bit V4.1 Flash |
| Self-built server: EPYC, 512–768 GB DDR5, one GPU | 512–768 GB system memory | Not priced; DDR5 prices volatile | Parts available | Not measured; slow input unless the GPU handles it | For builders; mixture-of-experts offloading (llama.cpp, KTransformers) |
| NVIDIA DGX Station GB300 | 748 GB | About $85,000–164,000, by partner | Orderable | Not measured | Data-centre class; far beyond this use |

### Details

#### Benchmarks used

- **DGX Spark**, from llama.cpp's own benchmark file (February 2026 build), `llama-bench` with 2,048-token prompts at increasing context depth. gpt-oss-120b (MXFP4): input 2,444 at depth 0, 2,217 at 8K, 1,567 at 32K; output 59 to 43. gpt-oss-20b: input 4,506 to 2,689. Qwen3-Coder 30B-A3B (Q8_0): 2,987 to 1,348. GLM-4.7-Flash (Q8_0): 2,364 to 567.
- **Ryzen AI Max+ 395**: gpt-oss-120b input 459 (512-token prompt, Vulkan), 340 (Hardware Corner, October 2025), 589 at 32K on ROCm 7.2.3 (kyuz0 toolbox); output 49–55. Qwen3.8 27B Q4_K_M output 12.6.
- **Apple M5 Max**: gpt-oss-120b input 1,325 at 4K and 2,710 at 16K, output 87.9 (MLX, on a MacBook Pro, via ComputingForGeeks). Rising input speed with longer context is unusual and wasn't explained. Qwen3.8 27B output 31 (MLX 4-bit).
- **Apple M5 Ultra**: no controlled benchmark found. Users report DeepSeek V4.1 Flash at up to 1,100 input and 54 output on 512 GB, and 3,101 input averaged over 512 to 256K tokens with `mlx-serve`. A separate report: a 400,000-token DeepSeek V4 Flash prompt took 934 s in llama.cpp (about 430 tokens/s). Apple claims prompt processing "up to 4 times faster" than the previous generation in LM Studio.
- **RTX 5090**: Qwen3.6 27B Q4_K_M input 3,826 (`llama-bench` pp512, May 2026). gpt-oss-120b input 484, because 65 GB doesn't fit in 32 GB and spills into system memory.
- **RTX 3090**: no current 27B input figure found. The estimate of about 1,300 scales the RTX 5090's figure by the two cards' ratio on a common benchmark (Llama 2 7B: 5,175 against 14,073). Output about 40 on Qwen3.6 27B.
- **RTX PRO 6000**: gpt-oss-120b input about 2,419 at Q8_0 on an older build, with a wide spread (±514); output 170–196.
- Engines, quantizations and dates differ across sources, so treat differences under about 20% as noise.

#### Time per search

From the figures above, for spec 0004's searches (sizes and token counts as in research 0007: small 2 MB, medium 20 MB, large 40 MB; 0.4 million input tokens per MB; 0.05 million output per MB stated and 0.25 million inferred). Assumes a few requests in parallel, which roughly doubles to triples aggregate output on these machines. Estimates, not measurements.

| Machine and model | Stated: small / medium / large | Inferred: small / medium / large |
| --- | --- | --- |
| RTX 3090, Qwen3.8 27B Q4 | 30 min / 5 h / 10 h | 2 h / 19 h / 38 h |
| Mac Studio M5 Max 128 GB, gpt-oss-120b | 15 min / 2.5 h / 5 h | 50 min / 8 h / 16 h |
| DGX Spark, gpt-oss-120b | 15 min / 2.5 h / 5 h | 1 h / 10 h / 20 h |
| Mac Studio M5 Ultra 512 GB, DeepSeek V4.1 Flash | 20 min / 3 h / 6 h | 1 h / 10 h / 21 h |

For comparison, research 0007 estimates a large inferred search with DeepSeek V4.1 Flash on rented GPUs at about 20 minutes and $9. Electricity for a local search is cents to about a dollar: the M3 Ultra Mac Studio drew 227 W and the Spark 123 W at peak in one test.

#### Apple Mac Studio (M5 Max, M5 Ultra; released September 2026)

- M5 Max: 36, 48, 64 or 128 GB (128 GB needs the 40-core GPU), 460 or 614 GB/s. M5 Ultra: 96, 256 or 512 GB (512 GB needs the 80-core GPU), 1.2 TB/s.
- Prices (Engadget, MacRumors, ComputingForGeeks): M5 Max from $2,499; 48 GB $3,099; 64 GB $3,499; 128 GB about $5,100. M5 Ultra from $5,499; 256 GB about $9,400–11,300 by configuration; 512 GB $22,299, of which the memory upgrade is $15,500, on the $6,799 80-core model.
- macOS lets the GPU use about 75% of memory by default. The limit can be raised (`iogpu.wired_limit_mb`), not verified here.
- Ollama runs on macOS with Metal. MLX, Apple's own framework, is usually faster, and is served by LM Studio and `mlx-lm` through an OpenAI-compatible API.

#### NVIDIA DGX Spark (GB10; formerly Project DIGITS)

- 128 GB unified memory at 273 GB/s, GB10 Grace Blackwell chip, NVIDIA's DGX OS (Ubuntu), CUDA. Two can be linked through their 200 Gb/s network ports to run models up to about 256 GB.
- Price: $3,999 at launch (October 2025), $4,699 (February 2026), $6,950 (October 2026), all blamed on memory supply. A 64 GB version from $4,999, sold only through partners from October 2026. NVIDIA's own store showed the 128 GB model out of stock on 11 October 2026, with no restock date.
- Partner versions with the same chip: Dell Pro Max with GB10, HP ZGX Nano ($6,900–7,200), ASUS, Acer, Gigabyte, MSI.
- Its big brother, the DGX Station (GB300, 748 GB), costs $85,000 (MSI) to $164,000 (Dell lists from $160,195), and is out of scope.

#### AMD Ryzen AI Max (Strix Halo and Gorgon Halo)

- Ryzen AI Max+ 395 (Strix Halo): up to 128 GB at 256 GB/s; up to about 96 GB usable by the GPU on Windows, about 115–120 GB on Linux. Many makers: Framework Desktop ($3,449 for 128 GB without an SSD, often out of stock), GMKtec EVO-X2 ($3,500–3,700), Minisforum MS-S1 Max ($3,900–4,000), AMD's own Ryzen AI Halo ($3,999).
- Ryzen AI Max+ PRO 495 (Gorgon Halo), new in late 2026: up to 192 GB. GMKtec EVO-X5 Pro $6,399–7,099; Minisforum $7,399 on pre-order, $9,249 regular; Framework Desktop at 192 GB $6,799.
- Runs llama.cpp through ROCm or Vulkan; input speed is its weakness.

#### Self-built GPU machines

- **Used RTX 3090 (24 GB)**: the cheapest CUDA card with 24 GB. $1,425–1,650 on eBay in November 2026, one tracker nearer $2,000. Two fit in a desktop for 48 GB.
- **Radeon AI PRO R9700 (32 GB)**: $1,299 list (October 2025); Newegg listings out of stock. ROCm only.
- **Intel Arc Pro B60 (24 GB)**: $599–660 retail; software support for language models is behind CUDA and ROCm. Not benchmarked here.
- **RTX 5090 (32 GB)**: $1,999 list, $6,200–7,350 street in November 2026.
- **RTX PRO 6000 Blackwell (96 GB)**: $8,565 at launch (March 2025), $13,250 (June 2026), $16,000 list now; retailers $15,000–18,000.
- The rest of the PC (CPU, board, 64–128 GB of system memory, power supply) costs more than in 2025 because of DDR5 prices; the "built" estimates assume about $1,000–1,500 beyond the GPUs and weren't priced part by part.

## Caveats

- **Prices are moving weekly**, and most come from third-party trackers, not the makers' own stores, which didn't render prices. Check before buying.
- No controlled, like-for-like benchmark covers these machines on the models in research 0006. The estimates marked "estimated" are scaled from other models or cards, and the time-per-search table is arithmetic on them. A labelled test set (research 0006) run on the actual machine is the only reliable measure.
- Not verified: M5 Ultra and Mac delivery times; DGX Spark restock; current R9700 stock; self-built parts prices; macOS's GPU memory limit override; whether Ollama runs MLX models; KTransformers and CPU-offloading speeds for the large tier; the 2× Spark figure, which comes from a single source on DeepSeek V4 Flash rather than V4.1.
- Used GPUs carry wear and no warranty; the 3090 draws about 350 W.

## Sources

- Apple: [Mac Studio specs](https://www.apple.com/mac-studio/specs/), [MacRumors M5 Max vs M5 Ultra](https://www.macrumors.com/guide/m5-max-vs-m5-ultra/), [Engadget M5 Ultra review](https://www.engadget.com/2263184/apple-mac-studio-m5-ultra-review/), [MacStories M5 Ultra review](https://www.macstories.net/stories/m5-ultra-mac-studio-review-the-dream-mac-for-local-ai-agents/), [M5 Ultra vs dual DGX Spark (MindStudio)](https://www.mindstudio.ai/blog/m5-ultra-vs-dual-dgx-spark) (third party)
- NVIDIA: [DGX Spark llama.cpp benchmarks](https://github.com/ggml-org/llama.cpp/blob/master/benches/dgx-spark/dgx-spark.md), [llama.cpp discussion 16578](https://github.com/ggml-org/llama.cpp/discussions/16578), [DGX Spark price history (OpenClaw)](https://openclawdc.com/gear/dgx-spark/) (third party), [64 GB DGX Spark (Techaeris)](https://techaeris.com/2026/10/03/nvidia-unveils-64gb-dgx-spark-at-4999/) (third party), [DGX Station listings (Tom's Hardware)](https://www.tomshardware.com/desktops/nvidias-gb300-powered-dgx-station-desktop-tower-listed-for-nearly-usd100-000-online-enterprise-ai-powerhouse-now-available-to-buy-for-mere-mortals-with-lots-of-cash), [Dell Pro Max with GB300](https://www.dell.com/en-us/shop/desktop-computers/dell-pro-max-with-gb300/spd/dell-pro-max-fct6263-desktop/xcto_fct6263_usx)
- AMD: [Ryzen AI Max+ 395 mini PC prices (Liliputing)](https://liliputing.com/more-ryzen-ai-max-395-mini-pcs-with-128gb-are-now-available-if-you-can-afford-one/), [Strix Halo benchmarks (Presenc)](https://presenc.ai/research/amd-strix-halo-local-llm-benchmarks-2026), [Gorgon Halo prices (TechRadar)](https://techradar.com/pro/usd6-399-thats-how-much-gmktec-sells-its-evo-x5-pro-mini-pc-with-an-amd-max-pro-495-and-192gb-ram-and-thats-the-cheapest-fully-loaded-gorgon-halo-device), [Framework Desktop at 192 GB (HWBusters)](https://hwbusters.com/news/framework-desktop-goes-to-192gb-with-gorgon-halo-and-the-price-nearly-doubles-to-6799/), [Radeon AI PRO R9700 pricing (HotHardware)](https://hothardware.com/news/amd-confirms-radeon-ai-pro-r9700-gpu-pricing-release-date)
- Comparisons: [DGX Spark vs Strix Halo vs Mac Studio (ComputingForGeeks, November 2026)](https://computingforgeeks.com/dgx-spark-vs-strix-halo-vs-mac-studio/) (third party), [What GPU do you need for Qwen3.8, Gemma 4 and gpt-oss (RigBase, October 2026)](https://dev.to/rigbase/what-gpu-do-you-need-for-qwen38-qwen36-gemma-4-and-gpt-oss-locally-measured-oct-2026-1eg6) (third party), [RTX 5090 benchmarks dataset](https://huggingface.co/datasets/witcheer/rtx-5090-benchmarks) (third party), [RTX PRO 6000 (llm-tracker)](https://llm-tracker.info/RTX-PRO-6000) (third party), [llama.cpp GPU scoreboard](https://knightli.com/en/2026/04/23/llama-cpp-gpu-benchmark-cuda-rocm-vulkan-scoreboard/) (third party)
- GPU prices: [RTX 5090 (Thunder Compute)](https://www.thundercompute.com/blog/nvidia-rtx-5090-pricing) (third party), [RTX PRO 6000 at $16,000 (VideoCardz)](https://videocardz.com/newz/nvidia-raises-rtx-pro-6000-blackwell-price-to-16000-now-87-above-original-msrp), [used RTX 3090 (OpenClaw)](https://openclawdc.com/gear/rtx-3090/) (third party), [Intel Arc Pro B60 (Wccftech)](https://wccftech.com/us-store-lists-intel-arc-pro-b60-at-just-599/) (third party)
