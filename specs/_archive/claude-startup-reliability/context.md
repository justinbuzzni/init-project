---
기능: claude-startup-reliability
상태: 완료
마지막 갱신: 2026-10-29
---

# Claude 시작 안정성 Context

## 현재 상태

사용자가 승인한 초기화 대기 분리·오류 진단 개선·시작 훅 최적화의 소스 구현과 관련 검증을 마쳤다. Happy 수정 위치는 작업공간 아래 `.aplus/worktrees/happy-claude-startup-fix`의 별도 체크아웃(기반 2cb0a4f70, CLI 1.1.10-aplus.367)이다. Happy 변경은 상위 저장소의 일반 diff에 나타나지 않으므로 `.aplus/verification/patches/happy-claude-startup-reliability.patch`로도 보존한다. 설치본·데몬·계정 설정은 변경하지 않았으며 운영 장애가 복구됐다고 검증한 것은 아니다.

## 판단

- 초기화만 60초, 이후 인증 제어는 10초로 유지한다. 재검토 조건은 SDK의 시작 훅 대기 계약이 바뀌는 경우다.
- 초기화·인증 제어 시간 초과 안내를 계정/정책 실패 안내와 분리했다. 진단에는 고정된 단계·사유·시간 및 검증된 CLI 버전만 담고 SDK 오류 원문과 설정·토큰은 담지 않는다.
- 훅의 프론트매터는 한 awk 프로세스로 읽고 같은 날짜 계산을 캐시한다. 날짜 파싱보다 먼저 현재 시각을 캐시하면 초 경계에서 경과 일수가 하루 줄 수 있어, 기존의 파싱 → 현재 시각 순서를 유지한다. 이를 고정 시계 회귀로 확인했다.
- 당시 어떤 실제 훅이 지연됐는지는 원 로그로 확정되지 않았다.

## 검증 결과

- 기존 Happy 소스로 새 회귀를 실행했을 때 8개 실패·26개 통과를 확인한 뒤 수정했다. 수정 후 관련 단위 테스트 35개 통과(느린 초기화·60초 제한·10초 제어 제한·초기화 중 취소·차단·안내·진단 비밀 비노출).
- 실제 SDK 0.3.308과 로컬 더미 HTTP/SSE 서버로 7개 통과. 개인/조직 모두 12초 SessionStart 훅 이후 약 12.35초에 요청이 완료됐고, 설정 출처·프로젝트 규칙·권한 제한 보존도 확인했다. Linux 전용 정책 통합 테스트 3개는 macOS에서 건너뛰었다. 실계정 토큰/외부 모델 요청은 사용하지 않았다.
- Happy `tsc --noEmit`, `pnpm run build` 통과. 빌드의 bin 경로/빈 chunk 경고는 남아 있으며 해당 영역은 변경하지 않았다.
- `bash tests/hooks/run.sh`, `bash tests/bootstrap/run.sh`, 두 저장소의 `git diff --check` 통과. 새 훅 프로세스 회귀는 awk 253 → 1회, date 164 → 6회. 날짜 파싱 경계 회귀도 통과했다.
- 실제 프로젝트 스냅샷의 기존 훅과 수정 훅을 각 3회 실행했다. 기존 8102/6981/6186ms → 수정 855/864/923ms(중앙값 약 8.1배 개선). 최종 stdout 72,319바이트가 완전히 동일했다. 동시에 전체 테스트를 실행 중인 로컬 측정이며 운영 성능 보장은 아니다.
- 추가 전체 단위 검증은 799개 파일 중 755개 통과·34개 실패·10개 건너뜀, 테스트 13,593개 통과·214개 실패·78개 건너뜀. 모든 변경 대상 테스트는 통과했다. 실패는 별도 launcher/managed/browser/도구 등의 영역에 남아 있으며 전체 통과로 표시하지 않는다. 대표 두 파일(`generationManifest`, `startHappyServer`)의 66개 실패는 변경 전 소스로도 재현했다. 나머지 실패 전부의 기준선 비교는 수행하지 않았다.
- 재현 설정과 결과 로그는 `.aplus/verification/diagnostics/`에 있다. 관련 단위 검증은 `vitest run --config .aplus/verification/diagnostics/auth-pin-tests.config.mjs --configLoader runner --no-cache`, 실제 SDK 검증은 같은 명령에 `HAPPY_CLAUDE_AUTH_PIN_INTEGRATION=1`을 추가한다. 실행 파일은 별도 Happy 체크아웃의 `packages/happy-cli/node_modules/.bin/vitest`다.

## 다음 시작점·승인 경계

- 2026-10-29 후속 리뷰: GNU date는 BSD 옵션 거절 뒤 GNU 형식으로 재시도하므로 성능 회귀의 date 호출 상한을 7 → 8회로 보정했다. 실제 gdate로 수정 전 실패(8회)를 재현했고, 수정 후 BSD/GNU date 각각으로 훅·bootstrap 전체 테스트가 통과했다. 첫 상태/날짜 필드 우선 및 빈 상태 제외 회귀도 보강했다.
- 이번 `claude-token-account-check`의 커밋·PR 대상은 init-project 훅·테스트·아키텍처 및 이 기능 문서뿐이다. 별도 Happy 소스·보존 패치와 `.aplus/`, `.ax/`, `.env`는 포함하지 않는다. 사용자의 후속 요청은 이 브랜치 push·PR 생성 및 명시된 검증 조건 충족 시 main 머지를 승인했으며, Happy 발행·설치 변경은 여전히 별도 범위다.

- 소스 리뷰 시 별도 Happy 체크아웃의 diff 또는 보존 패치를 사용한다. 로컬 의존성 링크는 검증용이며 패치에 포함하지 않는다.
- 설치본에 반영하려면 Happy의 공식 릴리스/설치 절차 및 해당 동작에 대한 별도 승인이 필요하다. Happy push·배포·데몬 재시작·계정 변경은 수행하지 않았다.
- 전체 테스트의 범위 밖 실패와 Linux 정책 통합 검증은 후속 환경에서 별도로 확인해야 한다. 이번 변경과 무관한 실패를 수정하지 않았다.
