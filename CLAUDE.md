# CLAUDE.md

> 공통 가이드는 **AGENTS.md가 유일한 원본**입니다. 규칙 수정은 AGENTS.md에서만 하세요 (여기에 복사 금지 — 드리프트의 원인).
> 이 파일은 Claude Code 전용 확장만 담습니다.

@AGENTS.md

## Claude Code 전용

- **훅**: `.claude/settings.json`에 등록된 리마인더 훅이 컨텍스트 로딩 안내·문서 동기화·커밋 drift 경고를 자동 처리한다 (AGENTS.md §2.7). 훅이 주입하는 `[ACTIVE FEATURES]`, `[SPEC SYNC]` 메시지는 이 가이드의 규칙을 상기시키는 것이므로 따를 것
- **훅 의존성**: bash + `jq`. 훅 수정 시 스크립트를 샘플 stdin JSON으로 직접 실행해 검증할 것
