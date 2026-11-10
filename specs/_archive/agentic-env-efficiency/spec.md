# Agentic 환경 효율 개선 Spec

> 작성일: 2026-11-11 / 상태: 승인됨
> ⚠️ 승인 후에는 사용자 지시 없이 수정 금지

## 목표

스타터 유지보수자와 소비 프로젝트의 에이전트가 불필요한 리마인더·문서 읽기·수동 확인 없이 일하도록, 2026-11-11 분석에서 확인한 결함과 누락을 고친다.

## 요구사항

- R1. Given 상태 프론트매터가 없는 context.md만 있는 프로젝트, When 편집·커밋·Stop 훅이 실행되면, Then SessionStart와 같이 침묵한다.
- R2. Given 편집 훅, When 마커를 만들면, Then 주입된 마커 디렉터리만 쓰고 경로를 벗어나는 session_id에는 침묵한다.
- R3. Given 새 커밋을 만들지 않은 Bash 명령에 `git commit` 문자열이 있을 때, When 커밋 훅이 실행되면, Then 과거 커밋을 근거로 안내하지 않는다.
- R4. Given 스타터와 새 소비 프로젝트, When git 상태를 보면, Then `.env`는 무시된다(스타터는 `.ax/`도).
- R5. Given 진행 중 기능 목록, When SessionStart가 안내하면, Then 요청과 관련된 기능의 context만 읽도록 안내한다(AGENTS.md §2.1·§2.7과 일치).
- R6. Given 기능 문서 양식, When 승인 상태를 기록하면, Then 기록 위치는 context.md 한 곳이다.
- R7. Given 새 소비 프로젝트, When bootstrap을 실행하면, Then docs에는 스타터 내부 설명이 없는 빈 양식이 복사된다.
- R8. Given settings.json이 이미 있는 소비 프로젝트, When bootstrap을 재실행하면, Then 등록되지 않은 스타터 훅을 이름으로 알려준다.
- R9. Given 지침 변경 전·후 버전, When 평가 러너를 실행하면, Then 파일 결과로 통과·실패를 판정하고 턴 수·토큰 사용량을 기록한다. 판정 로직은 모델 호출 없이 검증할 수 있다.
- R10. Given push 또는 PR, When CI가 실행되면, Then ubuntu와 macOS에서 훅·bootstrap·평가 판정 회귀와 설정 JSON 검사를 수행한다.
- R11. AGENTS.md 상시 로드 분량 축소는 변경안 diff와 전·후 평가 결과를 준비해 승인을 요청한다. 승인 전에는 적용하지 않는다.

## 비목표 (Non-Goals)

- 훅 실행 속도 최적화 — 호출당 10~18ms로 이미 충분하다.
- 검증 전용 서브에이전트 정의 — 스타터 검증 출력이 2~3줄이라 이득이 없고 Claude 전용 자산만 늘어난다.
- SessionStart 표시 건수(20건) 변경 — 재검토 조건을 둔 최근 결정이다.
- `.claude/settings.json`을 스타터용과 배포 원본으로 분리 — 현재 필요한 소비자가 없다.
- 세션 환경(전역 플러그인·MCP·메모리 훅) 정리 — 저장소 밖 사용자 설정이다.
- push·PR·merge — 별도 사용자 요청이 필요하다.

## 제약

- 호환성: 기존 소비 프로젝트의 문서·설정·심링크를 덮어쓰지 않는다. context 프론트매터 키를 유지한다.
- 의존성: 훅은 bash와 jq만 사용한다. bootstrap의 jq 사용은 선택적이어야 한다(없으면 기존 수동 안내).
- 보안: 평가 러너는 임시 디렉터리에서 허용 목록 도구만 쓰고 MCP·사용자 설정을 연결하지 않는다.

## 완료 기준 (Definition of Done)

- [x] R1~R10에 대응하는 검증 완료 (동작은 테스트, 문서는 링크·형식·내용 검토)
- [x] `bash tests/hooks/run.sh`, `bash tests/bootstrap/run.sh`, 평가 판정 자체 테스트, 설정 JSON 검사 통과
- [x] 문서 갱신 (context.md, ARCHITECTURE.md, CONVENTIONS.md, README.md)
- [x] R11 변경안과 평가 결과 제시, 승인 여부에 따른 후속 처리
