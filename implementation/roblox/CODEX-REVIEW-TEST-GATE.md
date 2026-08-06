# Codex 검수 포함 테스트 Gate

- 상태: `ACTIVE`
- 최종 갱신일: 2026-08-07
- 상위 정책: [`Codex 감독형 검수·테스트 정책`](../../docs/remake/product/codex-supervised-review-and-test-policy.md)
- 실행 테스트 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 1. 적용 원칙

기능 Batch, Persistence Batch, Grand Acceptance Phase와 Merge 전 검수에는 Codex Review 단계를 포함한다.

Codex는 테스트 실행의 대체물이 아니다. Codex는 테스트 계획, 구현, 로그와 결과 주장 사이의 모순을 독립적으로 찾는다.

```text
Source·Test 변경
→ 자동 Gate
→ Codex Review Command
→ Codex Finding
→ Lead Triage
→ 수정·Delta Review
→ Studio·Human Acceptance
```

## 2. Batch 준비 필수 산출물

Batch Acceptance를 요청하기 전에 다음을 준비한다.

```text
1. Exact Target SHA
2. Batch Scope
3. Authority References
4. Automated Test List
5. Codex Review Command
6. Codex Finding Triage
7. Open Risk·Deferred List
8. Studio Acceptance Script
9. Expected Logs·Summary
```

Codex Review Command가 없거나 결과가 분류되지 않았으면 Batch 상태는 `REVIEW_INCOMPLETE`다.

## 3. 기본 Reviewer 역할

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

## 4. Codex 명령문 위치

기본 명령문 템플릿:

```text
.github/CODEX-REVIEW-COMMAND-TEMPLATE.md
```

각 PR의 실제 명령문은 Target SHA와 변경 범위에 맞게 채워 PR 댓글 또는 Review Artifact로 남긴다.

## 5. 결과 상태

```text
CODEX_REVIEW_PENDING
CODEX_FINDINGS_RECEIVED
CODEX_TRIAGE_COMPLETE
CODEX_FIX_IN_PROGRESS
CODEX_DELTA_REVIEW_PENDING
CODEX_REVIEW_COMPLETE
BLOCKED_CODEX_REVIEW_UNAVAILABLE
```

`CODEX_REVIEW_COMPLETE`는 CI·Studio·Human Acceptance 성공을 의미하지 않는다.

## 6. Batch Summary 추가 필드

새 Acceptance Batch Summary에는 가능한 범위에서 다음을 포함한다.

```text
codexReviewTargetSha
codexReviewRoles
codexFindingCount
codexConfirmedCount
codexOpenRiskCount
codexDeltaReviewStatus
```

Runtime Harness가 GitHub Codex 결과를 직접 조회할 필요는 없다. 이 필드는 Build 준비 Artifact 또는 Manual Acceptance Record에서 관리할 수 있다.

## 7. Finding 처리

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

`CONFIRMED` BLOCKER·HIGH Finding이 남아 있으면 Studio 검사를 요청하지 않는다.

## 8. Runtime Evidence 보호

Codex는 다음을 대신할 수 없다.

- Roblox Studio 실제 실행
- 사용자 Mouse·Keyboard 입력
- DM·Player·Observer 실제 Client 분리
- DataStore Load·Save·Restore
- 장시간 Memory·Performance 측정
- Screenshot·시각 품질 검수

Codex가 코드상 정상으로 판단해도 해당 Runtime Gate는 별도로 실행한다.

## 9. Merge 전 Gate

```text
Automated CI PASS
+ Codex Triage Complete
+ Confirmed High/Blocker Zero
+ Delta Review Complete
+ Required Runtime Evidence
+ Deferred Risk Recorded
→ Merge Candidate
```

Codex 접근 실패는 자동 면제가 아니다. 사용자의 명시적 면제 또는 Review 복구 전까지 `BLOCKED_CODEX_REVIEW_UNAVAILABLE`로 유지한다.
