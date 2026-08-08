# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-RULES-PROFILE-LEAK-GATE-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_RULES_PROFILE_LEAK_GATE`
- commandPath: `.github/CODEX-IMPLEMENTATION-ADR0091-RULES-PROFILE-LEAK-GATE-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_RULES_PROFILE_LEAK_GATE_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-ADR0091-ASSET-REGISTRY-IMPLEMENTATION-001`
- previousCommandStatus: `PASS_VERIFIED_BY_CHATGPT`
- phase9Status: `FINAL_PASS`
- phase10Status: `PARTIAL_HOLD_4_ADR0091_FINAL_CONTRACT_GAPS`
- completedCorrections: `ASSET_REGISTRY_FOUNDATION`
- currentCorrection: `RULES_PROFILE_RELEASE_LEAK_GATE`
- nextCorrectionOnSuccess: `CORE_RULES_READER`
- newCurrentHeadStaticGate: `NOT_YET`
- studioRuntimeState: `BLOCKED`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-09`

## 현재 활성 작업

ADR-0091 remaining blocker 4개 중 **Rules Profile + Public Release Leak Gate 하나만** 실제 Production Source/Tooling으로 구현한다.

```text
BuiltinPackIndex
→ RulePackageResolver
→ development/test/studio-acceptance = private integrated base
→ private source readiness / pin / count fail closed
→ explicit allowSrdFallback only
→ public/release/artifact = rvtt.core.rules only
→ ReleaseContentLeakGate
→ private package/source/chunk/index/snippet metadata leak rejection
→ Acceptance blocker 하나만 해제
```

성공해도 Phase 10 전체는 HOLD다. Core Rules Reader, Official Sheet, Dice Notice는 계속 BLOCKED다.

## 고정 Authority

Profile mapping:

```text
development / test / studio-acceptance
→ rvtt.test.rules.2024.integrated.ko

public / release / artifact
→ rvtt.core.rules
```

Private integrated package:

```text
sourceBindingKey = RVTT_PRIVATE_DND2024_KO_SOURCE
sourceRevision = d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4
sourceRoot = 10-RULEBOOKS/integrated-2024
expected counts = classes 12 / subclasses 48 / backgrounds 16 / species 10 / feats 75 / spells 391
```

Private rule 본문, generated chunk, search index, snippet, credential은 public Git tree에 커밋하지 않는다.

## 실행 규칙

1. `commandPath`를 가장 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. `AGENTS.md`, Work Order, AGENT-TEST-STATUS, ADR-0091, final UI/content contract, Acceptance Matrix/validator, BuiltinPackIndex, Asset Registry foundation을 읽는다.
4. 기존 `BuiltinPackIndex.lua`를 package authority로 재사용한다. 중복 package authority를 만들지 않는다.
5. profile별 기본 package는 정확히 하나여야 한다.
6. unknown profile은 fail closed한다.
7. private readiness missing/binding mismatch/revision mismatch/root mismatch/count mismatch/digest mismatch는 fail closed한다.
8. `allowSrdFallback=true`가 명시된 development/test/studio-acceptance에서만 SRD fallback을 허용한다.
9. fallback은 `fallbackActive`와 viewer-safe reason code를 지속 표시한다. 정상 integrated 상태로 가장하지 않는다.
10. public/release/artifact는 malformed option과 무관하게 `rvtt.core.rules`만 선택한다.
11. 동일 Build에서 private/public base body 자동 병합 금지.
12. ReleaseContentLeakGate는 실제 public output/artifact staging 범위에 대해 fail closed해야 한다.
13. Gate는 private package id/source path/private metadata/chunk/index/snippet/private rule link를 차단한다.
14. Gate는 `rvtt.core.rules` attribution/license와 public `rvtt-rule://` package anchor를 검증한다.
15. source code/ADR/test fixture에서 leak-pattern 문자열을 정의하는 것 자체를 output leak으로 오판하지 않는다.
16. client-safe 상태에 private source credential/path/raw revision/count를 필요 없이 노출하지 않는다.
17. 실제 private rule body를 repository에 추가하지 않는다.
18. Core Rules Reader UI/virtualization은 구현하지 않는다.
19. Official Sheet/Dice Notice도 구현하지 않는다.
20. Acceptance Matrix에서 rules-profile/leak-gate blocker만 `STATIC_VERIFIED`로 전환한다.
21. Asset Registry PASS는 유지하고 나머지 3 final gaps는 BLOCKED로 유지한다.
22. focused tests + repository-required validators/format/lint/Rojo/sourcemap/Luau analysis를 실행한다.
23. Studio/Studio MCP/Human Playtest는 실행하지 않는다.
24. current branch에 non-force push한다.
25. push 후 새 result HEAD 관련 GitHub Actions를 실제 확인한다.
26. failure/pending/cancelled 하나라도 있으면 PASS 금지.
27. 지정 result marker로 PR #2 top-level 결과 댓글을 남긴다.

