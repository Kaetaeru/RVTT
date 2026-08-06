# Implementation Spec — Slice 10 Scene Authoring·Compile·Publish

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Scene Source, Editor Tool, Compiler Provider, Prefab Catalog와 Published Runtime 구조가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Guide: [`Scene Editor`](../../../guides/scene-editor/README.md), [`Scene`](../../../guides/scene/README.md), [`UI`](../../../guides/ui/README.md), [`Extension`](../../../guides/extension/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> Scene Source는 Canonical Authoring 원본이고 Workspace Instance는 Preview·Runtime 표현이다. Candidate Build 일부를 Published Runtime과 혼합하지 않으며 Publish는 검증된 Build Pointer를 원자 교체한다.

## 1. Acceptance Flow

```text
Scene Draft 열기
→ Tool 선택
→ Object 배치·수정·삭제
→ Undo·Redo·Auto Save
→ Compile·Diagnostic
→ Candidate Test Play
→ Publish Review
→ Atomic Publish
→ 새 Session에서 Runtime Scene 사용
```

DM은 Build 실패 시 기존 Published Scene을 계속 사용할 수 있고, Player는 Authoring Source·Secret Metadata를 받지 않는다.

## 2. 직접 권위 문서

- [`Scene Compiler와 Compiled Runtime Scene`](../../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Scene Editor Tool Module Architecture`](../../../architecture/scene-editor-tool-module-architecture.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Streaming과 Ready Activation`](../../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
- [`Spatial Query Engine`](../../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Navigation Authoring Pipeline`](../../../systems/navigation/navigation-authoring-pipeline.md)
- [`Runtime Navigation과 Movement Execution`](../../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Command Ordering과 Transaction Coordinator`](../../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Networking Command와 Projection`](../../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`UI Projection·Input·Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Semantic Scene, World와 Runtime Build`](../../../systems/scene/scenes-and-world.md)
- [`인게임 Scene Editor와 맵 제작 도구`](../../../systems/scene/ingame-scene-editor-tools.md)
- [`Scene Editor Interaction과 Layout`](../../../ui/scene-editor/scene-editor-interaction-and-layout.md)

## 3. 범위

포함:

- Scene Source·Stable Object ID·Revision·Schema Migration
- Authoring Command·History·Undo·Redo·Auto Save
- Editor Input·Selection·Placement·Snap·ViewY·Preview
- Tool Registry·Capability·Dependency·Object Schema
- Wall·Floor·Prefab·Door·Stair·Region·Lighting Tool
- Semantic Profile·Compiler Provider·Dependency Graph
- Navigation·Visibility·Interaction·State Binding Build Layer
- Diagnostic·Critical Route·Disclosure Validation
- Candidate Test Play·Atomic Publish·Last Known Good
- Draft·History·Reconnect·Restart

제외:

- 활성 Session 자동 Live Patch
- 범용 3D Modeling·NavMesh 수동 편집
- 공개 사용자 코드 Plugin
- Runtime Quick Edit 영구 Source 승격

## 4. Type와 계층

```lua
export type SceneSource = {
    sceneId: string,
    schemaVersion: number,
    sourceRevision: number,
    sceneMetadata: {[string]: unknown},
    objectRecords: {[string]: SceneSourceObject},
    layerBindings: {[string]: unknown},
    activePublishedBuildRef: string?,
}

export type SceneSourceObject = {
    sourceObjectId: string,
    objectTypeId: string,
    objectSchemaVersion: number,
    transform: {position: {number}, rotation: {number}, scale: {number}},
    semanticProfileRef: string,
    properties: {[string]: unknown},
    lifecycleState: string,
    revision: number,
}

export type CompiledSceneBuild = {
    buildId: string,
    sceneId: string,
    sourceRevision: number,
    compilerVersionSet: {string},
    providerVersionSet: {string},
    objectMapping: {[string]: string},
    artifactManifest: {[string]: unknown},
    diagnosticDigest: string,
    buildHash: string,
}

export type AuthoringCommand = {
    commandId: string,
    sceneId: string,
    baseSourceRevision: number,
    toolRef: string,
    operation: string,
    payload: unknown,
    idempotencyKey: string,
}
```

Source Object ID는 Move·Rename 후 유지되고 Duplicate는 새 ID를 받는다. Runtime Object ID·Incarnation, Compiled Artifact ID와 Dynamic Gameplay State를 Source Object에 복사하지 않는다.

## 5. Editor Core

```text
Pointer·Keyboard
→ Editor Input Context
→ Local Ghost·Preview
→ Authoring Command
→ Permission·Revision·Schema·Budget 검증
→ Source Mutation Transaction
→ Authoring Projection
```

ViewY, Camera, Ghost와 Surface Cursor는 Local Presentation이다. Server는 Transform, Asset Ref, Object Count, Tool Capability와 Source Revision을 재검증한다.

Editor Core가 공통 제공:

- Selection·Multi-selection
- Surface-first Placement
- Position·Angle·Height Snap
- Shift 정밀·Snap Bypass와 Ctrl Elevation
- Move·Rotate·Scale
- Copy·Duplicate·Delete
- Inspector·Property Edit
- Undo·Redo·History
- Auto Save·Draft Recovery

Tool Module이 이를 각각 재구현하지 않는다.

## 6. Tool Registry

```lua
export type ToolDefinition = {
    toolId: string,
    toolVersion: string,
    capabilityRefs: {string},
    objectTypeRefs: {string},
    dependencyRefs: {string},
    parameterSchemaRef: string,
    migrationRefs: {string},
}
```

Tool은 Trusted Registry에서 활성화하고 Editor 시작 전 Version Set을 고정한다. Tool 오류·Deactivate 후 Input Connection, Ghost, Preview와 Selection Token을 정리한다. Source에 임의 Luau Callback을 저장하지 않는다.

기본 Object Tool은 Wall, Floor, Prefab, Door, Stair, Region·Trigger, Lighting Source와 Scene Anchor를 포함한다. 실제 Asset은 Prefab Catalog의 검증된 Stable ID를 사용한다.

## 7. Authoring History와 동시성

```text
Command + base Source Revision
→ Object·Layer Ordering Key
→ Precondition·Capability 검증
→ Source Mutation Plan
→ History Entry
→ Commit
→ Source Projection
```

독립 Object 변경은 병합 가능하지만 같은 Object·Layer·Dependency Graph를 변경하는 충돌은 구조화된 Conflict를 반환한다. Last-write-wins를 기본 사용하지 않는다.

Undo·Redo는 이전 Workspace Snapshot을 복사하지 않고 Versioned Inverse 또는 History Target을 새 Command로 적용한다. 이미 Published된 Build Pointer를 조용히 되돌리지 않는다.

## 8. Semantic Compiler

```text
Canonical Scene Source
→ Schema·Reference Validation
→ Object Type Provider
→ Semantic Contribution
→ Dependency Graph
→ Navigation·Visibility·Interaction·Streaming Layer
→ State Binding·Index
→ Artifact Manifest
→ Candidate Build
```

Compiler 요구:

- 같은 Source Revision·Version Set에서 같은 Build Hash
- Partial Compile과 Full Compile의 의미·Hash 동일성
- Provider Dependency·Version·Cycle 검출
- Missing Module·Migration Failure 구조화
- Source Lineage와 Secret Metadata의 Player Artifact 제외
- Build 실패 시 Active Published Build 유지

DM에게 Runtime Polygon, A* Node, BVH·Octree와 내부 Cache를 직접 편집하게 하지 않는다.

## 9. Diagnostic·Critical Route

Publish Gate 검사:

- Entry Anchor와 필수 Spawn 가능성
- Traversal·Door·Stair·Height 연결
- Scene Essential Chunk와 Streaming Dependency
- Navigation·Visibility·Interaction Layer Version 일치
- State Binding·Object Mapping 무결성
- Secret Object·Source Lineage Disclosure
- Asset·Prefab 접근권과 Missing Dependency
- Object·Chunk·Payload·Memory Budget

Diagnostic은 Source Object·Property·Provider와 Camera Focus Target을 안전하게 연결한다. Player에게 Secret 위치와 Source Metadata를 전송하지 않는다.

## 10. Candidate Test Play와 Publish

```text
Candidate Build
→ 격리된 Test Play Session
→ Production Runtime Path로 Scene Bootstrap
→ Body Profile·Navigation·Interaction·Disclosure Scenario
→ Test Result·Diagnostic
→ DM Review
→ Publish Command
→ Published Build Pointer Atomic Swap
```

Test Play는 Campaign Dynamic State를 변경하지 않는다. Publish 성공은 Source Auto Save·Compile Ready와 별도 상태다. 새로운 Published Build는 활성 Session에 자동 적용되지 않는다.

대표 Command:

- `CreateSceneDraft`
- `ApplyAuthoringCommand`
- `UndoAuthoringChange`
- `CompileSceneCandidate`
- `StartCandidateTestPlay`
- `PublishSceneBuild`
- `ArchiveSceneSourceObject`
- `MigrateSceneSource`

## 11. Persistence·Recovery

저장:

- Scene Source·Object·Layer·Revision
- Authoring History·Draft·Auto Save Pointer
- Tool·Object Schema Version
- Candidate·Published Build Manifest·Pointer
- Compiler·Provider Version Set
- Diagnostic·Test Result Reference

Derived Spatial·Navigation·Search Index와 Workspace Preview는 재생성한다. Restart는 Draft·History·Published Pointer를 복원하고 Candidate의 Commit 상태를 판정한다. Missing Tool Version은 Source를 보존하고 Publish를 차단한다.

Rollback은 Gameplay Branch와 Authoring History를 자동 결합하지 않는다. Published Pointer 복구는 명시적 Publish/Rollback Command다.

## 12. UI·Diagnostics·Security·Test

UI 상태:

```text
Draft 저장 중
Source Revision 충돌
Tool 누락·Migration 필요
Compile 진행·취소
Diagnostic Error·Warning
Candidate Test Play
Publish Review
Published·활성 Session 미적용
Recovery·Last Known Good
```

Trace:

```text
scene.source_command
scene.history
scene.tool_activate
scene.compile
scene.provider
scene.diagnostic
scene.test_play
scene.publish
scene.recover
```

Security:

- Client가 Transform·Asset·Object Count·Revision을 확정하지 못한다.
- Player·Observer가 Source·Tool·Diagnostic·Secret Metadata를 받지 않는다.
- Tool·Provider가 다른 Store·Remote·Workspace를 직접 수정하지 않는다.
- Asset 권리·접근권 없는 Prefab은 Candidate·Release Pack에 포함하지 않는다.

Test:

1. Stable Source Object ID Move·Rename·Duplicate.
2. Authoring Command Conflict·Undo·Redo·Auto Save.
3. Tool Dependency·Capability·ID 충돌 거부.
4. Tool 오류 후 Input·Ghost·Connection 정리.
5. Client Transform·Asset Ref 변조 거부.
6. Partial·Full Compile 결정성.
7. Build 실패와 Published Last Known Good.
8. Navigation·Visibility·Interaction 혼합 Revision Publish 차단.
9. Secret Source Lineage Negative Disclosure.
10. Critical Route·Entry·Chunk Gate.
11. Test Play가 Campaign State 불변.
12. Atomic Publish와 활성 Session 자동 미적용.
13. Restart 후 Draft·History·Pointer 복구.
14. 대형 Scene Tool·Compiler·UI Budget.

## 13. 구현 순서와 완료 기준

```text
Source·Identity·Schema
→ Command·History
→ Editor Core
→ Tool Host·Basic Tools
→ Semantic Compiler·Provider
→ Diagnostic·Test Play
→ Atomic Publish
→ Persistence·Security·Integration Test
```

완료 기준:

- Source·Build·Runtime·Dynamic State가 분리된다.
- Tool이 Editor Core와 Authority를 우회하지 않는다.
- Compile·Test·Publish가 별도 상태다.
- Build 실패가 Published Scene을 손상하지 않는다.
- Secret·Source Metadata가 Player Artifact에 없다.

Production 구현 전 실제 Editor·Tool·Compiler·Asset·Legacy Scene Mapping이 필요하다.