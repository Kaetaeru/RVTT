# Implementation Spec — Slice 02 Core Rules Kernel

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Rules·Character·Dice·Effect Source Tree와 기존 저장 Schema가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`First Session Walking Skeleton`](../01-first-session-walking-skeleton/implementation-contract.md)
- 관련 Guide: [`Runtime`](../../../guides/runtime/README.md), [`Rules`](../../../guides/rules/README.md), [`Character`](../../../guides/character/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md), [`Extension`](../../../guides/extension/README.md)

> 이 Spec은 대표적인 Ability Check, Basic Attack, Saving Throw, Damage와 Healing을 같은 RuleExecution·Roll·Transaction 경로로 실행하기 위한 최소 Core Rules Kernel을 정의한다. 전체 공식 콘텐츠 Coverage는 Slice 13·14가 소유한다.

## 1. 목표와 Acceptance Flow

### Player

```text
공개된 Capability 선택
→ 필요한 대상·DC·AC·Option 확인
→ RuleExecution 시작
→ Roll 공개 또는 자동 결과
→ Damage·Healing·Resource 결과 확인
→ Character Projection 갱신
→ 재접속 후 같은 결과 유지
```

### DM

```text
Campaign Ruleset·Policy Version 확인
→ Check·Save·Attack Context 또는 DC 제공
→ 실행 진행·필요 시 Adjudication
→ RollRecord·Modifier Source·Outcome 확인
→ Commit된 HP·Effect·Resource 결과 확인
```

사용자가 보는 주사위 연출은 결과를 표현한다. 실제 난수, Modifier, 성공 여부와 피해 Commit은 Server Authority가 소유한다.

## 2. 직접 권위 문서

