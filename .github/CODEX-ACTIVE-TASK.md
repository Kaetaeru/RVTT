# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_IMPLEMENTATION_REPAIR`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_AUTHORITY_REPAIR`
- commandPath: `.github/CODEX-FIX-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-002.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_002_RESULT -->`
- resultStatus: `PENDING`
- setupBaseHeadBeforeCommand: `0d151c8253cc36fa31f7582e845bbe184e780bbd`
- commandFileCommit: `c95d6e298dda896f3254228d402c1bf31052332d`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_OFFICIAL_SHEET_AUTHORITY_REPAIR`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION,RULES_PROFILE_RELEASE_ENFORCEMENT,CORE_RULES_READER_ENGINE,PRIVATE_RULES_READER_IMPORT_OVERLAY,PRIVATE_STABLE_LINK_NORMALIZATION`
- currentCorrection: `OFFICIAL_2024_CHARACTER_SHEET_AUTHORITY_AND_PRODUCTION_PATH_REPAIR`
- coreRulesReaderAcceptanceState: `FINAL_STATIC_PASS`
- rulesProfileReleaseAcceptanceState: `STATIC_PASS`
- officialCharacterSheetAcceptanceState: `HOLD_PENDING_AUTHORITY_REPAIR`
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
.github/CODEX-FIX-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-002.md
```

## ChatGPT 독립 검증 판정

직전 구현은 current-head Actions가 green이었지만 아래 차단 결함 때문에 Official Sheet를 `STATIC_VERIFIED`로 인정하지 않았다.

1. `rules.sheet_roll`이 client-supplied `ability/proficient/mode`를 규칙 권위로 사용할 수 있음.
2. focused spec이 Production command path로 만들 수 없는 Character/Item fields를 직접 주입함.
3. Sheet attack list가 authoritative `ActorProfileResolver` attack catalog와 분리됨.
4. Page 1 Top Header/Main Left 정보 구조가 Final UI contract보다 부족함.
5. Equipment가 첫 row 하나만 실질 interaction surface임.
6. details/send가 완결된 interaction flow가 아니고 structured spell slots rendering도 보강 필요.

따라서 현재 matrix의 Official Sheet `STATIC_VERIFIED`와 final gap 1개 기록은 성공 증거로 사용하지 않는다. Codex는 작업 중 실제 상태를 HOLD에 맞추고, 모든 repair와 gate 성공 후에만 다시 `STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION`으로 올릴 수 있다.

## 이번 repair의 필수 축

```text
server-authoritative roll resolution
→ forged payload negative regressions
→ Production-constructible Character/Inventory state
→ projection/attack source parity
→ exact Official 2024 two-page information structure
→ all Equipment rows + working Popover/details/send
→ receipt/revision/epoch safety
→ strengthened validator + current-head Actions
```

### 서버 Roll 권위

Client가 modifier/proficiency/advantage/damage formula를 선택할 수 없어야 한다. `rollKind + stable sourceId + authoritative domain/profile`에서 서버가 ability/proficiency/formula/eligibility를 해석한다.

### Production constructibility

Synthetic fixture에만 `attacks/spellcasting/equipSlot/usable/attunable/hotbarCapable`를 직접 넣고 PASS하는 것은 금지한다. 실제 Production character/inventory/content boundary로 생성된 state에서 Sheet positive path가 성립해야 한다.

특정 D&D class/item/spell 수치나 CR을 임의로 만들지 않는다. authoritative source가 없는 optional field는 unavailable/empty로 표시한다.

### UI 계약

Accepted Final UI contract의 Page 1 Header/Main Left/Main Right와 Page 2 비율·내용을 그대로 유지한다. Equipment 34%에는 모든 row가 표시되고 각 row가 `SheetItemActionPopover`를 열어야 한다.

## 범위 밖

- Dice Slot Reveal Notice
- Studio/Human execution
- Persistence
- performance/soak
- ADR-0092 Production

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

Codex는 `FINAL_PASS`를 쓰지 않는다. ChatGPT가 결과 diff, domain authority, regressions, validator, current-head Actions를 독립 검증한 뒤 최종 판정한다.

## 결과 전달

PR #2 top-level Conversation에 다음 marker를 사용한다.

```text
<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_002_RESULT -->
```

세부 성공 조건과 필수 결과 필드는 command 파일을 따른다.
