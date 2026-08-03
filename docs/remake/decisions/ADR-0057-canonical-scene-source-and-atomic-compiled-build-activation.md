# ADR-0057. Canonical Scene Source와 원자적 Compiled Build 활성화

- 상태: 확정
- 작성일: 2026-08-03
- 결정 범위: Scene 저장 원본, Semantic Compilation, Runtime Layer 패키징, 부분 컴파일과 Live Build 교체
- 관련 문서:
  - [`Runtime Architecture Principles`](../architecture/runtime-architecture-principles.md)
  - [`Scene Compiler와 Compiled Runtime Scene 계약`](../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
  - [`Spatial Query Engine과 Provider 계약`](../architecture/spatial-query-engine-and-provider-contract.md)
  - [`Runtime Navigation 계약`](../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`Scenes and World`](../systems/scene/scenes-and-world.md)
  - [`Semantic Scene 기반 Navigation Authoring Pipeline`](../systems/navigation/navigation-authoring-pipeline.md)

## 배경

RVTT Scene은 시각 Asset뿐 아니라 Navigation, Visibility, Interaction, Rule, 권한별 Metadata와 공간 Index를 함께 제공해야 한다.

Scene Editor가 이 모든 Runtime 자료구조를 직접 저장하거나, 각 시스템이 Workspace와 Model을 독자적으로 해석하면 다음 문제가 생긴다.

- DM이 Polygon, Portal, 차단체와 내부 Attribute를 직접 관리해야 함
- 문 하나의 상태가 Navigation, Visibility와 Interaction에서 다르게 반영됨
- 일부 Layer만 새 데이터로 바뀌어 활성 Scene이 혼합 Revision이 됨
- Compiler 실패가 현재 플레이 중인 Scene을 손상시킴
- 부분 수정에도 Scene 전체를 반복해서 재분석함
- 비밀문과 함정의 실제 데이터가 일반 클라이언트에 복제됨
- Runtime Artifact와 저장 원본의 경계가 사라져 마이그레이션과 복구가 어려워짐

## 결정

### 1. Scene Source를 유일한 Authoring 원본으로 사용한다

DM이 저장하는 원본은 안정적 ID, Asset 참조, Transform, 외부 Semantic Profile, Scene Override, 명시적 Region·Link와 Scene 설정이다.

Compiled Polygon, Graph, Index, Cache와 Roblox Instance는 Authoring 원본이 아니다.

Compiled Artifact는 Source와 Version Set으로 다시 생성할 수 있어야 한다.

### 2. 원본 Model과 Semantic Profile을 분리한다

가져온 Model은 시각 Geometry를 제공한다.

규칙 의미는 Asset Library, Content Pack 또는 Scene Instance Metadata의 Semantic Profile에서 제공한다.

일반 Model을 사용하기 위해 `Walkable`, `Deniable`, `DifficultTerrain` 같은 Attribute와 Value를 직접 넣도록 요구하지 않는다.

### 3. Compiler는 공통 Semantic Contribution IR을 사용한다

Scene Source와 Profile은 먼저 안정적 ID, Source Lineage, Layer 종류, Geometry 참조, State Binding과 Dependency를 가진 정규화된 Semantic Contribution으로 변환한다.

Navigation, Visibility, Interaction, Rule과 확장 Layer Builder는 이 공통 Contribution을 입력으로 사용한다.

Builder가 Editor UI, Workspace 순서와 다른 Builder의 내부 상태를 직접 해석하지 않는다.

### 4. Compiled Runtime Scene은 불변 Build Package다

각 Build는 다음에 고정된다.

```text
sceneId
+ buildId
+ sourceRevision
+ sourceContentHash
+ compilerVersionSet
+ providerVersionSet
+ artifactSchemaVersion
```

새 Build는 기존 Build를 제자리에서 수정하지 않는다.

활성 Runtime과 Snapshot은 명시적인 `buildId`를 참조한다.

### 5. Layer와 Index는 Manifest 단위로 원자적으로 활성화한다

Navigation만 새 Build, Visibility는 이전 Build처럼 혼합된 상태를 허용하지 않는다.

모든 필수 Layer, State Binding, Index, Chunk와 Disclosure Segment 검증이 끝난 뒤 Published Build Pointer를 한 번에 교체한다.

Candidate Build 실패 시 현재 Published Build를 유지한다.

### 6. Dynamic State 변경은 Source 재컴파일이 아니다

문 열림, Actor 이동, 함정 발동과 Runtime Effect 생성은 서버 권위 Command로 Dynamic State Revision을 바꾼다.

Compiler는 상태별 Contribution 활성화와 무효화 대상을 `CompiledStateBinding`으로 미리 만든다.

Runtime Snapshot은 해당 Binding과 Dynamic State를 결합하고 필요한 Index만 증분 갱신한다.

### 7. 부분 컴파일은 내부 최적화이며 결과는 완전한 Build다

Authoring ChangeSet은 Dependency Graph와 공간 Bounds를 사용해 영향받는 Contribution, Layer Artifact와 Index만 재생성할 수 있다.

그러나 게시되는 결과는 항상 전체 Build Manifest를 가진다.

같은 입력에서 부분 컴파일 조립 결과와 전체 컴파일 결과가 다르면 부분 Cache를 폐기하고 전체 Build를 다시 만든다.

### 8. Last Known Good Build를 유지한다

Compiler, Provider, Packaging 또는 게시 검증이 실패해도 활성 세션과 Published Build를 제거하지 않는다.

정상 Build가 없는 Scene만 플레이 시작을 차단한다.

### 9. 활성 세션은 Build에 고정하고 Live Patch는 명시적으로 수행한다

실행 중인 세션은 `sceneId + buildId + dynamicStateRevision`에 고정된다.

새 Authoring Build를 게시했다고 활성 세션에 자동 적용하지 않는다.

구조적 Live Patch는 안전 Checkpoint, Dynamic State Rebase와 호환성 검사를 거쳐 전체 Build를 원자적으로 교체하며, 실패 시 이전 Build로 복구한다.

세션 중 임시 조정은 Runtime Semantic Overlay로 처리하고 Scene Source로 자동 승격하지 않는다.

### 10. Stable ID와 결정적 Build를 사용한다

Source Object, Contribution와 Artifact ID는 배열·Workspace·Lua table 순서가 아니라 안정적 Source ID와 Provider Local Key에서 파생한다.

같은 Source Content Hash와 Version Set은 같은 의미, 정렬과 Build Content Hash를 생성해야 한다.

### 11. Raw Server Build와 Client Disclosure Segment를 분리한다

비밀문, 함정, 숨겨진 Actor Blueprint, DM Metadata와 Source Lineage는 일반 플레이어용 Segment에 포함하지 않는다.

서버에 모든 정보를 복제한 뒤 UI에서만 숨기는 방식은 사용하지 않는다.

### 12. Compiler Provider는 등록형·제한형 계약을 따른다

Provider는 자신의 Contribution과 Layer Artifact만 생성한다.

Provider는 Scene Source와 Dynamic State를 변경하거나, Remote·UI를 호출하거나, Roblox Instance를 Runtime Artifact로 반환하지 않는다.

의존성, Version, Capability, 결정성 정책과 실패 심각도를 Registry에 명시한다.

## 결과

- Scene Editor는 Semantic Object와 예외에 집중할 수 있다.
- Runtime은 문자열, Model 이름과 임의 Attribute를 반복 해석하지 않는다.
- Navigation, Visibility, Interaction과 Rule이 같은 Source Object와 State Binding을 공유한다.
- Build 실패가 현재 플레이를 손상시키지 않는다.
- 대형 Scene을 부분 컴파일할 수 있으면서도 게시 결과의 완전성과 결정성을 유지한다.
- Runtime Quick Edit와 영구 Authoring 변경의 경계가 명확해진다.
- Cache와 Index를 잃어도 Source에서 다시 생성할 수 있다.
- 클라이언트에 비밀 Runtime Artifact가 불필요하게 전달되지 않는다.

## 비용과 주의점

- Compiler Core, Provider Registry, Dependency Graph와 Artifact Packaging 구현이 필요하다.
- Source ID와 Version 관리가 초기부터 엄격해야 한다.
- 부분 컴파일과 전체 컴파일의 동일성을 검증하는 테스트가 필요하다.
- Live Build 교체에는 Dynamic State Rebase와 안전한 복구 절차가 필요하다.
- 여러 Layer가 하나의 State Binding을 공유하므로 Cross-layer Validation이 필수다.

## 비목표

- 이 ADR은 Runtime Object 전체 생명주기를 확정하지 않는다.
- Scene Streaming Ready Protocol과 로드 우선순위를 확정하지 않는다.
- 특정 Polygon, BVH, Octree와 Chunk 알고리즘을 고정하지 않는다.
- 일반 사용자가 임의 Compiler 코드를 설치하는 Plugin Sandbox를 제공하지 않는다.
