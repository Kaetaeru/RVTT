# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-PHASE9-CONTROL-REVISION-FIX-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_9_CONTROL_REVISION_FIX`
- commandPath: `.github/CODEX-FIX-PHASE9-CONTROL-REVISION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_PHASE9_REVISION_FIX_RESULT -->`
- resultStatus: `PENDING`
- previousFixCommand: `RVTT-PR2-PHASE9-QUEUE-RECONCILIATION-001`
- previousFixReportedStatus: `PASS`
- chatgptVerificationStatus: `PARTIAL_HOLD_EDGE_CASE`
- phase9ApprovalState: `HOLD_PENDING_CONTROL_REVISION_FIX`
- phase10State: `DO_NOT_ADVANCE_UNTIL_FINAL_VERIFICATION`
- studioRuntimeState: `BLOCKED_UNTIL_PHASE10_AND_NEW_CURRENT_HEAD_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

Phase 9의 마지막 reconciliation edge case만 수정한다.

```text
dm.assign_control
→ success receipt alone는 confirmed 금지
→ 제출 전부터 동일한 control 값이 있던 same/base revision projection도 confirmed 금지
→ command baseRevision보다 새로운 authoritative projection
   + expected actor/controller 일치
→ projection_confirmed
```

새 DM 기능이나 Phase 10 Acceptance 구현은 시작하지 않는다.

## ChatGPT 검수에서 확인된 마지막 blocker

이전 fix는 recovery duplicate, terminal failure viewer-safe feedback, 일반 control reconciliation을 수정했고 current-head Static/CI도 통과했다.

하지만 현재 `DmWorkspaceViewModel`의 control confirmation은 accepted command의 expected actor/controller와 현재 `dm_workspace.control` 값 일치만 검사하고 projection revision freshness를 요구하지 않는다.

따라서 다음 edge case에서 잘못된 조기 confirmation이 가능하다.

```text
revision R에서 이미 actor:A → user:22
→ 같은 actor:A → user:22를 다시 submit
→ success receipt 수신
→ 아직 새 projection은 오지 않음, 화면은 여전히 revision R
→ 기존 값이 같다는 이유만으로 projection_confirmed 가능
```

이 경우 올바른 상태는 `accepted_awaiting_projection`이다.

## 실행 규칙

1. `commandPath`를 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. current source와 실제 receipt/revision 계약을 조사한다.
4. pre-existing identical control assignment edge case를 재현 또는 정적으로 입증한다.
5. 최소 수정만 한다.
6. accepted control은 **baseRevision보다 새로운 authoritative projection** 또는 repository가 이미 제공하는 더 강한 committed-revision boundary를 만족해야만 confirmed할 수 있다.
7. 같은/base revision의 matching control 값은 confirmed 금지.
8. newer projection의 다른 controller도 confirmed 금지.
9. newer matching authoritative projection만 confirmed.
10. recovery dedup, terminal failure redaction/bounded history, role-loss/full-sync purge를 회귀시키지 않는다.
11. Player/Observer negative disclosure와 Player View Preview no-live-sequence-mutation 경계를 유지한다.
12. 새 gameplay-authority `dm.*` command를 추가하지 않는다.
13. focused tests에 pre-existing identical assignment case를 반드시 추가한다.
14. `CURRENT-WORK-ORDER.md`의 stale prose `DM Workspace와 Acceptance 정합화가 남아`를 성공 시 실제 상태에 맞게 최소 수정한다.
15. validator/formatter/lint/Rojo/sourcemap/Luau analysis를 실행한다.
16. Studio/Studio MCP/Human Playtest는 실행하지 않는다.
17. current PR branch에 non-force 반영한다.
18. push 후 새 current HEAD의 관련 GitHub Actions를 실제 확인한다.
19. 원격 CI 하나라도 failure/pending이면 PASS 금지.
20. 성공한 경우에만 Phase 9 final PASS를 보고하고 Phase 10을 IN_PROGRESS로 인정한다.
21. 지정 Marker로 PR #2 top-level 결과 댓글을 남긴다.

## 필수 focused regression

```text
A. success receipt alone → accepted_awaiting_projection
B. pre-existing matching control + same/base revision → accepted_awaiting_projection
C. newer projection + conflicting controller → NOT confirmed
D. newer projection + matching controller → projection_confirmed
```

그리고 이전 fix의 recovery dedup / terminal failure safe-redaction/bounding 회귀 테스트를 유지한다.

## 명시적 제외

- Phase 10 Acceptance 구현
- 새 DM Tool/feature
- 새 gameplay-authority command
- Full Scene Editor
- ADR-0092 Runtime
- Persistence Runtime
- Performance/Soak
- Studio / Human Runtime
- Player Minimap / separate Map / Objective Tracker
- test 삭제/skip/assertion 약화
- validator/lint/CI bypass
- force push
- PR Ready/Approve/Merge

## 성공 조건

```text
same/base revision의 pre-existing identical control이 조기 confirmed 되지 않음
+ success receipt alone confirmed 금지
+ newer conflicting projection confirmed 금지
+ newer matching projection confirmed
+ previous reconciliation fixes 유지
+ negative disclosure 유지
+ Work Order stale prose 수정
+ focused tests PASS
+ local/static validation PASS
+ new current HEAD related GitHub Actions SUCCESS
→ Phase 9 FINAL PASS eligible
→ Phase 10 IN_PROGRESS
```

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 하면:

1. PR #2 current HEAD를 다시 조회한다.
2. 최신 `<!-- RVTT_CODEX_PHASE9_REVISION_FIX_RESULT -->` 댓글을 찾는다.
3. target/result SHA와 실제 commit/files를 대조한다.
4. revision-aware control confirmation과 cases A-D focused tests를 직접 확인한다.
5. recovery/terminal failure regressions와 negative disclosure를 확인한다.
6. Work Order stale prose가 정정됐는지 확인한다.
7. 새 HEAD 관련 GitHub Actions를 직접 확인한다.
8. 모두 성공한 경우에만 Phase 9 final PASS를 인정한다.
9. 그 뒤에만 Phase 10 Acceptance로 진행한다.
