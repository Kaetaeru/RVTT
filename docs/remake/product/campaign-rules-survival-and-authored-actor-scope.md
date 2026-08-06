# 캠페인 규칙·생존 보급·DM 저작 Actor 제품 범위

- 상태: 확정
- 문서 종류: Product Scope
- 최종 갱신일: 2026-08-06
- 상위 결정: [`ADR-0092`](../decisions/ADR-0092-campaign-survival-logistics-and-dm-authored-actor-tokens.md)
- 상세 Runtime:
  - [`Campaign Survival Logistics`](../architecture/campaign-survival-logistics-and-supply-settlement-runtime-contract.md)
  - [`DM-authored Actor Token`](../architecture/dm-authored-actor-token-and-statblock-import-runtime-contract.md)
- Slice 동기화: [`ADR-0092 Slice Sync Plan`](../specs/ADR-0092-SLICE-SYNC-PLAN.md)

## 1. 제품 결정

RVTT는 서사 중심 캠페인과 세부 생존 규칙을 사용하는 캠페인을 모두 지원한다.

생존·보급은 전 제품에 강제되는 단일 모드가 아니라 캠페인 생성과 진행 중에 DM이 관리하는 Campaign Rule Profile이다.

```text
Narrative
Standard
Survival
Custom
```

Profile은 다음 Module을 조합한다.

```text
Food
Water
Mount Feed
Exposure
Encumbrance
Ammunition
Rest Quality
Spoilage
```

Preset은 UI 편의를 위한 Binding 묶음이다. 실제 권위는 Campaign Policy Binding과 Frozen Policy Snapshot이다.

## 2. 정확한 규칙 수치의 소유자

Engine과 UI에 하루 소비량, 결핍 시작 시점, 환경 배율과 공식 규칙 결과를 하드코딩하지 않는다.

```text
활성 Ruleset·Source Pack
→ Consumption Requirement
→ Supply Unit
→ Shortage Consequence Recipe
→ Stable Rule Anchor
```

- 개발·테스트 Profile은 권한이 확인된 통합 규칙 Source를 사용할 수 있다.
- 공개 Release는 재배포 권한이 있는 Public Profile만 포함한다.
- Rule Profile에 필요한 Definition이 없으면 임의 수치를 만들어 자동 정산하지 않는다.
- DM의 명시적 Homebrew 값은 Campaign Policy Source와 변경 기록을 가진다.

## 3. 시간 진행과 보급

여행·휴식·다운타임·DM 시간 진행이 Logistics Boundary를 넘으면 Supply Preview가 생성될 수 있다.

```text
Time Advance Proposal
→ Logistics Boundary
→ Consumer와 Requirement 계산
→ 공급원·보호 Stack·예약 충돌 계산
→ Preview
→ DM 확인 또는 Campaign Policy 승인
→ Time·Inventory·Shortage 결과 Atomic Commit
```

제품 결과:

- 부분 날짜와 부분 Stack을 지원한다.
- 여러 날 진행은 중간 사건과 Supply Boundary에서 나눈다.
- 시간만 진행되고 Item 소비가 실패한 혼합 상태를 허용하지 않는다.
- Retry·Restart·Rollback 후 같은 Settlement가 중복 소비되지 않는다.
- Hidden Actor와 비공개 Container를 Player 수량·오류·예측에 누출하지 않는다.

Quest·Key·Protected·Reserved Item과 Supply Metadata가 없는 Item은 기본 자동 소비 대상이 아니다.

## 4. 캠페인 진행 중 규칙 변경

DM은 Campaign Rules에서 Profile 또는 Module을 변경할 수 있다.

```text
Change Proposal
→ Candidate Frozen Policy Snapshot
→ Impact Preview
→ Safe Boundary Activation
```

기본은 비소급이다.

- 끄더라도 이미 소비한 Item을 환불하지 않는다.
- 기존 결핍 Effect를 조용히 제거하지 않는다.
- 켜더라도 과거 기간을 자동 재정산하지 않는다.
- 새 설정은 다음 미정산 안전 경계부터 사용한다.
- 과거 재정산은 별도 Retroactive Reconcile Preview·Confirm·Audit 작업이다.

## 5. DM 저작 Actor와 Token

DM은 Campaign에 필요한 NPC·Monster·Follower를 순수 데이터와 검증된 Asset으로 추가할 수 있다.

```text
Actor Model Registry
→ Stat Block Draft
→ Strict JSON Validation
→ Actor·Token Preview
→ Campaign-local Package Publish
→ SceneNpc Spawn
```

다음 원본과 상태를 분리한다.

```text
ActorModelAssetDefinition
ActorStatBlockDefinition
TokenPrefabDefinition
ActorTemplateDefinition
SceneNpcInstance
```

