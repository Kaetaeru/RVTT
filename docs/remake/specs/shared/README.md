# Shared 구현 명세

- 상태: REVIEW_REQUIRED
- 문서 종류: Implementation Spec Subindex
- 상위 허브: [`../README.md`](../README.md)

여러 규칙·전투·아이템·장면 시스템이 공통으로 사용하는 구현 계약을 보관한다.

현재 Shared Spec 001·002는 Main System Guide와 Player·DM User Guide 완료 전에 작성됐다. 구현 가능 상태로 간주하지 않고, 다음 Spec Work Order에서 최신 Runtime 계약과 다시 대조한다.

## 읽기 전 순서

```text
CURRENT-WORK-ORDER
→ Quick Flow와 관련 User Guide
→ Runtime Foundation Guide
→ Rules Guide와 직접 인접 Guide
→ 직접 Authority Documents
→ Shared Spec 001·002
```

- 현재 작업 순서: [`../../CURRENT-WORK-ORDER.md`](../../CURRENT-WORK-ORDER.md)
- 한눈에 보는 세션 흐름: [`../../user-guides/QUICK-FLOW.md`](../../user-guides/QUICK-FLOW.md)
- Runtime Foundation Guide: [`../../guides/runtime/README.md`](../../guides/runtime/README.md)
- Rules Guide: [`../../guides/rules/README.md`](../../guides/rules/README.md)
- Implementation Spec Template: [`../../templates/implementation-spec-template.md`](../../templates/implementation-spec-template.md)

## 현재 문서

1. [`001. Recipe Step Runtime Foundation`](001-recipe-step-runtime-foundation.md)
   - StepDefinition·Registry·Compiler
   - BindingStore와 StepExecutor
   - Guided·Assisted 대기·재개·복구
2. [`002. Standard Recipe Step Handler Contracts`](002-standard-step-handler-contracts.md)
   - StepHandler·Registry·제한 Service
   - Config·입력·출력 검증
   - PendingEffect·Branch·Presentation 반환 경계
   - 오류 격리·멱등성·진단·테스트

## 재검토 Gate

다음을 확인한 뒤 각 Spec 상태를 결정한다.

- RuleExecution Orchestrator와 책임 중복 여부
- Frozen Ruleset·Policy·Build Version 고정
- Transaction Coordinator·Reservation·Outbox·Projection Barrier
- Session Recovery·AuthorityEpoch·Pending Input 재개
- Correlated Trace·Stable Error·Budget·Health
- Deterministic Scheduler·RNG·Fault Injection
- Quick Flow와 Player·DM Prompt·Recovery Acceptance Flow
- Extension Registry·Version·Migration·Safe Activation

판정 값:

```text
CURRENT
UPDATE_REQUIRED
SUPERSEDED
```

재검토 완료 전에는 이 두 문서를 근거로 Production Code를 시작하지 않는다.