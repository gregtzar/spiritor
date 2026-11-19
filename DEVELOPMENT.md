# Developer Notes

[![Go Reference](https://pkg.go.dev/badge/github.com/gregtzar/spiritor.svg)](https://pkg.go.dev/github.com/gregtzar/spiritor)

## Versioning

Releases are [semver](https://semver.org/) tags (`vMAJOR.MINOR.PATCH`) on `main`, each with a GitHub release page holding the release notes and binaries. While the major version is `v0`, a minor version may introduce breaking changes.

## Contributions

I will be gladly accepting PR contributions, but at this point it would be best to open an issue and discuss the planned changes beforehand, to make sure your implementation lines up with the intended roadmap.

I take a design-first approach to engineering which means we need to first discuss and agree on the changes before you write the code. All PRs should conform to the existing design principles, conventions and architecture, documented in [`docs/`](docs/) (start with [`docs/conventions.md`](docs/conventions.md)). These things can of course be improved upon also, but the new direction needs to be proposed and agreed upon first. See: [Chesterton's Fence](https://medium.com/@mesw1/understanding-chestertons-fence-a-guiding-principle-in-software-engineering-7459e1fb7bf1).

Pull requests are squash-merged into `main`, so a branch may hold as many commits as you like. Write the PR title and description as a clear and succinct commit message that describes the change, since they become the commit on `main`. Run the checks below before opening a PR; CI runs the same checks and must pass before a PR can merge.

# Quick Reference Commands

Run all checks, exactly as CI does (formatting, lint, tests, release builds and a vulnerability scan; it never changes files):
```sh
build/check.sh
```

Format the code:
```sh
go tool -modfile=tools/golangci-lint.mod golangci-lint fmt ./...
```

Local install:
```sh
go install .
```

Build release binaries for every platform (into the current folder, or the folder given):
```sh
build/build_go.sh [output folder]
```

Add or update a dependency (dependencies are not vendored):
```sh
go get <module>@<version> && go mod tidy
```

Update a developer tool (each has its own module file in `tools/`):
```sh
go get -tool -modfile=tools/golangci-lint.mod github.com/golangci/golangci-lint/v2/cmd/golangci-lint@<version>
go get -tool -modfile=tools/govulncheck.mod golang.org/x/vuln/cmd/govulncheck@<version>
```
