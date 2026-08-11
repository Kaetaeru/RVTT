# RVTT Codex Implementation Command — Phase 9 DM Live Workspace

- commandId: `RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_9`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`

## 1. 목표

이번 한 Phase만 수행한다.

```text
DM Live Workspace
→ modular window host
→ player-view-safe preview
→ authoritative override/control intents
→ projected queue/status
```

Phase 8 Entry·Role·Recovery와 그 CI recovery는 완료됐다. 이번 Phase는 기존 DM Workspace Domain, Projection Policy, CommandClient, Shared Shell, Input Context, Preference 경계를 재사용해 Live DM 작업공간을 현재 확정 UI 계약에 맞춘다.

Phase 10 Acceptance 확장, Studio/Human Runtime, ADR-0092 Runtime은 시작하지 않는다.

## 2. 시작 전 Authority 순서

다음 순서로 읽고 충돌 시 위가 우선한다.

```text
AGENTS.md
→ 현재 PR #2 / 현재 remote HEAD
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ AGENT-TEST-STATUS.md
→ ADR-0089 observer-first session and UI surface realignment
→ ADR-0090 modular DM tool windows
→ ADR-0091 / final-ui-content-implementation-contract.md
→ ADR-0045 DM workspace
→ ADR-0047 contextual DM quick actions
→ modular-dm-tool-window-contract.md
→ 현재 Production Source / Tests
```

`implementation-ready-ui-ux-and-settings-spec.md`는 superseded된 부분을 권위로 사용하지 않는다.

## 3. 현재 Source 사실 — 반드시 먼저 재확인

명령 작성 시 확인된 현재 Source는 다음과 같다. Codex는 실행 시 최신 HEAD에서 다시 검사하고 이름이나 계약이 달라졌으면 최신 Source를 따른다.

### DmWorkspaceDomain

현재 `dm_workspace` Domain은 다음 상태를 가진다.

```text
control
quickActions
runtimePatches
recoveryRequests
```

현재 DM-only Command:

```text
dm.assign_control
dm.quick_action
dm.runtime_patch
dm.request_recovery
```

지원되지 않는 임의 `dm.*` Command를 UI 편의를 위해 꾸며내지 않는다. 새 권위 Command가 정말 필요하다고 판단되면 먼저 기존 Architecture/Domain 계약에 명시적으로 근거가 있는지 확인하며, 이번 Phase의 UI 정합화만으로는 새 gameplay authority를 만들지 않는다.

### Projection

현재 `DomainProjectionPolicy`는 `dm_workspace`를 DM에게만 전체 Projection하고 non-DM에게 `{}`로 차단한다.

```text
DM
→ authorized dm_workspace projection

Player / Observer
→ no DM workspace data
```

이 negative-disclosure 경계를 약화하지 않는다. Player/Observer에게 DM Tool 이름, private count, queue length, hidden actor, runtime patch, recovery request를 placeholder나 disabled control로도 보내지 않는다.

현재 `ProjectionBuilder:build(state, userId, role)`는 viewer 기준 Projection을 생성하지만 live `projectionSequence`를 증가시킨다. **Player View Preview를 만들기 위해 실제 Player의 live projection sequence를 소비하거나 변경하면 안 된다.** Preview는 기존 `DomainProjectionPolicy`를 재사용하는 side-effect-free viewer projection adapter/query 또는 동등하게 안전한 경계를 사용한다.

## 4. DM Workspace 화면 계약

### 4.1 Visibility

- DM role에서만 DM Workspace launcher/window surface를 표시한다.
- role/permission을 잃으면 sensitive projection을 즉시 폐기하고 관련 Window를 Close 또는 permission-safe surface로 전환한다.
- Player/Observer shell에는 DM Workspace의 빈 자리, badge, count, disabled button을 남기지 않는다.
- Phase 8 resync/role-change cleanup과 연결한다.

### 4.2 기본 Layout과 Window Host

ADR-0089의 기본 읽기 흐름을 유지한다.

```text
Top Authoring Strip
→ DM tool launcher

Left default dock
→ Selection Inspector

