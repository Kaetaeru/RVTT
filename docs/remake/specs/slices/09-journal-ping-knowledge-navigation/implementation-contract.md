# Implementation Spec — Slice 09 Journal·Ping·Knowledge Navigation

- 상태: SPEC_CHECKPOINT_COMPLETE
- 문서 종류: Slice Integration Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 차단 이유: 실제 Journal Source·Markdown Compiler·Search Index·UI·Ping 구조가 확인되지 않았다.
- Work Order: [`CURRENT-WORK-ORDER.md`](CURRENT-WORK-ORDER.md)
- Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 관련 Guide: [`Journal`](../../../guides/journal/README.md), [`UI`](../../../guides/ui/README.md), [`Scene`](../../../guides/scene/README.md), [`Exploration`](../../../guides/exploration/README.md), [`Session`](../../../guides/session/README.md), [`Diagnostics`](../../../guides/diagnostics/README.md)

> 사용자 Journal과 Transaction Recovery Journal은 서로 다른 저장물이다. Journal Link는 Stable Anchor를 통해 Navigation Proposal을 만들지만 다른 Domain Store를 직접 수정하지 않는다.

## 1. Acceptance Flow

```text
Scene 기본 Journal 열기
→ Document·Outline 탐색
→ Markdown 보기·편집
→ Search·Backlink
→ Wiki Link·World Link 활성화
→ Camera Focus·Selection·Scene Transition 제안
→ Point·Path Ping 공유
→ Reconnect 후 Draft·열람 상태 재결합
```

DM은 Document·Folder·ACL·World Anchor를 관리하고 Player View Preview로 실제 공개 결과를 확인한다.

## 2. 직접 권위 문서

