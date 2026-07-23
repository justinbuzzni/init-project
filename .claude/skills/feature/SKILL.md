---
name: feature
description: 새 기능 개발 시작 — specs/[feature]/ 문서 세트(spec→plan→tasks→context)를 템플릿에서 생성하고 계획 승인까지 진행. 사용자가 새 기능·큰 작업을 시작하려 할 때 사용. 인자는 기능 이름(kebab-case)과 한 줄 설명.
---

# /feature — 새 기능 시작

AGENTS.md §2.1~2.3 (Phase 1: Planning)의 실행판. 인자가 없으면 기능 이름과 목적부터 질문할 것.

## 절차

1. **기억 회수**: 메모리 레이어가 있으면 `mem-context-pack`(query=기능 주제)과 `mem-lesson-list`로 관련 과거 결정·시행착오·교훈을 회수해 계획에 반영한다 (AGENTS.md §2.8). 실패해도 작업은 계속한다.
2. **컨텍스트 로드**: `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`를 읽는다. 아직 placeholder 상태면 그 사실을 사용자에게 보고하고, 이번 기능에 필요한 최소 범위만이라도 함께 채울지 물어본다.
3. **중복 확인**: `specs/`(및 `specs/_archive/`)에 같은·유사 기능이 이미 있는지 확인. 있으면 새로 만들지 말고 기존 폴더의 문서를 갱신하는 쪽을 제안한다.
4. **폴더 생성**: `specs/[feature-name]/`을 만들고 `specs/_templates/`에서 `spec.md`, `plan.md`, `tasks.md`, `context.md`를 복사한다 (임의 양식 금지).
5. **spec.md 작성**: 사용자와 함께 목표(한 문장), 요구사항(Given/When/Then), **비목표(Non-Goals)**, 제약, 완료 기준을 확정한다. 가정하지 말고 불명확하면 질문. 여러 해석이 가능하면 선택지를 제시.
6. **아키텍처 영향 평가**: plan.md의 영향 표를 채운다. 새 모듈·외부 의존성·공개 API·스키마 변경이 있으면 `docs/adr/NNN-title.md` 초안까지 작성 (재검토 조건 필수).
7. **plan.md 작성**: 3~5개의 작은 Phase로 분리 — 각 Phase는 독립적으로 테스트·커밋 가능해야 한다. 기각한 대안을 한 줄씩 명시.
8. **tasks.md 작성**: 실행 순서 부여(① 의존성 → ② Tidy First → ③ 리스크/불확실성 → ④ 검증 가능성 → ⑤ 작은 것부터) + 순서 근거 한 줄.
9. **context.md 초기화**: 프론트매터를 채운다 — `기능: [feature-name]`, `상태: 진행중(Phase 1)`, `마지막 갱신: 오늘 날짜`.
10. **승인 대기**: 계획을 한 문단으로 요약 보고하고 승인을 기다린다. **승인 전 코드 작성 금지.** 승인은 tasks.md 전체 범위에 대한 실행 허가이므로, 승인 후에는 AGENTS.md §2.3 Phase 2의 연속 실행 규칙을 따른다.
