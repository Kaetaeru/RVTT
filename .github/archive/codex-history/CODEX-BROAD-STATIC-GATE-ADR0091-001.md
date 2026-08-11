# Codex Command — ADR-0091 Broad Current-HEAD Static Gate Release 001

- commandId: `RVTT-PR2-ADR0091-BROAD-STATIC-GATE-RELEASE-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `936c27ed3bfbb123fbb62a2ee16e89a0f5cbe3ce`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_BROAD_STATIC_GATE_RELEASE_001_RESULT -->`
- taskType: `STATIC_GATE_RELEASE_AND_STATUS_RECONCILIATION`
- studioRuntime: `FORBIDDEN_IN_THIS_COMMAND`
- humanPlaytest: `FORBIDDEN_IN_THIS_COMMAND`

## 0. 시작 조건

작업 시작 시 PR #2 current remote HEAD를 확인한다.

- 이 command를 포함한 최신 branch HEAD에서만 작업한다.
- 새 PR/새 branch를 만들지 않는다. 기존 PR #2 branch에 fast-forward push한다.
- 외부 변경으로 HEAD가 전진했으면 먼저 diff를 확인한다.
- Studio/Human Runtime은 이 command에서 실행하지 않는다.
- 구현 기능을 다시 설계하거나 unrelated refactor를 하지 않는다.

## 1. ChatGPT 독립 검증 결과 — 이 command의 Authority

ChatGPT는 FIX-003 result HEAD `936c27ed3bfbb123fbb62a2ee16e89a0f5cbe3ce`를 독립 검증했다.

확정 판정:

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader = FINAL STATIC PASS
Official 2024 Character Sheet = FINAL STATIC PASS
Dice Slot Reveal Notice = FINAL STATIC PASS
Effective ADR-0091 Source/Static finalContractGaps = 0
Studio/Human = NOT_EXECUTED
```

Dice FIX-003에서 다음을 실제 source/test/validator/current-head Actions로 확인했다.

- full-motion numeral strip은 `top_to_bottom` 방향이며 initial Y가 final Y보다 작다.
- reduced motion은 `CrossfadeA/B` 두 레이어에서 outgoing/incoming transparency tween을 겹쳐 실행한다.
- projected natural은 `natural_lock` 전 공개하지 않는다.
- 방향 반전과 single-label fade-in-only 회귀는 validator negative self-test로 차단한다.
- 기존 server authority, audience nondisclosure, queue/stack/replay suppression, formula tween, Natural 1/20 effects, dual Applied emphasis, Production advantage/disadvantage server path는 유지됐다.
- FIX-003 HEAD의 PR-triggered Actions 6개는 모두 success였다.

이 command는 위 결과를 **repository acceptance state와 broad validator에 반영하는 latch release**다. 새 기능 구현 command가 아니다.

## 2. Broad validator verification latch 해제

`implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`를 현재 확정 판정에 맞춘다.

필수:

```text
RESOLVED_FINAL_IDS
→ final.asset-registry-separation
→ final.official-2024-sheet-interactions
→ final.dice-slot-reveal-notice
→ final.core-rules-reader-filtering
→ final.rules-profile-release-leak-gate

