# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_6`
- commandPath: `.github/CODEX-IMPLEMENTATION-EXPLORATION-ENCOUNTER-HUD-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001`
- previousCommandStatus: `PASS`
- studioRuntimeState: `BLOCKED_UNTIL_UI_ALIGNMENT_AND_NEW_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

다음 한 Phase만 수행한다.

```text
Exploration·Encounter HUD
→ Preview · Turn · Reaction · Selection Continuity
```

Phase 4 Shared Shell·Preference Foundation과 Phase 5 Input·Context Action은 완료됐다.
이번 Phase는 기존 Shared Shell, Projection, World Direct Play, Exploration/Encounter Authority를 재사용해 실제 플레이 HUD와 Preview Presentation을 정합화한다.

## 현재 Authority

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ ADR-0088
→ ADR-0089 / ADR-0090 / ADR-0091
→ final-ui-content-implementation-contract.md
→ implementation-ready-ui-ux-and-settings-spec.md
→ implementation/roblox/CONTEXTUAL-POINTER-ACTIONS.md
→ Exploration / Encounter 관련 Architecture·System Guide·Slice Spec
→ EXECUTION-TEST-RULES.md
```

충돌 시 상위 Accepted ADR과 최신 Final UI Contract를 따른다.

## 이번 Phase의 고정 계약

### Exploration

- World와 HUD가 같은 semantic actor selection을 사용한다.
- 기본 행동을 클릭 전에 식별할 수 있다.
- 이동 path, distance, remaining movement, risk를 권위 Projection 범위에서 Preview한다.
- pending, approved, denied, stale, reconciliation을 구분한다.
- Client가 Movement Authority 결과를 새로 발명하지 않는다.

### Encounter

- Initiative, current turn, active actor와 주요 Action Economy 상태를 표시한다.
- End Turn과 Reaction 진입점은 서버 Projection을 따른다.
- Turn 전환은 HUD/World 강조와 soft notification을 사용한다.
- Turn 전환만으로 Camera를 강제 이동하지 않는다.

### Target / Area / Reaction

- 공개된 Range, valid target, area, affected target, cost를 Preview한다.
- hidden target, capability, opportunity는 노출하지 않는다.
- Reaction은 서버가 공개한 Opportunity가 있을 때만 표시한다.
- 실제 Movement, Attack, Reaction, Resource 변경은 기존 서버 Authority를 유지한다.

### Continuity

```text
move / attack / interaction
→ actor selection 유지

turn transition
→ active-turn presentation 갱신
→ 사용자 selection을 불필요하게 제거하지 않음
```

World, Action Table, HUD, Preview는 Revision mismatch를 감지하고 stale preview를 확정하지 않는다.

## 작업 경계

이번 Phase에서는 다음을 하지 않는다.

- Roblox Studio 또는 Human Playtest
- Phase 7 Inventory·Journal·Settings
- Phase 8 Entry·Role·Recovery
- Phase 9 DM Live Workspace
- Phase 10 Full Acceptance 완료 처리
- ADR-0092 Runtime 구현
- Persistence Runtime 확대
- Touch·Controller 전용 UI
- Player Minimap·별도 Map·Objective Tracker
- 서버 Gameplay Authority를 Client로 이동
- Hidden 정보의 placeholder 노출
- PR Ready 전환·승인·Merge

Studio Human Retest는 Phase 4~10 정합화와 새 current-HEAD Static Gate가 끝난 뒤에만 진행한다.

## 실행 절차

1. `commandPath`의 Phase 6 명령을 읽는다.
2. PR #2 최신 HEAD와 현재 Branch를 확인한다.
3. `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
4. Phase 5 `DONE`, Phase 6 `IN_PROGRESS`를 확인한다.
5. 기존 Shared UI/Input/Projection/World/Exploration/Encounter Source를 조사한다.
6. 같은 책임의 기존 모듈을 재사용한다.
7. Phase 6 범위만 구현한다.
8. Repository가 정의한 정적·자동 검증과 관련 HUD/Preview/Selection Test를 실행한다.
9. 성공한 경우에만 Phase 6을 `DONE`, Phase 7을 `IN_PROGRESS`로 갱신한다.
10. `AGENT-TEST-STATUS.md`를 실제 결과에 맞춰 갱신한다.
11. 변경을 현재 PR Branch에 반영한다.
12. 결과를 지정된 PR #2 Top-level Conversation Comment에 남긴다.
13. Studio Runtime/Human PASS를 주장하지 않는다.

## 결과 검수 기준

결과 댓글은 `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->` Marker를 사용하고 다음을 포함한다.

```text
commandId: RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_6
implementedScope: <concise list>
changedFiles: <paths>
testsRun: <commands/results>
staticValidationStatus: <status>
studioRuntimeStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 6/7 status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

PASS는 Phase 6 Source/Static 범위만 의미한다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인해`라고 지시하면 PR #2의 현재 HEAD, 최신 Phase 6 결과 Marker, 실제 changed files, tests, Work Order 상태를 대조한다. PASS면 Phase 6 완료 여부만 인정하고 Phase 7로 이어간다. Studio Runtime/Human PASS로 확대 해석하지 않는다.
