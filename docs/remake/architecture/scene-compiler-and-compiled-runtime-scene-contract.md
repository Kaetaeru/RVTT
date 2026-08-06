# Scene Compiler와 Compiled Runtime Scene 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Scene Build 작업 큐의 동시 실행 수와 시간 예산
  - Content-addressed Artifact Cache의 메모리·저장 상한
  - 기본 Chunk 목표 크기와 경계 확장 폭
  - 마지막 정상 Build 보존 개수
  - 대형 Scene의 진단 결과 페이지 크기
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0054`](../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md)
  - [`ADR-0055`](../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md)
  - [`ADR-0056`](../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md)
  - [`ADR-0057`](../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
- 관련 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Spatial Query Engine과 Provider 계약`](spatial-query-engine-and-provider-contract.md)
  - [`Runtime Navigation 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`Scenes and World`](../systems/scene/scenes-and-world.md)
  - [`Semantic Scene 기반 Navigation Authoring Pipeline`](../systems/navigation/navigation-authoring-pipeline.md)

## 1. 목적

Scene Compiler는 DM이 편집하는 Scene Source를 플레이 중 직접 사용할 수 있는 검증된 Runtime Definition으로 변환한다.

```text
Scene Source
+ Asset Semantic Profile
+ Content Pack Definition
+ Scene Override
→ Source Validation
→ Semantic Normalization
→ Layer Builder
→ Cross-layer Validation
→ Index와 Dependency Graph 생성
→ Compiled Runtime Scene Build
```

Compiler의 목적은 Scene Editor의 복잡성을 줄이면서 Navigation, Visibility, Interaction, Rule과 Metadata가 같은 오브젝트와 상태를 일관되게 해석하도록 만드는 것이다.

Compiler는 플레이 중 Actor를 움직이거나 문을 열지 않는다. Authoring Source를 검증하고 불변 파생 데이터를 생성하는 저작·게시 계층이다.

## 2. 사용자 결과

내부 계약은 다음 사용자 경험을 보장하기 위해 존재한다.

- DM은 집, 벽, 문, 계단, 물, 함정과 소품을 의미 있는 오브젝트로 배치한다.
- DM은 Runtime Polygon, Spatial Index, Portal 폭과 내부 Node를 직접 관리하지 않는다.
- `Scene Runtime 만들기 / 갱신` 한 번으로 필요한 Layer와 Index를 함께 만든다.
- Build에 실패해도 현재 플레이 중인 마지막 정상 Scene은 손상되지 않는다.
- 오류는 내부 Artifact 이름이 아니라 관련 오브젝트와 위치, 원인, 수정 선택지로 표시한다.
- 문 하나의 상태가 Navigation에서는 열렸지만 Visibility에서는 닫힌 것처럼 보이는 혼합 결과를 게시하지 않는다.
- 대형 Scene의 일부만 수정해도 전체 Scene을 매번 처음부터 만들 필요가 없다.
- 비밀문, 함정과 DM 전용 Metadata가 일반 플레이어용 Runtime Package에 섞여 유출되지 않는다.

## 3. 권위 데이터 구분

### 3.1 Scene Source

DM이 편집하고 영구 저장하는 유일한 저작 원본이다.

```text
SceneSourceManifest
├─ sceneId
├─ sourceSchemaVersion
├─ authoringRevision
├─ coordinateSystemRef
├─ worldScaleRef
├─ sourcePackDependencies[]
├─ placedObjectSources[]
├─ parametricObjectSources[]
├─ semanticRegionSources[]
├─ explicitLinkSources[]
├─ entryAnchorSources[]
├─ criticalRouteDefinitions[]
├─ sceneSettingsRef
├─ metadataRef
├─ sourceChunkManifest
└─ sourceContentHash
```

Scene Source는 Roblox Instance 참조를 저장하지 않는다. 저장 가능한 ID, 숫자, 문자열, Transform, Profile 참조와 명시적 Authoring 데이터만 가진다.

### 3.2 Compiled Runtime Scene Definition

특정 Scene Source Revision과 Compiler Version Set으로부터 생성된 불변 Build Package다.

Compiled Definition은 다시 만들 수 있는 파생 데이터이며 영구 저작 원본이 아니다.

### 3.3 Authoritative Dynamic State

플레이 중 서버가 소유하는 상태다.

- Actor 위치와 상태
- 문, 레버, 상자와 함정의 현재 상태
- 파괴·이동된 오브젝트 상태
- 활성 Rule Volume과 Scene Effect
- Fog 공개 상태
- Encounter와 턴 상태

Dynamic State는 Compiler가 직접 변경하지 않는다.

### 3.4 Runtime Scene Snapshot

특정 시점의 권위 조회 대상이다.

```text
Compiled Runtime Scene Build
+ Authoritative Dynamic State Revision
+ Runtime-created Semantic Overlay
→ Runtime Scene Snapshot
```

Spatial Query, Navigation Planner, Perception과 Rules는 Snapshot을 사용한다.

## 4. Scene Source 데이터 계약

### 4.1 PlacedSceneObjectSource

```text
PlacedSceneObjectSource
├─ sceneObjectId
├─ assetDefinitionRef
├─ transform
├─ parentGroupId?
├─ semanticProfileRef?
├─ instanceSemanticOverrides[]
├─ initialStateSeedRef?
├─ authoringTags[]
├─ editorLockState?
└─ sourceRevision
```

`sceneObjectId`는 배열 순서나 Roblox Instance 이름에서 만들지 않는다. Scene 안에서 안정적으로 유지되는 ID다.

오브젝트를 이동하거나 외형을 바꾸어도 같은 논리 오브젝트라면 ID를 유지한다. 복제는 새 ID를 만든다.

### 4.2 ParametricSceneObjectSource

벽 체인, 방, 계단과 같이 원본 파라미터로 재생성되는 오브젝트다.

```text
ParametricSceneObjectSource
├─ sceneObjectId
├─ toolDefinitionId
├─ toolSchemaVersion
├─ parameters
├─ generatedAssetPolicy
├─ semanticProfileRef
├─ instanceSemanticOverrides[]
└─ sourceRevision
```

Compiler는 Editor Tool 코드를 실행하지 않는다. Tool이 저장한 검증된 파라미터를 등록된 Parametric Source Expander를 통해 정규화한다.

### 4.3 SemanticRegionSource

DM이 자동 판단의 예외를 공간적으로 명시하는 Authoring 데이터다.

예:

- Support Surface 후보
- Obstacle Volume
- Rule 또는 Movement Cost Field
- Compiler 제외 영역
- Trigger·Scene Transition 영역
- Visibility·Sound·Magic 등 특정 Layer 전용 영역

Region은 최종 Runtime Index가 아니다. Compiler가 Layer별 자료구조로 변환한다.

### 4.4 ExplicitLinkSource

두 오브젝트, Anchor 또는 영역 사이의 의미 있는 연결이다.

예:

- 문과 문틀
- 레버와 문
- 계단 아래와 위
- 사다리 양 끝
- Scene 출구와 다른 Scene의 Entry Anchor
- 함정 판과 발사 장치

단순 ObjectValue나 Roblox 계층을 권위 연결로 저장하지 않는다.

## 5. Semantic Profile과 정규화 기여 데이터

Asset Semantic Profile은 오브젝트가 각 Runtime Layer에 어떤 의미를 제공하는지 설명한다.

Compiler는 Profile을 바로 Layer Builder에 넘기지 않고 공통 `NormalizedSemanticContribution`으로 정규화한다.

```text
NormalizedSemanticContribution
├─ contributionId
├─ sourceSceneObjectId?
├─ sourceRegionId?
├─ providerId
├─ layerKind
├─ semanticTypeId
├─ normalizedGeometryRef?
├─ anchorRefs[]
├─ parameterSet
├─ stateBindingRef?
├─ disclosurePolicyRef
├─ dependencyKeys[]
├─ affectedBounds?
└─ sourceLineage
```

### 5.1 Contribution ID

`contributionId`는 다음 안정적 구성요소에서 파생한다.

```text
sceneId
+ source object or region ID
+ providerId
+ localContributionKey
```

배열 순서, Workspace 생성 순서와 Lua table 순서를 사용하지 않는다.

### 5.2 Source Lineage

모든 Compiled Artifact는 자신이 어느 Scene Object, Region, Profile과 Provider에서 만들어졌는지 추적할 수 있어야 한다.

이 정보는 다음에 사용한다.

- 오류 위치 이동
- 부분 컴파일 영향 계산
- Query Trace와 Navigation 진단
- Build 간 변경 비교
- Plugin 또는 Provider 오류 격리

### 5.3 Geometry Adapter

원본 Model의 Geometry를 읽어야 하는 경우 등록된 Geometry Adapter가 정규화된 단순 Geometry를 만든다.

Geometry Adapter는 다음을 지킨다.

- Model 이름, 색상과 투명도를 규칙 의미로 임의 해석하지 않는다.
- Roblox Instance를 Compiled Artifact에 저장하지 않는다.
- 시각 Mesh의 모든 세부 형상을 권위 충돌체로 복사하지 않는다.
- Profile과 Override가 제공한 의미 범위 안에서만 Geometry를 추출한다.
- 실패 시 `Unknown` 또는 구조화된 진단을 반환한다.

## 6. Compiler Pipeline

Scene Build는 다음 단계로 진행한다.

```text
1. Source Manifest 로드
2. Source Schema 검증과 Migration
3. Source Pack·Asset Definition 참조 해결
4. 좌표·Transform·ID 정규화
5. Parametric Source 확장
6. Semantic Profile과 Override 합성
7. Normalized Semantic Contribution 생성
8. Layer Builder 실행
9. Runtime Object Blueprint와 State Binding 생성
10. Spatial Index와 Dependency Graph 생성
11. Cross-layer Validation
12. 자동 경로·Anchor·게시 검사
13. Chunk와 Disclosure Segment 패키징
14. Build Manifest와 Diagnostics 생성
15. 원자적 Ready Build 등록
```

앞 단계가 실패했는데 뒤 단계가 임의의 기본값으로 계속 진행해서는 안 된다. 안전하게 격리 가능한 선택적 Provider만 비활성화하고, 핵심 Layer 실패는 Build 전체를 실패시킨다.

## 7. SceneCompilerProvider 계약

Layer와 확장 기능은 등록된 Provider를 통해 컴파일된다.

```text
SceneCompilerProvider
├─ providerId
├─ providerVersion
├─ supportedLayerKinds[]
├─ sourceSchemaRange
├─ contributionSchemaRange
├─ dependencies[]
├─ compileCapability
├─ validationCapability
└─ deterministicPolicy
```

Provider는 다음을 할 수 있다.

- 자신이 지원하는 Contribution 읽기
- 자신의 Layer Artifact 생성
- Source Lineage와 Dependency 기록
- 영향을 받는 Bounds와 Artifact Key 반환
- 구조화된 진단 반환

Provider는 다음을 할 수 없다.

- Scene Source 직접 수정
- Authoritative Dynamic State 변경
- Remote, UI와 Presentation 호출
- Roblox Instance를 Runtime Artifact로 반환
- 다른 Provider의 Artifact를 몰래 수정
- 전역 Workspace를 무제한 순회

Provider 간 의존성은 Registry에 명시하고 순환 의존성을 허용하지 않는다.

## 8. Compiled Runtime Scene Build

```text
CompiledRuntimeSceneBuild
├─ sceneId
├─ buildId
├─ artifactSchemaVersion
├─ sourceRevision
├─ sourceContentHash
├─ compilerVersionSet
├─ providerVersionSet
├─ buildStatus
├─ layerManifest
├─ runtimeObjectBlueprintTable
├─ stateBindingTable
├─ anchorRegistry
├─ spatialIndexManifest
├─ dependencyGraphRef
├─ disclosureSegmentManifest
├─ chunkManifest
├─ diagnosticSummary
├─ buildContentHash
└─ createdAt
```

`buildId`는 활성 Runtime과 Snapshot이 참조하는 고정 ID다. 같은 Scene에 새 Build가 생성되어도 기존 Build의 내용을 제자리에서 수정하지 않는다.

### 8.1 Layer Manifest

초기 Layer 종류:

```text
navigation
visibility
interaction
rule
permission_metadata
custom_registered
```

각 Layer Artifact는 다음 공통 필드를 가진다.

```text
CompiledLayerArtifact
├─ layerKind
├─ layerRevision
├─ artifactSchemaVersion
├─ providerIds[]
├─ artifactRefs[]
├─ spatialCoverage
├─ dependencyKeys[]
├─ disclosureSegmentRef
└─ contentHash
```

### 8.2 Navigation Layer

Runtime Navigation 계약에 정의된 다음 자료를 제공한다.

- Traversal Domain
- Transition Graph
- Static Obstacle Field
- Supporting Surface Index
- Movement Cost Field
- Portal Geometry와 Vertical Free-span
- 구성 공간 가속 자료

### 8.3 Visibility Layer

다음을 위한 정적·상태 연동 Definition을 제공한다.

- 시야 차단 Geometry
- 투과·부분 차단 정책
- Portal과 문 상태 Binding
- 규칙 조명·가림 Field의 정적 원본
- Visibility Provider용 공간 Index

최종 관찰자별 탐지 결과는 Perception Runtime이 계산한다.

### 8.4 Interaction Layer

다음을 제공한다.

- 상호작용 가능한 Runtime Object Blueprint
- 사용 Anchor와 접근 후보
- 상태 전환 Definition 참조
- 연결된 오브젝트와 Command Capability 참조
- 공개·발견 정책

잠금 해제 가능 여부와 실제 상태 변경은 Runtime Command가 처리한다.

### 8.5 Rule Layer

다음을 제공한다.

- Rule Field Definition
- Trigger Boundary
- Hazard와 Scene Effect 생성용 Blueprint
- Scene Transition과 Encounter 후보
- Runtime Rule Provider용 Index

### 8.6 Permission-aware Metadata Layer

다음을 일반 공개 데이터와 분리한다.

- 비밀문 실제 연결
- 함정의 숨겨진 Blueprint
- DM 전용 Journal Link
- 미발견 오브젝트의 정확한 위치와 상태
- Compiler 진단용 Source Lineage

## 9. Runtime Object Blueprint와 State Binding

이 문서는 Runtime Object의 전체 생명주기를 정의하지 않는다. Scene Compiler가 제공해야 할 최소 Blueprint와 상태 연결만 정의한다.

```text
CompiledSceneObjectBlueprint
├─ runtimeObjectId
├─ objectKind
├─ sourceSceneObjectId?
├─ defaultTransform
├─ presentationDefinitionRef?
├─ initialStateSeedRef?
├─ semanticContributionRefs[]
├─ stateBindingRefs[]
├─ anchorRefs[]
├─ disclosurePolicyRef
└─ sourceLineage
```

### 9.1 State Binding

문, 함정과 파괴 오브젝트의 상태는 여러 Layer의 의미를 함께 바꿀 수 있다.

```text
CompiledStateBinding
├─ stateBindingId
├─ runtimeObjectId
├─ authoritativeStatePath
├─ allowedStateValues[]
├─ contributionActivationMap
├─ contributionParameterOverrides
├─ invalidationTargets[]
└─ revisionPolicy
```

예: 닫힌 문에서 열린 문으로 변경될 때:

```text
Navigation Obstacle 비활성
Navigation Linked Transition 활성
Visibility Blocker 비활성 또는 변경
Interaction Action Set 변경
Presentation State 변경
```

문이 열릴 때 Scene Source를 다시 컴파일하지 않는다. Command가 Dynamic State Revision을 전진시키고 Snapshot Assembler가 이미 컴파일된 State Binding을 적용한다.

## 10. Spatial Index와 Chunk

Compiler는 Query와 Streaming이 사용할 Index와 Chunk를 만든다.

```text
SpatialIndexManifest
├─ indexKind
├─ coveredLayerKinds[]
├─ chunkRefs[]
├─ coordinateBounds
├─ artifactSchemaVersion
└─ contentHash
```

Index는 Layer Artifact의 파생 데이터다. 손상되거나 버전이 바뀌면 다시 만들 수 있어야 한다.

Chunk는 다음 원칙을 따른다.

- Stable ID와 Cross-chunk Reference를 유지한다.
- Chunk 경계가 규칙 경계가 되지 않는다.
- 경계에 걸친 Geometry와 Query를 위한 overlap 또는 reference policy를 가진다.
- 비밀 정보는 일반 플레이어용 Chunk와 별도 Disclosure Segment에 둔다.
- 일부 Chunk 로드 실패를 빈 공간으로 오인하지 않는다.

정확한 스트리밍 활성화 순서는 후속 Streaming 계약에서 정의한다.

## 11. Dependency Graph와 부분 컴파일

```text
CompiledDependencyGraph
├─ sourceToContributions
├─ contributionToArtifacts
├─ artifactToIndexes
├─ stateBindingToInvalidationTargets
├─ crossLayerLinks
├─ spatialDependencyBounds
└─ reverseDependencies
```

### 11.1 Authoring Change

Scene Editor에서 Source가 변경되면:

```text
Authoring ChangeSet
→ 변경 Source ID와 Bounds 계산
→ Reverse Dependency 탐색
→ 영향받는 Contribution과 Artifact 재생성
→ 인접·Cross-layer 재검증
→ 새 Candidate Build 조립
```

부분 컴파일은 내부 최적화다. 게시 결과는 항상 완전한 Build Manifest를 가진다.

### 11.2 Dynamic State Change

문 열림, Actor 이동과 Runtime Effect 생성은 Authoring Change가 아니다.

```text
Authoritative Command
→ Dynamic State Revision 변경
→ State Binding과 Runtime Overlay 적용
→ 관련 Runtime Index 증분 갱신
→ 새 Snapshot 공개
```

이 흐름은 Source Compiler 전체를 실행하지 않는다.

### 11.3 동일성 보장

같은 Source Revision과 Compiler Version Set으로 전체 컴파일한 결과와 부분 컴파일을 조립한 결과는 같은 의미와 Content Hash를 가져야 한다.

부분 컴파일 결과가 전체 컴파일과 다르면 부분 캐시를 폐기하고 전체 Build를 재실행한다.

## 12. Build Lifecycle

```text
draft_source
→ compile_queued
→ resolving
→ normalizing
→ building_layers
→ validating
→ ready
→ published
→ superseded
```

실패 상태:

```text
failed_source
failed_provider
failed_validation
failed_packaging
cancelled
```

`ready`는 Build가 사용 가능하다는 뜻이고, `published`는 Scene Record의 기본 활성 Build로 선택되었다는 뜻이다.

### 12.1 원자적 활성화

다음은 금지한다.

```text
Navigation: 새 Build
Visibility: 이전 Build
Interaction: 새 Build 일부
```

Scene Build는 완전한 Manifest 단위로만 활성화한다.

활성화 흐름:

```text
Candidate Build 완성
→ 모든 필수 Layer와 Index 검증
→ Build Manifest 봉인
→ Published Build Pointer 원자적 교체
```

### 12.2 Last Known Good Build

Build 실패 시:

- 현재 Published Build를 유지한다.
- 활성 세션은 기존 Build와 Snapshot을 계속 사용한다.
- 실패한 Candidate Artifact는 권위 Build가 되지 않는다.
- DM에게 실패 위치와 수정 경로를 보여준다.

Scene에 정상 Build가 한 번도 없다면 플레이 시작을 차단한다.

## 13. 활성 세션과 Live Patch

활성 세션은 다음에 고정된다.

```text
sceneId
+ buildId
+ dynamicStateRevision
```

새 Build가 게시되어도 실행 중인 세션에 자동 적용하지 않는다.

### 13.1 구조적 Authoring 변경

벽, 계단, 대형 지형과 Semantic Link 변경은 Candidate Build를 만든다.

활성 세션에 적용하려면:

1. 호환성 검사
2. 안전 Checkpoint 또는 세션 일시정지
3. Dynamic State Rebase 가능성 확인
4. 전체 Build Manifest 원자적 교체
5. Spatial Index와 Presentation 재투영
6. 실패 시 이전 Build 복구

### 13.2 Runtime Quick Edit

세션 중 임시 차단, 임시 Rule Field와 DM 조정은 Runtime Command로 `Runtime Semantic Overlay`를 만들 수 있다.

Quick Edit는 기본적으로 Scene Source를 자동 수정하지 않는다.

DM이 원하면 별도 `Source로 승격` 흐름을 통해 다음 Authoring Revision에 반영한다.

## 14. 결정성과 Version

Compiler는 같은 입력에서 같은 결과를 만들어야 한다.

고정 입력:

- Source Content Hash
- Source Pack Version
- Semantic Profile Version
- Compiler Core Version
- Provider Version Set
- Artifact Schema Version
- 명시적 Build Option

안정적 정렬 기준을 사용하고 Workspace 순서와 Lua table 순서에 의존하지 않는다.

Version 종류:

```text
sourceSchemaVersion
semanticProfileSchemaVersion
compilerCoreVersion
providerVersion
artifactSchemaVersion
```

Compiled Artifact의 오래된 Schema를 복잡하게 마이그레이션하는 대신 Source를 새 Compiler로 다시 Build한다.

Scene Source Migration은 영구 데이터 변경이므로 멱등성과 실패 복구를 보장해야 한다.

## 15. 진단과 게시 게이트

```text
SceneCompilerDiagnostic
├─ diagnosticId
├─ severity
├─ category
├─ sourceRefs[]
├─ worldBounds?
├─ providerId?
├─ messageKey
├─ suggestedFixes[]
├─ blocksBuild
├─ blocksPublish
└─ traceRef?
```

### 15.1 게시 차단 오류

초기 범주:

- Source Schema 또는 Migration 실패
- 필수 Asset·Profile·Content Pack 참조 누락
- 중복 Stable ID
- 필수 Provider 실패
- Cross-layer State Binding 불일치
- 필수 Entry Anchor가 유효 Runtime 위치로 컴파일되지 않음
- 게시 차단 Critical Route 실패
- 일반 플레이어 Segment에 비밀 정보 포함
- Chunk Manifest 또는 Cross-chunk Reference 손상
- 필수 Index 생성 실패
- Compiler 결과 결정성 검사 실패

### 15.2 경고

예:

- 시각 전용으로 처리된 의미 불명 Asset
- 비차단 Critical Route 실패
- 자동 보정된 작은 Geometry 결함
- 사용되지 않는 Anchor와 Link
- 필요하지 않은 대형 Artifact
- 대체 가능 Provider 비활성화

`Unknown`을 임의 의미로 변환하지 않는다. Gameplay 의미가 필요하지 않은 장식은 명시적으로 visual-only로 처리할 수 있다.

## 16. 보안과 Disclosure

Compiler는 서버 Raw Build와 클라이언트 공개 View를 구분한다.

```text
Server Build Package
├─ 모든 Runtime Layer
├─ 비밀 오브젝트와 실제 연결
├─ DM Metadata
└─ Source Lineage와 Diagnostics

Client Disclosure Segment
├─ 허용된 Visual·Collision Projection
├─ 공개된 Runtime Object Definition
├─ 권한에 맞는 Query View Data
└─ 발견된 정보
```

서버에 존재하는 비밀 데이터를 일반 클라이언트에 모두 복제한 뒤 UI에서만 숨기는 방식을 사용하지 않는다.

## 17. Cache와 성능

허용되는 Cache:

- Asset Definition별 정규화 Geometry
- Semantic Profile별 Contribution Template
- Source Content Hash별 Layer Artifact
- Chunk별 Spatial Index
- 자주 사용하는 Body Configuration용 구성 공간 파생 데이터

Cache는 권위 원본이 아니다.

다음 원칙을 따른다.

- Cache Miss가 규칙 결과를 바꾸지 않는다.
- Cache 손상 시 재생성하거나 Last Known Good Build를 사용한다.
- Compiler 실패가 활성 Runtime을 정지시키지 않는다.
- 플레이 중 Source Compiler를 매 프레임 실행하지 않는다.
- Build 진행은 작업 큐와 Budget으로 제한한다.

## 18. 사용자 표시

DM에게 기본적으로 보여줄 상태:

```text
편집 중
Runtime 생성 필요
생성 중
검토 권장
게시 가능
게시됨
생성 실패
```

진행 단계는 다음처럼 제품 의미로 표시한다.

```text
에셋 확인
장면 의미 생성
이동·시야·상호작용 검사
핵심 경로 확인
게시 데이터 준비
```

내부 Provider 함수명과 Artifact ID를 일반 UI의 주 메시지로 표시하지 않는다.

## 19. 검증 기준

구현 명세는 최소한 다음을 검증해야 한다.

1. 같은 Source와 Version Set은 같은 Build Content Hash를 만든다.
2. 부분 컴파일 결과와 전체 컴파일 결과가 동일하다.
3. 한 Provider 실패가 필수도에 따라 안전하게 격리되거나 Build를 실패시킨다.
4. Candidate Build 실패 중에도 Published Build가 유지된다.
5. Layer 일부만 새 Build로 활성화할 수 없다.
6. 문 State Binding이 Navigation, Visibility와 Interaction에 같은 상태를 반영한다.
7. 비밀문과 함정의 Raw Artifact가 일반 Client Segment에 포함되지 않는다.
8. Stable ID가 Source 배열 순서 변경으로 바뀌지 않는다.
9. Runtime Quick Edit가 Source를 자동 변경하지 않는다.
10. Active Session Build 교체 실패 시 이전 Build와 Snapshot으로 복구된다.
11. Source Object를 선택하면 관련 Diagnostic과 Compiled Artifact Lineage를 추적할 수 있다.
12. Index와 Cache를 삭제해도 Source에서 정상 Build를 재생성할 수 있다.

## 20. 비목표

- 구체적인 Polygon 생성 라이브러리와 공간 분할 알고리즘을 이 문서에서 고정하지 않는다.
- Runtime Object 전체 생명주기와 저장 계약을 이 문서에서 완성하지 않는다.
- Scene Streaming의 로드 우선순위와 클라이언트 Ready Protocol을 이 문서에서 확정하지 않는다.
- Editor Tool의 정확한 버튼 배치와 조작법을 정의하지 않는다.
- Compiler Provider가 임의 코드를 실행하는 일반 Plugin Sandbox를 제공하지 않는다.
