# RVTT Codex Active Task

- status: `AWAITING_CODEX_RESULT_COMMENT`
- commandId: `RVTT-PR2-STUDIO-PREFLIGHT-DELTA-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- reviewPhase: `STUDIO_PREFLIGHT_DELTA_REVIEW`
- reviewerRole: `Final Studio Runtime Preflight Delta Reviewer`
- commandPath: `docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-DELTA-002-REVIEW-COMMAND.md`
- runtimeCommandId: `RVTT-PR2-STUDIO-SMOKE-001`
- runtimeCommandPath: `implementation/roblox/runtime-commands/PR-0002-STUDIO-SMOKE-001.md`
- triagePath: `docs/remake/audits/codex-reviews/PR-0002-STUDIO-PREFLIGHT-DELTA-001-TRIAGE.md`
- runtimeFixCommit: `23ce78ea7fe6a04242424ce9aa9d16f01d595bfa`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_REVIEW_RESULT -->`
- resultStatus: `PENDING`
- staticGateState: `UNVERIFIED_CURRENT_HEAD`
- runtimeExecutionState: `NOT_STARTED`
- mcpConnectionState: `NOT_CONNECTED_IN_CHATGPT_AUTHORING_SESSION`
- previousCommandId: `RVTT-PR2-STUDIO-PREFLIGHT-DELTA-001`
- previousResultComment: `https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5208437045`
- updatedBy: `ChatGPT Lead Reviewer`
- updatedAt: `2026-08-07`

## 이번 활성 작업의 목적

Codex는 마지막 Studio Preflight 계획 결함 하나만 Delta 검수한다.

```text
STUDIO-PREFLIGHT-008
— MCP_AUTOMATED 선언을 실제 Tool identity와 호출 Evidence에 강제 연결
```

검수 대상 수정은 다음을 요구한다.

```text
non-empty actualToolName
실제 노출 MCP Tool 이름 일치
호출 시작·종료 시각
호출 결과
Evidence 파일 연결
Core Capability별 최소 성공 호출 수
누락 Fixture의 BLOCKED 판정
```

이 작업은 Roblox Studio, MCP, Rojo Build, Play Solo 또는 Human Playtest를 실행하는 명령이 아니다.

Codex가 `READY_AFTER_STATIC_GATE_AND_CAPABILITY_HANDSHAKE`를 보고하더라도 다음 조건은 별도로 충족돼야 Runtime을 시작할 수 있다.

```text
1. 현재 Runtime Target SHA의 Implementation Static Gate 검증
2. 연결된 Studio MCP의 실제 Capability Handshake
3. Core Required Capability의 실제 Tool identity와 성공 Invocation Evidence
```

## Codex 실행 절차

1. 이 파일의 `commandPath`를 연다.
2. PR #2의 정확한 현재 HEAD SHA를 작업 시작 시 조회한다.
3. `runtimeCommandPath`, `triagePath`와 지정 Authority를 해당 SHA 기준으로 검수한다.
4. 이전 Reviewed SHA와 `runtimeFixCommit`의 변경을 분리해 확인한다.
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

`STUDIO-PREFLIGHT-008`이 해결되고 새 중간 이상 계획 결함이 없으면 문서 Preflight 검수 Loop를 종료한다. 그 뒤 current-SHA Static Gate와 실제 MCP Capability Handshake가 충족돼야 `RVTT-PR2-STUDIO-SMOKE-001` Runtime을 시작할 수 있다.
