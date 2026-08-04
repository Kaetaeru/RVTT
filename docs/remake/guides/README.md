# Main System Guides

- 상태: 활성 문서 허브
- 문서 종류: Guide Index
- 즉시 구현 명세 가능성: 해당 없음

`guides/`는 완료된 주요 시스템의 권위 문서 관계, 전체 흐름과 읽기 순서를 설명하는 길잡이 문서만 보관한다.

Guide는 새로운 제품 규칙, Architecture 결정, API, 데이터 구조나 구현 정책을 만들지 않는다.

```text
권위 Product·Architecture·System·ADR·Spec
→ 시스템 기획 완료 판정
→ Main System Guide 작성
```

## 현재 작업 기준

- [`CURRENT-GUIDE-WORK-ORDER.md`](CURRENT-GUIDE-WORK-ORDER.md)
  - Main System Guide 단계에서 둘 이상의 Guide 순서를 정하거나 변경할 때 먼저 갱신한다.
  - 가장 위의 `IN_PROGRESS` Guide를 현재 작업으로 사용한다.
- 상위 단계는 [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)를 따른다.

## 현재 Guide

- [`Runtime Foundation과 Authority`](runtime/README.md)
  - Guide Status: `CURRENT`
  - Source·Build·State·Policy·Command·RuleExecution·Transaction·Event·Projection·Recovery의 공통 권위 흐름
  - 모든 후속 Main System Guide가 공유하는 용어와 추천 읽기 순서
- [`Session, Networking, Persistence와 Recovery`](session/README.md)
  - Guide Status: `CURRENT`
  - Campaign Membership·Owner·Controller·Role, Lobby·Join·Reconnect와 Session Mode·Transition
  - Versioned Command·Projection Sync·Scene Ready·Snapshot·Journal·Restart·Rollback 흐름
- [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](scene/README.md)
  - Guide Status: `CURRENT`
  - Scene Source·Compiled Build·Runtime Object Presence·Runtime Scene Snapshot의 권위 계층
  - Client-safe Streaming·Ready Activation·Spatial Query·Path Planning·Checkpoint Movement의 월드 Runtime 흐름
- [`Exploration, Selection, Interaction과 Perception`](exploration/README.md)
  - Guide Status: `CURRENT`
  - 실시간 Exploration 실행, Input Context, Candidate·Selection·Frozen Binding과 Capability 기반 Interaction
  - Observer별 Visibility·Detection·Knowledge·Disclosure, Fog와 Hover Projection, Hazard·Encounter 전환 흐름
- [`Rules, Character Action, Spell, Dice와 Effect`](rules/README.md)
  - Guide Status: `CURRENT`
  - Frozen Policy·Capability·ActionOpportunity·RuleExecution·Recipe·TimingWindow의 규칙 실행 수명주기
  - Spell Route·Payment·Component·Targeting, 서버 Roll·Reveal·Outcome, PendingEffect·EffectInstance·Duration 흐름
- [`Combat와 Encounter`](combat/README.md)
  - Guide Status: `CURRENT`
  - Encounter Proposal·Initiative Reveal·Timeline·Turn·Opportunity·Reaction과 Objective 진행
  - Damage·HP 0·Death 통합, Round·Campaign Time Boundary, Encounter End와 Branch Rollback 흐름
- [`Character, Inventory와 Downtime`](character/README.md)
  - Guide Status: `CURRENT`
  - Character Progression Source·Compiled Build·Persistent State와 Scene Actor·Encounter State 경계
  - ItemInstance·Equipment·World Presence, Rest·Level Up·Spellbook·Crafting·Training·Travel과 Atomic Completion 흐름
- [`UI, Camera와 Presentation`](ui/README.md)
  - Guide Status: `CURRENT`
  - Permission-aware Projection Replica·ViewModel·Panel·Semantic Input·UI Intent와 Epoch-safe Recovery
  - CameraRequest·Focus·Follow·Bookmark, Presentation Recipe·Queue·Marker·Audience·Fallback 흐름
- [`Journal과 Ping`](journal/README.md)
  - Guide Status: `CURRENT`
  - 안정적 Document·Section Identity, Markdown Compile, Permission-aware Search·Backlink와 World Anchor Lifecycle
  - Safe Navigation Capability와 위치·경로 Ping의 비권위 Audience·Presentation·Lifetime 흐름
- [`Scene Editor와 Authoring`](scene-editor/README.md)
  - Guide Status: `CURRENT`
  - DM Authoring Overlay, Scene Source·Stable Object·Tool Module·Authoring Command와 Edit History
  - Candidate Build·Diagnostic·Test Play·Atomic Publish, Runtime Quick Edit·Source Promotion과 안전한 Live Patch 흐름

## 1. Guide의 역할

Guide는 다음 질문에 빠르게 답한다.

- 이 시스템은 어떤 문제를 해결하는가?
- 어떤 권위 문서들이 이 시스템을 구성하는가?
- 문서 사이의 상하 관계와 실행 흐름은 무엇인가?
- 다른 시스템과 어디에서 연결되는가?
- 처음 읽는 사람은 어떤 순서로 문서를 읽어야 하는가?
- 구현·변경 시 어느 문서까지 함께 확인해야 하는가?

Guide는 권위 문서의 요약·관계도·탐색 경로다. Guide의 문장과 권위 문서가 충돌하면 권위 문서가 우선한다.

