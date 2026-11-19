# Conventions

Coding standards for this repo. Anything a tool can enforce (formatting, vetting, linting) lives in tool config instead and is not repeated here; this file covers what needs judgment.

## Language

- Go, following [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments). Where those and the rules below disagree, the Go guidance wins.
- Code is formatted with `gofmt`.
- Wrap errors with `%w` so callers can inspect them with `errors.Is` and `errors.As`. Existing code wraps with `%v` in places; fix it when touching that code.
- Long-running and network work takes a `context.Context` as its first parameter and honors cancellation.
- No package-level `init` side effects that read the environment or exit; read configuration in `main` or a command and pass it down explicitly. `transcribe/whisper.go` still reads `API_KEY_OPENAI` in `init`.
- Treat data from outside the process (files, model responses, ffmpeg output, flags, environment) as unvalidated: parse it into typed values at the boundary before the rest of the code uses it.

## Naming

- Go's own conventions first: `MixedCaps`, initialisms in one case (`URL`, `ID`, `API`), short receiver names, and short names for small scopes such as loop indexes.
- Beyond that, prefer clear, verbose, self-documenting names. A reader should understand an exported function, type or package-level variable without knowing the rest of the codebase.
  - Good: `TranscribeAudioFile`, `isRemoteProviderAllowed`
  - Avoid: `Do`, `proc`, `data`, `tmp`
- Booleans read as questions: `isForced`, `hasTranscript`.
- Name things after what they mean in the business, not how they are implemented. Use the terms defined in `docs/glossary.md`.
- Package names are short, lowercase, single words that say what the package provides. Avoid catch-all names such as `utils` or `common` (Go Code Review Comments); `utils/` still exists.

## File and folder names

Follow the established convention of each area. Only where none exists, fall back to lowercase snake_case. Never use spaces.

- Go packages: a lowercase folder named as the package, with no underscores or dashes.
- Go files: lowercase snake_case (`sentence_splitter.go`), as in the standard library. Go gives meaning to the suffixes `_test`, `_<os>` and `_<arch>`, so use them only for that meaning.
- Decision records, specs and research: numbered kebab-case (`0001-agents-use-their-own-github-app-identity.md`), the convention of ADR tooling and design-doc processes.
- Files whose names are fixed by a tool or spec keep them: `README.md`, `AGENTS.md`, `go.mod`, `LICENSE`.

## Branches and releases

