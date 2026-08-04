# Main System Guides

- 상태: COMPLETE
- 문서 종류: Guide Index
- Guide Phase: `COMPLETE`
- 완료 감사: [`Main System Guide 일관성과 문서 허브 완료 감사`](../audits/main-system-guide-consistency-and-document-hub-completion-audit.md)

`guides/`는 완료된 권위 문서의 관계, 전체 흐름, 책임 경계와 구현 진입 순서를 설명하는 비권위 길잡이다.

Guide는 새로운 제품 규칙, Architecture 결정, API, Type, Schema, Command와 기본값을 만들지 않는다. Guide와 권위 문서가 충돌하면 권위 문서가 우선한다.

## 현재 작업 기준

- 전체 단계: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 한눈에 보는 세션 흐름: [`../user-guides/QUICK-FLOW.md`](../user-guides/QUICK-FLOW.md)
- Player·DM User Guide: [`../user-guides/README.md`](../user-guides/README.md)
- 완료된 Guide 세부 순서: [`CURRENT-GUIDE-WORK-ORDER.md`](CURRENT-GUIDE-WORK-ORDER.md)
- Implementation Spec Hub: [`../specs/README.md`](../specs/README.md)
- Implementation Spec Template: [`../templates/implementation-spec-template.md`](../templates/implementation-spec-template.md)

현재 활성 작업은 구현 명세 전 최종 문서 연결 감사다. 감사 완료 후 Implementation Specs 단계로 복귀한다.

## 현재 Guide

1. [`Runtime Foundation과 Authority`](runtime/README.md)
   - Source·Build·State·Policy·Command·RuleExecution·Transaction·Event·Projection·Recovery
2. [`Session, Networking, Persistence와 Recovery`](session/README.md)
   - Membership·Owner·Controller·Role, Lobby·Join·Reconnect, Network Sync·Snapshot·Rollback
3. [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](scene/README.md)
   - Scene Source·Compiled Build·Runtime Object·Streaming·Spatial Query·Path·Movement
4. [`Exploration, Selection, Interaction과 Perception`](exploration/README.md)
   - 실시간 이동·Input Context·Selection·Interaction·Visibility·Encounter 전환
5. [`Rules, Character Action, Spell, Dice와 Effect`](rules/README.md)
   - Frozen Policy·Capability·Action·Spell·RuleExecution·Roll·PendingEffect·EffectInstance
6. [`Combat와 Encounter`](combat/README.md)
   - Encounter·Initiative·Timeline·Turn·Reaction·Damage·Death·Time·Rollback
7. [`Character, Inventory와 Downtime`](character/README.md)
   - Character Source·Build·State, ItemInstance·Equipment·World Presence와 장기 활동
8. [`UI, Camera와 Presentation`](ui/README.md)
   - Projection Replica·ViewModel·Semantic Input·CameraRequest·Presentation·Fallback
9. [`Journal과 Ping`](journal/README.md)
   - Document·Section Identity·Permission·Search·World Anchor와 Ping
10. [`Scene Editor와 Authoring`](scene-editor/README.md)
    - Scene Source·Tool Module·Candidate Build·Test Play·Publish·Quick Edit·Live Patch
11. [`Diagnostics, Simulation과 Operations`](diagnostics/README.md)
    - Trace·Decision·Budget·Incident·Support와 Production-parity Scenario·Recovery 검증
12. [`Extension, Plugin과 Content Pack`](extension/README.md)
    - Content Pack·Trusted Module·Campaign Data와 Registry·Version·Migration

현재 12개 Guide는 모두 `CURRENT`와 `GUIDE_CURRENT`다.

## 사용자 흐름 대응표

| Quick Flow·사용자 구간 | 상세 User Guide | 기본 Main System Guide | 직접 인접 Guide |
|---|---|---|---|
| 세션 참가·캐릭터 선택·준비 | Player Guide 빠른 시작, DM Guide 세션 준비 | Session Guide | Character, UI |
| 장면 입장·탐험 이동 | Player Guide Exploration, DM Guide Live 진행 | Scene Guide, Exploration Guide | Session, UI |
| 조사·상호작용·비밀 정보 | Player Guide 상호작용, DM Guide Fog·판정 | Exploration Guide | Rules, Journal, UI |
| 행동·주문·주사위 | Player Guide 행동·주문 | Rules Guide | Combat, Character, UI |
| 전투 시작·차례·종료 | Player Guide Encounter, DM Guide Encounter | Combat Guide | Rules, Session, UI |
| Character·Inventory·Downtime | Player Guide Sheet·Inventory, DM Guide 관리 | Character Guide | Rules, Session, UI |
| Journal·Ping·카메라 | Player·DM Journal 안내 | Journal Guide, UI Guide | Session, Scene |
| Scene 준비·편집·게시 | DM Guide Scene 관리 | Scene Editor Guide | Scene, Diagnostics, Extension |
| 재접속·복구·Rollback | Player Guide 문제 대응, DM Guide Recovery | Session Guide | Combat, Diagnostics, UI |
| Plugin·Content Pack 확장 | DM Guide Source Pack 준비 | Extension Guide | Runtime, Rules, Scene Editor |

이 표는 탐색을 위한 연결이다. 구현 계약의 직접 근거는 각 Guide의 Authority Documents에 연결된 Product·Architecture·System·UI·ADR이다.

## 정식 읽기 순서

전체 구조를 처음 파악할 때는 1번부터 12번까지 읽는다.

실제 작업에서는 다음 최소 경로를 사용한다.

```text
CURRENT-WORK-ORDER
→ Quick Flow의 대상 구간
→ 관련 Player·DM Guide
→ Runtime Foundation Guide
→ 현재 Domain Main System Guide
→ 직접 인접 Guide
→ Guide의 Authority Documents
→ 기존 Spec
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
→ 새 Spec
```

## Authority Tree

Guide는 Authority Tree의 Parent가 될 수 없다.

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

- Product·Architecture·System·UI·Spec이 Guide를 규칙 근거로 사용하지 않는다.
- Spec은 User Guide를 Acceptance Flow로 연결하지만 계약 근거는 직접 권위 문서에서 찾는다.
- `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 Authority Documents와 추천 읽기 순서에서 제외한다.

## Guide 상태와 갱신

```text
NOT_READY
READY_TO_WRITE
CURRENT
UPDATE_REQUIRED
```

권위 문서의 의미·관계·흐름이 바뀌면 `UPDATE_REQUIRED`로 되돌린다. 오탈자와 링크만 교정하고 의미가 같으면 `CURRENT`를 유지할 수 있다.

새 Guide 또는 갱신 Guide는 [`Main System Guide Template`](../templates/main-system-guide-template.md)을 사용한다.

## 완료 판정

완료 감사는 다음을 확인했다.

- 계획된 Guide 12개 존재
- 모든 Guide가 `CURRENT`와 `GUIDE_CURRENT`
- 표준 절과 완료 체크리스트 충족
- Parent·Children·References 구분
- 권위 중복과 새 Core Engine 공백 없음
- 폐기 문서 제외

최종 문서 연결 감사는 여기에 Quick Flow·User Guide·Spec Template·Lifecycle의 양방향 탐색을 추가로 확인한다.