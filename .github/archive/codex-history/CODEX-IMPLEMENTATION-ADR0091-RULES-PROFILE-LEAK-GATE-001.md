# Codex Implementation Command — ADR-0091 Rules Profile + Release Leak Gate 001

- commandId: `RVTT-PR2-ADR0091-RULES-PROFILE-LEAK-GATE-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_RULES_PROFILE_LEAK_GATE`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_RULES_PROFILE_LEAK_GATE_RESULT -->`

## 1. 목적

Phase 10 Acceptance에서 남은 ADR-0091 final-contract blocker 4개 중 다음 하나만 실제 Production Source/Tooling으로 닫는다.

```text
final.rules-profile-release-leak-gate
```

구현 목표:

```text
BuiltinPackIndex package authority
→ RulePackageResolver
→ development/test/studio-acceptance private integrated base selection
→ private source readiness / pin / count fail-closed contract
→ explicit allowSrdFallback only
→ public/release/artifact SRD-only selection
→ ReleaseContentLeakGate
→ private package/source/body/index/snippet metadata leak rejection
→ public rule-link package validation + attribution gate
→ focused tests / static validation / remote CI
```

이 작업 성공 후에도 Phase 10 전체는 `PARTIAL / HOLD`다. Official Sheet, Dice Notice, Core Rules Reader 3개 blocker는 유지한다.

## 2. Authority

우선순위는 root `AGENTS.md`와 Accepted ADR을 따른다. 반드시 아래를 읽는다.

- `AGENTS.md`
- `implementation/roblox/CURRENT-WORK-ORDER.md`
- `AGENT-TEST-STATUS.md`
- `docs/remake/decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md`
- `docs/remake/ui/shared/final-ui-content-implementation-contract.md`
- `implementation/roblox/full-ui-ux-acceptance-matrix.json`
- `implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`
- `implementation/roblox/src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua`
- 현재 Asset Registry foundation과 관련 validator/test

현재 확정 Profile mapping:

```text
development
 test
 studio-acceptance
→ rvtt.test.rules.2024.integrated.ko

public
 release
 artifact
→ rvtt.core.rules
```

Private integrated package pinned contract:

```text
packageId = rvtt.test.rules.2024.integrated.ko
sourceBindingKey = RVTT_PRIVATE_DND2024_KO_SOURCE
sourceRevision = d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4
sourceRoot = 10-RULEBOOKS/integrated-2024
expected counts = 12 / 48 / 16 / 10 / 75 / 391
rights = developer_private / ownerOnly / redistributable=false / publicBuildAllowed=false / clientExportAllowed=false
```

Public package:

```text
packageId = rvtt.core.rules
SRD 5.2.1 public/release/artifact base
CC-BY-4.0 attribution required
```

## 3. 범위

### A. Server-side RulePackageResolver

기존 `BuiltinPackIndex.lua`를 package authority로 사용한다. 별도 중복 package registry를 만들지 않는다.

Resolver는 최소 다음 계약을 가져야 한다.

1. profile별 기본 Rule Package는 정확히 하나다.
2. `development`, `test`, `studio-acceptance`는 private integrated package를 기본 선택한다.
3. `public`, `release`, `artifact`는 `rvtt.core.rules`만 기본 선택한다.
4. public/release/artifact에서 private integrated package를 base 또는 implicit overlay로 절대 선택하지 않는다.
5. 동일 Build에서 private + public base body를 자동 병합하지 않는다.
6. House Rule Overlay가 필요하면 명시적 input만 허용하고 base package 선택과 분리한다. 이번 작업에서 새 House Rule content system을 만들지 않는다.
7. unknown profile은 fail closed한다.

### B. Private source readiness / fail closed

실제 private Markdown이나 변환 Rule Chunk를 public repository에 넣지 않는다.

Resolver 또는 별도 server/build contract는 caller가 주입한 private-source readiness evidence를 검증할 수 있어야 한다. 최소 evidence:

```text
bindingPresent
sourceBindingKey
sourceRevision
sourceRoot
contentCounts
contentHash or verifiedDigest when available
```

기본 동작:

```text
private source missing
or binding key mismatch
or pinned revision mismatch
or source root mismatch
or expected count mismatch
or verified digest mismatch when supplied
→ fail closed
```

`allowSrdFallback=true`가 명시된 development/test/studio-acceptance 요청에서만 `rvtt.core.rules` fallback을 허용한다.

Fallback 결과는 조용히 정상 integrated 상태로 보이면 안 된다. 반환 projection/status에 viewer-safe machine-readable 상태를 남긴다. 예:

```text
basePackageId = rvtt.core.rules
fallbackActive = true
fallbackReasonCode = INTEGRATED_TEST_PACK_UNAVAILABLE
```

Source path credential/token/raw private metadata를 client-safe 결과에 포함하지 않는다.

public/release/artifact profile에는 `allowSrdFallback` 의미 자체가 없어야 하며 항상 SRD base다.

### C. ReleaseContentLeakGate

공개 Release/Artifact publish 전 실행 가능한 fail-closed gate를 구현한다.

Gate는 실제 output inventory/manifest/file tree 또는 build artifact staging path를 입력으로 검사할 수 있어야 한다. Repository tooling과 Production contract 둘 다 필요하면 최소 구조로 추가한다.

최소 금지:

```text
rvtt.test.rules.2024.integrated.ko
Kaetaeru/D-D-2024-
RVTT_PRIVATE_DND2024_KO_SOURCE
10-RULEBOOKS/integrated-2024
private Rule Chunk
private Search Index
private snippet/cache
private source commit/revision metadata in runtime output
credential/token-like private source metadata
non-public package anchors in public rvtt-rule:// links
```

단, public source code의 `BuiltinPackIndex.lua`, ADR, test fixture처럼 **검사를 정의하기 위해 필요한 문자열 자체**를 무조건 repository leak으로 오판하지 않는다. Gate 대상은 명시적인 public build/output/artifact staging 범위여야 한다.

공개 산출물 성공 조건:

1. public/release/artifact resolved base = `rvtt.core.rules` only.
2. private package/chunk/index/snippet/source metadata absent.
3. `rvtt.core.rules` license/attribution metadata present and valid.
4. public `rvtt-rule://` links가 공개 허용 package anchor만 가리킨다.
5. 실패 시 publish/upload를 허용하는 success result를 만들지 않는다.

