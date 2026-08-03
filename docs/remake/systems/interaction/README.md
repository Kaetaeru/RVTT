# Interaction 시스템

무설정 상호작용 프리팹, 상태 전환, 문·상자·레버, 함정·비밀문과 파괴 오브젝트를 다룬다.

## 권위 문서

### 기능 모델

- [`zero-metadata-interaction-prefab-and-state-transition-model.md`](zero-metadata-interaction-prefab-and-state-transition-model.md)
- [`trap-secret-door-and-destructible-object-model.md`](trap-secret-door-and-destructible-object-model.md)

### 공통 Runtime 권위

- [`../../architecture/runtime-object-system-and-entity-lifecycle-contract.md`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - 상호작용 Object의 RuntimeObjectId와 Component 조합
  - StateMachine, Interaction, Durability, Link와 Presentation Binding
  - Spawn·Suspend·Archive·Restore·Destroy
  - 강한 Link 무효화, Ownership Cleanup과 Tombstone
- [`../../architecture/spatial-query-engine-and-provider-contract.md`](../../architecture/spatial-query-engine-and-provider-contract.md)
  - 상호작용 후보, 접근 Anchor, 거리와 공간 증거
- [`../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - Interaction Blueprint, State Binding과 Disclosure Segment

## 고정 경계

- SceneObjectId는 Authoring Source ID이며 Live Runtime Command의 최종 참조가 아니다.
- Runtime 상호작용 명령은 서버가 SceneObjectId를 현재 RuntimeObjectRef로 해결하거나 RuntimeObjectRef를 직접 사용한다.
- 상태 전환, Navigation·Visibility Binding과 Presentation은 같은 Commit 경계에서 일관되게 갱신한다.
- Workspace Model과 Tween 완료 여부를 권위 Object Lifecycle로 취급하지 않는다.
- 비밀문과 숨겨진 함정의 Runtime Identity를 공개 전 Client에 전달하지 않는다.
