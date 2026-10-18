#!/bin/bash
# 기본 경로 배포 산출물·사용자 파일 보존·재실행·공백 경로의 훅 실행을 검증한다.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
FIXTURES="$ROOT/tests/hooks"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/init-project-bootstrap.XXXXXX")
trap 'rm -r -- "$TMP"' EXIT

# 쪼개진 첫 단어("$TMP/WINDOWS")에 실제 파일이 있던 사고를 재현하는 미끼
printf '#!/bin/sh\nexit 3\n' > "$TMP/WINDOWS"
chmod +x "$TMP/WINDOWS"

new_project() {
  local project="$TMP/WINDOWS USER/$1"
  mkdir -p "$project/init-project/"{specs,docs,scripts,.claude}
  # 배포 입력만 복사해 사용자 .env, git 메타데이터, 작업 산출물을 격리한다.
  cp "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/.mcp.json" "$project/init-project/"
  cp "$ROOT/scripts/bootstrap.sh" "$project/init-project/scripts/"
  cp "$ROOT/docs/ARCHITECTURE.md" "$ROOT/docs/CONVENTIONS.md" "$project/init-project/docs/"
  cp -R "$ROOT/.claude/settings.json" "$ROOT/.claude/hooks" "$ROOT/.claude/skills" "$project/init-project/.claude/"
  cp -R "$ROOT/specs/_templates" "$project/init-project/specs/"
  echo "$project"
}

bootstrap() {
  (cd "$1" && bash init-project/scripts/bootstrap.sh >/dev/null)
}

assert_distribution() {
  local project=$1 name source
  grep -qF 'init-project/AGENTS.md' "$project/AGENTS.md"
  grep -qF '@init-project/AGENTS.md' "$project/CLAUDE.md"
  for name in ARCHITECTURE.md CONVENTIONS.md; do
    cmp "$project/init-project/docs/$name" "$project/docs/$name"
  done
  cmp "$project/init-project/.mcp.json" "$project/.mcp.json"
  jq empty "$project/.mcp.json"
  [ -d "$project/docs/adr" ] && [ -d "$project/specs/_archive" ]
  [ "$(readlink "$project/specs/_templates")" = '../init-project/specs/_templates' ]
  [ -f "$project/specs/_templates/plan.md" ]
  for source in "$project/init-project/.claude/skills/"*/; do
    name=$(basename "$source")
    [ "$(readlink "$project/.claude/skills/$name")" = "../../init-project/.claude/skills/$name" ]
    [ -f "$project/.claude/skills/$name/SKILL.md" ]
  done
  jq -e '.hooks | length > 0' "$project/.claude/settings.json" >/dev/null
  for name in 'memory/' '.DS_Store'; do
    [ "$(grep -cxF "$name" "$project/.gitignore")" -eq 1 ]
  done
}

distribution_manifest() {
  (cd "$1" && find . -path ./init-project -prune -o -type d -print \
    -o -type f -exec cksum {} \; \
    -o -type l -exec sh -c 'printf "link %s %s\n" "$1" "$(readlink "$1")"' _ {} \;) | LC_ALL=C sort
}

# settings.json 의 모든 훅 명령을 Claude Code 처럼 셸로 실행해 종료 0 인지 확인한다.
assert_hook_commands_run() {
  local project=$1 event command input
  jq -r '.hooks | to_entries[] | .key as $event | .value[].hooks[] | select(.type == "command") | "\($event)\t\(.command)"' \
    "$project/.claude/settings.json" > "$TMP/commands"
  [ -s "$TMP/commands" ]
  while IFS=$'\t' read -r event command; do
    case "$event" in
      SessionStart) input="$FIXTURES/session_start.json" ;;
      Stop) input="$FIXTURES/stop.json" ;;
      *) input=/dev/null ;;
    esac
    if ! CLAUDE_PROJECT_DIR="$project" INIT_PROJECT_CLAUDE_SETTINGS=/dev/null INIT_PROJECT_HOOK_TMPDIR="$TMP" \
      sh -c "$command" < "$input" >/dev/null 2> "$TMP/stderr"; then
      echo "실패: [$event] $command" >&2
      cat "$TMP/stderr" >&2
      return 1
    fi
  done < "$TMP/commands"
}

