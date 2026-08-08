# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_8`
- commandPath: `.github/CODEX-IMPLEMENTATION-ENTRY-ROLE-RECOVERY-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-INVENTORY-JOURNAL-SETTINGS-IMPLEMENTATION-001`
- previousCommandStatus: `PASS`
- studioRuntimeState: `BLOCKED_UNTIL_UI_ALIGNMENT_AND_NEW_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

다음 한 Phase만 수행한다.

```text
Entry · Role · Recovery
→ Projection rebuild · Reconnect · Error Boundary
```

Phase 4~7은 완료됐다. 이번 Phase는 기존 Session/Character/Projection/Networking/Client Runtime 권위 경계를 재사용해 Entry, Role 전환, Reconnect, Recovery UI와 상태를 정합화한다.

## 핵심 계약

- non-DM은 authoritative assignment 전 Observer-first다.
- local selection/pending command만으로 Player 권위를 얻지 않는다.
- Character Owner / Runtime Controller / Session Role을 분리한다.
- 역할/캐릭터 전이는 서버 권위 + Projection 확인 뒤에만 UI/행동 권위를 바꾼다.
- reconnect/full sync는 authoritative Projection에서 다시 구축한다.
- stale preview/pending claim/revision-bound intent는 resync 후 재검증한다.
- local preference는 기존 preference boundary 안에서만 유지한다.
- 새 role에서 더 이상 보이지 않는 selection/private state/capability는 제거한다.
- recoverable network/projection error와 fatal boundary를 구분한다.
- Player/Observer에 DM-only 정보나 control을 placeholder로도 노출하지 않는다.
- client-side role/gameplay authority를 만들지 않는다.

## 실행 절차

1. `commandPath`를 읽는다.
2. PR #2 최신 원격 HEAD를 `targetShaAtStart`로 기록한다.
3. `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`와 지정 Authority를 읽는다.
4. Phase 7 `DONE`, Phase 8 `IN_PROGRESS`를 확인한다.
5. 기존 `SessionDomain`, `CharacterDomain`, Projection, Networking/full-sync, `ProjectionReplica`, `CommandClient`, `ClientRuntime`, App/Shell과 error/recovery utility를 조사한다.
6. 같은 책임의 기존 경로를 재사용하며 Phase 8 범위만 구현한다.
7. observer-first, authoritative role/assignment, reconnect/full-sync rebuild, stale invalidation, recovery/error boundary, negative disclosure 관련 테스트를 보강한다.
8. Repository가 정의한 정적/자동 검증을 실제 실행한다.
9. 모두 PASS한 경우에만 Phase 8을 `DONE`, Phase 9를 `IN_PROGRESS`로 갱신하고 `AGENT-TEST-STATUS.md`도 갱신한다.
10. 현재 PR branch에 non-force 반영한다.
11. 지정 Marker의 PR #2 top-level 결과 댓글을 남긴다.
12. Roblox Studio, Studio MCP, Human Playtest는 실행하지 않는다.
13. PR Ready·Approve·Merge를 하지 않는다.

## 범위 제외

- Phase 9 DM Live Workspace 구현
- Phase 10 Acceptance 완료
- Studio/Human PASS
- Persistence Runtime
- ADR-0092 Runtime 확대
- touch/controller 전용 UI
- Player minimap·별도 map·objective tracker
- client-side role/gameplay authority

## 성공 시 상태

```text
Phase 8 Entry·Role·Recovery → DONE
Phase 9 DM Live Workspace → IN_PROGRESS
Studio Human Retest → 계속 BLOCKED
```

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 지시하면 현재 PR HEAD, Phase 8 결과 Marker, `commandId/resultHeadSha`, 실제 changed files/tests, Work Order와 AGENT-TEST-STATUS 전이를 대조한다. PASS면 Phase 8 Source/Static 완료만 인정한다.