# Journal Document, Section, Anchor, Permission, Search와 Projection Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 문서·Section 단위 최대 크기와 단일 수정 Command의 최대 변경량
  - 자동 저장 Debounce, Draft 보존 기간과 충돌 Merge UI 기본값
  - 사용자·역할별 Journal Search 결과 수와 Snippet 길이 상한
  - Backlink·Anchor Resolution 재색인 Batch 크기와 지연 허용 시간
  - 삭제·Archive된 Anchor Target의 Tombstone 보존 기간
  - 공개 문서 안의 비공개 Anchor를 `plain_text`와 `omit` 중 어떤 방식으로 표시할지의 캠페인 기본값
  - Scene 진입 시 자동으로 열 기본 문서와 최근 문서 복원 우선순위
  - Markdown Import 시 안정적 Section ID를 생성·재사용하는 유사도 임계값
  - Section 단위 ACL을 초기 공개 버전에 활성화할지 여부
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0044`](../decisions/ADR-0044-linked-journal-and-two-mode-ping-system.md)
  - [`ADR-0058`](../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0071`](../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0073`](../decisions/ADR-0073-observer-relative-visibility-knowledge-and-hover-projections.md)
  - [`ADR-0074`](../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md)
  - [`ADR-0081`](../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md)
  - [`ADR-0083`](../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md)
  - [`ADR-0084`](../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md)
  - [`ADR-0085`](../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md)
  - [`ADR-0086`](../decisions/ADR-0086-stable-journal-identities-permission-partitioned-search-and-safe-world-navigation.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`UI Projection, ViewModel, Input Context와 Recovery Runtime 계약`](ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Persistence, Snapshot, Journal과 Recovery 계약`](persistence-and-session-recovery-model.md)
