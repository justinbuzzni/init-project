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
4. 메모리 레이어 설치 (선택이지만 강력 권장 — 학습 루프의 기반):
   ```bash
   npm install -g claude-memory-layer@latest
   claude-memory-layer install   # 최초 1회, Claude Code 훅 등록 (자동 대화 축적)
   claude-memory-layer import    # 프로젝트 디렉토리에서 — 기존 세션이 있다면 적재
   ```
   MCP 서버는 `.mcp.json`에 이미 등록되어 있어 별도 설정이 필요 없습니다.
5. Claude Code로 작업 시작 — 워크플로우는 `AGENTS.md`가 안내

## 학습 루프 (사용할수록 똑똑해지는 구조)

[claude-memory-layer](https://www.npmjs.com/package/claude-memory-layer)를 기반으로, 에이전트가 경험에서 배우고 스스로 개선하는 3단 루프를 워크플로우에 내장했습니다 (AGENTS.md §2.8):

```
① 회수(Recall)    작업 시작 시 mem-context-pack·mem-search로 과거 맥락과 교훈 확인
② 축적(Capture)   원시 대화는 자동 저장 + 시행착오의 교훈은 mem-lesson-save로 명시 자산화
③ 승격(Promote)   반복 적용된 교훈 → docs/CONVENTIONS.md 규칙 또는 .claude/skills/ 스킬로 승격
```

문서 체계(`docs/`, `specs/`)는 사람이 리뷰하는 공식 기록, 메모리 레이어는 검색 가능한 경험 자산 — 두 층이 상호보완합니다. `/learn` 스킬이 회고와 승격 검토를 수행합니다.

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
