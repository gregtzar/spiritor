---
status: current # current | outdated | superseded by NNNN
date: 2026-11-21 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Model provider data privacy and billing

## Question

When a user sends content to a remote model provider, what happens to it: how long it's kept, whether it trains models, whether zero data retention (ZDR) is offered and to whom, and how likely the provider is to keep its promises? Which providers bill per token, by subscription or otherwise? Is any hosted inference "zero trust", needing no trust in the provider at all? Informs `README.md`, which decision 0007 requires to tell users where each provider sends their content and how long it's kept, and future choices of remote providers.

## Recommendation

### Summary

- **Local stays the only zero-trust option.** A hosted model must see plaintext, so every remote provider is trusted to some degree. Attested confidential inference (Tinfoil, Privatemode) narrows that trust to the chip vendors and published code, but physical attacks have broken it (TEE.fail, 2025).
- **Ollama Cloud is ZDR by default on every plan, including pay as you go**, with no training. It is the only provider here that offers ZDR to everyone without a request, but the promise rests on a privacy policy alone: no contract, DPA, audit, certification or named hosts.
- **The frontier labs match the pattern the maintainer noticed:** about 30 days' retention by default on the API, no API training, and ZDR only by sales approval. Their consumer subscriptions train by default (OpenAI, Google, Mistral) or after the user opts in (Anthropic, up to 5 years). Their promises are the most enforceable: contracts, SOC 2 and ISO audits, and regulators.
- **Self-serve ZDR exists among open-model hosts:** Groq and Together let any customer turn it on; OpenRouter can route only to ZDR endpoints per request; Bedrock sets it per region.
- **Avoid DeepSeek's first-party service** for private content: data is stored in the People's Republic of China, kept for the life of the account, and may train models.
- **Trust scores** (out of 10, rubric under "Trust score"): local 10; attested services 9; Fireworks 7; Groq and Together 6; Bedrock 5; Ollama Cloud, Anthropic, OpenAI, Google, Microsoft, Mistral and OpenRouter 4; xAI 3; DeepSeek 0.

### Details

- `README.md` should state, per supported provider, the retention, training and ZDR facts in the summary table below, with links to the provider's own pages, since these change often.
- For users who want a remote model with guarantees stronger than a policy page, Tinfoil and Privatemode expose OpenAI-compatible APIs over open models, so an OpenAI-compatible provider in Spiritor would reach them. Whether to support them is a decision for a later spec.
- Retention that ends in deletion is weaker than ZDR: content that exists can be preserved by a court. The OpenAI preservation order (2025) held deleted consumer chats and non-ZDR API content for months; ZDR customers were excluded because there was nothing to keep.

## Findings

### Summary

"Trust score" is out of 10, scored as described in "Trust score" below: how the promise is checked (0–5), plus what exists by default to leak or be compelled (0–3), plus the provider's record (0–2). It scores the self-serve API, which is what Spiritor uses; consumer apps are often worse.