Center
→ live world
```

그러나 고정 단일 패널로 만들지 않는다. ADR-0090 / modular contract를 따른다.

공통 `DmWindowHost` 또는 Repository convention에 맞는 동등 구조가 다음을 담당한다.

- multiple window instances
- focus / z-order
- move / resize
- minimize / restore
- close
- dock / undock
- tab grouping이 현 Source 구조에서 합리적으로 구현 가능하면 지원
- stale / role / scene / permission lifecycle
- local layout serialization/reset
- Input Context Stack 연결

Window position/size/dock/tab/focus는 **local preference/presentation state**이며 Domain state가 아니다. 기존 preference/store 패턴을 재사용하고 campaign gameplay state에 저장하지 않는다.

최소한 Source 구조와 unit/static test에서 3개 이상의 독립 Window instance, singleton focus reuse, multiple-instance policy, 독립 dispose가 검증 가능해야 한다. Studio visual evidence는 이번 Phase에서 요구하지 않는다.

### 4.3 DmToolModule

Repository convention에 맞는 Registry/Module model을 사용한다. 개념 계약:

```text
moduleId
instanceId
toolKind/title
instancePolicy
projection scope
permission query
command bindings
window constraints
local view state
projection revision
pending commands
lifecycle
```

- Tool Module은 다른 Tool의 내부 상태를 직접 수정하지 않는다.
- 공유 authoritative state는 Projection/Command를 통해서만 전달한다.
- Quick Action은 `context_popover` 성격을 유지하고 자동으로 큰 Full Window가 되지 않는다.

## 5. Player View Preview

DM이 특정 participant/viewer가 **실제로 받을 수 있는 Projection**을 확인하는 Preview를 제공한다.

필수 조건:

1. Preview source는 server-authoritative current state + 기존 viewer projection policy다.
2. DM의 full projection을 client에서 임의로 필터링해 Player 화면처럼 보이게 하는 방식은 금지한다.
3. target viewer userId/role/assignment가 현재 authoritative session state와 맞는지 재검증한다.
4. Preview 생성은 gameplay state, live player projection sequence, pending command, selection authority를 변경하지 않는다.
5. Preview에는 target viewer에게 공개되지 않는 actor/item/journal/action/resource/count/DM workspace 정보가 없어야 한다.
6. Preview projection revision/authority epoch을 표시하거나 ViewModel이 추적해 stale 여부를 판단할 수 있어야 한다.
7. target viewer가 사라지거나 role/assignment/revision이 바뀌면 preview를 stale 처리하고 안전하게 refresh/close한다.

현재 Networking 구조에 안전한 non-mutating query/adapter가 없으면 최소한의 DM-only preview query boundary를 만들 수 있으나, 이것을 gameplay mutation Command처럼 취급하거나 일반 Player가 호출 가능하게 만들지 않는다.

## 6. Override / Control

이번 Phase의 `Override`는 임의 클라이언트 state mutation이 아니다.

기본적으로 현재 존재하는 서버 권위 경계를 사용한다.

```text
Control Assignment
→ dm.assign_control

Context Quick Action request
→ dm.quick_action

Runtime patch request
→ dm.runtime_patch

Recovery request
→ dm.request_recovery
```

UI Intent는 `CommandClient`와 현재 revision/authority epoch 경계를 통과한다.

- stale revision이면 실행을 우회하지 않는다.
- pending/accepted/denied/stale/reconciled 상태를 기존 Phase 6~8 feedback 문법과 일치시킨다.
- 위험한 action은 기존 confirmation policy/source가 있을 때만 confirmation surface를 사용한다.
- `runtime_patch`를 범용 백도어처럼 확장하지 않는다.
- Client가 actor controller, HP, fog, encounter, journal, recovery state를 직접 변경하지 않는다.

## 7. Queue / Status

`Queue`는 현재 authoritative/projection source가 실제로 제공하는 작업만 보여준다.

현재 `dm_workspace`의 `quickActions`, `recoveryRequests`, `runtimePatches`와 Command receipt/pending state를 조사해 ViewModel을 구성한다.

- map/table iteration 순서를 UI order로 사용하지 않는다.
- stable id + createdAt/revision 등 실제 field를 사용해 deterministic ordering을 만든다.
- 존재하지 않는 hidden queue item/count를 추론하지 않는다.
- local optimistic row는 authoritative row처럼 표시하지 않는다.
- accepted-awaiting-reconciliation과 projection-confirmed state를 구분한다.
- stale/denied/expired row는 viewer-safe reason만 표시한다.
- Projection refresh/reconnect 후 중복 row를 만들지 않는다.

Queue가 현재 Domain에서 의미하는 것보다 더 큰 workflow engine을 새로 만들지 않는다.

## 8. Selection / Camera / Input

- DM Window focus와 world Actor selection을 동일 상태로 합치지 않는다.
- Tool Window를 열고 닫아도 유효한 world selection과 camera position을 불필요하게 초기화하지 않는다.
- Q는 Focus된 Window/Input Context의 최상위 한 단계만 닫는다. 여러 Window나 world selection을 연쇄적으로 지우지 않는다.
- E/Left/Right/Middle/ESC의 ADR-0088 의미를 깨지 않는다.
- Window interaction 중 gameplay input leakage를 기존 Input Context Stack으로 막는다.
- Turn/Projection 변화가 DM camera를 강제 recenter하지 않는다.

## 9. Stale / Recovery / Permission

Phase 8 경계를 재사용한다.

```text
role 유지 + revision 갱신
→ refresh

context/entity 제거
→ safe empty / close

