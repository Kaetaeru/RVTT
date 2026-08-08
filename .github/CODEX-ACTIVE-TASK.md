# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_7`
- commandPath: `.github/CODEX-IMPLEMENTATION-INVENTORY-JOURNAL-SETTINGS-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001`
- previousCommandStatus: `PASS`
- studioRuntimeState: `BLOCKED_UNTIL_UI_ALIGNMENT_AND_NEW_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

다음 한 Phase만 수행한다.

```text
Inventory · Journal · Settings
→ Screen · Intent · Permission · Preference
```

Phase 4 Shared Shell·Preference Foundation, Phase 5 Input·Context Action, Phase 6 Exploration·Encounter HUD는 완료됐다.
이번 Phase는 기존 Shared Shell/Projection/Command/Preference 경계를 재사용해 관리 화면을 정합화한다.

## 현재 Authority

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ ADR-0088 / ADR-0089 / ADR-0090 / ADR-0091
→ final-ui-content-implementation-contract.md
→ implementation-ready-ui-ux-and-settings-spec.md (상위 계약에 의해 superseded된 부분 제외)
→ Inventory / Journal / Character / Settings 관련 Architecture·Slice·System Guide
→ EXECUTION-TEST-RULES.md
```

중요: 최신 상위 계약에 따라 Player persistent UI에 Minimap·별도 Map·Objective Tracker를 추가하지 않는다.

## 이번 Phase의 고정 계약

### Inventory

- Projection-backed inventory/equipment/item presentation을 사용한다.
- 현재 Repository에 존재하는 loot/transfer/identification flow만 UI Intent로 연결한다.
- UI가 Domain Store를 직접 변경하지 않는다.
- 실제 변경은 기존 Command boundary와 Server authorize를 통과한다.
- viewer에게 공개되지 않은 item/property/count/container/capability는 노출하거나 추측하지 않는다.

### Journal

- 기존 Journal Projection과 Permission을 따른다.
- private/DM-only/hidden entry를 placeholder로도 누출하지 않는다.
- 별도 Player Map이나 Objective Tracker를 새로 만들지 않는다.
- navigation/selection은 권위 Command가 없는 한 local presentation state다.

### Settings

기존 다음 경로를 재사용한다.

```text
PreferenceSchema
→ UiPreferenceStore
→ ThemeContract / ThemeApplicator
→ SettingsPanel
```

- schema가 실제 지원하는 설정만 노출한다.
- reset은 기존 schema/store 계약을 따른다.
- binding 편집이 현 계약에 포함돼 있으면 conflict를 감지·표시하며 조용히 덮어쓰지 않는다.
- accent/ui scale/text scale/motion 등 기존 preference 변경 중 gameplay selection/focus를 불필요하게 제거하지 않는다.
- 현재 architecture보다 강한 persistence 보장을 꾸며내지 않는다.

### Availability / Permission

```text
viewer에게 비공개
→ 미표시

viewer에게 공개되지만 현재 불가능
→ disabled + viewer-safe reason

현재 가능
→ enabled intent
```

stale projection/revision으로 권위 변경을 우회하지 않는다.

## 작업 경계

이번 Phase에서는 다음을 하지 않는다.

- Roblox Studio 또는 Human Playtest
- Phase 8 Entry·Role·Recovery
- Phase 9 DM Live Workspace
- Phase 10 Full Acceptance 완료
- ADR-0092 Runtime
- Persistence Runtime 확대
- Touch·Controller 전용 UI
- Player Minimap·별도 Map·Objective Tracker
- Client Gameplay Authority 신설
- Hidden 정보 placeholder
- PR Ready·Approve·Merge

Studio Human Retest는 Phase 4~10 정합화와 새 current-HEAD Static Gate 뒤에만 진행한다.

## 실행 절차

1. `commandPath`의 Phase 7 명령을 읽는다.
2. PR #2 최신 원격 HEAD와 현재 Branch를 확인한다.
3. `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 먼저 읽는다.
4. Phase 6 `DONE`, Phase 7 `IN_PROGRESS`를 확인한다.
5. 기존 Inventory/Journal/Settings UI·Projection·Domain·Permission·Command·Preference Source를 조사한다.
6. Shared Shell, `PanelShell`, `ProjectionReplica`, `CommandClient`, `PreferenceSchema`, `UiPreferenceStore`, Theme 경계를 재사용한다.
7. `RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001` 범위만 구현한다.
8. Screen composition, permission/negative disclosure, intent routing, preference validation/reset/conflict, revision handling 관련 test를 보강한다.
9. Repository가 정의한 가능한 정적/자동 검증을 실행한다.
10. 성공한 경우에만 Phase 7을 `DONE`, Phase 8을 `IN_PROGRESS`로 갱신하고 `AGENT-TEST-STATUS.md`도 실제 결과에 맞춘다.
11. 현재 PR branch에 non-force 반영한다.
12. 결과 게시 직전 원격 PR HEAD를 재확인한다.
13. 지정 Marker를 포함한 PR #2 top-level 결과 댓글을 남긴다.
14. Studio Runtime/Human PASS를 주장하지 않는다.

## 결과 검수 기준

결과 댓글은 최소 다음을 포함한다.

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | PARTIAL | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_7
implementedScope: <concise list>
changedFiles: <count and/or paths>
testsRun: <commands/results>
staticValidationStatus: <status>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
currentWorkOrderStatus: <phase 7/8 status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
negativeDisclosure: <summary>
notes: <limitations>
```

PASS는 Phase 7 Source/Static 범위만 의미한다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 지시하면:

1. PR #2 현재 HEAD를 조회한다.
2. 최신 `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->` 댓글을 찾는다.
3. `commandId`가 `RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001`인지 확인한다.
4. `resultHeadSha`와 현재 PR HEAD가 일치하는지 확인한다.
5. 실제 changed files/tests와 결과 보고를 대조한다.
6. Screen·Intent·Permission·Preference 및 negative disclosure 경계를 확인한다.
7. PASS면 Phase 7 완료만 인정하고 Phase 8로 이어간다.
8. Studio Runtime/Human PASS로 확대 해석하지 않는다.
