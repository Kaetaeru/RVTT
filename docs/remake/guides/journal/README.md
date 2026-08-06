# Main System Guide: Journal과 Ping

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 RVTT의 사용자 문서 시스템이 Obsidian형 Markdown 편집, Docs형 문서·Outline 탐색, 안정적인 문서·Section Identity, 권한별 Search·Backlink, 실제 월드 대상 Anchor와 안전한 Camera·Selection·Scene Navigation을 제공하는 전체 흐름을 설명한다. 또한 클릭 위치 핑과 드래그 경로 핑이 Journal Anchor나 이동 명령이 아닌 짧은 비권위 Presentation Signal로 생성·검증·공개·만료되는 경계를 통합한다.

사용자에게 보장하는 결과:

- Journal 문서 제목, 폴더 경로, 파일명과 Heading Text를 바꾸어도 `documentId`와 `sectionId`가 유지되는 한 기존 Link가 유지된다.
- Markdown Source만을 권위 원본으로 사용하지 않고 Section Identity, Permission, Anchor와 Scene Binding을 타입 있는 Source Metadata로 함께 보존한다.
- Journal Source는 Compiler를 거쳐 불변 Compiled Document가 되며, Compile 실패 시 마지막 정상 Build를 유지한다.
- 문서를 열면 현재 안전하게 복원 가능한 문서, 현재 Scene의 Viewer용 기본 문서, 최근 문서와 Journal Home 순서로 진입 대상을 결정할 수 있다.
- 현재 문서의 공개 가능한 `##` 이상 Section은 왼쪽 Outline에서 빠르게 이동할 수 있다.
- 문서·Section, Character, Actor, Scene Source Object, Runtime Object, Scene, Region, Encounter, Item, Spell, World Coordinate와 Camera Bookmark를 타입 있는 Link Target으로 참조할 수 있다.
- 장기 Scene Link는 가능한 한 Scene Source Object Identity를 사용하고, 특정 Runtime Incarnation 자체가 의미가 있을 때만 Runtime Object Reference를 사용한다.
- Runtime Object Link는 `runtimeObjectId + incarnation + authorityEpoch`를 검증하며 Rollback·Respawn·ID 재사용 후 다른 대상에 자동 연결하지 않는다.
- Target이 삭제·Archive·Unload·Republish되었을 때 Link를 같은 이름의 다른 대상에 자동 Retarget하지 않고 `temporarily_unavailable`, `stale_incarnation`, `broken_reference`, `archived_target` 같은 상태로 보존한다.
- Retarget은 사용자의 명시적 Command와 새 Source Revision으로 기록한다.
- Journal Link를 클릭해도 Journal Runtime이 Camera, Selection Store, Workspace 또는 Scene Transition을 직접 조작하지 않는다.
- Link는 Viewer Context에서 다시 해결된 `JournalNavigationCapability`를 만들며 허용된 CameraRequest, Selection Intent 또는 SceneTransitionProposal만 제출한다.
- 공개 문서 안에 비공개 Target Link가 있더라도 Raw ID, 숨은 좌표와 내부 이름을 Client에 보내지 않는다.
- `discover`, `read`, `search`, `navigate_links`, `create_links`, `comment`, `edit`, `manage_permissions`, `export` 권한을 분리한다.
- 권한 없는 사용자는 비공개 문서와 Section의 본문뿐 아니라 제목, 존재, Alias, Tag, Outline, Search Hit, Result Count, Backlink와 Anchor Metadata도 받지 않는다.
- Search는 Permission-partitioned Server Index를 사용하고 결과 반환 직전에 최신 ACL·Disclosure를 다시 검증한다.
- Client는 캠페인 전체 Raw Journal, Link Graph와 Search Index를 다운로드하지 않는다.
- DM의 Player Audience Preview는 선택된 Player와 동일한 Projection을 사용한다.
- 동시에 편집할 때 Base Source Revision과 Section Revision을 검증하고 충돌을 구조화된 `JournalEditConflict`로 반환한다.
- 서버는 마지막 요청의 Markdown 문자열로 이전 변경을 조용히 덮어쓰는 Last-write-wins를 사용하지 않는다.
- 외부 Markdown의 제목 기반 Wiki Link는 Import Preview에서 후보를 보여 주고 사용자가 확정한 뒤 안정적 ID Link로 변환한다.
- 동명 문서나 Object를 Import 과정에서 임의로 선택하지 않는다.
- Export는 사용자가 읽고 내보낼 수 있는 Section만 포함하고 내부 ID, ACL, 비밀 Anchor Metadata와 Raw Runtime Reference를 제거한다.
- 사용자 Journal Document와 Authority Transaction 복구용 Commit Journal·Recovery Journal을 서로 다른 시스템으로 유지한다.
- Encounter Rollback은 사용자가 작성한 Journal Source를 자동으로 과거 Revision으로 되돌리지 않는다.
- Rollback과 Branch 전환 후 Anchor Resolution, 공개 Projection, Search·Backlink Cache와 Runtime Reference를 새 AuthorityEpoch에서 다시 계산한다.
- 클릭 핑은 한 위치를, 드래그 핑은 간소화된 경로를 공유한다.
- 핑은 Actor 이동, NavigationPlan, Frozen Selection Binding, 이동 비용, 기회 공격, 충돌, 시야 또는 규칙 결과를 확정하지 않는다.
- 핑은 Journal Anchor, Camera Bookmark, Document Link와 Selection을 자동 생성하지 않는다.
- 핑 Server는 Session Role, Audience, Scene Scope, 좌표·표면 범위, Payload와 Rate Limit을 검증한다.
- 경로 핑은 공개 가능한 Navigation Surface에 시각적으로 투영할 수 있지만 실제 이동 경로 권위로 사용하지 않는다.
- 권한 없는 표면이나 Streaming되지 않은 구간은 끊김·경고 표시로 표현하며 숨은 공간을 공개하지 않는다.
- Ping은 짧은 Presentation Lifetime 후 제거되고 Campaign Authority Snapshot과 Recovery Snapshot에 저장하지 않는다.
- Presentation Signal 손실과 만료 Ping 미재생은 Authority Event Gap이나 Gameplay Recovery 실패가 아니다.
- Journal·Ping UI 오류와 Presentation 실패가 Gameplay Transaction, Character, Scene와 Encounter 권위 상태를 바꾸지 않는다.

