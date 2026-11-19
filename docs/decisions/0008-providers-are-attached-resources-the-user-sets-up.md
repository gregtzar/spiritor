---
status: accepted
date: 2026-11-19
---

# Providers are attached resources the user sets up

## Context

Users choose a provider for each capability (decision 0007). Providers need very different setup: faster-whisper needs a Python environment with GPU libraries, OpenAI an account and API key, Ollama a running server. If Spiritor depended on how each user installed their provider, it would break whenever that changed. Some providers do need help to load, though: faster-whisper with CUDA libraries installed through pip, the method its own documentation gives, can't find them unless they are loaded first.

## Decision

Providers are attached resources, as in the Twelve-Factor App's [backing services](https://12factor.net/backing-services): set up independently, and located by Spiritor only through configuration.

- **Provider setup is the user's.** Installing an engine, its drivers and libraries, a Python environment, an account or API key, or a server happens outside Spiritor. `README.md` gives the instructions, and `docs/integrations/` records each provider's facts and quirks.
- **Spiritor's configuration says which provider and how to reach it.** For each capability, through environment variables and flags (see "Secrets and configuration" in `docs/conventions.md`):
  - the provider, a master switch such as `SPIRITOR_SCRIBE_PROVIDER`;
  - the provider's entry point: a command to run for a provider that runs as a local process, or a URL for one reached over the network;
  - its credentials, under the names the provider's own tools use;
  - Spiritor's own options for it, such as concurrency.
- **The provider setting is the only choice.** It decides which other options are required. Options for other providers never select a provider and are ignored. With no provider set, or an unrecognized one, the command stops with an error, even if one provider's other options are all set.
- **Spiritor never changes the user's environment or installs anything.** It calls the entry point, and if that fails, it stops with an error saying what failed and pointing to the setup instructions.
- **Spiritor's integration code may follow a provider's own documented setup to load it**, inside Spiritor's own processes only, and only when that setup is present. For example, Spiritor's faster-whisper helper loads the CUDA libraries that faster-whisper's documented pip install puts in the Python environment, and does nothing when they aren't there.

## Reasons

- Spiritor keeps working whichever way a user installed their provider, as long as the entry point works.
- Each side has one owner: the user owns the provider's setup, and Spiritor owns what it does with the provider.
- An explicit provider switch means configuring two providers can't silently pick one, and stale options for an old provider can't take effect.
- It follows the Twelve-Factor App, which Spiritor follows for configuration as well.

## Alternatives considered

- Spiritor prepares any provider environment it finds, however it was installed — ties Spiritor to every installation method users might choose.
- No help with loading at all, so users write wrapper scripts that prepare the environment, such as setting `LD_LIBRARY_PATH` — an extra setup step for the user, for a setup the provider itself documents.
- Choosing the provider from whichever provider's options are set — ambiguous when several are set, and a leftover option could quietly select a provider.

## Consequences

- Following a provider's documented setup is limited to that one documented method; other installations must work through the entry point on their own.
- Every provider has three documented parts: its setup, its entry point and its options.
