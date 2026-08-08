# RVTT Codex Implementation Command — Full UI·UX Acceptance Expansion

- commandId: `RVTT-PR2-FULL-UI-UX-ACCEPTANCE-IMPLEMENTATION-001`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`

## 1. 목표

Phase 4~9에서 정합화한 현재 UI Source를 기준으로 **실행 가능한 Full UI·UX Acceptance Matrix**를 등록한다.

이번 Phase의 핵심은 새 기능을 넓히는 것이 아니라 다음을 하나의 검증 계약으로 연결하는 것이다.

```text
accepted ADR / current final UI contract
→ current Production Source
→ automated/static evidence
→ Studio single-client evidence
→ multi-client evidence
→ Human UI/accessibility evidence
→ explicit blocked/deferred evidence
```

문서 체크리스트만 복사하지 않는다. 각 Acceptance 항목은 stable id, authority source, target surface/role, evidence class, executable test/batch 또는 human scenario, 현재 상태를 가져야 한다.

Phase 10이 성공해도 Studio Runtime PASS는 아니다. Phase 10 완료 뒤 별도 **new current-HEAD Static Gate**가 남는다.

## 2. 시작 Authority

실행 시작 시 최신 remote HEAD를 `targetShaAtStart`로 기록하고 다음을 읽는다.

```text
AGENTS.md
→ current PR #2 / current remote HEAD
→ .github/CODEX-ACTIVE-TASK.md
→ this command
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ AGENT-TEST-STATUS.md
→ ADR-0088 / ADR-0089 / ADR-0090 / ADR-0091
→ docs/remake/ui/shared/final-ui-content-implementation-contract.md
→ docs/remake/ui/policies/UI-UX-REVIEW-CHECKLIST.md
→ implementation/roblox/EXECUTION-TEST-RULES.md
→ implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md
→ implementation/roblox/grand-acceptance-manifest.json
→ current Source / current Tests
```

낮은 권위의 오래된 checklist/Work Order 문구가 Accepted ADR과 충돌하면 그대로 구현 요구로 승격하지 않는다.

## 3. High-authority stale-contract exception

다음은 현재 Player UI 방향이 아니다.

```text
Player persistent Minimap
separate Player Map
Objective Tracker
```

ADR-0089 이후 accepted direction과 현재 명시적 authority에 따라 위 세 항목을 Player persistent UI Acceptance로 요구하지 않는다.

따라서 기존 `UI-UX-REVIEW-CHECKLIST.md`, `CURRENT-WORK-ORDER.md`, `AGENT-TEST-STATUS.md` 등에 남은 다음 종류의 문구는 Phase 10에서 authority-aware하게 정리한다.

- Player Minimap 기본값/크기/방향을 필수 Acceptance로 요구
- Player separate Map을 Management surface로 요구
- Objective Tracker 존재를 Exploration HUD 필수 조건으로 요구
- `Journal·Map Permission·Navigation`을 Player separate Map 존재 조건으로 해석

필요하면 최소 문서 정정을 한다. 단 DM-only authoring/scene/world tooling의 map-like surface까지 임의 삭제하지 않는다.

## 4. Acceptance evidence class

각 항목은 최소 하나의 evidence class를 가진다.

```text
STATIC
STUDIO_SINGLE_CLIENT
STUDIO_MULTI_CLIENT
REAL_TRANSPORT
HUMAN_UI_UX
HUMAN_ACCESSIBILITY
PERSISTENCE_DEFERRED
PERFORMANCE_DEFERRED
CONTENT_DEFERRED
```

하나의 항목이 여러 evidence class를 요구할 수 있다.

규칙:

- Source/Static 존재만으로 Runtime PASS를 만들지 않는다.
- Studio Runtime만으로 Human visual/accessibility PASS를 만들지 않는다.
- Single-client PASS로 Multi-client/negative-disclosure PASS를 만들지 않는다.
- 일반 Runtime으로 Persistence/Performance/Release PASS를 만들지 않는다.
- 현재 Phase에서 실행하지 않은 evidence는 `NOT_EXECUTED`, `BLOCKED`, `DEFERRED`, `PLANNED` 중 사실에 맞는 상태로 둔다.

## 5. Acceptance Matrix 최소 범위

Codex는 현재 repository convention을 조사한 뒤 machine-readable matrix와 사람이 읽는 contract/summary를 최소 범위로 추가 또는 확장한다.

새 artifact 이름은 repository convention과 충돌하지 않는 범위에서 선택하되, 의미상 다음을 제공해야 한다.

```text
FullUiUxAcceptanceMatrix
├─ schemaVersion
├─ matrixId
├─ authoritySnapshot
├─ acceptanceItems[]
│  ├─ id
│  ├─ area
│  ├─ requirement
│  ├─ authorityRefs[]
│  ├─ roles[]
│  ├─ surfaces[]
│  ├─ evidenceClasses[]
│  ├─ automatedRefs[]
│  ├─ humanScenario?
│  ├─ currentState
│  └─ blocker/deferReason?
└─ runtimeBatches[]
```

Stable ids는 이후 report와 human evidence에서 재사용 가능해야 한다.

### A. Input · Direct Play

최소:

- ESC gameplay no-op
- Q one-context-back, no cascade
- E only current semantic confirm
- left-click controllable ally selection switching
- left-click default-action preview before execution
- right-click capability action table
- middle-drag camera orbit
- disabled-visible versus hidden-unperceived distinction
- disabled hover/focus viewer-safe reason
- movement/attack/interaction preview
- selection continuity
- no forced turn recenter
- pending / denied / stale / awaiting projection / reconciled distinction
- context table blocks world default left action while camera remains usable

### B. Exploration · Encounter HUD

최소:

- Exploration without Initiative/EndTurn
- Encounter adds initiative/resource/end-turn without replacing base shell
- movement/attack/interaction preview parity
- turn/resource/EndTurn state from projection
- selection continuity
- Observer safe HUD
- **no Player persistent Minimap / separate Map / Objective Tracker**

### C. Inventory · Journal · Settings

최소:

- Inventory/Equipment projection and authorized transfer intent
- hidden/private item negative disclosure
- Journal reader/navigation and authorized private create/edit intent
- no separate Player Map requirement
- Settings accent/UI scale/text scale/action rows/delay/motion/reset
- binding conflict safe presentation where current Source supports it
- preference changes do not restore gameplay authority
- focus/selection continuity where static/runtime evidence is appropriate

현재 Source가 아직 제공하지 않는 historical checklist feature를 acceptance fake-PASS로 만들지 않는다. 실제 gap이면 `BLOCKED` 또는 later-scope로 기록한다.

### D. Entry · Role · Recovery

최소:

- non-DM observer-first entry
- character selection alone does not grant Player
- authoritative assignment/capability transition
- owner/controller/session-role separation
- permission gain/loss UI behavior
- reconnect/full-sync revision/epoch rebuild
- stale projection dangerous-confirm block
- invalid selection fallback/deselect
- pending/preview/repeat/action-lock invalidation
- local preference survival without authority restore
- recovery/error boundary viewer-safe state
- modal/recovery input blocking
- negative disclosure on role loss

### E. DM Live Workspace

최소:

- DM-only modular window host
- local move/resize/dock/focus preference versus server authority separation
- Player View Preview uses server viewer policy
- Preview does not consume live target projection sequence
- control/override uses existing `dm.assign_control`, `dm.quick_action`, `dm.runtime_patch`, `dm.request_recovery`
- recovery/runtime-patch/quick-action/control reconciliation
- assign-control newer-revision proof
- terminal failure viewer-safe bounded local feedback
- permission-loss purge
- Player/Observer `dm_workspace` negative disclosure

### F. Shared UI / Accessibility / Responsive

현재 Source와 실제 가능 범위를 조사해 다음을 분류한다.

- semantic design tokens
- UI scale 0.80 / 1.00 / 1.40
- text scale current supported range
- focus visibility / keyboard focus
- long Korean label resilience
- reduced/minimal motion semantics if implemented
- modal click-through prevention
- 1280×720 through wide desktop responsive behavior

자동으로 증명할 수 없는 항목은 Human evidence로 분류한다. 테스트 코드가 없는데 Static PASS로 꾸미지 않는다.

### G. ADR-0091 final contract

`final-ui-content-implementation-contract.md` Acceptance를 current Source와 대조한다.

다음은 특히 현재 구현/테스트 존재 여부를 조사한다.

- Developer Asset Registry separation / client-safe leak
- Official 2024 Character Sheet interactions and revision parity
- Dice Slot Reveal Notice state contract
- Core Rules Journal Reader / permission filtering
- private integrated Korean rules profile versus public SRD leak gate

현재 Phase 4~9 Source 범위 밖이거나 아직 구현되지 않았다면 Phase 10에서 거대한 새 subsystem을 즉석 구현하지 않는다. Matrix에 명확한 `BLOCKED`, `DEFERRED`, 또는 별도 implementation follow-up으로 기록하고 Phase 10 결과에서 blocker 여부를 사실대로 보고한다.

Accepted final contract의 필수 Acceptance가 실제 Source에 없는데 문서만 등록하고 Phase 10을 PASS 처리해서는 안 된다.

## 6. Runtime Batch mapping

현재 사용자 수동 Runtime 그룹을 유지한다.

```text
G1 Grand Single-client
G2 Grand Multi-client
G3 Grand Real Transport
P1-P7 Persistence Runtime (deferred)
```

Acceptance Matrix의 실행 가능한 항목을 위 batch와 연결한다.

- G1: Direct Play, main HUD, management, settings, entry/recovery의 single-client 가능한 항목
- G2: DM/Player/Observer role, viewer projection, negative disclosure, role transition
- G3: real disconnect/reconnect/full sync
- Human UI/Accessibility: G1/G2 실행 후 screenshot/viewport/scale/focus evidence로 별도 판정
- P1-P7: 이번 Phase에서 실행하지 않고 deferred mapping만 유지

필요하면 `grand-acceptance-manifest.json` 또는 관련 runner/validator에 최소 additive metadata를 추가한다. 기존 Persistence 실행 계약이나 순서를 깨지 않는다.

## 7. Machine-readable validation

Matrix가 추가되면 typo와 drift를 막는 validator를 추가 또는 기존 validator에 통합한다.

최소 검사:

- duplicate acceptance id 금지
- unknown evidence class 금지
- authorityRefs 대상 경로 존재
- automatedRefs 대상 파일/known test id 존재 여부를 가능한 범위에서 검사
- `PASS`인데 evidence가 비어 있는 상태 금지
- Runtime/Human 미실행 항목의 거짓 PASS 금지
- deferred item은 reason 필수
- Player persistent Minimap / separate Player Map / Objective Tracker를 required acceptance로 재등록 금지
- required current role/negative-disclosure/recovery items 누락 탐지
- runtime batch ids는 manifest와 일치

Validator는 repository의 기존 `validate_implementation.py` 또는 별도 focused validator 중 유지보수성이 높은 쪽을 사용한다. CI path가 Matrix 변경을 놓치지 않도록 실제 workflow path coverage도 확인한다.

## 8. Existing tests mapping and focused gaps

현재 Unit/Integration/ContextInputAcceptance/MultiClient/RealTransport/Grand harness를 조사하고 acceptance item에 실제 test/source reference를 연결한다.

가능한 것은 기존 테스트를 재사용한다. 같은 계약을 검증하기 위해 새 parallel harness를 만들지 않는다.

다음은 focused static/automated assertion이 없고 작은 추가로 닫을 수 있을 때만 보강한다.

- no Player persistent minimap/map/objective tracker source assertion
- accepted ADR input grammar assertion
- role/negative-disclosure mapping completeness
- DM workspace reconciliation mapping completeness
- matrix validator self-tests/negative fixtures

Studio Human 시각 판단을 Luau Unit test로 가장하지 않는다.

## 9. 문서 상태 정합화

실제 결과에 맞춰 다음을 최소 정정한다.

```text
implementation/roblox/CURRENT-WORK-ORDER.md
AGENT-TEST-STATUS.md
implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md   (필요할 때만)
implementation/roblox/grand-acceptance-manifest.json (필요할 때만)
```

### 성공한 경우

```text
Phase 10 Full UI·UX Acceptance expansion → DONE
new current-HEAD Static Gate → REQUIRED / NEXT
Studio Human Retest → BLOCKED until that Static Gate PASS
```

Phase 10 DONE은 Matrix/Source/Static acceptance-registration 완료라는 뜻이다. Studio/Human Runtime PASS가 아니다.

### 필수 final-contract gap을 발견한 경우

해당 gap을 실제 blocker로 남긴다.

```text
Phase 10 → PARTIAL / HOLD
Studio → BLOCKED
next → focused implementation correction before Static Gate
```

거대한 ADR-0091 subsystem을 이번 Phase에 몰래 구현하지 않는다.

## 10. 검증

Repository에서 현재 요구하는 검증을 모두 실행한다.

최소:

```text
focused acceptance-matrix validator / tests
python implementation/roblox/tooling/validate_implementation.py
python implementation/roblox/tooling/validate_remake_docs.py
python implementation/roblox/tooling/validate_content_templates.py
python implementation/roblox/tooling/validate_grand_harness.py
python implementation/roblox/tooling/validate_grand_persistence.py
python implementation/roblox/tooling/validate_production_lease.py
StyLua --check
Selene
git diff --check
all required Rojo builds
default/test/multi-client sourcemaps
production/test Luau analysis
```

Studio / Roblox TestRunner / Human Playtest는 이번 command에서 실행하지 않는다.

Push 후 새 current HEAD의 관련 GitHub Actions를 실제 확인한다.

최소:

- Validate RVTT implementation
- Validate remake documentation
- Validate RVTT content templates
- Validate Grand harness
- Validate production lease

하나라도 failure/pending이면 PASS 금지.

주의: 위 CI 성공은 별도 `new current-HEAD Static Gate`의 운영상 최종 승인과 동일시하지 않는다. Phase 10 후 ChatGPT 검수를 거쳐 다음 command로 Static Gate를 확정한다.

## 11. 명시적 제외

이번 Phase에서 하지 않는다.

- Studio / Studio MCP / Human Runtime 실행
- Phase 11 Human Retest 실행
- Persistence Runtime 실행
- Performance / Soak 실행
- ADR-0092 Runtime
- Player persistent Minimap
- separate Player Map
- Objective Tracker
- 새 gameplay-authority command
- client gameplay authority
- hidden/private placeholder 또는 count inference
- 테스트 삭제/skip/assertion 약화
- validator/lint/CI bypass
- force push
- PR Ready/Approve/Merge

## 12. 성공 조건

PASS에는 최소 다음이 필요하다.

```text
current accepted authority 기반 Full UI·UX Acceptance Matrix 등록
+ stale minimap/map/objective requirements 제거 또는 authority-aware supersede
+ existing automated test/evidence mapping
+ G1/G2/G3/Human/deferred evidence class 분리
+ no evidence → no PASS invariant
+ current role/recovery/negative-disclosure/DM reconciliation coverage
+ final ADR-0091 acceptance gap audit
+ matrix validation gate
+ current Work Order / AGENT status sync
+ local/static checks PASS
+ new current HEAD related GitHub Actions SUCCESS
```

ADR-0091의 필수 Acceptance가 current Source에 실제로 빠져 있고 이번 Phase 범위를 넘어서는 implementation gap이면 `PARTIAL/HOLD`가 올바른 결과다.

## 13. 결과 댓글 형식

```text
<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->
commandId: RVTT-PR2-FULL-UI-UX-ACCEPTANCE-IMPLEMENTATION-001
targetShaAtStart: <sha>
resultHeadSha: <sha or unchanged>
resultStatus: PASS | PARTIAL | FAIL | BLOCKED | ABORTED_STALE_HEAD
phase: FULL_UI_UX_ALIGNMENT_PHASE_10
acceptanceArtifacts: <paths>
acceptanceItemCount: <count>
evidenceClassSummary: <counts/status>
staleContractCorrections: <what changed>
automatedEvidenceMapping: <summary>
runtimeBatchMapping: <G1/G2/G3/Human/deferred summary>
finalContractGapAudit: <none or explicit gaps>
negativeDisclosure: <status>
testsRun: <actual commands/results>
staticValidationStatus: <status>
remoteCiStatus: <new current-head workflow conclusions>
studioRuntimeStatus: NOT_EXECUTED
humanPlaytestStatus: NOT_EXECUTED
phase10Status: DONE | HOLD
nextGate: NEW_CURRENT_HEAD_STATIC_GATE | FOCUSED_IMPLEMENTATION_CORRECTION
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

## 14. ChatGPT 후속 검수

사용자가 `확인`이라고 하면 ChatGPT는:

1. PR #2 current HEAD를 다시 조회한다.
2. 최신 Phase 10 result comment를 찾는다.
3. target/result SHA와 실제 compare/files를 대조한다.
4. Acceptance Matrix와 validator를 직접 읽는다.
5. stale Minimap/Map/Objective 항목이 다시 required contract로 살아나지 않았는지 확인한다.
6. automated refs와 runtime batch mapping이 실제 repository와 맞는지 표본 검증한다.
7. ADR-0091 final-contract gap audit를 Source와 대조한다.
8. 새 HEAD GitHub Actions를 직접 확인한다.
9. 모두 맞으면 Phase 10을 승인하고 다음 `new current-HEAD Static Gate`로 진행한다.
10. Studio/Human PASS를 주장하지 않는다.
