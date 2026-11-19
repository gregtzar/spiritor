---
status: in progress # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Agent workflow setup

## Goal

Let coding agents work in this repo safely: under their own GitHub identity, from documented conventions and decisions, with checks that tools enforce rather than instructions, and with a maintainer deciding at each checkpoint.

## Scope

- In scope: the agent docs (`AGENTS.md`, `docs/`), the check-in skill, the repo's location, the App's access, Go tooling and code checks, the Git hook, CI, rulesets and repository settings.
- Out of scope: new product features; release automation (binaries and release notes), which gets its own spec when needed; cloud agents.

## Design

Steps in order. A maintainer does the steps marked **maintainer**, because they need account access agents don't have.

### 1. Agent docs

`AGENTS.md`, `docs/` and `.claude/skills/check-in-code/SKILL.md`, describing a Go CLI and module that nothing deploys; the workflow is decision 0002.

### 2. Move the repo

Per decision 0005:

1. **Maintainer:** transfer `spiritorai/spiritor` to `gregtzar`.
2. **Maintainer:** point the `spiritor.ai` redirect at `https://github.com/gregtzar/spiritor`.
3. **Agent:** change the module path in `go.mod`, every import, `README.md`, `DEVELOPMENT.md` and `build/build_go.sh`, then run the checks.

### 3. Give the App access

1. **Maintainer:** add the repo to the `micromason-agent-prime` installation's repository access. The App's permissions are set once for all its repos (Contents, Pull requests and Workflows read/write; Actions, Checks and Commit statuses read).
2. **Agent:** confirm the installation lists the repo.

### 4. Go toolchain and checks

- Raise `go.mod`'s `go` line from `1.21.6` to a supported release, since Go supports only its two newest releases.
- One command defines what passes, run identically by people, agents, the Git hook and CI: `gofmt` (no changes needed), `go vet`, `go test`, `go build`, plus a linter.
- Fix what `go vet` reports: three Kong struct tags in `spiritor.go` use Kong's shorthand (`arg`, `cmd`, an unquoted `default:false`), which isn't valid Go struct tag syntax.
- A Claude Code `PostToolUse` hook in `.claude/settings.json` runs `gofmt` on each `.go` file an agent edits and reports `go vet` errors for its package.
- **Maintainer:** `.claude/settings.json` sets agents' own permissions, so a maintainer writes and changes it.

### 5. Git hook

Runs the check command on every commit, for people and agents, and never changes files.

### 6. CI and rulesets

- GitHub Actions job named `check` (rulesets require it by name) on every push to a branch other than `main` and on pull requests: `actions/setup-go` with `go-version-file: go.mod`, then the check command. It never changes files.
- `.github/rulesets/main.json`, in the format GitHub's ruleset import accepts: deletion and force pushes blocked, `check` required with branches up to date. **Maintainer** imports it, since the App has no Administration permission.
- **Maintainer:** repository settings: squash merging only, head branches deleted after merge.

### 7. Contributor docs

Reconcile `DEVELOPMENT.md` with decision 0002 (see open questions), and consider renaming it `CONTRIBUTING.md`, the file GitHub links from new issues and pull requests.

## Open questions

- Which Go version to target? Blocks step 4.
- Linter: `golangci-lint` is the established choice. Its maintainers recommend installing the release binary over `go install` or `go.mod`'s `tool` directive, which conflicts with "all tooling is a project dependency". Pin its version in a committed install script, or use `go tool` anyway? Blocks step 4.
- Git hook mechanism: Go has no install step that can install a hook the way npm's `prepare` script can, so a committed hook needs per-clone or per-developer setup. Options: (a) each developer sets a global `core.hooksPath` pointing at a dispatcher that runs the repo's committed `.githooks/pre-commit` when one exists; (b) `lefthook`, which needs `lefthook install` in each clone; (c) no Git hook, relying on the Claude Code hook and CI. Blocks step 5.
- Keep vendoring? Go's module proxy and checksum database make it optional; it costs repo size and a separate commit per dependency change. Blocks nothing.
- `DEVELOPMENT.md` asks contributors to squash into one commit rebased on `main`, plus a separate commit for vendor changes. A squash merge makes the first unnecessary and merges the second into the change. Which rule wins? Blocks step 7.

## Done when

- The App can push a branch and open a pull request on the repo.
- One check command passes locally, in the Git hook (if any) and in CI, and the `main` ruleset requires it.
- `docs/architecture.md` describes the repo's location, checks, CI and agent access as built.

## Implementation notes

- Steps 1, 2 and 3 are done.
- The `go vet` struct tag fix in step 4 is done; `--help` output is unchanged.
