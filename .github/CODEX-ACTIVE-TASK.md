# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ADR0091-ASSET-REGISTRY-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_ASSET_REGISTRY`
- commandPath: `.github/CODEX-IMPLEMENTATION-ADR0091-ASSET-REGISTRY-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_ASSET_REGISTRY_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-FULL-UI-UX-ACCEPTANCE-IMPLEMENTATION-001`
- previousCommandStatus: `PARTIAL_VERIFIED_BY_CHATGPT`
- phase9Status: `FINAL_PASS`
- phase10Status: `HOLD_5_ADR0091_FINAL_CONTRACT_GAPS`
- currentCorrection: `ASSET_REGISTRY_FOUNDATION`
- nextCorrectionOnSuccess: `RULES_PROFILE_RELEASE_LEAK_GATE`
- studioRuntimeState: `BLOCKED`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

ADR-0091 final-contract blocker 5개 중 **Asset Registry foundation 하나만** 실제 Production Source로 구현한다.

```text
content-source package boundary
→ Server-authoritative Content/Packs registry
→ ReplicatedStorage client-safe ContentRuntime view
→ stable asset validation
→ negative-disclosure/leak regression
→ Acceptance Matrix의 asset-registry blocker만 해제
```

Phase 10 전체는 이 작업 성공 후에도 HOLD다. 나머지 4개 blocker를 거짓 PASS로 만들지 않는다.

## 현재 확인된 blocker

```text
content-source/
→ absent

ServerStorage/RVTT/Content
→ BuiltinPackIndex.lua only

ReplicatedStorage/RVTT/ContentRuntime
→ absent

Acceptance
→ final.asset-registry-separation = BLOCKED
```

## 실행 규칙

1. `commandPath`를 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. `AGENTS.md`, Work Order, AGENT-TEST-STATUS, ADR-0091, final UI/content contract, Acceptance Matrix/validator를 읽는다.
4. 중복 Content authority를 만들지 말고 기존 `BuiltinPackIndex.lua`와 연결한다.
5. Authoring Source / Server Registry / Client-safe Runtime View 세 경계를 실제 source로 만든다.
6. 존재하지 않는 production model/prefab/thumbnail/Roblox asset ID를 발명하지 않는다.
7. 실제 production asset이 없다면 empty registry를 지원하고 synthetic fixture는 tests에만 둔다.
8. Stable Asset Record와 kind-specific validation을 구현한다.
9. duplicate IDs, identity drift, rights/provenance 누락, pivot/bounds/footprint 등 kind-specific metadata 누락, dependency cycle, invalid performance budget을 거부한다.
10. executable source/import payload declaration을 fail closed한다.
11. client-safe view는 allowlist projection이어야 하고 private/non-exportable record는 placeholder/count inference 없이 부재해야 한다.
12. current `BuiltinPackIndex`의 core rules/test rules/core baseline package 의미는 유지한다.
13. Private Rules importer/Profile Resolver/Release leak gate 전체는 이번에 구현하지 않는다.
14. Acceptance validator의 final gaps를 영구 5개 BLOCKED로 강제하는 구조를 실제 gap subset 방식으로 개선한다.
15. 성공 시 `final.asset-registry-separation`만 `STATIC_VERIFIED`, 나머지 4개는 `BLOCKED`다.
16. Runtime/Human/Persistence/Performance 상태는 승격하지 않는다.
17. Work Order에 남은 별도 Player Map 의미의 stale `Journal·Map·Ping` 문구를 최소 정정한다.
18. focused tests + 기존 전체 static/build/lint/type 검증을 실행한다.
19. Studio/Studio MCP/Human Playtest는 실행하지 않는다.
20. current PR branch에 non-force 반영한다.
21. push 후 새 current HEAD 관련 GitHub Actions를 실제 확인한다.
22. failure/pending이 하나라도 있으면 PASS 금지.
23. 지정 Marker로 PR #2 top-level 결과 댓글을 남긴다.

## 필수 focused regression

```text
valid empty baseline registry
valid synthetic test-only token/prop fixture
duplicate asset ID rejection
missing rights/provenance rejection
missing token geometry/metadata rejection
dependency cycle rejection
private/non-exportable item absent from client-safe view
client-safe allowlist only
source/server identity drift rejection
executable payload declaration rejection
```

Acceptance validator도 다음을 거부해야 한다.

```text
asset-registry source/server/client-safe boundary missing
asset-registry blocker evidence 없이 해제
remaining four ADR-0091 blockers 거짓 해제
stale Player Minimap/separate Map/Objective Tracker 재도입
runtime/human false PASS
```

## 성공 상태

```text
ADR-0091 Asset Registry = STATIC_VERIFIED
Phase 10 = PARTIAL / HOLD
remaining blockers = 4
next = RULES_PROFILE_RELEASE_LEAK_GATE correction
new current-HEAD Static Gate = NOT YET
Studio Human Retest = BLOCKED
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
```

## 명시적 제외

- Official 2024 interactive Character Sheet
- Dice Slot Reveal Notice
- Core Rules Reader
- private integrated rules importer body processing
- public SRD release leak gate 전체 구현
- ADR-0092 Runtime
- Player persistent Minimap / separate Player Map / Objective Tracker
- fabricated asset IDs
- private rules body in public Git tree
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
2. 최신 `RVTT_CODEX_ADR0091_ASSET_REGISTRY_RESULT` 댓글 확인
3. target/result SHA와 실제 compare/files 대조
4. Source/Server/Client-safe 세 경계 직접 확인
5. focused validation/leak tests 직접 확인
6. private/non-exportable negative disclosure 확인
7. Acceptance Matrix/validator가 asset blocker만 해제했는지 확인
8. 나머지 4 blocker가 유지되는지 확인
9. Work Order Player Map drift 정정 확인
10. current HEAD GitHub Actions 직접 확인
11. 모두 맞아야 이 correction PASS 인정
12. Studio/Human PASS 확대 금지
