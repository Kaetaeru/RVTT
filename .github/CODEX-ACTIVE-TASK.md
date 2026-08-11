# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-STUDIO-RETEST-HARNESS-FIX-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_ACCEPTANCE_HARNESS_REPAIR`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `RUNTIME_ENTRY_PREFLIGHT_EXPLORATION_CONTEXT_INPUT`
- commandPath: `.github/CODEX-FIX-STUDIO-RETEST-HARNESS-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_001_RESULT -->`
- resultStatus: `PENDING`
- broadStaticVerifiedHead: `15711da15225a19e43f54827fabcd8fa0ca0995a`
- commandFileCommit: `700c660df5f274f510f41a9fdb8ed99f3d83bfae`
- phase9Status: `FINAL_PASS`
- phase10Status: `BROAD_CURRENT_HEAD_STATIC_PASS`
- sourceStaticFinalContractGaps: `0`
- assetRegistryAcceptanceState: `STATIC_PASS`
- rulesProfileReleaseAcceptanceState: `STATIC_PASS`
- coreRulesReaderAcceptanceState: `FINAL_STATIC_PASS`
- officialCharacterSheetAcceptanceState: `FINAL_STATIC_PASS`
- diceSlotRevealNoticeState: `FINAL_STATIC_PASS`
- runtimeEntryPreflightState: `HARNESS_REPAIR_REQUIRED`
- explorationContextStudioRetestState: `NOT_EXECUTED`
- studioRuntimeState: `NOT_EXECUTED`
- humanUiUxState: `NOT_EXECUTED`
- persistenceRuntimeState: `NOT_EXECUTED_DEFERRED`
- nextRuntimeOnVerifiedSuccess: `EXPLORATION_CONTEXT_INPUT_STUDIO_RETEST`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-11`

## ChatGPT Broad Static 판정

ChatGPT는 HEAD `15711da15225a19e43f54827fabcd8fa0ca0995a`에서 다음을 최종 확인했다.

```text
ADR-0091 Source/Static = PASS
Full UI/UX Broad Static Gate = PASS
Final Contract Gaps = 0
Studio/Human = NOT_EXECUTED
```

따라서 기능 구현 Gate는 종료됐고 Runtime lane으로 진입한다.

## Studio 진입 직전 발견된 Harness drift

실제 사용자 Batch를 열기 전에 Acceptance Harness를 production input contract와 대조한 결과 다음 stale test semantics를 확인했다.

```text
Production: middle-button drag = Orbit
WorldTokenAcceptance: middle-button = camera-pan 기대

Production: Q = one-context Cancel/Back
Production: ESC = gameplay no-op
ContextInputAcceptance 안내: Esc로 action table 닫기
```

이 상태에서 사용자에게 Studio를 실행시키면 정상 Production도 Harness가 false-fail할 수 있으므로, 먼저 Acceptance Harness만 수리한다.

Production input behavior 자체를 stale harness에 맞춰 바꾸지 않는다.

## 활성 작업

Codex는 가장 먼저 아래 명령을 읽고 그대로 실행한다.

```text
.github/CODEX-FIX-STUDIO-RETEST-HARNESS-001.md
```

핵심 범위:

```text
World batch middle-drag Orbit 정합화
+ WASD Pan과 Orbit 분리 유지
+ Context batch Q close 실제 evidence
+ ESC gameplay no-op 실제 evidence
+ stale Esc 안내 제거
+ PR-bound exact-branch Studio Batch 실행 규칙
+ validator negative regression
+ current-head Actions
```

## 성공 조건

```text
Harness current input grammar 정합
Broad/focused validators PASS
Implementation validation PASS
Current result HEAD Actions all completed/success
Studio/Human still NOT_EXECUTED
```

Codex 완료 후 ChatGPT가 결과 diff를 독립 검증한다.

그 검증이 PASS하면 **추가 Source 기능 작업 없이 바로 사용자 Studio Batch를 시작**한다.

```text
Exploration · Context Input Studio Retest
```

그때 ChatGPT가 current verified result HEAD에 고정된 전체 Windows PowerShell build block과 수동 입력 순서를 사용자에게 제공한다.

## 범위 밖

- Production input grammar 변경
- ADR-0091 기능 재설계
- Studio/MCP/Human 실행
- Persistence Runtime
- Multi-client Runtime
- ADR-0092 Production
- force push
- merge / ready-for-review

## 결과 전달

PR #2 top-level Conversation에:

```text
<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_001_RESULT -->
```

Codex는 `STUDIO_PASS`, `HUMAN_PASS`, `RUNTIME_PASS`, `MERGE_READY`를 쓰지 않는다.
