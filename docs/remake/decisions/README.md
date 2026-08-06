# Architecture Decision Records

- 상태: ACTIVE
- 문서 종류: ADR Index
- 최종 갱신일: 2026-08-06

되돌리기 어렵거나 여러 시스템에 영향을 주는 결정을 시간순 ADR로 기록한다.

## 현재 UI·직접 플레이 권위 결정

### [`ADR-0089 Observer 우선 세션 진입과 전술 콘솔 중심 UI 표면`](ADR-0089-observer-first-session-and-ui-surface-realignment.md)

- 미배정 참가자는 Observer로 진입한다.
- DM의 Character 배정이 Owner·Controller·Player Projection을 함께 전환한다.
- Player Character Actor는 명시적 다른 선택이 없으면 기본 의미 선택이다.
- Objective·Map·Minimap Player UI를 제거한다.
- 하단은 통합 Character Console을 사용한다.
- Context Action Table은 작고 세로 한 열이다.
- 물리 주사위 뒤 상단 투명 Result Notice를 표시한다.
- 공식형 Character Sheet와 VTT 관리형 Character Sheet를 모두 제공한다.
- DM Inspector는 왼쪽, 주요 진행·편집 도구는 상단, Scene Editor Catalog는 하단이다.
- DM Quick Action은 큰 창이 아니라 문맥 Popover다.

ADR-0089는 ADR-0033·0039·0040·0041·0044·0045·0047·0049·0080·0088의 권위·도메인 구조는 유지하면서 충돌하는 화면 배치와 Session Entry 표현을 대체·구체화한다.

### [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)

- 왼쪽 클릭: 선택 또는 가시적인 기본 행동
- 오른쪽 클릭: Capability 기반 Context Action Table
- 마우스 휠 클릭 드래그: Camera Orbit
- Q: 최상위 문맥 하나만 닫기·취소
- ESC: Gameplay 의미 없음
- 비활성 행동: 비활성 색상과 Hover·Focus 불가능 사유

ADR-0089가 Context Action Table의 작은 세로 표현과 Player Actor 기본 의미 선택을 추가한다.

## 기본 규칙

- 파일명: `ADR-XXXX-short-title.md`
- 번호는 전역에서 증가한다.
- 기존 ADR 번호를 재사용하지 않는다.
- 최신 결정이 기존 ADR을 대체하면 `superseded by`·`supersedes` 관계를 기록한다.
- 단순 기능 설명은 `systems/`, 공통 Runtime 계약은 `architecture/`, 화면 계약은 `ui/`에 둔다.
- User Guide와 HTML 예시는 ADR을 새로 만들지 않는다.

## 읽기 순서

```text
CURRENT-WORK-ORDER
→ Quick Flow와 User Guide
→ ADR-0089·ADR-0088
→ 구현 직전 UI·UX 명세
→ 관련 Runtime·Domain 문서
→ Implementation Spec
```

- 현재 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Quick Flow: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- UI·HTML 충돌 감사: [`../audits/ui-html-authority-conflict-and-realignment-audit.md`](../audits/ui-html-authority-conflict-and-realignment-audit.md)
- 구현 직전 UI·UX: [`../ui/shared/implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- Architecture: [`../architecture/README.md`](../architecture/README.md)
- Systems: [`../systems/README.md`](../systems/README.md)
- Implementation Specs: [`../specs/README.md`](../specs/README.md)

## 권위와 수명주기

- 확정 ADR은 관련 Product·Architecture·System·UI보다 높은 결정 근거다.
- 기존 문서와 ADR-0089가 충돌하면 ADR-0089를 따른다.
- 오래된 문서는 삭제하지 않고 충돌 감사와 Git history로 결정 변화를 보존한다.
- 문서 완료를 Runtime PASS로 해석하지 않는다.
