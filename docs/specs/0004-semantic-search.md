---
status: draft # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Semantic search

## Goal

A new `search` command that finds content by meaning rather than exact words. Details to come from the maintainer.

## Scope

- In scope: the `search` command, and the Ollama provider it needs, Spiritor's first Ollama integration (decision 0004).
- Out of scope: to be decided.

## Design

Not designed yet. Constraints so far:

- Ollama runs the models, local by default; a remote provider only by explicit choice (decision 0004).
- The Ollama client is its own package behind a Spiritor interface, and its facts and quirks go in `docs/integrations/` (see "Structure" in `docs/conventions.md`).

## Open questions

- What is searched, how results are presented, and how the user runs a search. Awaiting the maintainer's description; blocks everything below.
- Which embedding model, and where the search index is stored and how it's kept current. Blocks the design.

## Done when

To be written with the design.

## Implementation notes

Filled in during implementation: where the built result deviates from the design above, and why.
