# RVTT Codex Active Task

- status: `AWAITING_CODEX_RESULT_COMMENT`
- commandId: `RVTT-PR2-ADR0092-DELTA-004`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- reviewPhase: `DELTA_REVIEW`
- reviewerRole: `Schema·Full-Gate Delta Reviewer`
- commandPath: `docs/remake/audits/codex-reviews/PR-0002-DELTA-004-REVIEW-COMMAND.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- expectedOutputChannel: `PR #2 Top-level Conversation Comment`
- resultMarker: `<!-- RVTT_CODEX_REVIEW_RESULT -->`
- resultStatus: `PENDING`
- previousCommandId: `RVTT-PR2-ADR0092-DELTA-003`
- previousResultComment: `https://github.com/Kaetaeru/RVTT/pull/2#issuecomment-5207697398`
- updatedBy: `ChatGPT Lead Reviewer`
- updatedAt: `2026-08-07`

## Codex 실행 절차

1. 이 파일의 `commandPath`를 연다.
2. PR #2의 정확한 현재 HEAD SHA를 작업 시작 시 조회한다.
3. 상세 명령문을 해당 SHA 기준으로 수행한다.
4. 결과 게시 직전에 PR HEAD를 다시 조회한다.
5. HEAD가 바뀌었으면 `STALE_TARGET` 댓글만 남기고 현재 HEAD를 검수했다고 주장하지 않는다.
6. HEAD가 같으면 PR #2에 지정 Marker를 가진 Top-level Conversation Comment를 게시한다.
7. 파일 수정, PR 승인, Ready 전환과 Merge를 수행하지 않는다.

## 사용자가 Codex에 보낼 최소 지시

```text
RVTT 저장소의 .github/CODEX-ACTIVE-TASK.md에서
ChatGPT가 작성한 활성 명령을 확인해 실행하고,
결과를 지정된 Pull Request 댓글로 남겨.
```

## ChatGPT 후속 절차

사용자가 “Codex 피드백을 확인해”라고 지시하면 ChatGPT Lead Reviewer는 PR #2 댓글과 Review Thread를 조회한다.

현재 `commandId`와 Codex가 확정한 `targetSha`가 PR의 현재 HEAD와 일치하는 Result만 현재 검수 결과로 분류한다.
