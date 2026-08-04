# Scene 시스템

Scene Source, Compiled Runtime Build, 세션 Dynamic State, Runtime Object Lifecycle, Client Streaming, 라이브 패치와 인게임 제작 도구를 다룬다.

## 권위 문서

### Session Mode와 Overlay

- [`../../architecture/session-play-mode-context-overlay-and-transition-contract.md`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - Exploration·Encounter·Downtime Base Play Mode
  - DM Authoring은 전역 Gameplay Mode가 아니라 DM 전용 Overlay
  - Scene Transition·Join·Reconnect·Recovery는 일반 Command를 차단하는 Transitional State
  - Pause·Selection·Presentation Focus와 Rollback Review의 Overlay 경계

### Scene과 World

- [`scenes-and-world.md`](scenes-and-world.md)
  - Campaign World와 Scene 권위 경계
  - Scene Source, Published Build와 Runtime State 분리
  - Scene 생성, Runtime Build, 검토, 게시와 테스트 플레이
  - 활성 세션 Build 고정, Live Authoring과 Runtime Quick Edit
  - Scene Transition, Entry Anchor, 저장·복구와 삭제 경계

### Compiler와 Runtime Definition

- [`../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - Canonical Scene Source와 Normalized Semantic Contribution
  - Navigation, Visibility, Interaction, Rule과 Metadata Layer Build
  - Runtime Object Blueprint, State Binding, Spatial Index와 Chunk
  - 부분 컴파일, 원자적 Build 게시와 Last Known Good Build
  - 권한별 Client Disclosure Segment

### Runtime Object와 Lifecycle

- [`../../architecture/runtime-object-system-and-entity-lifecycle-contract.md`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - Actor, 문, 함정, 소환체와 Scene Effect Presence의 공통 Identity
  - RuntimeObjectId, Incarnation, Component와 Registry
  - Spawn·Suspend·Archive·Restore·Destroy
  - Scene Transfer, Build Rebind, Tombstone과 Ownership Cleanup
  - Workspace Model과 권위 Object Lifecycle 분리

### Streaming과 Scene 전환

- [`../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
  - Client-safe Scene Chunk와 Projection·Presentation 분리
  - Projection Interest와 Camera·Movement Presentation Interest
  - Entry Essential, Controlled Actor와 Encounter Activation Set
  - Streaming Veil, Prefetch, Cache, Eviction과 실패 격리
  - Prepare·Commit 기반 Scene Transition과 그룹 전환
  - Chunk Stream Out과 Runtime Object Lifecycle 분리

### Scene Editor

- [`ingame-scene-editor-tools.md`](ingame-scene-editor-tools.md)
  - 인게임 벽·바닥·방·문·계단·프리팹 제작 도구
  - 공통 배치 커서, 스냅, ViewY와 파라메트릭 편집
  - Scene Source를 변경하는 Authoring Tool 흐름

이동 의미 생성은 [`../navigation/`](../navigation/), 편집 UI는 [`../../ui/scene-editor/`](../../ui/scene-editor/)를 따른다.

## 고정 경계

- Scene Editor는 `DM_ONLY` Authoring Overlay이며 다른 참가자의 Exploration·Encounter Mode를 바꾸지 않는다.
- Scene Source Authoring과 Runtime Quick Edit를 동일한 Commit으로 섞지 않는다.
- Scene Editor는 Scene Source를 편집하고 Runtime Layer를 직접 편집하지 않는다.
- Compiler Build는 불변이며 Layer 일부만 혼합해 게시하지 않는다.
- Compiler는 Runtime Object Blueprint를 만들고 Live RuntimeObjectId는 Runtime Registry가 바인딩한다.
- 플레이 중 상태 변경은 Dynamic State와 Runtime Overlay에 기록한다.
- Runtime Object Lifecycle은 서버 권위 Command로만 변경한다.
- Client Chunk의 Ready·Evicted·Failed는 Runtime Object의 Active·Suspended·Archived·Destroyed와 별개다.
- Scene Entry Essential이 준비되기 전에 Gameplay Command를 허용하지 않는다.
- Scene Transition은 Target Preload 후 안전 경계의 원자적 Presence Transfer를 사용한다.
- Quick Edit는 명시적 승격 전까지 Scene Source를 변경하지 않는다.
- Workspace Instance와 Compiler Cache는 저장 원본이 아니다.