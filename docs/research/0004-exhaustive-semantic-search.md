---
status: current # current | outdated | superseded by NNNN
date: 2026-11-19 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Exhaustive semantic search

## Question

The maintainer wants searches such as "every passage where I write about topic X" over a folder of notes, with exhaustive results and full context. Retrieval-augmented generation (RAG) fell short in their own trials. Does a tool or established approach already do this with local models, and what should Spiritor borrow? Informs spec 0004.

## Recommendation

### Summary

Build it in Spiritor, as the maintainer proposed: run a language model over every file and extract the matching passages. This is an established pattern, "semantic operators", but no existing tool is a ready search command for notes. Borrow DocETL's verbatim extraction by line ranges, and its split-and-gather handling of long documents.

### Details

Spec 0004 applies this: numbered lines and line-range answers, passages cut by Spiritor rather than written by the model, structured outputs, and splitting at headings and paragraphs with neighbouring chunks as read-only context.

## Findings

### Summary

| Approach                                    | Exhaustive                         | Passages verbatim                 | Local models          | Form                                   | Verdict                       |
| ------------------------------------------- | ---------------------------------- | --------------------------------- | --------------------- | -------------------------------------- | ----------------------------- |
| RAG (embeddings, top results)               | No: returns the closest few chunks | Yes, but chunks lose context      | Yes                   | Many tools                             | Fails the requirement         |
| semtools (LlamaIndex)                       | No: embedding similarity           | Yes                               | Yes                   | Command-line tool                      | Fails the requirement         |
| GraphRAG global search (Microsoft)          | Covers the corpus through summaries | No: answers from summaries       | Yes                   | Python library                         | Wrong output                  |
| DocETL (`extract`, `split`, `gather`)       | Yes: every document is processed   | Yes                               | Yes, including Ollama | Python library, YAML pipelines, UI     | Closest; borrow its design    |
| LOTUS (`sem_filter`, `sem_extract`)         | Yes                                | Partly                            | Yes                   | Python DataFrame library               | Same pattern                  |
| Palimpzest                                  | Yes                                | Partly                            | Yes                   | Python library                         | Same pattern                  |

### Details

#### Semantic operators

Database research calls running a language model over every record of a collection, to filter, extract from, aggregate or join it, "semantic operators" (the LOTUS paper, 2024; VLDB 2025). Because every record is read, the results are exhaustive, which is what RAG's top-few retrieval cannot promise. LOTUS also describes a cascade, where a cheaper model screens records before a stronger one processes them, a later speed-up for Spiritor.

#### DocETL

UC Berkeley's DocETL (MIT license, about 4,300 stars, active as of November 2026) runs on Ollama, and its source shows three relevant operators:

- `extract` pulls sections out "verbatim, without synthesis or summarization". Its default strategy re-wraps text into numbered 80-character lines, asks the model only for a JSON list of `start_line` and `end_line` ranges, and cuts the text out itself.
- `split` cuts documents by token count or a fixed delimiter.
- `gather` adds context to each chunk: chosen previous and next chunks, in full or shortened, and the document's heading hierarchy.

#### Ollama

- `/api/show` reports a model's maximum context; for `qwen3.5:9b` it is 262,144 tokens.
- Ollama's FAQ: "By default, Ollama uses a context window size of 4096 tokens", unless the server or the request sets it. A request must set `num_ctx` for longer files.
- Ollama supports structured outputs, constraining an answer to a JSON schema.
- Ollama truncates input that exceeds the context by default (documented for its embeddings endpoint as `truncate`, "Defaults to `true`"), and allocates memory for the whole context, multiplied by the number of parallel requests (FAQ).

#### A starting corpus

A typical personal notes collection is a reasonable first target: a few hundred Markdown files, a few megabytes in total, most files a few kilobytes, and the largest tens of kilobytes (around 10,000 tokens). At that size every file fits a modern model's context whole, so splitting is the exception, and a local model can search the whole collection in an hour or two.

## Caveats

- No measurement yet of how well a local 9B model follows the extraction prompt on stream-of-thought journals; spec 0004's done criteria test it.
- The search for existing tools found research systems and libraries, not consumer note-search tools; one built for a note app could exist.
- DocETL's star count and activity were read on 2026-11-19.

## Sources

- [Semantic Operators: A Declarative Model for Rich, AI-based Data Processing (LOTUS)](https://arxiv.org/pdf/2407.11418)
- [Semantic Operators and Their Optimization (VLDB 2025)](https://www.vldb.org/pvldb/vol18/p4171-patel.pdf)
- [DocETL paper (VLDB 2025)](https://www.vldb.org/pvldb/vol18/p3035-shankar.pdf)
- [DocETL](https://github.com/ucbepic/docetl)
- [DocETL `extract`](https://ucbepic.github.io/docetl/operators/extract/), [`gather`](https://ucbepic.github.io/docetl/operators/gather/), [Ollama example](https://ucbepic.github.io/docetl/examples/ollama/)
- [LOTUS](https://github.com/lotus-data/lotus)
- [Palimpzest](https://github.com/mitdbg/palimpzest)
- [GraphRAG](https://github.com/microsoft/graphrag)
- [semtools](https://github.com/run-llama/semtools)
- [Unstructured data analysis using LLMs (survey)](https://arxiv.org/pdf/2510.27119)
- [Ollama FAQ](https://github.com/ollama/ollama/blob/main/docs/faq.mdx)
- [RAG failing as the number of documents grows (OpenAI forum)](https://community.openai.com/t/rag-is-failing-when-the-number-of-documents-increase/578498)
