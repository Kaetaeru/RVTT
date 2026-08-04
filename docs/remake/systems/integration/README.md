# Cross-System Integration 시스템

여러 Domain Runtime이 하나의 결과에 함께 참여할 때의 Transaction, Follow-up, Gate와 Projection 경계를 다룬다.

## 관련 Main System Guide

- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - Damage·Temporary HP·Current HP·VitalState·DeathSave Immediate Closure
  - Death 이후 Objective·Turn Advance Follow-up, Encounter End Transaction과 Projection Barrier
- [`Character, Inventory와 Downtime Guide`](../../guides/character/README.md)
  - Character Source·Build Ref·State Migration의 Atomic Activation
  - Crafting Input·Output·Ground Presence, RecoveryPlan과 Downtime Completion 통합
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
  - Roll·PendingEffect·CommitGroup·EffectInstance가 Cross-Domain Outcome으로 진입하는 경계
- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
  - Projection Barrier 이후 Replica·ViewModel·Presentation 적용과 Client Failure Isolation
- [`Journal과 Ping Guide`](../../guides/journal/README.md)
  - Journal Source Commit 이후 Compile·Index·Projection 갱신과 Safe Navigation Follow-up
  - Ping을 Authority Transaction과 분리된 비권위 Presentation Signal로 유지하는 경계
- [`Scene Editor와 Authoring Guide`](../../guides/scene-editor/README.md)
  - Scene Source Authoring Transaction, Candidate Build·Atomic Publish와 Last Known Good 경계
  - Runtime Quick Edit·Source Promotion, Build Migration·Runtime Object Rebind와 Projection Barrier

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
- Rest Recovery + Resource·Effect·Condition Settlement
- Live Scene Build Activation + Runtime Object Rebind + Dynamic State Rebase

Provider 하나라도 실패하면 전체 Transaction을 Abort한다.

## Deferred Consequence

새 굴림, Reaction, 선택, DM 판정, 미래 시간 또는 Commit된 최신 상태가 필요한 후속 실행이다.

예:

- 피해 후 Concentration Check
- 사망 후 Objective·Morale Evaluation
- Scheduler Due 사건
- Runtime Object 변경 후 Derived Index Rebuild
- Journal Anchor Reindex
- Scene Build 활성화 후 선택적 Presentation·Diagnostic 갱신
- Presentation Playback

Subscriber가 Store를 직접 수정하지 않고 새 Command 또는 RuleExecution을 제출한다.

## 고정 경계

- Integration Coordinator는 새 Domain Store를 소유하지 않는다.
- Domain Provider는 자신의 Store에 대한 Mutation Proposal만 만든다.
- Damage Provider가 Encounter Timeline Cursor를 직접 이동하지 않는다.
- Encounter Objective와 End는 Encounter Runtime이 소유한다.
- Downtime Runtime이 Character·Inventory·Rest Store Mutation을 직접 작성하지 않는다.
- Character Compiler가 Item·Actor·Encounter Live State를 직접 수정하지 않는다.
- Scene Compiler가 Authoritative Dynamic State와 활성 Session Build를 직접 교체하지 않는다.
- Scene Authoring Command와 Runtime Quick Edit를 같은 Transaction에 섞지 않는다.
- Journal Index·Anchor Resolver 실패가 이미 Commit된 Journal Source Revision을 되돌리지 않는다.
- Ping Presentation은 Authority Mutation Provider나 Projection Sequence의 일부가 아니다.
- UI·Presentation·Workspace Instance는 Authority Mutation Provider가 아니다.
- Derived Index 실패가 이미 Commit된 권위 결과를 되돌리지 않는다.
- 오래된 Index로 권위 판정을 할 위험이 있으면 관련 Command Scope만 Gate한다.
- 같은 Transaction의 HP·Vital·Effect·Encounter, Build·State·Item 또는 Scene Build·Rebind Projection은 Barrier Batch로 적용한다.
- Root Outcome과 Follow-up Consequence는 각각 멱등성을 가진다.
- 이전 AuthorityEpoch의 Follow-up과 ACK는 새 Branch에 적용하지 않는다.

## 필수 통합 Scenario

- Damage→HP 0→DeathSave Atomic Commit
- Instant Death→Effect·Opportunity Cleanup
- Concentration Follow-up 중복 방지
- Current Turn Actor 사망과 Turn Advance
- Last Hostile Death와 Encounter End Candidate
- Encounter End 후 Actor·Item 상태 보존
- Character Source·Build Ref·State Migration 원자성
- Crafting Input·Output·Ground Presence 원자성
- Rest Recovery와 Resource·Effect Settlement
- Runtime Object 파괴와 Index Failure
- Scene Candidate Build 실패와 Published Build 보존
- Scene Live Patch의 Build·Rebind·Dynamic State Rebase 원자성
- Scene Live Patch 실패와 이전 Build 복구
- Runtime Quick Edit와 Source Promotion 분리
- Journal Anchor 비자동 Retarget
- Journal Permission 축소와 Projection·Index 무효화
- Ping Presentation Failure Isolation
- Rollback 이전 Follow-up 차단
- Projection Barrier
- Presentation Failure Isolation

## 관련 영역

- Combat: `../combat/`
- Character: `../character/`
- Rules: `../rules/`
- Inventory: `../inventory/`
- Scene: `../scene/`
- Navigation: `../navigation/`
- Downtime: `../downtime/`
- Journal: `../journal/`
- Events: `../events/`
- Diagnostics: `../diagnostics/`
- Testing: `../testing/`

## Guide 상태

```text
Guide Status: READY_FOR_MAIN_GUIDE_PHASE
```

Combat·Encounter, Rules, Character·Inventory·Downtime, UI·Presentation, Journal·Ping와 Scene Editor·Authoring 관련 Integration 흐름은 현재 각 Main System Guide에 연결됐다. 나머지 Operations·Extension 영역은 후속 Guide 순서에서 계속 통합한다.
