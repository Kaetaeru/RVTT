# Main System Guide: Scene Editor와 Authoring

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 DM이 Roblox Studio나 내부 Runtime 자료구조를 직접 다루지 않고 RVTT 안에서 Scene을 만들고, 벽·바닥·문·계단·프리팹·조명·규칙 영역을 배치하며, 검증된 Scene Runtime을 생성·검토·게시하고, 필요할 때 활성 세션에 안전하게 적용하는 전체 Authoring 흐름을 설명한다.

핵심 사용자 결과:

- Scene Editor는 `DM_ONLY` Authoring Overlay이며 Exploration·Encounter·Downtime과 같은 Base Play Mode가 아니다.
- DM Authoring Overlay가 열려 있어도 다른 참가자의 Base Mode 자체는 바뀌지 않는다.
- 구조 편집처럼 플레이와 충돌하는 작업은 Pause Gate 또는 안전한 Build Migration Transition을 사용한다.
- DM이 저장하는 유일한 Scene 저작 원본은 Scene Source다.
- Roblox Workspace Instance, 생성된 Part 묶음, Compiled Polygon·Graph·Index와 Compiler Cache를 Scene 저작 원본으로 사용하지 않는다.
- Scene Source, 불변 Compiled Runtime Scene Build, 플레이 중 Authoritative Dynamic State와 Client Presentation을 분리한다.
- Editor 입력은 Scene Source 변경 Command를 만들며 Navigation·Visibility·Interaction·Rule Runtime Layer를 직접 수정하지 않는다.
- 배치 전 Preview·Ghost·가상 격자·ViewY·드래그 상태는 Client 로컬 표시이고 서버 권위 변경이 아니다.
- 실제 편집은 서버가 권한, Source Revision, Object Reference, 도구 Schema, 크기·개수 한도와 충돌을 검증한 Authoring Command로만 확정한다.
- 한 번의 사용자 작업은 여러 시각 Part를 만들더라도 하나의 Authoring Transaction과 편집 이력 항목으로 기록된다.
- Authoring Undo·Redo는 Scene Source 편집 이력이며 Encounter Rollback이나 Gameplay 결과 역연산과 동일하지 않다.
- 벽·방·계단·도로 같은 파라메트릭 결과는 버전이 있는 Source Object와 원본 Parameter를 유지해 다시 편집할 수 있다.
- Scene Object Identity는 Roblox Instance 이름이나 배열 순서가 아니라 안정적인 Source ID를 사용한다.
- 복제는 새 Source Object ID를 만들고, 동일 논리 오브젝트의 이동·회전·Parameter 수정은 기존 ID를 유지한다.
- Tool Module은 공통 Placement·Snap·Selection·Input·Inspector·Command·History 서비스를 재구현하지 않는다.
- 새 Tool을 추가할 때 중앙 거대 분기문을 늘리지 않고 Registry, Capability와 버전이 있는 Module 계약을 사용한다.
- Tool Module은 물리 키, RemoteEvent와 Workspace 권위 변경을 직접 소유하지 않는다.
- Tool Module이 생성한 Source Data는 Module ID, Object Type과 Schema Version을 보존하고 호환 가능한 Migration을 제공한다.
- 누락되거나 호환되지 않는 Tool Module Data를 조용히 삭제하지 않고 원본을 보존한 채 읽기 전용 대체 표시·경고·게시 Gate를 적용한다.
- 기본 제작은 선택 모드와 연속 배치 모드로 구분한다.
- 에셋·도구·복제본·청사진을 선택하면 상시 가상 격자 커서에 Ghost가 붙고, 명시적으로 종료할 때까지 같은 대상을 연속 배치할 수 있다.
- Shift는 현재 조작의 Snap만 일시 해제하며 저장된 Snap 설정을 바꾸지 않는다.
- ViewY는 사용자별 로컬 표시·Pointer Filter이며 Scene Source, Visibility Rule, Collision과 다른 사용자의 화면을 바꾸지 않는다.
- Ctrl 수직 이동은 현재 배치 Cursor·Ghost·가상 작업 평면의 높이를 조절하며 전역 Scene 높이 설정이 아니다.
- Editor는 `5 ft = 4 studs`의 공통 월드 비율을 사용하고 규칙 거리는 feet, 월드 경계는 중앙 환산 기준을 사용한다.
- 일반 Asset의 규칙 의미는 Model 이름·색상·임의 Attribute가 아니라 Asset Semantic Profile, Scene Override, Region과 Explicit Link에서 온다.
- DM은 Runtime Polygon, A* Node, Portal 폭과 Actor별 Clearance를 직접 편집하지 않고 의미 있는 오브젝트와 예외만 지정한다.
- Scene Compiler는 Source를 정규화해 Navigation·Visibility·Interaction·Rule·Permission Metadata Layer, Runtime Object Blueprint, State Binding, Spatial Index, Chunk와 Disclosure Segment를 하나의 Candidate Build로 만든다.
- 부분 Compile은 내부 최적화일 뿐 게시 결과는 항상 완전한 Build Manifest를 가진다.
- 같은 Source Revision과 Compiler Version Set의 전체 Compile과 부분 Compile 조립 결과는 같은 의미와 Content Hash를 가져야 한다.
- Cross-layer State Binding이 일치하지 않거나 Entry Anchor·Critical Route·Disclosure·Chunk·Index 검사가 실패하면 게시를 차단한다.
- Candidate Build 실패는 현재 Published Build와 활성 세션을 손상시키지 않는다.
- Scene은 Last Known Good Build를 유지하며 실패한 Candidate의 일부 Layer를 활성 Runtime에 섞지 않는다.
- 게시할 때 모든 필수 Layer와 Index를 검증하고 봉인된 Build Manifest와 Published Build Pointer를 원자적으로 교체한다.
- Candidate Build는 실제 Campaign State를 변경하지 않는 격리된 Test Play에서 Entry·Movement·Door·Visibility·Interaction·Trigger·Exit 흐름을 검증할 수 있다.
- 새 Build를 게시해도 실행 중 세션에 자동 적용하지 않는다.
- 활성 세션은 `sceneId + buildId + dynamicStateRevision`에 고정된다.
- 구조적 Live Patch는 호환성, 안전 Checkpoint 또는 Pause, Dynamic State Rebase와 Client 재투영을 확인한 뒤 완전한 Build 단위로 교체한다.
- Live Patch가 실패하면 이전 Build를 복구하고 혼합 Build 상태를 남기지 않는다.
- 플레이 중 문 열기, Actor 이동, 함정 발동과 오브젝트 상태 변경은 Authoring Source 수정이 아니라 Runtime Command와 Dynamic State 변경이다.
- 임시 차단·위험 지역·조명·Trigger 같은 Runtime Quick Edit는 Runtime Semantic Overlay로 처리하고 Scene Source에 자동 반영하지 않는다.
- Quick Edit를 영구 Scene 요소로 남길 때만 `Source로 승격`하여 저장 가능한 Authoring Data와 새 Source ID를 만들고 새 Candidate Build를 요구한다.
- Runtime State를 그대로 직렬화해 Scene Source에 복사하지 않는다.
- Scene Lighting Profile, Local Light와 Environment Volume은 Authoring Source로 저장하고 Roblox Lighting Instance를 권위 원본으로 사용하지 않는다.
- 시각 조명과 D&D 규칙 조명 범위를 분리해 시각 품질 조정이 규칙 판정을 우연히 변경하지 않게 한다.
- DM Workspace의 Live DM Mode와 Full Scene Edit는 같은 Panel Component를 재사용할 수 있지만 허용되는 Command와 Pause·Authoring Gate가 다르다.
- Compiler Diagnostic은 내부 Node 번호가 아니라 관련 Source Object, World Bounds, 원인과 의미 있는 수정 선택지를 제공한다.
- Tool·Compiler Provider 하나의 오류는 해당 Tool 작업이나 Candidate Build로 격리되고 다른 Editor Tool과 현재 Published Runtime은 가능한 범위에서 유지된다.
- Auto Save는 Scene Source Draft를 보존하지만 자동 저장이 곧 Publish나 활성 세션 Build 교체를 의미하지 않는다.
- 재접속·Server Recovery 후 마지막 검증된 Scene Source와 Published Build Pointer를 복구하고 재생성 가능한 Build·Index·Cache는 Source에서 다시 만든다.
- Rollback은 Authoring History와 Encounter Branch를 자동으로 동일하게 되돌리지 않는다. 현재 Branch에 적용되는 Runtime Object·Dynamic State와 Authoring Source Revision을 각각의 권위 수명주기로 처리한다.
- Player와 Observer는 권한에 맞는 Published Runtime Projection만 받으며 Scene Source, Secret Metadata, Compiler Diagnostic과 DM Authoring Preview를 받지 않는다.

