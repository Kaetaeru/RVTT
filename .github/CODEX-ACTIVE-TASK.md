# RVTT Codex Active Task

- status: `AWAITING_CODEX_RESULT_COMMENT`
- commandId: `RVTT-PR2-STUDIO-PREFLIGHT-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- reviewPhase: `STUDIO_PREFLIGHT`
- reviewerRole: `Studio Runtime Preflight Reviewer`
- commandPath: `docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-001-REVIEW-COMMAND.md`
- runtimeCommandId: `RVTT-PR2-STUDIO-SMOKE-001`
- runtimeCommandPath: `implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_REVIEW_RESULT -->`
- resultStatus: `PENDING`
- staticGateState: `UNVERIFIED_GITHUB_HOSTED_RUNNER_INFRA_BLOCKED`
- runtimeExecutionState: `NOT_STARTED`
- mcpConnectionState: `NOT_CONNECTED_IN_CHATGPT_AUTHORING_SESSION`
- previousCommandId: `RVTT-PR2-ADR0092-DELTA-004`
- previousResultComment: `https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5207940603`
- updatedBy: `ChatGPT Lead Reviewer`
- updatedAt: `2026-08-07`

## 이번 활성 작업의 목적

Codex는 Studio MCP Smoke Runtime 계획만 사전 검수한다.

이 작업은 Roblox Studio, MCP, Rojo Build, Play Solo 또는 Human Playtest를 실행하는 명령이 아니다. 현재 GitHub-hosted Runner 장애로 `Validate RVTT implementation`이 실행되지 않았으므로 Static Gate PASS를 주장하지 않는다.

Codex가 `READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE`를 보고하더라도 다음 두 조건이 별도로 충족돼야 Runtime을 시작할 수 있다.

```text
1. 현재 Runtime Target SHA의 Implementation Static Gate 검증
2. 연결된 Studio MCP의 실제 Capability Handshake
```

## Codex 실행 절차

1. 이 파일의 `commandPath`를 연다.
2. PR #2의 정확한 현재 HEAD SHA를 작업 시작 시 조회한다.
3. `runtimeCommandPath`와 지정 Authority를 해당 SHA 기준으로 검수한다.
4. GitHub Actions 상태를 현재 SHA에서 다시 확인한다.
5. Studio, MCP 또는 Human Playtest를 실행하지 않는다.
6. 결과 게시 직전에 PR HEAD를 다시 조회한다.
7. HEAD가 바뀌었으면 `STALE_TARGET` 댓글만 남기고 현재 HEAD를 검수했다고 주장하지 않는다.
8. HEAD가 같으면 PR #2에 지정 Marker를 가진 Top-level Conversation Comment를 게시한다.
9. 파일 수정, PR 승인, Ready 전환과 Merge를 수행하지 않는다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서
ChatGPT가 작성한 활성 명령을 확인해 실행하고,
결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 절차

사용자가 “Codex 피드백을 확인해”라고 지시하면 ChatGPT Lead Reviewer는 PR #2 댓글과 Review Thread를 조회한다.

현재 `commandId`와 Codex가 확정한 `targetSha`가 PR의 현재 HEAD와 일치하는 Result만 현재 Studio Preflight 결과로 분류한다.

Finding을 분류하고 필요한 수정을 완료한 뒤, 현재 SHA Static Gate와 MCP Capability Handshake가 모두 충족돼야 `RVTT-PR2-STUDIO-SMOKE-001` Runtime 실행을 승인한다.
