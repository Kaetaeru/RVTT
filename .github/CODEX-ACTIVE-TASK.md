# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-CORE-RULES-PRIVATE-STABLE-LINK-FIX-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION_FIX`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_CORE_RULES_PRIVATE_STABLE_LINK_FIX`
- commandPath: `.github/CODEX-FIX-ADR0091-CORE-RULES-PRIVATE-STABLE-LINKS-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_CORE_RULES_PRIVATE_LINK_FIX_RESULT -->`
- resultStatus: `PENDING`
- setupBaseHeadBeforeCommand: `1201b587e8638c7111422d2679f7e6bcd784c5b3`
- commandFileCommit: `bde6f3a70ca2c84c45081aff2ea798229cfca03c`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_CORE_RULES_PRIVATE_STABLE_LINK_FIX`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION,RULES_PROFILE_RELEASE_ENFORCEMENT,CORE_RULES_READER_ENGINE,PRIVATE_RULES_READER_IMPORT_OVERLAY_BASE`
- currentCorrection: `CORE_RULES_PRIVATE_STABLE_LINK_NORMALIZATION`
- coreRulesReaderFunctionalState: `STATIC_IMPLEMENTED`
- coreRulesReaderAcceptanceState: `HOLD_PENDING_PRIVATE_STABLE_LINK_FIX`
- matrixRecordedFinalContractGaps: `2_PREMATURE_UNTIL_THIS_FIX_PASSES`
- effectiveRemainingFinalContractGaps: `3`
- nextCorrectionOnSuccess: `OFFICIAL_2024_CHARACTER_SHEET`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `BLOCKED`
- studioHumanRetestState: `NOT_STARTED_CURRENT_CONTRACT`
- humanUiUxState: `NOT_EXECUTED`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-09`

## 활성 작업

Codex는 아래 command를 가장 먼저 읽고 그대로 실행한다.

```text
.github/CODEX-FIX-ADR0091-CORE-RULES-PRIVATE-STABLE-LINKS-001.md
```

핵심 repair 범위는 다음 세 축이다.

```text
1. imported sourceRoot 내부 Markdown navigation
   -> stable rvtt-rule:// document/section anchor

2. missing local target 또는 sourceRoot 밖 repository-relative link
   -> raw private source path를 runtime text/relatedLinks/backlinks에 남기지 않고 safe plain-text downgrade

3. synthetic private pipeline
   -> 실제 link graph + fragment + duplicate anchor + missing/out-of-root/external + reciprocal backlink regression
```

## ChatGPT 검증상 현재 상태

이 task 시작 전 독립 재검증 판정은 다음과 같다.

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader engine/filter/lazy-load = STATIC 구현됨
Core Rules Reader private stable-link import = HOLD
Official 2024 Character Sheet = BLOCKED
Dice Slot Reveal Notice = BLOCKED
Studio/Human Runtime = NOT_EXECUTED
```

현재 `full-ui-ux-acceptance-matrix.json`이 Core Rules Reader를 `STATIC_VERIFIED`로 기록하고 `finalContractGaps = 2`라고 하더라도, **이번 repair가 PASS하기 전까지 그 상태를 성공 증거로 사용하지 않는다.**

실질적으로는 현재 Core Reader stable-link issue까지 포함해 3개 blocker로 취급한다.

## 확인된 구체적 결함

현재 importer는 `_resolve_rule_uri()`가 실패하면 original Markdown link를 그대로 보존한다.

실제 pinned private corpus에는 다음 유형이 존재한다.

```text
integrated-2024/README.md
-> directory README navigation

integrated-2024/character-creation/README.md
-> in-root document links
-> ../README.md
-> ../../../00-QUICK-RULES/... 같은 sourceRoot 밖 repository-relative link
```

따라서 unresolved/out-of-root local link가 raw `.md` source path로 private runtime RuleReaderPackage text에 남을 수 있다.

Codex는 private body를 public RVTT Git tree에 복사하지 않고 importer behavior와 public-safe synthetic fixtures만 수정해야 한다.

## 보존해야 할 현재 PASS 영역

다음을 회귀시키면 안 된다.

- BuiltinPackIndex single package authority
- private revision / subtree digest / exact content count / dirty-source fail closed
- generated private overlay outside public Git tree
- explicit owner-only authorizedUserIds
- unauthorized viewer pre-resolution nondisclosure
- explicit `allowSrdFallback=true` runtime path
- public/release/artifact SRD-only
- filesystem release leak gate
- RuleProfileStatus client-safe allowlist
- Reader manifest body/chunk graph non-replication
- lazy chunk loading
- permission-filtered title/count/snippet/link/body nondisclosure
- Session authoritative role marker
- Player persistent Minimap / separate Player Map / Objective Tracker prohibition

## 성공 조건

Codex가 command의 필수 regression과 repository-required validators/toolchain/Actions를 모두 통과한 경우에만 다음 상태를 인정한다.

```text
Core Rules Reader = STATIC_VERIFIED
remaining Final Contract gaps = 2
1. Official 2024 Interactive Character Sheet
2. Dice Slot Reveal Notice
Phase 10 = PARTIAL / HOLD
next = OFFICIAL_2024_CHARACTER_SHEET
```

failure/pending/cancelled Actions가 있거나 stable-link/raw-path nondisclosure가 불완전하면 `PASS` 금지다.

## 결과 전달

PR #2 top-level Conversation에 다음 marker로 결과를 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_CORE_RULES_PRIVATE_LINK_FIX_RESULT -->
```

최소 포함:

- commandId
- targetShaAtStart
- resultHeadSha
- resultStatus
- changed files
- in-root document/fragment normalization evidence
- duplicate-anchor evidence
- missing-local/sourceRoot-escape nondisclosure evidence
- relatedLinks/backlinks reciprocity evidence
- synthetic private runtime pipeline result
- focused validators
- current-head GitHub Actions
- Studio/Human `NOT_EXECUTED`
- remaining Final Contract gaps

## 증거 경계

```text
Source/Static/Build evidence만 이번 Codex 작업 범위
Real private corpus Studio Runtime = NOT_EXECUTED
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
Multi-client Runtime = NOT_EXECUTED
Persistence Runtime = DEFERRED
Performance/Soak = PENDING
```

Studio/Human 실행은 아직 요청하지 않는다.