적용 범위:

- Scene Record, Scene Source Manifest와 Authoring Revision
- Placed Object, Parametric Object, Semantic Region, Explicit Link와 Entry·Exit Anchor
- Asset Semantic Profile, Scene Instance Override와 Source Pack Dependency
- Editor 선택 모드, 배치 모드, ViewY, Placement Cursor, Snap, Ghost와 Gizmo
- Inspector, Eyedropper, Duplicate, Blueprint, Group, Lock, Paint와 Measurement
- Tool Module Registry, Capability, Client Controller, Command Definition과 Object Type
- Source Object Schema Version, Migration, Missing Module과 Read-only Fallback
- SceneCommandBus, EditHistory, Authoring Transaction, Undo·Redo와 Auto Save
- Scene Compiler Pipeline, Normalized Semantic Contribution와 Provider
- Candidate Build, Dependency Graph, Partial Compile와 Determinism
- Cross-layer Validation, Diagnostic, Review Queue, Critical Route와 Disclosure Gate
- Test Play, Ready Candidate, Atomic Publish와 Last Known Good Build
- Active Session Build Pinning, Compatibility, Build Migration과 Live Patch
- Runtime Quick Edit, Runtime Semantic Overlay와 Source Promotion
- Scene Lighting Profile, Local Light, Environment Volume와 Authoring UI
- DM Workspace, Quick Action과 Scene Editor UI의 공통 Client Runtime 경계
- Permission, Persistence, Recovery, Diagnostics와 Deterministic Validation

명시적 비범위:

- Runtime Spatial Query, Path Search, Movement Execution과 Streaming Protocol의 내부 구현
- Character, Encounter, Effect, Item과 Runtime Object Gameplay State의 규칙 해결
- Scene Editor를 정밀 3D Modeling·Sculpting·Animation 제작 프로그램으로 만드는 기능
- 사용자가 임의 Luau Tool·Compiler Provider를 업로드하고 실행하는 Plugin Sandbox
- 모든 장소를 하나의 Seamless World로 합치는 기능
- 최종 Roblox Module 경로, Luau Type, Remote와 Persistence Schema
- 기본 Snap 간격, Build Queue 수, Cache 크기, Diagnostic Page 크기와 Live Patch Timeout의 측정 전 기본값
- 최종 UI Pixel Layout, Icon Asset와 Animation Curve
- Runtime Quick Edit를 자동으로 영구 Source에 반영하는 기능
- Compiler Artifact를 장기 Authoring 원본으로 보존하는 구조
- 음악, NPC 대화 시스템과 모든 규칙 효과음

## 2. 전체 구조

### Authoring 입력과 Source 변경

