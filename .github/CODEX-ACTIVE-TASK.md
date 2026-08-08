# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-RULES-PROFILE-RELEASE-ENFORCEMENT-FIX-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_RULES_PROFILE_RELEASE_ENFORCEMENT_FIX`
- commandPath: `.github/CODEX-FIX-ADR0091-RULES-PROFILE-RELEASE-ENFORCEMENT-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_RULES_RELEASE_FIX_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-ADR0091-RULES-PROFILE-LEAK-GATE-IMPLEMENTATION-001`
- previousCommandReportedStatus: `PASS`
- previousCommandChatGPTVerification: `PARTIAL_HOLD`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_RULES_RELEASE_ENFORCEMENT`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION`
- currentCorrection: `RULES_PROFILE_RELEASE_ENFORCEMENT_FIX`
- rulesProfileFunctionalState: `PARTIAL_PASS`
- rulesProfileAcceptanceState: `HOLD_PENDING_ENFORCEMENT_FIX`
- nextCorrectionOnSuccess: `CORE_RULES_READER`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `BLOCKED`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-09`

## 현재 활성 작업

이전 Rules Profile + Release Leak Gate 구현의 잔여 결함 두 개만 닫는다.

```text
1. BuiltinPackIndex single package authority
   → Resolver/validator의 private revision/root/count 중복 하드코딩 제거

2. Actual filesystem release staging enforcement
   → staging root/inventory 생성
   → Release leak validation
   → CI nonzero failure 연결
```

Core Rules Reader는 이번 fix가 ChatGPT 독립 검증에서 PASS하기 전까지 시작하지 않는다.

## 현재 HOLD 이유

### A. duplicated package authority

`BuiltinPackIndex.lua`가 이미 private rules package의 pinned version, sourceBindingKey, sourceRoot, expected counts를 선언하지만 `RulePackageResolver.lua`와 Python validator가 같은 계약을 별도 literal로 다시 선언하고 있다.

성공 조건:

```text
Resolver readiness comparison
→ matched BuiltinPackIndex package record field 기준

Python/static validator
→ private revision/root/count를 독립 authority로 재정의하지 않음
```

### B. release enforcement 미연결

현재 Leak Gate와 synthetic fixture는 존재하지만 실제 public/release staging output을 입력받아 CI를 실패시키는 경로가 없다.

성공 조건:

```text
actual filesystem staging root
→ deterministic inventory
→ leak/attribution/public-link validation
→ CI step
→ leak 발생 시 workflow FAIL
```

Synthetic in-memory fixture만으로 PASS 금지.

## 실행 규칙

1. `commandPath`를 가장 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. root `AGENTS.md`, Work Order, AGENT status, ADR-0091, final UI/content contract를 읽는다.
4. 이전 Resolver/Leak Gate Source와 tests/tooling/workflow를 직접 읽는다.
5. BuiltinPackIndex를 package metadata의 단일 runtime authority로 유지한다.
6. Resolver 내부에 private pinned revision, sourceRoot, expected counts를 duplicate authority table/literal로 유지하지 않는다.
7. Python validator도 동일 metadata를 독립 specification으로 재정의하지 않는다.
8. actual filesystem staging root 또는 generated inventory를 입력받는 release validation 경로를 만든다.
9. staging missing/incomplete는 fail closed한다.
10. clean actual staging directory PASS와 negative actual filesystem fixture들을 테스트한다.
11. CI가 staging 생성/검사 step을 실제 실행하고 leak failure를 workflow failure로 전달해야 한다.
12. private rule body/credential/generated private chunk/index/snippet을 public Git에 추가하지 않는다.
13. public/release/artifact SRD-only, explicit development fallback, client-safe allowlist를 보존한다.
14. Asset Registry PASS를 보존한다.
15. Core Rules Reader, Official Sheet, Dice Notice는 구현하지 않는다.
16. Runtime/Human/Persistence/Performance evidence를 승격하지 않는다.
17. focused regression + full repository-required static/build/lint/type validation을 실행한다.
18. Studio/Studio MCP/Human Playtest는 실행하지 않는다.
19. current branch에 non-force push한다.
20. result HEAD의 PR-triggered GitHub Actions를 실제 확인한다.
21. failure/pending/cancelled가 하나라도 있으면 PASS 금지.
22. 지정 result marker로 PR #2 top-level 결과 댓글을 남긴다.

## 필수 regression

### Single authority

```text
package-index fixture의 version 변경 -> Resolver가 fixture record를 기준으로 readiness 판단
package-index fixture의 expected count 변경 -> Resolver가 fixture record를 기준으로 판단
Resolver private revision/root/count duplicate literals 없음
unknown/ambiguous profile fail closed
explicit SRD fallback 유지
public/release/artifact SRD-only 유지
client-safe private metadata 부재
```

### Filesystem release staging

```text
clean public staging directory -> PASS
missing staging root -> FAIL
private package id staged -> FAIL
private source marker staged -> FAIL
private metadata staged -> FAIL
non-public rvtt-rule:// link -> FAIL
missing/wrong SRD attribution -> FAIL
unlisted staged private marker file도 누락 없이 검사되어 FAIL
valid rvtt.core.rules link + attribution -> PASS
```

## Acceptance 성공 상태

이 fix를 실제로 모두 만족한 경우에만:

```text
final.asset-registry-separation = STATIC_VERIFIED
final.rules-profile-release-leak-gate = STATIC_VERIFIED
final.core-rules-reader-filtering = BLOCKED
final.official-2024-sheet-interactions = BLOCKED
final.dice-slot-reveal-notice = BLOCKED
finalContractGaps = 3
Phase 10 = PARTIAL / HOLD
next = CORE_RULES_READER
new current-HEAD Static Gate = NOT YET
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
```

현재 Matrix의 rules-profile `STATIC_VERIFIED`는 이 fix의 성공 증거로 간주하지 않는다.

## 명시적 제외

- Core Rules Reader UI/search/virtualization/chunk lazy-load
- private rule body importer
- Official 2024 Character Sheet
- Dice Slot Reveal Notice
- ADR-0092 Runtime
- Persistence Runtime
- Performance/Soak
- Player persistent Minimap / separate Player Map / Objective Tracker
- new gameplay-authority command
- test 삭제/skip/assertion 약화
- validator/CI bypass
- force push
- PR Ready/Approve/Merge

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인`이라고 하면:

1. PR #2 current HEAD 재조회
2. 최신 `RVTT_CODEX_ADR0091_RULES_RELEASE_FIX_RESULT` 확인
3. target/result SHA 및 compare 확인
4. Resolver가 BuiltinPackIndex record를 실제 authority로 사용하는지 확인
5. Resolver/validator duplicate private metadata authority 제거 확인
6. filesystem staging inventory builder/validator 직접 확인
7. CI workflow가 actual staging gate를 실행하는지 확인
8. negative filesystem regression 확인
9. Acceptance remaining gaps = 3 확인
10. current HEAD Actions 전부 success 확인
11. Studio/Human PASS 확대 금지
