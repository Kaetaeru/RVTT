# ADR-0092: 캠페인 생존·보급 규칙과 DM 저작 Actor Token Pipeline을 사용한다

- 상태: 확정
- 결정일: 2026-08-06
- 결정 종류: Campaign Policy · Game Time · Inventory · Survival Logistics · Content Authoring · Actor Token
- 보강 대상:
  - [`ADR-0001`](ADR-0001-authored-rules-content.md)
  - [`ADR-0003`](ADR-0003-ruleset-source-packs-localization.md)
  - [`ADR-0006`](ADR-0006-rigless-3d-token-continuous-movement.md)
  - [`ADR-0010`](ADR-0010-replicatedstorage-prefab-catalog.md)
  - [`ADR-0013`](ADR-0013-single-character-and-scene-scoped-npcs.md)
  - [`ADR-0051`](ADR-0051-inventory-loot-transfer-and-identification.md)
  - [`ADR-0091`](ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md)
- 상세 계약:
  - [`campaign-survival-logistics-and-supply-settlement-runtime-contract.md`](../architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md)
  - [`dm-authored-actor-token-and-statblock-import-runtime-contract.md`](../architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md)
  - [`CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md`](../user-guides/dm/CAMPAIGN-SURVIVAL-AND-ACTOR-TOKEN-AUTHORING.md)

## 1. 배경

Campaign Game Time이 여러 날 진행되어도 식량·물·탈것 사료·탄약과 같은 자원이 자동으로 아무 의미 없이 남아 있으면 여행과 장기 활동의 세부 규칙이 실제 플레이에 연결되지 않는다. 반대로 모든 캠페인에 생존 규칙을 강제하면 서사 중심 세션의 진행을 방해한다.

또한 DM은 기본 Actor Definition과 Token Prefab만 사용하는 것이 아니라, 자신의 캠페인에 필요한 NPC·몬스터·동료를 추가해야 한다. 이 기능은 임의 Script 실행이나 무검증 AI 출력 가져오기가 아니라, 신뢰된 Asset Registry와 엄격한 Stat Block Schema를 사용하는 저작 Pipeline이어야 한다.

## 2. 캠페인 생존 규칙은 교체 가능한 Policy Module이다

생존·보급 기능은 하나의 전역 Boolean으로 만들지 않는다.

```text
survival.logistics.enabled
survival.food.enabled
survival.water.enabled
survival.mount_feed.enabled
survival.exposure.enabled
survival.encumbrance.enabled
survival.ammunition.enabled
survival.rest_quality.enabled
survival.spoilage.enabled
```

Campaign 생성 시 DM은 다음 Preset 중 하나를 선택한다.

```text
Narrative
→ 보급 자동 소비 없음, 필요 시 수동 기록

Standard
→ 식량·물 예측과 경고, 기본적으로 DM 확인 후 정산

Survival
→ 활성 규칙 팩의 소비량·결핍·환경 규칙을 자동 정산

Custom
→ Module별 개별 설정
```

Preset은 UI 편의를 위한 Binding 묶음이며, 권위 원본은 Campaign Policy Binding과 Frozen Snapshot이다.

## 3. 정확한 소비량과 결핍 결과는 Ruleset Content가 제공한다

Engine에 `하루 식량 몇 개`, `하루 물 몇 단위`, `며칠 후 어떤 상태` 같은 수치를 하드코딩하지 않는다.

```text
Ruleset·Source Pack
→ ConsumptionRequirementDefinition
→ Supply Unit Definition
→ Shortage Consequence Recipe
→ Stable Rule Anchor
```

개발·테스트에서는 활성 한국어 통합 Rule Profile의 규칙 Anchor를 사용하고, 공개 Release에서는 SRD Profile이 제공하는 재배포 가능한 규칙만 사용한다.

## 4. Time Advance와 보급 정산은 하나의 계획으로 Commit한다

```text
TimeAdvanceProposal
→ 날짜·식사·휴식·여행 경계 계산
→ 보급 요구량과 사용 가능한 공급원 계산
→ Supply Settlement Preview
→ ItemInstance Reservation
→ DM 확인 또는 Policy 자동 승인
→ Time·Inventory·Shortage Consequence Atomic Commit
```

시간만 먼저 진행한 뒤 식량을 나중에 차감하거나, 식량만 차감한 뒤 시간 진행에 실패하는 상태를 허용하지 않는다.

일부 날짜, 부분 수량과 여러 날 점프를 지원한다. 8일 여행 중 3일째 사건이 발생하면 8일 소비를 먼저 확정하지 않고 해당 Checkpoint까지만 정산한다.

## 5. 캠페인 진행 중 설정 변경

DM은 Campaign Rules Tool에서 Module을 변경할 수 있다. 변경은 다음 흐름을 따른다.

```text
변경 Proposal
→ Candidate Policy Snapshot Compile
→ 영향 Preview
→ 안전 경계 선택
→ Atomic Activation
```

기본 규칙:

- 변경은 과거 소비를 자동 재계산하지 않는다.
- 기능을 끄면 미래 Settlement만 중단한다.
- 이미 소비된 Item을 환불하지 않는다.
- 이미 발생한 결핍 Effect를 조용히 제거하지 않는다.
- 기능을 켜면 다음 미정산 경계부터 적용한다.
- 과거 날짜 재정산은 별도 `Retroactive Reconcile` 도구에서 Preview·확인·Audit 후 실행한다.
- 활성 Time Advance, Rest, Travel, Downtime 또는 Supply Transaction 중간에는 변경하지 않는다.

