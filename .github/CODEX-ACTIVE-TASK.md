# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_IMPLEMENTATION`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_DICE_SLOT_REVEAL_NOTICE`
- commandPath: `.github/CODEX-IMPLEMENTATION-ADR0091-DICE-SLOT-REVEAL-NOTICE-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_001_RESULT -->`
- resultStatus: `PENDING`
- setupBaseHeadBeforeCommand: `a942f8187ef5535d8e74374433e4c134747dd83a`
- commandFileCommit: `96f7472c6d7d0e3c40b44ddf7718be390841495e`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_DICE_SLOT_REVEAL_NOTICE`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION,RULES_PROFILE_RELEASE_ENFORCEMENT,CORE_RULES_READER_ENGINE,PRIVATE_RULES_READER_IMPORT_OVERLAY,PRIVATE_STABLE_LINK_NORMALIZATION,OFFICIAL_2024_CHARACTER_SHEET_FINAL_STATIC_PASS`
- currentCorrection: `DICE_SLOT_REVEAL_NOTICE`
- coreRulesReaderAcceptanceState: `FINAL_STATIC_PASS`
- rulesProfileReleaseAcceptanceState: `STATIC_PASS`
- officialCharacterSheetAcceptanceState: `FINAL_STATIC_PASS`
- diceSlotRevealNoticeState: `BLOCKED_PENDING_IMPLEMENTATION`
- effectiveRemainingFinalContractGaps: `1`
- nextCorrectionOnVerifiedSuccess: `CHATGPT_BROAD_CURRENT_HEAD_STATIC_REVALIDATION`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `NOT_EXECUTED`
- studioHumanRetestState: `NOT_EXECUTED`
- humanUiUxState: `NOT_EXECUTED`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-10`

## 활성 작업

Codex는 아래 command를 가장 먼저 읽고 그대로 실행한다.

```text
.github/CODEX-IMPLEMENTATION-ADR0091-DICE-SLOT-REVEAL-NOTICE-001.md
```

## ChatGPT 독립 검증 기준점

current pre-command HEAD `a942f8187ef5535d8e74374433e4c134747dd83a`에서 다음을 독립 검증했다.

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader = FINAL STATIC PASS
Official 2024 Character Sheet = FINAL STATIC PASS
Dice Slot Reveal Notice = BLOCKED
Effective Final Contract gaps = 1
Studio/Human = NOT_EXECUTED
```

따라서 이번 작업은 ADR-0091의 마지막 Source/Static gap인 Dice Slot Reveal Notice만 구현한다.

## 필수 계약

```text
DiceNoticeProjection
→ server-authored naturalResults/appliedIndex/modifierTerms/total/adjudication/semanticCritical/audience
→ deterministic client ViewModel queue/reconciliation
→ presentation-only DiceSlotRevealNotice
```

Client는 applied die, modifier arithmetic, total, success/failure, critical을 계산하지 않는다.

Normal d20 state machine:

```text
hidden
→ square_enter        120 ms
→ slot_spin           420–720 ms
→ natural_lock        180 ms
→ formula_expand      260 ms
→ adjudication_append 180 ms
→ hold                1600–2600 ms
→ dismiss             240 ms
```

Advantage/Disadvantage는 두 Natural Cell + server `appliedIndex`, discarded contrast 45–55%, applied cell만 Natural 1/20 visual semantic을 사용한다.

Reduced Motion은 2–3단계 Crossfade, no shake, 동일 공개 순서를 사용한다.

여러 roll은 FIFO queue, 동시 stack 최대 2개, duplicate/stale/reconnect replay를 deterministic하게 억제한다.

Unauthorized viewer에게는 roll placeholder/count/subject/action/natural/total/adjudication을 노출하지 않는다.

## 범위 밖

- Official Sheet 재설계
- Core Rules Reader 변경
- Persistence
- ADR-0092 Production
- 3D Dice physics
- Studio/Human execution
- unrelated refactor

## 성공 상태

모든 implementation + focused regressions + validator/self-tests + build/type + current-head Actions 성공 후에만:

```text
Dice Slot Reveal Notice = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Effective ADR-0091 Source/Static Final Contract gaps = 0
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
next = CHATGPT_BROAD_CURRENT_HEAD_STATIC_REVALIDATION
```

Codex는 `FINAL_PASS`, `PHASE_10_PASS`, `STUDIO_PASS`, `HUMAN_PASS`를 쓰지 않는다.

## 결과 전달

PR #2 top-level Conversation에 다음 marker를 사용한다.

```text
<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_001_RESULT -->
```

세부 필수 결과 필드는 command 파일을 따른다.