```text
DM Authoring Overlay
→ Selection 또는 Placement Tool
→ Local Cursor·Snap·Ghost·Inspector Preview
→ Tool Command
→ Server Permission·Schema·Revision·Reference Validation
→ Authoring Transaction
→ Scene Source Revision Commit
→ Edit History·Auto Save·Projection
```

### Compiler와 게시

```text
Scene Source Revision
+ Asset Semantic Profile
+ Content Pack Definition
+ Scene Override·Region·Explicit Link
→ Source Validation·Migration
→ Semantic Normalization
→ Layer·Blueprint·State Binding·Index Build
→ Cross-layer·Critical Route·Disclosure Validation
→ Immutable Candidate Build
→ Test Play·Review
→ Build Manifest Seal
→ Atomic Published Build Pointer Swap
```

### 활성 세션 적용

```text
Published Build
→ 새 Session은 해당 Build로 시작

실행 중 Session
→ 기존 Build에 고정
→ 명시적 Live Patch Proposal
→ Compatibility·Checkpoint·Dynamic State Rebase
→ Build Migration Transaction
→ Projection·Streaming·Presentation 재동기화
→ 성공 시 새 Build / 실패 시 이전 Build
```

### Runtime Quick Edit

```text
DM Live Command
→ Runtime Semantic Overlay·Dynamic State
→ 즉시 Runtime Snapshot 반영

영구화 선택
→ Source Promotion Adapter
→ 새 Source Object·Revision
→ 새 Candidate Build 필요
```

## 3. 주요 데이터 흐름

### 3.1 Scene Source와 Build

```text
SceneSourceManifest
├─ sceneId·sourceSchemaVersion·authoringRevision
├─ coordinateSystemRef·worldScaleRef
├─ sourcePackDependencies
├─ placedObjectSources
├─ parametricObjectSources
├─ semanticRegionSources
├─ explicitLinkSources
├─ entryAnchorSources·criticalRouteDefinitions
├─ sceneSettings·metadata
└─ sourceChunkManifest·sourceContentHash

→ SceneCompiler

CompiledRuntimeSceneBuild
├─ sceneId·buildId·sourceRevision·contentHash
├─ compilerVersionSet·providerVersionSet
├─ layerManifest
├─ runtimeObjectBlueprintTable·stateBindingTable
├─ anchorRegistry·spatialIndexManifest
├─ dependencyGraph·disclosureSegmentManifest
├─ chunkManifest·diagnosticSummary
└─ buildContentHash
```

Scene Source는 영구 저작 원본이고 Build는 특정 Source와 Version Set에서 다시 생성할 수 있는 불변 파생 Package다.

### 3.2 Source Object Identity

```text
PlacedSceneObjectSource
→ stable sceneObjectId + assetDefinitionRef + transform + overrides

ParametricSceneObjectSource
→ stable sceneObjectId + toolDefinitionId + toolSchemaVersion + parameters

SemanticRegionSource
→ 의미 예외의 공간 Authoring Data

ExplicitLinkSource
→ Object·Anchor·Region 사이 타입 있는 의미 연결
```

Object를 이동하거나 Parameter를 바꿔도 같은 논리 오브젝트라면 ID를 유지한다. Duplicate·Blueprint 배치는 새 ID 집합을 만든다.

### 3.3 Tool Module 데이터

```text
Tool Definition
├─ globally unique module ID·version
├─ category·display metadata
├─ required capabilities·dependencies
├─ client controller
├─ server command definitions
├─ object type definitions
├─ inspector·panel declarations
└─ optional recommendation·snap providers

Source Object
├─ typeId
├─ schemaVersion
├─ ownerModule
└─ validated parameters
```

Editor Core가 Selection, Placement, Snap, ViewY, Preview, Input Context, Inspector Host, Command Bus와 History를 소유한다. Module은 자신의 도형·Parameter·Semantic Contribution만 제공한다.

### 3.4 로컬 Editor 상태와 권위 상태

```text
Local Editor State
├─ ViewY
├─ current tool·selection mode
├─ placement cursor·virtual plane height
├─ ghost·drag preview·gizmo hover
├─ panel layout·inspector focus
└─ unsent parameter draft

Authority-bound Authoring State
├─ Scene Source Revision
├─ Source Object·Group·Lock metadata
├─ Tool Command result
├─ Edit History revision
├─ Build status·diagnostic
└─ Published Build pointer
```

Local Preview가 유실돼도 Scene Source는 유지된다. 권위 Source 변경은 Projection으로 다시 받아 UI를 Reconcile한다.

### 3.5 Semantic Contribution와 Runtime Layer

```text
Source Object·Region·Profile·Override
→ NormalizedSemanticContribution
→ navigation | visibility | interaction | rule | permission_metadata
→ Runtime Object Blueprint·State Binding·Index·Chunk
```

각 Artifact는 Source Lineage와 Dependency를 가져 Diagnostic 위치 이동, Partial Compile, Build Diff와 Provider 오류 격리에 사용한다.

### 3.6 Build 상태

```text
draft
→ runtime_outdated
→ building
→ review_recommended
→ ready_to_publish
→ published

실패: build_failed
```

Architecture 내부 Build Lifecycle의 `draft_source`, `compile_queued`, `resolving`, `normalizing`, `building_layers`, `validating`, `ready`, `published`, `superseded`는 사용자 표시 상태를 세분화하는 내부 진행 단계다.

### 3.7 Authoring Revision, Build와 Dynamic State Revision

```text
Authoring Revision
→ Scene Source 변경

Build ID
→ 특정 Source·Compiler Version의 불변 Runtime Package

Dynamic State Revision
→ 플레이 중 문·Actor·Effect·Runtime Object 상태 변경

Snapshot ID
→ 특정 Build와 Dynamic State를 결합한 조회 시점
```

