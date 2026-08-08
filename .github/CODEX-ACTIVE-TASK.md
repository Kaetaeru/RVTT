# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-PHASE9-QUEUE-RECONCILIATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_9_RECONCILIATION_FIX`
- commandPath: `.github/CODEX-FIX-PHASE9-QUEUE-RECONCILIATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_PHASE9_FIX_RESULT -->`
- resultStatus: `PENDING`
- previousImplementationCommand: `RVTT-PR2-DM-LIVE-WORKSPACE-IMPLEMENTATION-001`
- previousImplementationReportedStatus: `PASS`
- chatgptVerificationStatus: `PARTIAL_HOLD`
- phase9ApprovalState: `HOLD_PENDING_RECONCILIATION_FIX`
- phase10State: `DO_NOT_ADVANCE`
- studioRuntimeState: `BLOCKED_UNTIL_PHASE10_AND_NEW_CURRENT_HEAD_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

새 DM 기능을 추가하지 않는다.

```text
Phase 9 Queue / Receipt reconciliation fix
→ recovery duplicate 제거
→ control assignment projection confirmation
→ terminal denied/stale/failure viewer-safe feedback 유지
→ focused regression tests
→ local/static validation
→ publish
→ new current HEAD remote CI success 확인
```

## ChatGPT 검수에서 확인된 blocker

Phase 9 구현과 원격 CI 자체는 성공했지만, Source 검수에서 다음 결함이 확인됐다.

1. `dm.request_recovery` projected record는 stable key `recovery:<commandId>`를 가지지만 record.commandId가 없어 현재 generic dedup이 local pending과 연결하지 못한다.
2. `dm.assign_control` success pending은 authoritative `dm_workspace.control[actorId]`와 expected controller를 대조하지 않아 `projection_confirmed`로 수렴하지 못한다.
3. terminal failure receipt는 DM Workspace local pending에서 즉시 삭제되어 denied/stale/timeout/validation feedback이 보이지 않는다.
4. 기존 focused test는 runtime patch dedup은 검증하지만 위 recovery/control/failure 경계를 충분히 고정하지 않는다.

따라서 repository status 문서가 Phase 9 DONE/PASS를 표시하더라도 **최종 승인 상태는 HOLD**다. 이 Active Task와 연결된 fix command가 현재 explicit follow-up authority다.

## 실행 규칙

1. `commandPath`를 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. current Phase 9 Source/Test를 다시 조사해 위 root cause가 실제로 맞는지 확인한다.
4. 결함을 재현/정적으로 입증한 뒤 필요한 최소 수정만 한다.
5. 새 gameplay-authority `dm.*` command를 추가하지 않는다.
6. `DmWorkspaceDomain` state shape는 기존 stable identity로 해결할 수 있으면 변경하지 않는다.
7. recovery는 기존 `recovery:<commandId>` stable identity를 우선 활용한다.
8. control assignment는 submitted expected actor/controller와 authorized projection을 대조해 success receipt만으로 confirmed 처리하지 않는다.
9. terminal denied/stale/timeout/validation 등은 bounded local viewer-safe feedback으로 유지한다. authoritative history로 가장하지 않는다.
10. Player/Observer negative disclosure, Player View Preview server-policy parity, no live projection-sequence mutation을 보존한다.
11. role loss/full sync는 sensitive windows와 local pending/terminal feedback을 purge해야 한다.
12. recovery/control/failure focused tests와 기존 runtime patch/quick action regression test를 보강한다.
13. repository validator/formatter/lint/Rojo/sourcemap/Luau analysis를 실행한다.
14. Studio/Studio MCP/Human Playtest는 실행하지 않는다.
15. 변경은 current PR branch에 non-force 반영한다.
16. push 후 새 current HEAD의 관련 GitHub Actions를 실제 확인한다.
17. 원격 CI 하나라도 failure면 PASS로 보고하지 않는다.
18. 성공할 때만 Phase 9 final PASS, Phase 10 IN_PROGRESS로 상태 문서를 정정한다.
19. 실패/부분 완료면 Phase 9 HOLD, Phase 10 DO NOT ADVANCE를 유지한다.
20. 지정 Marker로 PR #2 top-level 결과 댓글을 남긴다.

## 명시적 제외

- Phase 10 Acceptance 구현
- 새 DM Tool/feature 추가
- Full Scene Editor
- ADR-0092 Runtime
- Persistence Runtime
- Performance/Soak
- Studio / Human Runtime
- Player Minimap / separate Map / Objective Tracker
- client gameplay authority
- hidden/private placeholder
- test 삭제/skip/assertion 약화
- validator/lint/CI bypass
- force push
- PR Ready/Approve/Merge

## 성공 조건

```text
recovery command local/projected row 정확히 1개로 수렴
+ assign_control은 authoritative projection 일치 뒤 confirmed
+ denied/stale/terminal failure가 bounded viewer-safe local feedback으로 표시
+ runtime patch/quick action regression 없음
+ role-loss purge 유지
+ negative disclosure 유지
+ focused tests PASS
+ local/static validation PASS
+ new current HEAD related GitHub Actions SUCCESS
→ Phase 9 FINAL PASS
→ Phase 10 IN_PROGRESS
```

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 하면:

1. PR #2 current HEAD를 다시 조회한다.
2. 최신 `<!-- RVTT_CODEX_PHASE9_FIX_RESULT -->` 댓글을 찾는다.
3. target/result SHA와 실제 commit/files를 대조한다.
4. recovery/control/failure reconciliation과 focused tests를 직접 확인한다.
5. 새 HEAD 관련 GitHub Actions를 직접 확인한다.
6. 모두 성공한 경우에만 Phase 9 final PASS를 인정한다.
7. 그 뒤에만 Phase 10 Acceptance로 진행한다.