| Provider | Trust score | Billing | API default retention | API training | ZDR | Consumer apps | Jurisdiction | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Local (Ollama, faster-whisper) | **10** (5+3+2) | Free; own hardware | Nothing leaves the machine | No | Inherent | n/a | User's own | The reference point |
| Tinfoil | **9** (4+3+2) | Per token; chat $20/month; GPU hours | None except encrypted in-enclave cache | No | Default, and verifiable | Chat app | US | Strongest hosted option |
| Privatemode (Edgeless Systems) | **9** (4+3+2) | Usage-based | None; encrypted to the enclave | No | Default, and verifiable | Chat app | EU | Strongest hosted option |
| Fireworks AI | **7** (2+3+2) | Per token; dedicated GPUs | None for open models (Responses API `store` keeps 30 days) | Not stated | Enterprise only, as an enforced policy | n/a | Not checked | Good by default |
| Groq | **6** (2+2+2) | Per token | None by default; abuse logs 30 days | Not stated | **Self-serve** toggle for all customers | n/a | US (GCP) | Good |
| Together AI | **6** (2+2+2) | Per token; dedicated GPUs | History kept until deleted | Only with opt-in | **Self-serve** toggle | n/a | Not stated | Good once toggled |
| Amazon Bedrock | **5** (2+2+1) | Per token in AWS | Mode per region; `none` is zero retention | Not shared with model makers | Self-serve (`none`); models that require review (Fable) keep 30 days | n/a | Customer-chosen region | Strong, self-serve ZDR |
| Ollama Cloud | **4** (0+3+1) | Per token at each model's rate; plans include monthly credits (Pro $20, Max $100, Team $500), or pay as you go | None: "processed transiently" | Never | **Default for everyone**, no request | Same service | US, overflow to Europe | Best default; trust on its word |
| Anthropic | **4** (2+1+1) | API per token; Claude Pro/Max subscriptions | 30 days | No (feedback excepted) | By sales request; not for Covered Models (Fable, Mythos), which keep 30 days | Training only if the user opts in; then up to 5 years, otherwise 30 days | US | Strong, but ZDR shrinking for newest models |
| OpenAI | **4** (2+1+1) | API per token; ChatGPT subscriptions | 30 days (abuse logs) | No since March 2023 | By sales approval; many endpoints excluded | Free/Plus/Pro train by default (opt-out) | US and vendors' countries | Strong on API with ZDR; consumer weak |
| Google (Vertex AI, paid Gemini API) | **4** (2+1+1) | Per token through Cloud Billing; Google AI subscriptions | Paid: "limited period" for abuse; free tier kept and human-reviewed | Free tier: yes; paid: no | Vertex AI only; some features can't be ZDR | Trains when Gemini history is on; kept 18 months; reviewed chats 3 years | Customer-chosen regions (Vertex) | Vertex strong; free API tier is not private |
| Microsoft (Azure Foundry) | **4** (2+1+1) | Per token in Azure | Stored for human abuse review in the customer's geography | No | "Modified abuse monitoring" by application; ending for models released from November 2026 | n/a | Customer-chosen geography | Strong, but its ZDR path is closing |
| Mistral | **4** (2+0+2) | Per token; Le Chat/Vibe subscriptions; free mode | Not stated | Free mode: yes; pay as you go: opt-out | Pay as you go, stateless calls, at Mistral's discretion | Free and paid individual plans train unless opted out | EU (company) | Usable with opt-out and ZDR |
| OpenRouter (router) | **4** (0+2+2), and no higher than the provider routed to | Per token, passes through provider prices | Depends on the provider routed to | Can exclude training providers | **Per request** (`zdr: true`) or per account | n/a | In-region routing on Business plans | Useful for enforcing ZDR |
| xAI (Grok) | **3** (1+1+1), partly unverified | API per token; SuperGrok and X Premium subscriptions | 30 days (third-party summaries) | No (third-party summaries) | Reported self-serve per team; unverified | Not verified | US | Weak record |
| DeepSeek (first party) | **0** (0+0+0) | Per token | Kept for the life of the account | Yes, opt-out by request | None | Same | China | Avoid for private content |

### Details

#### Ollama Cloud

- Privacy policy (updated March 2026): content of cloud requests is processed "transiently to provide the Service and this content is not stored beyond the time required to fulfill the request". The cloud FAQ: "Ollama operates with a zero data retention (ZDR) policy" and "does not store or log that content and never trains on it". No plan, including Enterprise, mentions ZDR as an option, because it applies to all.
- Metadata is kept: app version and request counts, and diagnostic metadata, none including content.
- Hosts are unnamed: Ollama "collaborates with NVIDIA Cloud Providers (NCPs)" and requires of them "no logging, no training, and zero data retention policies". The privacy policy also lists unnamed "model inference providers". GitHub issue 14279 (February 2026) asked whether Qwen 3.5 requests went to Alibaba, at the time the only host of that model; no Ollama staff answered, and the author closed it.
- Exceptions: the policy may disclose "your information" when required by law or to investigate policy violations, without saying whether that can include content. With transient processing there should be no content to disclose.
- No DPA, SOC 2, ISO certification or sub-processor list was found. A GDPR review (InferCheck, April 2026) found the same.
- Billing changed from session and weekly limits to tokens: plans now include monthly usage credits, metered per token at each model's rate, with off-peak discounts. Local models stay unlimited.

#### Anthropic

