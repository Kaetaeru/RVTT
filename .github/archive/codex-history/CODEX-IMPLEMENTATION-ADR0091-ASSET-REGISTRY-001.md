# RVTT Codex Implementation Command — ADR-0091 Asset Registry Foundation

- commandId: `RVTT-PR2-ADR0091-ASSET-REGISTRY-IMPLEMENTATION-001`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_ASSET_REGISTRY`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_ASSET_REGISTRY_RESULT -->`

## 1. 목적

Phase 10 Acceptance audit에서 확인된 ADR-0091 필수 구현 Gap 5개 중 **Developer Asset Registry separation** 하나만 실제 Production Source로 닫는다.

현재 확인된 상태:

```text
implementation/roblox/content-source/
→ 없음

ServerStorage/RVTT/Content
→ BuiltinPackIndex.lua만 존재

ReplicatedStorage/RVTT/ContentRuntime
→ 없음

full-ui-ux-acceptance-matrix.json
→ final.asset-registry-separation = BLOCKED
```

이번 명령의 목표:

```text
Authoring Source
→ Server-authoritative Package Registry
→ explicit client-safe runtime projection/view
→ validation + leak regression
→ Acceptance Matrix에서 asset-registry gap만 실제 evidence로 해제
```

나머지 ADR-0091 Gap 4개는 이번 명령에서 구현하지 않는다.

## 2. Authority

우선순위대로 읽는다.

1. 루트 `AGENTS.md`
2. PR #2 current remote HEAD
3. `implementation/roblox/CURRENT-WORK-ORDER.md`
4. `AGENT-TEST-STATUS.md`
5. `docs/remake/decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md`
6. `docs/remake/ui/shared/final-ui-content-implementation-contract.md`
7. `implementation/roblox/FULL-UI-UX-ACCEPTANCE.md`
8. `implementation/roblox/full-ui-ux-acceptance-matrix.json`
9. current Content/Projection/Test/Tooling source

충돌 시 Accepted ADR와 final UI/content contract가 낮은 문서보다 우선한다.

## 3. 고정 계약

ADR-0091의 기존 Content 체계를 확장하고 **중복 Content authority를 만들지 않는다.**

### Authoring Source

```text
implementation/roblox/content-source/packages/<packageId>/
```

최소 package manifest/source metadata 경계를 실제로 만든다. Source Binary를 꾸며내거나 존재하지 않는 Roblox Asset ID를 발명하지 않는다.

### Server-authoritative Registry

```text
implementation/roblox/src/ServerStorage/RVTT/Content/Packs/<packageId>/
```

Server-only Definition/Manifest/Registry/Validation metadata가 존재해야 한다. `BuiltinPackIndex.lua`와 모순되는 별도 package 목록 authority를 만들지 말고, 기존 index와 새 registry를 한 방향으로 연결한다.

### Client-safe Runtime View

```text
implementation/roblox/src/ReplicatedStorage/RVTT/ContentRuntime/
```

Client에 필요한 catalog/thumbnail/UI/placement-safe 정보만 명시적으로 projection한다. Server source metadata 전체 table을 ReplicatedStorage로 복사하지 않는다.

Client-safe view는 allowlist 기반이어야 한다. 다음 종류의 server/private 값은 기본적으로 client-safe view에 포함하지 않는다.

- source repository/path/binding/credential
- private provenance detail
- source content hash가 공개될 이유가 없는 private metadata
- unpublished runtime address
- server validation internals
- hidden package/asset count를 추론하게 하는 placeholder
- private/non-entitled record

권리 고지나 공개 attribution처럼 실제 client-visible이 필요한 값은 명시적 safe field로 projection할 수 있다.

## 4. Stable Asset Record

ADR-0091 / final contract의 `ContentAssetRecord` 의미를 실제 schema/validation contract로 구현한다.

핵심 field:

```text
assetId
packageId
version
kind
displayNameKey
sourceContentHash
runtimeContentAddress
publishedAssetId?
thumbnailAssetId
bounds
pivot
placementProfile
collisionProfile
navigationProfile
interactionCapabilities[]
performanceBudget
dependencies[]
rights
provenance
```

