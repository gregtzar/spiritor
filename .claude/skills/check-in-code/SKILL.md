---
name: "check-in-code"
description: "The procedure for checking in code in this repo. Use before every commit, push, merge or release."
---

# Check in code

The workflow is decision 0002. Checks are enforced by tools (see spec 0001); this procedure covers what needs judgment.

- Commit and push only when the maintainer you work for has asked for it.
- Steps marked **checkpoint** each need that maintainer's explicit okay in the current session, one okay per operation (see decision 0003).
- Run Git and `gh` as your own GitHub App identity (see decision 0001).

## A change

1. **Branch.** Work on a feature branch from an up-to-date `main`, named as a short kebab-case description. Never commit to `main`.
2. **Documentation.** Apply "Keeping documentation current" in `AGENTS.md` to this change: `docs/architecture.md`, `README.md` if users see the change, the spec's status and implementation notes, decision records, conventions.
3. **Checks.** Run `build/check.sh`. Fix every failure at its cause.
4. **Review.** Read `git status` and the full diff. Stage files by name, and confirm nothing staged is a secret, a build output or unrelated to the change.
5. **Commit.** Write an imperative subject line that says what changed, and a body only if the reason isn't obvious. Add the attribution trailer your tool requires. A branch may hold several commits; the merge squashes them.
6. **Push and open a pull request into `main`.** `GIT_TERMINAL_PROMPT=0 git push -u origin <branch>`, then `gh pr create --base main`. The title and description become the squashed commit's subject and body, and later the source of the release notes, so write them as a commit message: what changed and why, readable without the diff. Wait for CI: `gh pr checks <number> --watch --fail-fast`.
7. **Merge (checkpoint).** If `main` moved, merge it into the branch first (`git fetch origin && git merge origin/main`), resolve any conflicts in that merge commit, push, and wait for CI again. Merging rather than rebasing keeps the branch's history intact, so it needs no force push; the squash drops the merge commit. Then `gh pr merge <number> --squash --delete-branch --subject "<title> (#<number>)" --body "<body>"`. Write the body for the change as a whole, ending with the attribution trailers, because GitHub's default body joins every commit message on the branch, review fixes included.

## A release (checkpoint)

A release is a tag and a GitHub release page with notes and binaries. The maintainer's okay covers both.

1. **Version.** Confirm `main`'s head passed CI, and choose the version by semver: while the major version is `v0`, a breaking change bumps the minor version.
2. **Notes.** Read what changed since the last release with `git log <previous tag>..origin/main`; each commit is a squashed pull request. Write the notes for users, not contributors: a short summary, then breaking changes with what users must do, then other changes. Summarize internal-only changes in one line or leave them out.
3. **Tag.** `git fetch origin && git tag -a v<version> origin/main -m "v<version>"`, then `GIT_TERMINAL_PROMPT=0 git push origin v<version>`.
4. **Binaries.** With the tag checked out (`git switch --detach v<version>`), run `./build_go.sh` from `build/`.
5. **Publish.** `gh release create v<version> --verify-tag --title v<version> --notes-file <notes file> build/spiritor-*`. Uploading takes a few minutes. Then delete the binaries from `build/` and switch back to `main`.
6. **Confirm.** From outside the repo, `go list -m github.com/gregtzar/spiritor@v<version>` resolves the release through the Go module proxy.

## Review feedback

Maintainers review pull requests in GitHub's web UI. No agent watches GitHub, and @mentions reach no agent, so the maintainer says in a session when a review is in.

1. **Read.** Read every unresolved review thread and top-level comment on the pull request with `gh`.
2. **Fix.** Push fixes as new commits on the same branch, never rewriting its history, so GitHub can show the reviewer what changed since their review. Follow steps 2 to 5 of "A change" for each commit.
3. **Reply.** Reply on each thread with what changed, or why it didn't. Answer questions in the thread. Where you disagree, explain and change nothing; the maintainer decides.
4. **Leave resolving to the reviewer.** Never resolve a thread; the reviewer decides when a point is settled.
5. **Approval ends the review.** It isn't an okay to merge: merging is still the checkpoint in step 7 of "A change", unless a maintainer merges in the web UI.

## If a check or hook blocks you

- Never bypass a Git hook (`--no-verify`, `-n`) and never weaken a check or its config to get past it. A rule change is its own decision for the maintainers.
- Never force push, delete a branch other than through `--delete-branch` on a merge, or move or delete a tag, without the maintainer's okay.
- If a check can't be made to pass, GitHub rejects a push, or a permission check blocks a step, stop and report it to the maintainer.
