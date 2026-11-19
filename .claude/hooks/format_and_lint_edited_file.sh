#!/usr/bin/env bash

# Claude Code PostToolUse hook: formats the Go file an agent just edited and lints its
# package, so the agent fixes problems while editing rather than at commit time.
# Exit code 2 sends stderr back to the agent. build/check.sh remains what defines passing.

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
	echo "format_and_lint_edited_file.sh needs jq to read the hook input; install jq." >&2
	exit 2
fi

edited_file_path=$(jq -r '.tool_input.file_path // empty')
project_dir=${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR is not set}

case "$edited_file_path" in
"$project_dir"/*.go) ;;
*) exit 0 ;;
esac
[ -f "$edited_file_path" ] || exit 0

cd "$project_dir" || exit 2
relative_file_path=${edited_file_path#"$project_dir"/}

golangci_lint() { go tool -modfile=tools/golangci-lint.mod golangci-lint "$@"; }

if ! format_output=$(golangci_lint fmt "$relative_file_path" 2>&1); then
	echo "Formatting $relative_file_path failed:" >&2
	echo "$format_output" >&2
	exit 2
fi

if ! lint_output=$(golangci_lint run "./$(dirname "$relative_file_path")/" 2>&1); then
	echo "Lint issues in the package of $relative_file_path:" >&2
	echo "$lint_output" >&2
	exit 2
fi