모든 kind에 같은 필드를 억지로 요구하지 말고 kind-specific requirement를 명시적으로 검증한다.

특히 Token Prefab은 최소 다음 계약을 잃지 않는다.

- feet pivot
- footprint / selection bounds
- rig/animation/camera-focus metadata가 필요한 경우 explicit
- stable asset ID
- rights/provenance
- performance budget

실제 production asset이 아직 없다면 fabricated sample asset을 Production registry에 넣지 않는다. 대신 focused test fixture로 validation behavior를 증명할 수 있다.

## 5. 필수 Validation / Leak Gate

최소 다음 오류를 deterministic하게 거부한다.

- duplicate stable asset ID
- duplicate package-local stable key
- packageId mismatch
- 필수 rights/provenance 누락
- required pivot/bounds/thumbnail 또는 kind-specific metadata 누락
- invalid dependency reference
- dependency cycle
- invalid/negative performance budget
- client-safe allowlist 밖의 server/private field 누출
- private/non-client-exportable package/asset의 client catalog 노출
- package manifest와 server registry의 version/package identity drift

Source/import 경계에서 Script·LocalScript·ModuleScript·Remote 등 실행 가능한 payload를 허용하지 않는 계약도 validator/test로 고정한다. 실제 binary importer가 아직 없는 경우에도 manifest/import description이 executable payload를 승인할 수 없게 fail closed한다.

## 6. 기존 Package와의 연결

현재 `BuiltinPackIndex.lua`의 다음 package 의미를 유지한다.

- `rvtt.core.rules`
- `rvtt.test.rules.2024.integrated.ko`
- `rvtt.core.baseline`

이번 명령은 **Asset Registry foundation**만 구현한다.

Private Rules 본문 importer, `RulePackageResolver`, public release leak gate 전체는 다음 dedicated correction 범위다. 따라서 private rules profile blocker를 이번에 거짓 해제하지 않는다.

`rvtt.core.baseline`에 production asset이 실제로 존재하지 않는다면 registry가 빈 asset set을 안전하게 나타낼 수 있어야 한다. 존재하지 않는 prefab/model/thumbnail ID를 채우지 않는다.

## 7. Acceptance Matrix / Validator 변경

현재 validator가 `REQUIRED_FINAL_GAPS` 5개를 항상 BLOCKED로 강제하는 구조는 후속 구현 완료를 표현할 수 없다.

이번 성공 시 다음 구조로 개선한다.

- final-contract **항목 ID 5개 자체는 모두 필수**로 유지
- `finalContractGaps`는 현재 `BLOCKED`인 final-contract 항목의 실제 subset과 일치
- resolved item은 구체적인 Production Source + focused test/validator evidence 없이는 `STATIC_VERIFIED`로 바꿀 수 없음
- 이번 명령 성공 시 `final.asset-registry-separation`만 `STATIC_VERIFIED`
- `finalContractGaps`는 나머지 4개만 유지
- 다음 4개는 계속 `BLOCKED`
  - `final.official-2024-sheet-interactions`
  - `final.dice-slot-reveal-notice`
  - `final.core-rules-reader-filtering`
  - `final.rules-profile-release-leak-gate`
- Runtime/Human/Persistence/Performance evidence는 그대로 NOT_EXECUTED/DEFERRED

Validator negative fixtures는 최소 다음을 포함한다.

- source/server/client-safe 경계 중 하나 삭제 → fail
- client-safe record에 private/server-only field 삽입 → fail
- non-client-exportable asset/package를 client view에 포함 → fail
- duplicate assetId → fail
- missing rights/provenance → fail
- dependency cycle → fail
- asset-registry gap을 evidence 없이 해제 → fail
- 남은 final-contract blocker를 거짓 해제 → fail

## 8. Focused Tests

Production code와 함께 최소 다음 focused tests를 추가한다.

