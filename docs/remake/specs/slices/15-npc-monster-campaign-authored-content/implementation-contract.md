# Implementation Spec — Slice 15 NPC·Monster·Campaign Authored Content

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Content·Runtime Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유:
  - 실제 NPC·Monster Statblock 데이터의 Source·Version·권리·배포 범위를 검토하지 않았다.
  - 기존 Actor·Token·Prefab·JSON Import·Campaign Content Source Tree를 확인하지 못했다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 계약: [`Core Rules`](../02-core-rules-kernel/implementation-contract.md), [`Encounter`](../04-encounter-core-loop/implementation-contract.md), [`Character`](../05-character-foundation-creation/implementation-contract.md), [`Inventory`](../06-inventory-equipment-world-items/implementation-contract.md), [`Content Platform`](../12-content-pack-localization-trusted-extension/implementation-contract.md), [`Spell·Equipment Content`](../14-official-2024-spell-equipment-rules-content/implementation-contract.md)
- 관련 Guide: [`Character`](../../../guides/character/README.md), [`Rules`](../../../guides/rules/README.md), [`Combat`](../../../guides/combat/README.md), [`Scene`](../../../guides/scene/README.md), [`Extension`](../../../guides/extension/README.md), [`Journal`](../../../guides/journal/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> NPC와 Monster는 별도 규칙 엔진이 아니다. Actor Definition이 Character·Rules·Item·Effect Capability를 조합하고, Runtime Actor Instance는 Scene Presence와 현재 State만 소유한다.

## 1. Acceptance Flow

### DM

```text
Catalog Statblock 선택 또는 JSON Import
→ Validation·Normalization·Content Ref Resolution
→ Candidate Actor Definition Compile
→ Diagnostic·Preview·Review
→ Campaign Content Publish
→ Scene Token·Prefab 배치
→ Exploration·Encounter에서 Control
→ Loot·Journal·저장·Migration
```

### Player

Player는 자신에게 공개된 이름·외형·상태·행동 결과만 받는다. 비공개 Statblock 수치, 숨은 Capability, DM Note와 전체 Loot Table은 공개 Policy를 따른다.

## 2. 직접 권위 문서

- [`Character Runtime과 Compiled Character Build`](../../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`Rules Content Grant와 Capability`](../../../architecture/rules-content-grant-capability-model.md)
- [`Rules Content Execution과 Spell Contract`](../../../architecture/rules-content-execution-and-spell-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Encounter Timeline, Turn, Opportunity와 Objective`](../../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md)
- [`Inventory, ItemInstance와 World Presence`](../../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`Monster·NPC Statblock과 안전한 JSON Import`](../../../systems/character/monster-npc-statblock-and-ingame-json-import-model.md)
- [`Content Platform Spec`](../12-content-pack-localization-trusted-extension/implementation-contract.md)

## 3. 범위

포함:

- NPC·Monster Actor Definition Source와 Compiled Build
- Actor Instance Persistent State와 Scene Runtime Presence
- Statblock Schema·Normalizer·Content Reference Resolver
- Safe JSON Import·Diagnostic·Candidate Review
- Campaign Authored Content Source·Publish·Version
- Token·Prefab·Appearance Binding
- Rules·Spell·Item·Effect Capability 연결
- Encounter·Faction·Control·Objective Integration
- Loot·Inventory·Journal Anchor Integration
- Missing Pack·Content·Version Migration·Recovery·Export
- Starter Catalog·Fixture·Coverage Matrix

제외:

- NPC Dialogue Tree·생성형 대화 AI
- 자동 전술 AI 전체
- 공식 Monster Catalog 전체 포함 약속
- Import된 Code·Remote·URL 실행
- 공식 규칙 본문·Artwork의 무검토 배포

## 4. Actor Definition·Instance Type

```lua
export type ActorDefinitionSource = {
    actorDefinitionId: string,
    sourceKind: "official_pack" | "developer_pack" | "campaign_authored",
    sourceVersionRef: string,
    sourceRevision: number,
    creatureProfile: CreatureProfileSource,
    capabilityRefs: {string},
    itemLoadoutRefs: {string},
    effectRefs: {string},
    presentationProfileRef: string?,
    prefabBindingRef: string?,
    localizationKeyPrefix: string,
}

export type CreatureProfileSource = {
    size: string,
    creatureType: string,
    abilityScores: {[string]: number},
    proficiencyProfileRef: string,
    armorProfileRef: string,
    hitPointProfileRef: string,
    speedProfiles: {string},
    saveRefs: {string},
    skillRefs: {string},
    senseRefs: {string},
    languageRefs: {string},
    immunityRefs: {string},
    resistanceRefs: {string},
    vulnerabilityRefs: {string},
}

export type CompiledActorDefinition = {
    actorBuildId: string,
    actorDefinitionId: string,
    sourceRevision: number,
    compilerVersion: string,
    rulesetSnapshotRef: string,
    contentVersionSet: {string},
    derivedStatProfile: {[string]: unknown},
    capabilityRefs: {string},
    attackProfileRefs: {string},
    buildHash: string,
}

export type ActorPersistentState = {
    actorInstanceId: string,
    actorBuildRef: string,
    stateRevision: number,
    currentHitPoints: number,
    temporaryHitPoints: number,
    resourceStates: {[string]: unknown},
    conditionRefs: {string},
    inventoryOwnerRef: string?,
}

export type ActorSceneBinding = {
    actorInstanceId: string,
    runtimeObjectId: string,
    runtimeIncarnation: string,
    sceneRuntimeRef: string,
    transformRevision: number,
    controllerRef: string?,
}
```

Actor Definition, Persistent State, Encounter Participant와 Runtime Presence를 하나의 Record로 합치지 않는다. Scene 이동·Respawn에서 Runtime Incarnation은 바뀔 수 있지만 Actor Instance와 Build Ref는 정책에 따라 유지된다.

## 5. Statblock Schema와 Normalizer

Normalizer는 입력 표현을 공통 Definition Schema로 변환한다.

```text
Input Statblock
→ Schema Version·Size·Depth·String·Array Budget
→ Enum·Number·Formula Parsing
→ Stable Content Ref Resolution
→ Ability·Defense·HP·Speed·Sense·Language Normalize
→ Capability·Spell·Item·Effect Mapping
→ Candidate Definition
→ Compile·Diagnostic
```

구조화되는 항목:

- Ability Scores·Modifier·Proficiency
- AC Source·HP Formula·Speed Modes
- Saving Throw·Skill·Sense·Language
- Immunity·Resistance·Vulnerability
- Actions·Bonus Actions·Reactions·Legendary 또는 Special Capability
- Spellcasting Profile·Spell Ref
- Equipment·Loot Ref
- Size·Creature Type·Faction·Tag

표시 문자열을 Capability ID, Spell ID와 Item ID로 그대로 실행하지 않는다. Resolver는 명시적 Stable Ref 또는 사용자 확인 Mapping을 요구한다.

## 6. Safe JSON Import

허용 입력은 순수 데이터다.

금지:

- Luau·JavaScript·Module Path
- RemoteEvent·Function Name
- 외부 URL·Webhook·Asset Download Instruction
- Callback·Expression Eval·Template Code
- 무제한 중첩·재귀 Graph
- 권한 없는 Asset·Content Ref

Import 상태:

```text
uploaded
→ structural_validation
→ reference_resolution
→ normalized
→ compile_ready
→ review_required
→ published | rejected
```

Import 실패가 Active Catalog·Scene·Actor State를 변경하지 않는다. Diagnostic은 입력 위치와 안전한 오류를 제공하되 Raw Secret·Credential·전체 Payload를 일반 Support View에 포함하지 않는다.

## 7. Campaign Authored Content Publish

```text
Normalized Candidate
→ Campaign Ruleset·Pack Binding 검증
→ Actor Definition Compile
→ Capability·Recipe·Item Dependency Closure
→ Token·Prefab·Localization 검증
→ DM Preview·Player Audience Preview
→ Publish Command
→ Campaign Content Version Activation
```

Campaign Authored Content는 Trusted Operation과 Tool Module을 새로 등록하지 못한다. 기존 Registry에 등록된 Definition·Recipe·Operation만 참조한다.

수정 시 새 Source Revision과 Candidate Build를 만든다. 이미 배치된 Actor Instance를 조용히 최신 Build로 바꾸지 않고 Migration·Rebind Policy를 사용한다.

## 8. Token·Prefab·Scene Binding

```text
Actor Definition·Appearance Profile
→ 검증된 Prefab Catalog Ref
→ Scene Placement Source 또는 Runtime Spawn Command
→ Actor Instance 생성·Binding
→ Runtime Object Presence·Incarnation
```

Client가 Prefab ID, Mesh·Asset Ref, Transform과 Size를 권위로 확정하지 않는다. Prefab 누락 시 Actor State를 삭제하지 않고 Safe Placeholder·Diagnostic과 Rebind Review를 제공한다.

Token 외형과 이름은 공개 Policy를 따르며, 숨은 Actor는 Player Scene·Camera·VFX·Error Payload에 존재하지 않는다.

## 9. Rules·Encounter·Loot Integration

Actor Capability는 Slice 02·14 Runtime을 재사용한다.

```text
Compiled Actor Definition
→ Capability Projection
→ RuleExecution
→ Roll·PendingEffect·Transaction
```

Encounter는 Actor Build·State를 복제하지 않고 Participant Binding과 Control만 가진다. DM 또는 위임된 Controller가 일반 Capability를 실행할 때 같은 Command Route를 사용한다.

Loot:

- Actor Inventory는 ItemInstance·Location Binding을 사용한다.
- Loot Table은 결과 후보를 제공하며 ItemInstance 생성은 Transaction을 거친다.
- 사망 시 Actor 삭제와 Inventory 삭제를 자동 결합하지 않는다.
- Secret Loot·미식별 Item은 Player Projection Policy를 따른다.

Journal Anchor는 Actor Definition, Actor Instance 또는 Runtime Presence를 명시적으로 구분한다.

## 10. Missing Content·Migration·Export

Missing Pack·Spell·Item·Recipe·Prefab 처리:

```text
Reference Scan
→ Missing Dependency Diagnostic
→ Read-only Actor Build 또는 Safe Capability Disable
→ Mapping·Migration Candidate
→ DM Review
→ Recompile·Rebind·Atomic Activation
```

이름이 같은 최신 Definition으로 자동 치환하지 않는다. 진행 Encounter와 RuleExecution은 시작 Version을 유지한다.

Export는 Campaign 소유 Source와 공개 가능한 Metadata만 포함한다. 공식 Pack 본문·권리 제한 Asset·Secret DM Note·Internal Diagnostic을 무단 포함하지 않는다.

## 11. Starter Catalog와 Fixture

초기 개발용 Fixture와 Release Content를 분리한다.

```text
Test Fixture
→ deterministic test 전용

Starter DM Catalog
→ Rights·Source·Localization·Scenario Gate 통과한 실제 Content
```

Fixture가 Release Catalog에 노출되지 않도록 Pack Trust·Environment Gate를 사용한다. Starter Catalog는 전체 공식 Monster Coverage를 의미하지 않으며 지원 범위를 Coverage Matrix로 명시한다.

Coverage 축:

- Creature Type·Size·Movement·Sense
- Basic Attack·Save·Condition·Spellcasting
- Reaction·Special Capability
- Inventory·Loot·Death·Encounter
- Token·Prefab·Localization
- Import·Migration·Disclosure Scenario

## 12. Persistence·Recovery·Rollback

저장:

- Actor Definition Source·Revision·Compiled Build Ref
- Actor Instance State·Inventory Owner
- Scene Binding·Runtime Incarnation Mapping
- Campaign Content Version·Import Mapping
- Missing Dependency·Migration·Rebind Record
- Encounter·Journal·Loot Stable References

Restart는 Build·State·Presence를 복원하고 Derived Capability와 Projection을 재생성한다. Rollback은 정확한 Content·Actor Build·State·Scene Binding을 새 AuthorityEpoch에서 복원한다. 이전 Import·Publish·Controller Command를 거부한다.

## 13. UI·Diagnostics·Security

DM UI 상태:

```text
Import 구조 오류
Content Ref 매핑 필요
Compile Warning·Error
Player Audience Preview
Prefab 누락
사용 중 Actor Migration 필요
Read-only Recovery
Publish·Rebind 완료
```

Trace:

```text
actor.import
actor.normalize
actor.reference_resolve
actor.compile
campaign_content.publish
actor.instance_create
actor.scene_bind
actor.migrate
actor.export
```

Security:

- Import Payload·String·Array·Graph·Formula Budget
- Code·URL·Remote·Asset 권한 차단
- Player Projection의 Secret Stat·Capability·Loot·Source 누출 차단
- DM Publish·Migration·Force Rebind Mandatory Audit
- Malformed Formula·NaN·Infinity·범위 초과 수치 거부

## 14. Test 계획

1. 정상 Statblock Import→Compile→Publish→Scene 배치.
2. Code·URL·Remote·과도한 Depth·Payload 거부.
3. Spell·Item 문자열 Ambiguity와 수동 Mapping.
4. Ability·AC·HP·Speed·Sense Normalize.
5. 같은 입력·Version의 Actor Build Hash 결정성.
6. Actor Capability가 Core Rules·Encounter를 재사용.
7. Token Prefab 누락과 Safe Placeholder.
8. Hidden Actor·Secret Stat·Loot Negative Disclosure.
9. Actor 사망 후 Inventory·시체 Presence 보존.
10. Active Actor Definition Upgrade·Migration Review.
11. Missing Pack·Recipe·Prefab Read-only Recovery.
12. Restart·Rollback 후 exact Build·State·Binding 복구.
13. Fixture와 Release Catalog 분리.
14. 대규모 NPC Catalog·Scene Presence·Projection Budget.

## 15. 구현 순서와 완료 기준

```text
Actor Definition·Build·State
→ Statblock Schema·Normalizer
→ Safe JSON Import
→ Campaign Candidate·Publish
→ Token·Prefab·Scene Binding
→ Rules·Encounter·Loot·Journal Integration
→ Migration·Export·Coverage
→ Security·Integration Test
```

완료 기준:

- NPC·Monster가 공통 Character·Rules·Item·Encounter Runtime을 재사용한다.
- Import는 순수 데이터이며 Code·URL·Remote를 실행하지 않는다.
- Definition·State·Presence가 분리된다.
- Missing Content와 Upgrade가 명시적 Migration·Review를 사용한다.
- 공개 범위와 Rights Gate가 Release Content에 적용된다.

Production 구현은 실제 Actor·Prefab·Import Pipeline과 Statblock Data·Rights Review 전에는 시작할 수 없다.