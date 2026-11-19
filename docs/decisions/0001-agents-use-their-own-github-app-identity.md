---
status: accepted
date: 2026-11-18
---

# Agents use their own GitHub App identity

## Context

Coding agents commit, push and open pull requests on this repo for its maintainers. A maintainer's own GitHub credentials reach every repo that maintainer can access, which is far more than an agent working on this repo needs.

## Decision

Maintainers' agents authenticate as a GitHub App, `micromason-agent-prime`, installed only on the repos they work on, with the narrowest permissions their work needs. Its commits and pull requests appear as `micromason-agent-prime[bot]`.

The repo holds nothing agent-specific: no credentials and no per-clone configuration. The App's key and the tooling that mints its tokens live outside the repo, so a plain clone works the same for a person and for an agent.

The App has no Administration permission, so a maintainer applies repository settings and rulesets.

## Reasons

- GitHub recommends Apps for automation. Installation tokens expire within an hour and carry only the App's permissions, and an App needs no seat.
- Pull requests opened by the App can be approved by a maintainer; GitHub does not let an author approve their own.
- Agent work is clearly attributed to the bot, separately from a maintainer's own commits.

## Alternatives considered

- A maintainer's own credentials (SSH key or `gh auth login`) — give agents access to every repo the maintainer can reach.
- Fine-grained token on a maintainer's account — pull requests would be authored by the maintainer, who then could not approve them.
- Machine user account — a long-lived credential and an extra account to manage.
- Deploy key — Git only, so it cannot open pull requests.

## Consequences

- Agents run Git and `gh` with short-lived App tokens, never a stored login.
- The App is private, so it can only be installed on repos of the account that owns it (see decision 0005).
- Outside contributors' agents work under whatever identity the contributor gives them, on the contributor's fork, like any other contribution.