### D. Client-safe profile status

필요한 경우 client-safe status/projection을 추가하되 allowlist만 사용한다.

허용 가능한 정보 예:

```text
activeProfile
basePackageId
fallbackActive
fallbackReasonCode
attributionRequired
```

Private source repository URL, binding secret/value, raw revision metadata, content counts가 권한 없는 client에게 필요 없이 노출되면 안 된다.

Core Rules Reader UI 자체는 이번 작업 범위가 아니다.

### E. Acceptance gap transition

성공 시:

```text
final.asset-registry-separation = STATIC_VERIFIED (유지)
final.rules-profile-release-leak-gate = STATIC_VERIFIED
final.core-rules-reader-filtering = BLOCKED
final.official-2024-sheet-interactions = BLOCKED
final.dice-slot-reveal-notice = BLOCKED
finalContractGaps = 3
```

`validate_full_ui_ux_acceptance.py`를 더 이상 “나머지 4개 영구 BLOCKED”에 하드코딩하지 말고, 이번 resolved evidence를 요구하면서 실제 remaining subset 3개를 보존하도록 갱신한다.

Runtime/Human/Persistence/Performance evidence는 승격하지 않는다.

## 4. 금지 사항

- private integrated Korean rule body를 public Git tree에 복사
- private source credential/value/token 커밋
- private generated Rule Chunk/Search Index/Snippet 커밋
- fabricated content count/hash로 success 만들기
- source unavailable인데 integrated package가 준비됐다고 가장
- `allowSrdFallback` 기본 true
- release/public profile이 private package를 선택하는 fallback
- release gate bypass, `|| true`, continue-on-error
- test 삭제/skip/assertion 약화
- Official 2024 Character Sheet 구현
- Dice Slot Reveal Notice 구현
- Core Rules Reader UI/virtualized article 구현
- ADR-0092 Runtime 확대
- Player persistent Minimap / separate Player Map / Objective Tracker
- Studio/Studio MCP/Human Playtest 실행 또는 PASS 주장
- force push
- PR Ready/Approve/Merge

## 5. 필수 focused regression

최소 아래를 실제 executable tests/tooling fixture로 검증한다.

### Resolver

