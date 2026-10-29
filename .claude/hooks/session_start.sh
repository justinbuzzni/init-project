#!/bin/bash
# SessionStart: 진행 중 기능의 context.md를 안내하고, 30일 초과 미갱신은 아카이브 검토를 제안.
# 진행 중 기능 또는 확인된 CML 등록이 있을 때만 안내한다.
set -uo pipefail
. "$(dirname "$0")/lib/common.sh" || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# 항목마다 "정렬 날짜␟30일 초과 여부␟안내 줄"을 모은 뒤 최근 갱신 순으로 상위 SHOWN_LIMIT건만 싣는다.
# 수백 건(수십 KB)을 다 실으면 Claude Code가 출력을 파일로 빼서 앞부분만 전달하므로,
# 나머지는 건수와 전체 목록 명령으로 대신한다.
SHOWN_LIMIT=20
sep=$'\037'
entries=""
date_values=()
date_days=()
date_count=0
while IFS=$'\034' read -r status updated context_file; do
  rel="${context_file#"$PROJECT_DIR"/}"
  extra=""
  days=""
  if [ -n "$updated" ]; then
    cache_index=0
    while [ "$cache_index" -lt "$date_count" ]; do
      [ "${date_values[$cache_index]}" = "$updated" ] && break
      cache_index=$((cache_index + 1))
    done
    if [ "$cache_index" -eq "$date_count" ]; then
      date_values[$date_count]="$updated"
      date_days[$date_count]=$(days_since "$updated")
      date_count=$((date_count + 1))
    fi
    days=${date_days[$cache_index]}
  fi
  stale=0
  if [ -n "$days" ] && [ "$days" -gt 30 ]; then
    extra=" — ${days}일 경과: 계속 진행할지, specs/_archive/로 옮길지 검토"; stale=1
  fi
  key=""
  [[ "$updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]] && key="${updated:0:10}"
  entries="${entries}${key}${sep}${stale}${sep}- ${rel} (상태: ${status}, 마지막 갱신: ${updated:-미기재})${extra}"$'\n'
done < <(feature_context_metadata)

lines="" all_lines="" shown=0 hidden=0 hidden_stale=0
while IFS="$sep" read -r _ stale line; do
  [ -n "$line" ] || continue
  all_lines="${all_lines}${line}"$'\n'
  if [ "$shown" -lt "$SHOWN_LIMIT" ]; then
    lines="${lines}${line}"$'\n'; shown=$((shown + 1))
  else
    hidden=$((hidden + 1)); hidden_stale=$((hidden_stale + stale))
  fi
done < <(printf '%s' "$entries" | sort -s -r -t "$sep" -k1,1)

if [ "${1:-}" = "--all" ]; then
  printf '%s' "$all_lines"
  exit 0
fi
if [ "$hidden" -gt 0 ]; then
  script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=$(dirname "$0")
  script_rel="${script_dir#"$PROJECT_DIR"/}/$(basename "$0")"
  # 안내한 명령을 그대로 붙여 넣어도 실행되도록, 셸 특수문자가 있으면 작은따옴표로 감싼다.
  q="'"
  case "$script_rel" in
    *[!A-Za-z0-9_./-]*) script_rel="'${script_rel//$q/$q\\$q$q}'" ;;
  esac
  lines="${lines}- 외 ${hidden}건(그중 30일 넘게 갱신되지 않은 문서 ${hidden_stale}건). 전체 목록: 프로젝트 루트에서 \`bash ${script_rel} --all\`"$'\n'
fi

mem_note=""
# Tokenize the registered command without executing it; preserve quoted spaces.
session_script=$(jq -er '
  select(.disableAllHooks != true) |
  [.hooks.SessionStart[]?.hooks[]? | select(.type == "command") |
   .command | strings | scan("\u0027[^\u0027]*\u0027|\"[^\"]*\"|[^[:space:]]+") |
   sub("^[\u0027\"]"; "") | sub("[\u0027\"]$"; "") |
   select(startswith("/") and endswith("/claude-memory-layer/dist/hooks/session-start.js"))][0] // empty
' "$CML_SETTINGS_FILE" 2>/dev/null) || session_script=""

if [ -n "$session_script" ]; then
  package_json="${session_script%/dist/hooks/session-start.js}/package.json"
  cml_version=$(jq -er '.version | strings' "$package_json" 2>/dev/null) || cml_version=""
  # Reject malformed/oversized numeric fields before bash arithmetic. Prereleases
  # of 2.4.0 precede the index release; build metadata does not affect precedence.
  version_pattern='^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'
  if [[ "$cml_version" =~ $version_pattern ]]; then
    cml_major=${BASH_REMATCH[1]}; cml_minor=${BASH_REMATCH[2]}; cml_patch=${BASH_REMATCH[3]}
    prerelease=${BASH_REMATCH[4]:-}
    if (( cml_major > 2 || (cml_major == 2 && (cml_minor > 4 || (cml_minor == 4 && cml_patch > 0))) )) ||
       { (( cml_major == 2 && cml_minor == 4 && cml_patch == 0 )) && [ -z "$prerelease" ]; }; then
      mem_note='관련 교훈이 세션 컨텍스트의 `## Project Lessons` 인덱스에 보이면 `mem-lesson-get`(이름)으로 본문을 열고 나서 작업하세요. 인덱스에 없으면 `mem-lesson-list`로 전체를 볼 수 있습니다.'
    else
      mem_note='과거 맥락·교훈은 mem-context-pack / mem-lesson-list로 회수할 수 있습니다 (AGENTS.md §2.8).
업그레이드 권장: npm i -g claude-memory-layer'
    fi
  fi
fi

msg="$mem_note"
if [ -n "$lines" ]; then
  msg="[ACTIVE FEATURES] 진행 중인 기능 문서:
${lines}작업 시작 전 해당 context.md를 읽고, 현재 상태를 한 문단으로 보고한 뒤 AGENTS.md §2.1에 따라 진행하세요.
${mem_note}"
fi
[ -z "$msg" ] && exit 0

jq -n --arg ctx "$msg" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}' 2>/dev/null
exit 0