네 값을 하나의 `sceneRevision`으로 합치지 않는다.

### 3.8 Lighting Authoring

```text
SceneLightingProfile
+ LocalLightObject
+ EnvironmentVolume
→ Scene Source
→ Compiled Visual·Rule Contributions
→ Published Runtime·Presentation
```

시각용 Light와 규칙용 Light Volume을 분리하며 Tween 중간값을 저작 원본으로 저장하지 않는다.

## 4. 주요 실행 흐름

### 4.1 Scene 생성과 Editor 진입

```text
Create Scene Intent
→ Campaign·DM Permission 검증
→ Stable sceneId·Source Schema·기본 Entry Anchor 생성
→ Authoring Revision Commit
→ DM Authoring Overlay 활성화
→ Scene Source Projection·Tool Registry 준비
→ Selection Mode와 Placement Cursor 활성화
```

빈 Scene도 ID와 Version이 있는 Source다.

### 4.2 배치 작업

```text
Tool·Asset·Blueprint 선택
→ Placement Mode
→ Pointer Query + ViewY Filter
→ Surface-first Cursor 또는 Virtual Plane
→ Snap·Shift Bypass·Ctrl Elevation
→ Local Ghost·Semantic Preview
→ Click·Drag·Confirm
→ Tool Command 제출
→ Server Validation
→ Source Object 생성·Authoring Revision 증가
→ History 한 항목 Commit
→ Projection Reconciliation
→ 다음 Ghost 유지
```

배치가 한 번 끝나도 자동으로 Selection Mode로 돌아가지 않는다.

### 4.3 기존 Object 편집

```text
Selection Mode
→ Object 또는 3D Box Selection
→ Gizmo·Inspector·Parametric Handle
→ Local Preview
→ Update Tool Command
→ expected Source Revision·Object Revision 검증
→ Authoring Transaction
→ Source Commit·Dependency invalidation
→ UI Reconcile
```

ViewY 위 Object는 현재 사용자의 Pointer 후보에서 제외하지만 Source에서 삭제하거나 서버 Collision을 끄지 않는다.

### 4.4 Eyedropper·Duplicate·Blueprint

```text
Source Object 선택
→ 배치 가능한 Definition·Parameter 추출
→ 새 Placement Ghost
→ 사용자 배치 확정
→ 새 Source Object ID 생성
```

Blueprint는 내부 Source Object·Link·상대 Transform을 보존하며 배치 후에도 개별 요소를 다시 편집할 수 있다.

### 4.5 Tool 등록과 활성화

```text
Tool Module Package 발견
→ Definition·ID·Version·Capability·Dependency 검증
→ Tool Registry 등록
→ Palette·Inspector·Panel Host 자동 노출
→ 사용자 활성화
→ Context 주입·Input Context 획득
→ begin/update/confirm/cancel/deactivate Lifecycle
```

도구 전환·오류·종료 시 Event Connection, Ghost, Input Context와 Render Hook을 정리한다.

### 4.6 Tool Command와 Undo·Redo

```text
Local Preview
→ Tool Command
→ DM Permission·Schema·Reference·Limit·Revision 검증
→ SceneCommandBus
→ 하나의 Authoring Transaction
→ Source Mutation + History Record
→ Projection
```

Undo·Redo도 공통 History와 현재 Source Revision 검증을 사용한다. Tool이 Workspace를 직접 복구하거나 임의 Remote를 호출하지 않는다.

### 4.7 Source Data Migration

```text
Scene Source Load
→ sourceSchemaVersion·Tool Object schemaVersion 확인
→ 등록된 Migration Chain 실행
→ 멱등성·Reference 보존 검증
→ Candidate Migrated Source
→ Commit 또는 원본 유지·Read-only Fallback
```

Migration이 없거나 실패하면 원본 Payload를 보존하고 게시를 차단하거나 명시적 복구 선택지를 제공한다.

### 4.8 Runtime 생성

```text
Scene Runtime 만들기
→ Source Auto Save·Revision 고정
→ Asset·Profile·Pack Reference 해결
→ Parametric Source 확장
→ Semantic Contribution 정규화
→ Layer Builder·Blueprint·State Binding
→ Index·Dependency Graph·Chunk 생성
→ Cross-layer Validation
→ Critical Route·Entry·Disclosure 검사
→ Candidate Build
```

Compiler는 Editor Tool Controller를 실행하지 않는다. 저장된 Parametric Source는 등록된 Source Expander·Provider를 통해 정규화한다.

### 4.9 Diagnostic과 Review

```text
Compiler Diagnostic 선택
→ Source Lineage와 World Bounds Resolve
→ CameraRequest
→ 관련 Object 선택·Inspector 열기
→ 원인·Severity·게시 차단 여부 표시
→ 제안된 의미 수정 Command 선택
```

안전한 Geometry 보정만 자동화할 수 있으며, 의미가 불명확한 계단·문·물·비밀 통로를 임의로 해석하지 않는다.

### 4.10 Test Play

```text
Ready Candidate Build
→ 격리 Test Runtime
→ Entry Anchor 배치
→ 대표 Body Profile 이동·Door·Visibility·Interaction·Trigger 검사
→ Exit·Critical Route 확인
→ Test Dynamic State 폐기
→ Diagnostic·Review Result만 Authoring 화면에 반환
```

Test 결과를 실제 Campaign State에 반영하려면 별도의 명시적 Authoring 또는 Gameplay Command가 필요하다.

### 4.11 Publish

```text
Ready Candidate 선택
→ 현재 Source·Candidate Revision 검증
→ 필수 Layer·State Binding·Index·Entry·Route·Disclosure·Chunk 재검증
→ Manifest Seal
→ Published Build Pointer 원자 교체
→ Scene 상태 published
→ 새 Session 기본 Build 갱신
```