```text
development -> integrated private base when readiness evidence valid
test -> integrated private base when readiness evidence valid
studio-acceptance -> integrated private base when readiness evidence valid
public -> rvtt.core.rules
release -> rvtt.core.rules
artifact -> rvtt.core.rules
unknown profile -> fail closed
private source missing -> fail closed
binding key mismatch -> fail closed
pinned revision mismatch -> fail closed
source root mismatch -> fail closed
count mismatch for classes/subclasses/backgrounds/species/feats/spells -> fail closed
explicit allowSrdFallback=true -> SRD fallback + persistent fallback status
implicit/no fallback -> no silent SRD fallback
public/release cannot select private package even when malformed options are supplied
```

### Leak gate

```text
clean synthetic public artifact -> PASS
private package id in output -> FAIL
private repository/source path token in output -> FAIL
private chunk/index/snippet fixture in output -> FAIL
private source revision metadata in runtime output -> FAIL
missing SRD attribution/license -> FAIL
private rvtt-rule:// package anchor in public output -> FAIL
public rvtt.core.rules anchor -> PASS
client-safe profile status contains no private source credential/path/raw metadata
```

실제 private rule 본문은 fixture에 사용하지 않는다. synthetic marker만 사용한다.

## 6. Validation

구현 후 최소 다음을 실행한다.

- focused resolver/leak-gate tests
- new rules-profile/leak validator self-tests if added
- `validate_full_ui_ux_acceptance.py`
- `validate_implementation.py`
- relevant remake/content/grand/persistence/lease validators
- StyLua
- Selene
- `git diff --check`
- all repository-required Rojo builds
- default/test/multi-client sourcemaps as required
- production/test Luau analysis

Studio/Studio MCP/Human Runtime은 실행하지 않는다.

## 7. Publish / Remote CI

1. 시작 시 PR #2 current remote HEAD를 `targetShaAtStart`로 기록한다.
2. 작업 중 remote HEAD가 예상치 않게 다른 작업으로 이동하면 충돌을 확인하고 destructive overwrite를 하지 않는다.
3. current PR branch에 non-force push한다.
4. push 후 **새 result HEAD**의 관련 GitHub Actions를 실제 확인한다.
5. failure/pending/cancelled가 하나라도 있으면 `PASS`를 보고하지 않는다.

## 8. 상태 문서

성공 시 Work Order / `AGENT-TEST-STATUS.md` / `FULL-UI-UX-ACCEPTANCE.md`를 사실에 맞게 최소 갱신한다.

```text
ADR-0091 Asset Registry = STATIC_VERIFIED
ADR-0091 Rules Profile + Release Leak Gate = STATIC_VERIFIED
remaining final-contract blockers = 3
Phase 10 = PARTIAL / HOLD
next correction = CORE_RULES_READER
new current-HEAD Static Gate = NOT YET
Studio Human Retest = BLOCKED
```

## 9. 결과 댓글 형식

PR #2 top-level conversation에 아래 marker로 결과를 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_RULES_PROFILE_LEAK_GATE_RESULT -->
commandId: RVTT-PR2-ADR0091-RULES-PROFILE-LEAK-GATE-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | PARTIAL | FAIL | BLOCKED | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_RULES_PROFILE_LEAK_GATE
resolverContract: <summary>
privateReadinessContract: <summary>
releaseLeakGate: <summary>
focusedTests: <summary>
negativeDisclosure: <summary>
acceptanceGapTransition: <summary>
testsRun: <summary>
staticValidationStatus: PASS | FAIL | NOT_EXECUTED
remoteCiStatus: <actual current result-head workflow status>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
phase10Status: PARTIAL / HOLD
nextCorrection: ADR-0091 CORE_RULES_READER
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <scope/evidence boundary>
```

## 10. 성공 조건

아래를 모두 만족할 때만 이 correction을 PASS로 보고한다.

```text
Resolver profile mapping exact
+ private readiness mismatch fail closed
+ explicit-only SRD fallback
+ public/release/artifact SRD-only invariant
+ release output leak gate executable and fail closed
+ SRD attribution + public rule-link validation
+ client-safe negative disclosure
+ focused tests PASS
+ acceptance final gap 4 -> 3 only
+ all required local static/build checks PASS
+ current result HEAD remote CI all required checks SUCCESS
```

Phase 10 전체 PASS 또는 Studio Runtime PASS를 주장하지 않는다.
