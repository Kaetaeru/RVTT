# Shared 구현 명세

- 상태: UPDATE_REQUIRED
- 문서 종류: Implementation Spec Subindex
- 상위 허브: [`../README.md`](../README.md)
- 최신 재검토: [`Shared Spec 001·002 재검토 감사`](../../audits/shared-spec-001-002-revalidation-audit.md)
- 갱신 예정 단계: `Character Action·Rules Slice`

여러 규칙·전투·아이템·장면 시스템이 공통으로 사용하는 구현 계약을 보관한다.

현재 Shared Spec 001·002는 최신 RuleExecution·Transaction·Outbox·Projection·Recovery·Diagnostics·Simulation 계약보다 먼저 작성됐다.

최신 판정:

```text
001 Recipe Step Runtime Foundation
→ UPDATE_REQUIRED

002 Standard Recipe Step Handler Contracts
→ UPDATE_REQUIRED
```

두 문서의 핵심 Recipe·Handler 방향은 유지 가능하므로 `SUPERSEDED`는 아니다. 그러나 현재 파일 상단의 `준비 완료`, `READY` 표시는 최신 재검토 감사에 의해 효력을 잃으며 Production Code의 승인된 근거로 사용할 수 없다.

## 읽기 전 순서

```text
CURRENT-SPEC-WORK-ORDER
→ Shared Spec 재검토 감사
→ Runtime Foundation Guide
→ Rules Guide와 직접 인접 Guide
→ 직접 Authority Documents
→ Shared Spec 001·002
```

- Spec 작업 순서: [`../CURRENT-SPEC-WORK-ORDER.md`](../CURRENT-SPEC-WORK-ORDER.md)
- 현재 상위 작업 순서: [`../../CURRENT-WORK-ORDER.md`](../../CURRENT-WORK-ORDER.md)
- Runtime Foundation Guide: [`../../guides/runtime/README.md`](../../guides/runtime/README.md)
- Rules Guide: [`../../guides/rules/README.md`](../../guides/rules/README.md)
- Implementation Spec Template: [`../../templates/implementation-spec-template.md`](../../templates/implementation-spec-template.md)

## 현재 문서

1. [`001. Recipe Step Runtime Foundation`](001-recipe-step-runtime-foundation.md)
   - 최신 판정: `UPDATE_REQUIRED`
   - 유지: Step Definition·Registry·Compiler, Typed Binding, 직접 Mutation 금지
   - 갱신: RuleExecution Adapter, Frozen Version Set, Transaction Contribution, Outbox·Projection, Epoch Recovery, Diagnostics·Simulation
2. [`002. Standard Recipe Step Handler Contracts`](002-standard-step-handler-contracts.md)
   - 최신 판정: `UPDATE_REQUIRED`
   - 유지: Trusted Handler Registry, 제한 Provider, Input·Output 검증, Fault Isolation
   - 갱신: Capability Manifest, 최소 Provider Set, Version·Migration·Last Known Good, Trace·Health, Transaction·Presentation Adapter

## First Slice와의 관계

```text
First Session Walking Skeleton
→ Shared 001·002에 의존하지 않음
```

현재 첫 Slice는 Session Join, Scene Entry, Click Movement와 Reconnect를 구현 명세화한다. Recipe·Step Runtime은 Character Action·Rules Slice에서 필요해질 때 갱신한다.

## 갱신 Gate

Shared 001·002를 다시 `준비 완료`로 전환하려면 다음을 모두 충족해야 한다.

- RuleExecution Orchestrator와 책임 중복 제거
- Frozen Ruleset·Policy·Recipe·Handler·Build Version Ref
- Snapshot-bound Typed Query와 제한 Provider Set
- Ordering·Resource Reservation·Transaction Contribution
- Domain Event Outbox·Projection Barrier
- Manifest·Chunk·Journal·AuthorityEpoch·Branch Recovery
- Correlated Trace·Stable Error·Support Reference·Health
- Production-parity Deterministic Harness·Fault Injection·Negative Disclosure
- Player·DM Guided·Assisted Prompt Acceptance Flow
- 실제 저장소 Module·Schema·Test 조사
- 측정 근거 없는 성능 수치 제거
- 문서 검증 성공

갱신 순서는 [`CURRENT-SPEC-WORK-ORDER.md`](../CURRENT-SPEC-WORK-ORDER.md)를 따른다.