REMAINING_FINAL_GAPS
→ empty set
```

Dice final item validation도 더 이상 `BLOCKED pending ChatGPT verification`을 요구하면 안 된다.

반드시 다음을 요구한다.

```text
final.dice-slot-reveal-notice.currentState == STATIC_VERIFIED
final.dice-slot-reveal-notice.evidenceStatus.STATIC == PASS
required Dice production/test/validator evidence refs present
finalContractGaps == actual BLOCKED final item subset == empty set
```

Validator를 약화하지 않는다.

- Dice focused validator 호출 유지
- Asset Registry focused validator 유지
- Rules Profile/Release focused validator 유지
- Core Rules Reader focused validator 유지
- Official Sheet focused validator 유지
- forbidden Player persistent surface checks 유지
- existing matrix/manifest consistency checks 유지

Self-test도 새 latch 상태에 맞춰 갱신한다.

필수 negative fixtures:

1. Dice를 다시 BLOCKED로 내리면 broad validator가 실패한다.
2. Dice STATIC evidence를 PASS가 아닌 값으로 바꾸면 실패한다.
3. `finalContractGaps`에 Dice를 다시 넣으면 실패한다.
4. empty final gaps인데 어떤 final item이 BLOCKED면 실패한다.
5. 기존 focused validator self-tests는 계속 통과한다.

## 3. Acceptance Matrix 0-gap 전환

`implementation/roblox/full-ui-ux-acceptance-matrix.json`:

`final.dice-slot-reveal-notice`를 다음 상태로 전환한다.

```json
"currentState": "STATIC_VERIFIED",
"evidenceStatus": {"STATIC": "PASS"}
```

- pending ChatGPT blockerReason을 제거한다.
- `finalContractGaps`를 정확히 `[]`로 만든다.
- 다른 Runtime/Human evidence를 임의로 PASS 처리하지 않는다.
- Studio/Human/Persistence/Performance 상태는 기존 NOT_EXECUTED/DEFERRED를 유지한다.

## 4. 상태 문서 동기화

최소 다음을 current broad-static truth에 맞춘다.

- `implementation/roblox/FULL-UI-UX-ACCEPTANCE.md`
- `implementation/roblox/CURRENT-WORK-ORDER.md`
- `implementation/roblox/AGENT-TEST-STATUS.md`
- 필요 시 같은 canonical 상태를 반복하는 implementation status 문서

정확한 의미:

```text
ADR-0091 Source/Static final-contract gaps = 0
Full UI/UX broad static gate = CANDIDATE_PASS_PENDING_CURRENT_HEAD_ACTIONS until Actions finish
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
Persistence Runtime = DEFERRED / NOT_EXECUTED according to existing schema
Performance/Soak = DEFERRED
next runtime gate = Exploration / Context Input Studio Retest
```

기존 Historical Studio evidence를 current-head evidence처럼 재라벨링하지 않는다.

## 5. Broad Static validation

변경 후 최소 다음을 실행한다.

```text
python implementation/roblox/tooling/validate_dice_slot_reveal_notice.py
python implementation/roblox/tooling/validate_full_ui_ux_acceptance.py
python implementation/roblox/tooling/validate_implementation.py
```

그리고 repository-required checks:

- private rules synthetic runtime pipeline
- public release staging/leak gate
- content template validation where applicable
- StyLua
- Selene
- all repository-required Rojo builds/sourcemaps
- Luau type analysis

정적/빌드 성공을 Studio Runtime PASS라고 쓰지 않는다.

## 6. Current-head GitHub Actions gate

최종 result HEAD의 PR-triggered workflow를 확인한다.

필수:

- current result HEAD와 workflow head_sha가 정확히 일치
- expected PR workflows가 모두 completed/success
- `Validate RVTT implementation` structure-and-policy success
- public rules release staging success
- private rules runtime pipeline success
- formatter/lint success
- required Rojo builds success
- Luau type analysis success

Actions가 queued/in_progress/failure/cancelled이면 broad gate PASS를 주장하지 않는다.

## 7. 성공 시 상태

모든 local/static validator와 current-head Actions가 성공한 경우에만:

```text
ADR-0091 broad current-head Static Gate = PASS_PENDING_CHATGPT_FINAL_CONFIRMATION
ADR-0091 finalContractGaps = 0
Phase 10 Source/Static = PASS_PENDING_CHATGPT_FINAL_CONFIRMATION
Studio Runtime = NOT_EXECUTED
Human Playtest = NOT_EXECUTED
next = EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST
```

Codex는 `STUDIO_PASS`, `HUMAN_PASS`, `RUNTIME_PASS`, `MERGE_READY`를 주장하지 않는다.

## 8. 실패 시

어떤 broad validator/Actions가 실패하면:

- 실패 원인을 최소 범위로 고친다.
- unrelated refactor 금지.
- 기능 계약을 완화해 validator를 통과시키지 않는다.
- 해결할 수 없으면 Matrix/Work Order를 과대 승격하지 말고 BLOCKED/HOLD로 유지한다.
- result comment에 정확한 blocker를 남긴다.

## 9. Active Task 완료 상태

성공 시 `.github/CODEX-ACTIVE-TASK.md`를 다음 의미로 갱신한다.

```text
status: RESULT_READY_FOR_CHATGPT_VERIFICATION
resultStatus: BROAD_STATIC_GATE_CANDIDATE_PASS
phase10Status: SOURCE_STATIC_CANDIDATE_PASS
assetRegistryAcceptanceState: STATIC_PASS
rulesProfileReleaseAcceptanceState: STATIC_PASS
coreRulesReaderAcceptanceState: FINAL_STATIC_PASS
officialCharacterSheetAcceptanceState: FINAL_STATIC_PASS
diceSlotRevealNoticeState: FINAL_STATIC_PASS
effectiveRemainingFinalContractGaps: 0
newCurrentHeadStaticGate: CANDIDATE_PASS_PENDING_CHATGPT_FINAL_CONFIRMATION
nextRuntimeOnVerifiedSuccess: EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST
studioRuntimeState: NOT_EXECUTED
studioHumanRetestState: NOT_EXECUTED
humanUiUxState: NOT_EXECUTED
```

## 10. PR 결과 댓글

PR #2 top-level Conversation에 정확히 한 개의 새 result comment를 남긴다.

Marker:

`<!-- RVTT_CODEX_ADR0091_BROAD_STATIC_GATE_RELEASE_001_RESULT -->`

필수 필드:

- commandId
- startHeadSha
- resultHeadSha
- resultStatus
- changedFiles
- finalContractGaps
- broadValidatorEvidence
- focusedValidatorEvidence
- matrixStateEvidence
- currentHeadActions
- implementationJobEvidence
- studioRuntimeState: `NOT_EXECUTED`
- humanPlaytestState: `NOT_EXECUTED`
- nextRuntimeGate: `EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST`
- remainingRisks

## 11. 범위 밖

- Studio/MCP/Human 실행
- Persistence Runtime
- Performance/Soak
- ADR-0092 Production
- 3D Dice physics
- broad UI redesign
- force push
- PR ready/approve/merge
