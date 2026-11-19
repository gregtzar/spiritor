---
status: accepted
date: 2026-11-18
---

# Host the repo on the maintainer's personal account

## Context

The repo was `spiritorai/spiritor`, in an organization owned by the maintainer's personal account `gregtzar`. Agents work through the GitHub App `micromason-agent-prime` (decision 0001), a private App owned by `gregtzar`, and GitHub only lets a private App be installed on the account that owns it. The Go module path is `github.com/spiritorai/spiritor`, with one release (`v0.1.0`).

## Decision

Transfer the repo to `gregtzar/spiritor`, and change the Go module path to `github.com/gregtzar/spiritor` in the change that follows the transfer.

## Reasons

- The App can then be installed on the repo without making it public or creating a second App.
- The maintainer already planned this move, and a Go module path change only gets more costly as users and importers accumulate. While the module is `v0` with one release, the cost is lowest.
- `spiritor.ai` redirects to the repo, so users following the domain are unaffected once the redirect target is updated.

## Alternatives considered

- Keep the organization and make the App public — anyone could then install it on their own repos. That grants us nothing of theirs that we'd use, but it widens what the App is and how it's listed, for no other gain.
- Keep the organization and create a second, organization-owned App — another key to manage and rotate.

## Consequences

- GitHub redirects the old repo URL, including Git remotes, unless a new repo is later created with the old name.
- Importers of `github.com/spiritorai/spiritor` keep resolving `v0.1.0` through the Go module proxy, but newer versions require the new path. The change ships in the next minor release with a note in its release notes.
- `README.md` badges, install instructions and `build/build_go.sh` change to the new path.