Navigation, Visibility와 Interaction을 서로 다른 Build Revision으로 게시하지 않는다.

### 4.12 활성 세션 Live Patch

```text
새 Published Build
→ Live Patch Proposal
→ 현재 Session Build·Dynamic State·Runtime Object Binding 확인
→ Compatibility·Rebase Plan
→ 안전 Checkpoint 또는 Pause Gate
→ Build Migration Transaction
→ Runtime Object Rebind·Index·Projection·Streaming 재구성
→ Client Ready
→ 새 Build 활성화
```

어느 단계든 실패하면 이전 Build·Snapshot으로 복구하고 일반 Gameplay 입력을 안전하게 재개한다.

### 4.13 Runtime Quick Edit

```text
Live DM Mode
→ Quick Action·Runtime Edit Intent
→ Runtime Permission·현재 Revision 검증
→ Runtime Command
→ Dynamic State 또는 Runtime Semantic Overlay Commit
→ Snapshot·Projection 갱신
```

Quick Edit는 Authoring History와 Source Revision을 자동으로 변경하지 않는다.

### 4.14 Source로 승격

```text
Runtime Overlay 선택
→ Source Promotion 가능성 검증
→ 저장 가능한 Tool·Source Object Parameter로 변환
→ 새 Source Object ID
→ Authoring Transaction
→ Source Revision 증가
→ Candidate Build Outdated 표시
```

현재 Runtime Object·Dynamic State를 그대로 Source Payload로 복사하지 않는다.

### 4.15 Auto Save·Build 실패·Recovery

```text
Source Draft Auto Save
→ Source Revision·Chunk 저장
→ Compile은 별도 Queue

Candidate 실패
→ Published Build 유지
→ 실패 Artifact 폐기·Diagnostic 표시

Server Recovery
→ 마지막 검증 Source·Published Pointer 복구
→ Build·Index 유실 시 Source에서 재생성
→ 활성 Session은 검증된 Build·Dynamic State로 복구
```

### 4.16 Scene 보관과 삭제

```text
active
→ archived
→ pending_deletion
→ deleted
```

다른 Scene Transition, Campaign 기본 Scene, Character 위치, Journal Anchor, 활성 Session과 Snapshot 참조가 있으면 삭제 전 검증·경고한다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Source·Build·State·Projection과 Roblox Instance 권위 분리
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — DM Authoring Overlay, Pause Gate와 Build Migration Transition
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Revision 검증, Ordering, Reservation과 원자 Commit
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md) — Source·Manifest·Chunk 저장, Restart와 AuthorityEpoch Recovery
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Editor Panel·Input Context·Intent·Pending·Recovery 공통 Client 경계

### Child Authority

