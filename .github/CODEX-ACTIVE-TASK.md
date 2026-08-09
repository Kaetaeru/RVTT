# RVTT Execution State

- status: `RESULT_READY_FOR_CHATGPT_VERIFICATION`
- commandId: `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_OFFICIAL_2024_CHARACTER_SHEET`
- commandPath: `.github/CODEX-IMPLEMENTATION-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_RESULT -->`
- resultStatus: `IMPLEMENTED_PENDING_CHATGPT_VERIFICATION`
- resultHeadSha: `CURRENT_REMOTE_HEAD_AT_RESULT_PUBLICATION`
- setupBaseHeadBeforeCommand: `ed6879eeb43ef3a0c097d975b1104a190a8f4210`
- commandFileCommit: `224698d7ebdc2e3ea95091f7c8547c804022871f`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_DICE_SLOT_REVEAL_NOTICE`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION,RULES_PROFILE_RELEASE_ENFORCEMENT,CORE_RULES_READER_ENGINE,PRIVATE_RULES_READER_IMPORT_OVERLAY,PRIVATE_STABLE_LINK_NORMALIZATION,OFFICIAL_2024_INTERACTIVE_CHARACTER_SHEET`
- currentCorrection: `OFFICIAL_2024_INTERACTIVE_CHARACTER_SHEET`
- coreRulesReaderAcceptanceState: `FINAL_STATIC_PASS`
- officialCharacterSheetAcceptanceState: `STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION`
- diceSlotRevealNoticeState: `BLOCKED`
- matrixRecordedFinalContractGaps: `1`
- effectiveRemainingFinalContractGaps: `1`
- nextCorrectionOnVerifiedSuccess: `DICE_SLOT_REVEAL_NOTICE`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `NOT_EXECUTED`
- studioHumanRetestState: `NOT_EXECUTED`
- humanUiUxState: `NOT_EXECUTED`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-09`

## 활성 작업

Codex는 아래 command를 가장 먼저 읽고 그대로 실행한다.

```text
.github/CODEX-IMPLEMENTATION-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001.md
```

## 이번 작업 목표

ADR-0091 / ADR-0040의 Official 2024 Character Sheet를 generic mockup이 아니라 실제 Production projection/control surface로 구현한다.

핵심 축:

```text
authoritative domain/projection
→ CharacterSheetProjection + revision parity
→ official-style Page 1 / Page 2 layout
→ roll / equip / use / prepare / attune / hotbar intents
→ CommandClient / server command
→ receipt / awaiting projection / reconciliation
```

Character Sheet는 별도 상태 저장소가 아니다. Inventory/Equipment/Character/Spell/Resource와 같은 authoritative state를 projection하여 표시하고, 변경은 server command만 제출한다.

## 필수 UI 계약

```text
Reference page ratio = 8.5:11 portrait

Page 1
Top Header = 13%
Main = 87%
Main Left / Right = 35% / 65%
Right subsections = 24% / 43% / 33%

Page 2
Left / Right = 68% / 32%
Left Top = 24% / 76%
Right subsections = 14% / 30% / 10% / 34% / 12%
```

Wide/Reference는 two-page spread, Compact는 Page Tab 1/2이며 compact column reflow는 금지한다.

## 필수 authority / interaction 계약

- Sheet revision은 authoritative projection revision이며 VTT Inventory와 동일해야 한다.
- Ability/Save/Skill/Initiative/Attack/Damage/Spell Attack/Hit Dice/Death Save/Feature Roll은 client dice 계산 없이 server roll request를 만든다.
- HP/Temp HP, equip/unequip, use/split/send, attune/unattune, prepare/memorize, hotbar pin/unpin, inspiration spend는 server command만 사용한다.
- 현재 backend에 accepted action이 없으면 UI fake success가 아니라 최소 server-owned generic state/command를 구현하고 synthetic regression으로 검증한다.
- receipt success와 authoritative projection 반영을 구분한다.
- stale revision, permission revoke, authority epoch rebuild를 fail-safe 처리한다.
- Player owner / authorized DM / Observer-or-unrelated-player nondisclosure를 projection builder 단계에서 검증한다.
- 특정 class/item/spell 또는 공식 수치를 UI 코드에 꾸며내지 않는다.

## 범위 밖

이번 task에서는 다음을 시작하지 않는다.

- Dice Slot Reveal Notice
- Studio/Human execution
- Multi-client runtime campaign
- Persistence runtime
- Performance/soak
- ADR-0092 Production

## 성공 조건

모든 focused/static/build/current-head Actions가 통과한 경우에만 Codex는 구현 완료를 주장할 수 있다.

성공 시 repository 상태 목표:

```text
Official 2024 Character Sheet = STATIC_VERIFIED
Core Rules Reader = FINAL STATIC PASS
remaining Final Contract gaps = 1
→ final.dice-slot-reveal-notice
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

`full-ui-ux-acceptance-matrix.json`의 Official Sheet 항목을 실제 Source/spec/validator 증거와 함께 갱신하고, `finalContractGaps`를 Dice Notice 하나로 줄이는 것은 모든 gate 통과 후에만 한다.

## 완료 후 결과 상태

Codex는 작업 완료 후 이 파일을 stale `READY_FOR_CODEX_EXECUTION` 상태로 남기지 않는다.

성공 주장 시:

```text
status: RESULT_READY_FOR_CHATGPT_VERIFICATION
resultStatus: IMPLEMENTED_PENDING_CHATGPT_VERIFICATION
resultHeadSha: <current remote HEAD>
effectiveRemainingFinalContractGaps: 1
nextCorrectionOnVerifiedSuccess: DICE_SLOT_REVEAL_NOTICE
studioRuntimeState: NOT_EXECUTED
humanUiUxState: NOT_EXECUTED
```

ChatGPT 독립 검증 전에는 `FINAL_PASS`를 쓰지 않는다.

## 결과 전달

PR #2 top-level Conversation에 다음 marker로 결과를 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_RESULT -->
```

필수 결과 내용은 command 파일의 `결과 댓글` 절을 따른다.
