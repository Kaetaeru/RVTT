# Slice Checkpoint A Audit — Slices 01–04

- 상태: COMPLETE_WITH_SHARED_BLOCKER
- 문서 종류: Cross-Slice Specification Checkpoint Audit
- 즉시 구현 명세 가능성: BLOCKED
- 감사일: 2026-08-05
- 범위:
  - [`Slice 01`](../../specs/slices/01-first-session-walking-skeleton/implementation-contract.md)
  - [`Slice 02`](../../specs/slices/02-core-rules-kernel/implementation-contract.md)
  - [`Slice 03`](../../specs/slices/03-exploration-interaction-perception/implementation-contract.md)
  - [`Slice 04`](../../specs/slices/04-encounter-core-loop/implementation-contract.md)

## 1. 통합 사용자 흐름

```text
Campaign Join·Character Select·Scene Entry
→ Exploration Movement·Reconnect
→ Ability Check·Attack·Save·Damage
→ Door·Container·Search·Fog·WASD
→ Encounter Initiative·Turn·Reaction·End
→ Exploration 복귀
```

## 2. 공통 계약 검사

| 공통 계약 | 결과 |
|---|---|
| Stable ID·AuthorityEpoch·ConnectionEpoch·Revision | 일관됨 |
| Character·Actor·Scene Build·Runtime Presence 분리 | 일관됨 |
| Receipt·Terminal Result·Projection Reconciliation | 일관됨 |
| RuleExecution·RollRecord·PendingEffect | Slice 02–04에서 재사용됨 |
| Selection·Frozen Binding·Server 재검증 | Slice 03–04에서 재사용됨 |
| Click·WASD·Encounter Movement Position Authority | 같은 Navigation·Commit 경로 사용 |
| Transaction·Outbox·Projection Barrier | 모든 Slice에 포함 |
| Snapshot·Journal·Reconnect·Restart·Rollback | 모든 Slice에 포함 |
| Player·DM·Observer Negative Disclosure | 모든 Slice에 포함 |
| Deterministic·Fault·Roblox Integration Test | 모든 Slice에 포함 |

## 3. 중복·충돌 검사

발견되지 않은 문제:

- Slice별 독립 Dice Engine
- Encounter 전용 Position Store
- Client Preview·Physics·UI 기반 Authority
- Fog·Knowledge·Visibility의 단일 Boolean 결합
- Reaction 전용 임의 Stack
- Damage Roll의 직접 HP Mutation
- Rollback 역연산

공통 차단 사항:

- Production Source Tree와 실제 Package 경로 미확인
- 기존 Schema·Legacy Data·Migration 대상 미확인
- Roblox Integration Test Host 미확인
- 측정형 Payload·Timeout·Queue·Snapshot Budget 미확정

## 4. Checkpoint 판정

```text
Checkpoint A — Slices 01–04
→ SPECIFICATION CHECKPOINT COMPLETE

Cross-Slice Contract Consistency
→ PASS

Production Implementation Readiness
→ BLOCKED BY REPOSITORY MAPPING
```

새 Product·Architecture 결정이 필요한 충돌은 발견되지 않았다. 다음 Slice 05–08은 이 기반 위에 Character Source·Inventory·Progression과 공통 Client Surface를 추가한다.

## 5. 복구 기준

이 Audit이 포함된 Commit을 `checkpoint/specs-slices-01-04-2026-08-05` Branch로 고정한다. 이후 문서 변경이 Slices 01–04의 의미를 훼손하면 해당 Branch 또는 Commit SHA로 비교·복구할 수 있다.