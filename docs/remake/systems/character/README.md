# Character 시스템

캐릭터 성장 원본, Compiled Character Build, 캠페인 영구 현재 상태, 주문 획득과 주문책, HP 0·죽음·휴식·회복, NPC 스탯블록과 Scene Actor Binding을 다룬다.

## 관련 Main System Guide

- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
  - Damage·Healing·Temporary HP·VitalState·DeathSave·Death가 Encounter Turn과 Objective에 연결되는 경계
  - 사망 후 Opportunity·Concentration·Participant Eligibility 정리와 Deferred Turn Advance
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../../guides/rules/README.md)
  - Character Build가 제공하는 Capability·Spell Route가 Action·Roll·Effect 실행으로 이어지는 경계
  - Character 성장·Inventory·Downtime 전체 Guide는 별도 작업 순서를 따른다.

## 최상위 권위 계약

- [`../../architecture/compiled-build-and-authoritative-state-pattern.md`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
  - Source, 불변 Compiled Build, 버전된 Authoritative State와 Projection을 분리한다.
- [`../../architecture/character-runtime-and-compiled-character-build-contract.md`](../../architecture/character-runtime-and-compiled-character-build-contract.md)
  - Character Progression Source와 Compiled Character Build
  - Persistent Character State, Scene Actor State와 Encounter State의 수명주기 분리
  - Derived Statistics, Modifier, Resource와 Capability Binding
  - 레벨업·재구성 시 Build 교체와 State Migration
  - Persistence, Rollback과 Character Projection
- [`../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md`](../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
  - 휴식·레벨업·주문 준비·주문책 작업의 Activity 조정
  - Candidate Build·Migration과 RecoveryPlan의 Atomic Completion
  - 여러 참가자의 Activity와 Campaign Time 병렬 진행
- [`../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
  - Damage·Healing·HP·VitalState·DeathSave의 Atomic Closure
  - Death·Revival·Effect·Encounter Eligibility 통합
  - Build Activation·State Migration과 Crafting·Inventory 통합
  - Follow-up Consequence, Integration Gate와 Projection Barrier
- [`../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
  - Character·Downtime·Effect·Inventory Integration 완료와 Main Guide 단계 준비 판정

## 세부 권위 문서

- [`spell-acquisition-preparation-and-cast-access-model.md`](spell-acquisition-preparation-and-cast-access-model.md)
- [`spellbook-repository-and-copying-model.md`](spellbook-repository-and-copying-model.md)
- [`zero-hit-points-death-saves-rest-and-resource-recovery-model.md`](zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
- [`monster-npc-statblock-and-ingame-json-import-model.md`](monster-npc-statblock-and-ingame-json-import-model.md)

## Character와 Scene Actor 경계

- [`../../decisions/ADR-0014-character-data-and-scene-actor-separation.md`](../../decisions/ADR-0014-character-data-and-scene-actor-separation.md)
  - Character 영구 원본과 Scene CharacterActor를 분리한다.
- [`../../architecture/runtime-object-system-and-entity-lifecycle-contract.md`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - ActorId는 Actor Component가 있는 RuntimeObjectId의 타입 있는 Scene Presence 참조다.
  - CharacterId와 NPC 영구 원본 ID는 Scene Runtime Object와 별도로 유지한다.
  - Scene Transfer는 같은 CharacterId를 새 Actor Runtime Object에 연결한다.
  - Actor Spawn·Suspend·Archive·Destroy와 Presentation Materialization은 공통 Lifecycle을 사용한다.

## 고정 권위 경계

```text
Character Progression Source
→ 성장 출처, 선택과 예외 획득

Compiled Character Build
→ Grant, Capability, Modifier, Resource Definition과 Derived Plan

Persistent Character State
→ 현재 HP, 장기 자원, 장비·조율과 지속 상태

Scene Actor State
→ 위치, 회전, Scene Presence와 공개 상태

Encounter State
→ Initiative, 행동 경제와 이번 턴 이동력
```

한 계층의 값을 다른 계층에 복사해 독립 원본으로 만들지 않는다.

- 레벨업은 Progression Source Proposal, Candidate Build와 State Migration을 거쳐 원자적으로 적용한다.
- 주문 준비 변경은 Persistent spellPreparationState를 수정하며 Progression Source를 직접 바꾸지 않는다.
- 휴식 완료는 Downtime Runtime이 아니라 Rest Domain의 RecoveryPlan이 결과를 제공한다.
- Character 관련 Downtime Activity가 완료되어도 Character Store를 직접 수정하지 않고 Domain Completion Plan을 사용한다.
- Damage Resolution은 HP Store를 직접 수정하지 않고 Cross-Domain Outcome Plan을 사용한다.
- HP 0·VitalState·DeathSave Lifecycle과 즉시 필요한 Capability Closure는 같은 Transaction에 포함한다.
- 집중 내성, Objective 평가와 기타 새 굴림은 Commit 이후 별도 RuleExecution으로 처리한다.
- 사망은 Character, Inventory와 Actor Runtime Object의 삭제를 의미하지 않는다.
- 부활은 DeathRecord와 현재 상태를 검증하는 별도 RuleExecution·Atomic Commit이다.
- Build Activation은 Source Revision, Build Ref와 Persistent State Migration을 함께 Commit한다.
- 같은 Transaction의 HP·Vital·Resource·Capability Projection은 Barrier Batch로 적용한다.

아이템은 [`../inventory/`](../inventory/), 실행 규칙은 [`../rules/`](../rules/), 장기 활동 조정은 [`../downtime/`](../downtime/), Cross-Domain 결과는 [`../integration/`](../integration/)을 참고한다.

## Guide 상태

```text
Guide Status: READY_FOR_MAIN_GUIDE_PHASE
```

HP 0·Death·Encounter 연결은 현재 Combat Guide에 통합됐다. Character 성장·Inventory·Downtime 전체 흐름은 후속 Main System Guide에서 완료한다.
