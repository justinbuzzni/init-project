#!/bin/bash
# 훅 공통 유틸. 의존성: bash + jq (+ coreutils date). 오류 시에도 워크플로를 막지 않도록 exit 0 기본.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SPECS_DIR="$PROJECT_DIR/specs"
CML_SETTINGS_FILE="${INIT_PROJECT_CLAUDE_SETTINGS:-${HOME:-}/.claude/settings.json}"
HOOK_TMPDIR="${INIT_PROJECT_HOOK_TMPDIR:-${TMPDIR:-/tmp}}"

# 진행 중 기능의 context.md 목록. 판정은 feature_context_metadata 하나를 쓴다
# (상태 프론트매터가 있고 완료가 아닌 문서. _templates, _archive 제외).
list_feature_contexts() {
  feature_context_metadata | while IFS=$'\034' read -r _ _ context_file; do
    printf '%s\n' "$context_file"
  done
}

# 출력: "상태␜마지막 갱신␜경로". 문서마다 프로세스를 띄우지 않도록 awk 하나로 읽는다.
# 주의: BSD awk는 UTF-8 로케일에서 문자열 == 비교가 오동작(strcoll)하므로 index() 접두사 매칭 사용
feature_context_metadata() {
  [ -d "$SPECS_DIR" ] || return 0
  for context_file in "$SPECS_DIR"/*/context.md; do
    [ -e "$context_file" ] || continue
    case "$context_file" in
      */_templates/*|*/_archive/*) continue ;;
    esac
    printf '%s\n' "$context_file"
  done | awk '
    function read_context(context_file, line, status, updated, has_status, has_updated) {
      if ((getline line < context_file) <= 0 || line != "---") {
        close(context_file)
        return
      }
      while ((getline line < context_file) > 0) {
        if (line == "---") break
        if (!has_status && index(line, "상태: ") == 1) {
          status = substr(line, length("상태: ") + 1)
          has_status = 1
        }
        if (!has_updated && index(line, "마지막 갱신: ") == 1) {
          updated = substr(line, length("마지막 갱신: ") + 1)
          has_updated = 1
        }
      }
      close(context_file)
      if (status != "" && index(status, "완료") != 1)
        printf "%s\034%s\034%s\n", status, updated, context_file
    }
    { read_context($0) }
  ' 2>/dev/null
}

# YYYY-MM-DD → 오늘까지 경과 일수. 파싱 실패 시 출력 없음 (macOS/GNU date 모두 지원)
days_since() {
  local d="$1" then_ts now_ts
  [ -n "$d" ] || return 0
  then_ts=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null) \
    || then_ts=$(date -d "$d" +%s 2>/dev/null) \
    || return 0
  now_ts=$(date +%s)
  echo $(( (now_ts - then_ts) / 86400 ))
}
