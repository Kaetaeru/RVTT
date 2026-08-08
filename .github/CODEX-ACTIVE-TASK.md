# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-FULL-UI-UX-ACCEPTANCE-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10`
- commandPath: `.github/CODEX-IMPLEMENTATION-FULL-UI-UX-ACCEPTANCE-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-PHASE9-CONTROL-REVISION-FIX-001`
- previousCommandStatus: `PASS_VERIFIED_BY_CHATGPT`
- phase9Status: `FINAL_PASS`
- phase10Status: `IN_PROGRESS_READY_FOR_CODEX`
- nextGateAfterSuccess: `NEW_CURRENT_HEAD_STATIC_GATE`
- studioRuntimeState: `BLOCKED_UNTIL_PHASE10_AND_NEW_CURRENT_HEAD_STATIC_GATE_PASS`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

Phase 10만 수행한다.

```text
Full UI·UX Acceptance Expansion
→ accepted authority 기반 machine-readable acceptance matrix
→ existing test/evidence mapping
→ G1/G2/G3/Human/deferred evidence separation
→ stale player Minimap/Map/Objective requirements 제거 또는 supersede
→ final ADR-0091 acceptance gap audit
→ validator/static/CI
```

새 게임 기능을 임의로 넓히지 않는다.

## 가장 중요한 Authority 예외

현재 Player persistent UI에는 다음을 요구하지 않는다.

```text
Minimap
separate Player Map
Objective Tracker
```

오래된 `UI-UX-REVIEW-CHECKLIST.md`, Work Order, status checklist에 이 항목이 남아 있더라도 accepted ADR/product direction보다 우선하지 않는다.

Phase 10 Acceptance Matrix에서 위 항목을 required Player feature로 다시 살리지 않는다.

## 실행 규칙

1. `commandPath`를 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. `AGENTS.md`, Work Order, AGENT-TEST-STATUS, ADR-0088~0091, final UI contract, Review Checklist, Execution Test Rules, Grand Acceptance/Manifest를 읽는다.
4. Phase 9 final PASS와 Phase 10 IN_PROGRESS를 확인한다.
5. current Source/Tests와 기존 ContextInputAcceptance/MultiClient/RealTransport/Grand harness를 조사한다.
6. Acceptance 항목을 stable id와 evidence class로 등록한다.
7. 문서 존재만으로 PASS를 만들지 않는다.
8. Static / Studio Single / Studio Multi / Real Transport / Human UI / Human Accessibility / Deferred 범위를 분리한다.
9. 기존 자동 테스트가 있는 항목은 실제 reference를 연결한다.
10. 자동 테스트가 없지만 작은 static assertion으로 닫을 수 있을 때만 focused regression을 추가한다.
11. Human visual/accessibility 판단을 Unit test로 가장하지 않는다.
12. stale Minimap/Map/Objective checklist와 Work Order/AGENT status를 accepted direction에 맞게 최소 정정한다.
13. ADR-0091 final contract Acceptance를 current Source와 대조한다.
14. 큰 미구현 subsystem이 발견되면 이번 Phase에서 몰래 구현하지 말고 explicit `BLOCKED/DEFERRED/follow-up`으로 남긴다.
15. machine-readable matrix drift validator를 추가/통합한다.
16. G1/G2/G3와 Human evidence, P1-P7 deferred mapping을 유지한다.
17. validator/formatter/lint/Rojo/sourcemap/Luau analysis를 실행한다.
18. Studio/Studio MCP/Human Playtest는 실행하지 않는다.
19. current PR branch에 non-force 반영한다.
20. push 후 새 current HEAD의 관련 GitHub Actions를 실제 확인한다.
21. 하나라도 failure/pending이면 PASS 금지.
22. 성공 시 Phase 10을 DONE으로 바꾸되 Studio를 READY로 만들지 않는다. 다음은 별도 `NEW_CURRENT_HEAD_STATIC_GATE`다.
23. 지정 Marker로 PR #2 top-level 결과 댓글을 남긴다.

## Evidence 상태 원칙

```text
Document exists != Static PASS
Static PASS != Studio Runtime PASS
Studio Runtime PASS != Human UI/UX PASS
Single-client PASS != Multi-client PASS
Runtime PASS != Persistence PASS
Runtime PASS != Performance/Soak PASS
```

실행하지 않은 항목은 사실대로 `NOT_EXECUTED`, `BLOCKED`, `DEFERRED`, `PLANNED`를 사용한다.

## Acceptance 핵심 범위

### Direct Play
- ESC no gameplay meaning
- Q one-context-back
- E semantic confirm only
- left/right/middle pointer grammar
- click-before-action preview
- action availability/hidden disclosure
- movement/attack/interaction preview
- selection continuity/no forced recenter
- pending/denied/stale/projection reconciliation

### HUD / Management / Settings
- Exploration/Encounter composition
- Observer-safe projection
- Inventory/Equipment/authorized transfer
- Journal permission/navigation
- Settings/preferences/binding-safe behavior
- no Player persistent Minimap / separate Map / Objective Tracker

### Entry / Recovery
- Observer-first non-DM
- authoritative assignment and role transition
- owner/controller/session-role separation
- reconnect/full-sync/epoch/revision recovery
- invalid selection/pending cleanup
- viewer-safe recovery/error boundary

### DM Workspace
- modular local window layout versus server authority
- Player View Preview server-policy parity
- no live target sequence mutation
- existing DM command bindings only
- projected queue reconciliation
- newer-revision assign-control proof
- terminal failure safe feedback
- role-loss purge and negative disclosure

### Final ADR-0091
Asset Registry, Official 2024 Sheet, Dice Reveal, Core Rules Reader, private/public rules profile/leak gate를 current Source와 대조한다. 실제 gap이면 숨기지 않는다.

## 성공 결과 상태

모든 Phase 10 범위가 충족되면:

```text
Phase 10 Full UI·UX Acceptance Expansion = DONE
next = NEW_CURRENT_HEAD_STATIC_GATE
Studio Human Retest = BLOCKED
Studio Runtime = NOT_EXECUTED
Human UI/UX = NOT_EXECUTED
```

필수 final-contract implementation gap이 발견되면:

```text
Phase 10 = HOLD / PARTIAL
next = focused implementation correction
Studio = BLOCKED
```

## 명시적 제외

- Studio / Studio MCP / Human Runtime 실행
- Phase 11 실행
- Persistence Runtime
- Performance/Soak
- ADR-0092 Runtime
- Player persistent Minimap
- separate Player Map
- Objective Tracker
- 새 gameplay-authority command
- hidden/private placeholder/count leak
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
2. 최신 `RVTT-PR2-FULL-UI-UX-ACCEPTANCE-IMPLEMENTATION-001` 결과 댓글 확인
3. target/result SHA와 실제 compare/files 대조
4. Acceptance Matrix와 validator 직접 검수
5. stale Minimap/Map/Objective required contract 재생성 여부 확인
6. automated refs / G1-G3 / Human / deferred mapping 표본 대조
7. ADR-0091 final-contract gap audit를 Source와 대조
8. current HEAD GitHub Actions 직접 확인
9. 모두 맞아야 Phase 10 승인
10. 그 뒤 별도 new current-HEAD Static Gate로 진행
11. Studio/Human PASS 확대 금지