## 필수 focused regression

### Resolver

```text
development/test/studio valid readiness -> integrated package
public/release/artifact -> rvtt.core.rules
unknown profile -> fail closed
private binding missing/mismatch -> fail closed
pinned revision mismatch -> fail closed
source root mismatch -> fail closed
각 expected content count mismatch -> fail closed
explicit allowSrdFallback=true -> SRD fallback + persistent fallback status
implicit fallback -> 금지
public/release malformed options로 private 선택 -> 금지
```

### Release leak gate

```text
clean synthetic public artifact -> PASS
private package id -> FAIL
private repo/source path marker -> FAIL
private chunk/index/snippet marker -> FAIL
private source metadata -> FAIL
missing SRD attribution/license -> FAIL
private rvtt-rule:// package anchor -> FAIL
rvtt.core.rules public anchor -> PASS
client-safe profile state private metadata leak -> FAIL
```

실제 private copyrighted body를 fixture로 사용하지 않는다.

## Acceptance 성공 상태

이 correction이 성공하면:

```text
final.asset-registry-separation = STATIC_VERIFIED
final.rules-profile-release-leak-gate = STATIC_VERIFIED
final.core-rules-reader-filtering = BLOCKED
final.official-2024-sheet-interactions = BLOCKED
final.dice-slot-reveal-notice = BLOCKED
finalContractGaps = 3
Phase 10 = PARTIAL / HOLD
next = CORE_RULES_READER correction
new current-HEAD Static Gate = NOT YET
Studio Human Retest = BLOCKED
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
```

## 명시적 제외

- private integrated rule body import/commit
- private credentials/secrets
- Core Rules Reader UI/virtualized article
- Official 2024 interactive Character Sheet
- Dice Slot Reveal Notice
- ADR-0092 Runtime
- Player persistent Minimap / separate Player Map / Objective Tracker
- new gameplay-authority command
- test deletion/skip/assertion weakening
- validator/CI bypass
- force push
- PR Ready/Approve/Merge

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 하면:

1. PR #2 current HEAD 재조회
2. 최신 `RVTT_CODEX_ADR0091_RULES_PROFILE_LEAK_GATE_RESULT` 댓글 확인
3. target/result SHA와 실제 compare/files 대조
4. RulePackageResolver profile mapping 직접 확인
5. private readiness fail-closed와 explicit fallback 검수
6. public/release/artifact SRD-only invariant 확인
7. ReleaseContentLeakGate output-scope와 leak negative fixtures 확인
8. client-safe negative disclosure 확인
9. Acceptance Matrix가 이 blocker만 해제해 remaining gap 3인지 확인
10. Work Order/AGENT status consistency 확인
11. current HEAD GitHub Actions 직접 확인
12. 모두 맞아야 correction PASS 인정
13. Studio/Human PASS 확대 금지
