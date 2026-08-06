# Architecture Decision Records

- 상태: ACTIVE
- 문서 종류: ADR Index

되돌리기 어렵거나 여러 시스템에 영향을 주는 결정을 시간순 ADR로 기록한다.

## 현재 직접 플레이 권위 결정

- [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)
  - 왼쪽 클릭: 선택 또는 가시적인 기본 행동
  - 오른쪽 클릭: Capability 기반 전체 행동표
  - 마우스 휠 클릭 드래그: Camera Orbit
  - Q: 최상위 문맥 하나만 닫기·취소
  - ESC: Gameplay 의미 없음
  - 비활성 행동: 비활성 색상과 Hover 불가능 사유
  - 이동·대상 Preview, 선택·턴·카메라 연속성과 서버 피드백

ADR-0088은 ADR-0039·0050·0071·0072의 기존 구조 원칙을 유지하면서 실제 PC Pointer Grammar와 Direct Play UX를 구체화한다.

## 기본 규칙

- 파일명: `ADR-XXXX-short-title.md`
- 번호는 전역에서 증가한다.
- 기존 ADR 번호를 재사용하지 않는다.
- 최신 결정이 기존 ADR을 대체하면 양쪽 문서에 `superseded by`·`supersedes` 관계를 명시한다.
- 기존 결정을 유지하면서 세부를 추가하면 양쪽 문서에 보강 관계를 명시한다.
- 단순 기능 설명은 `systems/`, 공통 Runtime 계약은 `architecture/`, 화면 계약은 `ui/`에 둔다.
- User Guide와 Main System Guide에서 새로운 ADR 결정을 만들지 않는다.

## 읽기 순서

```text
CURRENT-WORK-ORDER
→ Quick Flow와 관련 User Guide
→ Runtime·Domain Main System Guide
→ Guide가 연결한 Product·Architecture·System·UI
→ 직접 관련 ADR
→ Implementation Spec
```

- 현재 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Quick Flow: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- Main System Guide: [`../guides/README.md`](../guides/README.md)
- Architecture: [`../architecture/README.md`](../architecture/README.md)
- Systems: [`../systems/README.md`](../systems/README.md)
- UI: [`../ui/README.md`](../ui/README.md)
- Implementation Specs: [`../specs/README.md`](../specs/README.md)

## 권위와 수명주기

- 확정 ADR은 관련 Product·Architecture·System·UI보다 높은 결정 근거다.
- ADR은 오래됐다는 이유만으로 `DISCONTINUED` 처리하지 않는다.
- 결정이 바뀌면 후속 ADR을 만들고 대체 관계를 기록한다.
- `superseded` ADR은 현재 구현 판단의 최종 근거로 단독 사용하지 않는다.
- 관련 Guide와 Spec의 변경 영향 지도를 함께 확인한다.

문서 역할과 우선순위는 [`DOCUMENT-GUIDE.md`](../DOCUMENT-GUIDE.md)를 따른다.
