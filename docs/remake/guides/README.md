# Main System Guides

- 상태: COMPLETE
- 문서 종류: Guide Index
- Guide Phase: `COMPLETE`
- 12개 Guide 상태: `CURRENT`
- Guide 완료 감사: [`Main System Guide 일관성과 문서 허브 완료 감사`](../audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
- 최종 연결 감사: [`구현 명세 전 최종 문서 연결 감사`](../audits/pre-implementation-document-linkage-audit.md)

`guides/`는 완료된 권위 문서의 관계, 전체 흐름, 책임 경계와 구현 진입 순서를 설명하는 비권위 길잡이다.

Guide는 새로운 제품 규칙, Architecture 결정, API, Type, Schema, Command와 기본값을 만들지 않는다. Guide와 권위 문서가 충돌하면 권위 문서가 우선한다.

## 현재 작업 기준

- 전체 단계: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- Quick Flow: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- Player·DM User Guide: [`../user-guides/README.md`](../user-guides/README.md)
- 완료된 Guide 작업 순서: [`CURRENT-GUIDE-WORK-ORDER.md`](CURRENT-GUIDE-WORK-ORDER.md)
- Implementation Spec Hub: [`../specs/README.md`](../specs/README.md)
- Implementation Spec Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)

현재 활성 단계는 Implementation Specs다.

## 현재 Guide

1. [`Runtime Foundation과 Authority`](runtime/README.md)
2. [`Session, Networking, Persistence와 Recovery`](session/README.md)
3. [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](scene/README.md)
4. [`Exploration, Selection, Interaction과 Perception`](exploration/README.md)
5. [`Rules, Character Action, Spell, Dice와 Effect`](rules/README.md)
6. [`Combat와 Encounter`](combat/README.md)
7. [`Character, Inventory와 Downtime`](character/README.md)
8. [`UI, Camera와 Presentation`](ui/README.md)
9. [`Journal과 Ping`](journal/README.md)
10. [`Scene Editor와 Authoring`](scene-editor/README.md)
11. [`Diagnostics, Simulation과 Operations`](diagnostics/README.md)
12. [`Extension, Plugin과 Content Pack`](extension/README.md)

모든 Guide 상단에 다음이 확인됐다.

```text
Guide Status: CURRENT
적용 시스템 상태: GUIDE_CURRENT
Completion Audit: 연결됨
```

## 사용자 흐름 대응표

| Quick Flow·사용자 구간 | 상세 User Guide | 기본 Main System Guide | 직접 인접 Guide |
|---|---|---|---|
| 세션 참가·캐릭터 선택·준비 | Player 빠른 시작, DM 세션 준비 | Session | Character, UI |
| 장면 입장·탐험 이동 | Player Exploration, DM Live 진행 | Scene, Exploration | Session, UI |
| 조사·상호작용·비밀 정보 | Player 상호작용, DM Fog·판정 | Exploration | Rules, Journal, UI |
| 행동·주문·주사위 | Player 행동·주문 | Rules | Combat, Character, UI |
| 전투 시작·차례·종료 | Player Encounter, DM Encounter | Combat | Rules, Session, UI |
| Character·Inventory·Downtime | Player Sheet·Inventory, DM 관리 | Character | Rules, Session, UI |
| Journal·Ping·Camera | Player·DM Journal 안내 | Journal, UI | Session, Scene |
| Scene 준비·편집·게시 | DM Scene 관리 | Scene Editor | Scene, Diagnostics, Extension |
| 재접속·복구·Rollback | Player 문제 대응, DM Recovery | Session | Combat, Diagnostics, UI |
| Content Pack·Extension | DM Source Pack 준비 | Extension | Runtime, Rules, Scene Editor |

이 표는 탐색을 위한 Reference다. 실제 구현 계약의 직접 근거는 각 Guide가 연결한 Product·Architecture·System·UI·ADR이다.

## Spec 작성 읽기 순서

```text
CURRENT-WORK-ORDER
→ Quick Flow의 대상 구간
→ 관련 Player·DM Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide의 Authority Documents
→ 기존 관련 Spec
→ Implementation Spec Template
```

예:

```text
첫 Session Join·Movement Slice
→ Quick Flow의 입장·탐험 구간
→ Player·DM Guide
→ Runtime Guide
→ Session Guide
→ Scene·Exploration·UI Guide
→ 직접 Authority Documents
→ 수직 Implementation Spec
```

## Authority 방향

```text
Runtime Principles
→ Product·Architecture
→ System·UI
→ Spec

User Guide
→ 사용자 결과를 설명하는 비권위 Reference

Main System Guide
→ 권위 문서 관계를 설명하는 비권위 Leaf
```

- Guide와 User Guide를 Parent Authority로 기록하지 않는다.
- Spec은 User Guide를 Acceptance Flow로 연결하지만 계약 근거는 직접 권위 문서에서 찾는다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 충돌 Draft를 Authority Documents에서 제외한다.

## 상태와 변경

```text
NOT_READY
READY_TO_WRITE
CURRENT
UPDATE_REQUIRED
```

권위 문서의 의미·관계·흐름이 바뀌면 관련 Guide를 `UPDATE_REQUIRED`로 되돌린다. 링크와 오탈자만 교정하고 의미가 같으면 `CURRENT`를 유지할 수 있다.

새 Guide 또는 갱신 Guide는 [`Main System Guide Template`](../templates/main-system-guide-template.md)을 사용한다.