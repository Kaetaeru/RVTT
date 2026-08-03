# ADR-0044: 문서 시스템은 Obsidian형 편집, Docs형 탐색과 월드 링크를 결합한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`08. 공통 입력 교과서`](../ui/common-input/common-input-grammar.md)
  - [`30. 시야·감각·은신·탐지 모델`](../systems/perception/visibility-senses-stealth-and-detection-model.md)
  - [`31. 상호작용 프리팹 모델`](../systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md)
  - [`38. 링크형 문서와 핑 시스템`](../systems/journal/linked-journal-and-two-mode-ping-model.md)

## 결정

RVTT의 문서는 Markdown 기반 Obsidian형 편집기를 사용하되, 왼쪽에는 Google Docs와 유사한 문서·제목 탐색 패널을 둔다.

문서 제목과 본문의 링크는 다른 문서뿐 아니라 다음 엔티티를 참조할 수 있다.

- Actor와 Character
- 장면 오브젝트
- Scene
- 인카운터
- 아이템과 주문
- DM 전용 방 번호·구역 번호
- 좌표와 카메라 북마크

문서 권한은 `private_dm`, `owner_and_dm`, `party`, `campaign` 범위를 지원한다. DM 전용 링크 대상과 숨겨진 문서는 권한 없는 클라이언트에 내용과 존재를 전송하지 않는다.

핑은 두 종류만 제공한다.

```text
클릭
→ 위치 핑

드래그
→ 시작점에서 끝점까지 경로 핑
```

경로 핑은 규칙 이동 경로를 확정하지 않는 설명용 시각 표시이며, 필요하면 현재 내비게이션 표면을 따라 투영한다.

## 결과

- 문서 구조가 복잡해져도 왼쪽 탐색으로 빠르게 이동할 수 있다.
- 문서와 실제 월드 정보가 양방향으로 연결된다.
- 핑 종류를 늘리지 않고 위치와 경로 전달만 명확하게 제공한다.
