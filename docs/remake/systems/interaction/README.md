# Interaction 시스템

무설정 상호작용 프리팹, 상태 전환, 문·상자·레버, 함정·비밀문과 파괴 오브젝트를 다룬다.

## 상위 권위 문서

- [`Interaction Capability, Contextual Command와 Adjudication 계약`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)
  - 선택된 대상에서 행위자·대상·아이템·효과 Capability를 결합한다.
  - Exploration과 Encounter의 비용·Timing 차이를 Context Policy로 처리한다.
  - E 기본 상호작용, Q 취소·거절과 DM 승인 문맥을 고정한다.
  - Player Command와 DM Override를 분리한다.
- [`Selection, Targeting, Preview와 Frozen Binding Runtime 계약`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - Interaction 대상의 Hover·Focus·Selection과 Frozen Binding
- [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - 상호작용 Object의 RuntimeObjectId와 Component 조합
  - StateMachine, Interaction, Durability, Link와 Presentation Binding
  - Spawn·Suspend·Archive·Restore·Destroy
- [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md)
  - 상호작용 후보, 접근 Anchor, 거리와 공간 증거
- [`Scene Compiler와 Compiled Runtime Scene 계약`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - Interaction Blueprint, State Binding과 Disclosure Segment

## 기능 모델

- [`zero-metadata-interaction-prefab-and-state-transition-model.md`](zero-metadata-interaction-prefab-and-state-transition-model.md)
  - 프리팹 제작, 상태 1·2 대응, Tween과 상태 전환 Presentation
  - Context Action과 권한의 최상위 권위는 Interaction Capability Architecture다.
- [`trap-secret-door-and-destructible-object-model.md`](trap-secret-door-and-destructible-object-model.md)

## 역할 경계

### PLAYER_ONLY

- 공개된 대상에 규칙상 허용된 상호작용 실행
- 자신의 아이템 사용·장착·버리기
- 공개 바닥 아이템 줍기
- DM 판정이 필요한 즉흥 의도 제출

### DM_ONLY

- 숨겨진 Object·Trigger 선택과 조작
- Force Open·Lock·Move, 생성·삭제·복원
- 비밀 DC와 실제 숨김 정보 확인
- Journal Link 작성
- Adjudication 승인·거절·수정

### SYSTEM_ONLY

- Capability Query와 Contextual Option Projection
- 거리·접근·권한·Action Economy 재검증
- RuleExecution·Reservation·Transaction·Rollback

## 고정 경계

- SceneObjectId는 Authoring Source ID이며 Live Runtime Command의 최종 참조가 아니다.
- Runtime 상호작용 명령은 현재 RuntimeObjectRef와 Incarnation을 검증한다.
- Selection과 UI는 Object 상태를 직접 변경하지 않는다.
- Context Action Menu는 Projection이며 저장 원본이 아니다.
- 상태 전환, Navigation·Visibility Binding과 Presentation은 같은 Commit 경계에서 일관되게 갱신한다.
- Workspace Model과 Tween 완료 여부를 권위 Object Lifecycle로 취급하지 않는다.
- 비밀문과 숨겨진 함정의 Runtime Identity와 Capability를 공개 전 Client에 전달하지 않는다.
- DM Override와 Player 일반 행동은 같은 Command로 처리하지 않는다.

## Guide Status

```text
READY_TO_WRITE
```

최신 Interaction Capability·Selection·Perception·Exploration 계약과 Completion Audit에서 통합 Guide 작성 조건이 충족되었다.