적용 범위:

- Journal Folder, Document와 Section의 Identity·Revision·Lifecycle
- Markdown Source, Frontmatter, Section Identity Map과 Journal Compiler
- Compiled Journal Document, Outline, Link Graph와 Last-known-good Build
- 문서·Section Permission, ACL, Viewer Context와 Disclosure Projection
- Document Link, World Anchor, Anchor Resolver와 수명주기
- Permission-aware Search, Snippet, Backlink와 Reverse Navigation
- Journal Command, Read Request, Edit Conflict와 Audience Preview
- Scene 기본 문서, 최근 문서, Folder·Document·Outline 탐색
- Markdown Import·Export와 안정적 Link 변환
- Journal Navigation Capability와 Camera·Selection·Scene Transition 연결
- Journal Projection Segment, UI State, 지연 로드와 Cache 무효화
- Persistence, Recovery, Rollback과 Journal Source History
- 위치 핑, 경로 핑, Audience, Input Context와 Presentation Lifetime
- Ping 좌표·경로 검증, Rate Limit, Merge와 성능 상한
- Player, DM, Observer와 System 역할 경계
- Diagnostics, Simulation과 Negative Disclosure 검증

명시적 비범위:

- Authority Transaction Commit Journal과 Session Recovery Journal의 내부 구현
- Camera Controller, Selection Runtime, Scene Transition과 Navigation Engine의 내부 구현
- Character, Actor, Item, Encounter와 Scene Object의 권위 상태
- Journal Editor의 최종 픽셀 레이아웃과 Markdown 렌더러 구현 세부
- 실시간 공동 편집 CRDT를 새로 도입하는 결정
- Ping을 실제 이동·명령·Targeting·Journal Annotation으로 승격하는 기능
- 영구 전술 그림, 지도 주석과 공유 Whiteboard
- 외부 URL의 자동 실행과 임의 HTML·Script·Luau 실행
- 문서 크기, 자동 저장 Debounce, Search Result, Snippet, Index Batch, Tombstone과 Ping Payload의 측정 전 기본값
- 음악, NPC 대화 시스템과 모든 규칙 효과음

## 2. 전체 구조

### Journal Source·Build·Projection 구조

```text
JournalDocumentSource
+ Stable Document·Section Identity
+ Permission·Anchor·Scene Binding
→ Journal Compiler
→ Immutable CompiledJournalDocument
→ Permission-aware Document·Outline·Search·Backlink Projection
→ UI ViewModel
→ Journal Intent
→ Read Request | Command | Navigation Capability
```

### World Anchor와 Navigation 구조

```text
Journal Link Activation
→ Viewer Context·Permission·Disclosure 검증
→ Stable Target·현재 Build·AuthorityEpoch Resolution
→ JournalNavigationCapability
→ open_document | scroll_to_section | focus_camera
  | select_target | highlight_target | open_public_info
  | request_scene_transition | copy_public_link
→ 대상 Runtime이 최신 상태에서 재검증
```

### Ping 구조

```text
Physical Input
→ Semantic Ping Action
→ 위치 클릭 또는 드래그 Sample
→ Client Ping Intent
→ Server Role·Audience·Scene·Coordinate·Rate 검증
→ Audience별 Presentation Signal
→ 위치·경로 표시
→ Lifetime 만료·제거
```

### 공통 사용자 경험

```text
Journal
→ 오래 유지되는 지식·권한·Link·검색·Anchor

Ping
→ 지금 보고 있는 위치·경로를 짧게 설명하는 표시
```

둘은 같은 UI와 Presentation 기반을 사용할 수 있지만 Identity, Persistence, Authority와 수명주기를 공유하지 않는다.

## 3. 주요 데이터 흐름

### 3.1 Journal Source, Build와 Projection

```text
JournalDocumentSource
├─ documentId·sourceRevision
├─ parentFolderId·title·aliases
├─ markdownSource·sectionIdentityMap
├─ frontmatter·tags
├─ Permission Binding·Section Override
├─ Anchor Binding·Scene Binding
└─ lifecycleState

→ JournalCompiler

CompiledJournalDocument
├─ compilerVersion·contentHash
├─ parsedAst·compiledSections
├─ outlineEntries
├─ resolved·unresolved Link Descriptor
├─ searchTokens·backlinkContribution
└─ validationDiagnostics

→ JournalDocumentProjection
├─ publicDocumentRef·projectionRevision
├─ visibleSections·renderedAstSegments
├─ visibleOutline·visibleLinks·visibleAnchors
├─ permittedActions·editRevisionToken
└─ integrityState
```

