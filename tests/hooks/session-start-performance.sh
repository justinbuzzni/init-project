#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/session-start-performance.XXXXXX")
trap 'rm -r -- "$TMP"' EXIT
project="$TMP/project with spaces"
mkdir -p "$project/specs" "$TMP/bin"
for number in $(seq 1 80); do
  mkdir -p "$project/specs/active-$number"
  printf '%s\n' '---' '상태: 진행중(Phase 1)' '마지막 갱신: 2000-01-01' '---' > "$project/specs/active-$number/context.md"
done
for feature in completed legacy missing-date future invalid missing-status empty-status; do
  mkdir -p "$project/specs/$feature"
done
printf '%s\n' '---' '상태: 완료(검증됨)' '---' > "$project/specs/completed/context.md"
printf '%s\n' '# Legacy' '상태: 진행중' > "$project/specs/legacy/context.md"
printf '%s\n' '---' '상태: 진행중' '상태: 완료' '---' > "$project/specs/missing-date/context.md"
printf '%s\n' '---' '상태: 진행중' '마지막 갱신: 2099-01-01' '---' > "$project/specs/future/context.md"
printf '%s\n' '---' '상태: 검토중' '마지막 갱신: invalid' '마지막 갱신: 2000-01-01' '---' > "$project/specs/invalid/context.md"
printf '%s\n' '---' '마지막 갱신: 2000-01-01' '---' > "$project/specs/missing-status/context.md"
printf '%s\n' '---' '상태: ' '상태: 진행중' '---' > "$project/specs/empty-status/context.md"
printf '%s\n' '{}' > "$TMP/settings.json"
export HOOK_TEST_REAL_AWK=$(command -v awk)
export HOOK_TEST_REAL_DATE=$(command -v date)
export HOOK_TEST_COUNTER="$TMP/processes"
cat > "$TMP/bin/awk" <<'SH'
#!/bin/bash
printf '%s\n' awk >> "$HOOK_TEST_COUNTER"
exec "$HOOK_TEST_REAL_AWK" "$@"
SH
cat > "$TMP/bin/date" <<'SH'
#!/bin/bash
printf '%s\n' date >> "$HOOK_TEST_COUNTER"
exec "$HOOK_TEST_REAL_DATE" "$@"
SH
chmod +x "$TMP/bin/awk" "$TMP/bin/date"
# 87건이라 컨텍스트에는 20건만 실린다. 판정은 같은 계산을 거치는 --all 전체 목록으로 확인한다.
output=$(PATH="$TMP/bin:$PATH" CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$ROOT/.claude/hooks/session_start.sh" --all | jq -Rs '{hookSpecificOutput: {additionalContext: .}}')
printf '%s' "$output" | jq -e '
  .hookSpecificOutput.additionalContext |
  contains("specs/active-80/context.md") and contains("일 경과")
  and contains("specs/missing-date/context.md (상태: 진행중, 마지막 갱신: 미기재)")
  and contains("specs/future/context.md (상태: 진행중, 마지막 갱신: 2099-01-01)\n")
  and contains("specs/invalid/context.md (상태: 검토중, 마지막 갱신: invalid)\n")
  and (contains("specs/completed/") | not) and (contains("specs/legacy/") | not)
  and (contains("specs/missing-status/") | not) and (contains("specs/empty-status/") | not)
' >/dev/null
awk_calls=0
date_calls=0
while IFS= read -r executable; do
  case "$executable" in
    awk) awk_calls=$((awk_calls + 1)) ;;
    date) date_calls=$((date_calls + 1)) ;;
  esac
done < "$HOOK_TEST_COUNTER"
echo "session-start performance: awk=$awk_calls date=$date_calls"
[ "$awk_calls" -le 2 ]
[ "$date_calls" -le 8 ]
cat > "$TMP/bin/date" <<'SH'
#!/bin/bash
if [ "$*" = '+%s' ]; then
  if [ -e "$HOOK_TEST_COUNTER.parsed" ]; then printf '%s\n' 2778401; else printf '%s\n' 2778400; fi
else
  : > "$HOOK_TEST_COUNTER.parsed"
  printf '%s\n' 100001
fi
SH
output=$(PATH="$TMP/bin:$PATH" CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$ROOT/.claude/hooks/session_start.sh" --all | jq -Rs '{hookSpecificOutput: {additionalContext: .}}')
printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext | contains("specs/active-80/context.md (상태: 진행중(Phase 1), 마지막 갱신: 2000-01-01) — 31일 경과")' >/dev/null
