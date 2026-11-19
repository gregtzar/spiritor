---
status: in progress # draft | approved | in progress | done | abandoned
date: 2026-11-18 # created
---

<!-- This template's structure and the standard behind it: "Documentation" in docs/conventions.md. -->

# Agent workflow setup

## Goal

Let coding agents work in this repo safely: under their own GitHub identity, from documented conventions and decisions, with checks that tools enforce rather than instructions, and with a maintainer deciding at each checkpoint.

## Scope

- In scope: the agent docs (`AGENTS.md`, `docs/`), the check-in skill, the repo's location, the App's access, Go tooling and code checks, CI, rulesets and repository settings.
- Out of scope: new product features; automating releases, which the check-in skill describes as manual steps; cloud agents.

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

- `go.mod` declares `go 1.26`, the oldest Go release still supported. With no patch number, CI installs the latest 1.26 patch release.
- Dependencies are not vendored, and golangci-lint and govulncheck are Go tool dependencies in their own module files in `tools/` (decision 0006).
- `build/check.sh` defines what passes, and people, agents and CI run it unchanged. In order: `go.mod` and `go.sum` are tidy (`go mod tidy -diff`); formatting (`golangci-lint fmt --diff`, with `gofmt`); lint (`golangci-lint run`); tests; release builds for every platform (`build/build_go.sh` into a temporary folder); known vulnerabilities (`govulncheck`). It never changes files.
- `.golangci.yml` uses golangci-lint's standard linters (errcheck, govet, ineffassign, staticcheck, unused) with its `std-error-handling` exclusion preset, which ignores unchecked errors from cleanup calls such as `Close`.

### 5. Agent feedback while editing

- `.claude/hooks/format_and_lint_edited_file.sh`, a Claude Code `PostToolUse` hook, formats each `.go` file an agent edits and reports lint issues in its package back to the agent. It needs `jq`.
- **Maintainer:** `.claude/settings.json` sets agents' own permissions, so a maintainer adds the hook to it.
- There is no Git hook: Go has no install step that could set one up without per-clone or per-developer setup. The agent runs `build/check.sh` before each commit, and CI is the failsafe.

### 6. CI and rulesets

- `.github/workflows/ci.yml`: one job, `check`, on pull requests and pushes to `main`. It installs Go from `go.mod`'s version and runs `build/check.sh`. Running on `main` gives the README badge `main`'s status.
- `.github/rulesets/` holds both rulesets in the format GitHub's ruleset import accepts. `main` blocks deletion and force pushes and requires `check` with the branch up to date; `release-tags` blocks updating or deleting `v*` tags, with repository admins able to bypass. **Maintainer** applies them, since the App has no Administration permission.
- **Maintainer:** repository settings: squash merging only, the pull request's title and description as the squashed commit's message, head branches deleted after merge.

### 7. Contributor docs

`DEVELOPMENT.md` follows decision 0002 (squash merges) and decision 0006 (no vendoring), and lists the developer commands.

## Open questions

- Rename `DEVELOPMENT.md` to `CONTRIBUTING.md`, the file GitHub links from new issues and pull requests? Blocks nothing.

## Done when

- The App can push a branch and open a pull request on the repo.
- `build/check.sh` passes locally and in CI, and the `main` ruleset requires it.
- The Claude Code hook is in `.claude/settings.json`.
- `docs/architecture.md` describes the repo's location, checks, CI and agent access as built.

## Implementation notes

- Steps 1, 2 and 3 are done, and the repository settings in step 6.
- The step 4 work fixed three Kong struct tags that `go vet` rejected; `--help` output is unchanged.
- golangci-lint's first run found four unchecked errors, all from deferred cleanup calls; the `std-error-handling` preset covers them.