Source는 사용자가 작성하고 관리하는 권위 원본이다. Compiled Build는 Source에서 재생성 가능한 불변 결과이며, Projection은 Viewer에게 공개 가능한 부분만 포함한다.

### 3.2 Document·Section Identity와 표시 문자열

```text
Document Ref
→ documentId + expectedRevision?

Section Ref
→ documentId + sectionId + expectedSectionRevision?

Link
→ Stable Target Descriptor + Authored Display Text + Disclosure Behavior
```

제목·Heading·경로와 표시 문자열은 Identity가 아니다. Rename·Move·Heading 변경은 같은 Node라면 ID를 유지하고 Revision을 증가시킨다.

### 3.3 Permission과 Viewer Context

```text
Journal ACL
+ Session Role·Ownership·Party·Campaign
+ Knowledge Snapshot·Active Scene
+ Frozen Policy Snapshot
→ JournalViewerContext
→ Discover·Read·Search·Navigate·Edit Projection
```

기본 Scope:

```text
private_dm
owner_and_dm
party
campaign
explicit_acl
```

권한 축소가 발생하면 Document Cache, Search·Backlink Index와 Anchor Metadata Projection을 우선 무효화한다.

### 3.4 Link Graph, Search와 Backlink

```text
Compiled Document Link Contribution
→ Server JournalLinkGraph
→ Permission-partitioned Search·Backlink Index
→ 최신 Permission·Disclosure 재검증
→ Viewer별 Search Result·Backlink Projection
```

Search는 Document Title·Alias, Section Heading, 본문 Token, Tag와 공개 가능한 Anchor Label을 사용할 수 있다. Raw 비밀 Target 이름과 내부 ID는 일반 Search Token으로 사용하지 않는다.

### 3.5 Anchor Binding과 Runtime Resolution

```text
JournalAnchorBinding
├─ owner Document·Section
├─ anchorKind
├─ stableTargetRef
├─ runtimeResolutionPolicy
├─ disclosure·fallback Policy
├─ lastResolvedDescriptor
└─ lifecycleState·revision
```

```text
Anchor
+ Viewer Context
+ Active Scene·Published Build·AuthorityEpoch
→ 타입별 Resolver Registry
→ JournalNavigationCapability
```

Resolver는 Workspace를 이름으로 검색하지 않는다. Runtime Object Registry, Scene Build Mapping, Character·Item Registry와 Camera Bookmark Registry의 타입 있는 Read Port를 사용한다.

### 3.6 Journal Command와 Read Request

수정 Command 예:

```text
Create·Update·Rename·Move·Archive Document
Set Permission
Create·Retarget·Remove Anchor
Bind Scene Default Document
```

모든 수정은 Base Source Revision, 필요한 Section Revision, Client Edit Operation ID와 Idempotency Key를 검증한다.

Read Request 예:

```text
Open Document
Search
Resolve Link
List Backlinks
List Scene Bindings
Preview Audience
```

Read Request는 Source를 변경하지 않고 Viewer Context에 고정된 Projection만 반환한다.

### 3.7 Journal UI 상태

```text
Local Workspace State
→ Panel Dock·크기·Scroll·접힌 Section·최근 탭

Authority-bound Journal UI State
→ 현재 Document Projection·Permission·Edit Revision

Recoverable Draft
→ Base Public Revision·Scope·Rebase Policy가 있는 미제출 편집
```

Reconnect·Role Change·Rollback 후 Local Layout은 유지할 수 있지만 이전 Permission Projection과 Edit Revision을 그대로 재사용하지 않는다.

### 3.8 Ping Intent와 Signal

```text
PingIntent
→ Scene·World Position·Surface Normal·Audience

PathPingIntent
→ Scene·Sampled Points·Audience·Projection Preference
```

Server가 Sender, Role, Audience, Scene Scope, 좌표·Point 수·길이·Payload와 Rate Limit을 검증한 뒤 Presentation Signal을 만든다. Payload는 비공개 Entity Identity와 숨은 좌표를 포함하지 않는다.

## 4. 주요 실행 흐름

### 4.1 문서 열기와 Outline 탐색

```text
Open Journal Intent
→ 안전하게 복원 가능한 문서 확인
→ Scene Viewer용 기본 문서 확인
→ 최근 공개 문서 확인
→ Journal Home Fallback
→ Document Read Request
→ Permission-aware Projection
→ Visible Outline·본문 렌더
→ Section 선택 시 sectionId 기준 Scroll
```

Heading 문자열이나 화면 배열 위치를 Section 이동 권위로 사용하지 않는다.

### 4.2 문서 생성·편집과 Compile

```text
Edit Intent
→ 현재 Edit Permission·Base Revision 확인
→ Update Command
→ Payload·Section Operation·Anchor·ACL 검증
→ Source Revision Transaction
→ Candidate Compile
→ Compile 성공 시 Build Pointer 교체
→ Search·Backlink·Projection 갱신
```

Compile 실패 시 새 Source Draft의 오류를 작성자에게 보여 주되 공개 Runtime에는 마지막 정상 Compiled Document를 유지한다.

### 4.3 동시 편집 Conflict

```text
Client A·B가 같은 Revision 편집
→ A Commit
→ B가 오래된 Base Revision 제출
→ JournalEditConflict
→ 충돌 Section·Server 변경 범위·Merge 가능 Operation Projection
→ 최신 문서 재동기화·사용자 Merge
```

Markdown 전체 문자열을 B의 내용으로 덮어쓰지 않는다.

