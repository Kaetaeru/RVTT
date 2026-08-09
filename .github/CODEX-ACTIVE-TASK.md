# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-003`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_IMPLEMENTATION_REPAIR`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_ELIGIBILITY_AUTHORITY_REPAIR`
- commandPath: `.github/CODEX-FIX-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-003.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_003_RESULT -->`
- resultStatus: `PENDING`
- setupBaseHeadBeforeCommand: `fecf0f39ce964d60229818f685afdf23cb5059e8`
- commandFileCommit: `b993341496af39ff8dbf4ff8135a0de2c6e1ebc1`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_OFFICIAL_SHEET_ELIGIBILITY_AUTHORITY_REPAIR`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION,RULES_PROFILE_RELEASE_ENFORCEMENT,CORE_RULES_READER_ENGINE,PRIVATE_RULES_READER_IMPORT_OVERLAY,PRIVATE_STABLE_LINK_NORMALIZATION,OFFICIAL_SHEET_FIX_002_MAJOR_REPAIR`
- currentCorrection: `OFFICIAL_2024_CHARACTER_SHEET_HIT_DIE_AND_ITEM_CAPABILITY_AUTHORITY`
- coreRulesReaderAcceptanceState: `FINAL_STATIC_PASS`
- rulesProfileReleaseAcceptanceState: `STATIC_PASS`
- officialCharacterSheetAcceptanceState: `HOLD_PENDING_ELIGIBILITY_AUTHORITY_REPAIR`
- diceSlotRevealNoticeState: `BLOCKED`
- matrixRecordedFinalContractGaps: `1_STALE_OVERSTATEMENT`
- effectiveRemainingFinalContractGaps: `2`
- nextCorrectionOnVerifiedSuccess: `DICE_SLOT_REVEAL_NOTICE`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `NOT_EXECUTED`
- studioHumanRetestState: `NOT_EXECUTED`
- humanUiUxState: `NOT_EXECUTED`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-10`

## 활성 작업

Codex는 아래 command를 가장 먼저 읽고 그대로 실행한다.

```text
.github/CODEX-FIX-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-003.md
```

## ChatGPT 독립 재검증 판정

FIX-002는 다음 큰 결함을 실제로 개선했다.

- `rules.sheet_roll` client rule-math forgery 차단
- server-owned Character/Item content hydration
- canonical profile attack source wiring
- Official two-page field/layout 보강
- 모든 Equipment row + working popover/details/send
- structured spell slots
- out-of-order receipt guard

그러나 current HEAD `fecf0f39ce964d60229818f685afdf23cb5059e8`에서 아래 차단 결함이 남아 있어 Official Sheet는 아직 `HOLD`다.

1. Hit Die는 `remaining == 0`이어도 server roll 가능하며 성공 시 remaining을 소비하지 않는다.
2. `inventory.equip`은 trusted `item.equipSlot`을 server boundary에서 강제하지 않고 client slot/비장착 item 우회가 가능하다.
3. `character.sheet_set_hotbar`는 `item.hotbarCapable == true` 및 target character ↔ item location 관계를 server boundary에서 강제하지 않는다.
4. trusted attack source가 없는 상태에서 fabricated generic fallback이 Official Sheet completeness의 성공 근거가 되지 않도록 non-invention guard가 필요하다.
5. focused regression/validator는 위 세 eligibility authority 우회를 아직 직접 잠그지 않는다.

현재 Matrix의 Official Sheet `STATIC_VERIFIED`와 final gap 1개 기록은 이번 ChatGPT 판정 기준으로 stale overstatement이며 성공 증거로 사용하지 않는다.

## 이번 FIX-003 필수 축

```text
Hit Die remaining authority + atomic consumption
→ Projection availability parity
→ trusted equipSlot enforcement
→ hotbarCapable + character-item relation enforcement
→ no fabricated attack acceptance
→ real Production-path negative regressions
→ validator negative self-tests
→ current-head Actions
```

### Hit Die

- authoritative `remaining > 0`일 때만 사용 가능
- 성공한 roll과 remaining -1이 같은 transaction
- zero/malformed/missing remaining은 fail closed
- Projection도 availability와 일치
- client가 sides/count/modifier/remaining을 지정하지 못함

### Equip

- trusted `item.equipSlot`만 canonical slot
- non-equippable item direct command 거부
- forged alternate slot 거부 또는 authority effect 없음
- 다른 character item을 equip command로 몰래 이전하는 우회 금지

### Hotbar

- trusted `item.hotbarCapable == true` 필수
- item current location이 target character에 속해야 함
- 다른 character/ground/non-capable item pin/unpin fail closed

### Attack non-invention

- positive attack acceptance는 active server-owned original definition의 explicit attack으로 증명
- trusted attack definition이 없는 character에 새 공식/가짜 attack formula를 발명하지 않음
- 특정 D&D 수치/CR/공격 수치를 새로 hardcode하지 않음

## 범위 밖

- Dice Slot Reveal Notice
- Studio/Human execution
- Persistence
- performance/soak
- ADR-0092 Production
- unrelated refactor

## 성공 상태

모든 repair + focused/static/build/current-head Actions 성공 후에만:

```text
Official 2024 Character Sheet = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Core Rules Reader = FINAL STATIC PASS
Effective Final Contract gaps = 1
→ final.dice-slot-reveal-notice
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

Codex는 `FINAL_PASS`를 쓰지 않는다. ChatGPT가 result diff, authority semantics, negative regressions, validator, current-head Actions를 독립 검증한 뒤 최종 판정한다.

## 결과 전달

PR #2 top-level Conversation에 다음 marker를 사용한다.

```text
<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_003_RESULT -->
```

세부 필수 결과 필드는 command 파일을 따른다.