1. valid empty `rvtt.core.baseline` package/registry가 deterministic하게 compile/validate된다.
2. valid synthetic test-only token/prop fixture가 stable IDs와 required metadata를 통과한다.
3. duplicate asset ID 거부.
4. missing rights/provenance 거부.
5. missing token pivot/bounds/footprint 또는 필요한 metadata 거부.
6. dependency cycle 거부.
7. private/non-exportable record는 client-safe view에서 완전히 부재한다. placeholder/count inference도 남기지 않는다.
8. client-safe projection은 allowlisted field만 포함한다.
9. server registry/source identity drift 거부.
10. executable source/import payload declaration 거부.

테스트를 삭제, skip, 느슨하게 만들지 않는다.

## 9. 문서 상태 정정

성공한 경우에만 상태를 다음처럼 갱신한다.

```text
Phase 10 = HOLD / PARTIAL
ADR-0091 Asset Registry = STATIC_VERIFIED
remaining final-contract blockers = 4
next = ADR-0091 rules profile/release leak gate correction
Studio Human Retest = BLOCKED
```

그리고 현재 Work Order의 stale Player surface 문구 `Character Sheet / Journal·Map·Ping`에서 **별도 Player Map을 다시 요구하는 의미의 `Map`**을 제거/명확화한다. DM authoring/world tooling의 Map 개념까지 삭제하지 않는다.

## 10. 명시적 제외

이번 명령에서 하지 않는다.

- Official 2024 interactive Character Sheet 구현
- Dice Slot Reveal Notice 구현
- Core Rules Reader 구현
- Private integrated rules importer 본문 처리
- public SRD release leak gate 전체 구현
- ADR-0092 Actor Model Registry / AI authoring runtime
- Studio / Studio MCP / Human Playtest
- Persistence runtime
- Performance/Soak
- Player persistent Minimap
- separate Player Map
- Objective Tracker
- fabricated model/asset IDs
- private rules/content body를 public Git tree에 추가
- 새 gameplay-authority command
- test deletion/skip/assertion weakening
- validator/CI bypass
- force push
- PR Ready/Approve/Merge

## 11. 검증

최소 실행:

- focused Asset Registry tests
- `python implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`
- `python implementation/roblox/tooling/validate_implementation.py`
- remake docs/content/grand/persistence/lease validators where current repo normally runs them
- StyLua check
- Selene
- `git diff --check`
- all current Rojo project builds
- production/test/multi-client sourcemaps
- production/test Luau analysis

Studio/TestRunner runtime은 이번 명령에서 실행하지 않는다.

push 후 **새 current HEAD**의 관련 GitHub Actions를 실제 확인한다. failure/pending이 하나라도 있으면 PASS 금지.

## 12. 성공 조건

```text
actual Authoring Source boundary exists
+ actual Server Registry boundary exists
+ actual Client-safe Runtime projection/view exists
+ stable asset schema/validation exists
+ private/non-exportable negative disclosure enforced
+ focused leak/validation regressions exist
+ no fabricated production asset ids
+ acceptance validator supports real gap closure
+ final.asset-registry-separation only -> STATIC_VERIFIED
+ remaining four ADR-0091 blockers remain BLOCKED
+ stale Player Map Work Order drift corrected
+ local/static validation PASS
+ new current HEAD related GitHub Actions SUCCESS
→ command PASS
→ Phase 10 remains PARTIAL/HOLD with 4 blockers
```

## 13. 결과 댓글 형식

```text
<!-- RVTT_CODEX_ADR0091_ASSET_REGISTRY_RESULT -->
commandId: RVTT-PR2-ADR0091-ASSET-REGISTRY-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | PARTIAL | FAIL | BLOCKED | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_ASSET_REGISTRY
implementedBoundaries: <source/server/client-safe summary>
validationContract: <summary>
focusedTests: <summary>
acceptanceGapTransition: <asset-registry state + remaining gap count>
negativeDisclosure: <summary>
workOrderCorrection: <summary>
testsRun: <summary>
staticValidationStatus: PASS | FAIL
remoteCiStatus: SUCCESS | FAILURE | PENDING
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
phase10Status: HOLD | PARTIAL
nextCorrection: <next>
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <scope boundary>
```
