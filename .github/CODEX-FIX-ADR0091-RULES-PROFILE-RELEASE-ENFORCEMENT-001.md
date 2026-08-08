# Codex Implementation Fix — ADR-0091 Rules Profile Release Enforcement 001

- commandId: `RVTT-PR2-ADR0091-RULES-PROFILE-RELEASE-ENFORCEMENT-FIX-001`
- taskType: `IMPLEMENTATION_FIX`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_RULES_PROFILE_RELEASE_ENFORCEMENT_FIX`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_RULES_RELEASE_FIX_RESULT -->`

## 1. 목적

이 작업은 이전 `RVTT-PR2-ADR0091-RULES-PROFILE-LEAK-GATE-IMPLEMENTATION-001`의 ChatGPT 검증에서 발견된 두 잔여 결함만 수정한다.

```text
A. BuiltinPackIndex가 선언한 private rule package 계약을 Resolver/validator가 다시 하드코딩하여 package authority가 중복됨
B. ReleaseContentLeakGate 알고리즘과 synthetic fixture는 존재하지만 실제 public/release staging output을 검사하는 CI enforcement가 없음
```

Core Rules Reader, Official Sheet, Dice Notice를 시작하지 않는다.

이번 fix가 성공해야만 `final.rules-profile-release-leak-gate = STATIC_VERIFIED`와 `finalContractGaps = 3`을 최종 인정한다.

## 2. 시작 시 확인

1. 이 command를 가장 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
4. ADR-0091과 `docs/remake/ui/shared/final-ui-content-implementation-contract.md`를 읽는다.
5. 다음 현재 구현을 직접 읽는다.
   - `implementation/roblox/src/ServerStorage/RVTT/Content/BuiltinPackIndex.lua`
   - `implementation/roblox/src/ServerStorage/RVTT/Content/RulePackageResolver.lua`
   - `implementation/roblox/src/ServerStorage/RVTT/Content/ReleaseContentLeakGate.lua`
   - `implementation/roblox/src/ReplicatedStorage/RVTT/ContentRuntime/RuleProfileStatus.lua`
   - `implementation/roblox/tooling/validate_rules_profile_release_gate.py`
   - `implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`
   - `implementation/roblox/full-ui-ux-acceptance-matrix.json`
   - `.github/workflows/validate-rvtt-implementation.yml`
6. 이전 결과 댓글과 ChatGPT HOLD 사유를 확인한다.

## 3. 결함 A — BuiltinPackIndex single-authority 복구

### 현재 문제

`BuiltinPackIndex.lua`에는 private package record가 이미 다음 계약을 가진다.

```text
packageId
version / pinned revision
sourceBindingKey
sourceRoot
expectedContentCounts
publicBuildAllowed
clientExportAllowed
ownerOnly
rights/license flags
```

그런데 Resolver와 Python validator가 revision, binding key, source root, 12/48/16/10/75/391 counts 등을 별도 상수로 다시 선언한다.

### 필수 수정

1. `BuiltinPackIndex.lua`를 package metadata의 단일 runtime authority로 유지한다.
2. `RulePackageResolver`는 profile에 해당하는 정확히 하나의 package record를 `BuiltinPackIndex`에서 찾고, private readiness를 **그 record의 필드와 비교**한다.
3. Resolver 내부에 다음 authority 값을 중복 literal로 선언하지 않는다.
   - private pinned revision/version
   - sourceBindingKey
   - sourceRoot
   - expected content counts
4. package ID를 lookup identifier로 쓰는 것은 허용하지만, package metadata 자체를 별도 table/constants로 복제하지 않는다.
5. public/release/artifact safety도 가능하면 matched package record의 `publicBuildAllowed`, `clientExportAllowed`, `ownerOnly`, license/attribution metadata를 사용한다.
6. Python validator/self-test 또한 private revision/root/count 계약을 독립 authority로 재정의하지 않는다.
   - `BuiltinPackIndex`에서 derivation/parsing하거나,
   - BuiltinPackIndex에서 생성/검증되는 machine-readable bridge를 사용하거나,
   - behavioral truth를 Luau focused spec에 두고 Python은 structural/enforcement wiring만 검사한다.
