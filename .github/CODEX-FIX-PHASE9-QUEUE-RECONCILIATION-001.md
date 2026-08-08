# RVTT Codex Fix Command — Phase 9 Queue / Receipt Reconciliation

- commandId: `RVTT-PR2-PHASE9-QUEUE-RECONCILIATION-001`
- taskType: `IMPLEMENTATION_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_9_RECONCILIATION_FIX`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_PHASE9_FIX_RESULT -->`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`

## 1. 목표

Phase 9 DM Live Workspace의 새 기능 범위를 넓히지 않는다.

ChatGPT 검수에서 확인된 **Queue / Receipt reconciliation 결함만 최소 수정**한다.

```text
Phase 9 current implementation
→ recovery pending/projection duplicate 가능
→ control assignment accepted 상태가 projection-confirmed로 닫히지 않음
→ denied/stale/timeout terminal receipt가 즉시 사라짐
→ focused tests가 이 경계를 충분히 검증하지 않음
```

이 결함을 닫은 뒤에만 Phase 9를 최종 PASS로 인정하고 Phase 10 Acceptance 확장으로 진행할 수 있다.

## 2. 시작 전 Authority

다음 순서를 읽고 현재 remote HEAD를 다시 확인한다.

```text
AGENTS.md
→ current PR #2 / current remote HEAD
→ 이 fix command / CODEX-ACTIVE-TASK.md
→ accepted ADR-0088 / ADR-0089 / ADR-0090 / ADR-0091
→ modular-dm-tool-window-contract.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ AGENT-TEST-STATUS.md
→ current Phase 9 source/tests
```

주의: 현재 `CURRENT-WORK-ORDER.md`와 `AGENT-TEST-STATUS.md`는 Phase 9를 PASS/DONE으로 표시할 수 있으나, ChatGPT의 post-implementation verification에서 아래 reconciliation defect가 확인되어 **Phase 9 final approval은 HOLD**다. 이번 명령은 그 상태를 정정하고 결함을 수정하기 위한 explicit follow-up이다.

## 3. 검수에서 확인된 결함

### 3.1 Recovery duplicate

현재 `dm.request_recovery`는 authoritative state에 다음 key를 사용한다.

```text
recovery:<commandId>
```

하지만 projected recovery record 자체에는 `commandId`가 없다.

현재 `DmWorkspaceViewModel`의 pending dedup은 projected row의 `commandId`만 확인하므로, 같은 recovery command가:

```text
accepted_awaiting_projection local row
+
projection_confirmed recovery row
```

두 줄로 남을 수 있다.

**최소 수정 원칙:** Domain schema를 불필요하게 바꾸지 않는다. 기존 stable recovery key `recovery:<commandId>`에서 안전하게 commandId를 derive할 수 있으면 그 경계를 우선 사용한다. 다른 repository convention이 더 적절하면 동일 의미를 유지한다.

### 3.2 Control assignment never reconciles

`dm.assign_control`은 authoritative `dm_workspace.control[actorId] = controllerUserId` 및 scene actor controller projection으로 결과가 나타난다.

현재 local pending record는 충분한 expected projection data를 보존하지 않고, ViewModel도 projected control과 accepted pending을 대조하지 않는다. 따라서 성공 receipt 후 `accepted_awaiting_projection`이 authoritative confirmation으로 닫히지 않을 수 있다.

**최소 수정 원칙:** 새 command/domain을 만들지 않는다. 제출 시 기존 payload의 필요한 expected values를 local reconciliation metadata로 보존하고, 최신 authorized projection에서 실제 control 결과와 일치할 때만 `projection_confirmed`로 닫는다.

### 3.3 Terminal failure feedback disappears

현재 DM Workspace `onReceipt`는 terminal failure receipt에서 local pending row를 즉시 삭제한다.

그 결과 Phase 9 계약의:

```text
denied
stale
expired/timeout
validation/network terminal failure
```

상태를 사용자가 확인할 수 없다.

**최소 수정 원칙:** 실패한 command를 authoritative row로 가장하지 않는다. terminal receipt를 짧은 local feedback/reconciliation record로 유지하고 viewer-safe code/reason만 표시한다. 내부 stack, hidden target, private payload, server-only details는 표시하지 않는다.

기존 Result/message 구조와 Phase 6~8 feedback vocabulary를 재사용한다. 새 오류 체계를 만들지 않는다.

