---
status: accepted
date: 2026-11-18
---

# Go modules without vendoring, and developer tools through `go tool`

## Context

Spiritor vendored its two dependencies in `vendor/`. The checks in spec 0001 need developer tools (golangci-lint, govulncheck) pinned as project dependencies, so people, agents and CI run the same versions. Go 1.24 added tool dependencies run with `go tool`, but `go tool` refuses to run a tool from a separate module file while `vendor/` exists (see research 0001).

## Decision

- Dependencies are pinned by `go.mod` and `go.sum` and fetched through Go's module proxy, not vendored.
- Each developer tool is a Go tool dependency in its own module file in `tools/` (`tools/<tool>.mod` and `.sum`), run with `go tool -modfile=tools/<tool>.mod <tool>`.

## Reasons

- The module proxy and checksum database give what vendoring was for: every version's hash is pinned in `go.sum` and checked against a public, append-only log, and the mirror keeps source that disappears upstream (research 0001).
- Most well-known Go projects no longer vendor (research 0001).
- `go tool` is Go's own mechanism for tool dependencies, so tools need no install step and every user runs the version pinned in the repo.
- A separate module file per tool keeps each tool's dependencies out of Spiritor's `go.mod`, where Go's version selection would otherwise let a tool raise the versions Spiritor builds with. golangci-lint's documentation describes this setup.

## Alternatives considered

- Keep vendoring and install golangci-lint from its release binary with a committed script — the approach golangci-lint recommends, but a script and checksums to maintain, and a second install method for govulncheck.
- Keep vendoring and run tools with `go run <tool>@<version>` — untested; versions would be pinned in a script rather than a module file, out of reach of dependency update tools.
- Tools in Spiritor's own `go.mod` (`go get -tool`) — mixes the tools' dependencies, about a hundred for golangci-lint, into Spiritor's.

## Consequences

- A first build needs network access to the module proxy, or a warm module cache.
- Pull request diffs show dependency changes as `go.mod` and `go.sum` changes, not source.
- golangci-lint warns that installing through `go tool` "isn't guaranteed to work", because it compiles with the local Go version. If that breaks, the fallback is the install script above.
