---
status: accepted
date: 2026-11-18
---

# Trunk-based workflow with semver release tags

## Context

Maintainers, their agents and outside contributors all change this repo. Spiritor is a CLI and a Go module: nothing deploys on push. Users get it through `go install` or `go get`, which resolve semver tags, and through release binaries.

## Decision

- `main` is the only long-lived branch. Work happens on short-lived feature branches, which reach `main` through a pull request merged with a squash, so each change is one commit.
- A release is an annotated semver tag (`vMAJOR.MINOR.PATCH`) on a commit of `main` that passed CI, following the Go module version numbering rules. While the major version is `v0`, minor versions may break the API.
- GitHub rulesets enforce the structure on `main` (no force pushes, no deletion, required CI) once CI exists (see spec 0001). Who may perform each step is decision 0003.

## Reasons

- Trunk-based development is the established practice for libraries and tools without a staging deploy, and it is how the Go project and most Go modules work.
- Go's module system resolves versions from semver tags, so tags are the release mechanism Go users already expect.
- Squash merges keep `main`'s history at one commit per change, however a pull request's branch was built.

## Alternatives considered

- A `dev` integration branch promoted to `main` — useful when `dev` deploys a staging environment; with no deploy, it adds a step with no benefit.
- Release branches — only needed when several release lines are maintained at once.

## Consequences

- Every merge to `main` should leave it releasable. `go install ...@latest` resolves the newest tag, not `main`, but `go get ...@main` is possible.
- There are no hotfixes: a bug, including one found in a release, is fixed on `main` like any other change and ships in the next release. Old releases are never patched.
