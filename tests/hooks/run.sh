#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/init-project-hooks.XXXXXX")
trap 'rm -r -- "$TMP"' EXIT
mkdir -p "$TMP/project/specs/demo" "$TMP/empty"
printf '%s\n' '---' '상태: 진행중(Phase 1)' '---' > "$TMP/project/specs/demo/context.md"
printf '%s\n' '{}' > "$TMP/settings.json"
export INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json"
export INIT_PROJECT_HOOK_TMPDIR="$TMP"
out=$(CLAUDE_PROJECT_DIR="$TMP/project" bash "$ROOT/.claude/hooks/session_start.sh" < "$ROOT/tests/hooks/session_start.json")
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
out=$(CLAUDE_PROJECT_DIR="$TMP/empty" bash "$ROOT/.claude/hooks/session_start.sh" < "$ROOT/tests/hooks/session_start.json")
[ -z "$out" ]
echo 'hooks baseline: all tests passed'