## 2. 작성 조건

Main System Guide는 관련 시스템의 기획이 완료된 뒤에만 작성한다.

필수 조건:

1. 시스템 범위와 사용자 결과가 확정됨
2. 핵심 Architecture 계약이 `READY`임
3. 관련 System·UI 기획이 `READY`임
4. 되돌리기 어려운 결정이 ADR로 기록됨
5. 주요 미결정이 구현자 판단으로 남아 있지 않음
6. Parent·Children·Reference 문서 관계가 정리됨
7. 구현 명세 작성 순서 또는 완료된 Spec 관계를 설명할 수 있음
8. 최신 Audit에서 중대한 `BLOCKED` 항목이 없음

`READY_WITH_DEFAULTS` 문서가 남아 있어도 Guide의 의미를 바꾸지 않는 측정형 기본값뿐이고, 시스템 완료 Audit가 작성 가능하다고 판정한 경우에만 예외적으로 Guide를 작성할 수 있다.

Guide가 필요하다는 이유로 미완성 기획을 완료된 것처럼 표시하지 않는다.

## 3. Guide 상태

각 주요 시스템은 Completion Audit 또는 해당 영역 README에 다음 상태를 기록한다.

```text
Guide Status
├─ NOT_READY
├─ READY_TO_WRITE
├─ CURRENT
└─ UPDATE_REQUIRED
```

- `NOT_READY`: 기획 또는 권위 계약이 미완성
- `READY_TO_WRITE`: 작성 조건을 통과했지만 Guide가 아직 없음
- `CURRENT`: 현재 권위 문서 관계와 일치하는 Guide가 있음
- `UPDATE_REQUIRED`: 권위 문서가 변경되어 Guide 갱신 필요

Guide 상태는 Architecture와 System 문서의 권위·준비도를 대체하지 않는다.

## 4. Guide 작성 금지 사항

Guide에서 다음을 확정하지 않는다.

- 새로운 제품 동작
- 새로운 Architecture 원칙
- 새로운 ADR 결정
- 새로운 Type, Schema, Command와 API
- 새로운 구현 순서의 강제 조건
- 권위 문서에 없는 예외 처리
- 미정 사항에 대한 임의 기본값

새 결정이 필요하면 먼저 해당 Product·Architecture·System·ADR·Spec을 수정한다. 그 뒤 Guide를 갱신한다.

## 5. 표준 구성

모든 Main System Guide는 [`../templates/main-system-guide-template.md`](../templates/main-system-guide-template.md)를 사용한다.

필수 절:

1. Guide 상태와 적용 범위
2. 시스템 목적과 사용자 결과
3. 전체 구조
4. 주요 데이터 흐름
5. 주요 실행 흐름
6. 문서 관계도
7. 다른 시스템과의 경계
8. 추천 읽기 순서
9. 구현·검증 순서
10. 변경 영향 지도
11. Authority Documents
12. ADR References
13. 알려진 비목표와 측정형 기본값

## 6. Authority Tree

Guide가 권위 문서의 Parent가 될 수 없다.

```text
Runtime Principles
→ Architecture
→ System·UI
→ Spec

Guide
→ 위 문서들을 설명하는 비권위 Leaf
```

권위 문서는 관계를 다음처럼 구분한다.

```text
Parent
→ 직접 상위 권위 문서

Children
→ 이 문서를 구체화하는 하위 권위 문서

References
→ 인접 시스템 또는 보조 근거
```

Guide는 이 관계를 시각적으로 정리하되 새로운 관계를 발명하지 않는다.

## 7. Architecture Freeze와 Guide

Architecture를 기반으로 구현 명세가 시작되면 해당 Architecture의 변경은 영향 분석을 요구한다.

변경 전 확인:

1. 대체 또는 보완 ADR 필요 여부
2. 영향받는 System·UI 문서
3. 영향받는 Specs
4. 영향받는 Main System Guide
5. 기존 구현과 Migration

권위 문서가 변경되면 관련 Guide는 즉시 `UPDATE_REQUIRED`로 표시한다. Guide가 오래되었다는 이유로 권위 문서 변경을 막지는 않는다.

## 8. Guide 영역과 작성 순서

현재 Guide 영역과 작성 순서는 [`CURRENT-GUIDE-WORK-ORDER.md`](CURRENT-GUIDE-WORK-ORDER.md)가 소유한다.

예상 영역:

```text
runtime
session·networking·persistence
scene·streaming·navigation
exploration·selection·interaction·perception
rules·actions·spells·dice·effects
combat·encounter
character·inventory·downtime
ui·camera·presentation
journal·ping
scene-editor·authoring
diagnostics·simulation·operations
extension·plugin·content-pack
```

현재 Guide가 없다는 것은 오류가 아니다. 미완성 시스템 Guide를 미리 작성하는 것이 더 큰 오류다.

## 9. 완료 정의

하나의 주요 시스템은 최소한 다음 단계를 구분한다.

```text
PLANNING
→ ARCHITECTURE_READY
→ SYSTEM_READY
→ SPEC_READY
→ IMPLEMENTATION_READY
→ IMPLEMENTED
→ GUIDE_CURRENT
→ AUDITED
```

Guide는 기획 완료를 만드는 문서가 아니라, 완료된 기획과 구현 관계를 탐색 가능하게 만드는 마지막 정리 문서다.
