# Scene 시스템

Scene Source, Compiled Runtime Build, 세션 Dynamic State, 라이브 패치와 인게임 제작 도구를 다룬다.

## 권위 문서

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

### Scene Editor

- [`ingame-scene-editor-tools.md`](ingame-scene-editor-tools.md)
  - 인게임 벽·바닥·방·문·계단·프리팹 제작 도구
  - 공통 배치 커서, 스냅, ViewY와 파라메트릭 편집
  - Scene Source를 변경하는 Authoring Tool 흐름

이동 의미 생성은 [`../navigation/`](../navigation/), 편집 UI는 [`../../ui/scene-editor/`](../../ui/scene-editor/)를 따른다.

## 고정 경계

- Scene Editor는 Scene Source를 편집하고 Runtime Layer를 직접 편집하지 않는다.
- Compiler Build는 불변이며 Layer 일부만 혼합해 게시하지 않는다.
- 플레이 중 상태 변경은 Dynamic State와 Runtime Overlay에 기록한다.
- Quick Edit는 명시적 승격 전까지 Scene Source를 변경하지 않는다.
- Workspace Instance와 Compiler Cache는 저장 원본이 아니다.
