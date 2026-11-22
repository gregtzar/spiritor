---
status: approved # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Semantic search

## Goal

A `search` command that finds every passage in a folder of text files matching a description, such as "everything I wrote about functional thinking", "all good business ideas", "all quotes and movie references" or "lines that read like poetry", and lists each one verbatim with a link to its file. Unlike retrieval-augmented generation, which returns a few chunks ranked by similarity, it reads every file with a language model, so the results are exhaustive and each judgement sees the whole file (research 0004). It is the first stage of Spiritor's content pipeline: later commands will take its results as input to group, summarize or write from them.

## Scope

- In scope: the `search` command; two match modes, stated and inferred; an Ollama provider, with the model running locally or from Ollama Cloud (decision 0007); `.md` and `.txt` files, recursively; splitting files too big for the model's context; a results folder with a Markdown report and machine-readable state; resuming an interrupted search.
- Out of scope: other providers; files that need converting, such as `.rtf`, PDF and Word documents; embeddings or a search index; screening files with a cheaper model first; ranking; configurable file types, ignored folders or result order; the later pipeline commands.

## Design

### Running a search

`spiritor search "<what to find>"`, run in the folder to search. The search text describes what to find, and the match mode says how a passage qualifies (see "Match modes"). Spiritor wraps both in its preset prompt.

| Environment variable           | Flag             | Meaning                                                                         |
| ------------------------------ | ---------------- | ------------------------------------------------------------------------------- |
| `SPIRITOR_SEARCH_PROVIDER`     | `--provider`     | `ollama`; required (decision 0008)                                              |
| `SPIRITOR_SEARCH_OLLAMA_URL`   | `--ollama-url`   | The Ollama server; defaults to `http://localhost:11434`, a local endpoint       |
| `SPIRITOR_SEARCH_OLLAMA_MODEL` | `--ollama-model` | The model, such as `qwen3.5:9b-q4_K_M` or a cloud model; required for Ollama    |
| `SPIRITOR_SEARCH_OLLAMA_CONTEXT` | `--ollama-context` | The model's context size in tokens, when Spiritor can't detect it or the user wants less (see "Context size") |
| `SPIRITOR_SEARCH_MATCH`        | `--match`        | `stated` (the default) or `inferred` (see "Match modes")                        |
| `SPIRITOR_SEARCH_THINKING`     | `--thinking`     | How much the model reasons before answering: `off`, `low`, `medium` or `high`; defaults to `off` for stated and `low` for inferred (see "Thinking") |
| `SPIRITOR_SEARCH_CONCURRENCY`  | `--concurrency`  | Files searched at once; defaults to 1                                           |
| none                           | `--resume`       | Finish an unfinished search instead of starting one (see "Resuming")            |

### Which files

- Every `.md` and `.txt` file under the current folder, recursively.
- Skipped: folders whose names start with a dot (such as `.obsidian` and `.git`), and Spiritor's own `spiritor/` output folder.
- A file that isn't valid UTF-8 text is reported and skipped.

### Searching one file

Following DocETL's `extract` operator (research 0004):

