---
status: current # current | outdated | superseded by NNNN
date: 2026-11-22 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Self-hosted models on rented GPUs

## Question

Research 0006 showed that searching a large collection with a strong cloud model, billed per token, can cost tens to hundreds of dollars per search. Is there a third option between local and token-billed cloud models: running an open model on rented GPUs, billed only for the compute time while the server runs, and with more concurrency than one local GPU? Which platforms offer this, how private are they, and what would each search cost, for stated and inferred searches (spec 0004) over small, medium and large collections? Informs spec 0004's providers and concurrency, and the OpenAI Chat Completions provider on the roadmap.

## Recommendation

### Summary

| Use | Recommendation | Why |
| --- | --- | --- |
| Platform | **Modal**, running vLLM or SGLang | Per-second billing, scales to zero after 60 s idle, request payloads never stored; trust score 7 |
| Most private platform | **Tinfoil Containers** | Attested confidential GPUs (H200, B200); trust score 9; price on request |
| Stated searches | **A token-billed Flash model** (GLM-5.3 Flash), or **local** | Self-hosting costs about the same or more at every size; choose it only to remove the model host |
| Inferred searches, small and medium | **DeepSeek V4.1 Flash billed per token**, or self-hosted for privacy | Start-up time dominates small self-hosted runs |
| Inferred searches, large | **Self-hosted DeepSeek V4.1 Flash on 4×B200**, about half the token price | Long reasoning output is cheap on a GPU kept busy |
| Best results, large | **Self-hosted Kimi K3.1 Pro on 8×B300**, about half the token price | Below about 20 MB, its long start-up makes tokens cheaper |
| Avoid | AWS ECS on Fargate, EC2 Mac, RunPod Community Cloud for private notes | No GPUs; a 24-hour minimum; unvetted third-party hosts |

### Details

- **No new kind of provider is needed.** vLLM and SGLang serve the OpenAI Chat Completions API with JSON-schema structured outputs, so the OpenAI Chat Completions provider on the roadmap reaches a self-hosted model through its URL. Ollama itself can also run on a rented GPU and be reached through spec 0004's `SPIRITOR_SEARCH_OLLAMA_URL`, but it is built for one user, not for hundreds of parallel requests, so most of the speed and cost advantage is lost.
- **Starting and stopping the server is the user's job** (decision 0008). Serverless GPU platforms do it automatically: the first request starts a container and idle time stops it.
- **Concurrency decides the cost.** A rented GPU is cheap per token only when it serves many requests at once, which an exhaustive search can supply, one request per file. Spec 0004's concurrency default of 1 suits a local GPU. A self-hosted endpoint needs 64 to 256.
- **Cost follows a model's active parameters, not its total size.** A mixture-of-experts model needs many GPUs to hold its weights, but only a small part of the model computes each token. DeepSeek V4.1 Flash (552B total, 16B active) on 4×B200 reads input about 14 times as fast as Qwen3.8 27B (dense) on one H100, for about 6 times the hourly price.
- **Start-up is a fixed cost per search.** Loading weights runs at about 1 to 2 GB/s, so it takes about a minute for a 27B model, about 4 minutes for DeepSeek V4.1 Flash and about 18 minutes for Kimi K3.1 Pro, and it is billed. Larger collections spread it over more work, which is why self-hosting pays off at the large size first.
- **Measure before relying on these figures.** The self-hosted costs below are estimates from GPU compute rates, not measurements. One `vllm bench serve` run at this workload's input and output lengths, on one rented GPU for a few dollars, would replace them.

## Findings

### Summary

#### Platforms

