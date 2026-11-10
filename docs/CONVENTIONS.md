# Conventions

> 마지막 갱신: 2026-11-11
> 스타터 저장소 자체의 검증 명령과 컨벤션이다. 소비 프로젝트에는 빈 양식 [specs/_templates/CONVENTIONS.md](../specs/_templates/CONVENTIONS.md)가 복사된다.

## 명령어

| 목적 | 명령어 | 적용 |
|------|--------|------|
| diff 공백 오류 | git diff --check | 모든 변경 |
| 훅 회귀·셸 구문 | bash tests/hooks/run.sh | 훅 관련 변경·완료 검증 (러너가 각 셸 파일을 개별 검사) |
| bootstrap 기본 경로 배포·보존·재실행·공백 경로 | bash tests/bootstrap/run.sh | bootstrap·훅 설정 변경 |
| 지침 평가의 판정 회귀 | bash tests/guidelines/selftest.sh | 평가 러너 변경 (모델 호출 없음) |
| 훅 설정 JSON | jq empty .claude/settings.json | 설정 변경 |
| MCP 설정 JSON | jq empty .mcp.json | 설정 변경 |
| SessionStart 빈 프로젝트 샘플 | printf '%s' '{}' &#124; INIT_PROJECT_CLAUDE_SETTINGS=/dev/null CLAUDE_PROJECT_DIR=/dev/null bash .claude/hooks/session_start.sh | CML 미등록 조건에서 종료 0, 출력 없음 |
| 애플리케이션 테스트·타입·빌드 | 해당 없음 | 이 저장소는 문서·셸 스타터 |

표의 &#124;는 셸 파이프 기호다.

## 변경 유형별 검증

- 문서·스킬: 상대 링크와 경로, 필수 프론트매터, 승인 경계 및 AGENTS.md와의 일관성을 확인한다. 테스트 파일을 형식적으로 추가하지 않는다.
- 훅: 임시 프로젝트의 specs에 context를 만들고 CLAUDE_PROJECT_DIR를 지정해 샘플 stdin JSON으로 직접 실행한다. 활성 기능·완료 기능·빈 프로젝트의 출력과 종료 코드를 확인한다. PostToolUse는 실제 tool_input.file_path 또는 tool_input.command 형태를 사용한다.
- bootstrap: 임시 소비 프로젝트에서 기본 경로로 실행해 생성 파일(docs는 양식과 동일)·스킬/템플릿 심링크·훅 경로를 확인한다. 재실행하여 기존 문서·설정 보존을 확인한다. 실제 사용자 프로젝트를 검증용으로 변경하지 않는다.
- 훅 회귀 러너는 tests/hooks/run.sh, bootstrap 회귀 러너는 tests/bootstrap/run.sh다. 후자는 기본 init-project 배치에서 생성 문서·포인터·심링크·MCP 설정, 기존 사용자 파일/링크 보존, 일부 배포 단계 후 재실행, gitignore 중복 방지, 공백 경로의 실제 훅 실행, 누락된 훅 등록 안내, 지원하지 않는 서브모듈 경로 거절을 검사한다. 파일 쓰기 도중 강제 종료, 임의 서브모듈 배치, 다른 OS까지 검증한 것은 아니다.
- 중요한 지침 변경은 tests/guidelines/run.sh로 변경 전·후를 같은 모델에서 비교한다(사례와 판정은 tests/guidelines/README.md). 모델 비용이 드는 수동 실행이며 필수 커밋 검사가 아니다. 실행하지 않았으면 미실행으로 보고하고, 단일 실행을 효과의 증거로 일반화하지 않는다.

## 명명·문서 컨벤션

- 기능 폴더와 스킬 이름은 kebab-case. ADR은 NNN-title.md.
- 새 기능 문서·ADR은 specs/_templates/의 해당 파일을 복사한다.
- 상태·체크박스·검증 결과는 실제 작업과 일치시킨다.
- 공통 승인 정책은 AGENTS.md에만 정의한다. 다른 파일에서는 해당 절을 참조한다.
