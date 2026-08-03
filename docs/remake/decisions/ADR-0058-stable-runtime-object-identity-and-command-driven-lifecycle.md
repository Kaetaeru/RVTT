# ADR-0058. Stable Runtime Object Identity와 Command 기반 Lifecycle

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: Scene Presence Identity, Runtime Component, Spawn·Suspend·Archive·Restore·Destroy, 소유 관계와 Presentation Materialization
- 관련 문서:
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`저장·세션 복구 모델`](../architecture/persistence-and-session-recovery-model.md)
  - [`ADR-0014`](ADR-0014-character-data-and-scene-actor-separation.md)
  - [`ADR-0029`](ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md)
  - [`ADR-0057`](ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)

## 배경

RVTT의 Scene에는 Actor, 문, 레버, 상자, 함정, 소환체, 지속 영역과 임시 장애물처럼 서로 다른 존재가 함께 있다.

각 시스템이 이들을 별도 임시 ID, Roblox Model과 Manager로 관리하면 다음 문제가 생긴다.

- Actor, 문과 효과 오브젝트의 참조·삭제·복구 규칙이 서로 다름
- Workspace Model이 사라지면 권위 Object도 사라진 것으로 오인함
- Spawn 일부만 성공해 규칙 State와 Presentation이 어긋남
- 삭제된 Object를 가리키던 비동기 작업이 새 Object에 잘못 적용됨
- Scene Build 교체 시 Dynamic State를 어떤 Object에 다시 연결할지 불명확함
- 소환체와 지속 영역의 Owner가 끝났는데 Child Object가 남음
- Chunk Streaming과 실제 Object 비활성화를 혼동함
- Rollback에서 파괴된 문과 생성된 Actor의 Identity를 재현하기 어려움

반대로 Character, ItemInstance, EffectInstance와 모든 정적 Geometry까지 하나의 범용 Entity로 강제하면 영구 원본, Scene Presence와 규칙 기록의 책임이 섞이고 Object 수가 불필요하게 증가한다.

## 결정

### 1. Runtime Object는 Scene Presence만 표현한다

Scene 안에서 독립된 Identity, Lifecycle, 공간 점유, 상호작용, 규칙 대상 또는 Presentation 투영이 필요한 존재를 Runtime Object로 관리한다.

Character 영구 원본, 인벤토리 안 ItemInstance, Scene Presence가 없는 EffectInstance, 정적 Polygon과 UI는 그 자체로 Runtime Object가 아니다.

이들은 필요한 Runtime Object에 타입 있는 Binding으로 연결한다.

### 2. RuntimeObjectId는 안정적이고 재사용하지 않는다

RuntimeObjectId는 권위 범위에서 고유하며 다른 Object에 재사용하지 않는다.

Scene Source 기반 Object는 같은 Source Identity와 논리 Presence가 유지되는 동안 Build가 바뀌어도 Identity를 유지할 수 있다.

Runtime에서 생성되는 Object ID는 서버가 발급한다. Client가 최종 ID를 생성하거나 선택하지 않는다.

### 3. RuntimeIncarnation과 AuthorityEpoch로 오래된 참조를 차단한다

Archived Object를 Restore하면 같은 RuntimeObjectId를 유지하되 RuntimeIncarnation을 증가시킨다.

서버 복구 또는 Rollback Branch 전환 시 AuthorityEpoch를 변경한다.

RuntimeObjectRef는 필요에 따라 Object ID, Incarnation, Epoch, Scene과 Revision을 포함하며 오래된 작업은 구조화된 실패를 받는다.

### 4. Scene Compiler는 Blueprint를 만들고 Live ID를 만들지 않는다

Compiled Build는 `RuntimeObjectBlueprintId`, Identity Policy, Component Blueprint와 초기 State Seed를 제공한다.

실제 RuntimeObjectId는 Scene 활성화 또는 Spawn Transaction에서 Object Registry가 바인딩한다.

Scene Compiler 계약의 초기 최소 예시에 있던 `CompiledSceneObjectBlueprint.runtimeObjectId`는 Live ID가 아니라 Blueprint Identity Seed 또는 RuntimeObjectBlueprintId로 해석한다.

### 5. Runtime Object는 Component 조합으로 구성한다

Object 동작은 긴 클래스 상속과 Object 이름별 분기로 만들지 않는다.

```text
Runtime Object
= Identity
+ Lifecycle
+ 등록된 Component Set
```

Actor, Spatial Presence, Interaction, State Machine, Durability, Perception, Trigger, Control, Ownership, Link, Persistence와 Presentation을 독립 Component 계약으로 구성한다.

ObjectKind는 진단과 기본 UI 분류이며 전용 동작의 유일한 분기 키가 아니다.

### 6. Lifecycle 변경은 서버 Command와 원자적 Transaction으로만 수행한다

Spawn, Suspend, Resume, Archive, Restore, Destroy와 Reconfigure는 서버 권위 Command를 사용한다.

