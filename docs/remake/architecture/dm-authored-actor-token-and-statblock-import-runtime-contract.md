# DM-authored Actor Token과 Stat Block Import Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 작성일: 2026-08-06
- 최종 갱신일: 2026-08-07
- 상위 결정: [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- 관련 결정:
  - [`ADR-0001`](../decisions/ADR-0001-authored-rules-content.md)
  - [`ADR-0003`](../decisions/ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0006`](../decisions/ADR-0006-rigless-3d-token-continuous-movement.md)
  - [`ADR-0010`](../decisions/ADR-0010-replicatedstorage-prefab-catalog.md)
  - [`ADR-0013`](../decisions/ADR-0013-single-character-and-scene-scoped-npcs.md)
  - [`ADR-0091`](../decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)

## 1. 목적

DM이 자신의 캠페인에 필요한 Actor Model, Stat Block과 Token Presentation을 추가할 수 있게 하되, 임의 Script 실행, 존재하지 않는 Asset ID, 검증되지 않은 AI 출력과 원본 Core Definition 오염을 막는다.

```text
Model 등록·선택
→ Stat Block Draft
→ AI Prompt 또는 직접 JSON
→ Strict Validation
→ Preview
→ Campaign Draft
→ Publish
→ SceneNpc Instance
```

## 2. 데이터 경계

```text
ActorModelAssetDefinition
├─ 시각 Model·Pivot·Bounds·Rig·Rights

ActorStatBlockDefinition
├─ 규칙 수치·행동·특성·Source

TokenPrefabDefinition
├─ Model + Footprint + Selection + Presentation

ActorTemplateDefinition
├─ Stat Block + Token Prefab + Campaign Defaults

SceneNpcInstance
├─ 현재 HP·상태·위치·진영·제어권
```

이 다섯 항목을 하나의 JSON이나 Roblox Model로 합치지 않는다.

## 3. Actor Model Asset Registry

```text
ActorModelAssetDefinition
├─ actorModelAssetId
├─ packageId
├─ version
├─ displayNameKey
├─ sourceContentHash
├─ runtimeContentAddress
├─ thumbnailAssetId
├─ modelKind
├─ rigProfile
├─ sizeCompatibility[]
├─ defaultFootprint
├─ bounds
├─ feetPivot
├─ verticalOffsetRange
├─ scaleRange
├─ selectionBounds
├─ animationProfileRef?
├─ materialVariantRefs[]
├─ performanceBudget
├─ rights
├─ provenance
├─ validationState
└─ contentHash
```

초기 `modelKind`:

```text
rigless_mesh
rigless_model
registered_rig
placeholder
```

기본 Token은 ADR-0006에 따라 `rigless_mesh` 또는 `rigless_model`이다. Humanoid나 Roblox Player Character를 권위 Actor 구조로 사용하지 않는다.

### Model Import Validation

- Stable Asset ID 중복 금지
- Feet Pivot과 Bounds 필수
- 허용 Scale·Size·Footprint 필수
- Script·LocalScript·ModuleScript 금지
- RemoteEvent·RemoteFunction 금지
- 예상하지 않은 Constraint·Physics Controller 거부
- 외부 Asset URI와 Dependency 검사
- Triangle·Texture·Material·Memory Budget 검사
- Rights·Provenance 필수
- Thumbnail과 Selection Preview 생성 가능 여부

Client가 업로드한 Model Instance를 서버가 그대로 Workspace에 삽입하지 않는다. 검증된 Package Build를 통해서만 Runtime Address를 만든다.

## 4. Actor Model Catalog Projection

Prompt Builder와 DM UI는 전체 Authority Asset Registry가 아니라 권한 필터링된 Projection을 사용한다.

Schema 원본:

```text
implementation/roblox/content-templates/actor-model-catalog.schema.json
```

```text
ActorModelCatalogProjection
├─ schemaVersion
├─ catalogRevision
├─ packageVersionSet
├─ models[]
└─ disclosureDigest
```

각 Entry:

```text
ActorModelCatalogEntry
├─ actorModelAssetId
├─ displayName
├─ modelKind
├─ rigProfile
├─ sizeCompatibility[]
├─ defaultFootprint
├─ scaleRange
├─ thumbnailViewRef
├─ rightsSummary
└─ availabilityState
```

Prompt에 넣을 때 `actorModelAssetId` 오름차순으로 Stable 정렬한다. 현재 권한으로 보이지 않는 Asset은 이름·개수·빈 슬롯도 노출하지 않는다.

`disclosureDigest`는 권한 필터링된 뒤의 canonical Model Entry 목록을 기준으로 계산한다. 같은 Viewer Context, Package Version Set과 Catalog Revision은 같은 Digest를 만들어야 한다.

현재 Catalog가 비어 있으면 Prompt에는 정확히 다음 canonical 구조를 넣는다.

```json
{
  "schemaVersion": "rvtt.actor-model-catalog.v1",
  "catalogRevision": 0,
  "packageVersionSet": [],
  "models": [],
  "disclosureDigest": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```

ADR 예시, Runtime Serializer, Prompt fixture와 테스트는 이 Schema를 공통 원본으로 사용한다. 축약형 `{"models":[]}` 또는 필드 일부가 빠진 별도 형식을 canonical output으로 사용하지 않는다.

## 5. Stat Block JSON

Schema 원본:

```text
implementation/roblox/content-templates/actor-statblock.schema.json
```

Schema는 Identity와 Source, D&D 2024 Size·Type·Alignment, AC·HP·Speed·Ability Scores, Save·Skill·Damage·Condition·Sense·Language, CR·XP·Proficiency, Trait·Action·Bonus Action·Reaction·Legendary Action, Spellcasting, Token Asset Binding, Provenance·Import Notes를 분리한다.

`additionalProperties=false`를 기본으로 사용해 오타 필드와 임의 Payload를 거부한다.

## 6. Automation 경계

```text
manual
trusted_recipe
```

```text
manual
→ 설명과 Roll·Target 도구를 제공하고 DM이 결과를 판정

trusted_recipe
→ Registry에 등록된 recipeRef만 실행
```

금지:

- AI가 만든 Luau 코드
- JSON 안의 Script 문자열 실행
- 임의 Module Path
- 임의 Remote Name
- Workspace Mutation 식
- 검증되지 않은 URL Callback

미등록 `recipeRef`는 Publish를 차단한다.

## 7. Source와 Official 표시

Canonical `sourceType`:

```text
sourceType
├─ rules_package
├─ campaign_homebrew
├─ imported_reference
└─ unknown_draft
```

`rules_package`를 사용하려면 활성 Package ID, Stable Rule·Definition Anchor, Source Version, Content Hash 또는 Definition Ref가 필요하다.

AI가 `official=true`를 자유롭게 생성하지 못한다. Source Anchor가 없으면 `campaign_homebrew` 또는 `unknown_draft`다.

`homebrew`와 `campaign_custom`은 이전 문서에서 사용된 legacy alias이며 `actor-statblock.schema.json`은 이를 거부한다. Importer가 legacy alias를 자동으로 canonical 값으로 바꾸지 않는다. 명시적 Migration 또는 DM 수정이 필요하다.

공식 Definition을 Import할 때 수치·CR·Action을 자동 조정하지 않는다. 변경하려면 Campaign-local Derived Template로 만들고 Diff와 이유를 기록한다.

## 8. AI Prompt Builder

템플릿 원본:

```text
implementation/roblox/content-templates/actor-statblock-ai-prompt.md
```

입력:

```text
rulesetId
activeRuleProfileId
locale
statBlockSourceText 또는 homebrewBrief
strictJsonSchema
actorModelCatalogProjection
knownTrustedRecipeCatalog
sourcePolicy
```

출력은 사용자에게 복사 가능한 Plain Text Prompt다. RVTT가 외부 AI 계정·대화·결과를 권위로 신뢰하지 않는다.

Prompt 필수 지침:

- JSON Object 하나만 출력
- Schema 외 Field 금지
- 제공된 Source Text 밖의 공식 내용을 복원하지 않음
- 공식 수치 임의 변경 금지
- `actorModelAssetId`는 Catalog에 있는 값만 사용
- 적절한 Model이 없으면 `token.actorModelAssetId=null`
- `sourceType`은 Strict Schema의 canonical enum만 사용
- Script·Code·URL 생성 금지
- 불확실한 값은 Import Warning으로 표시
- Automation은 `manual` 우선

## 9. Import Pipeline

```text
Paste JSON
→ JSON Parse
→ Schema Validation
→ Semantic Validation
→ Rule Content Validation
→ Asset Reference Validation
→ Rights·Provenance Validation
→ Automation Trust Validation
→ Preview Build
→ DM Review
→ Campaign Draft Save
```

Semantic Validation:

- ID 형식과 Campaign Namespace
- Size와 Token Footprint 호환
- AC·HP·Ability·Speed 타입과 범위
- Action ID 중복
- Attack·Save·Damage 구조 일관성
- Spell Reference의 활성 Package 존재
- CR·XP·Proficiency 표현 일관성 진단
- Natural Language 설명의 길이·Locale
- Token Scale·Offset 허용 범위

Validator는 규칙상 최적화나 CR 재계산을 자동 적용하지 않는다. 진단만 제공한다.

## 10. Campaign-local Package

```text
CampaignLocalContentPackage
├─ packageId
├─ campaignId
├─ version
├─ actorStatBlockDefinitions[]
├─ tokenPrefabDefinitions[]
├─ actorTemplateDefinitions[]
├─ assetDependencies[]
├─ ruleDependencies[]
├─ localizationEntries[]
├─ provenanceIndex
├─ validationReportRef
├─ publishedBy
├─ publishedRevision
└─ contentHash
```

Campaign-local Package는 Core Package를 직접 수정하지 않는다.

Draft와 Published Version을 분리한다. 기존 SceneNpc는 생성 당시 Template Version을 참조하며, 새 Version Publish가 활성 NPC의 현재 HP·상태·Action을 조용히 바꾸지 않는다.

## 11. Template Update와 Migration

```text
새 Template Version
→ 기존 Instance 영향 Diff
→ new_spawn_only | compatible_migration | explicit_migration
```

기본값은 `new_spawn_only`다.

기존 NPC에 적용하려면 최대 HP와 현재 HP 처리, 제거·추가 Action, Resource State, Token Size·Footprint·현재 위치, Encounter Participant 상태, 지속 Effect와 Concentration, Player Control Assignment를 검토한다.

활성 RuleExecution·Reaction·Transaction 중에는 Migration하지 않는다.

## 12. DM UI Module

```text
Actor Model Registry
→ Import·Validate·Thumbnail·Rights·Publish

Actor & Token Builder
→ Stat Block·Model·Footprint·Presentation 결합

AI Prompt Builder
→ Schema·Catalog·Source Text로 Prompt 생성

Stat Block JSON Validator
→ Parse·Schema·Semantic·Rule·Asset 진단

Actor Preview
→ Sheet·Token·Action·Hover·Selection·Scale 확인
```

각 창은 ADR-0090의 Move·Resize·Dock·Tab·Close 계약을 따른다.

## 13. Failure Code

```text
ACTOR_MODEL_CATALOG_EMPTY
ACTOR_MODEL_CATALOG_SCHEMA_MISMATCH
ACTOR_MODEL_NOT_FOUND
ACTOR_MODEL_NOT_VISIBLE
ACTOR_MODEL_SCRIPT_FORBIDDEN
ACTOR_MODEL_RIGHTS_MISSING
ACTOR_MODEL_BUDGET_EXCEEDED
STATBLOCK_JSON_INVALID
STATBLOCK_SCHEMA_MISMATCH
STATBLOCK_SOURCE_TYPE_LEGACY_ALIAS
STATBLOCK_SEMANTIC_INVALID
RULE_REFERENCE_NOT_FOUND
RECIPE_NOT_TRUSTED
TOKEN_SIZE_INCOMPATIBLE
TOKEN_SCALE_OUT_OF_RANGE
SOURCE_PROVENANCE_REQUIRED
CAMPAIGN_PACKAGE_CONFLICT
TEMPLATE_MIGRATION_REQUIRED
```

## 14. Acceptance

- Prompt Builder가 현재 보이는 Actor Model Entry 전부를 Stable 순서로 포함한다.
- Catalog가 비어 있으면 canonical versioned JSON fixture를 사용하고 Model ID를 발명하지 않으며 Publish를 차단한다.
- Actor Model Catalog Serializer와 fixture가 같은 JSON Schema를 사용한다.
- JSON Schema 밖의 Field를 거부한다.
- canonical Source Type 네 개를 허용하고 `homebrew`·`campaign_custom` legacy alias를 거부한다.
- AI 결과가 Script·Luau·Remote를 등록하지 못한다.
- 미등록 Recipe를 실행하지 못한다.
- Rights·Provenance가 없는 Model을 Publish하지 못한다.
- Official 표시는 Stable Source Anchor가 있을 때만 가능하다.
- Core Actor Definition은 Campaign Draft에 의해 직접 변경되지 않는다.
- Template Update가 기존 NPC를 자동 Migration하지 않는다.
- SceneNpc Spawn은 검증된 Published Package Version만 사용한다.