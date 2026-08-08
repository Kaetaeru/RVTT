# Codex Implementation Fix — ADR-0091 Core Rules Private Stable Links 001

- commandId: `RVTT-PR2-ADR0091-CORE-RULES-PRIVATE-STABLE-LINK-FIX-001`
- taskType: `IMPLEMENTATION_FIX`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_CORE_RULES_PRIVATE_STABLE_LINK_FIX`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_CORE_RULES_PRIVATE_LINK_FIX_RESULT -->`

## 1. 목적

이 작업은 Core Rules Reader의 private integrated importer에서 남은 **stable-link normalization 결함만** 수정한다.

현재 ChatGPT 독립 검증 결과:

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader engine/filter/lazy-load = STATIC 구조 구현됨
Core Rules Reader private stable-link import = HOLD
Official 2024 Character Sheet = BLOCKED
Dice Slot Reveal Notice = BLOCKED
Studio/Human Runtime = NOT_EXECUTED
```

현재 Acceptance Matrix의 `final.core-rules-reader-filtering = STATIC_VERIFIED`와 `finalContractGaps = 2`는 이번 repair가 통과하기 전까지 **premature/untrusted**로 취급한다.

이번 작업이 성공하면 Core Rules Reader를 다시 `STATIC_VERIFIED`로 인정하고 남은 final gap을 Official Sheet + Dice Notice 2개로 유지할 수 있다.

Official Sheet나 Dice Notice는 시작하지 않는다.

## 2. 시작 시 확인

1. 이 command를 가장 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. `.github/CODEX-ACTIVE-TASK.md`, `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
4. ADR-0091 및 final UI/content implementation authority를 읽는다.
5. 최소 다음 Source/Test/Tooling을 직접 읽는다.
   - `implementation/roblox/tooling/build_private_rules_runtime.py`
   - `implementation/roblox/tooling/_build_private_rules_runtime_base.py`
   - `implementation/roblox/tooling/prepare_private_rules_runtime.py`
   - `implementation/roblox/tooling/validate_private_rules_runtime_pipeline.py`
   - `implementation/roblox/tooling/validate_core_rules_reader.py`
   - `implementation/roblox/src/ServerStorage/RVTT/Content/RuleRuntimePackageBinding.lua`
   - `implementation/roblox/src/ServerScriptService/RVTT/Server/Networking/RuleReaderQuery.lua`
   - `implementation/roblox/src/ServerScriptService/RVTT/RuleReaderBoot.server.lua`
   - `implementation/roblox/tests/Unit/CoreRulesReader.spec.lua`
   - `implementation/roblox/tests/Unit/RuleRuntimePackageBinding.spec.lua`
   - `implementation/roblox/tests/Unit/RuleReaderQueryAccess.spec.lua`
   - `implementation/roblox/tests/Unit/RemoteBootstrap.spec.lua`
   - `implementation/roblox/tests/TestRunner.server.lua`
   - `implementation/roblox/full-ui-ux-acceptance-matrix.json`
   - `implementation/roblox/FULL-UI-UX-ACCEPTANCE.md`
6. private source binding이 사용 가능하면 pinned source `Kaetaeru/D-D-2024-` commit `d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4`, source root `10-RULEBOOKS/integrated-2024`의 Markdown link inventory를 실제로 확인한다. private body를 RVTT public Git tree에 복사/commit하지 않는다.
7. private repository 접근이 불가능한 환경이어도 public-safe synthetic fixture만으로 구현/검증 가능해야 한다. 단, 실제 pinned corpus에 존재하는 known path patterns를 command 계약으로 반영한다.

## 3. 확인된 결함

### A. unresolved/out-of-root Markdown link가 raw source path로 runtime text에 남음

현재 `normalize_markdown_links()`는 `_resolve_rule_uri()`가 `None`을 반환하면 원래 Markdown link를 그대로 둔다.

실제 pinned private corpus에는 예를 들어 다음 유형이 존재한다.

