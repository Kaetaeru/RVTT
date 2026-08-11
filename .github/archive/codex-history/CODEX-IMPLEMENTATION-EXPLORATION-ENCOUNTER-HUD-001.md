# RVTT Codex Implementation Command — Exploration·Encounter HUD 001

- commandId: `RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_6`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- previousCommand: `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001`
- previousCommandStatus: `PASS`
- expectedResultChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`

## 목적

`implementation/roblox/CURRENT-WORK-ORDER.md`의 현재 `IN_PROGRESS` 항목인 다음 한 Phase만 구현한다.

```text
Exploration·Encounter HUD
→ Preview · Turn · Reaction · Selection Continuity
```

Phase 4 Shared Shell·Preference Foundation과 Phase 5 Input·Context Action은 완료됐다. 이번 작업은 그 기반 위에 Exploration·Encounter의 실제 플레이 HUD와 Preview Presentation을 정합화한다.

이번 Phase는 Full UI·UX 정합화 전체를 끝내는 작업이 아니다. Inventory·Journal·Settings, Entry·Role·Recovery, DM Live Workspace, Full Acceptance Matrix, Studio Human Retest는 후속 Phase다.

## 시작 전 필수 확인

1. PR #2의 현재 원격 HEAD를 조회해 `targetShaAtStart`로 기록한다.
2. local checkout이 clean이면 plain `git fetch`와 branch checkout/switch로 `origin/agent/survival-logistics-token-authoring` 최신 HEAD에 맞춘다.
3. detached 또는 과거 checkout이라는 이유만으로 중단하지 않는다. clean checkout이면 최신 원격 Branch로 맞춘다.
4. 루트 `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 먼저 읽는다.
5. Phase 5가 `DONE`, Phase 6이 `IN_PROGRESS`인지 확인한다.
6. 아래 Authority와 기존 Source를 조사한다.
7. 기존 AppShell, ViewState, Theme, Projection, Input Context, World Action, World Token, Camera, Encounter/Exploration Domain과 테스트 Harness를 재사용한다.
8. 같은 책임의 HUD·Preview·Turn·Reaction 체계를 병렬로 새로 만들지 않는다.

예상치 못한 unrelated local 변경이 있으면 덮어쓰거나 삭제하지 말고 안전하게 중단한다.

## Authority

우선순위:

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ ADR-0088 direct-play pointer grammar and feedback continuity
→ ADR-0089 observer-first session and UI surface realignment
→ ADR-0090 action matrices and modular DM windows
→ ADR-0091 final UI/content implementation authority
→ final-ui-content-implementation-contract.md
→ implementation-ready-ui-ux-and-settings-spec.md (superseded 부분 주의)
→ implementation/roblox/CONTEXTUAL-POINTER-ACTIONS.md
→ Exploration / Encounter Architecture·System Guides·Slice Specs
→ EXECUTION-TEST-RULES.md
```

충돌 시 Accepted ADR과 최신 Final UI Contract가 과거 구현·문서를 대체한다.

## 기존 Source 재사용 원칙

먼저 Repository 전체에서 실제 책임 소유자를 찾는다. 특히 다음 기존 경계를 우선 조사·재사용한다.

```text
Shared UI
- AppShell / ShellContract / ViewState / DesignTokens / ThemeContract

Input / Selection / Projection
- SemanticInputRouter
- InputContextStack
- GameplayInputGuard
- ProjectionReplica

World Direct Play
- WorldActionMenu
- WorldContextActionResolver
- WorldTokenInputController
- WorldTokenRuntime
- WorldTokenRenderer
- WorldCameraController

Server Authority
- Exploration / Encounter / Movement / Rules Domain
- CommandRouter와 기존 authorize 경계

