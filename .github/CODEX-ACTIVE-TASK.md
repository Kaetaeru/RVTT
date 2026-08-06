# RVTT Codex Active Task

- status: `AWAITING_CODEX_RESULT_COMMENT`
- commandId: `RVTT-PR2-STUDIO-PREFLIGHT-DELTA-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- reviewPhase: `STUDIO_PREFLIGHT_DELTA_REVIEW`
- reviewerRole: `Studio Runtime Preflight Delta Reviewer`
- commandPath: `docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-DELTA-001-REVIEW-COMMAND.md`
- runtimeCommandId: `RVTT-PR2-STUDIO-SMOKE-001`
- runtimeCommandPath: `implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md`
- triagePath: `docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-001-TRIAGE.md`
- runtimeFixCommit: `7cdb9e83989666f430447bcebcb61f3049dda962`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_REVIEW_RESULT -->`
- resultStatus: `PENDING`
- staticGateState: `UNVERIFIED_CURRENT_HEAD`
- runtimeExecutionState: `NOT_STARTED`
- mcpConnectionState: `NOT_CONNECTED_IN_CHATGPT_AUTHORING_SESSION`
- previousCommandId: `RVTT-PR2-STUDIO-PREFLIGHT-001`
- previousResultComment: `https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5208363657`
- updatedBy: `ChatGPT Lead Reviewer`
- updatedAt: `2026-08-07`

## 이번 활성 작업의 목적

Codex는 Studio Preflight 001에서 확인된 세 계획 결함의 수정만 Delta 검수한다.

```text
STUDIO-PREFLIGHT-003 — Core MCP Capability와 Human fallback 경계
STUDIO-PREFLIGHT-004 — 저장소 밖 Runtime Evidence와 Source-clean invariant
STUDIO-PREFLIGHT-007 — bounded structured Forbidden Log allowlist
```

이 작업은 Roblox Studio, MCP, Rojo Build, Play Solo 또는 Human Playtest를 실행하는 명령이 아니다.

Codex가 `READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE`를 보고하더라도 다음 조건은 별도로 충족돼야 Runtime을 시작할 수 있다.

```text
1. 현재 Runtime Target SHA의 Implementation Static Gate 검증
2. 연결된 Studio MCP의 실제 Capability Handshake
3. Core Required Capability의 MCP_AUTOMATED 확인
```

## Codex 실행 절차

1. 이 파일의 `commandPath`를 연다.
2. PR #2의 정확한 현재 HEAD SHA를 작업 시작 시 조회한다.
3. `runtimeCommandPath`, `triagePath`와 지정 Authority를 해당 SHA 기준으로 검수한다.
4. 이전 Reviewed SHA와 Runtime Fix Commit의 변경을 분리해 확인한다.
5. GitHub Actions 상태를 현재 SHA에서 다시 확인한다.
6. Studio, MCP, Rojo Build 또는 Human Playtest를 실행하지 않는다.
7. 결과 게시 직전에 PR HEAD를 다시 조회한다.
8. HEAD가 바뀌었으면 `STALE_TARGET` 댓글만 남긴다.
9. HEAD가 같으면 PR #2에 지정 Marker를 가진 Top-level Conversation Comment를 게시한다.
10. 파일 수정, PR 승인, Ready 전환과 Merge를 수행하지 않는다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서
ChatGPT가 작성한 활성 명령을 확인해 실행하고,
결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 절차

사용자가 “Codex 피드백을 확인해”라고 지시하면 ChatGPT Lead Reviewer는 PR #2 댓글과 Review Thread를 조회한다.

현재 `commandId`와 Codex가 확정한 `targetSha`가 PR의 현재 HEAD와 일치하는 Result만 현재 Delta 결과로 분류한다.

세 Finding이 해결돼도 current-SHA Static Gate와 실제 MCP Capability Handshake가 모두 충족되기 전에는 `RVTT-PR2-STUDIO-SMOKE-001` Runtime을 실행하거나 PASS로 기록하지 않는다.