```text
integrated-2024/README.md
→ playing-the-game/README.md 등 directory README navigation

integrated-2024/character-creation/README.md
→ create-your-character.md 같은 in-root document link
→ ../../../00-QUICK-RULES/10-character-creation.md 같은 sourceRoot 밖 repository-relative link
→ ../README.md 같은 in-root parent link
```

따라서 현재 importer는 일부 링크를 stable `rvtt-rule://...`로 바꾸지만, resolve할 수 없는 local Markdown target이나 sourceRoot 밖 local path를 raw relative path로 runtime RuleReaderPackage text에 남길 수 있다.

이는 다음 계약과 충돌한다.

```text
private source/repository topology가 viewer runtime body에 raw path로 새지 않음
imported internal rule navigation은 stable rvtt-rule:// anchor 사용
relatedLinks/backlinks는 실제 imported/authorized rule target만 가리킴
모든 emitted rvtt-rule:// link는 Reader가 resolve 가능
```

### B. synthetic private pipeline이 link behavior를 실행 검증하지 않음

현재 `validate_private_rules_runtime_pipeline.py` synthetic Markdown fixture는 내부 Markdown link를 만들지 않는다.

따라서 CI가 green이어도 다음 회귀를 잡지 못한다.

```text
in-root cross-document link normalization
same-document/cross-document fragment anchor normalization
duplicate heading stable anchor
sourceRoot escape link nondisclosure
missing local target nondisclosure
relatedLinks/backlinks reciprocity
raw repository-relative Markdown path leakage
```

## 4. 필수 링크 정책

이 repair에서 정책을 다음처럼 고정한다.

### 4.1 imported sourceRoot 내부의 실제 target

- 현재 package로 import되는 Markdown document/README target이면 반드시 `rvtt-rule://<privatePackage>/<module>/<document>[#anchor]`로 변환한다.
- fragment가 있으면 실제 normalized stable section anchor로 변환한다.
- duplicate heading은 importer가 이미 만드는 deterministic suffix(`-2`, `-3`, ...)와 일관돼야 한다.
- `relatedLinks`에는 stable URI만 기록한다.
- target document/section의 first chunk에 reciprocal `backlinks`를 기록한다.
- same target 중복 link는 deterministic dedupe한다.

### 4.2 repository-relative이지만 sourceRoot 밖 target

예: `../../../00-QUICK-RULES/...md`.

이 target은 현재 private integrated `RuleContentPackage`의 import authority 밖이다.

필수 처리:

- raw relative repository path를 runtime chunk text에 남기지 않는다.
- `relatedLinks`/`backlinks`에 넣지 않는다.
- 링크 label의 사람에게 보이는 텍스트는 보존할 수 있지만 **plain text/non-link**로 downgrade한다.
- viewer에게 source repo URL, git ref, filesystem path, binding path를 새 metadata로 노출하지 않는다.
- 필요하면 importer manifest에 aggregate diagnostic count/reason을 기록할 수 있으나 private path 문자열을 client runtime package에 싣지 않는다.

### 4.3 sourceRoot 내부를 가리키지만 target이 존재하지 않는 local Markdown link

- raw broken relative path를 runtime text에 남기지 않는다.
- 사람에게 보이는 label은 plain text로 보존한다.
- `relatedLinks`/`backlinks`에 넣지 않는다.
- importer가 deterministic diagnostic count/reason을 기록해도 된다.
- 이 repair에서 실제 pinned corpus를 import 불가능하게 만드는 전면 fail-closed 정책으로 바꾸지 않는다. Source body 자체의 이미 존재하는 broken navigation은 safe downgrade로 격리한다.

### 4.4 external scheme URL

- `https:`, `http:` 등 명시적 external scheme은 기존 일반 Markdown link text로 보존할 수 있다.
- `relatedLinks`/`backlinks`에는 넣지 않는다.
- Reader의 `rvtt-rule://` resolver 대상으로 가장하지 않는다.

### 4.5 기존 rvtt-rule:// 입력

- imported private package에서 `relatedLinks`에 넣는 `rvtt-rule://` URI는 현재 generated package에서 실제 resolve 가능한 target이어야 한다.
- 임의 package/unknown document/unknown anchor를 blind pass-through해서 `relatedLinks`에 넣지 않는다.
- 기존 source text에 invalid/nonresolvable rule URI가 있다면 safe downgrade 또는 deterministic import diagnostic으로 처리하고 raw trusted related link로 승격하지 않는다.