Tests
- 기존 Unit/Integration Harness
- InputContext.spec와 관련 Slice/Acceptance Scenario
```

파일명은 참고 경로다. 실제 현재 HEAD의 책임 구조가 다르면 현재 구조를 따르고 결과 댓글에 실제 재사용 경계를 기록한다.

## A. Exploration HUD

기존 Shared Shell과 World Direct Play 위에 Exploration 상태를 구성한다.

최소 계약:

- 현재 조작 Actor와 선택 상태가 World·HUD에서 같은 semantic selection을 사용한다.
- 좌클릭 기본 행동은 실행 전에 Cursor·Outline·Action Label 등으로 식별 가능하다.
- 이동 가능 지점 Hover/Preview에서 가능한 범위의 경로, 총 거리, 남은 이동량, 초과 구간과 위험 정보를 표현할 수 있다.
- Difficult Terrain, Door/Transition, Jump/Climb, 위험 구간 등 이미 Projection에서 제공되는 정보를 표시하되 Client가 규칙 결과를 발명하지 않는다.
- Pending 이동과 서버 승인·거부·Stale/Reconciliation을 구분한다.
- 일반 거부는 중앙 Modal이 아니라 Cursor·World Target·관련 HUD 근처의 viewer-safe 이유로 표시한다.
- Exploration에서 허용된 Token WASD와 Click 이동은 같은 Authority 이동 경계를 유지한다.

Preview 계산에 필요한 권위 값이 Projection에 없으면 Client가 추정 truth를 만들지 않는다. 기존 서버/Projection 계약을 사용하고, 이번 Phase 범위에서 필요한 최소 Projection 연결만 추가한다.

## B. Encounter HUD

기존 Encounter Authority를 Projection하여 다음을 표현한다.

- Initiative / Current Turn / Active Actor
- Action, Bonus Action, Reaction, Movement 등 현재 사용할 수 있는 주요 Turn Resource
- End Turn 진입점과 현재 실행 가능 여부
- 필요한 범위의 HP 0 / urgent state 진입점
- 현재 Turn이 바뀌었음을 알리는 Soft Notification

중요 경계:

```text
Turn change
→ HUD·World 강조 갱신
→ 필요하면 Soft Notification
→ Camera 강제 이동 금지
```

Client HUD는 Turn owner, resource amount, opportunity와 권한을 스스로 확정하지 않는다. 서버 Projection/Receipt가 원본이다.

Player에게 존재하지 않는 DM 전용 Action, 미인지 Actor, 숨은 Resource·Count·Opportunity를 placeholder나 disabled item으로 누출하지 않는다.

## C. Attack·Target·Area Preview

Phase 5의 Context Action 선택 흐름에 실제 Preview Presentation을 연결한다.

가능한 범위에서 다음을 지원한다.

- 공격/행동 이름과 현재 대상
- Range와 유효/무효 대상
- Area Shape와 영향 대상 Preview
- 비용, Action Economy, 제한 Resource
- Cover/Visibility/Advantage·Disadvantage 등 이미 권위 Projection이 공개하는 정보
- 실행 전 필요한 경우 `E` Confirm Context
- 불가능 사유의 viewer-safe 표시

미인지 대상과 비공개 Rule/Capability는 Preview에도 나타내지 않는다.

Preview는 Projection이다. 실제 Attack, Save, Damage, Resource Consumption과 Target Validation은 기존 서버 Domain authorize·Execution 경계를 계속 사용한다.

## D. Reaction Presentation

Reaction 자체의 발생 조건과 사용 가능 여부를 Client에서 새로 계산하지 않는다.

- 서버가 공개한 Reaction Opportunity/Capability가 있을 때만 HUD/Prompt를 만든다.
- 권한 밖 Opportunity는 존재 자체를 누출하지 않는다.
- 사용 가능한 Reaction과 현재 사용할 수 없는 Reaction을 Authority가 허용하는 범위에서 구분한다.
- Reaction 요청은 기존 Command/Execution 흐름을 사용한다.
- Pending·accepted·denied·expired·stale 상태를 구분한다.
- Reaction Prompt가 떠도 Selection·Camera·다른 권한 상태를 임의 변경하지 않는다.

## E. Selection·Focus Continuity

다음 연속성을 실제 Source에서 보장한다.

```text
move
→ selection 유지

attack
→ selection 유지

interaction
→ selection 유지

