# RVTT Codex Implementation Command — Input Context 001

- commandId: `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_5`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedResultChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`

## 목적

`implementation/roblox/CURRENT-WORK-ORDER.md`의 현재 `IN_PROGRESS` 항목인 다음 단계만 구현한다.

```text
Input·Context Action 정합화
→ Q · ESC · Left · Right · Middle · Availability
```

Phase 4 Shared Shell·Preference Foundation은 이미 완료된 기반이다. 이번 작업은 그 기반을 재작성하지 않고 기존 입력·월드 액션 Source를 ADR-0088의 직접 플레이 문법에 맞춘다.

이번 Phase에서 Full Exploration·Encounter HUD, 이동·공격·범위 Preview의 완성, Turn·Reaction HUD, Inventory·Journal·Settings 화면, Entry·Role·Recovery, DM Live Workspace, Full Acceptance Matrix, Studio Human Retest는 진행하지 않는다.

## 시작 전 필수 확인

1. PR #2의 현재 원격 HEAD를 조회하고 `targetShaAtStart`로 기록한다.
2. local checkout 상태를 확인한다.
3. Working Tree가 clean하면 plain `git`으로 `origin/agent/survival-logistics-token-authoring`을 fetch하고 최신 원격 Branch에 맞춘다.
4. local HEAD와 원격 PR HEAD가 일치하는지 확인한다.
5. 루트 `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
6. Phase 4가 `DONE`, Phase 5가 `IN_PROGRESS`인지 확인한다.
7. 아래 Authority와 기존 Source를 읽고 같은 책임의 기존 모듈을 재사용한다.
8. unrelated local/user 변경을 덮어쓰거나 되돌리지 않는다.

Detached 또는 과거 checkout 자체는 blocker가 아니다. Working Tree가 clean하면 최신 원격 Branch로 맞춘 뒤 진행한다.

`gh` CLI 설치 여부는 구현·검증 선행조건이 아니다. plain `git`과 사용 가능한 GitHub 연결을 사용한다.

## Authority

우선순위:

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ docs/remake/decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md
→ docs/remake/decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md
→ docs/remake/decisions/ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md
→ docs/remake/ui/common-input/common-input-grammar.md
→ docs/remake/ui/shared/final-ui-content-implementation-contract.md
→ implementation/roblox/CONTEXTUAL-POINTER-ACTIONS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ implementation/roblox/EXECUTION-TEST-RULES.md
```

충돌 시 Accepted ADR과 최신 상위 UI Authority를 따른다.

## 먼저 조사할 기존 Source

최소 다음을 실제로 읽고 책임 관계를 확인한다.

```text
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/InputContextStack.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/SemanticInputRouter.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/CameraController.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldActionMenu.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldCameraController.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldContextActionResolver.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenInputController.lua
implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/World/WorldTokenRuntime.lua
```

관련 Shared Input/Projection/Selection/Command 계약과 Test가 다른 위치에 있으면 함께 추적한다.

파일 이름을 보고 새 Parallel Router·Context Stack·Action Resolver를 만들지 않는다. 기존 책임을 확장·정렬한다.

## 목표 입력 계약

물리 입력은 Domain Command에 직접 결합하지 않는다.

```text
Physical Input
→ Semantic Action
→ Input Context
→ World/UI Intent
→ Server Validation
→ Receipt/Projection
```

### A. Left Click — PrimaryPointer

```text
선택 전
→ 조작 가능한 Actor 선택

선택 후
→ 클릭 전에 결정된 상황별 기본 행동 요청 또는 해당 행동의 다음 단계
```

기본 행동 우선순위는 결정적이어야 한다.

```text
조작 가능한 다른 아군 Actor
→ 선택 전환

적대 Actor + 활성 Encounter
→ 현재 기본 공격 또는 명시된 기본 전투 행동

우호·중립 Actor
→ 대화·도움·상호작용
→ 암묵적 공격 금지

Exploration Object
→ 상태 기반 기본 상호작용

이동 가능한 표면
→ movement 계열 기본 행동

