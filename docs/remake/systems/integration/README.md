# Cross-System Integration 시스템

여러 Domain Runtime이 하나의 결과에 함께 참여할 때의 Transaction, Follow-up, Gate와 Projection 경계를 다룬다.

## 최상위 권위 문서

- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime 계약`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
  - Immediate Closure와 Deferred Consequence 분리
  - Domain Provider Registry와 Cross-Domain Outcome Plan
  - Damage·Healing·Vital·Death·Encounter 통합
  - Runtime Object·Scene·Derived Index 통합
  - Downtime·Build·Inventory·Crafting 통합
  - Follow-up Consequence Ledger, Integration Gate와 Projection Barrier
  - Restart·Rollback·Epoch-safe 멱등성
- [`ADR-0087`](../../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md)
  - 유효성 Closure는 같은 Transaction, 새 Gameplay 판단은 Commit 이후 실행으로 분리
- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - 현재 제품 범위의 Core·Support Engine과 Cross-System Integration 완료 판정

## 공통 실행 흐름

```text
Command·RuleExecution
→ CrossDomainOutcomeCandidate
→ Domain Provider Contribution
→ Immediate Closure Plan
→ Authority Transaction
→ Domain Event Outbox + Follow-up Ledger
→ Deferred Command·RuleExecution
→ Projection Barrier
→ UI·Presentation·Diagnostics
```

## Immediate Closure

Commit 직후 권위 상태가 유효하기 위해 필요한 변화다.

예:

- Damage + Temporary HP + Current HP + VitalState + DeathSave Lifecycle
- Death + 확정적 Effect·Opportunity·Reservation Cleanup
- Encounter End + Encounter-bound Effect + Session Mode Binding
- Character Build Activation + State Migration
- Crafting Input Consumption + Output Item + Ground Presence

Provider 하나라도 실패하면 전체 Transaction을 Abort한다.

## Deferred Consequence

새 굴림, Reaction, 선택, DM 판정, 미래 시간 또는 Commit된 최신 상태가 필요한 후속 실행이다.

예:

- 피해 후 Concentration Check
- 사망 후 Objective·Morale Evaluation
- Scheduler Due 사건
- Runtime Object 변경 후 Derived Index Rebuild
- Journal Anchor Reindex
- Presentation Playback

Subscriber가 Store를 직접 수정하지 않고 새 Command 또는 RuleExecution을 제출한다.

## 고정 경계

- Integration Coordinator는 새 Domain Store를 소유하지 않는다.
- Domain Provider는 자신의 Store에 대한 Mutation Proposal만 만든다.
- Damage Provider가 Encounter Timeline Cursor를 직접 이동하지 않는다.
- Encounter Objective와 End는 Encounter Runtime이 소유한다.
- UI·Presentation·Workspace Instance는 Authority Mutation Provider가 아니다.
- Derived Index 실패가 이미 Commit된 권위 결과를 되돌리지 않는다.
- 오래된 Index로 권위 판정을 할 위험이 있으면 관련 Command Scope만 Gate한다.
- 같은 Transaction의 HP·Vital·Effect·Encounter Projection은 Barrier Batch로 적용한다.
- Root Outcome과 Follow-up Consequence는 각각 멱등성을 가진다.
- 이전 AuthorityEpoch의 Follow-up과 ACK는 새 Branch에 적용하지 않는다.

## 필수 통합 Scenario

- Damage→HP 0→DeathSave Atomic Commit
- Instant Death→Effect·Opportunity Cleanup
- Concentration Follow-up 중복 방지
- Current Turn Actor 사망과 Turn Advance
- Last Hostile Death와 Encounter End Candidate
- Encounter End 후 Actor·Item 상태 보존
- Crafting Input·Output·Ground Presence 원자성
- Runtime Object 파괴와 Index Failure
- Journal Anchor 비자동 Retarget
- Rollback 이전 Follow-up 차단
- Projection Barrier
- Presentation Failure Isolation

## 관련 영역

- Combat: `../combat/`
- Character: `../character/`
- Rules: `../rules/`
- Inventory: `../inventory/`
- Scene: `../scene/`
- Downtime: `../downtime/`
- Events: `../events/`
- Diagnostics: `../diagnostics/`
- Testing: `../testing/`

## Guide 상태

```text
Guide Status: READY_FOR_MAIN_GUIDE_PHASE
```

실제 Module·Type·Command·Persistence Schema는 Main System Guides 이후 Implementation Specs에서 확정한다.
