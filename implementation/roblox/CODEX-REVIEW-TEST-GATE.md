# Codex Stabilization·Review Gate

- 상태: `ACTIVE`
- 최종 갱신일: 2026-08-12
- 상위 정책: [`Codex Studio 구현·검수 정책`](../../docs/remake/product/codex-supervised-review-and-test-policy.md)
- Studio MCP: [`ROBLOX-STUDIO-MCP-TEST-POLICY.md`](ROBLOX-STUDIO-MCP-TEST-POLICY.md)
- 실행 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

이 파일명은 기존 링크 호환을 위해 유지한다. 현재 역할은 **모든 개발 반복을 막는 Gate가 아니라 Stabilization·고위험 변경·Merge·Release용 Review Gate**다.

## 1. Review가 필요하지 않은 기본 Studio 반복

다음 흐름은 별도 Preflight Review 없이 진행할 수 있다.

```text
GitHub 조사
→ Studio MCP 구현
→ Play
→ Focused 수정
→ 다시 Play
```

Accepted Authority 안의 UI 배치, 시각 조정, 기존 기능 버그 수정과 작은 구현 반복이 여기에 해당한다.

## 2. 독립 Review가 필요한 경우

- Accepted ADR·Product Authority 변경
- 서버 Authority·Permission·Security·Disclosure 변경
- Persistence·Migration·Rollback·Lease 변경
- 공개 Schema·Package·Stable ID 계약 변경
- 대규모 Cross-slice 변경
- Merge·Release 후보
- 사용자가 Review를 요청한 경우

## 3. Review 절차

```text
정확한 PR·Target SHA 확인
→ Authority와 변경 범위 검수
→ Finding 게시
→ Finding Triage
→ 필요한 수정
→ Focused Delta Review
```

현재 SHA와 무관한 과거 Review 결과를 현재 Gate PASS로 사용하지 않는다.

## 4. Finding

기본 Marker:

```text
<!-- RVTT_CODEX_REVIEW_RESULT -->
```

필수 필드:

```text
commandId
targetSha
reviewPhase
reviewerRole
resultStatus
```

Finding은 최소 다음을 포함한다.

```text
findingId
severity
claim
evidence
minimalCorrection
requiredTest
```

분류:

```text
CONFIRMED
VALID_RISK
DESIGN_DECISION_REQUIRED
INTENTIONALLY_QUEUED
DUPLICATE
FALSE_POSITIVE
OUT_OF_SCOPE
```

사용자 제품 결정이 필요한 Finding은 자동 수정하지 않는다.

## 5. Active Task

`.github/CODEX-ACTIVE-TASK.md`는 긴 구현이나 Review를 지시하는 단일 포인터다.

- Active Task가 가리키는 Command만 현재 지시다.
- 과거 `.github/CODEX-*` 파일은 자동으로 활성화되지 않는다.
- 작은 Studio 반복에는 Active Task를 만들지 않아도 된다.

## 6. Runtime Review

Runtime Preflight와 Post-runtime Review는 위험이 높거나 Release Evidence가 필요한 경우에만 사용한다. 매 Development Play 전후로 의무화하지 않는다.

Runtime Review를 수행할 때는 다음을 구분한다.

```text
MCP 자동 동작
Human 동작
실제 Log·State
실행하지 않은 범위
```

## 7. Merge Gate

Merge 후보에서는 변경 위험에 맞게 다음을 확인한다.

- 관련 자동 CI
- 필요한 독립 Review
- `CONFIRMED` BLOCKER·HIGH 해결
- Server Authority·Security·Disclosure
- 변경 영역 Runtime
- 필요한 Human UI·UX
- Persistence·Migration·Multi-client 영향이 있으면 해당 Evidence
- 남은 Risk 기록

Codex Review만으로 Runtime 또는 Release PASS를 선언하지 않는다.
