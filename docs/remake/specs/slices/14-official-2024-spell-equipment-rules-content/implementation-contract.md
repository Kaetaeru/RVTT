# Implementation Spec — Slice 14 Official 2024 Spell·Equipment·Rules Content

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Content Coverage Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유:
  - 공식 Spell·Equipment·Rule 데이터의 Source·Version·권리·배포 범위를 검토하지 않았다.
  - 실제 Content·Recipe·Item·Localization·Asset Pipeline을 확인하지 못했다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Core Rules`](../02-core-rules-kernel/implementation-contract.md), [`Inventory`](../06-inventory-equipment-world-items/implementation-contract.md), [`Content Platform`](../12-content-pack-localization-trusted-extension/implementation-contract.md), [`Character Content`](../13-official-2024-character-options-content/implementation-contract.md)
- 관련 Guide: [`Rules`](../../../guides/rules/README.md), [`Character`](../../../guides/character/README.md), [`Combat`](../../../guides/combat/README.md), [`Extension`](../../../guides/extension/README.md), [`UI`](../../../guides/ui/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> 이 Spec은 공식 2024 Spell·Equipment·Rule Family의 Coverage 계약을 정의한다. 실제 콘텐츠는 공통 RuleExecution·Recipe·Item·Effect Runtime을 재사용하며, 규칙 본문을 장문 복제하지 않는다.

## 1. Acceptance Flow

```text
Character Capability·Inventory에서 Content 선택
→ Cast·Use·Attack·Action Route 검증
→ Target·Range·Resource·Component 확인
→ Roll·Save·Damage·Effect 실행
→ Duration·Concentration·Condition·Item State Commit
→ Projection·Presentation·저장
```

## 2. 직접 권위 문서

- [`Rules Content Execution과 Spell Contract`](../../../architecture/rules-content-execution-and-spell-contract.md)
- [`Spell Casting Route와 2024 Spell Runtime`](../../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md)
- [`Effect Recipe Resolution과 Commit`](../../../architecture/effect-recipe-resolution-and-commit-model.md)
- [`Effect, Condition과 Ongoing Runtime`](../../../architecture/effect-condition-and-ongoing-runtime-contract.md)
- [`Character Action·2024 Core Action Runtime`](../../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution`](../../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`Inventory, ItemInstance와 World Presence`](../../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Spell Acquisition·Preparation·Cast Access`](../../../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
- [`Item·Weapon·Attack Profile·Mastery`](../../../systems/inventory/item-weapon-attack-profile-and-mastery-model.md)
- [`Shared Recipe Runtime 001`](../../shared/001-recipe-step-runtime-foundation.md)
- [`Shared Step Handler 002`](../../shared/002-standard-step-handler-contracts.md)

## 3. 범위

포함:

- Spell Definition, Casting Route, Level, School·Tag, Target·Range·Area, Component·Resource·Duration
- Acquisition·Preparation·Repository·Cast Access 연결
- Weapon·Armor·Gear·Consumable Definition
- Weapon Attack Profile·Mastery·Equipment Requirement
- Condition·Duration·Concentration·Ongoing Effect
- Core Action·Reaction·Rest 관련 Rule Content
- Recipe·Step·SubRecipe·Advanced Operation Coverage
- Localization·Source Metadata·Rights Review
- Content Wave·Coverage Matrix·Migration·Regression

제외:

- 규칙 본문 장문 복제
- 공식 Artwork·Asset 무검토 배포
- NPC·Monster Statblock: Slice 15
- 사용자 임의 Script Content

## 4. Content Definition Type

```lua
export type SpellDefinition = {
    contentRef: string,
    sourceMetadataRef: string,
    spellLevel: number,
    spellTags: {string},
    castingRouteRef: string,
    targetProfileRef: string,
    resourceCostRef: string?,
    durationProfileRef: string?,
    concentrationProfileRef: string?,
    recipeRef: string,
    localizationKeyPrefix: string,
}

export type EquipmentDefinition = {
    contentRef: string,
    sourceMetadataRef: string,
    itemKind: "weapon" | "armor" | "gear" | "consumable",
    equipmentProfileRef: string?,
    attackProfileRefs: {string},
    useCapabilityRefs: {string},
    grantRefs: {string},
    recipeRefs: {string},
    localizationKeyPrefix: string,
}

export type ConditionDefinition = {
    contentRef: string,
    contributionRefs: {string},
    durationPolicyRef: string,
    stackingPolicyRef: string,
    cleanupTriggerRefs: {string},
    presentationTagRefs: {string},
}

export type ContentCoverageRecord = {
    familyId: string,
    definitionStatus: string,
    compileStatus: string,
    scenarioStatus: string,
    migrationStatus: string,
    localeStatus: string,
    rightsStatus: string,
}
```

모든 Definition은 Stable ID·Pack Version·Source Metadata를 가진다. 표시 이름과 Locale String이 Authority Ref를 대체하지 않는다.

## 5. Spell Casting Route

```text
Character Capability
→ Acquisition·Preparation·Repository·Equipment Access
→ Current Resource·Component·Opportunity 검증
→ Target·Range·Line·Area Selection
→ Frozen Binding
→ RuleExecution
→ Roll·Save·PendingEffect
→ Resource·Effect·Item Transaction
→ Projection·Presentation
```

Cast Access는 Character Source·Build, Preparation State, Item·Repository Binding, Effect Contribution과 Frozen Policy에서 계산한다. Client가 `castable=true`, Spell DC, Target Count와 Damage를 제출하지 않는다.

Casting Route는 Action, Bonus Action, Reaction, Ritual, Item Use와 DM Adjudicated Route를 구분한다. Encounter 외 실행은 Opportunity가 없더라도 Session·Mode Policy를 따른다.

## 6. Weapon·Armor·Gear·Consumable

Weapon은 Item Definition과 Character·Equipment 상태에서 Attack Profile을 파생한다.

```text
Weapon ItemInstance·Equipment Binding
+ Character Build·State
+ Mastery·Effect Contribution
+ Ruleset Policy
→ Attack Capability·Attack Profile
```

Armor는 AC Contribution과 Requirement를 제공하며 Character Source를 수정하지 않는다. Consumable은 Item Quantity·Charge Reservation 후 RuleExecution을 시작하고 Commit 성공 시 소비한다. 실행 실패·Cancel 시 Policy에 따라 Reservation을 해제한다.

## 7. Condition·Duration·Concentration

Effect Instance는 Definition, Source Execution, Owner·Target, Start Boundary, Duration Policy, Contribution Set과 Revision을 가진다.

```text
Pending Effect
→ Stacking·Immunity·Eligibility 검증
→ Effect Instance Plan
→ State·Resource·Concentration Transaction
→ Event·Projection
```

Concentration은 별도 Resource·Binding으로 관리하며 새 Concentration 시작 시 기존 Effect 종료 Plan을 같은 Transaction 또는 명시적 Closure로 처리한다. Turn·Round·Campaign Time Duration을 혼용하지 않는다.

Condition은 UI Tag만으로 규칙을 구현하지 않는다. Modifier·Capability·Movement·Visibility·Action Restriction Contribution을 구조화한다.

## 8. Core Action·Reaction·Rest Content

다음은 Runtime이 아닌 Versioned Rule Content로 제공한다.

- 일반 Action·Bonus Action·Reaction Route
- Dash·Disengage·Dodge·Help·Hide·Ready·Search·Study 등 Core Capability
- Rest 중 회복 Option·Resource Choice
- Weapon Mastery·Item Use·Basic Interaction Rule Profile

Encounter Timeline, Character State와 Navigation을 직접 수정하지 않고 Capability·RuleExecution·Contribution을 통해 연결한다.

## 9. Recipe·Step Coverage

표준 표현 우선순위:

```text
Standard Step
→ SubRecipe
→ Parameterized Trusted Operation
→ 명시적 Exception Spec·Scenario
```

대표 Step Family:

- Select Target·Area·Option
- Validate Range·Line·Visibility
- Roll Check·Save·Attack·Damage·Healing
- Reserve·Spend Resource·Item
- Apply·Remove Effect·Condition
- Move·Teleport·Create Runtime Object Proposal
- Wait for Prompt·Reaction·DM Adjudication
- Emit Presentation Intent

Advanced Operation은 반복·대상·시간·생성 Effect Budget을 가진다. Content가 Handler를 통해 Store·Remote·Workspace를 직접 수정하지 못한다.

## 10. Content Wave와 Coverage Matrix

Wave 예시:

```text
Core Weapons·Armor·Gear
→ Basic Conditions·Actions
→ Cantrip·Low-level Spell Families
→ Higher-level Spell Families
→ Complex Summon·Shapechange·Area·Persistent Effects
→ Full Regression·Migration
```

Wave는 Dependency Closure를 만족해야 한다. Spell Definition만 있고 Recipe·Targeting·Effect·Scenario가 없으면 `active`가 아니다.

Coverage Matrix 축:

- Spell Level·School·Casting Route
- Target·Area·Range Family
- Roll·Save·Attack·Automatic Outcome
- Damage·Healing·Condition·Movement·Summon Family
- Concentration·Duration·Upcast·Resource
- Weapon·Armor·Gear·Consumable·Mastery
- Action·Reaction·Rest Rule
- ko-KR Locale·Source Metadata·Rights
- Compile·Scenario·Migration·Disclosure

## 11. Source Metadata·Localization·Rights

Content Record는 Source Edition·Version·Publication Ref와 Rights Review Status를 가진다. 구현 저장소에는 필요한 구조화 수치·Tag·Formula·Reference와 자체 작성 Short Summary만 둔다.

Locale Bundle은 Name·UI Summary·Prompt·Accessibility 설명을 제공한다. 규칙 의미는 Definition·Recipe에 둔다. 권리 검토가 끝나지 않은 Text·Artwork·Asset은 Release Candidate에 포함하지 않는다.

## 12. Migration·Missing Content

Pack Upgrade 시:

```text
Old Content Ref·Active Execution·Character·Item·Effect
→ Definition·Recipe Diff
→ Compatibility·Migration
→ Candidate Recompile
→ State·Effect·Item Migration Plan
→ Review·Activation
```

진행 중 Execution과 Effect는 시작 Version을 유지한다. Version 누락 시 최신 Definition을 자동 사용하지 않는다. Read-only Recovery, Safe Cancel 또는 DM Review를 사용한다.

## 13. Diagnostics·Security·Test

Diagnostic:

- Missing Recipe·Step·Operation
- Invalid Target·Duration·Concentration Profile
- Unsupported Character·Item Dependency
- Missing Locale·Source Metadata·Rights
- Coverage Scenario 누락
- Migration Adapter 누락

Security:

- Content에 Code·Module·Remote·URL 금지
- Client가 Spell Result·Item Cost·Condition State를 확정하지 못함
- Hidden Spell·Item·Effect Source와 DM-only Modifier 누출 금지
- Operation Budget·Target·Loop 제한

Test:

1. Spell Cast Access·Preparation·Resource.
2. Target·Range·Area·Selection Revision.
3. Attack·Save·Automatic Outcome Family.
4. Damage·Healing·Condition·Concentration.
5. Duration의 Turn·Round·Campaign Time 분리.
6. Consumable Reservation·Commit·Cancel.
7. Weapon Attack Profile·Mastery·Equipment 변경.
8. Core Action·Reaction·Rest Capability.
9. Recipe·Step 결정성·Missing Handler Recovery.
10. Complex Operation Budget·Failure Isolation.
11. Localization·Source·Rights Release Gate.
12. Pack Upgrade 중 Active Execution Version 고정.
13. Restart·Rollback 후 Spell·Item·Effect Version 복원.
14. Content Family Coverage Matrix 완전성.

## 14. 구현 순서와 완료 기준

```text
Common Content Schema·Source Metadata
→ Core Equipment·Actions·Conditions
→ Spell Casting Route·Basic Families
→ Recipe·Step Coverage 확대
→ Complex Spell·Effect Family
→ Localization·Rights·Migration
→ Coverage Regression
```

완료 기준:

- Spell·Equipment·Rule Content가 공통 Runtime을 재사용한다.
- Definition만 있고 실행·Scenario가 없는 Placeholder가 없다.
- 예외 Operation은 명시적 계약·Budget·Test를 가진다.
- 전체 Family Coverage가 Matrix로 추적된다.
- Source·Rights Review가 Release Gate다.

Production 구현은 공식 데이터·권리 검토와 실제 Content Pipeline Mapping 전에는 시작할 수 없다.