turn transition
→ semantic active actor 표시 갱신
→ 기존 사용자 selection을 Authority가 무효화하지 않는 한 불필요하게 제거하지 않음
```

Party/Initiative/World/Action Surface가 서로 다른 Client selection truth를 만들지 않는다.

Preview 종료, Theme 변경, Surface update와 Projection refresh 때문에 Keyboard Focus 또는 Actor Selection을 불필요하게 초기화하지 않는다.

## F. Projection Revision과 Feedback 상태

World, Action Table, HUD와 Preview가 같은 Authority Revision 계열을 추적하도록 한다.

최소 상태:

```text
ready
pending
partial
stale
permission_denied
network_error
validation_error
conflict
recovery
```

- Stale Revision에서 오래된 Preview를 확정하지 않는다.
- 서버 거부 후 optimistic 표시를 권위 Projection으로 복구한다.
- Pending을 성공처럼 표현하지 않는다.
- Viewer에게 공개되지 않는 이유/대상/수치를 Error Text로 누출하지 않는다.

## G. 테스트 가능성

가능한 ViewModel/Projection logic은 Roblox Instance와 분리된 순수 Module로 구성한다.

최소 자동 검증 대상:

1. Exploration/Encounter mode composition이 올바른 HUD state를 만든다.
2. Movement preview가 권위 Projection의 distance/cost/risk만 사용하고 임의 truth를 만들지 않는다.
3. Attack/Area preview가 hidden target을 노출하지 않는다.
4. Turn transition이 selection을 불필요하게 지우거나 Camera auto-frame state를 만들지 않는다.
5. Reaction은 projected opportunity 없이 나타나지 않는다.
6. Pending/Denied/Stale/Reconciliation state transition이 구분된다.
7. World/Action/HUD/Preview가 Revision mismatch를 감지한다.
8. move/attack/interact 후 selection continuity가 유지된다.
9. permission absent와 authorized-but-unavailable을 구분한다.
10. Client HUD/Preview 변경이 서버 권위 Gameplay State를 mutate하지 않는다.

기존 Harness와 테스트 패턴을 우선 재사용하고 필요한 최소 Unit/Integration Test를 추가한다.

## 금지 범위

이번 작업에서 하지 않는다.

- Roblox Studio 실행 또는 Human Playtest
- Codex Studio MCP 사용
- PR Ready 전환, 승인, Merge
- Phase 7 Inventory·Journal·Settings 완성
- Phase 8 Entry·Role·Recovery 구현
- Phase 9 DM Live Workspace 구현
- Phase 10 Full UI·UX Acceptance 완료 처리
- ADR-0092 Survival/Actor Runtime 구현
- Persistence Runtime/DataStore 범위 확대
- Touch·Controller 전용 UI 추가
- Player Minimap·별도 Map·Objective Tracker 재도입
- NPC Dialogue·Audio 관련 Surface 추가
- 서버 Turn·Reaction·Movement·Attack Authority를 Client로 이동
- Hidden Actor/Action/Resource/Count/Opportunity를 disabled placeholder로 노출
- Phase 12의 Human Visual/Accessibility Evidence를 완료했다고 표시
- Studio Runtime PASS 또는 Human UX PASS 주장

## 구현 품질

- 가능한 Production Luau에서 `--!strict`를 유지한다.
- 공개 API Type을 명시한다.
- Render loop Polling을 새로 남발하지 않는다.
- Projection/ViewModel Update는 event-driven과 revision-aware를 우선한다.
- Connection·Task·Instance lifetime을 정리한다.
- HUD Component가 Command/Domain Authority를 직접 소유하지 않게 한다.
- 기존 Theme/Preference/Shared Shell을 우회하는 별도 Style 체계를 만들지 않는다.
- 기존 Phase 5 Semantic Input을 우회하는 물리 입력 Handler를 만들지 않는다.
- 테스트용 Fake Authority를 Production Path에 남기지 않는다.

## 검증

구현 후 Repository가 정의한 가능한 모든 정적/자동 검증을 실제로 실행한다.

최소:

```text
python implementation/roblox/tooling/validate_implementation.py
StyLua --check
Selene
관련 Rojo project build
Production/Test sourcemap
Production/Test Luau type analysis
추가·수정한 Unit/Integration tests
```

Phase 6에서 영향받는 기존 Input·World·Encounter·Exploration Test도 가능한 범위에서 재실행한다.

도구 하나가 없으면 가능한 나머지를 먼저 실행하고 정확히 `PARTIAL` 또는 `BLOCKED`로 기록한다. 실행하지 않은 검증을 PASS로 표시하지 않는다.

Static 검증 성공은 Studio Runtime/Human UX PASS가 아니다.

## 상태 문서 갱신

실제 구현이 완료되고 필요한 정적 검증이 통과한 경우에만 다음을 갱신한다.

1. `implementation/roblox/CURRENT-WORK-ORDER.md`
   - Phase 6 `Exploration·Encounter HUD` → `DONE`
   - Phase 7 `Inventory·Journal·Settings` → `IN_PROGRESS`

2. `AGENT-TEST-STATUS.md`
   - Exploration·Encounter HUD → 실제 결과에 맞게 `PASS`
   - Inventory·Journal·Settings → `IN_PROGRESS`
   - Full UI·UX Source·Acceptance → 계속 `IN_PROGRESS`
   - Studio Human Retest → 계속 `BLOCKED`
   - 새 current-HEAD Static Gate가 Phase 4~10 이후 필요함을 유지

필수 계약 일부가 구현되지 않았거나 검증 실패가 있으면 Phase 7로 상태를 올리지 않는다.

## Git 작업

`gh` CLI를 구현 선행조건으로 요구하지 않는다.

- plain `git`으로 최신 PR Branch에 맞춘다.
- 범위에 필요한 파일만 수정한다.
- unrelated 변경을 되돌리지 않는다.
- 검증 후 명확한 commit을 만든다.
- 같은 Branch에 non-force push한다.
- Push 전 원격 HEAD가 예상치 못하게 이동했는지 확인한다.
- 외부 변경이 들어왔다면 안전한 최신화가 명확할 때만 진행하고, 그렇지 않으면 `ABORTED_STALE_HEAD`로 보고한다.
- Force push하지 않는다.
- Merge하지 않는다.

plain git 인증이 실패하더라도 구현과 로컬 검증을 먼저 수행할 수 있다면 수행한다. 사용 가능한 GitHub 연결로 동일 validated tree를 non-force 방식으로 게시할 수 있는 경우, 게시 전/후 tree 동일성을 검증하고 결과에 기록한다.

## 결과 댓글

완료 후 PR #2 Top-level Conversation Comment에 다음 Marker와 필드를 남긴다.

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_6
implementedScope: <concise list>
changedFiles: <paths>
testsRun: <commands/results>
staticValidationStatus: <PASS/FAIL/BLOCKED/PARTIAL>
pushStatus: <PASS/FAIL/BLOCKED/NOT_REQUIRED>
studioRuntimeStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 6/7 status after work>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <important limitations>
```

결과 게시 직전에 PR #2 원격 HEAD를 다시 확인한다.

PASS는 Phase 6 Source/Static 범위만 의미한다. Studio, Human UX, Multi-client, Persistence, Accessibility Evidence, Performance 또는 Release PASS를 주장하지 않는다.