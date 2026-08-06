# Slice 02 Spec Checkpoint Audit — Core Rules Kernel

- 상태: COMPLETE_WITH_BLOCKER
- 문서 종류: Slice Specification Checkpoint Audit
- 즉시 구현 명세 가능성: BLOCKED
- 감사일: 2026-08-05
- Work Order: [`CURRENT-WORK-ORDER.md`](../../specs/slices/02-core-rules-kernel/CURRENT-WORK-ORDER.md)
- 통합 계약: [`implementation-contract.md`](../../specs/slices/02-core-rules-kernel/implementation-contract.md)

## 1. 감사 범위

- Core Policy와 Character Derived Stat
- RuleExecution·Recipe·Step Handler 책임
- D20 Test·Attack·Save·Damage·Healing
- Resource·Effect 최소 기반
- Persistence·Recovery·Disclosure·Deterministic Test

## 2. 검사 결과

| 항목 | 결과 |
|---|---|
| Core Rules가 Interaction·Encounter보다 선행 | 충족 |
| `dnd5e-2024` Policy Version 고정 | 충족 |
| Character Build·State·Derived View 분리 | 충족 |
| RuleExecution과 Recipe Step 책임 분리 | 충족 |
| RollRecord와 HP·Effect Mutation 분리 | 충족 |
| Transaction·Reservation·Outbox·Projection 경계 | 충족 |
| Pending Execution 저장·Reconnect·Rollback | 충족 |
| Player·DM·Observer 공개 차이 | 충족 |
| 결정적 RNG·Fault·Restart Scenario | 충족 |
| 실제 Package·Schema Mapping | 미충족 |
| 공식 Core Profile 데이터 권리·출처 확인 | 미충족 |

## 3. Shared Spec 판정

기존 Shared Spec 001·002의 핵심 방향은 유지한다. 다만 다음 변경 없이는 Production 구현 근거로 사용할 수 없다.

```text
자체 실행 수명주기
→ RuleExecution Orchestrator 하위 Cursor·Frame

광범위 World View
→ Frozen Context와 제한된 Typed Query Provider

CommitGroup 단독 Commit
→ Ordering·Reservation·Transaction·Outbox·Projection Barrier

최신 Handler 자동 사용
→ Version 고정·Migration·Recovery Review
```

따라서 두 문서는 계속 `UPDATE_REQUIRED`이며 Slice 02 구현 착수 전에 통합 계약에 맞춰 갱신한다.

## 4. 체크포인트 판정

```text
Slice 02 Specification Package
→ CHECKPOINT_COMPLETE

Core Rules 의미·실행 경계
→ COMPLETE

Production Implementation Readiness
→ BLOCKED
```

Blocker는 실제 Source Tree, Legacy Schema와 공식 데이터 Packaging 확인이다. 새로운 제품 결정을 요구하는 미정 규칙은 발견되지 않았다.

## 5. 후속 Slice 영향

Slice 03·04는 다음을 재사용한다.

- Capability Query와 Eligibility
- RuleExecution·Prompt·RollRecord
- D20 Test·Save·Attack·Damage·Healing
- PendingEffect·Resource Reservation
- Frozen Ruleset·Policy·Recipe Version
- Roll·Outcome·Projection·Recovery Test Harness

후속 Slice가 독자 Dice Engine, 임의 Handler Mutation 또는 Client Roll Authority를 만들면 이 Audit을 실패로 되돌린다.