- 하나의 Model을 여러 Stat Block과 함께 사용할 수 있다.
- Core Content를 Campaign Draft가 직접 수정하지 않는다.
- 새 Template Version이 기존 SceneNpc를 자동 교체하지 않는다.
- 적용 중인 NPC는 명시적 Migration·Rebind Review를 사용한다.

## 6. Actor Model Registry

등록 Model은 Stable Asset ID, 표시 이름, 허용 Size·Footprint·Scale, Feet Pivot, Bounds, 성능 Budget, Rights와 Provenance를 가진다.

Model Import는 Script·LocalScript·ModuleScript·RemoteEvent·RemoteFunction과 실행 가능한 외부 Callback을 허용하지 않는다.

Registry가 비어 있으면 제품은 존재하지 않는 기본 Model 이름을 제시하지 않는다. DM은 먼저 Model을 등록하거나 명시적 Placeholder 정책을 선택해야 한다.

## 7. AI Prompt Builder의 제품 경계

AI Prompt Builder는 외부 AI 서비스의 필수 Runtime 통합이 아니다. DM이 복사해 사용할 Prompt를 생성하는 저작 보조 도구다.

Prompt에는 다음을 포함한다.

- 현재 Ruleset과 Rule Profile
- Strict JSON Schema
- DM의 원문 또는 Homebrew Brief
- 허용된 Trusted Recipe
- 현재 DM에게 보이는 모든 Actor Model Catalog Entry

Model Catalog는 Stable Asset ID 순으로 전체를 포함한다. 비어 있으면 `models: []`를 제공한다.

AI 출력은 항상 Untrusted Draft다.

- JSON Object 하나 외의 출력은 Import하지 않는다.
- 존재하지 않는 Model ID와 미등록 Recipe를 거부한다.
- 임의 Script·Luau·Remote·URL Callback을 실행하지 않는다.
- 공식 수치나 CR을 자동 보정하지 않는다.
- DM 검토 없이 자동 Publish하지 않는다.

## 8. 최종 포함 범위와 단계적 구현

최종 제품 범위에는 다음이 포함된다.

- Campaign Rule Profile과 Module별 Toggle
- Supply Metadata·Allocation·Reservation·Settlement
- Supply Ledger와 역할별 Projection
- Campaign Rules·Time Advance Preview DM Tool
- Actor Model Registry
- Strict Stat Block JSON Import
- Actor Model Catalog Projection과 AI Prompt Builder
- Campaign-local Actor Template Publish
- SceneNpc Spawn·Version Migration

이 범위는 하나의 초기 Slice에 몰아 넣지 않는다.

```text
Slice 06
→ Supply Metadata와 Item·Container Reservation 기반

Slice 07
→ Campaign Time·Policy·Settlement·Ledger Authority

Slice 11
→ Campaign Rules·Preview·Reconcile DM Tool

Slice 12
→ Requirement·Schema·Catalog·Trusted Recipe Content Platform

Slice 15
→ Model Registry·Stat Block·Template Publish·SceneNpc

Slice 16
→ 장시간 Session·Rollback·Disclosure·Performance Release Gate
```

현재 진행 중인 UI·UX 정합화와 기존 Slice 01 Runtime 검증을 중단시키지 않는다. ADR-0092 Production 구현은 선행 Slice의 실제 Source Mapping과 Acceptance가 준비된 순서대로 착수한다.

## 9. 명시적인 비목표

- 모든 캠페인에 생존 규칙 강제
- Item 이름이나 Thumbnail만 보고 자동 소비
- Hidden Consumer·Storage를 Player 예상치에 포함
- 외부 AI가 직접 Campaign Authority를 수정
- AI 결과 자동 Publish
- Campaign Data로 Trusted Operation 또는 Code 등록
- 임의 Model Script 실행
- 공식 Stat Block·CR 자동 재조정
- 기존 NPC의 무검토 자동 Migration

## 10. 제품 Acceptance

- Campaign 생성 시 Narrative·Standard·Survival·Custom을 선택할 수 있다.
- 진행 중 변경은 Candidate Snapshot·Impact Preview·Safe Boundary를 사용한다.
- 여러 날 진행이 중간 사건과 Supply Boundary를 건너뛰지 않는다.
- 명시적 Supply Metadata가 있는 Item만 자동 정산 후보가 된다.
- Retry·Restart·Rollback이 중복 소비를 만들지 않는다.
- DM이 Model을 등록하고 Strict Stat Block과 결합할 수 있다.
- Prompt가 현재 보이는 전체 Model Catalog를 Stable 순서로 포함한다.
- AI Draft·미등록 Model·Code·Recipe가 자동 Publish되지 않는다.
- Campaign-local Template이 Core Content와 기존 SceneNpc를 조용히 덮어쓰지 않는다.
