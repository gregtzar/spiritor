# Spiritor

Open source Go toolkit for AI-assisted content generation, starting with writing: a CLI and importable Go module. Privacy first: it is designed to run locally through Ollama (local models and Ollama Cloud), with frontier model APIs (such as OpenAI and Anthropic) as an explicit opt-in (see decision 0004). There is no website: https://spiritor.ai redirects to the GitHub repo, so `README.md` is the public landing page.

## Where things are documented

Each fact has one home. Read the relevant file before acting rather than assuming:

- `README.md` — the public landing page: what Spiritor is, how to install and use it. Written for users, not contributors.
- `CONTRIBUTING.md` — contribution rules and developer commands.
- `docs/architecture.md` — what exists and runs today, and nothing planned. Read before any structural change.
- `docs/glossary.md` — business terms and their meanings. Use these terms in code and docs.
- `docs/conventions.md` — coding standards and naming rules. Read before writing or changing code.
- `docs/roadmap.md` — the order of work, linking each phase to its spec. Check before starting new work.
- `docs/specs/` — one design per feature or phase: goal, scope, design, open questions, done criteria, and status. Read the relevant spec before working on a feature.
- `docs/integrations/` — facts and quirks of each external system we integrate with (model providers, ffmpeg). Read before working on that integration.
- `docs/decisions/` — why things are the way they are (one record per decision). Check here before proposing an alternative to an existing choice.
- `docs/research/` — dated investigations of options, such as models, providers and libraries, with what was found and recommended. Read before revisiting a topic; findings age, so check the date.

## Commands

- Run commands from the repo root.
- A maintainer's agent runs Git and the GitHub CLI as its own GitHub App, never with a person's credentials or a stored `gh auth login` (see decision 0001). How it gets App tokens is set up outside this repo.
- Standard commands (check, build, install, dependencies) are in `CONTRIBUTING.md`. This section holds only agent-specific commands.

## Branch and release rules

- Work on a feature branch from `main` (outside contributors: on a fork); never commit directly to `main`. Changes reach `main` by squash-merged pull request, and releases are semver tags on `main` (see decision 0002).
- Merging a pull request, tagging a release, rewriting history, and changing rulesets or repository settings each need a maintainer's explicit okay in the current session, one okay per operation (see decision 0003).
- Before every commit, push, merge or release, follow `.claude/skills/check-in-code/SKILL.md`. Never bypass a Git hook.
- Never put secrets (API keys, tokens) in code, config files, test fixtures or docs. Spiritor reads them from the user's environment at run time; docs may name a secret but never contain its value.

## External references

Fetch specific pages from these rather than relying on memory:

- Go: [Effective Go](https://go.dev/doc/effective_go), [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments), [Go doc comments](https://go.dev/doc/comment), [module reference](https://go.dev/ref/mod), [standard library](https://pkg.go.dev/std).
- CLI framework: [Kong](https://github.com/alecthomas/kong).
- Ollama: [API reference](https://github.com/ollama/ollama/blob/main/docs/api.md), [OpenAI compatibility](https://github.com/ollama/ollama/blob/main/docs/openai.md).
- ffmpeg: [documentation](https://ffmpeg.org/documentation.html).

## Keeping documentation current

Documentation is part of every change, not a separate task.

- If a change alters what exists (packages, commands, providers, integrations, configuration, build and release, repo structure), update `docs/architecture.md` in the same change to describe what was actually built. If it changes what users install, run or configure, update `README.md` too.
- New features are designed in a spec before they are built: copy `docs/specs/spec-template.md` to `docs/specs/NNNN-short-title-with-dashes.md`, using the next number in sequence, and link it from `docs/roadmap.md`. Spec and decision numbers are separate sequences; refer to them as "spec NNNN" and "decision NNNN".
- While implementing a spec, keep its `status` current and record deviations from its design under "Implementation notes". When all its "Done when" criteria are met, set it to `done`; it stays in place as the record of how the feature was designed.
- When an open question in a spec is answered, move the answer into the spec's design (or a decision record) and remove the question.
- When researching options before a decision, such as models, providers or libraries, record the findings: copy `docs/research/research-template.md` to `docs/research/NNNN-short-title-with-dashes.md`, using the next number in sequence, and refer to it as "research NNNN". It's a dated snapshot, never updated: when its findings go stale, new research replaces it and the old one becomes `superseded by NNNN` or `outdated`. The decision or spec that acts on it links to it.
- If a change makes or reverses a significant decision — one a future developer or agent might reasonably question or try to undo, or one that outlives a single feature — add a decision record. Choices that only matter inside one feature stay in that feature's spec, which links any decision records it relies on. To add a decision record:
  - Copy `docs/decisions/adr-template.md` to `docs/decisions/NNNN-short-title-with-dashes.md`, using the next number in sequence.
  - Never edit the substance of an accepted decision record. To change a decision, write a new record and set the old one's status to `superseded by NNNN`.
- If a change introduces a new convention, add it to `docs/conventions.md`.
- Keep this file short. It is a map, not a manual; details belong in `docs/`. Only rules that apply to every task (branch, release and secrets rules, commands) live here; never restate content from `docs/`.
- If you are unsure whether something counts as a significant decision, ask.
