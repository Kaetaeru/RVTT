# RVTT Codex Active Task

- status: `READY_FOR_CODEX_EXECUTION`
- commandId: `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskType: `IMPLEMENTATION`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_4`
- commandPath: `.github/CODEX-IMPLEMENTATION-UI-FOUNDATION-002.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->`
- resultStatus: `PENDING`
- previousAttempt: `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-001`
- previousAttemptStatus: `BLOCKED_BEFORE_IMPLEMENTATION_GH_CLI_PREREQUISITE`
- studioRuntimeState: `BLOCKED_UNTIL_UI_ALIGNMENT_AND_NEW_STATIC_GATE`
- userManualRuntimeState: `NOT_STARTED_CURRENT_CONTRACT`
- updatedBy: `ChatGPT Lead Coordinator`
- updatedAt: `2026-08-08`

## 현재 활성 작업

Codex는 `commandPath`의 구현 명령을 읽고 다음 **한 Phase만** 수행한다.

```text
Shared Shell·Preference Foundation
→ Layer·Mode·System·Theme·Settings Store
```

이번 `002`는 이전 `001`의 재시도다. 이전 시도는 Source 수정 전에 `gh` CLI 필수 조건 때문에 중단됐다.

이번 작업에서는 **`gh` CLI를 구현 선행조건으로 사용하지 않는다.**

```text
`gh` 없음
→ 구현 계속
→ 가능한 정적 검증 계속
→ plain git commit/push 사용
→ 사용 가능한 GitHub 연결로 결과 댓글 게시
```

실제 plain git 인증이나 push 자체가 실패하면 그 단계의 실제 오류를 기록한다. `gh`가 없다는 이유만으로 Source 구현을 시작하지 않는 행동은 금지한다.

## 현재 Authority

```text
AGENTS.md
→ AGENT-TEST-STATUS.md
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ ADR-0091 + final-ui-content-implementation-contract.md
→ ADR-0090 / ADR-0089 / ADR-0088
→ implementation-ready-ui-ux-and-settings-spec.md (superseded 부분 주의)
→ final-ui-surface-gap-audit.md
→ EXECUTION-TEST-RULES.md
```

## 중요한 경계

이번 작업은 Roblox Studio 수동 테스트가 아니다.
Codex Studio MCP도 사용하지 않는다.

```text
Phase 4 구현
→ 자동/정적 검증
→ 상태 문서 갱신
→ plain git commit/push
→ PR 결과 댓글
```

Phase 4가 실제 완료되지 않았거나 필요한 검증이 실패하면 Phase 5로 상태를 올리지 않는다.

사용자 Studio Human Retest는 다음이 모두 끝난 뒤에만 진행한다.

```text
Phase 4~10 Full UI·UX Source·Acceptance alignment
→ 새 current-HEAD Static Gate PASS
→ 사용자 Studio Human Retest
```

## Codex 실행 절차

1. 이 파일의 `commandPath`를 연다.
2. PR #2의 최신 원격 HEAD를 조회하고 `targetShaAtStart`로 기록한다.
3. local checkout이 clean이면 plain `git fetch`와 branch checkout/switch로 원격 `agent/survival-logistics-token-authoring`의 최신 HEAD에 맞춘다.
4. detached/과거 checkout이라는 이유만으로 중단하지 않는다. clean checkout이면 최신 원격 branch에 맞추고 진행한다.
5. 루트 `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 먼저 읽는다.
6. 지정 Authority와 기존 Source를 조사한다.
7. 동일 책임의 기존 모듈을 재사용하고 중복 UI/Settings 체계를 만들지 않는다.
8. `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002`의 범위만 구현한다.
9. Repository가 정의한 가능한 정적/자동 검증을 실제로 실행한다.
10. 성공한 경우에만 CURRENT-WORK-ORDER와 AGENT-TEST-STATUS의 Phase 상태를 올바르게 갱신한다.
11. 범위에 필요한 변경만 commit하고 같은 branch에 plain `git`으로 non-force push한다.
12. `gh` CLI는 요구하지 않는다.
13. Roblox Studio, MCP, Human Playtest는 실행하지 않는다.
14. PR Ready 전환, 승인, Merge를 하지 않는다.
15. 결과 게시 직전 원격 PR HEAD를 확인하고 지정 Marker의 Top-level Conversation Comment를 사용 가능한 GitHub 연결로 남긴다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서 ChatGPT가 작성한 최신 활성 명령을 확인해 실행하고, 결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 절차

사용자가 `확인해` 또는 `Codex 피드백 확인해`라고 지시하면:

1. PR #2의 현재 HEAD를 조회한다.
2. 최신 `<!-- RVTT_CODEX_IMPLEMENTATION_RESULT -->` 댓글을 찾는다.
3. `commandId`가 `RVTT-PR2-UI-FOUNDATION-IMPLEMENTATION-002`인지 확인한다.
4. `resultHeadSha`와 PR 현재 HEAD가 일치하는지 확인한다.
5. changedFiles와 testsRun을 실제 repository 변경과 대조한다.
6. PASS면 Phase 4 완료 여부만 인정하고 Phase 5로 이어간다.
7. PARTIAL/BLOCKED면 실제 구현·검증·push 중 어디서 막혔는지 분리한다.
8. Studio Runtime/Human PASS로 확대 해석하지 않는다.
