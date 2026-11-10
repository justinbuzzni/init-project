# Agentic 환경 효율 개선 Plan

> 작성일: 2026-11-11 / 상태: 진행중
> 근거 문서: [spec.md](./spec.md)

## 아키텍처 영향

| 항목 | 내용 |
|------|------|
| 관련 모듈/레이어 | 리마인더(.claude/hooks), 배포(scripts/bootstrap.sh), 문서 양식(specs/_templates), 검증(tests/, CI) |
| 영향받는 소비 경로 | 새 소비 프로젝트의 docs 초기 내용과 .gitignore, 재실행 시 bootstrap 출력, 편집·커밋·Stop 리마인더 발생 조건 |
| 새 외부 의존성 | GitHub Actions(저장소 CI). 평가 러너는 선택적으로 claude CLI를 사용 |
| 모듈 경계/공개 API 변경 | 없음. bootstrap 입력에 `specs/_templates/{ARCHITECTURE,CONVENTIONS}.md` 추가 |
| 데이터 스키마 변경 | 없음. context 프론트매터 키 유지 |

## 접근 방식

훅은 `list_feature_contexts`를 SessionStart가 쓰는 `feature_context_metadata` 위에 올려 판정을 하나로 만든다.
소비 프로젝트용 docs 양식은 기존 양식 위치인 `specs/_templates/`에 두고 bootstrap이 거기서 복사한다. 새 최상위 디렉터리는 만들지 않는다.
평가는 판정(파일 결과 → JSON)과 실행(claude CLI 호출)을 분리해 판정만 CI에서 검증한다.
기각: 커밋 훅이 tool_response를 해석 — 스키마를 확인할 수 없어, HEAD 커밋 시각이 최근인지로 판단한다.
기각: bootstrap `--check` 별도 모드 — 재실행이 이미 멱등이라 기존 settings.json 분기에서 누락을 보고하면 충분하다.

## 신규 파일

- `specs/_templates/ARCHITECTURE.md`, `specs/_templates/CONVENTIONS.md` — 소비 프로젝트에 복사할 빈 양식.
- `tests/guidelines/run.sh` — 평가 픽스처 생성·판정·실행.
- `tests/guidelines/selftest.sh` — 모델 호출 없는 판정 회귀.
- `.github/workflows/verify.yml` — CI.

## 단계 (Phases)

- [x] **Phase 1: 독립적인 작은 수정** → 검증: `bash tests/hooks/run.sh`, `bash tests/bootstrap/run.sh`
- [x] **Phase 2: 배포 구조** → 검증: `bash tests/bootstrap/run.sh`, 문서 링크 검토
- [x] **Phase 3: 측정과 CI** → 검증: `bash tests/guidelines/selftest.sh`, 평가 실제 실행 1회 이상, 가능하면 Linux 컨테이너 실행
- [ ] **Phase 4: AGENTS.md 축소안** → 검증: 전·후 평가 결과와 diff 제시 (승인 지점)

## 리스크와 대응

- 레거시 문서를 진행 중으로 쓰던 소비 프로젝트는 편집·Stop 리마인더가 사라진다 → 의도한 변경이며 프론트매터를 추가하면 다시 추적된다. 되돌리려면 해당 커밋을 revert한다.
- 새 양식으로 docs가 바뀌는 것은 새 소비 프로젝트뿐이다 → bootstrap 보존 테스트로 기존 파일 불변을 확인한다.
- 평가 실행은 모델 비용이 든다 → CI에 넣지 않고 수동 실행으로 둔다. 실행 횟수는 조건당 1회로 제한한다.
- 안전성을 좌우하는 가정: ubuntu 러너에서 훅·bootstrap 테스트가 통과한다 → 확인 방법: Linux 컨테이너에서 두 러너 실행. 결과는 context.md에 기록한다.
