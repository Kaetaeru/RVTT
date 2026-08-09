# RVTT Agent Test Status

- 상태: `ACTIVE`
- 최종 갱신일: `2026-08-10`
- 목적: 새 에이전트가 저장소를 열었을 때 현재 구현·테스트 진행 상태, 다음 Gate, 남은 사용자 Runtime 범위를 한눈에 확인하게 한다.
- 적용 범위: RVTT 구현·Runtime·Acceptance·검증·Release 작업

> 이 문서는 **현재 상태 대시보드**다. 테스트 정의나 구현 순서의 원본을 대체하지 않는다.
> 현재 작업 순서는 `implementation/roblox/CURRENT-WORK-ORDER.md`를 따르고,
> 테스트 상세 계약은 `implementation/roblox/EXECUTION-TEST-RULES.md`, `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md`, `implementation/roblox/grand-acceptance-manifest.json`을 따른다.

---

## 1. 에이전트 필수 규칙

RVTT에서 구현, 테스트, 검증, Acceptance, Release 관련 작업을 하는 모든 에이전트는 다음을 지킨다.

1. 작업 시작 시 루트 `AGENTS.md` 다음으로 이 파일과 `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
2. 현재 구현 단계와 테스트 단계가 각각 `PASS`, `FAIL`, `BLOCKED`, `DEFERRED`, `PENDING`, `IN_PROGRESS` 중 무엇인지 확인한 뒤 작업한다.
3. 테스트를 실제 수행했거나 테스트 가능 상태, 다음 Gate, 구현 선행조건이 바뀌었으면 **같은 작업에서 이 파일도 갱신**한다.
4. 테스트를 실행하지 않았으면 `PASS`로 바꾸지 않는다.
5. Static·Build·Lint·Type PASS를 Studio Runtime PASS로 확대하지 않는다.
6. 일반 Runtime PASS를 Persistence, Multi-client, Accessibility, Performance, Full Release PASS로 확대하지 않는다.
7. 결과를 갱신할 때 최소한 테스트 대상 Head/SHA, 실행일, 결과, 실패 또는 Blocker, 다음 행동을 남긴다.
8. 세부 체크 항목을 새로 정의하거나 변경할 때는 먼저 원본 작업 순서·테스트 문서를 수정하고, 이 문서는 그 상태만 요약한다.
9. 사용자에게 작은 변경마다 Studio 실행을 요구하지 않는다. `EXECUTION-TEST-RULES.md`의 Batch Acceptance 원칙을 따른다.
10. 이 파일이 `CURRENT-WORK-ORDER.md`나 Grand Manifest와 충돌하면 원본을 기준으로 확인하고 이 파일을 즉시 정정한다.

---

## 2. 현재 구현·검증 역할

현재 운영 결정:

```text
ChatGPT Direct GitHub Implementation
→ Authority·Source 확인
→ Production Source·Test·Validator 직접 수정
→ current-head GitHub Actions 확인
→ Static PASS/HOLD 판정