- API: inputs and outputs deleted "within 30 days"; flagged content kept up to 2 years, and safety classification scores up to 7 years. ZDR by request to sales, per organization; under it, safety classifier results are still kept.
- Covered Models (Claude Fable 5 and Mythos 5 from June 9, 2026, and their 5.1 and 5.2 versions) "require 30-day data retention", even for ZDR organizations, except a limited-time transition offer for Fable. Anthropic plans "Enterprise Frontier Safeguards", storing that data in the customer's own cloud, by invitation (The Register, September 2026).
- ZDR excludes the Console, consumer plans, Team and Enterprise app interfaces (Claude Code on Enterprise has its own ZDR offering), and features such as the Files API, Batch and code execution.
- Consumer plans (since the October 2025 terms): training only with the setting on, then de-identified data kept up to 5 years; otherwise 30 days. Feedback is kept 5 years either way.
- On Bedrock and Google-managed Vertex, the cloud provider is the processor and its retention applies.

#### OpenAI

- API: abuse monitoring logs "retained for up to 30 days, unless longer retention is required by law". ZDR and Modified Abuse Monitoring need "prior approval by OpenAI"; stateful endpoints (Assistants, threads, files, vector stores, batches, fine-tuning) are not eligible. Image and file inputs flagged as possible CSAM are kept for review even under ZDR.
- ChatGPT Free, Plus and Pro train by default, with an opt-out; temporary chats are kept up to 30 days; thumbs-up or -down feedback can send a whole conversation to training despite the opt-out. Business, Enterprise and Edu don't train by default.
- The New York Times lawsuit's preservation order made OpenAI keep deleted and temporary consumer chats and non-ZDR API content from May 2025 until September 26, 2025; that data stays under legal hold. Enterprise, Edu and ZDR customers were excluded.

#### Google

- Gemini API free tier: Google uses content "to provide, improve, and develop Google products" and human reviewers "may read, annotate, and process" it. Paid tier: no training; logs kept "for a limited period of time" for abuse detection. In the EEA, Switzerland and the UK, paid terms apply to all use.
- ZDR is not available on the Gemini API: "use Vertex AI". On Vertex it is a configuration: no request logging, caching disabled, `store` off, and no Google Search or Maps grounding, which keep data 3 and 30 days with no way to turn it off.
- Gemini app: history auto-deletes after 18 months by default; human-reviewed chats are kept up to three years, even after the user deletes them.

#### Open-model hosts and clouds

- Groq: "does not retain customer data for inference requests" by default; "All customers may enable Zero Data Retention" in settings.
- Together AI: no training "without your explicit opt-in"; choosing "No" in privacy settings enables ZDR, from that moment on.
- Fireworks AI: doesn't log open-model prompts without opt-in; ZDR as an account policy is enterprise-only.
- OpenRouter: labels each endpoint as ZDR, safety retention, or retention and training, and assumes the worst when a provider's policy is unclear. Google's safety retention on Vertex keeps flagged prompts up to 90 days from October 2026.
- Amazon Bedrock: retention mode `none` per region; "does not share your content with model providers". Models that require review (Claude Fable) are blocked under `none` without an exception.
- Azure Foundry: prompts are stored for human abuse review unless Modified Abuse Monitoring is approved; from November 2026 it won't be offered for newly released models. Frontier labs are moving toward mandatory retention for their newest models.
- Mistral: ZDR only on pay as you go, for stateless calls, approved "at our discretion"; Labs and preview models ignore the training opt-out.
- DeepSeek: "we directly collect, process and store your Personal Data in People's Republic of China", kept "as long as you have an account", and used "to train and improve our technology". Italy's regulator banned its app in January 2025. Its open-weight models run privately on Ollama or other hosts; the risk is the first-party service.

#### Zero-trust inference

A provider can't run a model on content it can't read, so end-to-end encryption in the usual sense is impossible; Apple says cloud AI "requires unencrypted access to the user's request". The alternatives:

- **Attested confidential computing.** The model runs in a hardware enclave (AMD SEV-SNP or Intel TDX CPUs with NVIDIA Hopper or Blackwell GPUs in confidential mode). The client checks a hardware-signed attestation that the published, reproducibly built code and model are running, and encrypts only to that enclave. The operator can't read content, but the user trusts the chip vendors, the published code, and the hardware holding up. Apple Private Cloud Compute (own use only), Tinfoil and Privatemode work this way; Tinfoil verifies on every connection, Privatemode when trust is first established.
- **The hardware has been broken physically.** TEE.fail (October 2025) used a sub-$1,000 memory-bus probe on DDR5 servers to extract keys from Intel TDX and AMD SEV-SNP and forge NVIDIA GPU attestations; WireTap and Battering RAM did the same on DDR4. AMD and Intel consider physical attacks out of scope. This needs physical access to the server, so it's a risk from the data center operator or a state, not from a remote attacker.
- **Cryptographic inference** (fully homomorphic encryption or multi-party computation) needs no trusted hardware, but it is still far too slow for language models in production. Not verified for this record.