1. Spiritor re-wraps the file's text into short numbered lines, so the model can point inside long paragraphs, and keeps a map back to the original text.
2. The preset prompt gives the model the search text, the match mode's rules and worked examples, the file's path relative to the searched folder, and the numbered file, and asks for every passage matching the description:
   - the smallest self-contained span that fully covers each match, from one line to the whole file;
   - one result for the whole file when all of it matches;
   - adjacent spans about the same thing merged into one;
   - borderline matches included rather than dropped, because the user reviews the list and a missed match is invisible;
   - for each match, its evidence first (the mode's cue or rationale), then its line range and a one-line description of what it is (such as "Movie reference: Stalker"). The evidence comes first in the JSON schema because models write fields in schema order, so the model commits to a reason before choosing lines.
3. The answer is constrained to a JSON schema with Ollama's structured outputs, so it always parses.
4. Spiritor checks each line range against the file, dropping invalid ones and reporting them, and in stated mode marks each match whose cue it can't find (see "Checking cues"). It then cuts each passage from the original text itself, so passages are always exact and never rewritten by the model.

The prompt is versioned, and the version is recorded with every search.

### Match modes

A description such as "good business ideas" can mean two searches, which content analysis calls manifest and latent content: what the text says outright, and what a reader infers from it. Coding schemes in content analysis state which kind each category is and give the coder separate rules and examples for each; Spiritor's match modes do the same, chosen explicitly by the user rather than guessed from the wording of the search text.

- **Stated** (manifest, the default): a passage matches only where the author presents it as what the search describes, in their own words, however phrased. For "good business ideas": "startup idea", "someone should build…", "I could sell this" or a heading "Side hustles" all qualify; an idea the author didn't frame that way doesn't, however promising. Each match's evidence is its **cue**: the author's own words that frame it, quoted exactly.
- **Inferred** (latent): a passage matches where it fits the description on the model's reading, whether or not the author says so, for example a problem people would pay to solve, a skill that could earn money, or a line that reads like poetry. Everything stated mode would match is included. Each match's evidence is its **rationale**: one line on why it matches.

Topic searches, such as "everything I wrote about functional thinking", often match long sections or whole files. Stated mode matches where the author names the topic: in a heading, in the file's name, such as `2026-03-04_functional_thinking.md`, or in the text. Inferred mode also matches writing about the topic that never names it, such as a passage in a stream of consciousness. Topic writing often doesn't name its topic, and stated mode misses such passages silently, with no cue to quote, so inferred mode suits most topic searches.

The mode's rules and worked examples are part of the preset prompt. Each mode has one short example of a match and one of a non-match, on a fixed topic unrelated to most searches, labelled as illustrating the rule rather than the topic, so the examples don't steer what the model looks for. For stated mode on a business-ideas example: "Side business: sharpening knives at the farmers' market" matches; "Nobody in town fixes vintage synths anymore" doesn't, though inferred mode would match it.

### Checking cues

The model finds cues by meaning; Spiritor holds no list of phrases. Spiritor checks only that the model quoted real text: a cue must appear within the match's lines, in a heading above them (so a list under a heading such as "Startup ideas" qualifies by its heading), or in the file's path (so every passage of `2026-03-04_startup_ideas.md` can qualify by its name). The comparison is case-insensitive, with runs of whitespace collapsed, since re-wrapping splits text across lines, and, in paths, with `_`, `-` and `/` read as spaces. A match whose cue isn't found is kept but marked **unverified**, because the passage may still be a real match: the model may have paraphrased the author's framing instead of quoting it, and dropping it would be a miss the user never sees. Unverified results also expose a model that quotes from elsewhere in the file or invents a framing that isn't there, which smaller models and inferred-style judgements leaking into stated mode are prone to. How many results are unverified is a measure of how well a model handles stated mode. Rationales can't be checked mechanically; they're shown with each result for the user to review.

### Thinking

Stated mode is mostly recognising paraphrases, which mid-size models do well without reasoning; inferred mode is judgement, where reasoning helps, at several times the output and time (research 0006). Spiritor sends the thinking level with each request through Ollama's `think` field: `off` as `false`, and a level as that level where the model supports levels, otherwise as `true`.

### Context size

Ollama runs a request with a 4,096-token context unless the request asks for more, and by default it silently cuts a longer prompt to fit, so part of a file would never be read. It also allocates memory for the whole context up front, so a large context on a local model can exhaust GPU memory. Spiritor therefore sizes the context (`num_ctx`) to each request:

1. **The model's maximum**, in order: `SPIRITOR_SEARCH_OLLAMA_CONTEXT` if set; the maximum Ollama's `/api/show` reports; Spiritor's built-in table of known models' context sizes; otherwise 32,768 tokens.
2. **Each request's context** is Spiritor's estimate of what the prompt, the file and the answer need, rounded up, and never more than the model's maximum. Cloud models get their full context when a file needs it; local models use only what each file needs.
3. **The estimate** comes from the text's length, erring high, since Ollama has no way to count a prompt's tokens before it's sent.
4. **A file is split** only when it needs more than the model's maximum.
5. **Truncation is detected:** Ollama reports how many prompt tokens it read (`prompt_eval_count`). If that shows the prompt was cut, Spiritor retries the file with a larger context, or splits it if it's already at the maximum.

### Splitting large files

Following DocETL's `split` and `gather` operators, but splitting at the document's structure rather than at a fixed token count:

1. Spiritor splits at headings first, then at paragraph breaks, into chunks that fit the context.
2. Each chunk is searched with the file's path, its heading path and its neighbouring chunks included as read-only context, marked as not to be searched, so a chunk is judged with what comes before and after it.
3. Line numbers stay those of the whole file, so results from every chunk point into the same file.

### Results

Each search writes a folder in the searched folder: `spiritor/search/<YYYY-MM-DD_HHMM>_<query_slug>/`, where the slug is the search text in lowercase snake_case, shortened.

- `results.md`: the report, readable in Obsidian or any Markdown viewer.
  - A header with the search text, match mode, model, thinking level, prompt version, date and counts, including invalid line ranges dropped and unverified cues.
  - Results grouped by file, files ordered by date: a `YYYY-MM-DD` date at the start of the file name, then a date in the file's first heading, then the file's modified time. Within a file, results follow line order.
  - Each result: its description, its cue or rationale, a relative link to the file, the line range, and the passage verbatim, as a block quote.
  - In stated mode, results with unverified cues are listed after the verified ones, in their own section, so the user reviews them separately.
  - Files that were skipped or failed are not listed; they are recorded in `.search.json`.
- `.search.json`: the machine-readable state and results: search text, match mode, provider, model, thinking level, prompt version and settings; every file found, with its path, a hash of its contents, its status (pending, done, skipped or failed, with the reason) and its results; and the search's own status. Rewritten atomically after every file. It is what later pipeline commands read.
- A search is **complete** when every file in `.search.json` is done or skipped, and its results are in `results.md`. Failed files leave it unfinished, so resuming retries them.

The command prints progress per file, then a summary of files searched, results, files skipped or failed, and the path of `results.md`.

### Resuming

`spiritor search --resume` finishes an unfinished search. With `--resume`, the positional argument is an optional search folder instead of the search text.

- `spiritor search --resume`, run in the folder that holds `spiritor/`: prints the folder names of the unfinished searches in `spiritor/search/`, read from their `.search.json` files, so the user can copy one into the next command. Complete searches are left out. There is no interactive choice.
- `spiritor search --resume <search folder>`: resumes that search.

Resuming takes the search text, model and settings from `.search.json`, skips files that are done and unchanged, searches the rest, including files that are new, changed or failed, and rewrites `results.md`. A search can only be resumed with the prompt version it started with.

### Failures

- Ollama unreachable, or the model missing: the command stops with an error that points to the setup instructions (decision 0008).
- An error on one file, or an answer that fails validation: that file is marked failed and the search continues; resuming retries it.

## Open questions

- **Ollama Cloud models:** Ollama's docs say "Ollama's cloud currently does not support structured outputs" (checked 2026-11-21), so step 3 of "Searching one file" fails for cloud models. Open: whether to drop Ollama Cloud from this spec's scope and reach remote models through the OpenAI Chat Completions provider on the roadmap, or to accept unconstrained JSON from cloud models, relying on step 4's validation and retrying failed files. Also still unverified: whether `/api/show` reports cloud models' context size; the built-in table covers models whose size isn't reported.
- **Thinking controls by model family:** Ollama's `think` field takes `true` or `false`, and levels for some families such as gpt-oss; which families honour which values isn't documented in one place (research 0006). Checked during implementation; a model that ignores the setting still works, only slower or less careful. Blocks nothing.

## Done when

- A search lists every file it found in `.search.json` with a status, and completes when every file is done or skipped and all its results are in `results.md`.
- A file larger than the model's maximum context is split and searched, and its results point to the right lines.
- A stated search lists each result with its cue, and lists separately, marked unverified, any match whose cue isn't in its lines, a heading above them or the file's path; an inferred search lists each result with its rationale.
- `spiritor search --resume` lists only unfinished searches, and an interrupted search finishes with `spiritor search --resume <search folder>`, searching only the files it hadn't finished.
- `README.md` explains how to set up Ollama, configure `search`, and read the results; `docs/integrations/ollama.md` records Ollama's facts and quirks.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