사용자 직접 확인
→ Roblox Studio 실행
→ 실제 화면·입력·조작
→ Play Runtime
→ UI·UX
→ Output 확인
→ 기능 동작·플레이 감각
```

사용자가 `.github/CODEX-ACTIVE-TASK.md`의 최신 명령 실행을 명시적으로 요청해 `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001` Source·Static 경로를 Codex가 수행했다. 결과는 PR #2 top-level Conversation에 기록하며 Studio·Human Runtime은 이번 명령에서 실행하지 않는다.

기본적으로 **Codex ↔ Roblox Studio MCP 자동 Smoke를 필수 사용자 흐름으로 사용하지 않는다.** Studio MCP 자동화는 반복 작업 절감 효과가 명확하거나 사용자가 다시 명시적으로 요청할 때만 사용한다. Runtime 테스트를 생략한다는 뜻은 아니며 Studio Runtime 검증은 Batch 기반 사용자 직접 확인으로 진행한다.

---

## 3. 현재 상태 한눈에 보기

| 영역 | 상태 | 현재 판정 |
|---|---|---|
| ADR/설계 및 Studio Preflight 문서 검수 | `PASS` | 마지막 Codex Delta 결과 `NO_SUPPORTED_FINDINGS` |
| 마지막 별도 Implementation Static Gate | `PASS` | 역사적 검증 대상 `ef99a0740711b4f00fac0d5c8d0599f238ea48e9` |
| Full UI·UX Source·Acceptance 정합화 | `PARTIAL` | Dice presentation repair 로컬 구현 완료, ChatGPT 독립 검증 전 Matrix Gap 1개 보존 |
| ADR-0091 Asset Registry foundation | `STATIC_VERIFIED` | Source·Server·Client-safe 경계, validation·negative disclosure focused regression |
| ADR-0091 Rules Profile + Release Leak Gate | `STATIC_VERIFIED` | Builtin package single authority·private readiness·explicit fallback·actual filesystem staging·CI fail-closed regression |
| ADR-0091 Core Rules Reader | `STATIC_VERIFIED` | private in-root/README/fragment/duplicate stable link·missing/out-of-root raw-path nondisclosure·reciprocal backlink·deterministic import + lazy/viewer filtering regression |
| ADR-0091 Official 2024 Character Sheet | `STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION` | server-resolved roll semantics·active Content definition hydration·canonical attack parity·all-row equipment/details/send·structured slots·out-of-order receipt safety focused validation |
| ADR-0091 Dice Slot Reveal Notice | `BLOCKED_PENDING_CHATGPT_VERIFICATION` | 실제 slot/tween/critical/reduced-motion/dual connector + server challenge mode repair 구현, 독립 검증 전 HOLD |
| Shared Shell·Preference Foundation | `PASS` | `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002` 구현·로컬 정적 검증 완료 |
| Input·Context Action 정합화 | `PASS` | `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001` 구현·로컬 정적 검증 완료 |
| Exploration·Encounter HUD | `PASS` | `RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001` 구현·로컬 정적 검증 완료 |
| Inventory·Journal·Settings | `PASS` | `RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001` Source·Static 완료 |
| Entry·Role·Recovery | `PASS` | `RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001` Source·Static 완료 |
| DM Live Workspace | `PASS` | `RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001` Source·Static 완료 |
| Full UI·UX Acceptance 확장 | `HOLD` | 49개 항목 등록, 보수적 final-contract Gap 1개, Dice 독립 검증 필요 |
| 현재 사용자 Studio Human Retest | `BLOCKED` | Dice 독립 검증 + 새 current-HEAD 전체 Static Gate 재검증이 먼저 |
| Codex Studio MCP Smoke | `NOT_DEFAULT` | 현재 운영에서는 사용자 수동 Runtime으로 대체 |
| 일반 Runtime 실행 그룹 | `0 / 3 PASS` | G1도 아직 실행 가능 상태가 아님 |
| Persistence 실행 그룹 | `0 / 7 PASS` | 전용 Milestone까지 `DEFERRED` |
| UI Visual / Accessibility Human Review | `PENDING` | Studio Retest 이후 |
| Performance / Soak / Capacity | `PENDING` | Runtime Evidence 이후 |
| Full-session Release Gate | `PENDING` | 선행 Gate 미완료 |

### 마지막 검증된 구현 Snapshot

```text
PR: #2
branch: agent/survival-logistics-token-authoring
staticGateTargetSha: ef99a0740711b4f00fac0d5c8d0599f238ea48e9
staticGate: PASS · HISTORICAL_SEPARATE_GATE
phase4Implementation: PASS · RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002
phase4LocalStaticValidation: PASS
phase5Implementation: PASS · RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001
phase5TargetShaAtStart: 8002f7e64f0325da048ceff8a02958088c56d393
phase5LocalStaticValidation: PASS · validator + format + lint + 15 Rojo builds + default/test sourcemaps + production/test Luau analysis
phase6Implementation: PASS · RVTT-PR2-EXPLORATION-ENCOUNTER-HUD-IMPLEMENTATION-001
phase6TargetShaAtStart: c1896af5e8cfa4cc80b6b37445beb998e77a0b13
phase6LocalStaticValidation: PASS · validator + format + lint + 15 Rojo builds + default/test sourcemaps + production/test Luau analysis
phase7Implementation: PASS · RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001
phase7TargetShaAtStart: ebe282604fb7140a8acb31b2268c31f45702045e
phase7LocalStaticValidation: PASS · validators + format + lint + 15 Rojo builds + default/test sourcemaps + production/test Luau analysis
phase8Implementation: PASS · RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001
phase8TargetShaAtStart: 7f1d63e29cd6f3b6dc7097f5a2c45be8c6388c49
phase8LocalStaticValidation: PASS · validator + format + lint + 15 Rojo builds + default/test sourcemaps + production/test Luau analysis
phase9Implementation: PASS · RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001
phase9TargetShaAtStart: 2673f7d65ff42ae19c08eb14ae5ac44963fad95b
phase9LocalStaticValidation: PASS · validators + format + lint + 15 Rojo builds + default/test sourcemaps + production/test Luau analysis
phase9ReconciliationFix: PASS · RVTT-PR2-PHASE9-QUEUE-RECONCILIATION-001
phase9ReconciliationTargetShaAtStart: b70eb0aa34dc4a09270e0ed2c51e6cbd83d512db
phase9ReconciliationLocalStaticValidation: PASS · recovery/control/terminal-feedback focused regression + validators + format + lint + 15 Rojo builds + default/test/multi-client sourcemaps + production/test Luau analysis
phase9ControlRevisionFix: PASS · RVTT-PR2-PHASE9-CONTROL-REVISION-FIX-001
phase9ControlRevisionTargetShaAtStart: 068b6f35a5f4db2e527ad64ee30e6d9310b47a13
phase9ControlRevisionLocalStaticValidation: PASS · same/base-revision guard + cases A-D + previous reconciliation regressions + validators + format + lint + 15 Rojo builds + default/test/multi-client sourcemaps + production/test Luau analysis
newCurrentHeadStaticGate: REQUIRED_BEFORE_STUDIO
studioManualRuntimeCurrentContract: NOT_EXECUTED
humanPlaytestCurrentContract: NOT_EXECUTED
phase10AcceptanceTargetShaAtStart: e20853c3bc1e36fb78a1888809e13a8c8577ebb0
phase10AcceptanceRegistration: PARTIAL · 49 items · 12 batches · 1 pending-verification final-contract gap
phase10AssetRegistryCommand: RVTT-PR2-ADR0091-ASSET-REGISTRY-IMPLEMENTATION-001
phase10AssetRegistryTargetShaAtStart: 4321d104a597e530bf57748874ce42b13c42c1c4
phase10AssetRegistryStaticValidation: PASS · empty production registry + source/server/client-safe boundary + 11 focused fixtures
phase10RulesProfileCommand: RVTT-PR2-ADR0091-RULES-PROFILE-LEAK-GATE-IMPLEMENTATION-001
phase10RulesProfileTargetShaAtStart: 899292844d58b4c691dffbf2ff9ce84de4104005
phase10RulesProfileStaticValidation: SUPERSEDED_PARTIAL · in-memory gate existed, but package metadata duplication and filesystem/CI enforcement remained
phase10RulesReleaseEnforcementFixCommand: RVTT-PR2-ADR0091-RULES-PROFILE-RELEASE-ENFORCEMENT-FIX-001
phase10RulesReleaseEnforcementTargetShaAtStart: d23b47b1ad6b8f8804e59b146b59eb1a68933c6c
phase10RulesReleaseEnforcementStaticValidation: PASS · BuiltinPackIndex-derived readiness + injectable drift fixtures + deterministic filesystem staging inventory + CI nonzero gate
phase10CoreRulesReaderExecutionMode: CHATGPT_DIRECT_GITHUB_IMPLEMENTATION
phase10CoreRulesReaderStaticValidation: PASS · focused validator + StyLua + Selene + all required Rojo builds/sourcemaps + production/tests Luau analysis
phase10CoreRulesPrivateStableLinkFixCommand: RVTT-PR2-ADR0091-CORE-RULES-PRIVATE-STABLE-LINK-FIX-001
phase10CoreRulesPrivateStableLinkFixTargetShaAtStart: 783bce4e20aa2c1a843cdabf2b7937b45af7a9eb
phase10CoreRulesPrivateStableLinkLocalValidation: PASS · public-safe synthetic document/README/fragment/duplicate graph + missing/out-of-root/invalid-link nondisclosure + reciprocal backlinks + deterministic double import + focused/full validators + 15 Rojo builds + 3 sourcemaps + production/tests Luau analysis + PowerShell SelfTests
phase10CoreRulesReaderRuntime: NOT_EXECUTED
phase10OfficialCharacterSheetCommand: RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001
phase10OfficialCharacterSheetTargetShaAtStart: 67386abeba817faaea3c0031f6fc57735a977016
phase10OfficialCharacterSheetLocalStaticValidation: PASS · authoritative projection/viewmodel/layout/command/focused validator + Rojo builds/sourcemaps + Luau analysis; Studio/Human NOT_EXECUTED
phase10OfficialCharacterSheetState: IMPLEMENTED_PENDING_CHATGPT_VERIFICATION
phase10OfficialCharacterSheetAuthorityRepairCommand: RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-002
phase10OfficialCharacterSheetAuthorityRepairTargetShaAtStart: 6ee5cc953fdfe3015f18edb9a5ee5dd2318cbbe5
phase10OfficialCharacterSheetAuthorityRepairLocalStaticValidation: PASS · server-owned Content character/item definition hydration + forged roll semantics/domain negatives + canonical ActorProfile attacks + exact header/left/right information structure + all equipment rows/popover/details/authorized send targets + structured slots + out-of-order receipt regression + strengthened validator + 15 Rojo builds + 3 sourcemaps + production/tests Luau analysis
phase10OfficialCharacterSheetAuthorityRepairStudioHuman: NOT_EXECUTED
phase10OfficialCharacterSheetEligibilityRepairCommand: RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-003
phase10OfficialCharacterSheetEligibilityRepairTargetShaAtStart: 7bda8950d703028606d8a46404461fad13dc375d
phase10OfficialCharacterSheetEligibilityRepairLocalStaticValidation: PASS · atomic finite Hit Die consumption/exhaustion + trusted equipSlot and character-location enforcement + hotbar capability/character relation enforcement + attack fallback non-invention + focused negative regressions + strengthened validator/self-tests + public release leak gate + StyLua + 15 Rojo builds + 3 sourcemaps + production/tests Luau analysis; Selene delegated to current-head Actions
phase10OfficialCharacterSheetEligibilityRepairStudioHuman: NOT_EXECUTED
phase10DiceSlotRevealNoticeCommand: RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-001
phase10DiceSlotRevealNoticeTargetShaAtStart: 276ceb267fb01cd5adfd1e0c19ebf51bbba7ec0e
phase10DiceSlotRevealNoticeLocalStaticValidation: PASS · server projection authority + exact reveal state/timing + advantage/disadvantage appliedIndex + semantic critical presentation + reduced motion + FIFO/stack/dedupe/stale/reconnect + nondisclosure + focused/full validators + public release leak gate + private synthetic pipeline + 15 Rojo builds + 3 sourcemaps + production/tests Luau analysis; Selene delegated to current-head Actions
phase10DiceSlotRevealNoticeState: STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
phase10DiceSlotRevealNoticeStudioHuman: NOT_EXECUTED
phase10DiceSlotRevealNoticePresentationRepairCommand: RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-FIX-002
phase10DiceSlotRevealNoticePresentationRepairStartHead: 4738b890b56cca18922714a5604f7fd9e787a95b
phase10DiceSlotRevealNoticePresentationRepairLocalValidation: PASS · actual TweenService slot strip/formula expansion/Natural 1+20/reduced motion/applied connector + production challenge advantage/disadvantage + component-focused regression + hardened negative validator + public release leak gate + private synthetic pipeline + changed-file StyLua + 15 Rojo builds + 3 sourcemaps + production/tests Luau analysis; Selene delegated to current-head Actions
phase10DiceSlotRevealNoticeMatrixState: BLOCKED · pending ChatGPT independent verification
phase10StudioRuntime: NOT_EXECUTED
phase10HumanEvidence: NOT_EXECUTED
phase10Next: CHATGPT_DICE_PRESENTATION_VERIFICATION_THEN_BROAD_CURRENT_HEAD_STATIC_REVALIDATION
```

`ef99a07...` Static PASS는 역사적 증거로 유지한다. Dice presentation repair는 구현됐지만 ChatGPT 독립 검증 전 Matrix는 `BLOCKED`와 Gap 1개를 보존한다. 검증 성공 뒤에도 Studio Human Retest 전에는 **별도의 새 current-HEAD 전체 Static Gate를 다시 통과해야 한다.** focused Source/Static 성공은 전체 제품 Runtime PASS가 아니다.

---

## 4. 현재 작업 순서 — Studio를 아직 켜지 않는다

현재 Authority인 `implementation/roblox/CURRENT-WORK-ORDER.md`의 순서는 다음과 같다.

```text
Shared Shell·Preference Foundation
→ Input·Context Action 정합화
→ Exploration·Encounter HUD
→ Inventory·Journal·Settings
→ Entry·Role·Recovery
→ DM Live Workspace
→ Acceptance 확장
→ Dice presentation ChatGPT 독립 검증
→ 새 current-HEAD Static Gate
→ Exploration·Context Input Studio Human Retest
→ UI·Accessibility Evidence
→ DM·Player·Observer Test
→ Grand Persistence Runtime
→ Performance·Soak
→ Slice 16 Release Campaign
```

따라서 **현재는 사용자에게 Studio 실행을 요청하지 않는다.** `Studio Human Retest`는 새 Head의 전체 Static Gate가 PASS했을 때만 `PENDING/READY`로 전환한다.

---

## 5. 사용자 직접 Runtime 테스트 횟수

현재 사용자 관점의 핵심 Runtime 실행 그룹은 **총 10개**로 관리한다.

```text
일반 Runtime 3개
+
Persistence Runtime 7개
=
총 10개 실행 그룹
```

Grand Manifest의 내부 Phase 수와 사용자에게 요구하는 실행 횟수는 동일하지 않다. 여러 내부 Phase와 Assertion은 하나의 Batch 실행에서 함께 검증할 수 있다.

### 일반 Runtime — 3개

| # | 실행 그룹 | 범위 | 상태 |
|---:|---|---|---|
| G1 | Grand Single-client | Unit·Integration baseline + 최신 Slice 01/Direct Play 실제 입력 + Slices 02–12 자동 Authority Scenario | `BLOCKED` — UI·UX/Acceptance 정합화 선행 |
| G2 | Grand Multi-client | DM·Player·Observer 권한, Projection, Negative Disclosure, Stale Revision | `PENDING` |
| G3 | Grand Real Transport | 실제 Player 종료·재접속·Full Sync | `PENDING` |

### Persistence Runtime — 7개

| # | 실행 그룹 | 범위 | 상태 |
|---:|---|---|---|
| P1 | Live DataStore Baseline | 실제 DataStore 기본 Load·Save | `DEFERRED` |
| P2 | Restart Seed | Shutdown Dirty Snapshot·Flush Seed | `DEFERRED` |
| P3 | Restart Verify | Fresh Server Restore·Epoch Rotation·Stale 거부 | `DEFERRED` |
| P4 | Injected DataStore Outage | Retry 고갈·Dirty 보존·복구 | `DEFERRED` |
| P5 | Cross-server Lease Pair | Holder·Contender 충돌·Renew·Takeover·Fencing | `DEFERRED` |
| P6 | Production Lease Seed | Production ServerBoot·Lease·Fenced Flush | `DEFERRED` |
| P7 | Production Lease Verify | Higher Fence Restore·Stale Writer 거부·Cleanup | `DEFERRED` |

Persistence 7개는 `GRAND-ACCEPTANCE-CAMPAIGN.md`의 Persistence 전용 Milestone에서만 진행한다. 일반 기능 테스트에서 DataStore를 억지로 함께 검증하지 않는다.

---

## 6. 다음 사용자 Human Retest 체크리스트 — 준비 중

아래 체크리스트는 `CURRENT-WORK-ORDER.md`의 Acceptance 재작성 범위다. **현재 상태는 `BLOCKED / NOT READY`이며 아직 실행하지 않는다.** 남은 ADR-0091 Source correction과 새 current-HEAD Static Gate가 끝나면 G1 Runtime에 포함해 한 번의 Batch로 확인한다.

### Input·Direct Play — 11개

- [ ] 1. ESC가 Gameplay 의미를 가지지 않는다.
- [ ] 2. Q가 최상위 Context를 한 단계씩 닫거나 취소한다.
- [ ] 3. 조작 가능한 아군 좌클릭으로 선택이 전환된다.
- [ ] 4. 기본 행동이 클릭 전에 Cursor·Outline·Label 등으로 표시된다.
- [ ] 5. Action Table에서 현재 가능한 행동과 불가능한 행동이 구분된다.
- [ ] 6. 비활성 행동 Hover·Focus에서 불가능한 이유가 표시된다.
- [ ] 7. 권한 밖이거나 인지하지 못한 Action은 노출되지 않는다.
- [ ] 8. 중클릭 Camera Orbit이 정상 동작한다.
- [ ] 9. 이동·공격·범위 Preview가 실제 실행 전에 표시된다.
- [ ] 10. 행동 후 Selection이 유지되고 Camera가 강제로 이동하지 않으며 Soft Focus 계약을 따른다.
- [ ] 11. Pending·Denied·Stale·Projection Revision 상태가 일관되게 표시된다.

### Screen·Preference — 8개

- [ ] 12. Exploration·Encounter Mode Composition이 명세와 맞다.
- [ ] 13. Inventory·Loot·Transfer·Identification 흐름이 맞다.
- [ ] 14. Journal Permission·Document Navigation이 권한과 명세를 따르며 별도 Player Map을 요구하지 않는다.
- [ ] 15. Core Rules Reader에서 검색·stable anchor·lazy chunk·viewer filtering이 실제 Runtime에서도 정상이다.
- [ ] 16. Settings 초기값·Reset·Binding Conflict가 정상이다.
- [ ] 17. Accent·Scale·Motion 변경 중 Focus·Selection이 유지된다.
- [ ] 18. Entry·Role Change·Reconnect·Recovery 흐름이 정상이다.
- [ ] 19. Player·DM·Observer Projection이 서로 올바르게 분리된다.

### 현재 판정 기록

```text
status: BLOCKED
testedHead: NOT_EXECUTED
testedAt: NOT_EXECUTED
tester: USER_MANUAL
result: NOT_EXECUTED
passedChecks: 0
failedChecks: 0
blockedChecks: 19
blocker: Dice Notice independent verification + new current-HEAD Static Gate required
next: ChatGPT Dice presentation verification
```

### Historical Studio Evidence — 현재 계약 PASS로 사용 금지

```text
historicalHead: 582c1c4
historicalResult: [RVTT Batch Summary] batch=slice01-world-interaction result=PASS passed=16 failed=0 pending=0 revision=12
scope: old Camera·Token Pick·Move·Projection input contract only
```

이 Historical PASS는 새 Pointer, Screen Shell, Settings, Accessibility, Role/Recovery, Core Rules Reader 계약의 Runtime Evidence가 아니다.

---

## 7. 이후 예정 범위

현재 10개 Runtime 실행 그룹 외에도 Release까지 다음 품질·기능 검증이 남아 있다.

- Slice 02–12 전체 사용자 흐름·Disclosure·Recovery 보강
- Slice 13–15 공식 Content 권리·Asset·Production Catalog
- UI Visual Redesign·Human Review
- Accessibility Evidence
- Network/Storage/Restart 추가 Fault Evidence
- Performance Budget
- Memory·Network·Capacity·Soak
- Slice 16 Full-session Release Hardening

---

## 8. 상태 갱신 형식

테스트 결과가 바뀌면 최소 다음 형식을 남긴다.

```text
Test/Batch: <id or name>
Target Head: <sha>
Executed At: <YYYY-MM-DD>
Executor: USER_MANUAL | CHATGPT_DIRECT | CODEX | CI | OTHER
Result: PASS | FAIL | BLOCKED | DEFERRED | PARTIAL
Passed: <n>
Failed: <n>
Blocked: <n>
Evidence: <log/report/screenshot path or summary>
Failure/Blocker: <none or concise reason>
Next: <next required action>
```

실패를 수정한 뒤에는 기존 실패 기록을 지우지 말고, 최신 결과와 재검증 여부가 보이게 남긴다.

---

## 9. 원본 상태·테스트 문서

현재 Authority:

- `implementation/roblox/CURRENT-WORK-ORDER.md` — 현재 구현·검증 순서
- `implementation/roblox/EXECUTION-TEST-RULES.md` — Batch Acceptance 운영 규칙
- `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md` — Grand Runtime 실행 모델
- `implementation/roblox/grand-acceptance-manifest.json` — Runtime Phase Manifest
- 필요 시 개별 Acceptance Project와 Runner
