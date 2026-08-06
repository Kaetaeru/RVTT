# Codex 검수 포함 테스트 Gate

- 상태: `ACTIVE`
- 최종 갱신일: 2026-08-07
- 상위 정책: [`Codex 감독형 검수·테스트 정책`](../../docs/remake/product/codex-supervised-review-and-test-policy.md)
- Studio MCP 정책: [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 1. 적용 원칙

기능 Batch, Persistence Batch, Grand Acceptance Phase, Human Playtest와 Merge 전 검수에는 Codex Review 단계를 포함한다.

Codex는 테스트 실행의 대체물이 아니다. Codex는 테스트 계획, 구현, 로그와 결과 주장 사이의 모순을 독립적으로 찾는다.

사용자는 상세 Prompt를 복사하지 않는다. ChatGPT가 저장소에 활성 명령을 작성하고, 사용자는 Codex에 해당 명령을 찾아 실행하라고 지시한다.

```text
Source·Test 변경
→ 자동 Gate
→ ChatGPT가 Review Command·Active Task 작성
→ 사용자가 Codex 실행 지시
→ Codex가 PR 댓글로 Finding 게시
→ 사용자가 ChatGPT에 피드백 확인 지시
→ Lead Triage
→ 수정·Delta Review
→ Studio MCP·Human Acceptance
```

## 2. 활성 작업 Discovery

Codex의 단일 진입점:

```text
.github/CODEX-ACTIVE-TASK.md
```

이 파일은 실제 상세 명령문 경로, PR 번호, Review Phase, 결과 댓글 Marker를 가리킨다.

기본 Target Mode:

```text
CURRENT_PR_HEAD_AT_START
```

Codex는 작업 시작 시 정확한 PR HEAD SHA를 확정하고 종료 시 다시 확인한다. HEAD가 바뀌면 결과를 `STALE_TARGET`으로 남기며 Merge Gate Evidence로 사용하지 않는다.

기본 Result Marker:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
```

기본 결과 위치는 해당 PR의 Top-level Conversation Comment다. Finding의 파일 위치를 표시하기 위해 Inline Review Comment를 추가할 수 있지만 전체 Summary 댓글은 생략하지 않는다.

## 3. Batch 준비 필수 산출물

Batch Acceptance를 요청하기 전에 다음을 준비한다.

```text
1. Exact Target SHA 또는 CURRENT_PR_HEAD_AT_START Resolution
2. Batch Scope
3. Authority References
4. Automated Test List
5. Active Command ID·Path
6. Codex Result Comment ID·Target SHA
7. Codex Finding Triage
8. Open Risk·Deferred List
9. Studio MCP Runtime Command
10. Studio Acceptance Script
11. Expected Logs·Summary
12. Evidence Output Path
```

활성 Command가 없거나 Codex 결과가 현재 HEAD와 일치하지 않거나 Finding이 분류되지 않았으면 Batch 상태는 `REVIEW_INCOMPLETE`다.

## 4. 기본 Reviewer 역할

일반 기능 Batch:

```text
Reviewer A — Source·Security·Authority
Reviewer B — Test·Failure·Evidence
Delta Reviewer — 수정된 파일과 Finding 재검증
```

Persistence·Migration Batch:

```text
Reviewer A — Authority·Transaction·Idempotency
Reviewer B — Migration·Restart·Rollback
Reviewer C — Disclosure·Evidence Claims
Delta Reviewer
```

UI·Input Batch:

```text
Reviewer A — Input Context·Q/E/ESC·Selection Continuity
Reviewer B — Projection·Disabled Reason·Recovery·Accessibility
Delta Reviewer
```

Studio Runtime Batch:

```text
Reviewer A — Studio Runtime Preflight
Studio MCP·Human Execution
Reviewer B — Post-runtime Evidence
```

Playtest Batch:

```text
Reviewer A — Playtest Scenario·Instrumentation
Studio MCP Setup·Evidence Capture
Human Playtester
Reviewer B — Post-playtest Evidence·Claim Review
```

## 5. Codex 명령문 위치

기본 명령문 템플릿:

```text
.github/CODEX-REVIEW-COMMAND-TEMPLATE.md
```

각 PR의 실제 명령문은 Target 범위에 맞게 Review Artifact로 저장한다. `.github/CODEX-ACTIVE-TASK.md`가 현재 실행할 문서를 가리킨다.

사용자가 Codex에 전달하는 기본 지시는 다음 의미면 충분하다.

```text
RVTT의 활성 ChatGPT 명령을 확인해 실행하고,
결과를 지정된 PR 댓글로 남겨.
```

## 6. 결과 상태

```text
CODEX_REVIEW_COMMAND_READY
CODEX_REVIEW_PENDING
CODEX_FINDINGS_RECEIVED
CODEX_TRIAGE_COMPLETE
CODEX_FIX_IN_PROGRESS
CODEX_DELTA_REVIEW_PENDING
CODEX_REVIEW_COMPLETE
CODEX_RESULT_STALE
BLOCKED_CODEX_REVIEW_UNAVAILABLE
BLOCKED_CODEX_COMMENT_UNAVAILABLE
BLOCKED_MCP_RUNTIME_UNAVAILABLE
BLOCKED_MCP_CAPABILITY_UNAVAILABLE
```

`CODEX_REVIEW_COMPLETE`는 CI·Studio·Human Acceptance 성공을 의미하지 않는다.

## 7. Batch Summary 추가 필드

새 Acceptance Batch Summary에는 가능한 범위에서 다음을 포함한다.

```text
activeCommandId
activeCommandPath
codexReviewTargetSha
codexResultCommentId
codexReviewRoles
codexFindingCount
codexConfirmedCount
codexOpenRiskCount
codexDeltaReviewStatus
studioMcpSessionId
studioMcpCapabilities
studioRuntimeTargetSha
studioEvidencePath
humanInputStatus
playtestReportPath
```

Runtime Harness가 GitHub Codex 결과를 직접 조회할 필요는 없다. 이 필드는 Build 준비 Artifact 또는 Manual Acceptance Record에서 관리할 수 있다.

## 8. Finding 처리

Codex Finding은 다음 분류 중 하나를 가져야 한다.

```text
CONFIRMED
VALID_RISK
DESIGN_DECISION_REQUIRED
INTENTIONALLY_QUEUED
DUPLICATE
FALSE_POSITIVE
OUT_OF_SCOPE
```

`CONFIRMED` BLOCKER·HIGH Finding이 남아 있으면 Studio 검사나 Playtest를 요청하지 않는다.

Codex 결과 댓글이 과거 SHA를 가리키면 Finding 내용은 참고할 수 있지만 상태는 `CODEX_RESULT_STALE`이며 현재 Gate를 완료하지 않는다.

## 9. Roblox Studio MCP Gate

Studio MCP를 사용하기 전에 Capability Handshake를 기록한다.

필수 확인:

```text
MCP 연결 상태
사용 가능한 Studio Tool 목록
Place Open·Play·Stop 가능 여부
Server·Client Log 수집 가능 여부
Multi-client 가능 여부
Screenshot·State Snapshot 가능 여부
File·Evidence Export 가능 여부
```

요구 Capability가 없으면 가능한 척 우회하지 않는다. 자동화 가능한 단계와 사용자 수동 단계로 분리한다.

기본 Runtime 흐름:

```text
ChatGPT Runtime Command
→ Codex Preflight Result Comment
→ Lead Triage
→ MCP Capability Handshake
→ Target SHA·Rojo Project·Place 확인
→ MCP Automated Setup
→ MCP Automated Runtime Actions
→ Human Input Actions
→ Log·Screenshot·State Evidence Bundle
→ Codex Post-runtime Result Comment
→ Lead Final Triage
```

Runtime Command와 Evidence 세부 계약은 `ROBLOX-STUDIO-MCP-TEST-POLICY.md`가 소유한다.

## 10. Playtest Gate

Playtest도 동일한 Command·Comment·Triage 구조를 사용한다.

```text
ChatGPT Playtest Command
→ Codex Scenario Review 댓글
→ Lead Triage
→ Studio MCP가 Campaign·Save·Role·Scene 준비
→ Human Playtest
→ MCP Log·Screenshot·State Capture
→ Codex Post-playtest Review 댓글
→ Lead Bug·UX Risk·Decision Triage
```

Codex와 MCP는 실제 조작 감각, DM 부담, 가독성, 재미와 같은 Human Judgment를 대체하지 않는다.

Playtest Finding은 최소 다음으로 분류한다.

```text
RUNTIME_BUG
UX_FRICTION
CONTENT_GAP
PERFORMANCE_RISK
DISCLOSURE_RISK
TEST_HARNESS_DEFECT
PRODUCT_DECISION_REQUIRED
NON_REPRODUCIBLE
```

## 11. Runtime Evidence 보호

Codex는 다음을 대신할 수 없다.

- Roblox Studio 실제 실행
- 사용자 Mouse·Keyboard 입력
- DM·Player·Observer 실제 Client 분리
- DataStore Load·Save·Restore
- 장시간 Memory·Performance 측정
- Screenshot·시각 품질 검수
- Human Playtest의 주관적 판단

Codex가 코드상 정상으로 판단해도 해당 Runtime Gate는 별도로 실행한다.

MCP가 연결되지 않았거나 필요한 Capability가 없으면 Studio PASS를 주장하지 않는다.

## 12. Merge 전 Gate

```text
Automated CI PASS
+ Current Active Command Resolved
+ Current-SHA Codex Result Comment
+ Codex Triage Complete
+ Confirmed High/Blocker Zero
+ Delta Review Complete
+ Required Studio MCP Runtime Evidence
+ Required Human Input·Playtest Evidence
+ Deferred Risk Recorded
→ Merge Candidate
```

Codex 접근 또는 댓글 게시 실패는 자동 면제가 아니다. 사용자의 명시적 면제 또는 Review 복구 전까지 Blocked 상태를 유지한다.

Studio MCP가 필요한데 연결되지 않은 경우 정적 검증으로 대체하지 않고 Runtime Gate를 Blocked로 유지한다.
