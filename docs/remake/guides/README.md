# Main System Guides

- 상태: COMPLETE
- 문서 종류: Guide Index
- Guide Phase: `COMPLETE`
- 완료 감사: [`Main System Guide 일관성과 문서 허브 완료 감사`](../audits/main-system-guide-consistency-and-document-hub-completion-audit.md)

`guides/`는 완료된 주요 시스템의 권위 문서 관계, 전체 흐름, 시스템 경계와 읽기 순서를 설명하는 길잡이 문서만 보관한다.

Guide는 새로운 제품 규칙, Architecture 결정, API, 데이터 구조나 구현 정책을 만들지 않는다.

```text
권위 Product·Architecture·System·ADR·Spec
→ 시스템 기획 완료 판정
→ Main System Guide
```

Guide와 권위 문서가 충돌하면 권위 문서가 우선한다.

## 현재 작업 기준

- 전체 단계: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 완료된 Guide 세부 순서: [`CURRENT-GUIDE-WORK-ORDER.md`](CURRENT-GUIDE-WORK-ORDER.md)
- 다음 활성 단계: [`../specs/README.md`](../specs/README.md)

Main System Guide 단계는 완료됐다. 권위 문서 변경으로 Guide 갱신이 필요한 경우에만 관련 Guide를 `UPDATE_REQUIRED`로 다시 연다.

## 현재 Guide

1. [`Runtime Foundation과 Authority`](runtime/README.md)
   - Guide Status: `CURRENT`
   - Source·Build·State·Policy·Command·RuleExecution·Transaction·Event·Projection·Recovery의 공통 권위 흐름
2. [`Session, Networking, Persistence와 Recovery`](session/README.md)
   - Guide Status: `CURRENT`
   - Campaign Membership·Owner·Controller·Role, Lobby·Join·Reconnect, Network Sync·Snapshot·Rollback
3. [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](scene/README.md)
   - Guide Status: `CURRENT`
   - Scene Source·Compiled Build·Runtime Object·Streaming·Spatial Query·Path·Movement
4. [`Exploration, Selection, Interaction과 Perception`](exploration/README.md)
   - Guide Status: `CURRENT`
   - 실시간 이동·Input Context·Selection·Interaction·Visibility·Detection·Encounter 전환
5. [`Rules, Character Action, Spell, Dice와 Effect`](rules/README.md)
   - Guide Status: `CURRENT`
   - Frozen Policy·Capability·Action·Spell·RuleExecution·Roll·PendingEffect·EffectInstance
6. [`Combat와 Encounter`](combat/README.md)
   - Guide Status: `CURRENT`
   - Encounter·Initiative·Timeline·Turn·Reaction·Damage·Death·Time·Rollback
7. [`Character, Inventory와 Downtime`](character/README.md)
   - Guide Status: `CURRENT`
   - Character Source·Build·State, ItemInstance·Equipment·World Presence와 장기 활동
8. [`UI, Camera와 Presentation`](ui/README.md)
   - Guide Status: `CURRENT`
   - Projection Replica·ViewModel·Semantic Input·CameraRequest·Presentation Recipe·Fallback
9. [`Journal과 Ping`](journal/README.md)
   - Guide Status: `CURRENT`
   - Document·Section Identity·Permission·Search·World Anchor와 비권위 위치·경로 Ping
10. [`Scene Editor와 Authoring`](scene-editor/README.md)
    - Guide Status: `CURRENT`
    - Scene Source·Tool Module·Candidate Build·Test Play·Publish·Quick Edit·Live Patch
11. [`Diagnostics, Simulation과 Operations`](diagnostics/README.md)
    - Guide Status: `CURRENT`
    - Trace·Decision·Budget·Incident·Support와 Production-parity Scenario·Recovery 검증
12. [`Extension, Plugin과 Content Pack`](extension/README.md)
    - Guide Status: `CURRENT`
    - Content Pack·Trusted Module·Campaign Authored Data와 Registry·Version·Migration 경계

## 정식 읽기 순서

전체 구조를 처음 파악할 때는 위 1번부터 12번까지 읽는다.

실제 작업에서는 모든 Guide를 매번 읽지 않고 다음 순서를 사용한다.

```text
Runtime Foundation Guide
+ 현재 작업의 Main System Guide
+ 직접 인접한 Guide
+ Guide가 연결한 Authority Documents
→ 해당 Implementation Spec
```

예:

```text
Scene Tool 작업
→ Runtime Guide
→ Scene Editor Guide
→ Scene Guide
→ Tool Module·Scene Compiler Authority
→ Scene Editor Spec
```

```text
Spell 실행 작업
→ Runtime Guide
→ Rules Guide
→ Combat 또는 Character Guide
→ Spell·RuleExecution·Effect Authority
→ Rules Spec
```

## Guide 상태

```text
NOT_READY
→ 권위 기획이 미완성

READY_TO_WRITE
→ 작성 조건을 통과했지만 Guide가 없음

CURRENT
→ 최신 권위 문서 관계와 일치

UPDATE_REQUIRED
→ 권위 문서 변경으로 재검토 필요
```

현재 12개 Guide는 모두 `CURRENT`다.

## Authority Tree

Guide는 Authority Tree의 Parent가 될 수 없다.

```text
Runtime Principles
→ Architecture
→ System·UI
→ Spec

Guide
→ 위 문서들을 설명하는 비권위 Leaf
```

Guide 링크는 탐색 편의를 위한 Reference다. Product·Architecture·System·Spec이 Guide를 규칙 근거로 사용하지 않는다.

## 작성·갱신 조건

새 Guide 또는 `UPDATE_REQUIRED` Guide는 [`../templates/main-system-guide-template.md`](../templates/main-system-guide-template.md)를 사용한다.

필수 조건:

1. 시스템 범위와 사용자 결과가 확정됨
2. 핵심 Architecture와 System·UI가 준비됨
3. 필요한 ADR이 확정됨
4. 중대한 `BLOCKED` 항목이 없음
5. Parent·Children·References가 정리됨
6. 구현 명세 관계 또는 작성 순서를 설명할 수 있음
7. 최신 Completion Audit이 작성 가능성을 승인함

Guide에서 새로운 Type, Schema, Command, 실패 정책과 임의 기본값을 만들지 않는다. 새 결정이 필요하면 권위 문서를 먼저 수정한다.

## 문서 수명주기

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 Authority Documents와 추천 읽기 순서에서 제외한다.

권위 문서가 변경되면 영향받는 Guide를 검사한다.

```text
의미·관계·흐름 변경
→ UPDATE_REQUIRED

오탈자·링크만 교정
→ 의미가 같으면 CURRENT 유지 가능
```

## 완료 판정

[`Main System Guide 일관성과 문서 허브 완료 감사`](../audits/main-system-guide-consistency-and-document-hub-completion-audit.md)는 다음을 확인했다.

- 계획된 Guide 12개 존재
- 모든 Guide가 `CURRENT`와 `GUIDE_CURRENT`
- 표준 13개 절과 완료 체크리스트 충족
- Parent·Children·References 구분
- 권위 중복과 새 Core Engine 공백 없음
- 폐기 문서 제외와 문서 Hub 정리
- Implementation Specs 단계 시작 가능

다음 활성 작업은 Implementation Specs다.