#### Trust score

The question "can I trust them to do what they say, and to behave ethically with data?" is scored out of 10, from three parts. The scale borrows from vendor risk assessment practice, which scores assurance evidence, data exposure and incident history separately; the weights are this record's own.

- **How the promise is checked, 0–5.** 0: a privacy policy page only, which the provider can change. 1: binding terms or a DPA. 2: as 1, plus an independent audit of the controls (SOC 2 Type II or ISO 27001). 4: hardware attestation of published code, so the operator can't read content. 5: content never leaves the user's machine. The jump from 2 to 4 is deliberate: attestation changes "they promise not to look" into "they can't look".
- **What exists to leak or be compelled, by default, 0–3.** 0: content trains models, or is kept more than 30 days. 1: kept up to 30 days, no training. 2: ZDR any customer can turn on. 3: ZDR by default. Data that doesn't exist can't be breached, subpoenaed or quietly reused.
- **Record, 0–2.** Start at 2 and lose 1 for each of these, to a floor of 0: acted against its own privacy promises or settings, or used others' data unlawfully, per a court, a regulator or its own admission; a breach or leak exposing user data, at the company or a vendor; not disclosing who processes content; a legal duty to assist state intelligence on request.

What the ends mean: **10** needs no trust in anyone, which only local inference achieves. **9** is the most a hosted service can reach, because the enclave hardware has been broken by physical attack. **0** means proven untrustworthy on all three counts.