유효 기본 행동 없음
→ 실행하지 않음
→ 현재 Viewer에게 공개 가능한 이유 제공
```

최근 사용 행동만으로 default action을 조용히 변경하지 않는다.

Phase 6의 Full Movement/Attack/Area Preview UI를 이번 Phase에서 완성하지 않는다. 다만 Phase 5 Resolver가 후속 Preview가 사용할 `intent/action availability/default action/reason` 계약을 명확히 제공해야 한다.

### B. Right Click — ContextActionPointer

오른쪽 클릭은 Camera Orbit이 아니다.

- 선택 Actor + 클릭 Target + Viewer Capability + Session Context 기준 Action Table을 열거나 교체한다.
- 다른 Target을 우클릭하면 기존 Table을 새 Target Context로 교체한다.
- Action Table이 열린 동안 World Left Click 기본 행동은 실행하지 않는다.
- Camera WASD, Wheel, Middle Drag Orbit은 유지한다.
- Q는 Action Table만 닫고 그 아래 Actor Selection까지 같이 없애지 않는다.

Action Table은 규칙 원본이 아니라 Projection이다. 실제 실행은 기존 Server Domain authorize를 그대로 통과해야 한다.

### C. Middle Drag — CameraOrbitPointer

```text
Middle Mouse Drag
→ Camera Yaw/Pitch Orbit
```

- Right Click과 충돌하지 않는다.
- 선택, 권한, Domain State를 변경하지 않는다.
- 기존 Camera 감각/상수는 상위 문서에 다른 결정이 없는 한 유지한다.
- TextBox Focus 중 Gameplay Camera 입력을 소비하지 않는다.

### D. Q — 최상위 Context 한 단계 Pop

Q는 한 번에 정확히 한 단계만 취소한다.

우선순위 예:

```text
Action Table 열림
→ Table만 닫음

Targeting/Preview 진행 중
→ 현재 단계만 취소

반복 Action Lock
→ 반복 고정만 해제

Actor만 선택됨
→ Actor 선택 해제

취소 Context 없음
→ No-op
```

한 번의 Q로 Menu + Targeting + Actor Selection을 연쇄 해제하지 않는다.

### E. E — 현재 Context Confirm

E는 현재 Context가 실제로 Confirm 가능한 경우에만 Preview·선택·승인·확정을 진행한다.

- 아무 Confirm Context가 없으면 Gameplay side effect를 만들지 않는다.
- Server authoritative command가 필요한 동작은 Client 성공으로 선반영하지 않는다.
- Resource-heavy/ambiguous Action의 세부 Preview UI는 Phase 6 범위로 남긴다.

### F. ESC — Gameplay No-op

ESC에 다음 Gameplay 의미를 두지 않는다.

- Actor Selection 해제
- Action Table 닫기
- Targeting/Preview 취소
- Repeat Action 해제
- Gameplay Confirm/Reject

Roblox/System/UI-level ESC 동작 자체를 억지로 탈취하라는 의미는 아니다. RVTT Gameplay Input Router가 ESC를 위 Gameplay 동작으로 해석하지 않게 한다.

## Action Availability 계약

Viewer Permission과 현재 Availability를 분리한다.

```text
권한 없음 또는 미인지
→ Action 자체를 Projection/Menu에 포함하지 않음

권한 있음 + 현재 불가능
→ Action은 포함
→ enabled = false 또는 동등한 명시적 상태
→ 실행 차단
→ Viewer-safe disabled reason 제공