- [`Semantic Scene, World와 Runtime Build 모델`](../../systems/scene/scenes-and-world.md) — Scene Source·Build·Dynamic State, 제작·게시·Live Patch의 사용자 모델
- [`Scene Compiler와 Compiled Runtime Scene 계약`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md) — Source Schema, Compiler Pipeline, Provider, Build Lifecycle와 Atomic Publish
- [`인게임 Scene Editor와 맵 제작 도구`](../../systems/scene/ingame-scene-editor-tools.md) — 선택·배치·벽·바닥·프리팹·조명 등 Editor 도구 동작
- [`확장 가능한 Scene Editor Tool Module 구조`](../../architecture/scene-editor-tool-module-architecture.md) — Tool Registry·Capability·Command·Object Type·Migration·오류 격리
- [`Scene Editor 조작 모드와 창 배치`](../../ui/scene-editor/scene-editor-interaction-and-layout.md) — 선택·연속 배치, Snap, Inspector, Dock·History·Blueprint UI
- [`Semantic Scene 기반 Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md) — Semantic Profile, 예외 Region·Transition, 자동 검사·Critical Route
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md) — Live DM Mode·Full Scene Edit, Lighting Profile·Local Light·Environment Volume
- [`DM Quick Action과 Context Command`](../../ui/dm-workspace/dm-quick-action-and-context-command.md) — Live Runtime Command, Quick Edit와 Authoring 진입 경계

### References

- [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation Guide`](../scene/README.md) — 게시된 Build 이후 Runtime·Streaming·Query·Movement 전체 흐름
- [`UI, Camera와 Presentation Guide`](../ui/README.md) — Editor Panel·Focus·Input·Camera·Error Boundary와 Epoch-safe Recovery
- [`Journal과 Ping Guide`](../journal/README.md) — Scene·Object Journal Anchor와 안전한 Camera Navigation
- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md) — Build Rebind, Runtime Identity·Incarnation과 Lifecycle
- [`Scene Streaming, Client Interest와 Ready Activation`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md) — Live Patch·Scene Transition 이후 Client Ready
- [`Spatial Query Engine과 Provider`](../../architecture/spatial-query-engine-and-provider-contract.md) — Editor Placement Validation과 Compiled Spatial Artifact 소비 경계
- [`Runtime Navigation Path Planning과 Movement Execution`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md) — 게시 후 Traversal Domain·Movement 권위
- [`Diagnostics와 Observability Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — Tool·Compiler·Publish·Patch Trace와 Redaction
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — Compiler 결정성, Migration, Disclosure와 Live Patch 검증
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Build Migration·Runtime Object Rebind·Projection Barrier 통합

권위 읽기 순서에서 제외:

- `archive/` 아래 이전 Editor 설계와 폐기된 이동·Attribute 관례
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 상태의 Scene·Navigation·UI 문서
- 구형 `Walkable`, `Deniable`, `DifficultTerrain` Attribute 기반 규칙 해석

역사 문서가 현재 Source·Compiler·Tool 문서를 참조하더라도 최신 권위로 되돌아오지 않는다.

## 6. 다른 시스템과의 경계

| 인접 시스템 | Scene Editor·Authoring이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Session | DM Authoring Overlay, Pause·Build Migration 요청 | Base Mode, Overlay·Transition과 Effective Command Gate | Session Mode 계약 |
| Scene Runtime | Scene Source, Published Build와 Live Patch Proposal | Runtime Object·Dynamic State·Snapshot·Build Rebind | Scene Compiler, Runtime Object, Scene Guide |
| Asset·Content Pack | 배치 Instance·Profile Override·Dependency Reference | Asset Definition, Semantic Profile와 Version | Scene Compiler, Navigation Authoring, 후속 Extension Guide |
| Navigation | Semantic Object·Region·Transition·Critical Route Source | Traversal Domain, Runtime Plan·Execution과 검사 Provider | Navigation Authoring, Runtime Navigation |
| Visibility·Interaction·Rules | Source Contribution·State Binding·Disclosure Policy | 관찰자별 결과, Command 적격성·RuleExecution | Scene Compiler, Visibility·Interaction·Rules Runtime |
| UI | Editor Projection, Tool·Build·Diagnostic View와 Intent | Panel·ViewModel·Input Context·Focus·Pending Reconciliation | UI Runtime, Scene Editor UI |
| Camera | Diagnostic·Selection·Bookmark Focus Request | Camera Policy, Target Projection와 Restoration | Camera Runtime, UI Guide |
| DM Workspace | Scene·Asset·Inspector·Lighting·Quick Action Surface | 공통 Dock Layout, Live Command와 Override UI | DM Workspace 문서, UI Runtime |
| Persistence | Scene Source·Revision·Published Pointer·Migration Data | Snapshot·Chunk·Journal·Restart Recovery | Persistence 계약, Scene Compiler |
| Runtime Quick Edit | Source Promotion Adapter와 영구 Authoring 경계 | Dynamic State·Runtime Semantic Overlay Command | Scenes and World, Session 계약 |
| Journal | 안정적 Scene·Source Object Identity | Permission-aware Anchor·Search·Navigation | Journal Runtime, Journal Guide |
| Diagnostics | Source Lineage·Tool·Build·Publish Context | Trace·Incident·Budget·Sanitized Support Surface | Diagnostics Runtime |
| Simulation | Fixture Source·Candidate Build·Expected Diagnostic | Deterministic Compiler·Patch·Failure·Disclosure Harness | Simulation Runtime |
| Extension | Tool·Compiler Provider 등록점과 Version 요구 | 신뢰된 Module·Content Pack 배포·Capability 정책 | Tool Module·Compiler 계약, 후속 Extension Guide |

고정 경계:

- Editor Core와 Tool Module은 Dynamic Gameplay Store를 직접 수정하지 않는다.
- Runtime Domain은 Local Ghost, ViewY, Camera와 Panel 상태를 권위 입력으로 사용하지 않는다.
- Tool Module은 RemoteEvent, Workspace Mutation, InputService와 전역 Service Locator를 직접 소유하지 않는다.
- Compiler Provider는 Scene Source와 Authoritative Dynamic State를 직접 수정하지 않는다.
- Published Build와 활성 세션 Build를 동일시하지 않는다.
- Quick Edit와 Source Authoring을 하나의 Transaction에 섞지 않는다.
- Build 실패·Tool 오류·Presentation 실패가 현재 Published Runtime을 손상시키지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
   - Source·Build·State·Projection과 Roblox Instance의 공통 권위 경계를 먼저 확인한다.
2. [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md)
   - Canonical Scene Source, 불변 Build, Atomic Publish와 Live Patch 결정을 읽는다.
3. [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
   - Authoring이 Base Mode가 아니라 Overlay이며 Pause·Migration Gate를 사용함을 확인한다.
4. [`Semantic Scene, World와 Runtime Build`](../../systems/scene/scenes-and-world.md)
   - DM 관점의 Scene 생성·Build·게시·활성 세션 흐름을 읽는다.
5. [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
   - Source Schema, Compiler Pipeline, Layer·Index·Diagnostic와 Build Lifecycle을 읽는다.
6. [`인게임 Scene Editor와 맵 제작 도구`](../../systems/scene/ingame-scene-editor-tools.md)
   - 벽·방·문·계단·프리팹·Lighting Authoring 사용자 흐름을 읽는다.
7. [`ADR-0007`](../../decisions/ADR-0007-view-y-and-world-scale.md), [`ADR-0008`](../../decisions/ADR-0008-surface-first-placement-and-ctrl-elevation.md)
   - ViewY, World Scale, Surface-first Cursor와 Ctrl Elevation의 고정 조작을 확인한다.
8. [`Scene Editor UI`](../../ui/scene-editor/scene-editor-interaction-and-layout.md)
   - Selection·Placement, Snap, Inspector, History, Dock와 Blueprint 화면 동작을 읽는다.
9. [`Tool Module Architecture`](../../architecture/scene-editor-tool-module-architecture.md)
   - Registry, Capability, Context Injection, Command, Object Type와 Migration을 읽는다.
10. [`Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md)
    - Semantic Profile·Exception Tool·Critical Route와 자동 검사를 읽는다.
