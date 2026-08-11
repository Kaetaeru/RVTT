# RVTT Execution State

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-STUDIO-RETEST-HARNESS-FIX-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `FOCUSED_ACCEPTANCE_HARNESS_REPAIR`
- executionMode: `CODEX_IMPLEMENTATION_CHATGPT_VERIFICATION`
- phase: `RUNTIME_ENTRY_PREFLIGHT_EXPLORATION_CONTEXT_INPUT`
- commandPath: `.github/CODEX-FIX-STUDIO-RETEST-HARNESS-002.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_002_RESULT -->`
- resultStatus: `PENDING`
- broadStaticVerifiedHead: `15711da15225a19e43f54827fabcd8fa0ca0995a`
- harnessFix001ResultHead: `8c8355367729d45555c4143450b91155a943db21`
- commandFileCommit: `45f58f6d1d878d81d806554f4619a27936583615`
- phase9Status: `FINAL_PASS`
- phase10Status: `BROAD_CURRENT_HEAD_STATIC_PASS`
- sourceStaticFinalContractGaps: `0`
- assetRegistryAcceptanceState: `STATIC_PASS`
- rulesProfileReleaseAcceptanceState: `STATIC_PASS`
- coreRulesReaderAcceptanceState: `FINAL_STATIC_PASS`
- officialCharacterSheetAcceptanceState: `FINAL_STATIC_PASS`
- diceSlotRevealNoticeState: `FINAL_STATIC_PASS`
- runtimeEntryPreflightState: `HARNESS_FIX_002_REQUIRED`
- explorationContextStudioRetestState: `NOT_EXECUTED`
- multiClientAttackEvidenceState: `NOT_EXECUTED`
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

이 Source/Static 판정은 유지한다. 현재 blocker는 사용자 Runtime 진입용 Acceptance Harness의 정확성이다.

## FIX-001 독립 검증 결과

FIX-001 result HEAD `8c8355367729d45555c4143450b91155a943db21`에서 다음은 정상적으로 수정됐다.

```text
middle-button actual evidence = orbit / mouse-middle-screen-delta
WASD evidence = pan / keyboard-wasd
fake acceptance pan shim = removed
ESC gameplay no-op evidence = added
Q context-cancel one-context evidence = added
PR-bound exact branch/head build rule = added
current-head Actions = success
```

하지만 ChatGPT는 사용자 Studio 실행 전에 두 Harness blocker를 추가 발견했다.

### Blocker A — visible instruction drift

World batch 실제 check는 Orbit으로 고쳐졌지만 화면 안내 문구는 아직 middle-drag를 `Pan`이라고 표시한다.

### Blocker B — invalid single-client DM attack gate

Single-client Context batch는 DM으로 실행한다. Production authority상 DM은 scene actors를 control하므로 Dummy도 controllable target이다.

Production resolver/input semantics상:

```text
DM-controllable target
→ hostile attack action table 대상이 아님
→ left click은 default attack보다 controllable actor selection을 우선
```

따라서 현재 G1의 `attack-menu` / `attack-default` 필수 체크는 정상 Production에서 구조적으로 false-fail할 수 있다.

Production 권한 모델을 테스트에 맞춰 약화하면 안 된다.

## 활성 작업

Codex는 가장 먼저 아래 명령을 읽고 그대로 실행한다.

```text
.github/CODEX-FIX-STUDIO-RETEST-HARNESS-002.md
```

핵심 범위:

```text
World visible instruction: WASD=Pan / middle-drag=Orbit로 정정
+ G1 single-client DM에서 attack-menu / attack-default gate 제거
+ combat-only Dummy/manual instruction 제거 또는 비게이팅화
+ Player-vs-hostile attack runtime evidence를 G2 STUDIO_MULTI_CLIENT로 정직하게 이관
+ Production controlsActor / selection precedence 변경 금지
+ validator negative regression 강화
+ current-head Actions
```

## 성공 조건

```text
G1 = 실제 single-client DM에서 도달 가능한 Exploration/Context/Camera/Q/ESC만 gate
G2 = Player role + uncontrolled/hostile target attack evidence가 NOT_EXECUTED 상태로 명시 보존
Production authority semantics unchanged
Broad/focused validators PASS
Implementation validation PASS
Current result HEAD Actions all completed/success
Studio/Human/Multi-client still NOT_EXECUTED
```

Codex 완료 후 ChatGPT가 결과 diff를 독립 검증한다.

그 검증이 PASS하면 추가 Source 기능 작업 없이 바로 사용자 Studio Batch를 시작한다.

```text
Exploration · Context Input Studio Retest
```

그때 ChatGPT가 verified result HEAD에 고정된 전체 Windows PowerShell build block, 실제 입력 순서, PASS Output token을 제공한다.

## 범위 밖

- Production input grammar 변경
- DM authority 축소
- Player role fake injection
- Studio/MCP/Human 실행
- G2 Multi-client 실제 실행
- Persistence Runtime
- ADR-0092 Production
- force push
- merge / ready-for-review

## 결과 전달

PR #2 top-level Conversation에:

```text
<!-- RVTT_CODEX_STUDIO_RETEST_HARNESS_FIX_002_RESULT -->
```

Codex는 `STUDIO_PASS`, `MULTI_CLIENT_PASS`, `HUMAN_PASS`, `RUNTIME_PASS`, `MERGE_READY`, `FINAL_RELEASE_PASS`를 쓰지 않는다.