7. 새 machine-readable bridge를 추가한다면 그것이 independent hand-maintained authority가 되면 안 된다. drift negative test가 있어야 한다.

### 필수 regression

```text
BuiltinPackIndex private version 변경 fixture -> Resolver가 새 record 값을 기준으로 readiness 판단
BuiltinPackIndex expected count 변경 fixture -> Resolver가 record 값을 기준으로 판단
Resolver source에 pinned revision/root/count literal 복제 없음
unknown/ambiguous profile fail closed 유지
explicit SRD fallback semantics 유지
public/release/artifact SRD-only invariant 유지
client-safe allowlist 유지
```

실제 production BuiltinPackIndex 값을 테스트 때문에 바꾸지 말고 injectable/package-index fixture 또는 pure helper를 사용한다.

## 4. 결함 B — 실제 release staging enforcement 연결

### 현재 문제

현재 `ReleaseContentLeakGate.validate()`와 Python `validate_artifact()`는 synthetic artifact fixture를 잘 거부하지만, 실제 build/staging output을 입력받는 production/release enforcement 경로가 없다.

### 필수 수정

1. 명시적인 public/release artifact staging inventory contract를 추가한다.
2. Tooling은 **실제 파일 시스템 staging root 또는 실제 생성 manifest/inventory**를 입력으로 받아야 한다.
3. 최소 inventory는 다음을 증명할 수 있어야 한다.

```text
profile
basePackageId
packageIds
output files: path + inspectable text/metadata where applicable
ruleLinks
license / attribution metadata
```

4. 파일 전체가 binary라면 무조건 decode하지 말고, release contract상 inspectable manifest/index/text outputs와 file path/metadata를 deterministic하게 inventory화한다.
5. staging root가 없거나 inventory 생성이 불완전하면 release validation은 fail closed한다.
6. 실제 public staging fixture/build output에는 private body를 넣지 않는다. synthetic marker fixture는 tests 전용이다.
7. release validator CLI는 synthetic self-test만 실행해서 성공하면 안 된다. 최소 하나의 **actual filesystem staging fixture**를 만들어/읽어 clean pass를 증명하고, negative staging fixtures도 실제 파일 경로를 통해 검사한다.
8. CI에서 실제 public/release staging inventory 생성 → leak validation 순서가 실행되도록 연결한다.
9. 이 enforcement는 `.github/workflows/validate-rvtt-implementation.yml` 또는 별도 목적이 명확한 workflow에 연결할 수 있다.
10. 별도 workflow를 만들면 관련 Source/Tooling/Content path 변경 시 반드시 실행되도록 path filter를 포함한다.
11. CI step은 failure를 우회하는 `|| true`, `continue-on-error` 등을 사용하지 않는다.
12. release validation failure는 해당 workflow를 실패시켜야 한다.

### 현실적인 범위

현재 실제 public rules body/publish service가 아직 없다면, 이번 fix에서 완전한 배포 시스템을 만들지 않는다.
대신 repository가 가진 현재 public-safe runtime/source를 deterministic staging root에 구성하고, **그 실제 staging directory**를 inventory builder와 leak gate가 검사하도록 한다.

예시 형태는 구현자가 repository 구조에 맞게 선택한다.

```text
build_public_release_staging.py <staging-root>
→ public release metadata/index/client-safe outputs copy/generate
→ release-content-inventory.json

validate_rules_profile_release_gate.py --staging-root <staging-root>
→ filesystem inventory build/read
→ leak gate
→ nonzero exit on leak/missing attribution/missing required inventory
```

파일명은 예시이며 기존 tooling convention에 맞춰도 된다.

### 필수 filesystem regression

```text
clean public staging directory -> PASS
missing staging directory -> FAIL
private package id in staged manifest -> FAIL
private source marker in staged text -> FAIL
private metadata key/value in staged metadata -> FAIL
private/non-public rvtt-rule:// link -> FAIL
missing/wrong SRD attribution -> FAIL
extra unlisted staged file that contains forbidden marker -> FAIL or deterministic inventory inclusion 후 FAIL
public rvtt.core.rules link + valid attribution -> PASS
```

핵심은 synthetic in-memory dict만 검사하지 않는 것이다.

## 5. 기존 기능 보존