11. [`DM Workspace·Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md)과 [`Quick Action`](../../ui/dm-workspace/dm-quick-action-and-context-command.md)
    - Full Edit와 Live DM Command·Lighting Authoring 경계를 확인한다.
12. [`Scene Runtime Guide`](../scene/README.md)와 [`UI Guide`](../ui/README.md)
    - 게시 이후 Runtime·Streaming·Movement와 공통 Client 흐름을 연결한다.
13. [`Diagnostics`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md), [`Simulation`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md), [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
    - 결정성·실패 격리·Disclosure·Recovery 완료 기준을 확인한다.

## 8. 구현·검증 순서

권위 문서의 의존 관계를 따르면 다음 순서로 내려간다.

```text
Scene Source·Stable ID·Schema·Migration
→ Authoring Command·Revision·History Foundation
→ Editor Core: Input·Selection·Placement·Snap·ViewY·Preview
→ Tool Registry·Capability·Context·Object Type Host
→ 기본 Wall·Floor·Prefab·Door·Stair·Region Tool
→ Inspector·Panel·Blueprint·Lighting Authoring
→ Semantic Profile·Contribution·Compiler Provider
→ Layer·State Binding·Index·Dependency Graph Build
→ Diagnostic·Critical Route·Disclosure Validation
→ Candidate·Test Play·Atomic Publish
→ Runtime Quick Edit·Source Promotion
→ Live Patch·Build Rebase·Client Ready·Recovery
→ Diagnostics·Deterministic Scenario·Performance Audit
```

필수 검증 Scenario:

- 같은 Source Revision과 Version Set에서 반복 Build Hash 일치
- Partial Compile과 Full Compile 결과 동일성
- Build 실패 후 Published Build·활성 세션 유지
- Navigation·Visibility·Interaction 혼합 Revision 게시 차단
- Secret Object·Source Lineage의 Player Disclosure 차단
- Stable Source Object ID의 Move·Rename 유지와 Duplicate 새 ID
- Tool Module 등록·Dependency·Capability·ID 충돌 거부
- Tool Deactivate·오류 후 Ghost·Input Context·Connection 정리
- Client가 조작한 Transform·Object Count·Asset Ref·Revision 거부
- Undo·Redo와 Auto Save 이후 Source 일관성
- Tool Object Schema Migration 성공·실패·Missing Module Fallback
- ViewY가 Source·Collision·다른 Client에 영향을 주지 않음
- Shift Snap Bypass와 Ctrl Elevation의 Local Preview·Server Validation
- Critical Route·Entry Anchor·State Binding·Chunk·Disclosure Publish Gate
- Candidate Test Play가 Campaign Dynamic State를 변경하지 않음
- Publish Pointer 원자 교체와 Last Known Good 복구
- 새 Published Build가 활성 Session에 자동 적용되지 않음
- Live Patch 중 Dynamic State Rebase 실패와 이전 Build 복원
- Runtime Quick Edit가 Source Revision을 자동 변경하지 않음
- Source Promotion이 새 Source ID와 Candidate Build를 요구함
- Reconnect·Restart 후 Source Draft·Published Pointer·History·Tool Data 복구
- Player·Observer가 Authoring Source·Diagnostic·Secret Metadata를 받지 않음
- 대형 Scene에서 Tool·Compiler·UI Budget과 Error Isolation

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Scene Source·Object Schema | Scenes and World, Scene Compiler, Tool Module, Persistence | 향후 Scene Source·Migration Specs | `UPDATE_REQUIRED` |
| Tool Registry·Capability·Lifecycle | Tool Module Architecture, UI Runtime, Common Input | 향후 Editor Core·Tool Host Specs | `UPDATE_REQUIRED` |
| Placement·ViewY·Snap 입력 | ADR-0007·0008, Editor Tools, Scene Editor UI, Camera·UI Runtime | 향후 Placement·Pointer Specs | `UPDATE_REQUIRED` |
| Authoring Command·History·Revision | Tool Module, Transaction, Networking, Persistence | 향후 Authoring Command·History Specs | `UPDATE_REQUIRED` |
| Semantic Profile·Compiler Provider | Scene Compiler, Navigation Authoring, Extension 계약 | 향후 Semantic Compiler Specs | `UPDATE_REQUIRED` |
| Build Manifest·Validation·Publish | Scene Compiler, ADR-0057, Scenes and World | 향후 Build·Publish Specs | `UPDATE_REQUIRED` |
| Live Patch·Build Rebase | Scene Compiler, Runtime Object, Session Transition, Streaming | 향후 Build Migration Specs | `UPDATE_REQUIRED` |
| Runtime Quick Edit·Source Promotion | Scenes and World, Session, DM Quick Action | 향후 Runtime Overlay·Promotion Specs | `UPDATE_REQUIRED` |
| Lighting Source·Rule Binding | DM Workspace·Lighting, Scene Compiler, Visibility·Effect | 향후 Lighting Authoring Specs | `UPDATE_REQUIRED` |
| Permission·Disclosure | Scene Compiler, Visibility, Networking, UI | 향후 Disclosure·Projection Specs | `UPDATE_REQUIRED` |
| Cache·Queue·Snap·Timeout 기본값 | 각 문서의 `READY_WITH_DEFAULTS` 항목 | Operational·Performance Specs | 의미 변화가 있을 때만 갱신 |
| ADR·Lifecycle 상태 변경 | 해당 ADR, Document Lifecycle, Completion Audit | 모든 영향 Spec | `UPDATE_REQUIRED` |

## 10. Authority Documents

### Product

- [`핵심 세션 흐름과 플레이 모드`](../../product/core-session-loop.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`확장 가능한 Scene Editor Tool Module 구조`](../../architecture/scene-editor-tool-module-architecture.md)
- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Streaming, Client Interest와 Ready Activation`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Spatial Query Engine과 Provider`](../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation Path Planning과 Movement Execution`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Diagnostics와 Observability Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)

### Systems·UI

