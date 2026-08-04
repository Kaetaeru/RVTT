# Visibility, Knowledge, Detection과 Hover Information Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Perception Relation 재평가 주기와 공간 무효화 배치 크기
  - Hover Information Projection 캐시 TTL
  - HP 단계 표시 기본 임계값
  - 개인 발견을 파티에 자동 공유하는 캠페인 기본값
  - Noise Event 기본 감쇠 곡선
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0035`](../decisions/ADR-0035-manual-fog-masks-and-optional-region-assist.md)
  - [`ADR-0036`](../decisions/ADR-0036-observer-relative-perception-senses-stealth-and-rule-points.md)
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0055`](../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0071`](../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0073`](../decisions/ADR-0073-observer-relative-visibility-knowledge-and-hover-projections.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Selection, Targeting, Preview와 Frozen Binding Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Effect, Condition과 Ongoing Runtime 계약`](effect-condition-and-ongoing-runtime-contract.md)
- 관련 시스템:
  - [`수동 Fog of War와 선택형 Assist 모델`](../systems/perception/manual-fog-of-war-and-optional-assist-model.md)
  - [`시야·감각·은신·탐지 모델`](../systems/perception/visibility-senses-stealth-and-detection-model.md)

## 1. 목적

이 문서는 특정 관찰자에게 무엇이 현재 보이고, 무엇이 감지되며, 무엇을 기억하고 있고, 그중 어떤 정보를 Client Hover·Selection·Targeting·Journal에 공개할 수 있는지를 정의한다.

핵심 원칙:

```text
Visible
≠ Detected
≠ Known
≠ Disclosed
```

```text
서버 Authority State
→ Observer-relative Information Projection
→ Hover·Selection·UI Presentation
```

Client는 숨은 Runtime Object, 실제 HP, 비밀 DC, 미식별 Item Definition과 같은 권위 정보를 받은 뒤 숨기는 방식으로 구현하지 않는다.

## 2. 책임 분리

### Visibility

현재 시각적으로 관측 가능한지를 판단한다.

입력 예시:

- Line of Sight
- Rule Lighting
- Obscurement
- Invisibility
- Blindness
- Fog Current Reveal
- Vision Blocker

### Detection

시각 외 감각, 은신 대결, Search와 Trigger를 통해 대상의 존재나 위치를 알아차렸는지를 판단한다.

결과 예시:

```text
undetected
presence_known
approximate_location_known
exact_location_known
visually_perceived
fully_revealed
```

### Knowledge

현재 보이지 않더라도 이전 발견이나 DM 공개로 알고 있는 사실을 관리한다.

예시:

- 이전에 본 방 구조
- 발견한 함정 위치
- 식별한 아이템 이름
- 한 번 확인한 Actor 정체
- DM이 공개한 저항 또는 약점

### Disclosure

현재 관찰자에게 어떤 정보 필드를 전달할지 결정한다.

Visibility나 Knowledge가 있다고 해서 모든 세부 정보를 자동 공개하지 않는다.

## 3. Observer Context

모든 판정은 관찰자 기준이다.

```text
ObserverContext
├─ viewerUserId
├─ viewerRole
├─ controlledCharacterIds[]
├─ projectionAudienceIds[]
├─ sceneId
├─ baseMode
├─ activeContexts[]
├─ dmPreviewAudience?
└─ revision
```

지원 관찰자 유형:

```text
player
DM
player_observer
DM_observer
system
```

DM은 전체 Authority를 조회할 수 있지만, 플레이어 시점 미리보기에서는 선택한 Audience와 동일한 Projection만 받아야 한다.

## 4. Perceivable Entity

탐지 대상은 Actor에 한정하지 않는다.

```text
PerceivableEntityRef
├─ runtimeObjectRef?
├─ itemInstanceId?
├─ effectInstanceId?
├─ sceneRegionId?
├─ entityKind
└─ revision
```

`entityKind` 예시:

```text
actor
scene_object
item_presence
trap
secret_feature
illusion
scene_effect
noise_source
area_feature
custom_registered
```

Workspace Instance는 권위 Entity Reference가 아니다.

## 5. Perception Relation

```text
PerceptionRelation
├─ observerBinding
├─ subjectBinding
├─ visibilityState
├─ detectionLevel
├─ knowledgeState
├─ contributingSenseIds[]
├─ evidenceReferences[]
├─ lastConfirmedLogicalTime
├─ expiryPolicy?
└─ revision
```

`visibilityState`:

```text
not_visible
partially_visible
visible
visually_obscured
```

`knowledgeState`:

```text
unknown
suspected
known
identified
fully_disclosed
```

관계는 전역 Boolean이 아니며 Observer별로 다를 수 있다.

## 6. Fog와 Perception의 경계

수동 Fog는 지형 공개 권위이며 Actor 탐지 엔진을 대체하지 않는다.

```text
Fog DiscoveryMask
→ 지형을 기억하는가

Fog CurrentRevealMask
→ 현재 지형을 표시할 수 있는가

Perception Relation
→ Actor·함정·비밀문·효과를 인식하는가
```

Current Reveal 영역에 있어도 숨은 함정은 Detection을 통과하기 전까지 Projection되지 않는다.

Discovery 영역 밖의 숨은 Runtime Identity는 플레이어 Client에 전송하지 않는다.

## 7. Sense Capability

감각은 Character Build, Item, Effect와 Form Overlay가 기여하는 Capability다.

```text
SenseCapability
├─ senseKind
├─ rangeExpression
├─ originProfile
├─ targetFilters[]
├─ requiredSignatures[]
├─ blockerPolicy
├─ lightingPolicy
├─ precisionLevel
├─ informationPolicy
└─ activationPredicate
```

초기 감각:

```text
normal_vision
darkvision
blindsight
tremorsense
truesight
hearing
scent
magic_detection
custom_registered
```

감각마다 제공 가능한 정보의 최대 수준이 다르다.

예를 들어 Tremorsense가 정확한 위치를 제공하더라도 대상 외형이나 색상을 공개하지 않는다.

## 8. Stealth와 Detection Contest

은신은 모든 관찰자에게 동일한 전역 숨김 상태가 아니다.

```text
Hide Action
→ Stealth RollRecord
→ Stealth Evidence 생성
→ Observer별 Detection Contest
→ PerceptionRelation 갱신
```

관찰자가 대상을 발견해도 다른 관찰자의 관계가 자동 변경되지는 않는다.

Knowledge Scope 또는 명시적 공유 Command가 있을 때만 다른 Audience에 전파한다.

## 9. Search, Study와 Discovery

```text
Search 또는 Study RuleExecution
→ Roll·DM Adjudication
→ Discovery Proposal
→ Authority Transaction
→ Knowledge Record 갱신
→ Projection 갱신
```

Discovery는 UI 알림이 아니라 저장 가능한 Authority State다.

```text
KnowledgeRecord
├─ knowledgeRecordId
├─ subjectBinding
├─ knowledgeKind
├─ scopeBinding
├─ informationLevel
├─ disclosedFieldSetId
├─ sourceExecutionId?
├─ acquiredAtLogicalTime
├─ expiryPolicy?
└─ revision
```

## 10. Knowledge Scope

```text
character
player
party
faction
global
DM_only
custom_registered
```

기본적으로 개인 발견은 캠페인 설정에 따라 Character 또는 Party Scope를 사용한다.

DM은 발견 정보를 다른 Scope로 공개하거나 회수할 수 있다. 회수는 과거에 실제로 본 정보를 플레이어의 기억에서 자동 삭제한다는 의미가 아니라, 시스템 Projection의 권위 상태를 변경한다.

## 11. Noise Event

음악과 사운드 이펙트를 구현하지 않더라도 규칙상 소리는 존재한다.

```text
NoiseEvent
├─ sourceBinding
├─ origin
├─ intensityProfile
├─ propagationProfile
├─ semanticTags[]
├─ occurredAtLogicalTime
└─ revision
```

문 파괴, 큰 주문, 함정 작동과 고함은 Noise Event를 만들 수 있다.

Noise Event는 청각 Detection 후보를 만들지만 실제 오디오 재생을 요구하지 않는다.

## 12. Information Disclosure Profile

각 Entity는 공개 가능한 정보 묶음을 정의한다.

```text
InformationDisclosureProfile
├─ fieldGroups[]
├─ minimumKnowledgeByGroup
├─ minimumDetectionByGroup
├─ roleOverrides
├─ modeOverrides
└─ identificationPolicy
```

대표 Field Group:

```text
existence
approximate_location
exact_location
public_name
identified_name
faction
health_band
exact_hit_points
armor_class
public_conditions
hidden_conditions
resistances
immunities
item_rarity
item_definition
interaction_summary
```

실제 공개 여부는 Observer Context, Perception Relation, Knowledge Record와 역할을 결합해 결정한다.

## 13. Hover Information Projection

Hover는 별도 권위 조회 우회로가 아니다.

```text
Pointer Hover
→ Selection Candidate
→ Observer-relative Disclosure Evaluation
→ HoverInformationProjection
→ Hover Card Presentation
```

```text
HoverInformationProjection
├─ subjectPublicRef
├─ displayName?
├─ categoryLabel?
├─ healthBand?
├─ publicConditions[]
├─ interactionHints[]
├─ detectionSummary?
├─ knowledgeSummary?
├─ warningTags[]
├─ projectionRevision
└─ expiresAt?
```

Hover Card의 위치, 크기, 지연 시간과 애니메이션은 UI 문서가 담당한다.

Architecture는 다음만 보장한다.

- Hover 후보가 될 수 있는지
- 어떤 필드를 공개할 수 있는지
- Projection Revision이 최신인지
- 숨겨진 Authority 정보가 Client에 전달되지 않는지

## 14. 역할별 Hover 정보

### PLAYER_ONLY Projection

플레이어는 자신의 현재 Audience에 공개된 정보만 받는다.

기본 예시:

- 공개 또는 식별된 이름
- 알려진 진영
- 체력 단계
- 공개 상태
- 실행 가능한 상호작용 힌트
- 감지 방식에 맞는 위치 정확도

다음은 기본적으로 공개하지 않는다.

- 실제 최대·현재 HP 숫자
- 실제 AC
- 숨은 상태
- 저항·면역
- 미식별 아이템 Definition
- 비밀문·함정 Runtime Identity

규칙·DM 공개·Knowledge Record가 허용하면 일부 필드를 추가할 수 있다.

### DM_ONLY Projection

DM Hover는 다음을 포함할 수 있다.

- Authority 이름과 Runtime Identity
- 실제 HP·AC·상태
- 숨은 태그와 Detection 상태
- Item Definition과 식별 상태
- Visibility·Knowledge 진단
- Journal Link Target 정보

DM의 전체 Hover Projection은 플레이어 Client에 전송하지 않는다.

### Observer

Player Observer는 할당된 Audience Projection을 사용한다.

DM Observer는 Full 또는 특정 Player Preview Projection을 선택할 수 있다.

## 15. Hover, Selection과 Inspection 구분

```text
Hover
→ 일시적 간략 정보

Selection
→ 대상 Binding 보존

Inspection
→ 허용된 상세 정보 Panel

Target
→ Capability 실행 입력
```

Hover에서 클릭하면 Selection 또는 Inspection으로 전환할 수 있지만, 더 상세한 정보는 새 Projection Policy를 다시 통과해야 한다.

Hover가 제공하지 않은 숨은 필드를 Client가 로컬 데이터에서 복원할 수 없어야 한다.

## 16. Targeting과 Interaction 기여

Visibility Runtime은 대상 지정 가능 여부를 단독 결정하지 않는다.

```text
Perception Relation
+ Capability Targeting Policy
+ Spatial Query
+ Rule Context
→ Target Eligibility
```

예를 들어 보이지 않는 대상도 정확한 위치를 알고 있고 규칙이 허용하면 공격 대상 후보가 될 수 있다.

Interaction Candidate도 Disclosure Policy를 통과한 대상만 플레이어에게 제공한다.

## 17. Projection과 Streaming

Projection은 Client Interest와 분리된다.

```text
Authority Entity 존재
≠ Client에 복제 가능
≠ 현재 화면에 Streaming 필요
```

숨은 Entity를 Presentation Interest 때문에 미리 Client에 복제하지 않는다.

Knowledge가 지형 기억만 허용할 경우에는 라이브 Runtime Object 대신 안전한 Remembered Geometry Projection을 사용한다.

## 18. 저장·재접속·롤백

저장 대상:

- Fog Discovery와 Current Reveal Authority State
- Knowledge Record
- 지속되는 Detection Evidence
- 식별 상태
- DM 공개·회수 기록
- Observer Scope Binding
- 관련 Build Reference와 Revision

재생성 가능한 Line of Sight Cache, Hover Card, Candidate Highlight와 화면 위치는 저장하지 않는다.

재접속 시 현재 Observer Context로 Projection을 다시 생성한다.

Rollback은 해당 Branch의 Knowledge·Discovery·Fog·식별 상태를 함께 복원한다.

일반 Hover History는 복원 대상이 아니다.

## 19. 성능과 무효화

관찰자와 모든 Entity를 매 프레임 완전 비교하지 않는다.

무효화 원인:

- Observer 또는 대상 이동
- 문·벽·가림 상태 변경
- 조명 Field 변경
- Sense Capability 변경
- Stealth Evidence 변경
- Fog Audience 변경
- Knowledge Record 변경

Spatial Index와 Perception Invalidation Index를 사용해 영향 관계만 재평가한다.

Hover는 이미 Client-safe Candidate Projection에 대해 동작하며, 숨은 대상 탐색을 위한 별도 서버 스캔 API를 제공하지 않는다.

## 20. 역할 경계

### PLAYER_ONLY

- 공개 Candidate Hover
- Search·Study·Hide 선언
- 허용된 Knowledge 공유 요청
- 공개 정보 Inspection

### DM_ONLY

- 수동 Fog 편집
- 숨은 Entity와 실제 정보 확인
- Knowledge Scope 변경
- 비밀 DC와 Detection Evidence 확인
- 강제 발견·은폐·식별·미식별
- Player Projection Preview
- Journal Link Target 지정

### SHARED

- 허용된 공개 대상 Hover
- 공개된 발견 알림
- 공개 정보 Inspection

### SYSTEM_ONLY

- Sense 평가
- Perception Relation 계산
- Disclosure Evaluation
- Hover Information Projection 생성
- Client Projection 필터링
- Knowledge 저장·복구·Rollback

## 21. 금지 사항

- Visible, Detected와 Known을 하나의 Boolean으로 합치지 않는다.
- Hover 요청을 숨은 정보 조회 API로 사용하지 않는다.
- 실제 HP·AC·비밀 상태를 Player Client에 보내고 UI에서만 숨기지 않는다.
- Fog가 Actor Detection을 자동 대체하지 않는다.
- Roblox Lighting 픽셀 밝기를 규칙 권위로 사용하지 않는다.
- Workspace Instance를 Knowledge 또는 Perception의 저장 참조로 사용하지 않는다.
- 발견 전 함정·비밀문 Runtime Identity를 Player Projection에 포함하지 않는다.
