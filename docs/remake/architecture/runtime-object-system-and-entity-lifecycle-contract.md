# Runtime Object System과 Entity Lifecycle 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Runtime Object Registry 파티션 목표 크기
  - Lifecycle Batch의 기본 최대 Object 수
  - Tombstone과 Archive 장기 보존 개수·기간
  - Ownership Cascade의 기본 최대 깊이
  - Presentation Materialization 재시도 횟수와 실패 표시 시간
  - 활성 세션 Snapshot에서 허용할 Execution-scoped Object 최대 수
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0014`](../decisions/ADR-0014-character-data-and-scene-actor-separation.md)
  - [`ADR-0029`](../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`ADR-0042`](../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0057`](../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - [`Runtime Navigation 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`저장·세션 복구 모델`](persistence-and-session-recovery-model.md)
  - [`상태·지속 효과·집중 수명주기 모델`](../systems/rules/condition-ongoing-effect-duration-and-concentration-model.md)

## 1. 목적

Runtime Object System은 Scene 안에서 실제로 존재하며 선택, 공간 점유, 상호작용, 규칙 대상, 상태 변경 또는 Presentation 투영의 대상이 되는 존재를 하나의 공통 권위 계약으로 관리한다.

대상 예시:

- CharacterActor와 NPC Actor
- 문, 레버, 상자, 함정과 파괴 오브젝트
- 이동 가능한 바리케이드와 장면 장치
- 소환체와 생성된 장면 오브젝트
- 지속 영역, 오라와 공간 앵커
- 임시 장애물과 Runtime Quick Edit Object
- 규칙상 존재하는 투사체 또는 이동 중 효과 오브젝트

이 문서의 목적은 모든 데이터를 거대한 `Entity` 하나로 바꾸는 것이 아니다.

```text
Scene에 존재하는 권위 Presence
→ Runtime Object

캠페인 영구 원본과 규칙 기록
→ Character, ItemInstance, EffectInstance 등 각 도메인 원본
```

Runtime Object는 여러 시스템이 같은 존재를 서로 다른 ID와 임시 Roblox Instance로 추적하는 문제를 막는 공통 Scene Presence다.

## 2. 사용자 결과

내부 계약은 다음 결과를 보장하기 위해 존재한다.

- Actor, 문, 함정과 소환체가 선택·링크·저장·롤백에서 같은 참조 규칙을 사용한다.
- Scene을 다시 열거나 서버를 복구해도 같은 오브젝트를 안정적으로 식별한다.
- 삭제된 오브젝트를 가리키는 오래된 UI, Query Result와 비동기 작업이 새 오브젝트에 잘못 적용되지 않는다.
- Spawn 또는 Destroy 일부만 성공해 충돌체, 규칙 상태와 화면 모델이 서로 어긋나지 않는다.
- Presentation Model이 로드되지 않거나 깨져도 권위 상태가 사라지지 않는다.
- Chunk가 보이지 않는다는 이유만으로 서버의 Actor, 문과 효과가 삭제되지 않는다.
- DM은 Object ID, Component Store와 Incarnation을 직접 관리하지 않는다.
- 문제가 생기면 Object의 생성 출처, 소유 관계, Lifecycle Command와 마지막 상태를 추적할 수 있다.

## 3. Runtime Object의 경계

### 3.1 Runtime Object가 되는 것

다음 중 하나 이상을 충족하면 Runtime Object가 될 수 있다.

- Scene 안에서 독립된 권위 Transform 또는 공간 점유를 가짐
- Spatial Query, Navigation 또는 Perception의 개별 후보가 됨
- 직접 선택하거나 상호작용할 수 있음
- 다른 Object, Effect, Journal 또는 Trigger가 안정적으로 참조해야 함
- 독립된 Lifecycle과 공개 정책이 필요함
- 생성·비활성·아카이브·파괴를 명령으로 관리해야 함
- 권위 상태와 Presentation Projection을 연결해야 함

### 3.2 Runtime Object가 아닌 것

다음은 그 자체만으로 Runtime Object가 아니다.

- Character의 영구 성장·HP·인벤토리 원본
- 인벤토리 안에만 존재하는 ItemInstance
- Scene Presence를 만들지 않는 EffectInstance
- Compiled Navigation Polygon과 Spatial Index Node
- 정적인 벽 Geometry의 모든 조각
- Query Result와 Recipe Binding
- UI Panel, 선택 원, VFX, Camera와 Tween
- 저장용 Definition과 Content Pack 항목

필요하면 이 데이터가 Runtime Object에 바인딩된다.

```text
Character
→ CharacterBinding Component가 있는 Actor Runtime Object

EffectInstance
→ ownedObjectBindings로 Runtime Object 소유

ItemInstance
→ Scene에 떨어뜨릴 때 Item Presence Runtime Object 생성
```

### 3.3 모든 Scene Source Object가 Runtime Object는 아니다

정적인 바닥, 벽과 장식은 Layer Artifact와 Presentation Geometry만 생성할 수 있다.

```text
정적 바닥
→ Navigation Support와 Visual Artifact
→ Runtime Object 없음

파괴 가능한 벽
→ Navigation·Visibility Artifact
+ Runtime Object Blueprint
+ Durability·State Binding
```

Runtime Object가 필요하지 않은 정적 Geometry까지 Registry에 등록하지 않는다.

## 4. Identity 계약

### 4.1 ID 종류

```text
SceneObjectId
→ Scene Source의 저작 ID

RuntimeObjectBlueprintId
→ Compiled Build 안의 불변 Object Blueprint ID

RuntimeObjectId
→ 활성 권위 상태에서 Scene Presence를 식별하는 ID

RuntimeIncarnation
→ 같은 RuntimeObjectId가 Archive에서 Restore되어 다시 활성화된 세대

AuthorityEpoch
→ 서버 복구·Rollback Branch 전환 후 오래된 작업을 무효화하는 권위 세대
```

이 ID를 서로 대신 사용하지 않는다.

### 4.2 RuntimeObjectId

`RuntimeObjectId`는 캠페인 또는 활성 세션의 권위 범위 안에서 고유하고 한 번 발급되면 다른 Object에 재사용하지 않는다.

Scene Source에서 생성되는 지속 Object는 다음 의미를 가져야 한다.

```text
같은 sceneId
+ 같은 sourceSceneObjectId
+ 동일한 논리 Presence
→ Build가 바뀌어도 같은 RuntimeObjectId 유지 가능
```

구체적인 ID 문자열을 해시로 만들지 저장 Mapping으로 만들지는 구현 명세에서 정할 수 있다. 계약상 중요한 것은 논리적 안정성과 재사용 금지다.

Runtime 중 생성되는 Object는 서버가 새 불투명 ID를 발급한다.

클라이언트가 RuntimeObjectId를 생성하거나 최종 ID를 선택하지 않는다.

### 4.3 Domain ID와의 관계

기존 도메인 ID를 제거하지 않는다.

```text
ActorId
→ Actor Component가 있는 RuntimeObjectId의 타입 있는 별칭

CharacterId
→ 캠페인 Character 원본 ID

EffectInstanceId
→ 지속 규칙 효과 원본 ID

ItemInstanceId
→ 아이템 원본 ID

SceneObjectId
→ Authoring Source ID
```

`ActorId`는 Runtime Object의 Scene Presence를 가리키지만 `CharacterId`는 Scene 밖에서도 유지되는 영구 원본을 가리킨다.

### 4.4 RuntimeObjectRef

공개 Runtime 참조는 Roblox Instance와 문자열 경로가 아니라 타입 있는 참조를 사용한다.

```text
RuntimeObjectRef
├─ runtimeObjectId
├─ expectedIncarnation?
├─ authorityEpoch?
├─ expectedSceneId?
├─ expectedStateRevision?
└─ resolutionPolicy
```

`resolutionPolicy` 예시:

```text
active_only
active_or_suspended
allow_archived
include_tombstone
```

해결 결과:

```text
resolved
not_found
stale_incarnation
wrong_epoch
wrong_scene
suspended
archived
destroyed
not_disclosed
revision_conflict
```

빈 값이나 `nil` 하나로 모든 실패를 합치지 않는다.

## 5. Runtime Object Blueprint

Scene Compiler와 Runtime 생성 시스템은 공통 Blueprint 계약을 사용한다.

```text
RuntimeObjectBlueprint
├─ runtimeObjectBlueprintId
├─ blueprintSchemaVersion
├─ objectKind
├─ identityPolicy
├─ materializationPolicy
├─ componentBlueprintRefs[]
├─ initialStateSeedRef?
├─ lifecyclePolicyRef
├─ persistencePolicyRef
├─ ownershipPolicyRef?
├─ disclosurePolicyRef
├─ presentationDefinitionRef?
├─ migrationPolicyRef?
├─ sourceSceneObjectId?
├─ sourceLineage
└─ contentHash
```

### 5.1 Blueprint와 Live ID 분리

Compiled Build는 실제 활성 Object의 `RuntimeObjectId`를 저장하지 않는다.

Build는 다음만 제공한다.

- `RuntimeObjectBlueprintId`
- Scene Source Identity Seed
- Identity Policy
- 초기 Component Definition과 State Seed

Scene가 활성화되거나 Runtime Object가 Spawn될 때 Object Registry가 Live ID를 바인딩한다.

Scene Compiler 계약에 먼저 기록된 `CompiledSceneObjectBlueprint.runtimeObjectId`는 이 문서에서 **Blueprint Identity Seed 또는 RuntimeObjectBlueprintId**로 정정한다. Live RuntimeObjectId로 해석하지 않는다.

### 5.2 Identity Policy

초기 정책:

```text
stable_scene_presence
session_spawned
execution_spawned
derived_from_owner
custom_registered
```

- `stable_scene_presence`: Scene Source Object와 안정적으로 연결된다.
- `session_spawned`: 활성 세션 동안 고유 ID를 발급한다.
- `execution_spawned`: 특정 Action·Recipe 실행에서 생성된다.
- `derived_from_owner`: Owner 상태로부터 재구성되며 독립 저장을 최소화한다.

### 5.3 Materialization Policy

```text
none_static_artifact
logical_only
server_authority_object
client_presented_object
on_demand_presentation
custom_registered
```

Runtime Object가 있다고 반드시 Workspace Model을 즉시 생성하지 않는다.

## 6. Runtime Object Record

```text
RuntimeObjectRecord
├─ runtimeObjectId
├─ runtimeIncarnation
├─ objectKind
├─ sceneId
├─ buildId
├─ runtimeObjectBlueprintId
├─ lifecycleState
├─ suspensionRecords[]
├─ componentManifestRef
├─ authoritativeStateRefs[]
├─ domainIdentityBindings[]
├─ ownershipEdgeRefs[]
├─ linkEdgeRefs[]
├─ disclosurePolicyRef
├─ persistencePolicyRef
├─ sourceLineage
├─ createdRevision
├─ lastChangedRevision
├─ archivedRecordRef?
├─ tombstoneRef?
└─ recordHash
```

Registry Record는 모든 Component State를 거대한 Table에 복사하지 않는다.

각 도메인 Store가 자신의 상태를 소유하고 Object Record는 타입 있는 Component와 State Ref를 가진다.

## 7. Composition 기반 Component 모델

Runtime Object의 동작은 긴 상속 계층이나 `objectKind` 이름 분기로 결정하지 않는다.

```text
Runtime Object
= Identity
+ Lifecycle
+ 등록된 Component 조합
```

`objectKind`는 진단, 기본 UI와 기본 정책 선택을 돕는 분류이며 전용 코드 분기의 유일한 근거가 아니다.

### 7.1 초기 Core Component 종류

```text
SpatialPresenceComponent
TransformComponent
ActorBindingComponent
CharacterBindingComponent
PerceivableComponent
InteractionComponent
StateMachineComponent
RuleTargetComponent
TriggerComponent
DurabilityComponent
InventoryContainerComponent
OwnershipComponent
ControlComponent
LinkComponent
PersistenceComponent
DisclosureComponent
PresentationBindingComponent
CustomRegisteredComponent
```

모든 Object가 모든 Component를 가지지 않는다.

예시:

```text
닫힌 문
├─ SpatialPresence
├─ Interaction
├─ StateMachine
├─ Durability?
├─ Perceivable
├─ Link
├─ Disclosure
└─ PresentationBinding
```

```text
CharacterActor
├─ SpatialPresence
├─ ActorBinding
├─ CharacterBinding
├─ Perceivable
├─ RuleTarget
├─ Control
├─ Disclosure
└─ PresentationBinding
```

### 7.2 Component Registry

```text
RuntimeComponentDefinition
├─ componentTypeId
├─ schemaVersion
├─ blueprintSchema
├─ stateSchema
├─ dependencies[]
├─ lifecycleParticipation
├─ queryCapabilities[]
├─ commandCapabilities[]
├─ snapshotPolicy
├─ disclosurePolicy
├─ migrationAdapters[]
└─ diagnosticsPolicy
```

순환 필수 의존성을 허용하지 않는다.

Component는 다른 Component Store의 내부 Table을 직접 수정하지 않는다. Query, Command, typed Event와 공개 Service 계약을 사용한다.

### 7.3 Component 변경

활성 Object의 Component 추가·제거·교체는 일반 Table 수정이 아니다.

```text
ReconfigureRuntimeObjectCommand
→ Blueprint 또는 승인된 Reconfiguration Plan 검증
→ 새 Component Set 구성
→ Cross-component Validation
→ Registry와 Index 원자적 교체
```

변신, 탈것 탑승과 파괴 단계처럼 Component 구성이 바뀌는 기능은 이 경로를 사용하거나 기존 Component의 상태 전환으로 표현한다.

## 8. 권위 Lifecycle 상태

외부에 공개되는 기본 상태:

```text
active
suspended
archived
destroyed
```

명령 처리 중의 `staging`, `validating`, `committing`, `cleanup_pending`은 Transaction 내부 상태이며 정상 Runtime Snapshot에 부분 Object로 공개하지 않는다.

### 8.1 허용 전이

```text
Spawn Transaction
→ active 또는 suspended

active
↔ suspended

active 또는 suspended
→ archived

archived
→ active 또는 suspended

active 또는 suspended 또는 archived
→ destroyed

destroyed
→ 전이 없음
```

Rollback은 현재 Branch에서 `destroyed → active` Command를 실행하는 것이 아니다. 과거 Snapshot을 기반으로 새 Authority Epoch·Branch를 활성화하는 복구다.

### 8.2 Active

- 활성 Query와 Domain Index에 참여한다.
- 허용된 Interaction, Trigger와 Rule Capability를 제공한다.
- 공개 정책에 따라 Client View에 포함될 수 있다.
- Spatial Presence가 있다면 점유와 경계 판정에 참여한다.

### 8.3 Suspended

Object의 권위 State는 보존하지만 일부 또는 전체 Runtime 참여를 중단한다.

사용 예:

- 아직 전투에 등장하지 않은 숨겨진 증원
- Scene 안에 보존된 비활성 장치
- 규칙상 잠시 세계 참여가 정지된 Object
- 복구 또는 안전한 Reconfiguration을 기다리는 Object

Streaming, 화면 밖 상태와 Client Model 미생성은 Suspension이 아니다.

### 8.4 Archived

Object를 활성 Scene Runtime에서 제거하지만 복구 가능한 권위 State와 Identity를 보존한다.

- 활성 Spatial·Interaction·Trigger Index에서 제외
- Presentation Projection 제거 가능
- 저장, 감사, DM 복원과 소유 관계에 필요한 State 보존
- RuntimeObjectId 유지

### 8.5 Destroyed

현재 Authority Branch에서 Object가 종료된 터미널 상태다.

- 활성·Archive Registry에서 제거
- Tombstone 보존
- RuntimeObjectId 재사용 금지
- 소유 Object Cleanup 정책 실행
- 강한 Link 무효화 또는 구조화된 정리

일반 `RestoreObjectCommand`로 Destroyed Object를 되살리지 않는다. 같은 Blueprint에서 새 Object를 만들면 새 RuntimeObjectId를 사용한다.

## 9. Suspension Source 계약

하나의 Boolean `disabled`를 사용하지 않는다.

```text
RuntimeObjectSuspensionRecord
├─ suspensionId
├─ sourceKind
├─ sourceRef
├─ reasonCode
├─ affectedCapabilities[]
├─ createdRevision
└─ removalPolicy
```

여러 시스템이 동시에 Suspension을 걸 수 있다.

```text
hidden_reserve
+ scene_pause
+ dm_hold
```

한 Source가 해제되어도 다른 Suspension이 남아 있으면 Object를 활성화하지 않는다.

Effect의 `Suppressed` 상태와 Runtime Object Lifecycle Suspension을 구분한다.

- Effect Suppression: 특정 규칙 기여를 억제
- Object Suspension: Scene Presence의 Runtime 참여를 중단

## 10. Spawn 계약

```text
SpawnRuntimeObjectCommand
├─ commandId
├─ idempotencyKey
├─ blueprintRef
├─ spawnReason
├─ sceneId
├─ placementProposal?
├─ ownerRef?
├─ persistentBindingRefs[]
├─ initialOverrides[]
├─ disclosureContext
├─ expectedAuthorityRevision
└─ requestedBy
```

처리 흐름:

```text
1. Blueprint와 Provider Version 확인
2. 요청자 권한과 Spawn 정책 검증
3. Scene Build와 Source Dependency 확인
4. 목적지·점유·공개 정책 검증
5. RuntimeObjectId와 Incarnation 예약
6. Component State를 Transaction 내부에서 구성
7. Ownership·Link와 Domain Binding 검증
8. Spatial·Interaction·Rule Index 변경 준비
9. CommitGroup으로 Registry·State·Index 원자적 반영
10. ObjectSpawned Event 공개
11. Presentation Materialization 요청
```

Workspace Model을 먼저 생성한 뒤 성공한 것으로 취급하지 않는다.

Spawn 실패 시:

- 부분 Component State를 공개하지 않는다.
- Spatial Index에 잔여 항목을 남기지 않는다.
- Presentation Model을 권위 Object처럼 남기지 않는다.
- 같은 idempotencyKey 재시도는 같은 성공 결과 또는 같은 확정 실패를 반환한다.
- 예약되었다가 폐기된 ID는 다른 Object에 재사용하지 않을 수 있다.

### 10.1 Batch Spawn

소환 여러 개, 전투 배치와 Scene 활성화는 Batch를 사용할 수 있다.

```text
SpawnBatchPolicy
├─ atomic_all
├─ bounded_partial_with_explicit_results
└─ custom_registered
```

기본 권위 규칙은 `atomic_all`이다. 부분 성공을 허용하려면 콘텐츠가 각 Object의 독립성을 명시하고 결과를 개별 기록한다.

## 11. Activate와 Suspend

Lifecycle 변경은 Command로만 수행한다.

```text
SuspendRuntimeObjectCommand
ResumeRuntimeObjectCommand
```

Suspend 시:

- Suspension Record 추가
- 해당 Capability와 Index 참여 변경
- 진행 중 Movement, Interaction, Targeting과 Trigger Job에 취소·정지 신호
- Component별 안전 정리
- Presentation 상태 변경 Event

Resume 시:

- 지정한 Suspension Record만 제거
- 남은 Suspension 확인
- Spatial Occupancy와 현재 Build 재검증
- 필요한 Index 재등록
- 실패하면 Suspended 상태 유지

Resume가 다른 Object와 겹치거나 현재 위치가 무효하면 자동으로 임의 위치로 이동시키지 않는다. 명시적 Placement Resolution 또는 DM 선택을 요구한다.

## 12. Archive, Restore와 Destroy

### 12.1 Archive

```text
ArchiveRuntimeObjectCommand
├─ runtimeObjectRef
├─ archiveReason
├─ preserveRelationsPolicy
├─ expectedRevision
└─ requestedBy
```

Archive는 다음을 원자적으로 처리한다.

- 활성 실행 취소 또는 안전 경계 대기
- Spatial·Interaction·Trigger Index 제거
- Archive Snapshot 생성
- Owner와 Link 정책 적용
- Presentation Projection 제거 요청
- Lifecycle 변경 Event 기록

### 12.2 Restore

```text
RestoreArchivedRuntimeObjectCommand
├─ runtimeObjectId
├─ expectedArchiveRevision
├─ targetSceneId
├─ placementProposal?
├─ resumePolicy
└─ requestedBy
```

Restore 성공 시:

- 같은 RuntimeObjectId 유지
- RuntimeIncarnation 증가
- 현재 Scene Build와 Component Schema로 Migration
- 공간·권한·소유 관계 재검증
- 새 RuntimeObjectRef 공개

오래된 Incarnation을 가진 비동기 작업과 UI 참조는 자동으로 실패한다.

### 12.3 Destroy

```text
DestroyRuntimeObjectCommand
├─ runtimeObjectRef
├─ destroyReason
├─ cleanupPolicyOverride?
├─ expectedRevision
└─ requestedBy
```

Destroy는 단순 `Model:Destroy()`가 아니다.

```text
진행 중 실행 정리
→ Owned Object Cleanup Plan
→ Link 무효화·대체
→ Component State 종료
→ Registry와 Index 제거
→ Tombstone 기록
→ ObjectDestroyed Event
→ Presentation Projection 제거
```

규칙상 파괴와 화면 Model 제거를 분리한다.

## 13. Tombstone

```text
RuntimeObjectTombstone
├─ runtimeObjectId
├─ lastIncarnation
├─ objectKind
├─ sourceLineage
├─ destroyedRevision
├─ destroyedBy
├─ destroyReason
├─ replacementObjectId?
├─ finalStateSummaryRef?
├─ ownershipCleanupSummary
└─ integrityHash
```

Tombstone은 다음을 위해 유지한다.

- 오래된 참조의 정확한 실패 이유
- 명령 멱등성
- 복구와 Rollback 감사
- Journal과 로그 링크
- ID 재사용 방지

장기 보존과 압축 정책은 Persistence 문서와 구현 명세가 정한다.

## 14. Ownership과 Link Graph

### 14.1 Ownership은 Gameplay Owner와 다르다

```text
Runtime Ownership
→ 생성·정리 수명주기 관계

Character Ownership
→ 캐릭터 영구 소유자

Control Assignment
→ 현재 명령 가능 사용자

Item Ownership
→ 인벤토리 소유 관계
```

이 네 관계를 하나의 `ownerId`로 합치지 않는다.

### 14.2 Ownership Edge

```text
RuntimeOwnershipEdge
├─ ownershipEdgeId
├─ ownerRuntimeObjectId?
├─ ownerEffectInstanceId?
├─ childRuntimeObjectId
├─ ownershipKind
├─ cleanupPolicy
├─ transferPolicy
├─ createdRevision
└─ sourceExecutionId?
```

`cleanupPolicy`:

```text
destroy_with_owner
archive_with_owner
detach_on_owner_end
transfer_to_parent
end_by_rule_recipe
custom_registered
```

Ownership Graph의 강한 Cleanup Edge는 순환할 수 없다. 순환이 감지되면 Spawn 또는 Link 변경을 거부한다.

### 14.3 일반 Link

레버와 문, Journal과 Object, Trigger와 대상 같은 연결은 Ownership이 아니다.

```text
RuntimeObjectLink
├─ linkId
├─ sourceRef
├─ targetRef
├─ linkTypeId
├─ strength
├─ invalidationPolicy
├─ disclosurePolicyRef
└─ revision
```

`strength`:

```text
strong_required
weak_optional
historical
```

Target이 Destroyed일 때 Link 정책에 따라 Command 거부, Link 제거, 대체 Object 연결 또는 Historical Link 보존을 수행한다.

## 15. Scene Transfer

Runtime Object는 Scene Presence이므로 일반적으로 같은 Object Record의 `sceneId`만 바꾸지 않는다.

```text
SceneTransferTransaction
├─ persistentDomainBinding
├─ sourceRuntimeObjectRef
├─ targetSceneId
├─ targetEntryAnchor
├─ transferCorrelationId
└─ transferPolicy
```

기본 흐름:

```text
대상 Scene Build와 Placement 준비
→ 대상 Scene에 새 Runtime Object·Actor Presence Spawn
→ persistent Character·NPC·Item Binding 연결
→ 대상 준비 성공
→ 원본 Scene Presence Archive 또는 종료
→ Scene Transition Commit
```

대상 Presence는 새 RuntimeObjectId를 가진다.

Character는 같은 `characterId`를 유지하지만 새 `ActorId`를 받는다. 이는 캐릭터 원본과 Scene CharacterActor를 분리한 ADR-0014를 따른다.

Source와 Target을 추적하기 위해 다음을 남길 수 있다.

```text
predecessorRuntimeObjectId
successorRuntimeObjectId
transferCorrelationId
```

Scene 두 곳에 같은 Scene Presence가 동시에 활성화되지 않게 한다.

## 16. Lifecycle Command 공통 Envelope

모든 Lifecycle 변경 Command는 공통 필드를 가진다.

```text
RuntimeObjectLifecycleCommand
├─ commandId
├─ commandTypeId
├─ idempotencyKey
├─ targetRuntimeObjectRef?
├─ expectedAuthorityRevision
├─ expectedObjectRevision?
├─ sourceUserId?
├─ sourceActorId?
├─ sourceExecutionId?
├─ authorityContext
├─ requestedAt
└─ payload
```

검증 순서:

```text
Command Schema
→ Authority Epoch
→ idempotencyKey
→ 대상 Ref와 Incarnation
→ Lifecycle 전이 허용 여부
→ 제어권·권한·공개 정책
→ Component별 Precondition
→ 공간·소유·Link 제약
→ Transaction 구성
→ Commit
```

Lifecycle Command Handler가 Workspace를 직접 탐색해 Object 존재 여부를 결정하지 않는다.

## 17. Registry와 Store 책임

### 17.1 RuntimeObjectRegistry

Registry가 소유하는 것:

- RuntimeObjectId와 Incarnation
- Lifecycle 상태
- Component Manifest
- Domain ID Binding
- Scene·Build Binding
- Ownership·Link Entry Point
- Tombstone Locator
- Object Revision

Registry가 소유하지 않는 것:

- 모든 Actor 스탯
- 모든 Interaction State
- 모든 Effect 데이터
- 모든 Spatial Geometry
- Presentation Model 계층

### 17.2 Specialized Store

```text
ActorRuntimeStore
SpatialPresenceStore
InteractionStateStore
RuntimeRuleObjectStore
DurabilityStore
OwnershipGraphStore
LinkGraphStore
ArchiveStore
TombstoneStore
```

각 Store는 Stable ID와 revision을 사용한다.

하나의 거대한 `RuntimeObjectManager`가 모든 상태와 규칙을 직접 소유하지 않는다.

### 17.3 Index 참여

Lifecycle과 Component 변경은 다음 Index를 증분 갱신할 수 있다.

- Spatial Candidate Index
- Occupancy Index
- Perception Candidate Index
- Interaction Index
- Trigger Boundary Index
- Rule Target Index
- Control Assignment Index
- Disclosure Directory

Index 변경은 같은 CommitGroup에 포함하거나 새 Snapshot 공개 전에 완료한다.

## 18. Query와 Runtime Object

Spatial Query는 RuntimeObjectRegistry 전체를 선형 순회하지 않는다.

```text
Spatial Index 후보
→ RuntimeObjectId
→ Lifecycle·Disclosure 필터
→ 필요한 Component State Resolve
→ 결정적 정렬
```

기본 Query는 `active` Object만 포함한다.

Suspended, Archived와 Destroyed Object가 필요하면 Query Type이 명시적으로 허용해야 한다.

Query Result는 RuntimeObjectRef와 공간 증거를 반환하며 Roblox Instance를 반환하지 않는다.

## 19. Persistence Class

```text
RuntimeObjectPersistencePolicy
├─ persistenceClass
├─ snapshotPolicy
├─ journalPolicy
├─ archivePolicy
├─ recoveryPolicy
└─ cleanupAtSafeBoundary
```

초기 `persistenceClass`:

```text
scene_persistent
session_persistent
execution_scoped
derived_runtime
```

### scene_persistent

Scene를 닫고 다시 열어도 상태를 유지한다.

예:

- 문, 상자, 파괴 오브젝트
- Scene에 남은 NPC 또는 배치 Object

### session_persistent

활성 세션 재접속과 서버 복구에는 포함하지만 장기 캠페인 저장 전에 정책에 따라 정리할 수 있다.

예:

- 일시적으로 배치한 지원 장치
- 세션 동안 유지되는 소환체

### execution_scoped

Action 또는 Recipe 실행 안에서만 존재한다.

안전 Snapshot 전에 완료·전환·정리되어야 한다.

예:

- 순간적인 규칙 투사체
- 이동 중 충돌 판정을 위한 권위 Object

### derived_runtime

Owner 또는 Effect State에서 재구성할 수 있어 독립 원본으로 저장하지 않는다.

복구 시 같은 RuntimeObjectId와 State를 재현할 수 있는 결정적 Rebuild 계약이 필요하다.

## 20. Snapshot, Recovery와 Rollback

권위 Snapshot은 다음을 포함한다.

```text
Runtime Object Directory
+ Object Lifecycle States
+ Incarnation
+ Component State Manifest
+ Ownership·Link Graph
+ Archive Record
+ 필요한 Tombstone 범위
```

### 20.1 서버 복구

서버 복구 시:

- Snapshot과 Journal로 Registry를 복원한다.
- RuntimeObjectId와 Incarnation을 보존한다.
- 새 AuthorityEpoch를 발급한다.
- Index와 Presentation은 권위 State에서 재구성한다.
- 복구 전 Client Request와 비동기 작업은 Epoch 불일치로 거부한다.

### 20.2 DM Rollback

Rollback은 과거 Object Directory와 Component State를 새 Branch에 복원한다.

- 과거에 존재한 Object는 해당 ID로 복원될 수 있다.
- 이후 생성된 Object는 새 Branch에서 존재하지 않는다.
- 이후 Destroyed된 Object는 과거 상태로 돌아올 수 있다.
- AuthorityEpoch 또는 BranchId가 바뀌므로 현재 Timeline의 오래된 Ref와 Job은 재사용할 수 없다.

Rollback을 일반 Restore 또는 Spawn Command 여러 개로 흉내 내지 않는다.

## 21. Build 교체와 Object Rebinding

구조적 Live Patch 또는 새 Build 활성화 시 Scene Source Identity를 기준으로 Runtime Object를 Rebind한다.

```text
기존 sourceSceneObjectId
+ 새 Build의 같은 Source Identity
→ Blueprint 호환성 검사
```

결과:

```text
compatible_rebind
→ RuntimeObjectId와 State 유지
→ Blueprint·Build Binding 갱신

migration_required
→ Component Migration Transaction
→ 성공 시 Incarnation 증가 가능

source_removed
→ Archive 또는 Destroy 정책 적용

new_source
→ 새 Stable Scene Presence Spawn

ambiguous_identity
→ Patch 중단과 DM 진단
```

Layer 일부만 새 Build로 바꾸지 않는다. Object Rebind와 Build Pointer 교체는 같은 Live Patch Transaction의 안전 경계에서 이루어진다.

## 22. Presentation Materialization

권위 Lifecycle과 Workspace Presentation Lifecycle을 분리한다.

```text
Authority Object State
→ active

Client Presentation State
→ not_requested | loading | ready | evicted | failed
```

Client Model이 `evicted` 또는 `failed`여도 서버 Object는 Active일 수 있다.

```text
PresentationBinding
├─ runtimeObjectRef
├─ presentationDefinitionRef
├─ presentationGeneration
├─ currentProjectionState
├─ lastAppliedAuthorityRevision
└─ failureStatus?
```

Presentation Adapter는:

- Workspace Model을 생성·재생성할 수 있음
- Object State를 표시할 수 있음
- 권위 상태를 직접 변경할 수 없음
- Model 존재 여부로 Object 생존을 판단할 수 없음

Presentation 오류는 복구 가능한 진단으로 처리한다.

## 23. Streaming과 Client Disclosure

Streaming은 권위 Object Lifecycle을 변경하지 않는다.

Client는 권한과 관심 영역에 따라 Object Directory의 일부 View만 받는다.

```text
Server Raw Runtime Object
→ Disclosure Policy
→ Perception·Permission Filter
→ Client Runtime Object View
→ Presentation Materialization
```

숨겨진 함정과 비밀문은 일반 Client Directory에 실제 RuntimeObjectId와 정확한 위치를 미리 전달하지 않는다.

Chunk가 언로드되어도 서버의 Object, Trigger, Ownership과 Dynamic State는 유지된다. 서버 측 권위 Chunk 관리가 필요하면 Object Directory와 Cross-chunk Ref를 보존한 채 내부 Artifact만 Evict한다.

정확한 Client Ready·Streaming 순서는 후속 Streaming 계약이 소유한다.

## 24. Failure, 동시성과 멱등성

### 24.1 동일 Object 동시 Command

Object별 Revision과 Command Sequence를 사용한다.

- 같은 expectedRevision의 충돌 Command 둘을 모두 적용하지 않는다.
- 하나가 Commit되면 다른 하나는 `OBJECT_REVISION_CONFLICT`를 받는다.
- DM 강제 Command도 감사 로그와 명시적 Override Policy를 사용한다.

### 24.2 Lifecycle 중 진행 중 실행

Destroy, Archive와 Suspend 전에 다음을 확인한다.

- 이동 실행
- Interaction Transition
- 열린 Timing Window
- Targeting Session
- Owner Effect Cleanup
- Scene Transfer
- 저장 Snapshot 캡처

정책에 따라 즉시 취소, 안전 Checkpoint 대기, Command 거부 중 하나를 사용한다.

### 24.3 Component 실패

권위 Component 준비가 하나라도 실패하면 Lifecycle Transaction을 Commit하지 않는다.

Presentation Cleanup 실패는 권위 Destroy를 되돌리지 않고 별도 재시도 Queue로 격리할 수 있다.

### 24.4 구조화된 오류

초기 오류 예시:

```text
RUNTIME_OBJECT_NOT_FOUND
RUNTIME_OBJECT_STALE_INCARCATION
RUNTIME_OBJECT_WRONG_EPOCH
RUNTIME_OBJECT_WRONG_SCENE
RUNTIME_OBJECT_NOT_ACTIVE
RUNTIME_OBJECT_DESTROYED
LIFECYCLE_TRANSITION_NOT_ALLOWED
SPAWN_BLUEPRINT_NOT_FOUND
SPAWN_PLACEMENT_INVALID
COMPONENT_DEPENDENCY_MISSING
COMPONENT_MIGRATION_FAILED
OWNERSHIP_CYCLE_DETECTED
STRONG_LINK_TARGET_MISSING
ARCHIVE_RECORD_NOT_FOUND
RESTORE_OCCUPANCY_INVALID
OBJECT_REVISION_CONFLICT
PRESENTATION_MATERIALIZATION_FAILED
```

`STALE_INCARCATION`의 최종 철자는 구현 명세에서 `STALE_INCARNATION`으로 정규화한다.

## 25. Event 계약

Lifecycle Event는 Commit 이후에만 발행한다.

```text
RuntimeObjectSpawned
RuntimeObjectSuspensionChanged
RuntimeObjectArchived
RuntimeObjectRestored
RuntimeObjectDestroyed
RuntimeObjectReconfigured
RuntimeObjectReboundToBuild
RuntimeObjectLinkChanged
RuntimeObjectOwnershipChanged
```

공통 필드:

```text
RuntimeObjectLifecycleEvent
├─ eventId
├─ eventTypeId
├─ runtimeObjectId
├─ runtimeIncarnation
├─ authorityEpoch
├─ revisionBefore
├─ revisionAfter
├─ commandId
├─ reasonCode
├─ affectedComponentTypeIds[]
└─ disclosurePolicyRef
```

Event Handler가 원래 Transaction을 다시 실행하지 않도록 idempotency와 Event Sequence를 가진다.

## 26. 진단과 Trace

Object 진단 화면은 최소한 다음을 제공할 수 있어야 한다.

- RuntimeObjectId, Incarnation과 Lifecycle State
- Source Scene Object와 Blueprint
- Domain Identity Binding
- Component 목록과 각 Revision
- Suspension Source
- Owner·Child와 Link
- 마지막 Lifecycle Command
- 현재 Scene Build와 Dynamic State Revision
- Spatial·Interaction·Perception Index 참여 여부
- Client Presentation 상태
- Archive 또는 Tombstone 정보

DM에게는 내부 ID보다 다음을 우선 표시한다.

```text
문이 현재 복원되지 않았습니다.
이유: 복원 위치가 다른 오브젝트와 겹칩니다.
선택: 가까운 유효 위치 / 원래 위치 비우기 / 복원 취소
```

## 27. 성능 원칙

- 정적 Geometry를 모두 Runtime Object로 만들지 않는다.
- Object마다 독립 Heartbeat와 무한 Loop를 두지 않는다.
- Lifecycle과 Component 변경은 Event와 Command 기반으로 처리한다.
- Active Object만 기본 Spatial·Interaction Index에 둔다.
- Sparse Component Store를 사용해 없는 Component용 빈 State를 만들지 않는다.
- Spawn·Archive·Destroy Batch는 한 프레임에 무제한 실행하지 않는다.
- Tombstone과 Historical Link는 복구 범위를 보존한 뒤 압축할 수 있다.
- Presentation Model 생성 비용은 권위 Transaction과 분리해 분산할 수 있다.
- Registry와 Index 손상 시 Source·Snapshot에서 재구성할 수 있어야 한다.

## 28. 보안 원칙

- Client가 보낸 RuntimeObjectId는 존재 여부만으로 신뢰하지 않는다.
- Controller, Disclosure, Perception과 Command Capability를 다시 검증한다.
- 숨겨진 Object를 `NOT_FOUND`와 다른 상세 오류로 노출할지 Disclosure Policy가 결정한다.
- Roblox Instance, ObjectValue와 Workspace 경로를 Remote Payload에 넣지 않는다.
- Client는 Lifecycle State, Incarnation과 Component Set을 직접 지정하지 않는다.
- Runtime Object Blueprint Provider가 임의 Script, Remote와 실행 코드를 반환하지 못하게 한다.

## 29. 다른 문서와의 권위 경계

- Character 영구 상태: Character 도메인 문서
- Scene Presence Identity와 Lifecycle: 이 문서
- EffectInstance 지속시간·집중·종료: Effect Lifecycle 문서
- Effect가 소유한 Scene Object 정리: 이 문서의 Ownership 계약
- Scene Source와 Blueprint Build: Scene Compiler 문서
- 공간 후보·점유·시야 증거: Spatial Query 문서
- 경로 계획과 이동 실행: Runtime Navigation 문서
- 저장, Journal과 서버 복구: Persistence 문서
- 실제 UI와 Model Tween: Presentation·Interaction 문서

## 30. 확정 사항

1. Runtime Object는 Scene Presence의 공통 Identity와 Lifecycle 계약이다.
2. Character, ItemInstance와 순수 EffectInstance를 억지로 Runtime Object로 만들지 않는다.
3. RuntimeObjectId는 재사용하지 않고 Incarnation과 AuthorityEpoch로 오래된 참조를 차단한다.
4. Compiled Build는 Live RuntimeObjectId가 아니라 Blueprint와 Identity Seed를 제공한다.
5. Object 동작은 상속 계층보다 등록된 Component 조합으로 구성한다.
6. Lifecycle 변경은 서버 권위 Command와 원자적 CommitGroup으로만 수행한다.
7. Suspension Source를 누적하며 Streaming과 Presentation 상태를 Lifecycle과 분리한다.
8. Archived Object만 일반 Restore할 수 있고 Destroyed는 현재 Branch에서 터미널이다.
9. Scene Transfer는 Persistent Domain Identity를 유지하면서 새 Scene Presence를 생성한다.
10. Ownership Cleanup, Link 무효화, Index 갱신과 Tombstone을 Lifecycle Transaction에 포함한다.
11. Workspace Model은 Runtime Object의 권위 원본이 아니다.
12. Static Layer Artifact는 필요한 경우에만 Runtime Object Blueprint를 만든다.

## 31. 후속 구현 명세

다음 수직 명세로 분리한다.

1. RuntimeObjectRegistry와 RuntimeObjectRef Resolution
2. Blueprint Instantiation과 Atomic Spawn
3. Suspension·Archive·Restore·Destroy Lifecycle Command
4. Ownership·Link Graph와 Cascade Cleanup
5. Scene Build Rebind와 Live Patch Migration
6. Snapshot·Recovery·Rollback Object Directory
7. Client Disclosure Directory와 Presentation Materialization

각 명세는 실제 저장소 구조 조사 후 `docs/remake/specs/`에 작성한다.