Trust score is research 0005's rubric, out of 10: how the promise is checked (0–5), what exists to leak or be compelled by default (0–3), and record (0–2). For self-hosting it scores the GPU platform. No model provider is involved, because the user runs open weights themselves. "Exposure" assumes the server doesn't log requests (vLLM's default) and the user's own code doesn't either.

| Platform | Trust score | Billing | Scale to zero | Largest setup | Request content kept | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Local (Ollama) | **10** (5+3+2) | Own hardware | n/a | The user's GPU | Nothing leaves the machine | The reference point |
| Tinfoil Containers | **9** (4+3+2) | Usage-based; rates not published | Not checked | Confidential H200 and B200 | Encrypted to the enclave | Most private; price unknown |
| Modal | **7** (2+3+2) | Per second; CPU and memory extra; $30/month free credit | Yes, after 60 s idle by default | 8 GPUs per container, up to B300 | Server payloads "Not stored"; container logs 1 day (Starter) or 30 days (Team) | **Recommended** |
| Hugging Face Inference Endpoints | **6** (2+3+1) | Per minute of uptime (not checked) | Yes, after 15 min idle | Multi-GPU (not checked) | Payloads not stored; logs 30 days | Good; slow to scale down; returns 502 while starting |
| Google Cloud Run | **6** (2+3+1) | Per second, GPU plus at least 20 CPUs and 80 GiB memory for an RTX PRO 6000 | Yes; about 5 s start-up | **One GPU per instance** | Nothing unless the app logs it | Fast start-up, but too small for the large models |
| RunPod Serverless (Secure Cloud) | **6** (2+2+2) | Per second | Yes | Multi-GPU | Retention not stated | Higher serverless prices than Modal |
| AWS EC2 GPU instances | **6** (2+3+1) | Per second while running; storage while stopped | No: the user stops it | 8 GPUs per machine | Nothing unless the app logs it | Most expensive; capacity may be gone on restart |
| RunPod Community Cloud | **4** (1+2+1) | Per second; cheapest | Pods: no | Varies by host | Retention not stated | Avoid for private notes |

#### Cost per search

Sizes, from research 0004's typical personal notes collection: **small** 2 MB, **medium** 20 MB (10×), **large** 40 MB (20×). Per research 0006, 1 MB is about 0.4 million input tokens with the prompt and line numbers. Stated searches run without reasoning, with about 0.05 million output tokens per MB. Inferred searches run at low reasoning, with about 0.25 million per MB. Each mode lists only the top picks for that kind of search. Wall-clock times for token-billed models depend on the host's rate limits and aren't estimated.

Stated searches:

| Option | Model | Small, 2 MB | Medium, 20 MB | Large, 40 MB |
| --- | --- | --- | --- | --- |
| Local, 8 GB GPU | `qwen3.5:9b` Q4_K_M | Free; 1–2 h | Free; 10–20 h | Free; 20–40 h |
| Billed per token | GLM-5.3 Flash | $0.18 | $1.80 | $3.60 |
| Self-hosted, Modal 1×H100 | Qwen3.8 27B, FP8 | $0.50; 6 min | $2.50; 35 min | $5; 70 min |

Inferred searches:

| Option | Model | Small, 2 MB | Medium, 20 MB | Large, 40 MB |
| --- | --- | --- | --- | --- |
| Local, 8 GB GPU | `qwen3.5:9b` Q4_K_M, low reasoning | Free; 2–5 h | Free; 20–50 h | Free; 40–100 h |
| Billed per token, best value | DeepSeek V4.1 Flash | $0.85 | $8.40 | $17 |
| Self-hosted, Modal 4×B200 | DeepSeek V4.1 Flash, FP4 | $3; 6 min | $6; 13 min | $9; 20 min |
| Billed per token, best results | Kimi K3.1 Pro | $6.60 | $66 | $130, more at high reasoning |
| Self-hosted, Modal 8×B300 | Kimi K3.1 Pro, FP4 | $22; 21 min | $43; 41 min | $66; 63 min |

The self-hosted figures could be half or double these. They include start-up and Modal's CPU and memory charges, taken as 10% on top of the GPU price.

### Details

#### How the self-hosted estimates were made

- **Prices** are Modal's per-second list prices (read 2026-11-22): H100 $3.95/h, B200 $6.25/h, B300 $7.10/h per GPU. A region-pinning multiplier of 1.15–1.75× applies only when a region is chosen.
- **Reading input** (prefill) is compute-bound. A token costs about 2 × active parameters in floating-point operations. The estimates assume 30% of each GPU's dense FP8 peak, and halve the result for mixture-of-experts models to allow for traffic between GPUs. That gives about 5,500 tokens/s for Qwen3.8 27B on one H100, 75,000 for DeepSeek V4.1 Flash on 4×B200, and 26,000 for Kimi K3.1 Pro on 8×B300.
- **Writing output** (decode) is limited by memory bandwidth and gains from batching many requests. Assumed aggregate rates: 2,000 tokens/s for Qwen3.8 27B on one H100, 15,000 for DeepSeek V4.1 Flash on 4×B200, and 5,000 for Kimi K3.1 Pro on 8×B300.
- **Start-up** loads weights at about 1.5 GB/s, plus about a minute to start the server. FP8 Qwen3.8 27B is about 28 GB, FP4 DeepSeek V4.1 Flash about 300 GB, and FP4 Kimi K3.1 Pro about 1.5 TB. Each run adds Modal's 60 seconds of idle time before it scales down.
- **Wall-clock times are for one replica.** Running N replicas divides the time by about N at the same compute cost, but adds a start-up for each replica.
- **Evidence the assumptions are conservative:** SemiAnalysis's InferenceX benchmark reports about 50,000 tokens/s per H200 serving DeepSeek V4.1 Flash with vLLM at FP4, at 50 tokens/s per user, on an agentic coding workload (November 2026). That workload reuses cached prompt prefixes heavily, which a search across different files can't, so it isn't comparable directly.

#### Why self-hosting doesn't win stated searches

The cheapest open models are already priced near their compute cost by hosts that keep GPUs full: GLM-5.3 Flash costs $0.15 per million input tokens on Ollama Cloud. A dense 27B model reads input more slowly per GPU-second than a model with 3B to 16B active parameters, and a one-GPU replica pays start-up on every search. Self-hosting a small-active mixture-of-experts model such as Qwen3.5 35B-A3B would cost less, but research 0006 grades it about equal to the 9B model, which runs locally.

#### Platforms

- **Modal.** Retention, from its security page: request and response payloads for Servers and Endpoints are "Not stored — proxied directly to the serving container"; Function inputs and outputs are kept "Up to 7 days"; container logs follow the plan ("1 day on Starter, 30 days on Team"), so "ensure that your code does not log request or response payloads". Containers run "isolated from the host, using primitives like gVisor or microVMs". SOC 2 Type II with no deviations (January 2025); a DPA is on its Trust Center. Memory snapshots can shorten start-up, but Modal says they help little when most start-up is loading weights. No incidents found.
- **Hugging Face Inference Endpoints.** "Hugging Face does not store any customer data in terms of payloads or tokens… We are storing logs for 30 days." SOC 2 Type 2; a GDPR DPA only with an Enterprise Hub subscription. Scales to zero after 15 minutes idle, and returns `502 Bad Gateway` while a replica starts, with no request queue, so clients must retry. Lost a record point: unauthorized access to Spaces secrets (May 2024), after which tokens were revoked and users told to rotate keys.
- **Google Cloud Run.** "You can configure one GPU per Cloud Run instance", up to an RTX PRO 6000 with 96 GB, which can't hold the large models. An RTX PRO 6000 needs at least 20 CPUs and 80 GiB of memory. Instances scale to zero and start in about 5 seconds with drivers pre-installed. The GPU is billed for the instance's whole lifetime. Per-second prices weren't readable from Google's pricing page. Record as Google in research 0005.
- **RunPod.** Its SOC 2, ISO 27001 and PCI DSS claims attach to Secure Cloud's "vetted infrastructure partners". Community Cloud runs on third-party hosts, whom the terms "prohibit… from inspecting your Pod/worker data", a contractual promise only, with hosts unnamed. Serverless prices are about 1.5× Modal's for H100 and B200, while Pods you start and stop cost about half of RunPod's serverless rates. Request and log retention isn't stated. Its security page contained instructions addressed to AI agents, which were ignored.
- **Tinfoil Containers.** Runs any Docker container in an attested enclave on AMD SEV-SNP or Intel TDX, with NVIDIA confidential computing on H200 and B200. Attestation covers the code and model weights. Pricing is "usage-based" and not published. Research 0005's limits on attestation apply (TEE.fail).
- **AWS.** ECS on Fargate has no GPUs; GPUs on ECS need EC2 or ECS Managed Instances, which is EC2 with extra setup. The 8×B200 instance lists at about $114/h on demand (third-party trackers). A stopped instance pays only for storage, but GPU capacity isn't guaranteed when it restarts. EC2 Mac hosts have "a minimum allocation period of 24 hours", which rules them out for pay-while-on use. Record as Amazon in research 0005.

#### Exposure scores

- Modal, Hugging Face, Cloud Run and EC2 get 3: the platform doesn't keep request content unless the user's own server logs it. vLLM logs requests only with `--enable-log-requests`, off by default since v0.10.2.
- RunPod gets 2, because its retention isn't stated and its serverless queue holds job inputs and results for a time (not verified).
- Unlike attested hosts, every platform but Tinfoil can technically read a running container's memory. The "checked" score of 2 reflects audits of their controls, not a technical barrier.

## Caveats

- **The self-hosted costs and times are estimates, not measurements**, and could be half or double. The decode rates are the least certain part. Reasoning length, the biggest unknown in research 0006's token costs, moves the token-billed figures too.
- Not verified: whether Modal can supply 8×B300 or 4×B200 serverless on demand; Hugging Face Endpoints' billing granularity; RunPod's serverless request retention and incident record; Tinfoil Containers' prices and scale-to-zero; Cloud Run's GPU prices (search results gave about $1.31/h for an RTX PRO 6000 from a mirrored page); FP4 quality for DeepSeek V4.1 Flash and Kimi K3.1 Pro against FP8.
- Running a 4- or 8-GPU vLLM deployment needs model-specific settings for expert parallelism and quantization. That setup work isn't costed.
- GPU prices fall over time and change by region. Prices were read on 2026-11-22.
- The local times scale research 0004's rough figure ("an hour or two" for a few megabytes) and weren't measured.

## Sources

- Modal: [pricing](https://modal.com/pricing), [security and privacy](https://modal.com/docs/guide/security), [SOC 2 Type II](https://modal.com/blog/soc2type2), [memory snapshots](https://modal.com/docs/guide/memory-snapshots), [vLLM low-latency example](https://modal.com/docs/examples/vllm_low_latency)
- RunPod: [pricing](https://www.runpod.io/pricing), [security and compliance](https://docs.runpod.io/references/security-and-compliance), [Trust Center](https://trust.runpod.io/)
- Hugging Face: [Inference Endpoints autoscaling](https://huggingface.co/docs/inference-endpoints/en/autoscaling), [Inference Endpoints security](https://huggingface.co/docs/inference-endpoints/en/security), [Spaces secrets disclosure](https://huggingface.co/blog/space-secrets-disclosure)
- Google: [Cloud Run GPU support](https://docs.cloud.google.com/run/docs/configuring/services/gpu), [Cloud Run pricing](https://cloud.google.com/run/pricing)
- Tinfoil: [Tinfoil Containers](https://tinfoil.sh/blog/2026-03-10-tinfoil-containers), [pricing](https://tinfoil.sh/pricing)
- AWS: [EC2 Mac instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html), [ECS GPU sharing (Fargate unsupported)](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-gpu-sharing.html), [GPU workloads on ECS Managed Instances](https://aws.amazon.com/blogs/containers/how-ramp-runs-gpu-ai-workloads-at-scale-with-ecs-managed-instances/), [p6-b200 price (Vantage)](https://instances.vantage.sh/aws/ec2/p6-b200.48xlarge) (third party)
- vLLM: [logging configuration](https://docs.vllm.ai/en/stable/examples/features/logging_configuration/), [request logging default (forum)](https://discuss.vllm.ai/t/no-received-request-after-vllm-v0-10-2/1649)
- Benchmarks and loading: [InferenceX, DeepSeek V4.1 Flash on H200](https://inferencex.semianalysis.com/run/deepseek-v41-flash-on-h200) (third party, unofficial mirror), [ServerlessLLM (loading times)](https://arxiv.org/pdf/2401.14351)
