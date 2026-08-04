# ADR-0086: 안정적 Journal Identity, Permission-partitioned Search와 안전한 World Navigation

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Journal Document, Section, Anchor, Permission, Search와 Projection Runtime 계약`](../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`Selection Runtime 계약`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Visibility, Knowledge와 Detection Runtime 계약`](../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - [`Camera Runtime 계약`](../architecture/camera-policy-focus-follow-and-presentation-runtime-contract.md)
  - [`UI Runtime 계약`](../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)
  - [`Persistence와 Recovery 계약`](../architecture/persistence-and-session-recovery-model.md)

## 배경

RVTT Journal은 Markdown 문서, 문서 내부 Section, Obsidian형 Wiki Link와 Actor·오브젝트·Scene·Camera Bookmark 같은 월드 대상을 연결한다.

제목과 Markdown 문자열만으로 링크를 관리하면 다음 문제가 발생한다.

- 문서·Heading Rename과 이동으로 Link가 끊김
- 동명 문서·오브젝트에 잘못 연결됨
- Scene Republish, Respawn과 Rollback 이후 오래된 Runtime Reference가 남음
- 비공개 문서의 제목·검색 Hit·Backlink·Anchor Label이 Player에게 노출됨
- Journal Link가 Camera와 Selection을 직접 조작해 Disclosure를 우회함
- 동시 편집이 마지막 저장으로 조용히 덮어써짐

## 결정

### 1. Document와 Section은 제목·경로와 분리된 안정적 ID를 가진다

```text
JournalDocumentRef
→ documentId

JournalSectionRef
→ documentId + sectionId
```

문서 제목, 폴더 경로, 파일명, Heading Text와 배열 위치를 Identity로 사용하지 않는다.

Rename과 Move는 Identity를 유지하고 Revision만 증가시킨다.

### 2. Journal Source, Compiled Build와 Viewer Projection을 분리한다

```text
JournalDocumentSource
→ Journal Compiler
→ Immutable CompiledJournalDocument
→ Permission-aware JournalDocumentProjection
```

Markdown Source만 저장 원본으로 사용하지 않고 Section Identity, Permission, Anchor와 Scene Binding을 타입 있는 Source Metadata로 보존한다.

Compile 실패 시 마지막 정상 Build를 유지한다.

### 3. 문서와 Section의 존재 자체에 Permission과 Disclosure를 적용한다

기본 Scope:

```text
private_dm
owner_and_dm
party
campaign
explicit_acl
```

권한 없는 사용자는 본문뿐 아니라 제목, Section Outline, 검색 결과, Backlink, Anchor Metadata와 결과 수에도 접근할 수 없다.

Client가 Raw Journal이나 전체 Search Index를 받은 뒤 화면에서 숨기는 방식을 금지한다.

### 4. Search와 Backlink는 Server-side Permission Projection이다

Search는 Permission-partitioned Index를 사용하고 결과 반환 직전에 최신 ACL과 Disclosure를 다시 검증한다.

비공개 문서와 Section은 검색 Hit, Count, Facet와 Backlink Count에 포함하지 않는다.

### 5. World Link는 타입 있는 Anchor를 사용한다

지원 대상은 Document·Section, Character, Actor, Scene Source Object, Runtime Object, Scene, Region, Encounter, Item, Spell, Coordinate와 Camera Bookmark 등이다.

장기 Link는 가능한 한 Scene Source Identity를 사용하고, 특정 Runtime Incarnation이 의미가 있을 때만 `runtimeObjectId + incarnation + authorityEpoch`를 사용한다.

### 6. 이름 기반 자동 Retarget을 금지한다

Target이 삭제되거나 찾을 수 없을 때 같은 이름의 다른 Target으로 자동 연결하지 않는다.

Link는 `broken_reference`, `stale_incarnation`, `archived_target` 등의 상태로 보존한다. 새 Target 연결은 명시적인 Retarget Command와 Source Revision으로 처리한다.

### 7. Journal Link는 안전한 Navigation Capability만 생성한다

```text
Journal Link Activation
→ Permission-aware Resolve
→ JournalNavigationCapability
→ CameraRequest / Selection Intent / SceneTransitionProposal
```

Journal Runtime은 Camera, Selection Store, Workspace와 Scene Transition을 직접 조작하지 않는다.

Target은 공개 가능한 Projection Reference 또는 안전한 Transform Snapshot이어야 한다.

### 8. Revision 기반 동시 편집을 사용한다

모든 수정은 Base Source Revision과 필요한 Section Revision을 제출한다.

충돌 시 구조화된 Conflict를 반환하며 Markdown 전체를 Last-write-wins로 덮어쓰지 않는다.

### 9. 사용자 Journal과 Recovery Journal을 분리한다

사용자가 작성하는 Journal Document는 Authority Transaction 복구용 Journal이 아니다.

Encounter Rollback은 사용자 Journal Source를 자동으로 되돌리지 않는다. 대신 새 AuthorityEpoch에서 World Anchor Resolution과 Projection을 다시 계산한다.

### 10. Disclosure 회귀를 Deterministic Scenario로 검증한다

문서 Rename, Section Move, Scene Republish, Rollback, Permission 축소, Search·Backlink 누출, 비공개 Anchor와 Camera Focus를 필수 Scenario로 유지한다.

## 선택하지 않은 대안

### 문서 제목과 Heading 문자열을 Link Key로 사용

Rename과 동명 충돌에 취약하므로 선택하지 않았다.

### Client에 전체 문서와 Search Index를 보내고 UI에서 숨김

비밀 제목, Target과 검색 통계를 추출할 수 있으므로 선택하지 않았다.

### 삭제된 Target을 이름으로 자동 재연결

의도하지 않은 오브젝트와 비밀 대상에 연결될 수 있으므로 선택하지 않았다.

### Journal Link가 Camera·Selection을 직접 호출

공개 정책, Input Context와 Runtime 책임을 우회하므로 선택하지 않았다.

### 모든 Journal 편집을 하나의 전역 Lock으로 직렬화

장시간 편집과 여러 문서의 독립 작업을 불필요하게 차단하므로 선택하지 않았다.

### Encounter Rollback에 모든 문서 편집을 포함

사용자 메모와 캠페인 문서가 전투 Branch와 같은 수명주기를 가지지 않으므로 선택하지 않았다.

## 결과

### 장점

- Rename·Move와 Scene Republish 후에도 Link가 안정적으로 유지된다.
- 동명 Target과 오래된 Incarnation에 잘못 연결되지 않는다.
- 문서·Search·Backlink·Anchor의 정보 공개 경계가 일관된다.
- Camera·Selection과 Scene 이동이 기존 Runtime 계약을 재사용한다.
- 동시 편집과 Compile 실패를 안전하게 복구할 수 있다.
- Deterministic Harness에서 Journal 보안과 수명주기를 재현할 수 있다.

### 비용

- Markdown Source 외에 Section Identity Map, ACL과 Anchor Metadata를 보존해야 한다.
- Permission-aware Search·Backlink Index와 Cache 무효화가 필요하다.
- 각 Anchor Type에 Resolver Adapter와 Lifecycle 처리가 필요하다.
- Import·Export에서 내부 Identity와 Portable Markdown 사이의 변환이 필요하다.

이 비용은 캠페인 문서가 커진 뒤 Link와 비밀 정보 경계를 다시 설계하는 비용보다 작다.