- [`Ruleset Policy Registry와 Frozen Snapshot`](../../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Rule Runtime Orchestrator와 Pending Execution`](../../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution`](../../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Character Action·2024 Core Action Runtime`](../../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Effect, Condition과 Ongoing Runtime`](../../../architecture/effect-condition-and-ongoing-runtime-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Cross-Domain Outcome Cascade`](../../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Domain Event와 Projection Runtime`](../../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`Diagnostics와 Observability`](../../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation과 Test Harness`](../../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`Standard Recipe Step Library`](../../../systems/rules/standard-recipe-step-library.md)
- [`Shared Recipe Runtime 001`](../../shared/001-recipe-step-runtime-foundation.md)
- [`Shared Step Handler 002`](../../shared/002-standard-step-handler-contracts.md)

## 3. 범위와 종료 경계

포함:

- `dnd5e-2024` Core Policy Profile과 Frozen Snapshot
- Ability Score·Modifier, Proficiency Bonus, Skill·Save Proficiency
- AC, Current·Maximum HP와 최소 Resource Pool
- Capability Query와 Eligibility
- RuleExecution Identity·Lifecycle·Parent·Child·Pending Input
- D20 Roll Plan, Advantage·Disadvantage, Modifier Contribution, RollRecord
- Ability Check, Saving Throw, Attack Roll
- Damage Component, Temporary HP, Current HP와 Healing
- 최소 Condition·Duration·Contribution·Concentration 확장점
- Resource Reservation·Cost Commit·Cancel
- Restart·Reconnect·Rollback·Version Migration과 결정적 Test

제외:

- Encounter Initiative·Turn·Reaction Opportunity 전체
- 모든 Class·Feat·Spell·Item Definition
- 복잡한 Area, Summon, Shapechange와 장기 Script 예외
- 공식 설명문·Asset·전체 Localization 작성

종료 상태는 대표 Character가 Encounter 밖에서 Check·Attack·Save를 같은 Kernel로 실행하고, 결과가 Character State와 Projection에 Commit되며 Restart 뒤 복원되는 시점이다.

## 4. 데이터와 Type 계약

```lua
export type RulesetSnapshotRef = {
    rulesetId: string,
    rulesetVersion: string,
    policySnapshotId: string,
    policyDigest: string,
}

export type DerivedStatSnapshot = {
    characterId: string,
    characterBuildId: string,
    characterStateRevision: number,
    abilityModifiers: {[string]: number},
    proficiencyBonus: number,
    armorClass: number,
    maximumHitPoints: number,
}

export type CapabilityRef = {
    capabilityId: string,
    sourceRef: string,
    capabilityVersion: number,
    ownerRef: string,
}

export type RuleExecutionRecord = {
    executionId: string,
    executionIncarnation: string,
    parentExecutionId: string?,
    authorityEpoch: string,
    rulesetSnapshotRef: RulesetSnapshotRef,
    recipeVersionRef: string,
    state: "created" | "validating" | "awaiting_input" | "awaiting_roll" | "planning_commit" | "committed" | "cancelled" | "failed",
    cursor: number,
    revision: number,
}

export type RollPlan = {
    rollPlanId: string,
    rollKind: "ability_check" | "saving_throw" | "attack" | "damage" | "healing",
    dice: {count: number, sides: number, modifier: number},
    advantageState: "normal" | "advantage" | "disadvantage",
    dcOrArmorClass: number?,
    disclosurePolicyId: string,
}

export type RollRecord = {
    rollRecordId: string,
    rollPlanRef: string,
    randomStreamRef: string,
    rawResults: {number},
    selectedResult: number,
    total: number,
    outcome: "success" | "failure" | "critical_success" | "critical_failure" | "not_applicable",
    authorityRevision: number,
}

export type PendingEffect = {
    pendingEffectId: string,
    effectKind: "damage" | "healing" | "resource_cost" | "condition_apply" | "condition_remove",
    targetRef: string,
    sourceExecutionRef: string,
    payload: unknown,
    expectedTargetRevision: number,
}
```

Rules Content Definition은 표시 이름이 아니라 Stable Content ID와 Version으로 참조한다. 진행 중 Execution은 시작 당시 Ruleset·Policy·Recipe·Handler Version을 유지한다.

## 5. Policy와 Derived Stat

`dnd5e-2024` Core Profile은 다음 의미를 제공한다.

- Ability Modifier 계산 Policy
- Proficiency Bonus 조회와 적용 가능 출처
- Skill·Save Ability 연결과 Proficiency 단계
- D20 Test의 Advantage·Disadvantage 합성
- Check·Save의 DC 비교
- Attack의 AC 비교와 Critical 기본 의미
- Damage·Healing·Temporary HP 적용 순서
- HP 하한·상한과 Vital 후속 처리 진입점

Policy는 Character State를 직접 수정하지 않는다. Derived Stat Compiler는 Character Build, Item·Effect Contribution과 Frozen Policy를 읽어 불변 Derived View를 만든다. Current HP와 Resource 잔량은 Compiled Build가 아니라 Authoritative State다.

## 6. RuleExecution과 Recipe Adapter

```text
Capability Intent
→ Eligibility·Control·Policy Snapshot 검증
→ RuleExecution 생성
→ Compiled Recipe Cursor 실행
→ Selection·Roll·DM Adjudication·Timing Window
→ PendingEffect Set
→ Ordering·Resource Reservation 재검증
→ Authority Transaction
→ Event·Projection Barrier
→ Terminal Execution Record
```

Shared Spec 001·002의 책임을 다음처럼 제한한다.

```text
Recipe Definition·Compiler
→ RuleExecution이 실행할 결정적 Step Graph 제공

Step Handler
→ 제한된 Query와 Frozen Binding을 읽고
→ Pending Input·Roll Plan·Pending Effect·Presentation Intent 반환

RuleExecution Orchestrator
→ 실행 Identity·Lifecycle·Persistence·Parent/Child·Timing Window 소유

Transaction Coordinator
→ 실제 State Mutation과 Commit 소유
```

Handler가 Character·HP·Effect·Inventory Store를 직접 변경하거나 임의 Luau Callback을 저장하면 안 된다.

## 7. Roll과 공개

Roll 흐름:

```text
RollPlan
→ Named RNG Stream
→ Sealed Result
→ RollRecord Candidate
→ Audience별 공개 Policy
→ 최소 결과 Reveal
→ RollRecord Commit 또는 부모 Execution 결과에 포함
```

Advantage와 Disadvantage는 수치 보너스로 변환하지 않고 Roll Plan의 상태로 합성한다. 둘이 동시에 존재하면 Core Policy가 상쇄 결과를 제공한다. Client 물리 Dice와 Timestamp는 결과를 만들지 않는다.

Public RollRecord와 DM Diagnostic은 다를 수 있다. 숨은 Modifier Source, 비공개 DC, Secret Target과 DM-only Policy는 Player Payload·Tooltip·Support Bundle에 포함하지 않는다.

## 8. Attack·Save·Damage·Healing

Basic Attack:

```text
Attack Capability
→ Attacker·Target·Range·Line·Eligibility 검증
→ Attack RollPlan vs AC
→ RollRecord
→ Hit·Miss Outcome
→ Damage RollPlan
→ Final Damage Candidate
→ HP·Temporary HP PendingEffect
→ Atomic Commit
```

Saving Throw:

```text
Effect Source
→ Target Save Profile·DC Snapshot
→ Save RollPlan
→ Success·Failure Branch
→ Pending Effect Set
→ Commit
```

Damage RollRecord는 HP를 직접 수정하지 않는다. Damage Type, Resistance·Immunity·Reduction은 Final Damage Candidate 계산에 Contribution으로 들어가며, 실제 Temporary HP·Current HP·즉시 Vital Closure는 Transaction Provider가 확정한다.

Healing은 Maximum HP를 초과하지 않으며, HP 0 이후 VitalState 복구 여부는 Actor Policy와 후속 Slice의 세부 계약을 따른다.

## 9. Command·Prompt·Projection

대표 Command:

| Command | 검증 | 결과 |
|---|---|---|
| `BeginCapabilityExecution` | Controller, Capability Version, Target Context, Policy Snapshot | Execution Ref와 Receipt |
| `SubmitExecutionSelection` | Prompt Revision, Allowed Option, Connection Epoch | Execution Resume |
| `SubmitRollRevealAck` | Audience, Reveal Revision | 공개 Gate 진행; 결과 재계산 없음 |
| `CancelRuleExecution` | 취소 가능 상태, Reservation Policy | Pending 입력 폐기·Reservation 정산 |
| `AdjudicateExecution` | DM Role, 허용 Adjudication Kind, Mandatory Audit | Versioned DM Decision |

Projection:

- `CapabilityProjection`
- `AuthorityPromptProjection`
- `RollRecordProjection`
- `ExecutionStatusProjection`
- `CharacterCombatStatProjection`
- `HPResourceProjection`

Prompt와 Selection은 Connection이 끊겨도 Authority Record가 필요하면 유지한다. 새 연결에서 최신 Projection을 다시 발행하며 이전 Prompt Revision 응답은 거부한다.

## 10. Transaction·Persistence·Recovery

Ordering Key는 Execution Source·Target과 Resource Owner를 결정적 순서로 정렬한다. 장기 대기 동안 Ordering Lock을 유지하지 않고 Action·Resource·Target 사용권은 타입 있는 Reservation으로 보존한다.

저장 대상:

- Ruleset·Policy·Recipe·Handler Version Ref
- RuleExecution State·Cursor·Parent·Child
- Pending Input·Roll Plan·Committed RollRecord
- Resource Reservation과 PendingEffect Set
- Character HP·Resource·Effect State
- Commit Journal·Outbox Cursor

저장하지 않는 값:

- Client Dice 물리 위치
- Roll Animation 진행률
- Tooltip·Preview와 임시 Hit Chance
- UI Button Enabled 상태

Recovery는 정확한 Version을 찾지 못하면 최신 Handler로 자동 승격하지 않는다. Read-only Recovery, DM Review 또는 안전 취소를 사용한다. Rollback은 새 AuthorityEpoch에서 Execution·Roll·Reservation을 복원하며 이전 Branch의 Prompt·ACK·Subscriber를 거부한다.

## 11. UI와 Presentation 경계

UI는 다음 상태를 표현한다.

```text
Capability 불가 이유
대상 선택 중
DM 판정 대기
Roll 준비·공개 중
결과 Commit 중
Resource 부족
Revision 충돌
Reconnect·Execution 복구 중
Version 누락·Recovery Review 필요
```

PresentationIntent는 `roll_reveal`, `attack`, `damage_result`, `healing_result`, `condition_applied` 같은 의미를 받는다. VFX·Camera·Marker 실패가 Roll·HP·Effect 결과를 바꾸지 않는다.

## 12. Diagnostics·Security·Budget

Trace:

```text
capability.resolve
rule_execution.start
recipe.step
prompt.issue
roll.plan
roll.resolve
pending_effect.plan
transaction.commit
roll.publish
execution.recover
```

Security:

- Client가 Recipe·Handler·Modifier·DC·Roll Result를 제출하지 못한다.
- Content Definition에 임의 Module·Remote·URL·Callback을 저장하지 않는다.
- DM Adjudication은 Role·Scope·Mandatory Audit를 거친다.
- Public Error에 Secret Modifier와 Raw Target Ref를 넣지 않는다.

측정 대상:

- Execution Step 수와 대기 Record 크기
- Roll·Modifier Contribution 처리 시간
- Reservation 수와 Commit Write Set
- Projection Payload와 Roll Reveal 지연
- Recipe Compile·Registry Memory

구체 수치는 대표 Scenario와 Roblox Profiling 전 확정하지 않는다.

## 13. Test 계획

1. Ability Check 성공·실패와 Proficiency 적용.
2. Advantage 두 개와 Disadvantage 하나의 Core Policy 합성.
3. Basic Attack Hit·Miss·Critical과 AC Revision 충돌.
4. Saving Throw Branch와 비공개 DC 누출 차단.
5. Damage Resistance·Temporary HP·Current HP 원자 Commit.
6. Healing Maximum HP 제한.
7. Resource 예약 후 Cancel·Timeout·Disconnect 정산.
8. 중복 Selection·Roll ACK의 멱등 처리.
9. Commit 직후 Restart에서 RollRecord와 HP 복원.
10. Handler Version 누락 시 Last Known Good·Recovery Review.
11. Player·DM·Observer Roll Projection 차이와 Secret Canary.
12. 동일 Seed·Schedule에서 State·Event·Projection Digest 일치.
13. Step Handler 오류가 다른 Execution과 Server 전체를 손상하지 않음.
14. Presentation ACK 유실 후 Hard Fallback으로 공개되며 결과 불변.

## 14. 구현 순서와 완료 기준

```text
Policy·Content ID·Version Foundation
→ Derived Stat·Capability Query
→ RuleExecution Adapter
→ Recipe Compiler·Step Provider
→ D20 RollRecord
→ Attack·Save·Damage·Healing
→ Effect·Resource 최소 기반
→ Persistence·Diagnostics·Scenario
```

계약 완료 판정:

- 대표 Check·Attack·Save가 하나의 Kernel을 사용한다.
- Roll과 State Mutation이 분리된다.
- Recipe·Handler가 Orchestrator·Transaction을 우회하지 않는다.
- Version 고정·Recovery·Rollback·Disclosure가 정의된다.
- 후속 Exploration과 Encounter가 임시 판정 엔진을 만들 필요가 없다.

Production 구현 전 남은 Gate는 실제 Package Mapping, Legacy Migration 조사와 공식 Core Profile 데이터의 권리·출처 검토다.