- [`Scene 시스템`](../../systems/scene/README.md)
- [`Semantic Scene, World와 Runtime Build`](../../systems/scene/scenes-and-world.md)
- [`인게임 Scene Editor와 맵 제작 도구`](../../systems/scene/ingame-scene-editor-tools.md)
- [`Semantic Scene 기반 Navigation Authoring Pipeline`](../../systems/navigation/navigation-authoring-pipeline.md)
- [`Scene Editor UI`](../../ui/scene-editor/README.md)
- [`Scene Editor 조작 모드와 창 배치`](../../ui/scene-editor/scene-editor-interaction-and-layout.md)
- [`Common Input`](../../ui/common-input/README.md)
- [`DM Workspace`](../../ui/dm-workspace/README.md)
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md)
- [`DM Quick Action과 Context Command`](../../ui/dm-workspace/dm-quick-action-and-context-command.md)

### Specs

- [`Implementation Specs Index`](../../specs/README.md)
- Scene Editor·Authoring 전용 Specs: Main System Guide 단계 이후 작성 예정

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0005`](../../decisions/ADR-0005-performance-reliability-clean-code.md) — 성능·안정성·오류 격리와 유지보수성을 완료 조건으로 사용
- [`ADR-0006`](../../decisions/ADR-0006-rigless-3d-token-continuous-movement.md) — 연속 3D 월드와 리그 없는 토큰에 맞는 Scene Authoring
- [`ADR-0007`](../../decisions/ADR-0007-view-y-and-world-scale.md) — 연속 높이 ViewY와 `5 ft = 4 studs`
- [`ADR-0008`](../../decisions/ADR-0008-surface-first-placement-and-ctrl-elevation.md) — 상시 가상 격자 Cursor, Surface-first Placement와 Ctrl 높이 조절
- [`ADR-0045`](../../decisions/ADR-0045-dm-workspace-and-scene-lighting-authoring.md) — DM Workspace, Full Scene Edit와 Lighting Authoring
- [`ADR-0047`](../../decisions/ADR-0047-contextual-dm-quick-actions-and-safe-command-execution.md) — Context Quick Action과 안전한 Command 실행
- [`ADR-0054`](../../decisions/ADR-0054-compiled-semantic-runtime-and-query-authority-principles.md) — Semantic Source를 Compiled Runtime·Query Authority로 변환
- [`ADR-0055`](../../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md) — Snapshot-bound Spatial Query와 타입 있는 공간 경계
- [`ADR-0056`](../../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md) — Authoring 결과를 소비하는 Traversal Domain·Movement 구조
- [`ADR-0057`](../../decisions/ADR-0057-canonical-scene-source-and-atomic-compiled-build-activation.md) — Canonical Scene Source, Immutable Build, Atomic Publish와 Live Patch
- [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md) — Runtime Object Identity·Incarnation·Lifecycle와 Build Rebind
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Authoring Command·Projection Synchronization
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Authoring·Build Migration 원자 Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Source·Build·Snapshot·Recovery 저장 경계
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — DM Authoring Overlay·Pause·Build Migration 분리
- [`ADR-0071`](../../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md) — Editor Input Context와 Selection 경계
- [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md) — Projection 기반 Editor UI와 Recovery
- [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md) — Tool·Compiler·Publish Trace와 Redaction
- [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md) — Production-parity Authoring·Build·Patch 검증

## 12. 알려진 비목표와 측정형 기본값

권위 문서에서 확정된 비목표:

- Scene Source와 Workspace Instance·Compiled Artifact·Dynamic State를 하나의 Record로 합치지 않는다.
- DM에게 Runtime Polygon, A* Node, Portal 폭, BVH·Octree와 내부 Cache 편집을 요구하지 않는다.
- Model 이름·색상·투명도와 임의 Attribute를 규칙 의미의 권위 입력으로 사용하지 않는다.
- Tool Module마다 Selection·Placement·Snap·Input·Inspector·Undo·Save를 재구현하지 않는다.
- Tool Module이 직접 RemoteEvent·Workspace Mutation과 임의 Luau 실행을 소유하지 않는다.
- Candidate Build 일부 Layer를 Published Runtime에 혼합하지 않는다.
- Source Auto Save, Compile Ready, Publish와 Active Session Patch를 같은 상태로 취급하지 않는다.
- 새 Build 게시를 활성 Session에 자동 반영하지 않는다.
- Runtime Quick Edit를 자동으로 Scene Source에 영구화하지 않는다.
- Client ViewY·Ghost·Camera와 Pointer Preview를 Server 권위 입력으로 사용하지 않는다.
- Build·Tool·VFX 실패로 현재 Published Gameplay State를 되돌리지 않는다.

Implementation Spec에서 측정·확정할 기본값:

- 기본 위치·각도·높이 Snap 간격과 정밀 조절
- Placement Cursor Patch 크기와 Preview Update Budget
- Tool·Object·Blueprint별 개수·크기·Payload 상한
- Authoring Auto Save Debounce와 Draft 보존 기간
- Edit History 보존 수·Chunk·압축 정책
- Build Queue 동시 실행 수·취소·시간 Budget
- Partial Compile 영향 Bounds와 Full Rebuild 전환 기준
- Artifact Cache, Last Known Good Build와 Diagnostic 보존 수
- Scene Chunk 목표 크기와 Packaging Budget
- Review Result·Diagnostic Page 크기와 Camera Focus Timeout
- Test Play Fixture와 대표 Body Profile 기본 묶음
- Live Patch Pause·Checkpoint·Client Ready Timeout
- Missing Module·Migration Failure Tombstone 보존 기간
- Tool·Compiler·UI Error Budget와 Performance Threshold

남은 비차단 작업:

- Scene Source·Authoring Command·Editor Core·Tool Host Implementation Specs 작성
- Compiler·Build·Publish·Live Patch 수직 Specs 작성
- 기본 Tool Module별 Source Schema와 Migration Spec 작성
- 위 측정형 기본값의 플레이테스트·프로파일링
- Authoring Deterministic Scenario와 Roblox Integration Suite 구현

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 현재 존재하는 Specs를 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 권위 읽기 순서에서 제외했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