# 1) 새 소비 프로젝트
project=$(new_project fresh)
bootstrap "$project"
assert_distribution "$project"
assert_hook_commands_run "$project"
distribution_manifest "$project" > "$TMP/fresh-before"
bootstrap "$project"
assert_distribution "$project"
distribution_manifest "$project" > "$TMP/fresh-after"
cmp "$TMP/fresh-before" "$TMP/fresh-after"

# 2) 따옴표 없이 생성된 기존 settings.json 은 재실행 시 치유되고, 다른 명령은 그대로 둔다
project=$(new_project legacy)
mkdir -p "$project/.claude"
cat > "$project/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/init-project/.claude/hooks/stop_lesson_reminder.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/init-project/.claude/hooks/stop_lesson_reminder.sh"
          },
          {
            "type": "command",
            "command": "echo keep"
          }
        ]
      }
    ]
  }
}
EOF
bootstrap "$project"
assert_hook_commands_run "$project"
jq -e '[.hooks.Stop[].hooks[].command] | index("echo keep") != null' "$project/.claude/settings.json" >/dev/null

# 3) 재실행은 멱등이다
cp "$project/.claude/settings.json" "$TMP/before.json"
bootstrap "$project"
cmp -s "$TMP/before.json" "$project/.claude/settings.json"

# 4) 소비자가 소유한 문서·설정·템플릿·스킬은 보존한다.
project=$(new_project customized)
preserved=(AGENTS.md CLAUDE.md docs/ARCHITECTURE.md docs/CONVENTIONS.md
  .mcp.json .claude/settings.json specs/_templates/plan.md .claude/skills/feature/SKILL.md)
for file in "${preserved[@]}"; do
  mkdir -p "$(dirname "$project/$file")" "$(dirname "$TMP/preserved/$file")"
  case "$file" in
    *.json) printf '{"custom":"keep","hooks":{}}\n' > "$project/$file" ;;
    *) printf 'consumer-owned: %s\n' "$file" > "$project/$file" ;;
  esac
  cp "$project/$file" "$TMP/preserved/$file"
done
ln -s ../../custom-handoff "$project/.claude/skills/handoff"
printf 'consumer-cache/\nmemory/\n' > "$project/.gitignore"
bootstrap "$project"
distribution_manifest "$project" > "$TMP/custom-before"
bootstrap "$project"
distribution_manifest "$project" > "$TMP/custom-after"
cmp "$TMP/custom-before" "$TMP/custom-after"
for file in "${preserved[@]}"; do
  cmp "$TMP/preserved/$file" "$project/$file"
done
[ "$(readlink "$project/.claude/skills/handoff")" = '../../custom-handoff' ]
printf 'consumer-cache/\nmemory/\n.DS_Store\n' > "$TMP/expected-ignore"
cmp "$TMP/expected-ignore" "$project/.gitignore"
[ -f "$project/.claude/skills/learn/SKILL.md" ]

# 5) 일부 배포 단계가 끝난 상태에서 재실행한다. 파일 쓰기 도중의 중단은 이 검사의 범위 밖이다.
project=$(new_project partial)
mkdir -p "$project/docs" "$project/specs"
cp "$project/init-project/docs/ARCHITECTURE.md" "$project/docs/ARCHITECTURE.md"
ln -s ../init-project/specs/_templates "$project/specs/_templates"
bootstrap "$project"
assert_distribution "$project"
assert_hook_commands_run "$project"
distribution_manifest "$project" > "$TMP/partial-before"
bootstrap "$project"
assert_distribution "$project"
distribution_manifest "$project" > "$TMP/partial-after"
cmp "$TMP/partial-before" "$TMP/partial-after"

echo "bootstrap: all tests passed ($(uname -s))"