다음을 회귀시키지 않는다.

- Asset Registry STATIC_VERIFIED
- Rules profile six-profile mapping
- development/test/studio private readiness fail closed
- explicit `allowSrdFallback=true` only
- fallback visible reason
- public/release/artifact private selection 금지
- private source/body/chunk/index/snippet/credential public Git 미포함
- client-safe RuleProfileStatus allowlist
- Player persistent Minimap / separate Player Map / Objective Tracker 금지
- runtime/human/persistence/performance 상태 미승격

## 6. Acceptance 상태 규칙

현재 Matrix의 rules-profile item은 이전 구현에서 조기 `STATIC_VERIFIED`로 올라가 있다. 이를 근거로 이 fix를 자동 PASS 처리하지 않는다.

성공 시에만:

```text
final.asset-registry-separation = STATIC_VERIFIED
final.rules-profile-release-leak-gate = STATIC_VERIFIED
final.core-rules-reader-filtering = BLOCKED
final.official-2024-sheet-interactions = BLOCKED
final.dice-slot-reveal-notice = BLOCKED
finalContractGaps = 3
Phase 10 = PARTIAL / HOLD
next = CORE_RULES_READER correction
```

이번 fix 요구를 충족하지 못하면 resultStatus를 PASS로 쓰지 않는다. 남은 문제를 결과 댓글에 명시한다.

## 7. 검증

최소 다음을 실행한다.

- focused resolver single-authority regression
- focused filesystem staging/release leak regression
- `validate_rules_profile_release_gate.py`
- `validate_full_ui_ux_acceptance.py`
- `validate_implementation.py`
- StyLua check
- Selene
- repository-required Rojo builds/sourcemaps
- production/tests Luau analysis
- 관련 PowerShell self-tests

push 후 **result HEAD의 모든 PR-triggered GitHub Actions**를 실제 확인한다.

failure/pending/cancelled가 하나라도 있으면 PASS 금지.

Studio/Studio MCP/Human Playtest는 실행하지 않는다.

## 8. 명시적 제외

- Core Rules Reader UI/virtualization/search/chunk lazy-load 구현
- private rule importer body processing
- private copyrighted rule body commit
- Official 2024 Character Sheet
- Dice Slot Reveal Notice
- ADR-0092 Runtime
- Persistence Runtime
- Performance/Soak
- new gameplay-authority command
- test 삭제/skip/assertion 약화
- validator/CI bypass
- force push
- PR Ready/Approve/Merge

## 9. 결과 댓글 형식

PR #2 top-level conversation에 다음 marker로 결과를 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_RULES_RELEASE_FIX_RESULT -->
commandId: RVTT-PR2-ADR0091-RULES-PROFILE-RELEASE-ENFORCEMENT-FIX-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | PARTIAL | FAIL | BLOCKED | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_RULES_PROFILE_RELEASE_ENFORCEMENT_FIX
singleAuthorityStatus: PASS | PARTIAL | FAIL
filesystemStagingGateStatus: PASS | PARTIAL | FAIL
acceptanceRulesProfileStatus: STATIC_VERIFIED | BLOCKED
remainingFinalContractGaps: <number>
localValidation: <summary>
githubActions: <workflow name/status list>
studioRuntime: NOT_EXECUTED
humanUiUx: NOT_EXECUTED
changedFiles: <list>
blockerReason: <none or exact blocker>
```

## 10. ChatGPT 후속 검증 포인트

사용자가 `확인`이라고 하면 ChatGPT가 독립적으로 다음을 확인한다.

1. current PR HEAD와 result SHA 일치
2. compare가 target에서 예상 범위로만 이동
3. Resolver가 BuiltinPackIndex package record를 실제 비교에 사용
4. Resolver/validator에서 private revision/root/count metadata 중복 authority 제거
5. actual filesystem staging inventory builder/validator 존재
6. CI가 실제 staging root를 만들고 leak validation을 실행
7. negative filesystem fixtures가 private marker/link/metadata/attribution 문제를 거부
8. client-safe negative disclosure 유지
9. Acceptance gap이 rules-profile만 최종 해제되고 나머지 3개 유지
10. current HEAD Actions 전부 success
11. Studio/Human PASS로 확대하지 않음
