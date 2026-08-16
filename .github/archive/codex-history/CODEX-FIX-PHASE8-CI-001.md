# RVTT Codex Phase 8 CI Recovery

- commandId: `RVTT-PR2-PHASE8-CI-RECOVERY-001`
- taskType: `CI_FIX`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_8_CI_RECOVERY`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- failureSubjectSha: `2336fb76060a5933f9129949358b6e41b6e44b8e`
- failingWorkflow: `Validate RVTT implementation`
- failingRunId: `31256113909`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_CI_FIX_RESULT -->`

## 목적

Phase 8 `Entry · Role · Recovery` 구현 자체는 완료 보고됐으나, GitHub current evidence에서 `failureSubjectSha`의 `Validate RVTT implementation`이 실패했다.

이번 작업은 새 기능 구현이 아니다.

```text
실제 GitHub Actions 실패 로그 확인
→ root cause 특정
→ Phase 8 또는 CI 계약에 필요한 최소 수정
→ 관련 로컬 검증
→ non-force publish
→ 새 HEAD의 GitHub Actions 재확인
```

원격 CI가 실제로 성공하기 전에는 Phase 8을 최종 PASS로 확정하지 않는다.

## 시작 시 반드시 확인

1. 현재 PR #2 원격 HEAD와 branch를 확인한다.
2. `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
3. Phase 8 결과 댓글 `RVTT-PR2-ENTRY-ROLE-RECOVERY-IMPLEMENTATION-001`을 확인한다.
4. `failureSubjectSha=2336fb76060a5933f9129949358b6e41b6e44b8e`의 Actions 상태를 확인한다.
5. `gh auth status`를 확인한다.
6. `gh`로 실패한 `Validate RVTT implementation` run/job의 실제 로그를 읽는다.

권장 조사 순서:

```text
gh pr checks 2
→ gh run view 31256113909 --json name,workflowName,conclusion,status,url,event,headBranch,headSha
→ gh run view 31256113909 --log
→ 필요하면 failing job log를 gh api로 직접 조회
```

단순히 Codex의 이전 로컬 PASS 보고를 원격 CI 실패보다 우선하지 않는다.

## 수정 전 판정

로그에서 다음을 명확히 기록한다.

- failing step/check
- 핵심 failure snippet
- root cause
- Phase 8 변경과의 관련성
- 최소 수정 계획

### 수정 가능

다음 중 하나가 로그로 확인된 경우에만 수정한다.

- Phase 8 source/test의 실제 regression
- Phase 8에서 추가한 test가 repository CI 환경과 불일치
- Phase 8 변경으로 드러난 deterministic build/lint/type/static validation 오류
- CI 계약 자체의 명백한 결함이며 repository authority와 테스트 의도를 보존하는 최소 수정이 가능한 경우

### 수정하지 않고 보고

다음이면 Source를 억지로 바꾸지 않는다.

- GitHub infrastructure/transient outage
- 권한/secret/runner 문제
- Phase 8과 무관한 외부 서비스 실패
- 현재 HEAD에서 이미 동일 check가 성공해 해당 실패가 superseded됐고 추가 수정 근거가 없는 경우

이 경우 원인과 증거를 결과 댓글에 기록하고 적절한 status를 사용한다.

## 금지 사항

CI를 초록색으로 만들기 위해 아래를 하지 않는다.

- 실패한 test 삭제 또는 skip
- assertion 약화
- validator/lint/type check 비활성화
- workflow를 무조건 성공시키는 `|| true`/continue-on-error 류 우회
- coverage/negative disclosure/security 계약 축소
- Phase 9 DM Live Workspace 구현
- Phase 10 Acceptance 구현
- Studio/Human Playtest 실행 또는 PASS 주장
- ADR-0092 Runtime 확대
- Persistence Runtime 확대
- PR Ready/Approve/Merge

테스트나 CI 계약 자체가 잘못된 경우에는 상위 Authority와 실제 의도를 근거로 최소한만 고치고, 왜 test 변경이 정당한지 결과에 명시한다.

## Phase 8 계약 보존

수정 후에도 다음을 유지해야 한다.

- non-DM Observer-first
- DM-authoritative character assignment/revocation
- Character Owner / Runtime Controller / Session Role 분리
- authoritative projection 기반 role/UI transition
- reconnect/full-sync rebuild
- stale preview/pending/revision-bound intent invalidation
- role downgrade/revocation 시 private data/capability/invalid selection 제거
- Player/Observer에 DM-only projection/control 미노출
- viewer-safe recovery/error boundary
- client-side gameplay/role authority 금지

## 검증

root cause에 직접 관련된 focused test를 먼저 실행하고, 수정 후 최소 다음 current repository validation을 실행한다.

- implementation validator
- StyLua check
- Selene
- relevant Unit/Integration static analysis
- all repository-required Rojo builds/sourcemaps/Luau analysis that `Validate RVTT implementation` depends on
- `git diff --check`

가능한 경우 기존 Phase 8 테스트도 유지·재검증한다.

```text
EntryRecovery.spec.lua
EntryRoleRecovery.spec.lua
관련 MultiViewer/Projection/Session tests
```

## Publish 및 원격 CI 확인

1. 변경이 필요한 경우 현재 PR branch에 non-force commit/push한다.
2. push 뒤 새 PR HEAD를 기록한다.
3. 새 HEAD에서 `Validate RVTT implementation`을 포함한 관련 GitHub Actions를 `gh`로 재확인한다.
4. `Validate RVTT implementation`이 실제 `success`가 되기 전에는 `PASS`를 보고하지 않는다.
5. 다른 required workflow가 이번 수정 때문에 실패하면 함께 보고하고 PASS를 금지한다.

## Work Order / Test Status

현재 문서가 Phase 8 DONE / Phase 9 IN_PROGRESS로 적혀 있어도 이번 CI 실패 때문에 Phase 8 최종 승인 상태는 HOLD다.

- CI 복구 성공 시: Phase 8 Source/Static/CI를 최종 PASS로 확인하고 Phase 9 IN_PROGRESS 상태를 유지한다.
- CI 복구 실패/미해결 시: Phase 8 CI HOLD/BLOCKED 상태가 분명하도록 `AGENT-TEST-STATUS.md`를 실제 증거에 맞춘다. Phase 9 구현은 시작하지 않는다.
- `CURRENT-WORK-ORDER.md`는 실제 Gate 상태와 모순될 경우에만 최소 정정한다.

## 결과 댓글 형식

PR #2 top-level comment에 다음 Marker와 필드를 남긴다.

```text
<!-- RVTT_CODEX_CI_FIX_RESULT -->
commandId: RVTT-PR2-PHASE8-CI-RECOVERY-001
targetShaAtStart: <sha>
failureSubjectSha: 2336fb76060a5933f9129949358b6e41b6e44b8e
failingRunId: 31256113909
resultHeadSha: <sha or unchanged>
resultStatus: PASS | FAIL | BLOCKED | NO_CHANGE_REQUIRED | ABORTED_STALE_HEAD
failingStep: <step/job>
failureEvidence: <concise log evidence>
rootCause: <cause>
phase8Relation: <related/unrelated and why>
fixApplied: <summary or none>
changedFiles: <paths or none>
testsRun: <commands/results>
localValidationStatus: <status>
postPushWorkflowStatus: <Validate RVTT implementation and other relevant workflows>
phase8FinalStatus: PASS | HOLD | BLOCKED
currentWorkOrderStatus: <actual status>
agentTestStatusUpdated: true | false
failedChecks: <none or list>
blockerReason: <none or reason>
notes: <limitations>
```

`resultStatus: PASS`는 새 current HEAD의 관련 원격 GitHub Actions가 실제 성공한 경우에만 사용한다.