Registry, Component State, Ownership·Link, Spatial·Interaction·Rule Index와 Tombstone 변경은 한 CommitGroup에서 일관되게 반영한다.

Workspace Model 생성·삭제를 Lifecycle Commit으로 취급하지 않는다.

### 7. 공개 Lifecycle은 Active, Suspended, Archived, Destroyed다

```text
active ↔ suspended
active 또는 suspended → archived
archived → active 또는 suspended
active 또는 suspended 또는 archived → destroyed
```

Destroyed는 현재 Authority Branch에서 터미널이며 ID를 재사용하지 않는다.

일반 Restore는 Archived Object에만 사용한다. Rollback은 과거 Snapshot을 새 Authority Epoch·Branch로 활성화하는 별도 복구다.

### 8. Suspension은 Source 집합으로 관리한다

하나의 `disabled` Boolean을 사용하지 않는다.

여러 Suspension Source가 동시에 존재할 수 있고, 한 Source가 해제되어도 다른 Source가 남으면 Object를 활성화하지 않는다.

Streaming, 화면 밖 상태와 Presentation Model 미생성은 Lifecycle Suspension이 아니다.

### 9. Runtime Ownership과 일반 Link를 분리한다

Runtime Ownership은 생성과 Cleanup 수명주기 관계다.

Gameplay Owner, Control Assignment, Character Ownership과 Item Ownership을 같은 필드로 합치지 않는다.

Owner 종료 시 Child Object 정책은 `destroy_with_owner`, `archive_with_owner`, `detach`, `transfer` 또는 Rule Recipe 종료 중 하나로 명시한다.

레버와 문, Journal과 Object 같은 일반 Link는 Ownership이 아니며 별도 무효화 정책을 가진다.

### 10. Scene Transfer는 새 Scene Presence를 만든다

Runtime Object는 Scene Presence이므로 같은 Record의 SceneId만 바꾸지 않는다.

Scene Transfer는 대상 Scene에 새 Runtime Object를 생성하고 CharacterId, NPC Record 또는 ItemInstance 같은 Persistent Domain Binding을 연결한 뒤 원본 Presence를 Archive 또는 종료한다.

Character는 같은 CharacterId를 유지하지만 새 ActorId를 받는다.

### 11. Static Layer Artifact는 필요한 경우에만 Runtime Object를 만든다

바닥, 벽과 장식의 정적 Geometry는 Navigation·Visibility·Presentation Artifact만 만들 수 있다.

독립 상태, 선택, 링크, 파괴, 공개 또는 Lifecycle이 필요한 경우에만 Runtime Object Blueprint를 생성한다.

### 12. 권위 Object와 Presentation Materialization을 분리한다

Client Model은 `loading`, `ready`, `evicted`, `failed`일 수 있지만 서버 Runtime Object Lifecycle과 동일하지 않다.

Presentation 오류가 권위 Object를 파괴하거나 규칙 결과를 바꾸지 않는다.

Server Raw Object Directory는 Disclosure와 Perception을 거쳐 Client View로 투영하며 숨겨진 Object Identity를 미리 노출하지 않는다.

## 결과

- Actor, 문, 함정, 소환체와 지속 영역이 같은 참조·Lifecycle·Rollback 규칙을 사용한다.
- Character, Item과 Effect의 영구 원본 책임은 유지된다.
- 삭제·복원·서버 복구 후 오래된 Ref가 안전하게 실패한다.
- Scene Build 교체 시 Source Identity로 Object State를 Rebind할 수 있다.
- Spawn과 Destroy의 부분 성공을 원자적 Transaction으로 방지한다.
- Streaming과 Presentation 실패가 권위 Object Lifecycle을 바꾸지 않는다.
- 정적 Geometry를 Object로 만들지 않아 Registry와 복제 비용을 줄인다.
- Owner Effect 종료 시 Child Object Cleanup을 결정적으로 수행할 수 있다.

## 비용과 주의점

- Object Registry, Component Registry, Archive Store, Tombstone Store와 Ownership·Link Graph가 필요하다.
- Domain 문서는 SceneObjectId와 RuntimeObjectId를 구분해야 한다.
- Runtime Command와 Query가 Roblox Instance 대신 RuntimeObjectRef를 사용하도록 정리해야 한다.
- Live Build Patch에는 Blueprint Compatibility와 Component Migration이 필요하다.
- Tombstone과 Historical Link의 보존·압축 정책이 필요하다.
- Client Streaming은 Object Directory와 Presentation Materialization을 별도로 준비해야 한다.

## 비목표

- 이 ADR은 실제 ModuleScript 경로와 Store 구현 방식을 고정하지 않는다.
- 특정 ECS 라이브러리 사용을 결정하지 않는다.
- Streaming Chunk 로드 순서와 Client Ready Protocol을 확정하지 않는다.
- 모든 Component의 세부 Rules 동작을 이 ADR에 넣지 않는다.
- 일반 사용자가 임의 Component 코드를 실행하는 Plugin Sandbox를 제공하지 않는다.