- Feature branch names are short kebab-case descriptions of the change (`ollama-provider`), matching Git's own conventions.
- Release tags follow [Semantic Versioning](https://semver.org/) with Go's `v` prefix (`v0.2.0`), as the Go module system requires.

## Markdown frontmatter

In YAML frontmatter (`.md` files), quotes signal type:

- Double-quote every value meant to be a **string**, even when YAML doesn't require it: `name: "check-in-code"`.
- Leave a value **unquoted** only when it's meant to be something other than a string. YAML infers the type from the value: `date: 2026-11-18` becomes a date, `true`/`false` become booleans. Quoting one of these silently turns it into a string, so don't quote it "for consistency."

At a glance: quoted = string; unquoted = inferred non-string value.

## Documentation

Each kind of document follows or borrows from an established standard, named here so its structure isn't reinvented and its source can be consulted. `AGENTS.md` says where each kind lives.

| Document           | Standard                                                                                                                                                                                            | What we take from it                                                                                                                                                                                                                                |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `README.md`        | The README convention                                                                                                                                                                               | The entry point for people, and here also the public landing page: what the project is, how to install and use it.                                                                                                                                 |
| `AGENTS.md`        | [AGENTS.md](https://agents.md/), an open format                                                                                                                                                     | A README for coding agents: a short map plus the rules every task follows.                                                                                                                                                                          |
| Go doc comments    | [Go doc comments](https://go.dev/doc/comment)                                                                                                                                                       | Every exported identifier and package has a doc comment, rendered on pkg.go.dev.                                                                                                                                                                    |
| Decision records   | Michael Nygard's [architecture decision records](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions), with "Alternatives considered" from [MADR](https://adr.github.io/madr/) | One short record per decision: context, decision, consequences. A record is never rewritten; a new one supersedes it.                                                                                                                               |
| Specs              | Design docs, as used in RFC processes                                                                                                                                                               | Goal, scope, design, open questions and a status that tracks the work, kept afterwards as the design record.                                                                                                                                        |
| Research           | [Bottom line up front](<https://en.wikipedia.org/wiki/BLUF_(communication)>) and Barbara Minto's pyramid principle, with "considered options" from MADR                                             | The answer first, then more detail at each level, so a reader can stop as soon as they have what they need. Each summary stands alone, and its details add to it without restating it. Options are compared against the same criteria in one table. |
| `docs/glossary.md` | Domain-Driven Design's ubiquitous language                                                                                                                                                          | One meaning per business term, used the same way in conversation, docs and code.                                                                                                                                                                    |

Templates link here rather than repeating this table, because every document copied from a template would carry it.

## Principles

- Established industry practices take precedence over this repo's own preferences; the preferences apply where no standard exists.
- Name the standard or pattern a design follows or borrows from, where that design is recorded: a decision record, a rule here, or `docs/architecture.md`.
- Each language or domain keeps its own conventions; map explicitly at the boundaries. For example, a model provider's JSON field names and types are translated to ours inside that provider's package and never leak into commands.
- Packages have explicit responsibilities and contracts. Translate at the seam rather than sharing one package's internal types with another.
- Prefer the Go standard library over adding a dependency, unless requirements genuinely exceed it.
- When a dependency is needed, prefer minimal, composable libraries with strong external contracts and first-class support for their domain's standard specs. A good framework solves common patterns well without dictating overall architecture; avoid both unstructured code and do-it-all black boxes built on proprietary concepts.
- Agents-first, editor-independent: all tooling (formatter, linter, tests, build) is run through the command line and configured in repo files, so agents and CI run exactly what a human does. Editors are optional authoring tools that may read the repo's config but never add behaviour, settings or tooling the project relies on.
- Scripts do repeatable work; agents do judgment. Any deterministic step (checks, comparisons, test runs, data extraction, waiting on external state) is a committed script or established tool that reports concisely, never work an agent repeats by reasoning.
- One way of doing each thing. Before introducing a new pattern or library, check whether the codebase already solves the problem, and follow the existing approach.
- If a new pattern is genuinely better, add it here and note where the old pattern still exists.
- Minimize hidden "magic": prefer explicit code that can be followed by reading it over clever shortcuts, reflection or global state.
- Fail closed by default: a missing, invalid or unrecognized setting, input or check result denies access and leaves risky behaviour off. Risky behaviour, such as sending user content to a remote provider, turns on only for an exact, explicit value.

## Structure

- `spiritor.go` is the CLI entry point: it parses flags with Kong and hands typed values to commands. Command logic lives in packages, not in `main`.
- Each external system (a model provider, ffmpeg) is wrapped in its own package, an anti-corruption layer in Domain-Driven Design's terms: it translates that system's model into ours at the boundary. Nothing else talks to that system.
- Model providers implement one Spiritor interface per capability (such as transcription or text generation), so commands never depend on a specific provider (see decision 0004).
- Dependencies are vendored in `vendor/`. A dependency change goes in its own commit (see `DEVELOPMENT.md`).

## Secrets and configuration

- Spiritor reads API keys from the user's environment at run time (the rule against committing them is in `AGENTS.md`). Never log, print or write a key, including in debug output.
- Never hard-code environment-specific values (endpoints, keys, model names that differ per setup). Take them from explicit configuration (flags or environment variables), with defaults only where the default is safe: a local endpoint, never a remote one.

## Comments

- Explain _why_, not _what_. Well-named code covers the what.
- When code works around a quirk of an external system, say so in a comment and link its entry in that system's file in `docs/integrations/`.