- 관련 Runtime:
  - [`Runtime Object System과 Entity Lifecycle 계약`](runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Selection Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Visibility, Knowledge와 Detection Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - [`Camera Runtime 계약`](camera-policy-focus-follow-and-presentation-runtime-contract.md)
  - [`Diagnostics Runtime 계약`](diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
  - [`Deterministic Simulation과 Test Harness 계약`](deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

## 1. 목적

RVTT Journal은 Obsidian형 Markdown 편집, 문서·제목을 함께 보여주는 빠른 탐색, 다른 문서와 실제 월드 대상의 링크를 결합한다.

단순 Markdown 문자열과 제목 기반 링크만 사용하면 다음 문제가 발생한다.

- 문서 제목이나 `##` Heading을 바꾸면 링크가 끊김
- 같은 이름을 가진 Actor·오브젝트에 링크가 잘못 재연결됨
- Scene Build 교체나 Rollback 이후 이전 Runtime Object Incarnation을 계속 가리킴
- 권한 없는 사용자에게 문서 제목·검색 결과·Backlink·Anchor Label이 노출됨
- Journal Link가 Camera·Selection·Workspace를 직접 조작하며 공개 정책을 우회함
- 두 사용자가 동시에 편집할 때 마지막 저장이 이전 변경을 조용히 덮어씀
- Client가 Raw Journal 전체와 비밀 검색 Index를 받은 뒤 화면에서만 숨김

따라서 Journal의 공통 흐름을 다음으로 고정한다.

```text
JournalDocumentSource
+ Stable Document·Section Identity
+ Permission·Anchor Binding
→ Journal Compiler
→ Immutable CompiledJournalDocument
→ Permission-aware Journal Projection·Search Result
→ UI ViewModel
→ Journal Intent
→ Read Request·Command·Selection·Camera Request
```

핵심 원칙:

```text
문서 제목과 Heading 문자열
≠ Journal Identity
```

```text
Journal Link는 월드 권위를 직접 조작하지 않는다.
Link는 권한 검사를 거친 안전한 Navigation Intent만 만든다.
```

## 2. 사용자 결과

이 계약은 다음 경험을 보장한다.

- 문서 제목, 폴더와 Section Heading을 바꿔도 기존 링크가 유지된다.
- 문서를 열면 현재 Scene에 연결된 문서와 `##` 이상의 Section을 왼쪽에서 빠르게 이동할 수 있다.
- Actor·Character·오브젝트·Scene·방·Camera Bookmark와 문서를 안정적으로 연결할 수 있다.
- 대상이 삭제되거나 Scene가 다시 게시되어도 링크가 다른 동명 대상에 자동으로 연결되지 않는다.
- 권한 없는 사용자는 비밀 문서의 본문뿐 아니라 제목, 존재, 검색 Hit, Backlink와 Anchor Metadata도 받지 않는다.
- 공개 문서에서 비공개 대상에 연결된 Link는 정책에 따라 일반 텍스트 또는 생략으로 투영되고 숨은 ID를 노출하지 않는다.
- Journal에서 월드 링크를 눌러도 Camera와 Selection Runtime의 공개·권한 정책을 우회하지 않는다.
- 동시 편집 충돌은 구조화된 Conflict로 반환되고 조용한 Last-write-wins가 발생하지 않는다.
- 재접속과 Rollback 이후 현재 권위 상태를 기준으로 Anchor를 다시 해결하며 이전 Epoch의 Runtime Reference를 사용하지 않는다.
- Search와 Backlink는 서버가 사용자별 공개 범위를 적용한 결과만 반환한다.

## 3. 책임 경계

### 3.1 Journal Runtime이 소유한다

- Journal Document, Folder와 Section의 안정적 Identity와 Revision
- Markdown Source, Frontmatter와 내부 Section Identity Map
- Journal Compiler, AST, Outline, Link와 Anchor 검증
- 문서·Section 기본 Permission과 명시적 ACL Binding
- Document Link, World Anchor와 Backlink Graph
- Anchor Resolution 상태와 Broken·Stale·Retargeted 표시
- Scene·Actor·Object에서 연결 문서를 찾는 Reverse Index
- Permission-aware Search, Outline, Snippet와 Backlink Projection
- Journal Command·Read Request Registry와 편집 충돌 처리
- Scene별 기본 문서 Binding과 최근 문서 탐색
- Import·Export 시 Identity 유지·생성 정책
- 저장·복구·Migration과 Journal Source History

### 3.2 Journal Runtime이 소유하지 않는다

- Actor, Runtime Object, Scene, Encounter와 Item의 권위 상태
- 대상이 실제로 보이는지·알려졌는지에 대한 Visibility·Knowledge 판정
- Camera Transform, Follow와 Focus 정책
- Selection Candidate와 Frozen Selection Binding
- Gameplay Command Authorization
- Markdown Editor Component, Dock Layout와 Focus
- Recovery용 Authority Transaction Journal
- 위치 핑과 경로 핑의 Presentation 수명주기

이 문서에서 말하는 `Journal`은 사용자 문서 시스템이다. `Commit Journal`과 `Recovery Journal`은 Persistence·Transaction의 별도 권위 기록이다.

## 4. Source, Build, Projection 분리

```text
JournalDocumentSource
→ Journal Compiler
→ Immutable CompiledJournalDocument
→ Viewer별 JournalDocumentProjection
```

### 4.1 JournalDocumentSource

```text
JournalDocumentSource
├─ documentId
├─ sourceRevision
├─ parentFolderId?
├─ title
├─ aliases[]
├─ markdownSource
├─ sectionIdentityMap[]
├─ frontmatter
├─ defaultPermissionBindingId
├─ sectionPermissionOverrides[]
├─ anchorBindings[]
├─ sceneBindings[]
├─ tags[]
├─ createdBy
├─ updatedBy
├─ createdAt
├─ updatedAt
└─ lifecycleState
```

`markdownSource`만으로 Identity와 Permission을 재구성하지 않는다. Editor가 관리하는 Section Identity, Anchor와 ACL Metadata는 타입 있는 Source Field로 보존한다.

### 4.2 CompiledJournalDocument

```text
CompiledJournalDocument
├─ documentId
├─ sourceRevision
├─ compilerVersion
├─ contentHash
├─ parsedAst
├─ outlineEntries[]
├─ compiledSections[]
├─ resolvedLinkDescriptors[]
├─ unresolvedLinkDescriptors[]
├─ searchTokens
├─ backlinkContribution
├─ validationDiagnostics[]
└─ buildState
```

Compiled Build는 불변이다. 새 Source Revision이 유효하게 Compile되면 활성 Pointer를 원자적으로 교체한다. Compile 실패 시 마지막 정상 Build를 유지하고 Draft 오류를 작성자에게 표시한다.

### 4.3 JournalDocumentProjection

Client는 Raw Source와 전체 Link Graph를 받지 않는다.

```text
JournalDocumentProjection
├─ publicDocumentRef
├─ projectionRevision
├─ title
├─ visibleSections[]
├─ renderedAstSegments[]
├─ visibleOutline[]
├─ visibleLinks[]
├─ visibleAnchors[]
├─ permittedActions[]
├─ editRevisionToken?
└─ integrityState
```

권한 없는 Section은 본문만 가리는 것이 아니라 Outline, Section Count, Backlink와 검색 결과에서도 제거한다.

## 5. 안정적 Document와 Section Identity

### 5.1 Document Identity

```text
JournalDocumentRef
├─ documentId
└─ expectedRevision?
```

다음은 Identity가 아니다.

- 문서 제목
- 폴더 경로
- 파일명
- 최근 문서 배열 위치
- Markdown Wiki Link 문자열

문서 Rename·Move는 `documentId`를 유지하고 Source Revision만 증가시킨다.

### 5.2 Section Identity

```text
JournalSectionRef
├─ documentId
├─ sectionId
└─ expectedSectionRevision?
```

```text
JournalSectionSource
├─ sectionId
├─ headingLevel
├─ headingText
├─ sourceRangeHint
├─ parentSectionId?
├─ sectionRevision
└─ permissionOverrideId?
```

Heading Text, 순서와 깊이가 바뀌어도 Editor가 같은 Section Node로 판단한 경우 `sectionId`를 유지한다.

외부 Markdown Import처럼 안정적 Node Metadata가 없으면 새 Section ID를 생성한다. 제목 유사도만으로 기존 Section ID를 자동 재사용하지 않는다. 사용자가 명시적으로 Merge·Retarget할 수 있다.

### 5.3 표시 문자열 분리

Link는 안정적 Reference와 표시 문자열을 분리한다.

```text
JournalLinkSource
├─ linkId
├─ sourceDocumentId
├─ sourceSectionId
├─ targetDescriptor
├─ authoredDisplayText?
├─ disclosureBehavior
└─ revision
```

대상 이름이 바뀌어도 Link Identity는 유지한다. 표시 문구는 `live_label`, `authored_label`, `redacted_label` 정책으로 결정한다.

## 6. Permission과 Disclosure

### 6.1 기본 Scope

기존 제품 Scope를 유지한다.

```text
private_dm
owner_and_dm
party
campaign
explicit_acl
```

초기 구현은 문서 단위를 기본으로 하고 Section Override는 같은 Schema로 지원하되 Feature Flag로 제한할 수 있다.

### 6.2 권한 종류

```text
JournalPermissionGrant
├─ discover
├─ read
├─ search
├─ navigate_links
├─ create_links
├─ comment
├─ edit
├─ manage_permissions
└─ export
```

`discover`와 `read`를 분리한다. 권한 없는 사용자가 문서가 존재한다는 사실조차 알면 안 되는 경우 `discover=false`다.

### 6.3 권한 평가 입력

```text
JournalViewerContext
├─ viewerUserId
├─ viewerRole
├─ ownedCharacterIds[]
├─ partyId?
├─ campaignId
├─ activeSceneId?
├─ knowledgeSnapshotRef?
├─ dmPreviewAudience?
└─ policySnapshotRef
```

Permission은 Journal ACL, Session Role, Ownership와 Disclosure Policy를 결합한다. DM이 Player View를 미리 볼 때는 선택한 Player와 같은 Projection을 사용한다.

### 6.4 공개 불변식

- 권한 없는 Document와 Section의 제목, ID, Alias, Tag와 존재를 Client에 전송하지 않는다.
- 검색 결과 개수와 Facet Count로 비공개 문서의 존재를 추론할 수 없게 한다.
- Backlink Count에 비공개 Source Document를 포함하지 않는다.
- Anchor Target의 Raw Runtime ID, 숨은 위치와 내부 이름을 권한 밖으로 보내지 않는다.
- 공개 Section 안의 작성자 입력 텍스트는 그 Section의 공개 콘텐츠다. 하지만 Link Target Metadata는 별도로 공개 검사를 통과해야 한다.
- Client-side Hide는 보조 표시일 뿐 보안 경계가 아니다.

## 7. 문서 링크와 World Anchor

### 7.1 Link 종류

```text
JournalTargetDescriptor
├─ document_section
├─ character
├─ actor
├─ scene_source_object
├─ runtime_object
├─ scene
├─ scene_region
├─ encounter
├─ item_definition
├─ item_instance
├─ spell_definition
├─ world_coordinate
├─ camera_bookmark
└─ custom_registered
```

문서 간 링크는 `documentId + sectionId?`를 사용한다.

### 7.2 World Anchor

```text
JournalAnchorBinding
├─ anchorId
├─ ownerDocumentId
├─ ownerSectionId?
├─ anchorKind
├─ stableTargetRef
├─ runtimeResolutionPolicy
├─ disclosurePolicy
├─ fallbackPolicy
├─ lastResolvedDescriptor?
├─ lifecycleState
└─ revision
```

`lifecycleState`:

```text
active
temporarily_unavailable
stale_incarnation
broken_reference
archived_target
retargeted
```

### 7.3 Source Object와 Runtime Object 구분

장기 문서 링크는 가능한 한 `scene_source_object`처럼 게시 Build가 바뀌어도 유지되는 Authoring Identity를 사용한다.

```text
Scene Source Object Anchor
→ 현재 Published Build의 Runtime Object로 Resolution
```

특정 소환체나 일시적 생성물처럼 현재 Incarnation 자체가 의미가 있을 때만 `runtime_object` Anchor를 사용한다.

```text
RuntimeObjectRef
├─ runtimeObjectId
├─ incarnation
└─ authorityEpoch
```

Rollback, Respawn 또는 ID 재사용 후 Incarnation이 달라지면 이전 Anchor를 자동으로 새 Object에 연결하지 않는다.

### 7.4 이름 기반 자동 Retarget 금지

Target이 삭제되거나 찾을 수 없을 때 다음을 금지한다.

```text
"고대 레버"라는 이름 검색
→ 같은 이름의 다른 레버에 자동 연결
```

사용자는 Broken Reference를 확인하고 명시적인 `RetargetJournalAnchorCommand`로 새 Target을 선택해야 한다. Retarget History는 감사 가능한 Source Revision으로 남긴다.

## 8. Anchor Lifecycle와 Resolution

### 8.1 Compile-time Validation

Compiler는 다음을 확인한다.

- Target Type과 Reference Schema
- 문서·Section Target 존재 여부
- Scene Source Identity와 Build Compatibility
- Permission Binding과 Disclosure Behavior
- 순환 Link는 허용하되 무제한 Embedded Render는 차단
- Custom Anchor Handler Registry Version

### 8.2 Runtime Resolution

```text
Journal Anchor
+ Viewer Context
+ Active Scene·Build·AuthorityEpoch
→ Anchor Resolver
→ Permission-aware JournalNavigationCapability
```

Resolver는 Workspace를 이름으로 검색하지 않는다. Runtime Object Registry, Scene Build Mapping, Character·Item Registry와 Camera Bookmark Registry의 타입 있는 Read Port를 사용한다.

### 8.3 대상 변경

- Rename: 안정적 Target ID가 같으면 Link 유지
- Scene Republish: Source Object Mapping으로 현재 Runtime Object에 재결합
- Runtime Destroy: `broken_reference` 또는 `archived_target`
- Scene Unload: `temporarily_unavailable`; Link는 유지
- Rollback: 이전 Epoch Runtime Resolution 폐기 후 새 Branch에서 재평가
- Character Actor 교체: Character Anchor는 새 Actor Projection으로 해결 가능, Actor Anchor는 원래 Actor 수명주기를 따름
- Target Permission 축소: Link Target Metadata를 즉시 재투영하고 Search·Backlink Index를 무효화

## 9. Link Graph와 Backlink

```text
JournalLinkGraph
├─ sourceDocumentId
├─ sourceSectionId
├─ targetDescriptor
├─ sourceRevision
├─ permissionClass
└─ linkState
```

Raw Link Graph는 Server 내부 Derived Index다. Client에는 Viewer가 볼 수 있는 Backlink만 투영한다.

```text
JournalBacklinkProjection
├─ publicSourceDocumentRef
├─ publicSourceSectionRef?
├─ displayTitle
├─ snippet?
└─ navigateCapability
```

비공개 문서에서 공개 문서를 참조해도 공개 문서의 Player Backlink Count에는 포함하지 않는다.

## 10. Permission-aware Search

### 10.1 Index Source

Search는 다음을 Index할 수 있다.

- Document Title과 Alias
- Section Heading
- 본문 Token
- Tag
- 작성자가 공개한 Anchor Label
- Scene·Actor·Object의 공개 가능한 표시명

Raw 비밀 Target 이름과 내부 ID를 일반 Search Token으로 사용하지 않는다.

### 10.2 Query 흐름

```text
JournalSearchReadRequest
+ JournalViewerContext
→ Permission-partitioned Search Index
→ Candidate Document·Section
→ 최신 Permission·Disclosure 재검증
→ Snippet Projection
→ JournalSearchResultPage
```

검색 Index가 오래된 Permission을 가지고 있더라도 최종 결과 반환 전에 최신 ACL과 Disclosure를 재검증한다.

### 10.3 Search Result

```text
JournalSearchResult
├─ publicDocumentRef
├─ publicSectionRef?
├─ title
├─ headingPath[]
├─ snippet
├─ visibleTags[]
├─ visibleAnchorSummary?
├─ scoreBand
└─ navigateCapability
```

다음을 반환하지 않는다.

- Raw `documentId`가 공개 Reference가 아닌 경우
- 권한 없는 문서 수와 숨은 결과 수
- 비밀 Section Heading
- 숨은 Target Label과 좌표
- 내부 Ranking Feature와 Security Filter 이유

### 10.4 Client Index

Client는 현재 열람 가능한 소규모 문서 Outline과 최근 문서를 Cache할 수 있다. 캠페인 전체 Raw Search Index를 다운로드하지 않는다.

## 11. Journal Command와 Read Request

### 11.1 Command

대표 Command:

```text
CreateJournalDocumentCommand
UpdateJournalDocumentCommand
RenameJournalDocumentCommand
MoveJournalDocumentCommand
ArchiveJournalDocumentCommand
SetJournalPermissionCommand
CreateJournalAnchorCommand
RetargetJournalAnchorCommand
RemoveJournalAnchorCommand
BindSceneDefaultDocumentCommand
```

모든 수정 Command는 다음을 포함한다.

```text
baseSourceRevision
expectedSectionRevisions[]?
clientEditOperationId
idempotencyKey
```

Command는 권한, Payload, Base Revision과 Anchor Target Type을 검증하고 Authority Transaction으로 Source Revision을 갱신한다.

### 11.2 Read Request

```text
OpenJournalDocumentRead
SearchJournalRead
ResolveJournalLinkRead
ListJournalBacklinksRead
ListSceneJournalBindingsRead
PreviewJournalAudienceRead
```

Read Request는 상태를 변경하지 않으며 Viewer Context에 고정된 Projection만 반환한다.

## 12. 동시 편집과 Conflict

기본 정책은 Revision 기반 Optimistic Concurrency다.

```text
Base Source Revision
+ Edit Operations
→ 최신 Revision 검증
→ 적용 가능하면 Commit
→ 충돌하면 JournalEditConflict
```

```text
JournalEditConflict
├─ currentSourceRevision
├─ conflictingSectionIds[]
├─ serverChangedRanges[]
├─ clientOperationSummary
├─ mergeableOperations[]
└─ resyncRequired
```

서버는 Markdown 문자열 전체를 마지막 요청으로 덮어쓰지 않는다. 서로 다른 Section의 독립 변경은 등록된 Merge Policy가 있을 때만 결합한다.

## 13. 안전한 Journal Navigation Intent

Journal UI는 Link를 클릭했다고 Camera, Selection 또는 Scene를 직접 조작하지 않는다.

```text
JournalLinkActivated
→ ResolveJournalLinkRead
→ JournalNavigationCapability
→ 사용자가 허용된 동작 선택 또는 기본 동작 확인
→ CameraRequest / Selection Intent / Scene Transition Request
```

### 13.1 JournalNavigationCapability

```text
JournalNavigationCapability
├─ capabilityId
├─ sourcePublicDocumentRef
├─ targetKind
├─ publicTargetProjectionRef?
├─ allowedActions[]
├─ cameraTargetProjection?
├─ selectionBindingCandidate?
├─ sceneTransitionProposal?
├─ expiryConditions
└─ revisionSet
```

`allowedActions` 예:

```text
open_document
scroll_to_section
focus_camera
select_target
highlight_target
open_public_info
request_scene_transition
copy_public_link
```

### 13.2 Camera 연결

Journal은 `CameraRequest`만 제출한다.

- Target은 권한 검사를 통과한 `CameraTargetProjection` 또는 안전한 Transform Snapshot이다.
- 비밀 좌표와 숨은 Runtime Object Reference를 Player Client에 보내지 않는다.
- Hover만으로 Camera를 이동하지 않는다.
- 명시적인 Link Activation은 사용자 요청 우선순위의 Focus Request를 만들 수 있다.
- Camera 이동 실패가 Journal 문서를 닫거나 Gameplay State를 변경하지 않는다.

### 13.3 Selection 연결

Journal은 Selection Store를 직접 수정하지 않는다.

- 공개 가능한 `selectionBindingCandidate`만 Selection Runtime에 제출한다.
- Target이 현재 Selection 가능한 상태인지 최신 Snapshot에서 재검증한다.
- 문서에 링크가 있다는 사실만으로 미발견 함정이나 숨은 Actor를 Selection Candidate로 공개하지 않는다.
- DM은 자신의 전체 Projection으로 Target을 선택할 수 있지만 Player View Preview에서는 Player와 같은 제한을 받는다.

### 13.4 Scene 전환

다른 Scene Link는 즉시 전환하지 않고 `SceneTransitionProposal`을 만든다. Role, Permission, Session Mode와 진행 중 Encounter·RuleExecution Gate를 통과해야 한다.

## 14. Scene, Actor와 Object의 Reverse Navigation

Actor·Object Context Menu는 Journal Runtime에 Read Request를 보낸다.

```text
ListLinkedJournalDocumentsRead(targetRef, viewerContext)
```

가능한 UI Intent:

```text
연결된 문서 열기
새 문서 생성 후 Anchor 연결
현재 문서에 Link 삽입
연결된 Section으로 이동
```

Context Menu는 권한 없는 문서 제목이나 Link 수를 표시하지 않는다.

## 15. Scene 기본 문서와 빠른 탐색

```text
SceneJournalBinding
├─ bindingId
├─ sceneId
├─ audienceScope
├─ defaultDocumentId
├─ fallbackDocumentIds[]
├─ openPolicy
└─ revision
```

Journal을 열 때 기본 순서:

```text
현재 안전하게 복원 가능한 열린 문서
→ 현재 Scene의 Viewer용 기본 문서
→ 최근 열람 가능 문서
→ Journal Home
```

왼쪽 탐색 패널은 다음을 결합한다.

- 권한 있는 Folder와 Document
- 현재 문서의 Visible Outline
- 즐겨찾기와 최근 문서
- Search Result
- 권한 있는 Scene Binding

`##` 이상의 Heading을 Outline에 표시하는 제품 기본값을 유지한다. 정확한 최소 Heading Level은 사용자 설정이 아니라 Journal UI Policy로 조정할 수 있다.

## 16. Markdown Import와 Export

### Import

- 표준 Markdown과 `[[문서]]`, `[[문서#제목]]` 형태를 파싱할 수 있다.
- 제목 기반 Wiki Link는 Import 시 Target 후보를 보여주고 사용자가 확정한 뒤 안정적 ID Link로 변환한다.
- 동명 문서를 임의로 선택하지 않는다.
- 외부 Markdown에는 내부 Section ID가 없으므로 새 ID를 생성한다.
- Import Preview는 권한 없는 기존 문서를 후보로 노출하지 않는다.

### Export

- 사용자가 읽고 Export할 권한이 있는 Section만 포함한다.
- 내부 ID, ACL, 비밀 Anchor Metadata와 Raw Runtime Ref를 기본 Markdown에 노출하지 않는다.
- World Link는 공개 가능한 표시 문자열과 선택적 Portable Descriptor로 변환한다.
- 완전한 관리용 Backup Export는 별도 DM·Admin Command와 감사 정책을 사용한다.

## 17. Network와 UI 연결

### Projection Segment

Journal은 필요에 따라 다음 Projection Segment를 사용한다.

```text
journal_navigation_summary
journal_document_content
journal_outline
journal_search_page
journal_backlinks
journal_edit_state
```

문서 전체를 Session 접속 Snapshot에 무조건 포함하지 않는다. Scene 기본 문서 Summary와 최근 문서만 보내고 본문은 Read Request로 지연 로드할 수 있다.

### UI State

- 열린 Panel, Dock 위치, Scroll과 접힌 Section은 Local Workspace State다.
- 현재 Document Projection, Edit Revision과 Permission은 Authority-bound UI State다.
- 재접속 시 Local Layout은 유지할 수 있지만 이전 Revision의 Edit Draft는 재검증해야 한다.
- Rollback 또는 Role Change 후 이전 Permission으로 받은 Document Cache를 폐기한다.

## 18. Persistence, Recovery와 Rollback

저장 대상:

```text
Document·Folder Source
Section Identity Map
Permission Binding
Anchor Binding
Scene Journal Binding
Source Revision History Pointer
Compile Build Pointer
```

Derived Search Index, Backlink Cache와 Runtime Anchor Resolution은 재생성 가능하므로 권위 저장 원본이 아니다.

### 18.1 사용자 Journal과 Recovery Journal 분리

사용자 Journal Document를 Authority Transaction Recovery Journal로 사용하지 않는다. 이름이 같아도 저장 Schema와 권위 목적이 다르다.

### 18.2 Encounter Rollback

일반적인 Encounter Rollback은 사용자 작성 문서를 자동으로 과거 Revision으로 되돌리지 않는다.

- Journal Source는 Campaign Authoring History를 따른다.
- 월드 Anchor Resolution과 공개 Projection은 새 AuthorityEpoch에서 다시 계산한다.
- 시스템이 특정 Gameplay Branch에 종속된 자동 기록을 생성하려면 별도 Branch Binding을 명시해야 한다.
- Rollback 이전 Runtime Object Incarnation에 대한 Anchor Resolution Cache는 폐기한다.

### 18.3 Server Recovery

마지막 검증된 Journal Source와 Compile Pointer를 복구한다. Compile Build가 유실되었거나 Version이 바뀌면 Source에서 재Compile한다.

## 19. Diagnostics와 Simulation

필수 Trace:

```text
journal.command
journal.compile
journal.permission_evaluate
journal.projection_build
journal.search_query
journal.anchor_resolve
journal.navigation_resolve
journal.index_update
```

진단도 Permission-aware Projection을 사용한다. Player Support Report에 비밀 문서 제목, Section, Anchor Target과 Search Token을 포함하지 않는다.

필수 Simulation Scenario:

1. Document Rename 후 링크 유지
2. Section Heading Rename·Move 후 Section Link 유지
3. 동명 Object 삭제 후 자동 Retarget 금지
4. Scene Republish 후 Source Object Anchor 재결합
5. Rollback 후 이전 Runtime Object Incarnation Link 무효화
6. 비공개 문서가 Player Search·Count·Backlink·Recent에 나타나지 않음
7. 공개 문서의 비공개 Target Link가 Raw ID를 노출하지 않음
8. DM Player-view Preview가 Player Projection과 동일함
9. 동시 편집 충돌에서 Last-write-wins 금지
10. Journal Link Camera Focus가 숨은 위치를 공개하지 않음
11. 권한 축소 직후 Client Cache와 Search Result 무효화
12. Archive Target이 Broken·Archived 상태로 보존됨

## 20. 성능과 보안

- Markdown AST, Outline과 Search Index는 Document Revision 단위로 증분 갱신한다.
- 대형 문서는 Section Segment로 지연 로드하고 UI는 Virtualization을 사용한다.
- Search Snippet은 Server에서 생성하며 결과 수와 연산 Budget을 제한한다.
- Anchor Resolution은 타입별 Cache를 사용할 수 있지만 Target Revision, Build와 AuthorityEpoch를 Dependency로 가진다.
- Link Graph 순환은 허용하되 Embedded Preview 재귀 깊이를 제한한다.
- Client 입력 Markdown은 문자열 길이, Node 수, Link 수와 중첩 깊이를 검증한다.
- 임의 HTML, Script, 실행 가능한 Luau와 외부 Resource 자동 실행을 허용하지 않는다.
- URL Link는 별도 Allowlist·Confirmation 정책을 사용하며 World Anchor와 같은 신뢰 수준으로 취급하지 않는다.
- 권한 변경은 Search·Backlink·Projection Cache를 우선 무효화한다.

## 21. 역할 경계

### Player

- 자신에게 공개된 문서·Section을 읽고 검색한다.
- Grant가 있으면 문서를 생성·편집하고 공개 가능한 Target에 Link를 만든다.
- 자신의 권한 밖 Target을 Anchor 후보로 열거할 수 없다.

### DM

- Campaign Journal 구조, Permission, Scene Binding과 World Anchor를 관리한다.
- 비밀 Target Link를 작성하고 Player Audience Projection을 미리 볼 수 있다.
- Player에게 공개할 콘텐츠와 Target Navigation을 별도로 결정한다.

### Observer

- Observer Policy가 허용한 읽기·검색 Projection만 받는다.
- 편집과 Link Authoring은 기본적으로 허용하지 않는다.

### System

- Identity, Revision, Compile, Permission Projection, Index와 Anchor Resolution을 관리한다.
- Journal Link를 이유로 Gameplay Disclosure를 자동 확장하지 않는다.

## 22. 구조화된 오류

대표 Error Code:

```text
JOURNAL_DOCUMENT_NOT_FOUND
JOURNAL_SECTION_NOT_FOUND
JOURNAL_PERMISSION_DENIED
JOURNAL_DOCUMENT_NOT_DISCOVERABLE
JOURNAL_STALE_SOURCE_REVISION
JOURNAL_SECTION_CONFLICT
JOURNAL_COMPILE_FAILED
JOURNAL_ANCHOR_TARGET_INVALID
JOURNAL_ANCHOR_STALE_INCARCATION
JOURNAL_ANCHOR_BROKEN
JOURNAL_TARGET_NOT_DISCLOSED
JOURNAL_SEARCH_BUDGET_EXCEEDED
JOURNAL_NAVIGATION_EXPIRED
JOURNAL_SCENE_TRANSITION_BLOCKED
JOURNAL_EXPORT_REDACTED
```

권한이 없는 Document에 대해 `NOT_FOUND`와 `PERMISSION_DENIED` 중 무엇을 공개할지는 Disclosure Policy가 결정한다. 일반 Player에게 존재 여부가 비밀이면 `NOT_FOUND`와 구분되지 않는 안전한 오류를 사용한다.

## 23. 권장 구현 경계

```text
JournalSourceStore
JournalCommandService
JournalCompiler
JournalDocumentRegistry
JournalPermissionResolver
JournalProjectionBuilder
JournalSearchIndexer
JournalSearchService
JournalLinkGraphService
JournalAnchorResolverRegistry
JournalNavigationResolver
JournalSceneBindingService
JournalImportExportService
JournalDiagnosticsAdapter
```

Feature별 UI가 Journal Source Store, Workspace와 Search Index를 직접 조작하지 않는다.

## 24. 후속 구현 명세

- `specs/journal/001-document-section-source-and-revision.md`
- `specs/journal/002-markdown-compiler-outline-and-link-graph.md`
- `specs/journal/003-permission-projection-and-search-index.md`
- `specs/journal/004-world-anchor-resolution-and-lifecycle.md`
- `specs/journal/005-safe-navigation-camera-selection-and-scene-transition.md`
- `specs/journal/006-edit-conflict-import-export-and-recovery.md`
- `specs/journal/007-journal-simulation-and-disclosure-regression.md`

## 25. 완료 기준

다음이 충족되면 Journal 공통 Architecture를 완료한 것으로 판정한다.

- Document·Section Identity가 제목과 경로에서 분리됨
- Permission 없는 제목·검색·Backlink·Anchor Metadata가 Projection되지 않음
- Source Object와 Runtime Object Anchor Lifecycle이 분리됨
- Name-based 자동 Retarget이 금지됨
- Camera·Selection·Scene 이동이 안전한 Navigation Capability를 통함
- Revision Conflict와 Compile Last-known-good가 정의됨
- Persistence·Rollback·Recovery와 Search Rebuild가 정의됨
- Negative Disclosure Simulation Scenario가 정의됨