DM permission 상실
→ sensitive state purge
→ DM window close / safe surface

full sync / epoch change
→ stale local pending invalidation
→ authoritative rebuild
```

한 Window가 stale/dispose되어도 다른 Window의 local view/layout state를 손상시키지 않는다.

## 10. 명시적 제외

이번 Phase에서 하지 않는다.

- Phase 10 Full UI·UX Acceptance 확장 완료
- Roblox Studio / Studio MCP / Human Playtest
- Grand Persistence Runtime
- Performance/Soak
- ADR-0092 survival logistics runtime
- ADR-0092 actor authoring runtime
- 전체 Full Scene Editor 또는 asset authoring suite 신규 구현
- 모든 역사적 DM panel을 한 번에 완성
- Player Minimap
- 별도 Player Map
- Objective Tracker
- Touch/Controller 전용 UI
- Audio
- Client gameplay authority
- hidden/private placeholder
- test 삭제/skip/assertion 약화/CI bypass
- PR Ready / Approve / Merge

## 11. 구현 절차

1. 시작 즉시 PR #2 remote HEAD를 기록한다.
2. Active Task와 이 command를 읽은 뒤 Authority/Work Order/Test Status를 확인한다.
3. Phase 8 `DONE`, Phase 9 `IN_PROGRESS`를 확인한다.
4. 현재 DM UI, AppShell/App.client, ViewModel, ProjectionReplica, CommandClient, InputContextStack, PreferenceStore, Session/DM domains와 tests를 조사한다.
5. 기존 책임과 중복되는 새 subsystem을 만들지 않는다.
6. DM-only workspace host/module lifecycle을 구현 또는 현재 구조에 정합화한다.
7. side-effect-free player-view preview 경계를 구현하고 projection-policy parity test를 추가한다.
8. 기존 DM command를 사용해 control/override intents를 연결한다.
9. 실제 projected queue/status를 deterministic하게 표현하고 reconciliation을 연결한다.
10. role loss/resync/stale cleanup과 negative disclosure test를 보강한다.
11. Repository가 정의한 validator/formatter/lint/Rojo/Luau analysis 및 관련 tests를 실행한다.
12. 변경 파일의 UTF-8/format 문제를 확인하고 `git diff --check` 또는 동등 검사를 포함한다.
13. 모두 PASS한 경우에만 `CURRENT-WORK-ORDER.md`를 Phase 9 `DONE`, Phase 10 `IN_PROGRESS`로 갱신하고 `AGENT-TEST-STATUS.md`를 실제 결과에 맞춘다.
14. 현재 PR branch에 non-force 반영한다.
15. push 후 **새 current HEAD의 `Validate RVTT implementation`과 관련 required workflow 결론을 확인한다. 원격 CI가 failure면 PASS로 보고하지 않는다.**
16. 지정 result marker로 PR #2 top-level 결과 댓글을 남긴다.

PR HEAD가 작업 중 예상치 않게 다른 작업으로 이동하여 안전한 통합이 불가능하면 force push/overwrite하지 말고 `ABORTED_STALE_HEAD` 또는 `BLOCKED`로 보고한다.

## 12. 검증 요구

최소 정적/자동 검증 범위:

- DM-only workspace visibility
- Player/Observer negative disclosure
- independent multiple window instances / singleton reuse
- local layout state vs authoritative domain state separation
- Quick Action popover boundary
- player-view preview projection parity
- preview no live sequence/state mutation
- target role/assignment stale handling
- existing DM command intent routing
- queue deterministic ordering/dedup/reconciliation
- role loss / full-sync private-state purge
- Input Context one-level Q behavior where affected
- implementation validator
- formatter/lint
- all required Rojo builds
- production/test Luau analysis
- current HEAD GitHub Actions

## 13. 성공 시 상태

```text
Phase 9 DM Live Workspace → DONE
Phase 10 Acceptance 확장 → IN_PROGRESS
Studio Human Retest → 계속 BLOCKED
new current-HEAD Static Gate → Phase 10 뒤 별도 실행
```

Phase 9 PASS는 Source/Static/CI 범위만 의미한다. Studio Runtime, Human UX, Accessibility, Multi-client, Persistence, Performance, Release PASS를 의미하지 않는다.

## 14. 결과 댓글 형식

최소 다음 필드를 포함한다.

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_9
implementedScope: <concise list>
changedFiles: <count and/or paths>
playerViewPreviewBoundary: <how same viewer policy is reused without live sequence mutation>
overrideCommandBindings: <actual commands used>
queueProjectionBoundary: <actual sources/order/reconciliation>
negativeDisclosure: <DM vs Player/Observer evidence>
testsRun: <commands/results>
staticValidationStatus: <status>
remoteCiStatus: <actual current-head workflow conclusions>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 9/10 status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

## 15. 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```