## 4. 반드시 유지할 Phase 9 경계

### Authority

허용된 기존 DM command만 사용한다.

```text
dm.assign_control
dm.quick_action
dm.runtime_patch
dm.request_recovery
```

새 gameplay-authority `dm.*` command를 추가하지 않는다.

### Projection

- Player/Observer `dm_workspace` negative disclosure를 약화하지 않는다.
- Player View Preview의 server `DomainProjectionPolicy` 재사용 경계를 유지한다.
- Preview가 live target `projectionSequence`를 소비하지 않는 성질을 유지한다.
- client가 authoritative gameplay state를 직접 변경하지 않는다.

### Queue

- authoritative rows와 local feedback rows를 명확히 구분한다.
- deterministic ordering을 유지한다.
- refresh/full-sync/reconnect 후 duplicate를 만들지 않는다.
- commandId 또는 실제 stable identity가 같은 projected/local command는 정확히 한 최종 의미 상태로 수렴한다.
- 성공 receipt만으로 `projection_confirmed`라고 표시하지 않는다. authoritative projection이 실제 기대 결과를 보여야 한다.
- projection 결과가 아직 없으면 `accepted_awaiting_projection`을 유지한다.
- authoritative projection과 expected result가 충돌하면 조용히 성공 처리하지 말고 stale/conflict/reconciliation-safe 상태로 남긴다.

### Local feedback lifecycle

terminal failure row는 영구 authoritative history가 아니다. Repository의 기존 UI feedback convention에 맞는 bounded/local lifecycle을 사용한다. 무제한 누적을 금지한다.

## 5. 요구 수정 범위

Codex는 최신 HEAD를 조사한 뒤 필요한 최소 파일만 수정한다. 우선 검토 대상:

```text
implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/DmWorkspaceViewModel.lua
implementation/roblox/src/StarterGui/RVTT/UI/Components/DmWorkspacePanel.lua
implementation/roblox/src/ServerScriptService/RVTT/Server/Domains/DmWorkspaceDomain.lua
implementation/roblox/tests/Unit/DmWorkspace.spec.lua
implementation/roblox/tests/Integration/ViewerProjectionPreview.spec.lua
implementation/roblox/CURRENT-WORK-ORDER.md
AGENT-TEST-STATUS.md
```

`DmWorkspaceDomain.lua` 변경은 정말 필요한 경우에만 한다. 기존 stable ids/projected state로 client reconciliation을 안전하게 해결할 수 있으면 Domain state shape를 변경하지 않는 쪽을 선호한다.

## 6. 필수 테스트 케이스

최소 다음을 automated/static test로 고정한다.

### Recovery reconciliation

1. local `dm.request_recovery` pending exists
2. terminal success receipt → `accepted_awaiting_projection`
3. 같은 command의 `recovery:<commandId>` authoritative projection 도착
4. local duplicate 제거
5. queue에 동일 recovery 의미 row가 정확히 1개
6. 상태는 `projection_confirmed`
7. projection refresh를 반복해도 duplicate 없음

### Control reconciliation

1. local `dm.assign_control(actorId, controllerUserId)` pending exists
2. success receipt alone → 아직 `accepted_awaiting_projection`
3. projection의 `dm_workspace.control[actorId]`가 expected controller와 일치
4. local pending 제거/confirmed로 수렴
5. 다른 controller 값이면 confirmed로 처리하지 않음

가능하면 scene actor `controllerUserId`와 dm_workspace control이 repository authority상 함께 검증되어야 하는지 현재 Domain/Projection 계약을 조사하고 맞춘다. 임의 요구를 만들지 않는다.

### Failure feedback

각각 최소 한 케이스 이상:

```text
permission/denied
stale epoch or stale revision
validation or timeout/transport-safe terminal failure
```

- terminal receipt 후 row가 즉시 사라지지 않는다.
- authoritative projection row로 표시하지 않는다.
- viewer-safe code/reason만 표시한다.
- hidden/private payload는 leak하지 않는다.
- bounded cleanup/refresh policy가 동작한다.

### Existing regression

- runtime patch dedup 유지
- quick action dedup 유지
- deterministic queue order 유지
- non-DM workspace visibility false / no placeholders/counts 유지
- role loss purges sensitive windows, pending and terminal local feedback
- Player View Preview negative disclosure / live sequence non-mutation 유지
- Q one-context-back behavior affected 없음을 확인

