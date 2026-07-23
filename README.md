# init-project — Agentic 개발 스타터

AI 코딩 에이전트(Claude Code 등)와 함께 개발하는 프로젝트의 초기 환경 템플릿입니다.
TDD + Tidy First 워크플로우, 3레벨 문서 체계(docs / specs / context), 그리고 규칙을 런타임에 자동 집행하는 리마인더 훅을 제공합니다.

## 구조

```
AGENTS.md                # 공통 가이드 원본 (Single Source) — 모든 AI 에이전트용
CLAUDE.md                # Claude Code 전용 — AGENTS.md를 import + 전용 확장
docs/
├── ARCHITECTURE.md      # 시스템 구조 SSOT (프로젝트 시작 시 채우기)
├── CONVENTIONS.md       # 컨벤션 + 검증 명령어 (프로젝트 시작 시 채우기)
└── adr/                 # Architecture Decision Records
specs/
├── _templates/          # spec / plan / tasks / context / adr 표준 양식
├── _archive/            # 완료된 기능 문서 보관소
└── [feature-name]/      # 진행 중 기능의 작업 문서
.claude/
├── settings.json        # 훅 와이어링
├── hooks/               # 리마인더 훅 (bash + jq)
└── skills/              # /feature, /handoff 스킬 (선택적 커맨드)
```

## 시작하기

1. 이 저장소를 새 프로젝트로 복사(또는 clone 후 remote 변경)
2. `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`의 placeholder를 실제 내용으로 채우기
3. `jq` 설치 확인 (훅이 사용 — 대부분 시스템에 기본 포함)
4. Claude Code로 작업 시작 — 워크플로우는 `AGENTS.md`가 안내

## 훅 (자동 집행)

`.claude/settings.json`에 등록된 3개 훅이 규칙을 리마인더 방식으로 집행합니다 (차단 없음):

| 훅 | 동작 |
|---|---|
| SessionStart | 진행 중 기능의 `context.md` 안내 + 30일 초과 미갱신 알림 |
| PostToolUse (Edit/Write) | 코드 수정 후 tasks.md/context.md 동기화 리마인더 (30분 스로틀) |
| PostToolUse (Bash) | `git commit`에 코드만 있고 문서 갱신이 없으면 경고 |

## 스킬 (선택적 커맨드)

훅이 자동 집행하므로 평상시엔 일반 대화만으로 충분하고, 명시적 흐름이 필요할 때 사용합니다:

- `/feature [이름] [설명]` — 새 기능 시작: specs 문서 세트 생성 → 계획 수립 → 승인 대기
- `/handoff` — 세션 인수인계: 변경 마무리 → context.md/tasks.md 동기화 → 다음 시작점 기록

## 핵심 원칙

- **TDD**: Red → Green → Refactor, 테스트 없는 코드 금지
- **Tidy First**: 구조적 변경과 동작 변경을 커밋에서 분리
- **문서는 미래 세션의 메모리**: "무엇"이 아니라 "왜"를 기록
- **결정에는 재검토 조건**: 재검토 조건 없는 결정은 부패의 원인
