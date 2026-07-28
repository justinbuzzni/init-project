#!/bin/bash
# SessionStart: 진행 중 기능의 context.md를 안내하고, 30일 초과 미갱신은 아카이브 검토를 제안.
# 진행 중 기능이 없으면 침묵 (토큰 낭비 방지).
set -uo pipefail
. "$(dirname "$0")/lib/common.sh" || exit 0

lines=""
while IFS= read -r f; do
  status=$(fm_get "$f" "상태")
  updated=$(fm_get "$f" "마지막 갱신")
  case "$status" in 완료*) continue ;; esac
  # 상태 프론트매터가 없는 문서는 "진행 중"이 아니라 추적 대상 밖(레거시)이다.
  # 이를 진행 중으로 취급하면 오래된 spec 수백 개가 매 세션 컨텍스트를 채워,
  # 정작 읽어야 할 진행 중 문서와 메모리 회수 안내가 묻힌다.
  [ -n "$status" ] || continue
  rel="${f#"$PROJECT_DIR"/}"
  extra=""
  days=$(days_since "$updated")
  if [ -n "$days" ] && [ "$days" -gt 30 ]; then
    extra=" — ${days}일 경과: 계속 진행할지, specs/_archive/로 옮길지 검토"
  fi
  lines="${lines}- ${rel} (상태: ${status}, 마지막 갱신: ${updated:-미기재})${extra}"$'\n'
done < <(list_feature_contexts)

[ -z "$lines" ] && exit 0

mem_note=""
if [ -f "$PROJECT_DIR/.mcp.json" ] && grep -q "claude-memory-layer" "$PROJECT_DIR/.mcp.json" 2>/dev/null; then
  mem_note="
과거 맥락·교훈은 mem-context-pack / mem-lesson-list로 회수할 수 있습니다 (AGENTS.md §2.8)."
fi

msg="[ACTIVE FEATURES] 진행 중인 기능 문서:
${lines}작업 시작 전 해당 context.md를 읽고, 현재 상태를 한 문단으로 요약해 사용자에게 확인하세요.${mem_note}"

jq -n --arg ctx "$msg" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
exit 0