## 7. 상태 문서 정정

현재 repository status docs가 Phase 9를 이미 DONE/PASS로 표시하더라도 이번 검수 defect 때문에 최종 승인은 HOLD다.

작업 중에는 사실과 일치하도록 다룬다.

성공 조건을 모두 충족하고 새 current HEAD remote CI까지 성공한 뒤에만:

```text
Phase 9 DM Live Workspace → FINAL PASS / DONE
Phase 10 Full UI·UX Acceptance → IN_PROGRESS
```

로 확정한다.

실패/부분 완료/CI 실패면:

```text
Phase 9 → IN_PROGRESS / HOLD
Phase 10 → DO NOT ADVANCE
```

를 유지한다.

Work Order의 stale 문장 `DM Workspace와 Acceptance 정합화가 남아` 같은 본문/표 불일치가 있다면 최소 범위에서 현재 실제 상태와 맞춘다. 단, 오래된 Minimap/Map/Objective Tracker 문구를 다시 제품 권위로 살리지 않는다.

## 8. 검증

Repository가 요구하는 현재 검증을 실행한다.

최소:

```text
focused DmWorkspace unit/integration tests registered/static analyzed
python implementation/roblox/tooling/validate_implementation.py
python implementation/roblox/tooling/validate_remake_docs.py
relevant repository validators
StyLua --check
Selene
git diff --check
all required Rojo builds
default/test/multi-client sourcemaps as repository workflow expects
production/test Luau analysis
```

Studio/Roblox TestRunner runtime은 이번 fix에서 실행하지 않는다.

push 후 **새 current HEAD의 GitHub Actions를 직접 확인**한다.

최소 관련 workflow:

- Validate RVTT implementation
- Validate remake documentation
- Validate RVTT content templates
- Validate Grand harness
- Validate production lease

하나라도 failure면 PASS 금지.

## 9. 명시적 제외

하지 않는다.

- Phase 10 Acceptance 구현
- 새 DM feature/tool 추가
- 전체 Scene Editor 구현
- ADR-0092 runtime
- Persistence runtime
- Studio / Studio MCP / Human Playtest
- Performance/Soak
- Player Minimap / separate Map / Objective Tracker
- test 삭제/skip/assertion 약화
- validator/lint/CI bypass
- force push
- PR Ready/Approve/Merge

## 10. 성공 조건

다음 모두 필요하다.

```text
recovery duplicate closed
+ control assignment success reconciles only after projection
+ denied/stale/terminal failure remains visible as bounded viewer-safe local feedback
+ existing runtime patch/quick action reconciliation regression 없음
+ negative disclosure unchanged
+ focused tests added
+ local/static validation PASS
+ new current HEAD required GitHub Actions SUCCESS
```

그때만 Phase 9 final PASS다.

## 11. 결과 댓글 형식

```text
<!-- RVTT_CODEX_PHASE9_FIX_RESULT -->
commandId: RVTT-PR2-PHASE9-QUEUE-RECONCILIATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_9_RECONCILIATION_FIX
rootCauseConfirmed: <what was actually confirmed>
fixApplied: <minimal changes>
changedFiles: <count / paths>
recoveryReconciliation: <evidence>
controlReconciliation: <evidence>
terminalFailureFeedback: <evidence and bounded lifecycle>
negativeDisclosure: <evidence>
testsRun: <actual commands/results>
staticValidationStatus: <status>
remoteCiStatus: <current-head workflow conclusions/run ids if available>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
phase9FinalStatus: PASS | HOLD
phase10State: IN_PROGRESS | DO_NOT_ADVANCE
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

## 12. ChatGPT 후속 검수

사용자가 `확인`이라고 하면 ChatGPT는:

1. PR #2 current HEAD를 다시 조회한다.
2. 최신 `RVTT_CODEX_PHASE9_FIX_RESULT` 댓글을 찾는다.
3. target/result SHA와 실제 commit/files를 대조한다.
4. recovery/control/failure reconciliation source와 focused tests를 직접 확인한다.
5. current HEAD GitHub Actions를 직접 확인한다.
6. 모두 맞을 때만 Phase 9 final PASS를 인정한다.
7. 그 뒤에만 Phase 10 Acceptance로 진행한다.