## 5. 구현 요구

1. `build_private_rules_runtime.py`의 link catalog/normalization을 위 정책에 맞춘다.
2. README document 포함과 module/document ID mapping이 실제 generated package의 IDs와 정확히 일치해야 한다.
3. source text 변환 후에도 모든 semantic chunk는 UTF-8 기준 16KB 이하를 유지한다.
4. 변환 결과에서 local repository-relative `.md` navigation target이 raw link destination으로 남지 않게 한다.
5. `relatedLinks`의 모든 `rvtt-rule://` URI를 generated package catalog에 대해 validate한다.
6. reciprocal backlink target은 실제 target document/section의 first chunk여야 한다.
7. backlinks 자체도 stable URI만 포함하고 unauthorized/source path metadata를 포함하지 않는다.
8. deterministic ordering/deduplication을 유지해 같은 source에서 생성 결과가 흔들리지 않게 한다.
9. private body/source content를 RVTT public repository에 commit하지 않는다.
10. Rules Profile fallback, owner-only access, nondisclosure-before-profile-resolution, release leak gate를 회귀시키지 않는다.

## 6. 필수 regression — Python synthetic runtime pipeline

`validate_private_rules_runtime_pipeline.py` synthetic source에 **실제 link graph**를 추가하고 최소 다음을 실행 검증한다.

```text
A.md -> B.md
A.md -> B.md#existing-heading
A.md -> B.md#duplicate-heading-2 또는 동등한 deterministic duplicate anchor
A.md -> ../또는 하위 directory README.md (실제 존재 target)
A.md -> missing-local.md
A.md -> sourceRoot 밖 ../../../outside.md
A.md -> https://example.invalid/reference
```

검증해야 할 결과:

- existing in-root document link -> stable private rvtt-rule URI
- valid fragment -> 실제 stable anchor URI
- duplicate heading fragment -> deterministic suffixed stable anchor
- existing README navigation -> stable URI
- missing local target -> raw `.md` path가 runtime package text에 없음, related/backlink 없음
- sourceRoot escape -> raw source-relative path가 runtime package text에 없음, related/backlink 없음
- external URL -> related/backlink에 들어가지 않음
- every generated related `rvtt-rule://` URI resolves to generated document/anchor
- reciprocal backlink exists exactly where expected
- no duplicate related/backlink entries
- chunk size <= 16KB after normalization
- generated Rojo overlay build remains PASS

기존 negative regression도 유지한다.

```text
wrong revision
wrong digest
wrong content count
dirty source
missing source
missing authorized viewer allowlist
```

## 7. Focused validator 강화

`validate_core_rules_reader.py` 또는 적절한 focused validator가 최소 다음 drift를 거부해야 한다.

- link-normalization function/behavioral pipeline test 제거
- synthetic link graph 제거
- `RuleReaderQueryAccess.spec.lua` focused registration 제거
- `RuleRuntimePackageBinding.spec.lua` registration 제거
- raw sourceRoot-escape/local Markdown path를 allowed related link로 되돌리는 명백한 bypass

단순 marker count만 늘리는 것으로 끝내지 말고 가능한 검증은 실제 synthetic importer output을 통해 수행한다.

참고: `TestRunner.server.lua`가 `RemoteBootstrap.spec.lua`를 실행하고, `RemoteBootstrap.spec.lua`가 `CoreRulesReader.spec`, `RuleRuntimePackageBinding.spec`, `RuleReaderQueryAccess.spec`를 호출하는 현재 등록 구조는 유효하다. 별도 중복 runner를 만들 필요는 없다.

## 8. Acceptance 상태

이번 repair 시작 시 ChatGPT 판정은:

```text
final.asset-registry-separation = STATIC_VERIFIED
final.rules-profile-release-leak-gate = STATIC_VERIFIED
final.core-rules-reader-filtering = HOLD_PENDING_PRIVATE_STABLE_LINK_FIX
final.official-2024-sheet-interactions = BLOCKED
final.dice-slot-reveal-notice = BLOCKED
```