- [`Journal Document, Section, Anchor, Permission, Search와 Projection`](../../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery`](../../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Visibility, Knowledge와 Hover Projection`](../../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Selection, Targeting과 Frozen Binding`](../../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Camera Policy와 Presentation Runtime`](../../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
- [`Presentation Recipe Runtime`](../../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Session Play Mode와 Transition`](../../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Persistence와 Session Recovery`](../../../architecture/persistence-and-session-recovery-model.md)
- [`두 모드 Ping 모델`](../../../systems/journal/two-mode-ping-model.md)
- [`공통 입력 교과서`](../../../ui/common-input/common-input-grammar.md)

## 3. 범위

포함:

- Document·Folder·Section Stable Identity와 Revision
- Markdown Source·Compiler·AST·Outline·Link Graph
- ACL·Discover·Read·Search·Navigate·Edit Permission
- Permission-partitioned Search·Backlink
- World Anchor Resolver와 Lifecycle
- Safe Navigation Capability·Camera·Selection·Scene Transition Proposal
- Edit Conflict·Import·Export·Draft Recovery
- Scene 기본 문서와 Journal UI
- Point·Path Ping·Audience·Rate Limit·Presentation

제외:

- Journal Command의 직접 Gameplay Mutation
- Ping의 Movement·Targeting Authority 사용
- 외부 협업 Docs 서비스
- 사용자 작성 Luau 실행

## 4. Type와 Identity

```lua
export type JournalDocumentSource = {
    documentId: string,
    folderId: string?,
    sourceRevision: number,
    title: string,
    markdownSource: string,
    aclRef: string,
    lifecycleState: string,
}

export type CompiledJournalDocument = {
    buildId: string,
    documentId: string,
    sourceRevision: number,
    compilerVersion: string,
    sectionRefs: {string},
    outline: {unknown},
    linkDescriptors: {unknown},
    buildHash: string,
}

export type JournalSection = {
    sectionId: string,
    documentId: string,
    headingPath: {string},
    sourceRange: {startOffset: number, endOffset: number},
    revision: number,
}

export type AnchorDescriptor = {
    anchorId: string,
    anchorKind: "document" | "section" | "character" | "source_object" | "runtime_object" | "scene" | "item" | "coordinate" | "camera_bookmark",
    stableTargetRef: string,
    fallbackPolicy: string,
    revision: number,
}

export type JournalAcl = {
    aclId: string,
    discover: {string},
    read: {string},
    search: {string},
    navigate: {string},
    edit: {string},
    revision: number,
}
```

제목·Heading·표시 이름·검색 순위를 Identity로 사용하지 않는다. Rename·Move 후에도 Stable ID를 유지한다. 삭제된 동명 Target으로 자동 Retarget하지 않는다.

## 5. Source·Compiler·Build

```text
Markdown Source
→ Parse·Normalize
→ Stable Section Mapping
→ Outline·Link Descriptor
→ Validation
→ Candidate Build
→ Atomic Activation
```

Compile 실패 시 Source를 보존하고 Last Known Good Build를 계속 제공한다. Raw Markdown과 Compiled Document, Search Index와 Viewer Projection을 같은 Table로 합치지 않는다.

Wiki Link Import에서 동명 문서는 자동 선택하지 않고 사용자 확인을 요구한다. Export는 Viewer Permission을 적용해 Redact하며 Stable Internal ID를 무단 노출하지 않는다.

## 6. Permission·Projection·Search

Viewer Context에서 다음을 별도 판정한다.

- Document 존재 발견 가능성
- 내용 읽기
- 검색 결과 포함
- World Anchor Navigation
- Source 편집

비공개 Document가 Hit, Count, Facet, Recent, Backlink와 Error에 나타나지 않아야 한다. Search Index는 Permission Partition 또는 Query-time ACL 재검증을 사용하며 ACL Revision 변경 시 Cache를 즉시 무효화한다.

```text
Query
→ Viewer Context·ACL Revision
→ Permission-safe Index Partition
→ 최신 ACL 재검증
→ Redacted Snippet·Result
```

## 7. Anchor Resolution와 Safe Navigation

```text
Anchor Descriptor
→ Target Domain Resolver
→ Stable Source·Runtime·Scene·Item Ref 검증
→ Viewer Disclosure·Permission 검증
→ JournalNavigationCapability
→ CameraRequest | Selection Intent | SceneTransitionProposal
```

Source Object Anchor는 Scene Republish 후 Mapping을 통해 새 Runtime Presence를 찾을 수 있다. Runtime Object Anchor는 Incarnation이 다르면 자동 승계하지 않는다. Coordinate Anchor는 공개 가능한 Scene·Region인지 확인한다.

Journal은 Camera, Selection, Scene Transition을 직접 실행하지 않고 Proposal을 제출한다. 최신 Session Mode·Encounter Gate·Scene Readiness가 거부할 수 있다.

## 8. Edit Conflict와 Draft

```text
Edit Intent + base Source Revision
→ Permission·Revision 검증
→ 독립 Section 변경 Merge 가능성
→ Conflict Detection
→ New Source Revision
→ Compile Candidate
→ Activation
```

Last-write-wins를 기본 사용하지 않는다. 충돌은 Base·Current·Proposed 정보를 구조화해 사용자에게 제공한다. Client Draft는 Local Recovery 대상일 수 있지만 Server Source Authority가 아니다.

Command:

- `CreateJournalDocument`
- `MoveJournalDocument`
- `EditJournalSource`
- `SetJournalAcl`
- `CreateOrUpdateAnchor`
- `ResolveJournalNavigation`
- `ImportMarkdown`
- `ExportJournalView`

Read Request:

- `OpenJournalDocument`
- `SearchJournal`
- `ListBacklinks`
- `PreviewAudience`

## 9. Ping

Point Ping:

```text
Click Position
→ 공개 가능한 Surface·Coordinate 검증
→ Audience·Rate Limit
→ Ping Signal
→ Presentation
```

Path Ping:

```text
Drag Sample
→ 공개 가능한 Surface Projection
→ Path Simplification·Payload Limit
→ Audience Validation
→ Ping Signal·Presentation
```

Audience:

```text
party | campaign | selected_users | private_dm
```

Ping은 짧은 Signal이며 Authority Projection Sequence와 Movement Command가 아니다. Presentation 실패·Loss·Expiry가 Gameplay를 바꾸지 않는다. Ping Payload에 Hidden Entity ID, Secret Anchor와 권한 밖 좌표를 넣지 않는다.

## 10. Persistence·Recovery·Rollback

저장:

- Document·Folder·Section Source·Revision·History Pointer
- Active Compiled Build Ref
- ACL·Anchor Descriptor
- Import Mapping과 Draft Recovery Metadata
- Derived Search·Backlink Index는 재생성 가능

Ping은 일반적으로 Snapshot 복구 대상이 아니다.

Server Recovery는 Source·Build Pointer를 확인하고 Index를 재생성한다. Rollback은 Journal Source History와 Gameplay Branch를 독립적으로 다루되 Runtime Anchor를 새 AuthorityEpoch에서 재해석한다. 이전 Navigation Capability·Cache를 폐기한다.

## 11. UI·Diagnostics·Security

UI 상태:

```text
읽기 전용·편집 가능
Compile 오류·Last Known Good 표시
Search 결과 없음과 공개 불가 구분 방지
Link Target 누락·권한 없음
Conflict Review
Draft Recovery
Navigation 거부·Scene Loading
Ping Rate Limit·Audience 오류
```

Trace:

```text
journal.source_edit
journal.compile
journal.permission
journal.search
journal.anchor_resolve
journal.navigation
journal.import
journal.export
ping.validate
ping.publish
```

Security:

- Raw 비공개 Source·ACL·Anchor를 Player에게 전송하지 않는다.
- Search·Backlink·Error·Diagnostic Side Channel을 검사한다.
- Markdown에 Script·Remote·URL Runtime 실행을 허용하지 않는다.
- Import 크기·깊이·Link 수를 Budget으로 제한한다.

## 12. Test 계획

1. Document Rename·Folder Move 후 Link 유지.
2. Heading Rename·Move 후 Section Link 유지.
3. Compile 실패와 Last Known Good.
4. 독립·충돌 Section 동시 편집.
5. 비공개 Document Search·Count·Backlink 미노출.
6. Player View Preview와 실제 Projection 일치.
7. Scene Republish 후 Source Object Anchor 재결합.
8. Runtime Object Respawn·Rollback 후 이전 Incarnation 무효.
9. 동명 Target 삭제 후 자동 Retarget 금지.
10. Permission 축소 후 Client Cache 제거.
11. Camera Focus가 숨은 위치를 공개하지 않음.
12. Scene Transition·Selection 최신 Gate 거부.
13. Point·Path Ping Rate·Payload·Audience.
14. Ping Loss·Presentation 실패 후 Gameplay 불변.
15. Restart 후 Source·Build·Index·Draft 복구.

## 13. 구현 순서와 완료 기준

```text
Source·Identity·Revision
→ Markdown Compiler·Build
→ ACL·Projection·Search
→ Anchor Resolver·Navigation
→ Edit·Import·Export·Draft
→ Journal UI
→ Ping Validation·Presentation
→ Recovery·Disclosure·Test
```

완료 기준:

- Rename·Move 후 Link가 Stable ID로 유지된다.
- 권한 없는 문서·Target이 Search·Navigation·Error에 누출되지 않는다.
- Journal Navigation은 다른 Domain Proposal을 사용한다.
- Ping은 짧은 비권위 Signal로 유지된다.
- Compile·Conflict·Recovery가 Source를 손상하지 않는다.

Production 구현 전 실제 Parser·Index·UI·Anchor·Ping Package Mapping이 필요하다.