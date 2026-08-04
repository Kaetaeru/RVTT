# Journal 시스템

Obsidian형 Markdown 문서, Docs형 빠른 탐색, 안정적 Document·Section Identity, World Anchor, 권한별 Search·Backlink와 안전한 월드 이동을 다룬다.

## 권위 문서

- [`Journal Document, Section, Anchor, Permission, Search와 Projection Runtime 계약`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
  - 제목·경로와 분리된 `documentId`, `sectionId`와 Revision
  - Markdown Source→Compiled Document→Permission-aware Projection
  - `private_dm`, `owner_and_dm`, `party`, `campaign`, 명시적 ACL
  - Actor·Character·Scene Source Object·Runtime Object·Scene·Region·Camera Bookmark Anchor
  - 삭제·Archive·Scene Republish·Rollback·Incarnation 변경 시 Link 수명주기
  - Permission-partitioned Search·Backlink·Outline과 비밀 정보 차단
  - Journal Link→Navigation Capability→CameraRequest·Selection Intent·SceneTransitionProposal
  - 동시 편집 Conflict, Import·Export, Persistence와 Simulation
- [`ADR-0086`](../../decisions/ADR-0086-stable-journal-identities-permission-partitioned-search-and-safe-world-navigation.md)
  - 안정적 Identity, 이름 기반 자동 Retarget 금지와 안전한 World Navigation 결정
- [`ADR-0044`](../../decisions/ADR-0044-linked-journal-and-two-mode-ping-system.md)
  - Obsidian형 편집, Docs형 탐색, 월드 Link와 두 모드 Ping의 제품 방향

## 기능 문서

- [`위치 핑과 경로 핑 모델`](two-mode-ping-model.md)
  - 짧은 클릭 위치 핑과 드래그 경로 핑
  - 비권위 Presentation, Audience, Input Context와 Rate Limit
- [`링크형 문서와 두 모드 핑 시스템`](linked-journal-and-two-mode-ping-model.md)
  - `SUPERSEDED`; 초기 결합 모델로만 보존한다.

## 기본 흐름

```text
JournalDocumentSource
→ Journal Compiler
→ Immutable CompiledJournalDocument
→ Viewer별 Document·Outline·Search·Backlink Projection
→ UI ViewModel
→ Read Request 또는 Command
```

월드 링크 흐름:

```text
Journal Link 클릭
→ Permission-aware Resolve
→ JournalNavigationCapability
→ CameraRequest / Selection Intent / SceneTransitionProposal
```

## 고정 경계

- 문서 제목, 폴더 경로, 파일명과 Heading Text를 Identity로 사용하지 않는다.
- 동명 문서·Actor·오브젝트를 이름으로 자동 연결하지 않는다.
- 장기 Scene Link는 가능한 한 Source Object Identity를 사용한다.
- Runtime Object Link는 `runtimeObjectId + incarnation + authorityEpoch`를 검증한다.
- 권한 없는 문서와 Section은 제목, 존재, Search Hit, Result Count, Backlink와 Anchor Metadata까지 Projection하지 않는다.
- Raw Journal, 전체 Link Graph와 Search Index를 Player Client에 전달하지 않는다.
- Journal은 Camera, Selection Store, Workspace와 Scene Transition을 직접 조작하지 않는다.
- Encounter Rollback은 사용자 Journal Source를 자동으로 되돌리지 않고 Anchor Resolution만 새 Epoch에서 다시 계산한다.
- 사용자 Journal과 Transaction Recovery Journal을 같은 데이터로 취급하지 않는다.
- Compile 실패 시 마지막 정상 Compiled Document를 유지한다.
- 편집 충돌은 Revision Conflict로 반환하고 Last-write-wins를 사용하지 않는다.

## 역할 경계

- 플레이어는 자신에게 공개된 문서를 읽고 검색하며 Grant가 있을 때 편집·Link Authoring을 수행한다.
- DM은 Permission, Scene 기본 문서, 비밀 Anchor와 Player Audience Preview를 관리한다.
- Observer는 허용된 읽기 Projection만 받는다.
- 시스템은 Identity, Compile, Permission Projection, Search·Backlink Index와 Anchor Resolution을 담당한다.

## 후속 구현 명세

- `specs/journal/001-document-section-source-and-revision.md`
- `specs/journal/002-markdown-compiler-outline-and-link-graph.md`
- `specs/journal/003-permission-projection-and-search-index.md`
- `specs/journal/004-world-anchor-resolution-and-lifecycle.md`
- `specs/journal/005-safe-navigation-camera-selection-and-scene-transition.md`
- `specs/journal/006-edit-conflict-import-export-and-recovery.md`
- `specs/journal/007-journal-simulation-and-disclosure-regression.md`

실제 구현 순서는 `../../CURRENT-WORK-ORDER.md`를 따른다.

## Guide 상태

```text
Guide Status: READY_TO_WRITE
```

최신 Completion Audit에서 Journal Architecture와 Ping Feature Model의 구조적 차단 항목이 없으며, 남은 값은 구현·성능 측정형 기본값이다.