### 4.4 문서·Section Rename과 Move

```text
Rename·Move Command
→ documentId·sectionId 유지
→ Title·Heading·Parent·Order 변경
→ Source Revision 증가
→ Compile·Projection·Search Label 갱신
→ 기존 Stable Link 유지
```

표시 Label 정책이 `live_label`이면 최신 공개 이름을, `authored_label`이면 작성 문구를 사용한다.

### 4.5 World Anchor 작성

```text
공개 또는 DM Target 선택
→ 타입 있는 Target Descriptor 생성
→ 작성자 create_links·Target Disclosure 검증
→ CreateJournalAnchorCommand
→ Source Revision·Compile
→ Viewer별 Link Metadata Projection
```

Player는 자신의 권한 밖 Target을 Anchor 후보로 열거할 수 없다. DM의 비밀 Anchor도 Player Projection에 Raw Metadata를 전달하지 않는다.

### 4.6 Scene Republish와 Source Object Anchor

```text
Scene Source Object Anchor
→ 새 Published Build 활성화
→ Source Object Mapping 조회
→ 현재 Runtime Object Projection으로 재결합
→ 공개·권한 재검증
```

Source Identity가 유지되면 Runtime Object가 교체되어도 장기 Link를 유지할 수 있다.

### 4.7 Runtime Object 삭제·Respawn·Rollback

```text
Runtime Object Anchor
→ 현재 runtimeObjectId·incarnation·authorityEpoch 검사
→ 불일치·삭제·Archive 감지
→ stale_incarnation | broken_reference | archived_target
→ 자동 이름 Retarget 금지
```

Rollback 후 이전 Resolution Cache와 Navigation Capability를 폐기하고 새 Branch에서 다시 해결한다.

### 4.8 Journal Link 활성화와 Camera Focus

```text
Link Click
→ ResolveJournalLinkRead
→ JournalNavigationCapability
→ focus_camera 허용 여부 확인
→ CameraRequest 제출
→ Camera Runtime이 Target·Priority·Motion Safety 재검증
```

Camera 이동 실패나 사용자의 취소가 Journal 문서와 Gameplay State를 변경하지 않는다.

### 4.9 Journal Link와 Selection

```text
Link Click
→ 공개 가능한 Selection Binding Candidate
→ Selection Intent 제출
→ Selection Runtime이 현재 Snapshot·Eligibility 재검증
→ Selection View 갱신
```

문서에 링크가 있다는 이유만으로 미발견 함정, 비공개 Actor와 사용할 수 없는 Object를 Selection Candidate로 공개하지 않는다.

### 4.10 다른 Scene Link

```text
Journal Link Resolve
→ SceneTransitionProposal
→ Role·Permission·Mode·Encounter·RuleExecution Gate
→ 사용자·DM 확인
→ Session Transition Runtime
```

Journal은 Scene를 즉시 교체하지 않는다.

### 4.11 Actor·Object에서 연결 문서 열기

```text
Actor·Object Context Menu
→ ListLinkedJournalDocumentsRead
→ Viewer별 공개 문서·Section Projection
→ Open Document Intent
```

비공개 문서의 제목, 존재와 Link Count를 Context Menu에 표시하지 않는다.

### 4.12 Search와 Backlink

```text
Search Query
→ Permission-partitioned Index Candidate
→ 최신 ACL·Disclosure 재검증
→ 공개 Snippet·Heading Path·Tag·Navigation Capability
→ Virtualized Result Page
```

비공개 결과의 개수를 별도 Hidden Count로 제공하지 않는다. Backlink도 Viewer가 볼 수 있는 Source 문서만 포함한다.

### 4.13 Markdown Import

```text
Markdown 입력
→ Size·Node·Link·Depth 검증
→ AST Preview
→ Wiki Link Target 후보 조회
→ 권한 있는 후보만 표시
→ 사용자 Target 확정
→ 새 Stable Document·Section·Link Identity 생성
→ Import Command·Compile
```

제목 유사도만으로 기존 Section ID와 동명 문서를 자동 선택하지 않는다.

### 4.14 Markdown Export

```text
Export Intent
→ Export Permission 검증
→ 공개 가능한 Document·Section 선택
→ 내부 Identity·ACL·Secret Anchor 제거
→ Portable Markdown 생성
```

완전한 관리용 Backup은 일반 Export와 분리된 DM·Admin Command와 Audit를 사용한다.

### 4.15 위치 핑

```text
Semantic Ping Input
→ 공개 가능한 표면 위치 클릭
→ PingIntent 제출
→ Server Scene·좌표·Audience·Rate 검증
→ Presentation Signal
→ Audience Client에 위치 표시
→ Lifetime 만료
```

Client가 보낸 좌표를 그대로 신뢰하지 않으며 핑 표시 위치를 Actor·Object 권위 위치로 저장하지 않는다.

### 4.16 경로 핑

```text
Ping Drag 시작
→ Sample 수집
→ 공개 가능한 표면 투영
→ 경로 간소화
→ 마우스 해제
→ PathPingIntent 제출
→ Server 검증
→ Audience별 경로 Presentation
```

작성 중 Q는 현재 Ping Draft만 취소한다. Targeting, Scene Edit, Fog Edit, Drag와 Text Input이 더 높은 Input Context이면 Ping 입력을 소비하지 않는다.

### 4.17 Ping Audience와 비밀 정보

```text
party | campaign | selected_users | private_dm
```

