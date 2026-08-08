# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_9`
- commandPath: `.github/CODEX-IMPLEMENTATION-DM-LIVE-WORKSPACE-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001`
- previousCommandStatus: `PASS_AFTER_CI_RECOVERY`
- phase8CiRecoveryCommand: `RVTT-PR2-PHASE8-CI-RECOVERY-001`
- phase8CiRecoveryStatus: `PASS`
- studioRuntimeState: `BLOCKED_UNTIL_PHASE10_AND_NEW_CURRENT_HEAD_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

다음 한 Phase만 수행한다.

```text
DM Live Workspace
→ modular window host
→ player-view-safe preview
→ authoritative override/control intents
→ projected queue/status
```

Phase 4~8 Source 정합화와 Phase 8 remote CI recovery는 완료됐다. 현재 Work Order의 Phase 9 `DM Live Workspace 정합화`만 구현한다.

## 핵심 Authority

```text
AGENTS.md
→ current PR / current remote HEAD
→ CURRENT-WORK-ORDER.md
→ AGENT-TEST-STATUS.md
→ ADR-0089
→ ADR-0090
→ ADR-0091 / final UI contract
→ ADR-0045 / ADR-0047
→ modular-dm-tool-window-contract.md
→ current Production Source / Tests
```

상위 계약에 따라 Player persistent UI에는 Minimap, 별도 Map, Objective Tracker를 추가하지 않는다.

## 현재 Source 경계

실행 시 최신 HEAD에서 반드시 재확인한다.

현재 `DmWorkspaceDomain`은 다음 DM-only server command를 가진다.

```text
dm.assign_control
dm.quick_action
dm.runtime_patch
dm.request_recovery
```

현재 Projection Policy는 `dm_workspace`를 DM에게만 보여 주고 Player/Observer에는 `{}`를 제공한다.

이 경계를 유지한다. UI 편의를 위해 임의 gameplay-authority command나 client-side mutation을 만들지 않는다.

## 이번 Phase의 고정 계약

### DM Window Host

- Top Authoring Strip은 launcher다.
- Left Inspector는 기본 dock일 뿐 고정 불변 패널이 아니다.
- 여러 Tool Window를 독립 instance로 열 수 있다.
- Move/Resize/Close/Focus/Dock 계열 layout은 local preference다.
- Tool끼리 내부 상태를 직접 변경하지 않는다.
- authoritative shared state는 Projection/Command 경계만 사용한다.
- Quick Action은 작은 context popover로 유지한다.

### Player View Preview

- DM이 선택한 participant/viewer가 실제 받을 viewer-scoped Projection을 Preview한다.
- DM full Projection을 client에서 가짜로 필터링하지 않는다.
- 기존 server projection policy를 재사용한다.
- Preview 때문에 실제 Player의 live projection sequence나 gameplay state를 변경하지 않는다.
- target role/assignment/revision 변화 시 stale/refresh/close 처리한다.
- target viewer가 볼 수 없는 private data/count/capability/DM workspace는 Preview에도 없어야 한다.

### Override / Control

기본 binding:

```text
control assignment → dm.assign_control
quick action       → dm.quick_action
runtime patch      → dm.runtime_patch
recovery request   → dm.request_recovery
```

- CommandClient + revision/epoch 경계를 통한다.
- stale 우회 금지.
- runtime_patch를 범용 client backdoor로 확장하지 않는다.
- pending/accepted/denied/stale/reconciled feedback은 기존 Phase 6~8 문법을 따른다.

### Queue / Status

- 실제 projected `quickActions`, `recoveryRequests`, `runtimePatches`, command receipt/pending source만 사용한다.
- table iteration order를 UI order로 쓰지 않는다.
- stable id + 실제 timestamp/revision으로 deterministic order를 만든다.
- optimistic local item을 authoritative row처럼 가장하지 않는다.
- refresh/reconnect 뒤 duplicate row를 만들지 않는다.
- hidden item/count를 추론하거나 placeholder로 누출하지 않는다.

### Permission / Recovery

- DM 권한 상실 시 sensitive DM projection을 즉시 purge한다.
- 관련 window는 close 또는 permission-safe surface가 된다.
- 한 window의 stale/dispose가 다른 window local state를 손상시키지 않는다.
- Phase 8 full-sync/epoch-change recovery를 재사용한다.

## 작업 경계

이번 Phase에서 하지 않는다.

- Phase 10 Acceptance 완료
- Studio / Studio MCP / Human Playtest
- 전체 Full Scene Editor 신규 구현
- 모든 역사적 DM panel 전면 구현
- ADR-0092 Runtime
- Persistence Runtime
- Performance/Soak
- Touch/Controller UI
- Player Minimap / 별도 Map / Objective Tracker
- Audio
- Client gameplay authority
- hidden/private placeholder
- test skip/assertion 약화/CI bypass
- PR Ready/Approve/Merge

## 실행 절차

1. `commandPath`를 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. Authority, Work Order, AGENT-TEST-STATUS를 확인한다.
4. Phase 8 `DONE`, Phase 9 `IN_PROGRESS`를 확인한다.
5. 현재 DM UI/AppShell/App.client/ViewModel/Projection/Command/Input/Preference/Domain/Test source를 조사한다.
6. 기존 책임과 중복되는 subsystem을 만들지 않는다.
7. DM-only modular workspace/window lifecycle을 구현 또는 정합화한다.
8. side-effect-free viewer-scoped Player View Preview를 구현하고 projection parity test를 추가한다.
9. 기존 DM command에 control/override intents를 연결한다.
10. projected queue/status와 reconciliation을 구현한다.
11. role loss/resync/stale cleanup과 negative disclosure test를 보강한다.
12. validator/formatter/lint/Rojo/Luau analysis와 관련 tests를 실행하고 UTF-8/diff 문제도 확인한다.
13. 성공한 경우에만 Phase 9를 `DONE`, Phase 10을 `IN_PROGRESS`로 갱신하고 AGENT-TEST-STATUS도 실제 결과에 맞춘다.
14. current PR branch에 non-force 반영한다.
15. push 후 새 current HEAD의 `Validate RVTT implementation` 및 관련 required workflow 결론을 실제 확인한다. 원격 CI failure가 있으면 PASS 금지.
16. 지정 Marker로 PR #2 top-level 결과 댓글을 남긴다.
17. Studio/Human PASS를 주장하지 않는다.

## 결과 검수 기준

결과 댓글은 최소 다음을 포함한다.

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_9
implementedScope: <concise list>
changedFiles: <count and/or paths>
playerViewPreviewBoundary: <server viewer-policy reuse / no live sequence mutation>
overrideCommandBindings: <actual existing commands>
queueProjectionBoundary: <actual sources/order/reconciliation>
negativeDisclosure: <DM vs Player/Observer>
testsRun: <commands/results>
staticValidationStatus: <status>
remoteCiStatus: <current-head workflow conclusions>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 9/10 status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

PASS는 Phase 9 Source/Static/CI 범위만 의미한다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 하면:

1. PR #2 current HEAD를 다시 조회한다.
2. 최신 Phase 9 `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->` 댓글을 찾는다.
3. `commandId`, `targetShaAtStart`, `resultHeadSha`를 대조한다.
4. 실제 commit/files와 Player Preview/Override/Queue/negative-disclosure 구현을 확인한다.
5. 새 HEAD의 related GitHub Actions를 직접 확인한다.
6. 모두 성공한 경우에만 Phase 9 최종 PASS를 인정한다.
7. PASS 후에만 Phase 10 Acceptance 확장으로 진행한다.