| Provider | Checked | Exposure | Record, and what it lost points for |
| --- | --- | --- | --- |
| Local | 5 | 3 | 2 |
| Tinfoil, Privatemode | 4 | 3 | 2: none found; young companies |
| Fireworks AI | 2: SOC 2 Type II, ISO | 3: open models not logged | 2 |
| Groq | 2: SOC 2 Type II (Groq's community forum, 2024) | 2 | 2 |
| Together AI | 2: SOC 2 Type 2 (2025), ISO 27001 (2026) | 2 | 2 |
| Amazon Bedrock | 2 | 2 | 1: kept children's Alexa recordings after parents asked for deletion (FTC and DOJ, $25 million, 2023) |
| Ollama Cloud | 0: no DPA or audit found | 3 | 1: doesn't name its inference hosts |
| Anthropic | 2 | 1: ZDR by sales only | 1: trained on pirated books; the court found the piracy not fair use (Bartz, June 2025), settled for $1.5 billion |
| OpenAI | 2 | 1 | 1: API users' profile data stolen from its analytics vendor Mixpanel (November 2025) |
| Google | 2 | 1: Vertex abuse-logging opt-out needs approval | 1: jury found it kept collecting app data after users turned Web & App Activity off (Rodriguez, $425 million, September 2025; under appeal) |
| Microsoft | 2 | 1 | 1: Storm-0558 email breach, which the US Cyber Safety Review Board blamed on "a cascade of security failures" (2024) |
| Mistral | 2: SOC 2 Type II, ISO 27001 and 27701 | 0: pay as you go trains unless opted out | 2 |
| OpenRouter | 0: not checked | 2: ZDR per request | 2 |
| xAI | 1: terms exist; audits not verified | 1 | 1: over 370,000 shared Grok chats indexed by search engines without warning users (August 2025) |
| DeepSeek | 0 | 0 | 0: chat logs exposed in an open database (Wiz, January 2025); banned in Italy (January 2025); PRC intelligence law requires assisting state intelligence work |

Limits of the score:

- A clean record from a young or small company reflects less scrutiny as much as better conduct. Fireworks, Groq, Together, Tinfoil and Privatemode have had far less exposure than the large labs.
- Its "ethics" covers data handling only, not other conduct such as safety practices or labour.
- Ties are meaningful. Most large providers land at 4: audited, short retention, one blemish. Trusting them is trusting their word plus their auditors.
- Pending cases, such as The New York Times suit against OpenAI and the Irish DPC's proceedings over X training Grok on EU posts, don't count until decided.

#### How likely promises are kept

No provider's internal handling can be verified from outside, except attested services. What makes a promise more likely to hold:

- **Binding terms.** Commercial terms and DPAs are contracts; privacy policies can be changed by the provider, though in the US the FTC treats breaking a published privacy promise as a deceptive practice.
- **Audits.** SOC 2 and ISO 27001 auditors test that stated controls operate; Anthropic, OpenAI, Google, AWS and Microsoft have them; Ollama has none published.
- **Regulators.** EU regulators have acted: Italy fined OpenAI €15 million in 2024 (annulled by a Rome court in March 2026 on jurisdiction), banned DeepSeek, and Ireland's DPC opened proceedings over X training Grok on EU posts.
- **Nothing to hand over.** Courts and governments can compel retained data, overriding deletion promises (the OpenAI order); ZDR and attestation leave nothing to compel.
- **Direction of travel.** Retention is growing for the newest frontier models (Anthropic's Covered Models, Bedrock's review mode, Azure ending Modified Abuse Monitoring), justified as misuse prevention. Expect ZDR on frontier models to keep narrowing.

## Caveats

- Policies change quickly; several pages changed in the weeks before this record. Check the provider's own page before relying on a fact.
- xAI's legal pages refused automated fetching; its row rests on third-party summaries. Grok consumer policies and the 2025 report of shared Grok chats appearing in search results weren't checked.
- Not verified: Anthropic and OpenAI subscription prices; Google AI subscription terms; Mistral and Together API retention periods; billing for Groq, Fireworks and Together; Google Private AI Compute, NEAR AI and Phala confidential offerings; Tinfoil and Privatemode model lists and prices; the current state of homomorphic encryption for language models.
- The PRC intelligence-law deduction rests on the National Intelligence Law (2017, article 7), cited from background knowledge, not fetched for this record.
- Ollama's "old plans" session and weekly limits aren't defined on its current pricing page.
- Some quotes came from summarized page fetches; wording should be checked against the live page before quoting externally.

## Sources

- Ollama: [privacy policy](https://ollama.com/privacy), [cloud docs](https://docs.ollama.com/cloud), [cloud FAQ](https://docs.ollama.com/cloud/faq), [pricing](https://ollama.com/pricing), [terms](https://ollama.com/terms), [issue 14279](https://github.com/ollama/ollama/issues/14279), [InferCheck GDPR profile](https://infercheck.eu/en/provider/ollama-cloud) (third party)
- Anthropic: [API and data retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention), [organization data retention](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data), [commercial training](https://privacy.claude.com/en/articles/7996868-is-my-data-used-for-model-training), [consumer training](https://privacy.claude.com/en/articles/10023580-is-my-data-used-for-model-training), [consumer retention](https://privacy.claude.com/en/articles/10023548-how-long-do-you-store-my-data), [consumer terms update](https://www.anthropic.com/news/updates-to-our-consumer-terms), [ZDR scope](https://privacy.claude.com/en/articles/8956058-i-have-a-zero-data-retention-agreement-with-anthropic-what-products-does-it-apply-to), [Covered Models](https://support.claude.com/en/articles/15425695-covered-models), [certifications](https://privacy.claude.com/en/articles/10015870-what-certifications-has-anthropic-obtained), [The Register](https://www.theregister.com/ai-and-ml/2026/09/02/anthropic-promises-zero-data-retention-but-customers-must-check-it-worked/5293789) (third party)
- OpenAI: [your data](https://developers.openai.com/api/docs/guides/your-data), [enterprise privacy](https://openai.com/enterprise-privacy/), [privacy policy](https://openai.com/policies/row-privacy-policy/), [data controls FAQ](https://help.openai.com/en/articles/7730893-data-controls-faq), [chat retention](https://help.openai.com/en/articles/8983778-chat-and-file-retention-policies-in-chatgpt), [response to NYT data demands](https://openai.com/index/response-to-nyt-data-demands/)
- Google: [Gemini API terms](https://aistudio.google.com/docs/terms), [Gemini API ZDR](https://aistudio.google.com/docs/zdr), [Vertex AI data governance](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance), [Gemini Apps privacy hub](https://support.google.com/gemini/answer/13594961)
- xAI: [pricing](https://docs.x.ai/developers/pricing), [developersdigest summary](https://www.developersdigest.tech/models/data-retention/xai) (third party), [zdr.dev summary](https://zdr.dev/e/xai-zdr) (third party)
- Others: [Mistral training](https://help.mistral.ai/en/articles/347617-do-you-use-my-user-data-to-train-your-artificial-intelligence-models), [Mistral ZDR](https://help.mistral.ai/en/articles/347612-can-i-activate-zero-data-retention-zdr), [Mistral commercial terms](https://legal.mistral.ai/terms/commercial-terms-of-service), [Groq](https://console.groq.com/docs/your-data), [Together AI](https://www.together.ai/privacy), [Fireworks data handling](https://docs.fireworks.ai/guides/security_compliance/data_handling), [Fireworks ZDR](https://docs.fireworks.ai/accounts/zero-data-retention.md), [OpenRouter logging](https://openrouter.ai/docs/features/privacy-and-logging), [OpenRouter ZDR](https://openrouter.ai/docs/features/zdr), [Bedrock data protection](https://docs.aws.amazon.com/bedrock/latest/userguide/data-protection.html), [Bedrock data retention](https://docs.aws.amazon.com/bedrock/latest/userguide/data-retention.html), [Azure Foundry data privacy](https://learn.microsoft.com/en-us/legal/cognitive-services/openai/data-privacy), [DeepSeek privacy policy](https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html)
- Zero trust: [Apple Private Cloud Compute](https://security.apple.com/blog/private-cloud-compute/), [NVIDIA confidential computing](https://www.nvidia.com/en-us/data-center/solutions/confidential-computing/), [Tinfoil FAQ](https://tinfoil.sh/security-and-privacy-faq), [Tinfoil pricing](https://tinfoil.sh/pricing), [Privatemode security](https://www.privatemode.ai/security-and-encryption), [Privatemode attestation](https://docs.privatemode.ai/security/attestation/overview/), [TEE.fail (BleepingComputer)](https://www.bleepingcomputer.com/news/security/teefail-attack-breaks-confidential-computing-on-intel-amd-nvidia-cpus/amp/) (third party), [Schneier on secure enclave attacks](https://schneier.com/blog/archives/2025/11/new-attacks-against-secure-enclaves.html) (third party)
- Certifications: [Groq SOC 2 (community forum)](https://community.groq.com/t/is-groq-soc-2-compliant/82), [Together SOC 2](https://www.together.ai/blog/soc-2-compliance), [Together ISO 27001](https://together.ai/blog/iso-27001-2022-certification), [Fireworks certifications](https://docs.fireworks.ai/faq-new/security-compliance/what-type-of-certifications-do-you-have), [Mistral certifications](https://help.mistral.ai/en/articles/323772-do-you-have-soc2-or-iso27001-certification)
- Records: [FTC on Amazon Alexa](https://www.ftc.gov/business-guidance/blog/2023/05/out-mouths-babes-ftc-says-amazon-kept-kids-alexa-voice-data-forever-even-after-parents-ordered), [DOJ on Amazon Alexa](https://www.justice.gov/opa/pr/amazon-agrees-injunctive-relief-and-25-million-civil-penalty-alleged-violations-childrens), [Bartz settlement approved (Jurist)](https://www.jurist.org/news/2026/07/judge-approves-record-1-5-billion-settlement-involving-anthropic/) (third party), [OpenAI on Mixpanel](https://openai.com/index/mixpanel-incident/), [Rodriguez v. Google verdict (Bloomberg Law)](https://news.bloomberglaw.com/litigation/google-violated-privacy-of-nearly-100-million-users-jury-finds) (third party), [CSRB report on Storm-0558](https://www.cisa.gov/sites/default/files/2024-04/CSRB_Review_of_the_Summer_2023_MEO_Intrusion_Final_508c.pdf), [Grok chats indexed (TechCrunch)](https://techcrunch.com/2025/08/20/thousands-of-grok-chats-are-now-searchable-on-google) (third party), [Wiz on DeepSeek's exposed database](https://www.wiz.io/blog/wiz-research-uncovers-exposed-deepseek-database-leak)
- Enforcement: [Garante fine annulled](https://www.gage.academy/tools/eu-ai-act-enforcement-tracker/actions/AIT-2024-0007-garante-openai-fine-annulled-court-of-rome) (third party), [ABA on European enforcement](https://www.americanbar.org/groups/antitrust_law/resources/newsletters/ai-chatbots-meet-european-privacy-enforcement/) (third party)
