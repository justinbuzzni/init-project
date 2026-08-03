#!/bin/bash
# Stop: 진행 중 기능이 있을 때, 방금 작업에서 재사용 가능한 교훈이 나왔다면
# mem-lesson-save로 저장하도록 리마인드. 세션당 30분에 1회로 스로틀.
set -uo pipefail
. "$(dirname "$0")/lib/common.sh" || exit 0

active=$(list_feature_contexts | head -1)
[ -z "$active" ] && exit 0

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // "default"' 2>/dev/null)
marker="${TMPDIR:-/tmp}/claude_lesson_reminder_${session_id:-default}"
if [ -f "$marker" ] && [ -n "$(find "$marker" -mmin -30 2>/dev/null)" ]; then
  exit 0
fi
touch "$marker" 2>/dev/null

jq -n '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:"[LESSON CHECK] 방금까지의 작업에서 재사용 가능한 교훈(반복될 만한 실패 패턴, 우회법, 검증 순서 등)이 나왔다면 mem-lesson-save로 저장하세요. 판단이 안 서면 mem-lesson-candidates로 자동 탐지된 후보를 먼저 확인하세요 (AGENTS.md §2.7). 단순 진행 상황 보고였다면 무시해도 됩니다."}}'
exit 0
