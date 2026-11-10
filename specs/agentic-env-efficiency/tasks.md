# Agentic 환경 효율 개선 Tasks

> plan.md의 각 Phase를 실행 단위로 분해한 체크리스트. 승인 판단은 AGENTS.md §2.2~2.3을 따른다.

## 실행 순서 근거 (한 줄)

서로 독립인 작은 수정을 먼저 끝내고, 양식 분리(T5)가 평가 픽스처(T7)의 입력이며, 평가(T7)가 축소안(T9)의 근거라 그 순서로 둔다.

## Phase 1: 독립적인 작은 수정

- [x] T1. 편집·커밋·Stop 훅의 진행 중 판정을 SessionStart와 통일, 편집 훅 마커 경로·session_id 검증, 커밋 훅 오탐 제거 → 검증: `bash tests/hooks/run.sh`
- [x] T2. `.gitignore`와 bootstrap 무시 목록에 `.env` 추가(스타터는 `.ax/`도) → 검증: `bash tests/bootstrap/run.sh`, `git status`
- [x] T3. SessionStart 안내 문구를 "요청과 관련된 기능만"으로 수정 → 검증: `bash tests/hooks/run.sh`
- [x] T4. plan·tasks 양식의 승인 상태 기록을 context로 통합 → 검증: 양식·스킬 문구 일관성 검토

## Phase 2: 배포 구조

- [x] T5. 소비 프로젝트용 docs 양식을 `specs/_templates/`로 분리하고 스타터 docs에서 소비자 영역 제거 → 검증: `bash tests/bootstrap/run.sh`
- [x] T6. bootstrap 재실행 시 누락된 훅 등록 보고, 서브모듈 경로의 sed 특수문자 처리 → 검증: `bash tests/bootstrap/run.sh`

## Phase 3: 측정과 CI

- [ ] T7. 평가 러너와 판정 자체 테스트, 실제 실행 → 검증: `bash tests/guidelines/selftest.sh`, 실행 결과 JSON
- [ ] T8. CI 워크플로 추가 → 검증: 워크플로 명령의 로컬·Linux 컨테이너 실행

## Phase 4: AGENTS.md 축소안

- [ ] T9. 축소안 diff와 전·후 평가 결과 준비 → 검증: 평가 결과 JSON 비교

AGENTS.md 축소안 적용은 승인 대상이라 목록에 넣지 않고 [context.md](./context.md)의 "남은 승인 대상"에 기록한다.
