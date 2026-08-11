# RVTT Codex Implementation Command — UI Foundation 002

- commandId: `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_4`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- supersedesExecutionAttempt: `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-001`
- expectedResultChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`

## 이전 BLOCKED 처리

이 명령은 이전 `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-001`의 구현 재시도다.

이전 시도는 Source 구현 전에 `gh` CLI 필수 조건 때문에 `BLOCKED`됐고 실제 구현 파일은 변경되지 않았다.

이번 명령에서는 다음을 명시적으로 적용한다.

```text
`gh` CLI 설치 여부
≠ 구현 시작 조건
≠ 정적 검증 시작 조건
≠ plain git commit/push 조건
```

- `gh`가 없어도 작업을 중단하지 않는다.
- 저장소 동기화, commit, push에는 사용 가능한 plain `git`을 우선 사용한다.
- PR 결과 댓글은 Codex 환경에 이미 제공되는 GitHub 연결/도구가 있으면 그것을 사용한다.
- `gh`가 없다는 이유만으로 `BLOCKED`를 반환하지 않는다.
- 실제 `git fetch/push` 인증이나 GitHub 결과 댓글 게시 자체가 불가능한 경우에만 그 단계의 실제 blocker를 기록한다.
- Push/댓글 단계가 막히더라도 구현과 로컬 정적 검증을 이미 수행할 수 있다면 먼저 수행하고 `PARTIAL`로 정확히 보고한다. 구현 가능한 작업을 publish 사전조건 때문에 선제적으로 포기하지 않는다.

## 목적

`implementation/roblox/CURRENT-WORK-ORDER.md`의 현재 `IN_PROGRESS` 항목인 다음 단계만 구현한다.

```text
Shared Shell·Preference Foundation
→ Layer·Mode·System·Theme·Settings Store
```

이 작업은 Full UI·UX 정합화 전체를 한 번에 끝내는 작업이 아니다.
다음 Phase인 Input·Context Action, Exploration·Encounter HUD, Inventory·Journal·Settings 화면 완성, Entry·Role·Recovery, DM Live Workspace, Acceptance 확장, Studio Human Retest는 이번 범위에서 진행하지 않는다.

## 시작 전 필수 확인

1. PR #2의 현재 원격 HEAD를 조회하고 `targetShaAtStart`로 기록한다.
2. local checkout 상태를 확인한다.
3. Working Tree가 clean하면 plain `git`으로 `origin/agent/survival-logistics-token-authoring`을 fetch하고 그 최신 HEAD에 checkout/switch한다.
4. local HEAD가 원격 PR HEAD와 일치하는지 확인한다.
5. Working Tree가 clean한지 다시 확인한다.
6. 루트 `AGENTS.md`와 `AGENT-TEST-STATUS.md`를 읽는다.
7. `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽고 Phase 4가 실제로 `IN_PROGRESS`인지 확인한다.
8. 아래 Authority를 순서대로 읽고, 상위 문서가 하위 문서를 supersede한 부분을 반드시 지킨다.

로컬 checkout이 detached/과거 SHA인 것 자체는 blocker가 아니다. Working Tree가 clean하면 원격 branch를 fetch해 최신 PR HEAD에 맞춘 뒤 진행한다.

예상치 못한 unrelated local 변경이 있으면 덮어쓰거나 삭제하지 말고 그때만 안전하게 중단한다.

## Authority

