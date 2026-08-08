# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-PHASE8-CI-RECOVERY-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `CI_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_8_CI_RECOVERY`
- commandPath: `.github/CODEX-FIX-PHASE8-CI-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- failureSubjectSha: `2336fb76060a5933f9129949358b6e41b6e44b8e`
- failingWorkflow: `Validate RVTT implementation`
- failingRunId: `31256113909`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_CI_FIX_RESULT -->`
- resultStatus: `PENDING`
- previousCommand: `RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001`
- previousCommandReportedStatus: `PASS`
- phase8ApprovalState: `HOLD_PENDING_REMOTE_CI_RECOVERY`
- phase9ImplementationState: `DO_NOT_START`
- studioRuntimeState: `BLOCKED_UNTIL_UI_ALIGNMENT_AND_NEW_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

새 기능을 구현하지 않는다.

```text
Phase 8 remote CI failure 조사
→ 실제 Actions log 확보
→ root cause 특정
→ 필요한 최소 수정
→ local validation
→ publish
→ 새 HEAD remote CI success 확인
```

현재 알려진 충돌:

```text
Codex Phase 8 local/static report → PASS
GitHub HEAD 2336fb76060a5933f9129949358b6e41b6e44b8e
Validate RVTT implementation → FAILURE
```

원격 CI 증거가 우선한다. Phase 8은 현재 최종 승인 HOLD이며 Phase 9 구현을 시작하지 않는다.

## 실행 규칙

1. `commandPath`를 먼저 읽는다.
2. PR #2 최신 HEAD와 현재 branch를 확인한다.
3. `gh auth status` 후 실패 run `31256113909`의 실제 job/log를 `gh`로 확인한다.
4. 수정 전에 failing step, failure snippet, root cause, Phase 8 관련성, 최소 fix plan을 확정한다.
5. Phase 8과 무관한 transient/infrastructure 문제라면 Source를 억지로 변경하지 않는다.
6. 수정이 필요하면 실패 원인에 직접 필요한 최소 변경만 한다.
7. test 삭제/skip, assertion 약화, validator/lint/type bypass, `|| true`, continue-on-error 같은 CI 우회를 금지한다.
8. Phase 8 observer-first/assignment/recovery/negative-disclosure 권위 계약을 보존한다.
9. 관련 focused test와 repository-required implementation validation을 다시 실행한다.
10. 변경이 있으면 현재 PR branch에 non-force 반영한다.
11. 새 HEAD의 `Validate RVTT implementation` 및 관련 required workflows를 `gh`로 재확인한다.
12. 원격 check가 실제 success가 아니면 PASS로 보고하지 않는다.
13. Phase 9, Phase 10, Studio/Human, ADR-0092 Runtime, Persistence Runtime은 수행하지 않는다.
14. 지정 Marker를 사용해 PR #2 top-level 결과 댓글을 남긴다.

## 성공 조건

```text
실패 root cause가 증거로 설명됨
+ 필요한 최소 fix만 적용됨
+ local relevant validation PASS
+ 새 current HEAD Validate RVTT implementation SUCCESS
+ 다른 관련 required workflow도 실패 없음
→ Phase 8 최종 PASS 인정 가능
→ Phase 9 IN_PROGRESS로 복귀 가능
```

성공하지 못하면 Phase 8은 HOLD/BLOCKED로 유지한다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 확인

사용자가 `확인` 또는 `확인해`라고 지시하면:

1. PR #2 현재 HEAD를 다시 확인한다.
2. 최신 `<!-- RVTT_CODEX_CI_FIX_RESULT -->` 댓글을 찾는다.
3. root cause와 실제 Actions 로그 증거를 확인한다.
4. target/result SHA와 실제 commits/files를 대조한다.
5. 새 HEAD의 `Validate RVTT implementation`과 관련 workflow 상태를 직접 확인한다.
6. 모두 성공한 경우에만 Phase 8 최종 PASS를 인정한다.
7. 그 뒤에만 Phase 9를 진행한다.
