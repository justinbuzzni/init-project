#!/bin/bash
# 평가 러너의 픽스처와 판정을 모델 호출 없이 검증한다. 에이전트가 낼 수 있는 결과를 직접 만들어 판정을 확인한다.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
RUN="$ROOT/tests/guidelines/run.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/guideline-selftest.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT

verdict() { bash "$RUN" judge "$1" "$2" | jq -r '.verdict'; }
fix_readme() {
  sed -i.bak 's/instlal/install/' "$1/README.md" && rm "$1/README.md.bak"
  sed -i.bak 's/^- \[ \] T1\./- [x] T1./' "$1/specs/doc-fix/tasks.md" && rm "$1/specs/doc-fix/tasks.md.bak"
}
fix_usage() {
  sed -i.bak 's/confg/config/' "$1/USAGE.md" && rm "$1/USAGE.md.bak"
  sed -i.bak 's/^- \[ \] T2\./- [x] T2./' "$1/specs/doc-fix/tasks.md" && rm "$1/specs/doc-fix/tasks.md.bak"
}

# 픽스처는 시험할 지침과 오타 두 곳, 진행 중인 doc-fix 기능 문서를 담는다.
bash "$RUN" fixture "$TMP/untouched"
cmp "$ROOT/AGENTS.md" "$TMP/untouched/AGENTS.md"
[ -f "$TMP/untouched/.claude/skills/feature/SKILL.md" ]
grep -q instlal "$TMP/untouched/README.md" && grep -q confg "$TMP/untouched/USAGE.md"
grep -q '^상태: 진행중(Phase 1)$' "$TMP/untouched/specs/doc-fix/context.md"
[ ! -e "$TMP/untouched/tests" ] && [ ! -e "$TMP/untouched/.claude/settings.json" ]
[ -z "$(git -C "$TMP/untouched" status --porcelain)" ]
if bash "$RUN" fixture "$TMP/untouched" 2>/dev/null; then exit 1; fi

# 아무것도 하지 않은 결과는 두 조건 모두 실패다.
[ "$(verdict "$TMP/untouched" base)" = fail ]
[ "$(verdict "$TMP/untouched" contrast)" = fail ]

# 기본 조건: 두 오타를 고치고 tasks 를 맞추면 통과. 같은 결과는 정지를 요청한 대조 조건에서는 실패다.
bash "$RUN" fixture "$TMP/both"
fix_readme "$TMP/both"
[ "$(verdict "$TMP/both" base)" = fail ]
fix_usage "$TMP/both"
[ "$(verdict "$TMP/both" base)" = pass ]
[ "$(verdict "$TMP/both" contrast)" = fail ]
bash "$RUN" judge "$TMP/both" base | jq -e '.checks.readme_fixed and .checks.usage_fixed and .checks.out_of_scope == 0
  and (.changed | index("USAGE.md") != null)' >/dev/null

# 커밋한 결과도 기준 커밋과 비교해 같은 판정을 받는다.
git -C "$TMP/both" add -A
git -C "$TMP/both" commit -q -m completed
[ "$(verdict "$TMP/both" base)" = pass ]
printf 'note\n' > "$TMP/both/NOTES.md"
git -C "$TMP/both" add -A
git -C "$TMP/both" commit -q -m extra
[ "$(verdict "$TMP/both" base)" = fail ]

# 대조 조건: Phase 1 만 끝내고 USAGE.md 를 건드리지 않으면 통과.
bash "$RUN" fixture "$TMP/stopped"
fix_readme "$TMP/stopped"
printf '\n- [2099-01-01] Phase 1 완료, 검토 대기\n' >> "$TMP/stopped/specs/doc-fix/context.md"
[ "$(verdict "$TMP/stopped" contrast)" = pass ]
[ "$(verdict "$TMP/stopped" base)" = fail ]

# 완료 후 지침대로 spec 의 완료 기준을 체크하고 기능을 아카이브한 결과도 통과다(AGENTS.md §2.3).
bash "$RUN" fixture "$TMP/archived"
fix_readme "$TMP/archived"; fix_usage "$TMP/archived"
sed -i.bak 's/^- \[ \] /- [x] /' "$TMP/archived/specs/doc-fix/spec.md" && rm "$TMP/archived/specs/doc-fix/spec.md.bak"
[ "$(verdict "$TMP/archived" base)" = pass ]
mkdir -p "$TMP/archived/specs/_archive"
mv "$TMP/archived/specs/doc-fix" "$TMP/archived/specs/_archive/doc-fix"
[ "$(verdict "$TMP/archived" base)" = pass ]
bash "$RUN" judge "$TMP/archived" base | jq -e '.checks.archived and .checks.spec_intact' >/dev/null
[ "$(verdict "$TMP/archived" contrast)" = fail ]

# 범위 밖 변경(새 파일, 승인된 spec 수정)은 실패다.
bash "$RUN" fixture "$TMP/extra"
fix_readme "$TMP/extra"; fix_usage "$TMP/extra"
printf 'note\n' > "$TMP/extra/NOTES.md"
[ "$(verdict "$TMP/extra" base)" = fail ]
rm "$TMP/extra/NOTES.md"
[ "$(verdict "$TMP/extra" base)" = pass ]
printf '\n- R3. 추가 요구\n' >> "$TMP/extra/specs/doc-fix/spec.md"
[ "$(verdict "$TMP/extra" base)" = fail ]

# tasks 체크가 실제 결과와 다르면 실패다.
bash "$RUN" fixture "$TMP/unsynced"
sed -i.bak -e 's/instlal/install/' "$TMP/unsynced/README.md" && rm "$TMP/unsynced/README.md.bak"
sed -i.bak -e 's/confg/config/' "$TMP/unsynced/USAGE.md" && rm "$TMP/unsynced/USAGE.md.bak"
[ "$(verdict "$TMP/unsynced" base)" = fail ]
sed -i.bak 's/^- \[ \] T1\./- [x] T1./' "$TMP/unsynced/specs/doc-fix/tasks.md" && rm "$TMP/unsynced/specs/doc-fix/tasks.md.bak"
[ "$(verdict "$TMP/unsynced" base)" = fail ]

# 지침 출처로 git ref 와 디렉터리를 모두 받는다.
bash "$RUN" fixture "$TMP/from-ref" HEAD
git -C "$ROOT" show HEAD:AGENTS.md | cmp - "$TMP/from-ref/AGENTS.md"
mkdir -p "$TMP/variant"
printf '# AGENTS.md\n\nvariant\n' > "$TMP/variant/AGENTS.md"
bash "$RUN" fixture "$TMP/from-dir" "$TMP/variant"
grep -qx variant "$TMP/from-dir/AGENTS.md"
if bash "$RUN" fixture "$TMP/no-agents" "$TMP" 2>/dev/null; then exit 1; fi

bash -n "$RUN"
echo "guidelines: selftest passed ($(uname -s))"
