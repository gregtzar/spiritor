#!/usr/bin/env bash

# The single definition of what passes, run the same way by people, agents and CI
# (see spec 0001). It only checks: it never changes files.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> go.mod and go.sum are tidy"
go mod tidy -diff

echo "==> formatting"
go tool -modfile=tools/golangci-lint.mod golangci-lint fmt --diff ./...

echo "==> lint"
go tool -modfile=tools/golangci-lint.mod golangci-lint run ./...

echo "==> tests"
go test ./...

echo "==> release builds for every platform"
build_output_dir="$(mktemp -d)"
trap 'rm -rf "$build_output_dir"' EXIT
build/build_go.sh "$build_output_dir"

echo "==> known vulnerabilities"
go tool -modfile=tools/govulncheck.mod govulncheck ./...

echo "All checks passed."
