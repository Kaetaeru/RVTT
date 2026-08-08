# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_5`
- commandPath: `.github/CODEX-IMPLEMENTATION-INPUT-CONTEXT-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002`
- previousCommandStatus: `PASS`
- studioRuntimeState: `BLOCKED_UNTIL_UI_ALIGNMENT_AND_NEW_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

Codex는 `commandPath`를 읽고 다음 **한 Phase만** 수행한다.

```text
Input·Context Action 정합화
→ Q · ESC · Left · Right · Middle · Availability
```

Phase 4 Shared Shell·Preference Foundation은 완료됐다. 이번 작업은 기존 Input Context·Semantic Router·World Action·Camera Source를 ADR-0088에 맞추는 Phase 5다.

## 현재 Authority

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ ADR-0088 direct-play pointer grammar
→ ADR-0089 / ADR-0090
→ common-input-grammar.md
→ final-ui-content-implementation-contract.md
→ implementation/roblox/CONTEXTUAL-POINTER-ACTIONS.md
→ EXECUTION-TEST-RULES.md
```

## 이번 Phase의 고정 계약

```text
Left Click
→ PrimaryPointer
→ 선택 또는 결정적 기본 행동

Right Click
→ ContextActionPointer
→ Action Table

Middle Drag
→ CameraOrbitPointer

Q
→ 최상위 Context 한 단계만 Pop

E
→ 현재 Confirm Context 확정

ESC
→ RVTT Gameplay 의미 없음
```

Action Availability는 다음을 구분한다.

```text
권한 없음·미인지
→ 노출하지 않음

권한 있음·현재 불가능
→ disabled + viewer-safe reason

권한 있음·현재 가능
→ enabled
```

Client Action Resolver는 Projection이며 Server Domain authorize를 우회하지 않는다.

## 중요한 경계

이번 작업은 Roblox Studio 수동 테스트가 아니다.
Codex Studio MCP도 사용하지 않는다.

```text
Phase 5 구현
→ 자동/정적 검증
→ 상태 문서 갱신
→ plain git commit/push
→ PR 결과 댓글
```

Phase 5가 실제 완료되지 않았거나 필요한 검증이 실패하면 Phase 6로 상태를 올리지 않는다.

Phase 6의 Full Exploration·Encounter HUD와 Movement/Attack/Area Preview Presentation을 이번 작업에서 선점하지 않는다.

사용자 Studio Human Retest는 계속 다음 뒤에만 진행한다.

```text
Phase 4~10 Full UI·UX Source·Acceptance alignment
→ 새 current-HEAD Static Gate PASS
→ 사용자 Studio Human Retest
```

## Codex 실행 절차

1. 이 파일의 `commandPath`를 연다.
2. PR #2의 최신 원격 HEAD를 조회하고 `targetShaAtStart`로 기록한다.
3. clean checkout이면 plain `git fetch`와 branch checkout/switch로 원격 `agent/survival-logistics-token-authoring`의 최신 HEAD에 맞춘다.
4. detached/과거 checkout이라는 이유만으로 중단하지 않는다.
5. 루트 `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 먼저 읽는다.
6. Phase 4 `DONE`, Phase 5 `IN_PROGRESS`를 확인한다.
7. 지정 Authority와 기존 Input/World Source를 조사한다.
8. 동일 책임의 기존 `InputContextStack`, `SemanticInputRouter`, `WorldActionMenu`, `WorldContextActionResolver`, `WorldTokenInputController`, `WorldCameraController`를 재사용한다.
9. `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001` 범위만 구현한다.
10. Repository가 정의한 가능한 정적/자동 검증과 관련 Input/Context Test를 실제로 실행한다.
11. 성공한 경우에만 Phase 5를 `DONE`, Phase 6을 `IN_PROGRESS`로 갱신한다.
12. 범위에 필요한 변경만 commit하고 같은 branch에 plain `git`으로 non-force push한다.
13. `gh` CLI는 요구하지 않는다.
14. Roblox Studio, MCP, Human Playtest는 실행하지 않는다.
15. PR Ready 전환, 승인, Merge를 하지 않는다.
16. 결과 게시 직전 원격 PR HEAD를 확인하고 지정 Marker의 Top-level Conversation Comment를 남긴다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 절차

사용자가 `확인해` 또는 `Codex 피드백 확인해`라고 지시하면:

1. PR #2의 현재 HEAD를 조회한다.
2. 최신 `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->` 댓글을 찾는다.
3. `commandId`가 `RVTT-PR2-INPUT-CONTEXT-IMPLEMENTATION-001`인지 확인한다.
4. `resultHeadSha`와 PR 현재 HEAD가 일치하는지 확인한다.
5. changedFiles와 testsRun을 실제 Repository 변경과 대조한다.
6. Q·ESC·Left·Right·Middle·Availability 계약과 Server Authority 보존을 확인한다.
7. PASS면 Phase 5 완료 여부만 인정하고 Phase 6으로 이어간다.
8. PARTIAL/BLOCKED면 구현·검증·push 중 실제 blocker를 분리한다.
9. Studio Runtime/Human PASS로 확대 해석하지 않는다.