Player는 허용된 Audience만 선택하고 DM은 전체, 특정 Player와 DM 전용 Ping을 사용할 수 있다. Ping은 숨은 Entity Identity와 권한 밖 좌표를 Payload·Label·Diagnostics에 넣지 않는다.

### 4.18 Ping 혼잡·실패·재접속

```text
과도한 Ping
→ Rate Limit·Merge·Payload 상한

Presentation 실패
→ 해당 표시 생략·진단
→ Gameplay 계속

Reconnect
→ 아직 유효한 정책 대상만 처리
→ 만료 Ping 재생 안 함
```

Ping Signal 손실은 Authority Projection Sequence Gap으로 취급하지 않는다.

### 4.19 Role·Permission 변경

```text
Role·ACL·Knowledge 변경
→ Journal Projection·Search·Backlink Cache 무효화
→ 권한 없는 열린 Document Segment 제거
→ Edit·Navigation Capability 폐기
→ Input Context·Panel 재조정
```

Player Client에 이전 DM Projection을 남긴 채 화면에서만 숨기지 않는다.

### 4.20 Server Recovery와 Rollback

```text
Server Recovery
→ Journal Source·History Pointer 복원
→ Compiled Build 확인·필요 시 재Compile
→ Derived Search·Backlink·Anchor Index 재생성
→ Viewer Projection 생성

Encounter Rollback
→ Journal Source Revision 유지
→ 새 AuthorityEpoch에서 Runtime Anchor Resolution 재평가
→ 이전 Navigation Capability·Cache 폐기
```

Ping은 Recovery Snapshot에서 복구하지 않는다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Source·Build·Projection, Command·Read와 Roblox Instance 권위 경계
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Journal Projection Segment, Read Request, Command Result와 Epoch-safe Client Sync
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Journal Panel, Recoverable Draft, Semantic Input, Intent와 Cache 폐기
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md) — Source History, Compile Pointer, Snapshot·Journal 명칭 분리와 Rollback
- [`Visibility, Knowledge, Detection과 Hover Information`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md) — Document·Anchor·Target Disclosure와 Player Audience Projection

### Child Authority

- [`Journal Document, Section, Anchor, Permission, Search와 Projection Runtime`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md) — Journal Source·Build·Identity·ACL·Search·Anchor·Navigation·Recovery
- [`Journal 시스템 README`](../../systems/journal/README.md) — 권위 진입점, 고정 경계와 후속 Spec 순서
- [`위치 핑과 경로 핑 모델`](../../systems/journal/two-mode-ping-model.md) — 클릭·드래그 Ping Intent, Audience·검증·수명주기와 비권위 경계

### References

- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md) — Runtime Object Identity, Incarnation과 Archive
- [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md) — Scene Source Object와 Published Build Mapping
- [`Selection, Targeting, Preview와 Frozen Binding`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md) — Journal Navigation의 Selection Candidate와 Ping보다 높은 Targeting Context
- [`Camera Policy, Focus, Follow와 Presentation Runtime`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md) — Journal CameraRequest와 안전한 Target Projection
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md) — Ping Signal, Highlight와 비권위 Playback
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Scene Transition Proposal, Role·Mode Gate와 Panel·Mode 분리
- [`Diagnostics와 Observability Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md) — Journal Compile·Permission·Search·Anchor Trace와 Ping Redaction
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md) — Identity·Disclosure·Rollback·Signal Failure Scenario
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md) — Q 취소와 Context Stack, Ping·Journal 입력 의미
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md) — Journal Panel, Scene 문서와 Camera Bookmark Surface
- [`UI, Camera와 Presentation Guide`](../ui/README.md) — Projection·Input·CameraRequest·Presentation의 Client 공통 흐름
- [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation Guide`](../scene/README.md) — Anchor Target과 Scene Build·Runtime Presence 경계
- [`Exploration, Selection, Interaction과 Perception Guide`](../exploration/README.md) — World Focus·Selection·Disclosure와 Ping Input 경계
- [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Viewer Role·Reconnect·Scene Transition·Rollback 흐름

권위 읽기 순서에서 제외:

- [`링크형 문서와 두 모드 핑 시스템`](../../systems/journal/linked-journal-and-two-mode-ping-model.md) — `SUPERSEDED`; 최신 Journal Architecture와 Ping Feature Model이 분리해 대체한다.

## 6. 다른 시스템과의 경계

| 인접 시스템 | Journal·Ping이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 |
|---|---|---|---|
| UI Runtime | Document·Search·Backlink·Edit View, Journal·Ping Intent | Projection Replica, Panel·Draft·Input Context·Focus와 Reconciliation | UI Runtime, Journal Runtime |
| Networking | Journal Command·Read·Projection Segment, Ping Signal Payload | Epoch·Sequence·Readiness·Command Result와 Audience Delivery | Networking 계약 |
| Visibility·Knowledge | ACL·Anchor Disclosure 입력과 공개 Projection | Target이 알려졌고 공개 가능한지에 대한 Observer 판정 | Visibility Runtime, Journal Runtime |
| Runtime Object·Scene | Stable Anchor Descriptor와 Resolution 상태 | Source Object Mapping, Runtime Identity·Incarnation·Current Build | Journal Runtime, Runtime Object·Scene Compiler |
| Selection | 공개 Selection Candidate와 Intent | 최신 Candidate·Frozen Binding·Eligibility 검증 | Journal Runtime, Selection Runtime |
| Camera | 안전한 Camera Target과 CameraRequest | Focus·Follow·Priority·Motion Safety·복원 | Journal Runtime, Camera Runtime |
| Session·Transition | Scene Link Proposal과 Scene Journal Binding | Role·Mode·Encounter Gate와 실제 Scene Transition | Journal Runtime, Session Runtime |
| Presentation | Ping·Highlight·Link Feedback Intent | Queue·Audience·Lifetime·Fallback와 Client Playback | Ping Model, Presentation Runtime |
| Navigation | 경로 Ping의 시각 투영 후보 | 실제 Navigation Surface·Path·Movement Authority | Ping Model, Navigation Runtime |
| Persistence | Journal Source·Revision·History·Binding | Snapshot·Manifest·Branch·Recovery Infrastructure | Journal Runtime, Persistence 계약 |
| Diagnostics·Testing | Journal·Ping Trace Hook과 공개 가능한 Support 상태 | Redaction, Scenario·Fault·Disclosure Assertion | Diagnostics·Simulation Runtime |

고정 경계:

- Journal 제목·Heading·표시 이름과 Search Rank를 Identity로 사용하지 않는다.
- Journal은 다른 Domain Store, Camera, Selection과 Scene Transition을 직접 수정하지 않는다.
- Ping은 Journal Anchor, NavigationPlan, Movement Command와 Frozen Binding이 아니다.
- Ping Presentation의 성공·실패·손실·만료는 Gameplay 권위와 Projection Sequence를 변경하지 않는다.
- 사용자 Journal Source와 Transaction Recovery Journal은 같은 저장소·수명주기·Rollback 정책을 사용하지 않는다.
- 권한 없는 정보는 UI·Search·Backlink·Anchor·Navigation·Ping·Diagnostics 어디에도 전달하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
   - Source·Build·Projection과 Command·Read의 공통 권위 원칙을 확인한다.
2. [`ADR-0044`](../../decisions/ADR-0044-linked-journal-and-two-mode-ping-system.md)
   - Obsidian형 편집, Docs형 탐색, World Link와 두 Ping 종류의 제품 결정을 읽는다.
3. [`ADR-0086`](../../decisions/ADR-0086-stable-journal-identities-permission-partitioned-search-and-safe-world-navigation.md)
   - 안정적 ID, Permission Search, 자동 Retarget 금지와 안전한 Navigation 결정을 읽는다.
4. [`Journal Runtime`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
   - Source·Build·Identity·Permission·Anchor·Search·Navigation·Recovery 전체 계약을 읽는다.
5. [`Journal 시스템 README`](../../systems/journal/README.md)
   - 현재 권위 진입점과 후속 Implementation Spec 순서를 확인한다.
6. [`위치 핑과 경로 핑 모델`](../../systems/journal/two-mode-ping-model.md)
   - Ping 입력·Audience·검증·수명주기와 금지 경계를 읽는다.
7. [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)과 [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
   - Journal Panel, Draft, Q와 Ping Input Context를 확인한다.
8. [`Visibility Runtime`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
   - 문서·Anchor·Target의 공개 가능성을 확인한다.
9. [`Runtime Object`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)와 [`Scene Compiler`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
   - Source Object와 Runtime Incarnation Anchor를 구분한다.
10. [`Selection Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md), [`Camera Runtime`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md), [`Session Runtime`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
    - Navigation Capability가 실제 요청으로 연결되는 경계를 읽는다.
11. [`Presentation Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
    - Ping Signal과 Feedback Playback의 비권위 경계를 읽는다.
12. [`Diagnostics Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)과 [`Simulation Runtime`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)
    - 정보 누출, Conflict, Republish, Rollback과 Signal Failure 검증을 확인한다.
13. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
    - 남은 항목이 의미 결정이 아니라 측정형 기본값인지 확인한다.

## 8. 구현·검증 순서

현재 권위 문서에서 도출되는 권장 순서:

1. **Document·Folder·Section Source와 Revision**
   - 안정적 Identity, Lifecycle, Source Store, optimistic concurrency와 Source History를 먼저 구현한다.
2. **Markdown Compiler와 Compiled Document Registry**
   - AST, Outline, Section Mapping, Link Descriptor, Last-known-good Activation과 Validation을 구현한다.
3. **Permission Resolver와 Projection Builder**
   - Discover·Read·Search·Navigate·Edit 권한, Viewer Context와 Negative Disclosure를 구현한다.
4. **Search·Backlink·Reverse Index**
   - Permission-partitioned Index, 최신 ACL 재검증, Snippet과 Cache 무효화를 구현한다.
5. **Anchor Resolver Registry와 Lifecycle**
   - Document, Character, Source Object, Runtime Object, Scene, Item, Coordinate와 Bookmark Resolver를 타입별로 구현한다.
6. **Safe Navigation Resolver**
   - JournalNavigationCapability, CameraRequest, Selection Intent와 SceneTransitionProposal 경계를 구현한다.
7. **Journal Command·Read·Conflict**
   - Edit·Permission·Anchor Command, Open·Search·Backlink·Audience Preview Read와 구조화된 Conflict를 구현한다.
8. **Journal UI Vertical Slice**
   - Scene 기본 문서, Folder·Document·Outline, Markdown View·Edit, Search와 Link Activation을 Projection 기반으로 연결한다.
9. **Import·Export와 Draft Recovery**
   - Wiki Link 확인, 안정적 ID 생성, Redacted Export와 Rebase 가능한 Draft를 구현한다.
10. **Ping Input·Validation·Presentation Slice**
    - 위치·경로 Intent, Sample 간소화, Audience, Rate Limit과 짧은 Playback을 별도 Feature로 구현한다.
11. **Persistence·Recovery·Rollback**
    - Source·Build Pointer 복구, Derived Index Rebuild, Epoch-safe Anchor Resolution과 Ping 비복구를 검증한다.
12. **Diagnostics·Simulation·Security**
    - Rename·Move·Republish·동명 Target·Permission 축소·Search·Backlink·Camera·Ping 누출과 Conflict Scenario를 자동화한다.

후속 Implementation Spec 파일 순서:

```text
specs/journal/001-document-section-source-and-revision.md
specs/journal/002-markdown-compiler-outline-and-link-graph.md
specs/journal/003-permission-projection-and-search-index.md
specs/journal/004-world-anchor-resolution-and-lifecycle.md
specs/journal/005-safe-navigation-camera-selection-and-scene-transition.md
specs/journal/006-edit-conflict-import-export-and-recovery.md
specs/journal/007-journal-simulation-and-disclosure-regression.md
```

Ping 전용 Spec의 정확한 파일 분할은 Implementation Specs 단계에서 확정한다.

필수 검증 Scenario:

- Document Rename·Folder Move 후 Link 유지
- Section Heading Rename·Move 후 Section Link 유지
- 외부 Markdown Import의 동명 문서 수동 선택
- Compile 실패 시 Last-known-good Build 유지
- 독립·충돌 Section 동시 편집과 Last-write-wins 금지
- 비공개 문서가 Search Hit·Count·Facet·Recent·Backlink에 나타나지 않음
- 공개 문서의 비공개 Target Link가 Raw ID·Label·좌표를 노출하지 않음
- DM Player View Preview와 실제 Player Projection 일치
- Scene Republish 후 Source Object Anchor 재결합
- Runtime Object Respawn·Rollback 후 이전 Incarnation Link 무효화
- 동명 Target 삭제 후 자동 Retarget 금지
- Permission 축소 직후 Client Document·Search·Backlink Cache 폐기
- Journal Camera Focus가 숨은 위치를 공개하지 않음
- Selection·Scene Transition이 최신 Gate에서 거부될 수 있음
- 사용자 Journal Source와 Encounter Rollback 수명주기 분리
- 위치 Ping 좌표 변조·Scene Scope·Rate Limit 검증
- 경로 Ping Sample·길이·Payload 상한과 비공개 Surface 차단
- Ping Signal 유실·VFX 실패·Reconnect 후 만료 Ping 미재생
- Player·DM·Observer별 Journal·Ping Audience Matrix와 Diagnostics Redaction

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Document·Section Identity·Revision 변경 | Journal Runtime, ADR-0086, Persistence | Journal 001·002 | `UPDATE_REQUIRED` |
| Markdown Compile·Outline·Link Graph 변경 | Journal Runtime | Journal 002 | `UPDATE_REQUIRED` |
| Permission Scope·Grant·Disclosure 변경 | Journal Runtime, Visibility, UI | Journal 003·007 | `UPDATE_REQUIRED` |
| Search·Backlink·Snippet 정책 변경 | Journal Runtime | Journal 003·007 | `UPDATE_REQUIRED` |
| Anchor Type·Lifecycle·Resolver 변경 | Journal Runtime, Runtime Object, Scene Compiler | Journal 004 | `UPDATE_REQUIRED` |
| Navigation Capability·Camera·Selection·Transition 변경 | Journal Runtime, Camera, Selection, Session | Journal 005 | `UPDATE_REQUIRED` |
| Edit Conflict·Import·Export 변경 | Journal Runtime, UI | Journal 006 | `UPDATE_REQUIRED` |
| Rollback·Recovery·AuthorityEpoch 변경 | Journal Runtime, Persistence, Session | Journal 004·006·007 | `UPDATE_REQUIRED` |
| Ping 종류·Audience·Authority 성격 변경 | Ping Model, ADR-0044, Presentation | 향후 Ping Spec | `UPDATE_REQUIRED` |
| Ping Input·Rate·Payload·Lifetime 수치 변경 | Ping Model, UI, Networking, Presentation | 향후 Ping Spec | 의미 변화가 있을 때만 갱신 |
| Journal UI Layout·Outline 표시 변경 | UI Runtime, Journal Runtime, DM Workspace | 향후 Journal UI Spec | 의미·탐색 흐름 변화 시 갱신 |
| 진단·Simulation·Disclosure Assertion 변경 | Diagnostics, Simulation, Journal Runtime | Journal 007 | `UPDATE_REQUIRED` |
| ADR 대체·문서 Lifecycle 변경 | 해당 ADR, Document Lifecycle, Completion Audit | 전체 영향 Spec | `UPDATE_REQUIRED` |

## 10. Authority Documents

### Product

- [`핵심 세션 흐름과 플레이 모드`](../../product/core-session-loop.md)
- [`콘텐츠 자동화, Rollback, 저장과 비목표`](../../product/content-automation-rollback-storage-and-exclusions.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`Journal Document, Section, Anchor, Permission, Search와 Projection Runtime`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Scene Compiler와 Compiled Runtime Scene`](../../architecture/scene-compiler-and-compiled-runtime-scene-contract.md)
- [`Selection, Targeting, Preview와 Frozen Binding`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Visibility, Knowledge, Detection과 Hover Information`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Camera Policy, Focus, Follow와 Presentation Runtime`](../../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
- [`Presentation Recipe, Playback Priority와 Extension Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Diagnostics와 Observability Runtime`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)
- [`Deterministic Simulation과 Test Harness`](../../architecture/deterministic-simulation-scenario-and-test-harness-runtime-contract.md)

### Systems·UI

- [`Journal 시스템`](../../systems/journal/README.md)
- [`위치 핑과 경로 핑 모델`](../../systems/journal/two-mode-ping-model.md)
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md)

### Specs

- [`Implementation Specs Index`](../../specs/README.md)
- Journal·Ping 전용 Specs: Main System Guide 단계 이후 작성 예정

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

### 제외된 역사 문서

- [`링크형 문서와 두 모드 핑 시스템`](../../systems/journal/linked-journal-and-two-mode-ping-model.md) — `SUPERSEDED`

## 11. ADR References

- [`ADR-0044`](../../decisions/ADR-0044-linked-journal-and-two-mode-ping-system.md) — Obsidian형 편집, Docs형 탐색, World Link와 위치·경로 Ping
- [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md) — Runtime Object Identity·Incarnation과 Lifecycle
- [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md) — Versioned Command·Projection과 Client Sync
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Journal Source 수정의 원자 Transaction
- [`ADR-0063`](../../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md) — Snapshot·Commit Journal·Branch Recovery와 사용자 Journal 분리
- [`ADR-0071`](../../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md) — Journal·Ping Input Context와 Selection Intent
- [`ADR-0073`](../../decisions/ADR-0073-observer-relative-visibility-knowledge-and-hover-projections.md) — Observer별 문서·Anchor·Target Disclosure
- [`ADR-0074`](../../decisions/ADR-0074-projection-only-camera-policies-with-separate-focus-and-follow.md) — 안전한 Journal CameraRequest
- [`ADR-0075`](../../decisions/ADR-0075-versioned-data-driven-and-fault-isolated-presentation-runtime.md) — Ping Presentation과 실패 격리
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Journal Permission·Disclosure Policy Snapshot
- [`ADR-0083`](../../decisions/ADR-0083-projection-driven-ui-runtime-and-epoch-safe-client-recovery.md) — Journal UI Projection·Draft·Epoch-safe Recovery
- [`ADR-0084`](../../decisions/ADR-0084-correlated-authority-traces-and-permission-aware-observability.md) — Journal·Ping Trace Redaction과 Support Projection
- [`ADR-0085`](../../decisions/ADR-0085-production-parity-deterministic-scenarios-and-controlled-nondeterminism.md) — Journal Identity·Disclosure와 Ping Failure Scenario
- [`ADR-0086`](../../decisions/ADR-0086-stable-journal-identities-permission-partitioned-search-and-safe-world-navigation.md) — 안정적 Identity, Permission Search, Anchor Lifecycle와 안전한 Navigation

## 12. 알려진 비목표와 측정형 기본값

권위 문서에서 확정된 비목표:

- 제목·경로·Heading·표시 이름을 Journal Identity로 사용하지 않는다.
- Client에 Raw Journal, 전체 Link Graph와 Search Index를 보내고 화면에서만 숨기지 않는다.
- Target 삭제 시 동명 대상에 자동 Retarget하지 않는다.
- Journal Runtime이 Camera·Selection·Workspace·Scene Transition을 직접 조작하지 않는다.
- Encounter Rollback으로 사용자 Journal Source를 자동 되돌리지 않는다.
- 사용자 Journal과 Transaction Recovery Journal을 같은 Schema와 저장물로 사용하지 않는다.
- Markdown에서 임의 HTML, Script, Luau와 외부 Resource를 자동 실행하지 않는다.
- Ping을 Journal Anchor, 이동 경로, Selection, Camera Bookmark 또는 Gameplay Command로 사용하지 않는다.
- Ping Presentation Signal 손실을 Authority Event Gap으로 취급하지 않는다.
- Ping을 Recovery Snapshot에 저장하거나 만료 후 재생하지 않는다.

Implementation Spec에서 측정·확정할 기본값:

- 문서·Section 최대 크기와 단일 수정 Command 최대 변경량
- 자동 저장 Debounce, Draft 보존 기간과 Merge UI 정책
- Viewer별 Search 결과 수, Snippet 길이와 연산 Budget
- Search·Backlink·Anchor 재색인 Batch와 지연 허용 시간
- 삭제·Archive Anchor Target Tombstone 보존 기간
- 공개 문서의 비공개 Anchor 표시 `plain_text`·`omit` 캠페인 기본값
- Scene 진입 기본 문서와 최근 문서 복원 우선순위
- Markdown Import Section ID 생성·재사용 기준
- Section ACL 초기 공개 여부
- Ping Sample 수, 총 길이, Payload Byte와 Rate Limit
- Ping Merge Policy, Presentation Lifetime과 Client 품질 Variant
- Journal·Ping 전용 Module·Type·Command·Projection Segment 파일 배치

남은 비차단 작업:

- Journal·Ping Implementation Specs 작성
- Markdown Editor와 Journal Panel 상세 UI Spec
- Search·Index·Large Document 성능 프로파일링
- Ping 시각 Profile과 접근성 표시 플레이테스트
- Deterministic Disclosure·Conflict·Recovery Test Suite 구현

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent Authority, Child Authority와 References를 구분했다.
- [x] Journal과 Ping의 Authority·Persistence·수명주기를 분리했다.
- [x] 최신 ADR과 현재 존재하는 Specs 상태를 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 권위 읽기 순서에서 제외했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.