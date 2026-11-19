---
status: approved # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Semantic search

## Goal

A `search` command that finds every passage in a folder of text files matching a description, such as "everything I wrote about functional thinking", "all good business ideas" or "all quotes and movie references", and lists each one verbatim with a link to its file. Unlike retrieval-augmented generation, which returns a few chunks ranked by similarity, it reads every file with a language model, so the results are exhaustive and each judgement sees the whole file (research 0004). It is the first stage of Spiritor's content pipeline: later commands will take its results as input to group, summarize or write from them.

## Scope

- In scope: the `search` command; an Ollama provider, with the model running locally or from Ollama Cloud (decision 0007); `.md` and `.txt` files, recursively; splitting files too big for the model's context; a results folder with a Markdown report and machine-readable state; resuming an interrupted search.
- Out of scope: other providers; files that need converting, such as `.rtf`, PDF and Word documents; embeddings or a search index; screening files with a cheaper model first; ranking; configurable file types, ignored folders or result order; the later pipeline commands.

## Design

### Running a search

`spiritor search "<what to find>"`, run in the folder to search. The search text is the only input: it describes what to find, and Spiritor wraps it in its preset prompt.

| Environment variable           | Flag             | Meaning                                                                         |
| ------------------------------ | ---------------- | ------------------------------------------------------------------------------- |
| `SPIRITOR_SEARCH_PROVIDER`     | `--provider`     | `ollama`; required (decision 0008)                                              |
| `SPIRITOR_SEARCH_OLLAMA_URL`   | `--ollama-url`   | The Ollama server; defaults to `http://localhost:11434`, a local endpoint       |
| `SPIRITOR_SEARCH_OLLAMA_MODEL` | `--ollama-model` | The model, such as `qwen3.5:9b-q4_K_M` or a cloud model; required for Ollama    |
| `SPIRITOR_SEARCH_OLLAMA_CONTEXT` | `--ollama-context` | The model's context size in tokens, when Spiritor can't detect it or the user wants less (see "Context size") |
| `SPIRITOR_SEARCH_CONCURRENCY`  | `--concurrency`  | Files searched at once; defaults to 1                                           |
| none                           | `--resume`       | Finish an unfinished search instead of starting one (see "Resuming")            |

### Which files

- Every `.md` and `.txt` file under the current folder, recursively.
- Skipped: folders whose names start with a dot (such as `.obsidian` and `.git`), and Spiritor's own `spiritor/` output folder.
- A file that isn't valid UTF-8 text is reported and skipped.

### Searching one file

Following DocETL's `extract` operator (research 0004):

1. Spiritor re-wraps the file's text into short numbered lines, so the model can point inside long paragraphs, and keeps a map back to the original text.
2. The preset prompt gives the model the search text and the numbered file, and asks for every passage matching the description:
   - the smallest self-contained span that fully covers each match, from one line to the whole file;
   - one result for the whole file when all of it matches;
   - adjacent spans about the same thing merged into one;
   - borderline matches included rather than dropped, because the user reviews the list and a missed match is invisible;
   - for each match, its line range and a one-line description of what it is (such as "Movie reference: Stalker").
3. The answer is constrained to a JSON schema with Ollama's structured outputs, so it always parses.
4. Spiritor checks each line range against the file and drops invalid ones, reporting them. It then cuts each passage from the original text itself, so passages are always exact and never rewritten by the model.

The prompt is versioned, and the version is recorded with every search.

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
2. Each chunk is searched with its heading path and its neighbouring chunks included as read-only context, marked as not to be searched, so a chunk is judged with what comes before and after it.
3. Line numbers stay those of the whole file, so results from every chunk point into the same file.

### Results

Each search writes a folder in the searched folder: `spiritor/search/<YYYY-MM-DD_HHMM>_<query_slug>/`, where the slug is the search text in lowercase snake_case, shortened.

- `results.md`: the report, readable in Obsidian or any Markdown viewer.
  - A header with the search text, model, prompt version, date and counts.
  - Results grouped by file, files ordered by date: a `YYYY-MM-DD` date at the start of the file name, then a date in the file's first heading, then the file's modified time. Within a file, results follow line order.
  - Each result: its description, a relative link to the file, the line range, and the passage verbatim, as a block quote.
  - Files that were skipped or failed are not listed; they are recorded in `.search.json`.
- `.search.json`: the machine-readable state and results: search text, provider, model, prompt version and settings; every file found, with its path, a hash of its contents, its status (pending, done, skipped or failed, with the reason) and its results; and the search's own status. Rewritten atomically after every file. It is what later pipeline commands read.
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

- **Ollama Cloud models:** unverified whether `/api/show` reports their context size and whether structured outputs work with them. Checked during implementation; the built-in table covers models whose size isn't reported. Blocks nothing.

## Done when

- A search lists every file it found in `.search.json` with a status, and completes when every file is done or skipped and all its results are in `results.md`.
- A file larger than the model's maximum context is split and searched, and its results point to the right lines.
- `spiritor search --resume` lists only unfinished searches, and an interrupted search finishes with `spiritor search --resume <search folder>`, searching only the files it hadn't finished.
- `README.md` explains how to set up Ollama, configure `search`, and read the results; `docs/integrations/ollama.md` records Ollama's facts and quirks.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
