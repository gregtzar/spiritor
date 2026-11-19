---
status: accepted
date: 2026-11-18
---

# Agents perform checkpoint steps after a maintainer's okay

## Context

The workflow (decision 0002) has steps intended as human checkpoints: merging a pull request, tagging a release, rewriting history, and changing rulesets or repository settings. Who may perform them is expected to change as the project grows from a single maintainer to more contributors and more agent work. For now, speed matters more than enforcement.

## Decision

- A maintainer's agent may perform every checkpoint step, but only after that maintainer's explicit okay in the current session.
- One okay covers one operation (for example "merge PR #3" or "tag v0.2.0"), never a standing approval. This keeps each checkpoint distinct, so it can later be enforced one at a time.
- GitHub enforces the workflow's structure, not who performs it: no rule requires an approval or limits who may push.

## Reasons

- GitHub's required-approval rule is left off: GitHub never counts a pull request author's own approval, so it would block the agent from ever merging its own pull requests. The maintainer's okay in the session replaces it.
- The maintainer's okay keeps a person deciding at every checkpoint, at the cost of relying on the agent following its instructions.

## Alternatives considered

- Enforced approvals and maintainer-only merges now — slows solo development, where the maintainer reviews in the session anyway.
- Giving the agent standing approval for a session — loses the per-step checkpoints this is meant to simulate.

## Consequences

- Nothing on GitHub stops an agent that ignores its instructions; only the rulesets' structural rules apply.
- Outside contributors' pull requests are merged only by a maintainer, or by a maintainer's agent after that maintainer's okay.