## 6. 공급원과 소비 안전성

기본 공급원 우선순위:

```text
Actor Inventory
→ 지정된 Party Supply Container
→ Vehicle·Mount Storage
→ 접근 가능한 Camp·Campaign Storage
```

DM은 Campaign 단위로 우선순위를 변경할 수 있다.

Item은 명시적인 `supplyKind`, `supplyUnits`, `consumptionPolicy`를 가져야 한다. 이름이나 Thumbnail만 보고 음식처럼 보이는 Item을 자동 소비하지 않는다.

다음 Item은 기본 자동 소비 대상이 아니다.

- Quest·Key Item
- 잠금·예약된 Item
- 식별되지 않은 위험 Item
- 명시적으로 보호된 Stack
- 다른 사용자의 비공개·접근 불가 Container

## 7. DM Actor·Token 저작

DM은 Asset Registry에서 Actor Model을 등록하거나 기존 Model을 선택하고, 검증된 Stat Block Definition과 결합해 Campaign-local Actor Template을 만들 수 있다.

```text
Actor Model Asset 등록·선택
→ Stat Block 입력 또는 AI Prompt 생성
→ Strict JSON Import
→ Schema·Ruleset·Asset·Rights Validation
→ Preview와 오류 수정
→ Campaign Draft 저장
→ Publish
→ SceneNpc 생성
```

다음 데이터를 분리한다.

```text
ActorModelAssetDefinition
≠ ActorStatBlockDefinition
≠ TokenPrefabDefinition
≠ ActorTemplateDefinition
≠ SceneNpcInstance
```

하나의 Model을 여러 Stat Block과 결합할 수 있고, 하나의 Stat Block에 다른 Campaign Presentation을 연결할 수 있다.

## 8. AI Prompt Builder

RVTT는 외부 AI 서비스에 직접 요청하는 필수 기능이 아니라, DM이 복사해 사용할 수 있는 Prompt를 생성한다.

Prompt에는 다음을 넣는다.

- 현재 `rulesetId`와 Rule Profile
- 엄격한 JSON Schema
- DM이 입력한 Stat Block 원문 또는 Homebrew 요구
- 현재 사용자에게 보이는 모든 Actor Model Catalog Entry
- 허용된 `actorModelAssetId` 목록
- 공식 수치 임의 수정 금지
- 불확실한 값을 창작하지 말라는 지침
- JSON 한 개 외의 텍스트 출력 금지

Actor Model 이름은 문서에 고정 목록으로 복사하지 않는다. Prompt 생성 시 `ActorModelCatalogProjection`을 Stable Asset ID 순으로 열거한다.

현재 Registry가 비어 있으면 다음을 넣는다.

```json
{"models": []}
```

AI는 존재하지 않는 Model ID를 발명할 수 없으며, DM이 Model을 등록하거나 명시적 Placeholder를 선택하기 전에는 Publish할 수 없다.

## 9. 신뢰와 보안 경계

- AI 출력은 항상 Untrusted Draft다.
- AI 출력으로 임의 Luau, Script, ModuleScript, Remote 또는 Asset URI를 실행하지 않는다.
- Actor Model Import 시 Script 계열 Instance는 거부하거나 제거한다.
- Model·Texture·Audio의 Rights와 Provenance가 필수다.
- 공식 Stat Block이라고 표시하려면 활성 Rule Package의 Stable Source Anchor가 필요하다.
- 출처가 없는 항목은 `homebrew` 또는 `campaign_custom`으로 표시한다.
- 공식 수치와 CR을 자동으로 재조정하지 않는다.
- Automation은 `manual` 또는 신뢰된 `recipeRef`만 허용한다.
- Validation을 통과해도 DM의 명시적 Publish 전에는 Scene에서 사용할 수 없다.

## 10. UI Surface

DM Modular Workspace에 다음 독립 Tool을 추가한다.

```text
Campaign Rules
Supply Ledger
Time Advance Supply Preview
Actor Model Registry
Actor & Token Builder
AI Prompt Builder
Stat Block JSON Validator
Actor Preview
```

각 Tool은 ADR-0090의 독립 Window Module 계약을 따른다.

## 11. Acceptance

- Campaign 생성 시 Narrative·Standard·Survival·Custom을 선택할 수 있다.
- Campaign 진행 중 Module 변경은 Candidate Snapshot과 영향 Preview를 사용한다.
- Toggle이 과거 Item·Effect를 조용히 재작성하지 않는다.
- 여러 날 Time Advance가 중간 사건과 Supply Settlement Checkpoint를 건너뛰지 않는다.
- 식량·물 정산은 명시적 Supply Metadata가 있는 ItemInstance만 소비한다.
- 부분 날짜·부분 Stack·여러 Consumer·Mount·Follower를 결정적으로 처리한다.
- Rollback·Retry 후 같은 Settlement가 중복 소비되지 않는다.
- DM이 Actor Model을 등록하고 Stat Block JSON과 결합할 수 있다.
- Prompt Builder가 현재 Actor Model Catalog의 모든 보이는 Entry를 Stable 순서로 포함한다.
- 존재하지 않는 `actorModelAssetId`를 Import하지 못한다.
- JSON Schema가 임의 Script와 미등록 Recipe를 허용하지 않는다.
- AI Draft는 자동 Publish되지 않는다.
- Campaign-local Actor Template이 원본 Core Content를 직접 변경하지 않는다.