권한 있음 + 현재 가능
→ enabled = true
```

대표 disabled reason:

- 현재 턴이 아님
- Action Opportunity를 이미 사용함
- Movement가 부족함
- Target이 Range 밖
- Line of Sight 없음
- 필요한 Resource 없음

권한 밖 Actor/Action/Hidden Object/DM-only Capability의 이름, Count, Placeholder, disabled reason을 누출하지 않는다.

Action 정렬은 가능한 한 안정적으로 유지한다.

```text
Default Action
→ Action
→ Bonus Action
→ Movement
→ Interaction
→ Information
→ 허용된 DM Action
```

정확한 Category/ID는 기존 Source와 Authority에 있는 Stable ID를 사용한다.

## Selection·Projection 경계

이번 Phase에서 다음을 보장한다.

- 조작 가능한 다른 아군 Left Click은 Targeting 공격보다 Selection 전환이 우선한다.
- Input Context는 Viewer Projection 밖 Capability를 새로 발명하지 않는다.
- Selection은 Client Presentation 상태일 수 있지만 Actor 소유권·Controller·Role을 변경하지 않는다.
- 동일 Projection Revision에서 Action Availability를 계산한다.
- Stale/Denied 결과가 오면 기존 권위 Projection으로 돌아갈 수 있는 구조를 유지한다.

행동 후 Selection 유지, Turn Soft Focus, Pending/Denied World Feedback의 완전한 Presentation Acceptance는 Phase 6에 이어서 구현한다. Phase 5에서 그 계약을 깨뜨리는 새 side effect를 만들지 않는다.

## 서버 권위 보존

기존 Server Command authorize를 우회하지 않는다.

대표 Command:

```text
rules.attack
exploration.interact
exploration.search
movement.commit
```

Client Action Resolver가 `enabled=true`를 계산해도 Server는 최종 권한·Turn·Opportunity·Resource·Range·Visibility·Target validity를 재검증한다.

Client가 Roll result, Damage, final position, Capability 또는 Ownership을 확정하지 않는다.

## 테스트 가능성

가능한 Resolver/Context Logic은 Roblox Instance와 분리된 순수 Module 또는 기존 Unit-testable 구조로 유지한다.

최소 자동 검증 대상:

1. Physical input → Semantic action mapping
   - Left = PrimaryPointer
   - Right = ContextActionPointer
   - Middle Drag = CameraOrbitPointer
   - Q = ContextBack/Cancel
   - E = ContextConfirm
   - ESC = no RVTT Gameplay action
2. Q가 top context 하나만 pop하고 연쇄 pop하지 않음
3. Action Table open 중 World PrimaryPointer 실행 차단
4. 다른 Target Right Click 시 Action Table Context 교체
5. Middle Drag와 Right Click이 서로 충돌하지 않음
6. controllable ally Left Click의 Selection 전환 우선순위
7. unauthorized/unperceived Action 미노출
8. authorized-but-unavailable Action은 disabled + reason
9. disabled Action 실행 차단
10. stable Action ordering
11. TextBox Focus 중 Gameplay input/camera 소비 금지
12. Client availability 계산이 Server authority state를 mutate하지 않음

기존 Test Harness와 Acceptance pattern을 우선 재사용한다.

## 금지 범위

이번 작업에서 하지 않는다.

- Roblox Studio 실행 또는 Human Playtest
- Codex Studio MCP 사용
- PR Ready 전환, 승인, Merge
- ADR-0092 Survival/Actor Runtime 구현
- Phase 4 Foundation 재설계
- Phase 6 Full Exploration·Encounter HUD 구현
- Full movement path/range/area/risk preview presentation 완성
- Turn/Reaction/Dice HUD 완성
- Phase 7 Inventory·Journal·Settings 화면 완성
- Phase 8 Entry·Role·Recovery 구현
- Phase 9 DM Live Workspace 구현
- Phase 10 Full Acceptance Matrix 완료 선언
- DataStore/Persistence Runtime 확대
- Content Rights가 막힌 Slices 13–15 구현
- Controller/Touch 전용 입력 추가
- ESC Gameplay binding 재도입
- Right Click Camera Orbit 재도입
- Encounter Token WASD 직접 이동 재도입
- Client authority 확장

## 구현 품질

- Production Luau는 가능한 파일에서 `--!strict`를 유지한다.
- 공개 API 타입을 명시한다.
- 기존 Semantic Input/Context Stack/Action Resolver를 재사용한다.
- 숨은 global과 module load-order 의존성을 만들지 않는다.
- Connection/Task lifetime을 명확히 정리한다.
- Render loop polling을 새로 추가하지 않는다.
- Stable ID와 Projection Revision을 사용한다.
- Test-only bypass를 Production path에 남기지 않는다.

## 검증

구현 후 Repository가 정의한 가능한 모든 정적/자동 검증을 실제로 실행한다.

최소:

```text
python implementation/roblox/tooling/validate_implementation.py
StyLua --check
Selene
관련 Rojo *.project.json build
Default/Test sourcemap
luau-lsp Production src analysis
luau-lsp Test analysis
추가·수정한 Input/Context Unit·Integration tests
```

Pinned toolchain과 기존 명령을 사용한다.

도구 하나가 없으면 가능한 나머지를 먼저 실행하고 누락 검증을 정확히 기록한다. 실행하지 않은 검증을 PASS로 표시하지 않는다.

Static PASS는 Studio Runtime PASS가 아니다.

## 상태 문서 갱신

실제 구현이 완료되고 필요한 정적 검증이 통과한 경우에만 다음을 갱신한다.

1. `implementation/roblox/CURRENT-WORK-ORDER.md`
   - Phase 5 `Input·Context Action 정합화`를 `DONE`
   - Phase 6 `Exploration·Encounter HUD`를 `IN_PROGRESS`

2. `AGENT-TEST-STATUS.md`
   - Input·Context Action 정합화를 실제 결과로 갱신
   - Exploration·Encounter HUD를 다음 구현 작업으로 갱신
   - Studio Human Retest는 계속 `BLOCKED`
   - Phase 4 Local Static PASS와 Historical Studio Evidence의 범위를 보존
   - Full UI·UX Phase 4~10 완료 후 새 current-HEAD Static Gate 필요 상태를 유지

완료 조건을 만족하지 못하면 Phase 6로 올리지 않는다.

## Git 작업

`gh` CLI를 요구하지 않는다.

- plain `git`으로 최신 remote PR branch에 맞춘다.
- 범위에 필요한 파일만 수정한다.
- unrelated 변경을 되돌리지 않는다.
- 검증 뒤 명확한 commit을 만든다.
- same branch에 non-force push한다.
- Push 전 remote branch가 `targetShaAtStart`에서 예상치 못하게 이동했는지 확인한다.
- 외부 commit이 들어왔다면 안전한 최신화가 명확할 때만 진행한다.
- 불명확한 stale head면 `ABORTED_STALE_HEAD`로 보고한다.
- Force push와 Merge를 하지 않는다.

Push/댓글만 실패했더라도 구현과 로컬 검증이 완료됐다면 결과를 버리지 말고 `PARTIAL`로 정확히 보고한다.

## 결과 댓글

완료 후 PR #2 Top-level Conversation Comment에 다음 Marker와 필드를 남긴다.

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_5
implementedScope: <concise list>
changedFiles: <paths>
testsRun: <commands/results>
staticValidationStatus: <PASS/FAIL/BLOCKED/PARTIAL>
pushStatus: <PASS/FAIL/BLOCKED/NOT_REQUIRED>
studioRuntimeStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 5/6 status after work>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <important limitations>
```

Result 게시 직전에 PR #2 원격 HEAD를 다시 확인한다.

자신이 push한 `resultHeadSha`와 원격 HEAD가 일치하면 정상 결과를 게시한다. 외부 commit 때문에 달라졌다면 그 사실을 숨기지 말고 stale 여부를 명시한다.

## 완료 판정

`PASS`는 다음이 모두 참일 때만 사용한다.

```text
Phase 5 범위 실제 Source 구현 완료
+ Q/ESC/Left/Right/Middle/Availability 계약 정합화
+ 관련 자동 테스트 추가/갱신
+ 필수 정적 검증 PASS
+ 상태 문서 실제 결과 반영
+ Commit/Push 완료
+ Result Head와 원격 PR Head 정합
```

Studio Runtime과 Human UI·UX는 이번 명령의 PASS 조건이 아니며 실행하지 않는다.