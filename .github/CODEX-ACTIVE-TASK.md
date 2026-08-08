# RVTT Execution State

- status: `NO_ACTIVE_CODEX_TASK`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- executionMode: `CHATGPT_DIRECT_GITHUB_IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_2_ADR0091_FINAL_CONTRACT_GAPS`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION,RULES_PROFILE_RELEASE_ENFORCEMENT,CORE_RULES_READER,PRIVATE_RULES_READER_IMPORT_OVERLAY_REPAIR`
- lastCompletedDirectWork: `ADR0091_PRIVATE_RULES_READER_IMPORT_OVERLAY_REPAIR`
- nextDirectWork: `ADR0091_OFFICIAL_2024_CHARACTER_SHEET`
- remainingFinalContractGaps: `2`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `BLOCKED`
- studioHumanRetestState: `NOT_STARTED_CURRENT_CONTRACT`
- humanUiUxState: `NOT_EXECUTED`
- updatedBy: `ChatGPT Direct GitHub Implementation`
- updatedAt: `2026-08-09`

## 현재 실행 방식

Codex token budget을 사용하지 않는다. 사용자가 별도로 Codex 사용을 다시 요청하기 전까지 ChatGPT가 GitHub connector를 사용해 다음 흐름을 직접 수행한다.

```text
latest PR HEAD 확인
→ Authority / Source 분석
→ Production Source·Test·Validator 직접 수정
→ current-head GitHub Actions 확인
→ PASS/HOLD 판정
```

사용자에게 Roblox Studio 실행을 요청하는 시점은 남은 ADR-0091 Source gap을 모두 닫고 별도의 새 current-HEAD Static Gate가 PASS한 뒤다.

## 완료된 Core Rules Reader correction

```text
RuleLink stable URI
+ RuleReaderService viewer filtering
+ manifest/search/open/chunk query boundary
+ lazy chunk client cache
+ Journal Core Rules 3-column reader
+ >200k synthetic corpus lazy-load regression
+ unauthorized title/count/snippet/link/body nondisclosure
+ Session authoritative role marker wiring
+ Core Rules Reader acceptance validator
+ pinned private integrated subtree digest
+ private Markdown importer with revision/digest/count/dirty-source fail-closed validation
+ temporary RuleContentPackage + localized search index generation
+ generated Rojo project injecting ServerStorage.RVTTPrivateRuleContent
+ explicit server-only authorized-user allowlist
+ private profile query nondisclosure before rule service access
+ fail-closed private Studio build entry point
+ public-safe synthetic importer/preparer/overlay Rojo-build CI regression
```

`rvtt.core.rules` repository package는 현재 공개-safe Reader Guide만 포함한다. private integrated Korean rule body와 generated Rule Chunk는 public Git tree에 포함하지 않는다.

Private integrated Studio build는 `RVTT_PRIVATE_DND2024_KO_SOURCE`와 `RVTT_PRIVATE_RULES_AUTHORIZED_USER_IDS`가 모두 있어야 하며, pinned revision·source subtree digest·12/48/16/10/75/391 count가 일치하지 않거나 source root가 dirty이면 fail closed한다. 검증된 import는 RVTT Git tree 밖의 임시 workspace에만 생성되고 generated Rojo overlay를 통해 `RVTTPrivateRuleContent/Readiness`와 `RuleReaderPackage`를 ServerStorage에 주입한다.

Public GitHub Actions는 private repository나 private rule body를 읽지 않는다. 대신 동일 importer/preparer 경로를 synthetic private Git fixture로 실행해 generated ModuleScript binding과 Rojo overlay build, revision/digest/count/dirty/missing-source, missing viewer allowlist의 fail-closed 회귀를 검사한다. 이는 Source/Static·Build evidence이며 실제 private corpus Studio Runtime evidence가 아니다.

## 남은 Phase 10 ADR-0091 gap

1. `final.official-2024-sheet-interactions`
2. `final.dice-slot-reveal-notice`

다음 직접 구현은 Official 2024 Character Sheet다. 두 gap을 모두 닫은 뒤 Acceptance Matrix를 재검증하고 별도의 new current-HEAD Static Gate를 실행한다.

## 증거 경계

```text
Core Rules Reader Source/Static = implemented and current-head CI verified
Private importer synthetic generated-overlay Build = current-head CI verified
Real private corpus Studio Runtime = NOT_EXECUTED
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
Multi-client Runtime = NOT_EXECUTED
Persistence Runtime = DEFERRED
Performance/Soak = PENDING
```

상태 문서 변경 후의 최종 current HEAD Actions도 다시 모두 성공해야 최종 Static PASS로 인정한다.