현재 Matrix 파일이 Core Reader를 `STATIC_VERIFIED`로 기록하고 있더라도 그 상태 자체를 성공 증거로 사용하지 않는다.

repair가 모든 필수 요구와 current-head Actions를 통과한 경우에만:

```text
final.core-rules-reader-filtering = STATIC_VERIFIED
finalContractGaps = 2
Phase 10 = PARTIAL / HOLD
next = Official 2024 Character Sheet
```

repair가 불완전하면 결과를 `PARTIAL` 또는 `FAIL`로 남기고 Core Reader를 PASS로 주장하지 않는다.

## 9. 기존 기능 보존

다음을 회귀시키지 않는다.

- Asset Registry STATIC PASS
- BuiltinPackIndex single package authority
- private pinned revision/digest/count validation
- private generated overlay outside public Git tree
- explicit authorizedUserIds owner-only access
- unauthorized viewer pre-resolution nondisclosure
- explicit `allowSrdFallback=true` runtime wiring
- public/release/artifact SRD-only
- public release filesystem leak gate
- client-safe RuleProfileStatus allowlist
- Reader manifest body/chunk graph 비복제
- lazy open/chunk loading
- hidden module title/count/snippet/link/body nondisclosure
- Session authoritative role marker
- Player persistent Minimap / separate Player Map / Objective Tracker 금지
- Runtime/Human/Persistence/Performance 상태 미승격

## 10. 검증

최소 다음을 실행한다.

- updated `validate_private_rules_runtime_pipeline.py` with actual link graph
- `validate_core_rules_reader.py`
- `validate_full_ui_ux_acceptance.py`
- `validate_implementation.py`
- existing rules profile/release leak validator
- StyLua check
- Selene
- repository-required Rojo builds/sourcemaps
- production/tests Luau type analysis
- 관련 PowerShell bootstrap/self-tests

가능하면 importer output을 두 번 생성해 deterministic stable-link output도 비교한다.

push 후 **result HEAD의 모든 PR-triggered GitHub Actions**를 확인한다. failure/pending/cancelled가 하나라도 있으면 PASS 금지.

Studio/Studio MCP/Human Playtest는 이번 repair에서 실행하지 않는다.

## 11. 명시적 제외

- private copyrighted rule body를 RVTT public Git에 commit
- private repository history rewrite 또는 pin 임의 변경
- Official 2024 Character Sheet 구현
- Dice Slot Reveal Notice 구현
- ADR-0092 Runtime
- Persistence Runtime
- Performance/Soak
- new gameplay authority
- tests 삭제/skip/assertion 약화
- validator/CI bypass
- force push
- PR Ready/Approve/Merge

## 12. 결과 댓글 형식

PR #2 top-level Conversation에 다음 marker로 결과를 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_CORE_RULES_PRIVATE_LINK_FIX_RESULT -->
commandId: RVTT-PR2-ADR0091-CORE-RULES-PRIVATE-STABLE-LINK-FIX-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | PARTIAL | FAIL | BLOCKED | ABORTED_STALE_HEAD
changedFiles:
  - <path>
privateLinkPolicyEvidence:
  inRootDocument: <evidence>
  fragments: <evidence>
  duplicateAnchor: <evidence>
  missingLocal: <evidence>
  sourceRootEscape: <evidence>
  externalUrl: <evidence>
  rawPathNondisclosure: <evidence>
relatedBacklinkEvidence: <evidence>
focusedRegression:
  - <command/result>
validators:
  - <command/result>
currentHeadActions:
  - <workflow/result>
studioRuntime: NOT_EXECUTED
humanRuntime: NOT_EXECUTED
remainingFinalContractGaps: <2 only if PASS, otherwise 3>
next: <OFFICIAL_2024_CHARACTER_SHEET only if PASS; otherwise repair remaining issue>
```

결과 댓글 이후 commit/push가 더 발생했다면 그 댓글은 stale다. 최종 result HEAD와 current PR HEAD가 일치하는지 확인하고 필요하면 결과 댓글을 갱신한다.
