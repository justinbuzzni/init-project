---
기능: guideline-maintenance
상태: 완료
마지막 갱신: 2026-09-05
---

# 지침 운영 개선 Context

## 현재 상태

지침의 승인 경계를 정리하고 CML 2.4 교훈 회수 훅을 갱신했다.
Stop 훅은 `systemMessage`만 반환하여 턴을 연장하지 않으며, 네 훅의 등록·설명·테스트가 일치한다.
파일별 최초 지침 검토는 [plan.md](plan.md), 최종 실행 범위는 [tasks.md](tasks.md)에 있다.

## 핵심 결정 로그

- [2026-09-05] Stop 리마인드는 `systemMessage`로 사용자에게 표시 / 이유: `additionalContext`는 Stop 이벤트의 상태 안내 용도가 아니며 모델 턴을 이어갈 수 있음 / 기각: UserPromptSubmit으로 이동하면 리마인더 시점과 등록 범위가 바뀜 / 재검토 조건: Claude Code가 Stop 출력 계약을 변경할 때.
- [2026-09-05] CML SessionStart 명령을 실행하지 않고 절대 경로 토큰과 package.json만 읽음 / 이유: 훅 지연·부작용 없이 버전을 확인 / 기각: Node 프로세스 실행 / 재검토 조건: CML 설치 프로그램의 등록 형식이 변경될 때.
- [2026-09-05] 일반 작업의 최초 계획·Phase·세부 순서 재승인을 요구하지 않음 / 이유: 사용자가 추천안을 승인했고 내부 작업 단위의 반복 확인을 제거하기 위함 / 유지: 중요한 아키텍처·호환성·데이터·범위·권한 변경 승인 / 재검토 조건: 범위 판단 오류나 사용자가 중간 검토를 요구할 때.

## 시도했으나 실패한 접근

해당 없음.

## 발견된 문제 / 열린 질문

해당 없음.

## 다음 세션 시작점

기능은 완료됐다. 훅을 변경하면 `bash tests/hooks/run.sh`를 실행한다.
Linux 실행과 bootstrap 전체 배포 검증은 이번 완료 범위에 포함하지 않았다.

## 파일 맵

- `AGENTS.md` — 승인·자율 실행 정책 원본
- `.claude/hooks/` — SessionStart·PostToolUse·Stop 리마인더
- `.claude/settings.json` — 네 훅 등록
- `tests/hooks/` — 격리된 설정·스로틀·오류 경로 회귀 테스트
- `docs/CONVENTIONS.md` — 소비 프로젝트 명령과 스타터 검증 명령

## 검증·승인 상태

- 통과: `bash tests/hooks/run.sh` (Darwin). 버전 분기·공백 경로·설정/패키지 실패·이벤트 선택·완료 기능 제외·Stop 출력/스로틀/입력 실패·등록·셸 구문·JSON을 검사한다.
- 통과: 실제 머신의 CML 2.4.0 등록에서 활성 기능 없이 `mem-lesson-get` 안내 출력.
- 통과: 수정 문서 링크와 `git diff --check`.
- 승인 근거: 문서·스킬 정비, 자율 실행 추천안 적용, CML 훅 개선 및 외부 리뷰 수정에 대한 사용자 요청.
