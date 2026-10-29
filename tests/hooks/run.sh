#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HOOKS="$ROOT/.claude/hooks"
FIXTURES="$ROOT/tests/hooks"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/init-project-hooks.XXXXXX")
trap 'rm -r -- "$TMP"' EXIT

assert_json_event() {
  local output=$1 expected=$2
  printf '%s' "$output" | jq -e --arg event "$expected" '.hookSpecificOutput.hookEventName == $event' >/dev/null
}

assert_stop_message() {
  local output=$1
  printf '%s' "$output" | jq -e '
    .systemMessage
    and (.continue? != false)
    and (has("decision") | not)
    and ((.hookSpecificOutput?.additionalContext // "") == "")
  ' >/dev/null
}

make_settings() {
  local version=$1 root=$2
  mkdir -p "$root/node_modules/claude-memory-layer/dist/hooks"
  printf '{"version":"%s"}\n' "$version" > "$root/node_modules/claude-memory-layer/package.json"
  jq -n --arg command "$root/node_modules/claude-memory-layer/dist/hooks/session-start.js" '{hooks:{SessionStart:[{hooks:[{type:"command",command:$command}]}]}}' > "$TMP/settings.json"
}

project="$TMP/project"
mkdir -p "$project/specs/demo"
printf '%s\n' '---' '상태: 진행중(Phase 1)' '---' > "$project/specs/demo/context.md"

make_settings 2.4.0 "$TMP/cml240"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
assert_json_event "$out" SessionStart
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-get") and contains("Project Lessons")' >/dev/null

make_settings 2.3.5 "$TMP/cml235"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
assert_json_event "$out" SessionStart
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-list") and contains("업그레이드 권장") and (contains("mem-lesson-get") | not)' >/dev/null

printf '%s\n' '{}' > "$TMP/no-cml.json"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/no-cml.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
assert_json_event "$out" SessionStart
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | (contains("mem-lesson-list") | not)' >/dev/null

# 상태 프론트매터가 없는 레거시 context.md 는 추적 대상 밖이므로 활성 기능 목록에
# 올라오지 않는다. 이것이 무너지면 오래된 spec 수백 개가 매 세션 컨텍스트를 채운다.
mkdir -p "$project/specs/legacy"
printf '%s\n' '# 예전 기능 메모' '프론트매터 없음' > "$project/specs/legacy/context.md"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/no-cml.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
assert_json_event "$out" SessionStart
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("specs/demo") and (contains("specs/legacy") | not) and (contains("상태: 미기재") | not)' >/dev/null
rm -rf "$project/specs/legacy"

# 진행 중 문서가 많으면 최근 갱신 순 상위 20건만 싣고 나머지는 건수와 --all 명령으로 대신한다.
# 출력이 수십 KB가 되면 Claude Code가 파일로 빼서 앞부분만 전달하기 때문이다.
many="$TMP/many"
for i in $(seq -w 1 24); do
  mkdir -p "$many/specs/f$i"
  printf '%s\n' '---' "상태: 진행중($i)" "마지막 갱신: 2030-01-$i" '---' > "$many/specs/f$i/context.md"
done
mkdir -p "$many/specs/old" "$many/specs/undated"
printf '%s\n' '---' '상태: 진행중(old)' '마지막 갱신: 2000-01-01' '---' > "$many/specs/old/context.md"
printf '%s\n' '---' '상태: 진행중(undated)' '---' > "$many/specs/undated/context.md"
out=$(CLAUDE_PROJECT_DIR="$many" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/no-cml.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
ctx=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext')
[ "$(printf '%s\n' "$ctx" | grep -c '^- specs/')" -eq 20 ]
[ "$(printf '%s\n' "$ctx" | grep -m1 '^- specs/')" = '- specs/f24/context.md (상태: 진행중(24), 마지막 갱신: 2030-01-24)' ]
printf '%s\n' "$ctx" | grep -q '^- 외 6건(그중 30일 넘게 갱신되지 않은 문서 1건)\. 전체 목록: 프로젝트 루트에서 `bash [^`]*\.claude/hooks/session_start\.sh --all`$'
if printf '%s\n' "$ctx" | grep -q 'specs/f04/'; then exit 1; fi
all=$(CLAUDE_PROJECT_DIR="$many" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/no-cml.json" bash "$HOOKS/session_start.sh" --all < /dev/null)
[ "$(printf '%s\n' "$all" | grep -c '^- specs/')" -eq 26 ]
[ "$(printf '%s\n' "$all" | head -1)" = '- specs/f24/context.md (상태: 진행중(24), 마지막 갱신: 2030-01-24)' ]
printf '%s\n' "$all" | grep -q '^- specs/old/context.md (상태: 진행중(old), 마지막 갱신: 2000-01-01) — [0-9]*일 경과'
[ "$(printf '%s\n' "$all" | tail -1)" = '- specs/undated/context.md (상태: 진행중(undated), 마지막 갱신: 미기재)' ]
# 안내된 --all 명령은 공백·따옴표가 든 훅 경로에서도 프로젝트 루트에서 그대로 실행된다.
spaced="$TMP/hook dir's copy"
mkdir -p "$spaced"
cp -R "$HOOKS/." "$spaced/"
out=$(CLAUDE_PROJECT_DIR="$many" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/no-cml.json" bash "$spaced/session_start.sh" < "$FIXTURES/session_start.json")
advertised=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' | sed -n 's/^- 외 .*전체 목록: 프로젝트 루트에서 `\(.*\)`$/\1/p')
[ -n "$advertised" ]
[ "$(cd "$many" && CLAUDE_PROJECT_DIR="$many" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/no-cml.json" bash -c "$advertised" < /dev/null | grep -c '^- specs/')" -eq 26 ]

marker_dir="$TMP/markers"
mkdir -p "$marker_dir"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh" < "$FIXTURES/stop.json")
assert_stop_message "$out"
printf '%s' "$out" | jq -e '.systemMessage | contains("어휘 겹침") and contains("환경 의존 실패")' >/dev/null
second=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh" < "$FIXTURES/stop.json")
[ -z "$second" ]

# SessionStart must not infer registration from a different event.
make_settings 2.4.0 "$TMP/wrong-event"
jq '.hooks.Stop = .hooks.SessionStart | del(.hooks.SessionStart)' "$TMP/settings.json" > "$TMP/wrong-event.json"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/wrong-event.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-get") | not' >/dev/null

make_settings 2.4.0 "$TMP/path with spaces"
jq '.hooks.SessionStart[0].hooks[0].command |= ("node " + @sh)' "$TMP/settings.json" > "$TMP/quoted.json"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/quoted.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json")
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-get")' >/dev/null

make_settings nonsense "$TMP/invalid-version"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh" < "$FIXTURES/session_start.json" 2> "$TMP/stderr")
[ ! -s "$TMP/stderr" ]
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-list") | not' >/dev/null

out=$(printf '%s' '{bad json' | CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh")
[ -z "$out" ]

jq -e '.hooks.Stop[].hooks[] | select(.command | endswith("/stop_lesson_reminder.sh"))' "$ROOT/.claude/settings.json" >/dev/null

# Numeric precedence, prerelease boundary, and invalid package metadata.
for version in 2.4.0+build 2.4.1-rc.1 2.10.0 3.0.0; do
  make_settings "$version" "$TMP/version"
  out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh")
  printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-get")' >/dev/null
done
make_settings 2.4.0-rc.1 "$TMP/version"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh")
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("업그레이드 권장")' >/dev/null
for version in 2.x.0 2.4 02.4.0 999999999999999999999.0.0; do
  make_settings "$version" "$TMP/version"
  out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh" 2> "$TMP/stderr")
  [ ! -s "$TMP/stderr" ]
  printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-list") | not' >/dev/null
done

# No feature is needed for the CML index reminder; event ordering is unspecified.
mkdir -p "$TMP/empty-project"
make_settings 2.4.0 "$TMP/version"
for source in startup resume compact; do
  jq --arg source "$source" '.source = $source' "$FIXTURES/session_start.json" > "$TMP/input.json"
  out=$(CLAUDE_PROJECT_DIR="$TMP/empty-project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh" < "$TMP/input.json")
  assert_json_event "$out" SessionStart
  printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | contains("mem-lesson-get")' >/dev/null
done

printf '%s' '{bad json' > "$TMP/bad-settings.json"
jq '.disableAllHooks = true' "$TMP/settings.json" > "$TMP/disabled.json"
for settings in "$TMP/no-cml.json" "$TMP/missing.json" "$TMP/bad-settings.json" "$TMP/disabled.json"; do
  out=$(CLAUDE_PROJECT_DIR="$TMP/empty-project" INIT_PROJECT_CLAUDE_SETTINGS="$settings" bash "$HOOKS/session_start.sh" 2> "$TMP/stderr")
  [ -z "$out" ] && [ ! -s "$TMP/stderr" ]
done
for metadata in 'not json' '{}' '{"version":4}'; do
  printf '%s' "$metadata" > "$TMP/version/node_modules/claude-memory-layer/package.json"
  out=$(CLAUDE_PROJECT_DIR="$TMP/empty-project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/settings.json" bash "$HOOKS/session_start.sh" 2> "$TMP/stderr")
  [ -z "$out" ] && [ ! -s "$TMP/stderr" ]
done
jq -n --arg command "$TMP/missing/claude-memory-layer/dist/hooks/session-start.js" '{hooks:{SessionStart:[{hooks:[{type:"command",command:$command}]}]}}' > "$TMP/missing-package.json"
out=$(CLAUDE_PROJECT_DIR="$TMP/empty-project" INIT_PROJECT_CLAUDE_SETTINGS="$TMP/missing-package.json" bash "$HOOKS/session_start.sh" 2> "$TMP/stderr")
[ -z "$out" ] && [ ! -s "$TMP/stderr" ]

# Session keys remain independent, expired markers permit a reminder, and bad
# input never creates a default marker or escapes the injected marker directory.
jq '.session_id = "another-session"' "$FIXTURES/stop.json" > "$TMP/another.json"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh" < "$TMP/another.json")
assert_stop_message "$out"
touch -t 200001010000 "$marker_dir/claude_lesson_reminder_test-session"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh" < "$FIXTURES/stop.json")
assert_stop_message "$out"
for input in '{bad' '{"session_id":"../escape"}' '{"session_id":7}' '[]'; do
  out=$(printf '%s' "$input" | CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh" 2> "$TMP/stderr")
  [ -z "$out" ] && [ ! -s "$TMP/stderr" ]
done
[ ! -e "$marker_dir/claude_lesson_reminder_default" ]
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$TMP/missing-marker-dir" bash "$HOOKS/stop_lesson_reminder.sh" < "$FIXTURES/stop.json" 2> "$TMP/stderr")
[ -z "$out" ] && [ ! -s "$TMP/stderr" ]
printf '%s\n' '---' '상태: 완료' '---' > "$project/specs/demo/context.md"
out=$(CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_HOOK_TMPDIR="$marker_dir" bash "$HOOKS/stop_lesson_reminder.sh" < "$TMP/another.json")
[ -z "$out" ]

bash "$FIXTURES/session-start-performance.sh"

for script in "$HOOKS"/*.sh "$HOOKS"/lib/*.sh "$ROOT/scripts/bootstrap.sh" "$FIXTURES"/*.sh; do
  bash -n "$script"
done
jq empty "$ROOT/.claude/settings.json"
echo "hooks: all tests passed ($(uname -s))"
