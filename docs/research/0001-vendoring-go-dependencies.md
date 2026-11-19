---
status: current # current | outdated | superseded by NNNN
date: 2026-11-18 # researched
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Vendoring Go dependencies

## Question

Should Spiritor keep vendoring its dependencies in `vendor/`? Vendoring blocks running developer tools through `go tool` with a separate module file (spec 0001), so we needed to know whether it is still Go practice and what it protects against. Informs decision 0006.

## Recommendation

### Summary

Stop vendoring. Go's module proxy and checksum database now provide the integrity and availability vendoring was used for, most well-known Go projects don't vendor, and vendoring is the one thing preventing the standard `go tool` route for developer tools.

### Details

Delete `vendor/`, keep `go.mod` and `go.sum` as the pinned, hashed record of dependencies, and check with `go mod tidy -diff` that they stay current. Library users are unaffected: Go ignores a dependency's `vendor/` folder.

## Findings

### Summary

| Option     | Integrity                                                    | Survives a deleted upstream     | Dependency source in PR diffs | Works with `go tool -modfile` | Common in well-known Go repos       | Verdict     |
| ---------- | ------------------------------------------------------------ | ------------------------------- | ----------------------------- | ----------------------------- | ----------------------------------- | ----------- |
| Vendoring  | Code in the repo; hashes in `go.sum`                         | Yes, copy in the repo           | Yes                           | No: inconsistent vendoring    | 3 of 16 checked                     | Not needed  |
| No vendor  | `go.sum` hashes, checked against the public checksum database | Yes, module mirror keeps copies | No, only version and hash     | Yes                           | 13 of 16 checked                    | Recommended |

### Details

#### Go's defaults

- Since Go 1.13 the `go` command downloads modules through the module mirror (proxy.golang.org) and verifies them against the checksum database (sum.golang.org).
- The checksum database is an append-only, publicly verifiable log. The Go team's launch post says "the contents of each version are immutable" and "Even the author of a module can't move their tags around."
- The mirror caches source "allowing the mirror to continue to serve source code that is no longer available from the original locations."
- The Go modules reference presents vendoring as an option "to allow interoperation with older versions of Go, or to ensure that all files used for a build are stored in a single file tree", not as a recommendation. This sentence came from a summary of the page, not a verbatim read.

#### What projects do

Checked on GitHub on 2026-11-18 for a `vendor/` directory: Kubernetes, Moby and containerd vendor. Prometheus, Terraform, golangci-lint, the GitHub CLI, Grafana, etcd, Ollama, Caddy, Hugo, CockroachDB, Istio, Helm and Traefik don't. The projects that vendor are large infrastructure projects with offline builds and distribution packaging.

#### Tested in this repo

- `go tool -modfile=tools/golangci-lint.mod golangci-lint` fails with `go: inconsistent vendoring` while `vendor/` exists: Go checks `vendor/modules.txt` against whichever module file it is given. Neither `-mod=mod` (rejected by `go tool`) nor `GOFLAGS=-mod=mod` avoids it.
- With `vendor/` removed, `go mod verify` reports all modules verified, `go.sum` is unchanged, and the build and both tools work.

## Caveats

- What remains trusted either way: new dependency versions chosen in an upgrade, which neither vendoring nor pinning reviews, and the availability of Google's mirror.
- Builds now need the module proxy, or a warm module cache, the first time.
- Only the repos named above were checked; the sample is well-known projects, not a survey.

## Sources

- [Go modules reference](https://go.dev/ref/mod)
- [Module mirror and checksum database launched](https://go.dev/blog/module-mirror-launch)
- [proxy.golang.org](https://proxy.golang.org)
- [Checksum database design](https://golang.org/design/25530-sumdb)
- [Managing dependencies: tool dependencies](https://go.dev/doc/modules/managing-dependencies)
- [golangci-lint local installation](https://golangci-lint.run/docs/welcome/install/local/)