우선순위:

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ docs/remake/decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md
→ docs/remake/ui/shared/final-ui-content-implementation-contract.md
→ docs/remake/decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md
→ docs/remake/decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md
→ docs/remake/decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md
→ docs/remake/ui/shared/implementation-ready-ui-ux-and-settings-spec.md
→ docs/remake/audits/final-ui-surface-gap-audit.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ implementation/roblox/EXECUTION-TEST-RULES.md
```

`implementation-ready-ui-ux-and-settings-spec.md`는 일부가 ADR-0091과 `final-ui-content-implementation-contract.md`에 의해 대체됐으므로 충돌 시 새 Authority를 따른다.

## 구현 원칙

먼저 기존 Source를 검색해서 같은 책임의 모듈, UI Root, Theme, Preference/Settings 상태, Projection, Controller를 재사용한다.
파일명이나 모듈 위치를 추측해 중복 체계를 만들지 않는다.

### A. Shared Shell Foundation

현재 Source와 Authority가 요구하는 공통 Shell을 실제 Runtime Source에 연결한다.

최소 책임:

- 공통 UI Root/Layers의 명확한 소유권
- Gameplay/Management/Session/DM Surface가 공통 Shell 위에서 구성될 수 있는 기반
- Mode/Role 상태 표시 기반
- System Entry와 공통 Overlay/Prompt/Toast/Tooltip/Recovery Layer가 서로 z-order/ownership 충돌 없이 공존할 기반
- Selection/Focus를 불필요하게 파괴하지 않는 Surface 전환 기반
- `loading`, `empty`, `ready`, `pending`, `partial`, `stale`, `permission_denied`, `network_error`, `validation_error`, `conflict`, `recovery` 상태를 blank panel이나 spinner-only로 숨기지 않을 수 있는 공통 상태 계약

후속 화면의 모든 세부 UI까지 만들지 않는다. 공통 Shell 계약과 후속 Phase가 붙을 안정적인 확장 지점만 완성한다.

### B. Mode·Role Foundation

기존 Authority/Projection을 사용해 Mode와 Role을 임의의 Client truth로 만들지 않는다.

- Player / DM / Observer 등 권한 표시가 실제 Projection/Authority 경계와 연결될 수 있는 구조
- Exploration / Encounter 등 Mode가 후속 HUD를 구성할 수 있는 구조
- Client가 권한이나 게임 상태를 독자적으로 확정하지 않음
- 권한 밖 정보의 Count/placeholder/hidden surface를 새 Foundation에서 누출하지 않음

### C. Theme Foundation

기존 UI Style/Token이 있으면 재사용한다. 새 전역 Theme 시스템을 중복 생성하지 않는다.

- Accent, UI scale, text scale, motion 등 후속 Settings가 공통 UI에 적용될 수 있는 명시적 계약
- Semantic Success/Warning/Danger/Disabled 상태를 임의 색상 문자열로 분산하지 않음
- Focus/Selection 상태를 Theme 변경 때문에 초기화하지 않음

정확한 값과 허용 범위는 Authority와 기존 Source에서 가져온다. 문서에 없는 값을 새로 확정하지 않는다.

### D. Preference / Settings Store Foundation

기존 Preference/Settings Source가 있으면 확장한다. 없으면 가장 작은 명시적 Store를 만든다.

필수 속성:

- 기본값이 한 곳에서 정의됨
- 입력 검증/정규화가 명확함
- 알 수 없는 Key를 조용히 영구 상태로 받아들이지 않음
- UI Scale/Text Scale/Accent/Motion/Binding 등 Preference 종류를 후속 화면이 안정적으로 읽을 수 있는 API
- 설정 변경 중 Focus/Selection을 불필요하게 잃지 않도록 Presentation과 상태를 분리
- Client-only presentation preference와 서버 권위 gameplay state를 혼동하지 않음
- Persistence가 별도 계약이면 이번 Phase에서 임의 DataStore 저장을 추가하지 않음

정확한 Settings 목록, 기본값, 범위, Reset semantics는 Authority와 기존 Source에서 추출한다. `Audio Mixer`, 공개 Player Map/Minimap 등 최종 Release 범위에서 제외된 Surface를 placeholder로 추가하지 않는다.

### E. 테스트 가능성

가능한 로직은 Roblox Instance와 분리된 순수 함수/모듈로 구성해 자동 테스트가 가능하게 한다.

최소 자동 검증 대상:

- Preference default resolution
- known/unknown setting validation
- 값 normalize/clamp 또는 enum validation
- reset/default behavior
- Mode/Role mapping에서 권한을 새로 발명하지 않는지
- Theme/Preference 변경이 기존 game authority state를 mutate하지 않는지

기존 테스트 Harness와 패턴을 우선 재사용한다.

## 금지 범위

이번 작업에서 하지 않는다.

- Roblox Studio 실행 또는 Human Playtest
- Codex Studio MCP 사용
- PR Ready 전환, 승인, Merge
- ADR-0092 Survival/Actor Runtime 구현 시작
- Input·Context Action Phase 5 구현
- Exploration·Encounter HUD Phase 6 구현
- Inventory/Journal/Settings 완성 Phase 7 구현
- Entry/Role/Recovery Phase 8 구현
- DM Live Workspace Phase 9 구현
- Full Acceptance Matrix Phase 10을 완료한 것처럼 표시
- Persistence Runtime/DataStore 구현 확대
- Content Rights가 막힌 Slices 13–15 구현
- 문서에 없는 UX 결정을 임의 확정
- 기존 서버 Authority를 Client 상태로 이동

## 구현 품질

- Production Luau는 가능한 파일에서 `--!strict`를 유지한다.
- 공개 API 타입을 명시한다.
- 숨은 global과 모듈 load order 의존성을 만들지 않는다.
- 이벤트/Connection/Task lifetime을 명확히 정리한다.
- Render loop에서 불필요한 polling을 추가하지 않는다.
- 후속 Phase가 Foundation을 재사용할 수 있게 책임을 작게 분리한다.
- 테스트용 우회 로직을 Production path에 남기지 않는다.

## 검증

구현 후 가능한 모든 정적/자동 검증을 실제로 실행한다.

최소:

```text
python implementation/roblox/tooling/validate_implementation.py
StyLua check
Selene lint
관련 Rojo project build
Production/Test Luau type analysis
추가·수정한 Unit/Integration tests
```

Repository가 정의한 pinned toolchain과 기존 명령을 사용한다.
도구 하나가 없으면 가능한 나머지 검증을 먼저 수행하고, 누락 검증을 정확히 `BLOCKED`/`PARTIAL`로 기록한다.
실행하지 않은 검증을 PASS로 표시하지 않는다.

Static 검증 성공은 Studio Runtime PASS가 아니다.

## 상태 문서 갱신

실제 구현이 완료되고 필요한 정적 검증이 통과한 경우에만 다음을 갱신한다.

1. `implementation/roblox/CURRENT-WORK-ORDER.md`
   - Phase 4 `Shared Shell·Preference Foundation`을 `DONE`으로 변경
   - Phase 5 `Input·Context Action 정합화`를 `IN_PROGRESS`로 변경
   - 실제 완료 조건과 맞지 않으면 상태를 올리지 않는다.

2. `AGENT-TEST-STATUS.md`
   - Shared Shell·Preference Foundation 상태를 실제 결과로 갱신
   - Studio Human Retest는 계속 `BLOCKED`로 유지
   - 다음 구현 작업을 Input·Context Action 정합화로 변경
   - 새 코드 변경 후 Studio 전에 새 current-HEAD Static Gate가 필요함을 유지

## Git 작업

`gh` CLI를 요구하지 않는다.

- plain `git`으로 원격 branch를 fetch하고 current PR HEAD에 맞춘다.
- 범위에 필요한 파일만 수정한다.
- unrelated user changes를 되돌리지 않는다.
- 검증 후 변경을 명확한 commit으로 만든다.
- plain `git push origin HEAD:agent/survival-logistics-token-authoring` 또는 동등한 안전한 non-force push를 사용한다.
- Push 전 원격 branch가 `targetShaAtStart`에서 예상치 못하게 이동했는지 확인한다.
- 외부 commit이 들어왔다면 fetch/rebase 또는 안전한 최신화가 명확할 때만 진행하고, 불명확하면 `ABORTED_STALE_HEAD`로 보고한다.
- Force push하지 않는다.
- Merge하지 않는다.

Push 인증이 실제로 실패하면 구현과 로컬 검증 결과를 버리지 말고 `PARTIAL`로 보고하며 정확한 인증 오류를 남긴다.

## 결과 댓글

완료 후 PR #2 Top-level Conversation Comment에 다음 Marker와 필드를 남긴다.

`gh`가 없어도 Codex 환경의 사용 가능한 GitHub 연결/도구로 게시한다. `gh` 부재 자체는 blocker가 아니다.

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_4
implementedScope: <concise list>
changedFiles: <paths>
testsRun: <commands/results>
staticValidationStatus: <PASS/FAIL/BLOCKED/PARTIAL>
pushStatus: <PASS/FAIL/BLOCKED/NOT_REQUIRED>
studioRuntimeStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 4/5 status after work>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <important limitations>
```

Result 게시 직전에 PR #2 원격 HEAD를 다시 확인한다.
자신이 push한 `resultHeadSha`와 일치하면 정상 결과를 게시한다.
외부에서 예상하지 못한 새 commit이 들어와 작업 기준이 불명확해졌으면 덮어쓰지 말고 `ABORTED_STALE_HEAD`로 보고한다.

결과 댓글 게시 도구 자체가 최종 단계에서 unavailable이면 구현/검증/Push를 되돌리지 않는다. 가능한 채널에 결과 본문을 출력하고 `resultCommentStatus: BLOCKED`를 명시한다.

## 완료 의미

`PASS`는 **Shared Shell·Preference Foundation Phase 4 구현과 그 정적 검증만 완료**됐다는 뜻이다.

다음을 의미하지 않는다.

```text
Full UI·UX 전체 구현 완료
Studio Runtime PASS
Human UX PASS
Multi-client PASS
Persistence PASS
Accessibility PASS
Performance PASS
Release Ready
```
