# 링크형 문서와 두 모드 핑 시스템

- 상태: `SUPERSEDED`
- 대체 판정일: 2026-08-04
- 대체 문서:
  - [`Journal Document, Section, Anchor, Permission, Search와 Projection Runtime 계약`](../../architecture/journal-document-section-anchor-permission-search-and-projection-runtime-contract.md)
  - [`위치 핑과 경로 핑 모델`](two-mode-ping-model.md)
- 관련 결정:
  - [`ADR-0044`](../../decisions/ADR-0044-linked-journal-and-two-mode-ping-system.md)
  - [`ADR-0086`](../../decisions/ADR-0086-stable-journal-identities-permission-partitioned-search-and-safe-world-navigation.md)

이 문서는 Journal 권위 구조와 Ping 제품 동작을 한 파일에 함께 정의한 초기 모델이다.

현재 판단에서는 다음처럼 분리한다.

```text
Journal Document·Section·Permission·Anchor·Search·Projection
→ 최신 Journal Architecture 계약

클릭 위치 핑·드래그 경로 핑
→ 위치 핑과 경로 핑 System Feature Model
```

문서 제목, Heading 문자열과 이름 기반 World Link를 현재 Identity 계약으로 사용하지 않는다. 최신 Journal 문서는 안정적 `documentId`, `sectionId`, 타입 있는 Anchor와 Permission-aware Projection을 사용한다.
