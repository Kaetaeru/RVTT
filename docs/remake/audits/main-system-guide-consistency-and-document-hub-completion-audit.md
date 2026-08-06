# Main System Guide 일관성과 문서 허브 완료 감사

- 상태: ACTIVE
- 문서 종류: Completion Audit
- 감사일: 2026-08-05
- 감사 대상:
  - `docs/remake/guides/`
  - `docs/remake/README.md`
  - `docs/remake/systems/README.md`
  - `docs/remake/audits/README.md`
  - `docs/remake/specs/README.md`
  - `docs/remake/CURRENT-WORK-ORDER.md`
- 선행 감사: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 세부 작업 순서: [`Main System Guide 현재 작업 순서`](../guides/CURRENT-GUIDE-WORK-ORDER.md)

## 1. 감사 목적

이 감사는 현재 제품 범위의 Main System Guide 작성 단계가 실제로 완료됐는지 확인한다.

검토 질문:

1. 계획된 모든 Guide가 존재하고 `CURRENT` 상태인가.
2. 각 Guide가 표준 Template의 필수 절과 완료 체크리스트를 포함하는가.
3. Guide가 새로운 권위 문서가 아니라 Product·Architecture·System·ADR·Spec을 설명하는 Leaf로 유지되는가.
4. Parent Authority, Child Authority와 References가 구분되는가.
5. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서가 현재 권위 읽기 순서에 포함되지 않는가.
6. 시스템 사이의 중복 권위와 직접 Store 접근을 Guide가 다시 만들지 않는가.
7. 문서 허브가 Guide 중심 탐색과 현재 작업 단계를 정확히 안내하는가.
8. Main System Guide 단계 완료 후 Implementation Specs 단계로 전환할 수 있는가.

이 감사는 제품 동작, Architecture, API, Schema 또는 구현 기본값을 새로 정의하지 않는다.

## 2. 최종 판정

```text
Planned Main System Guides
→ 12 / 12 COMPLETE

Guide Status Consistency
→ PASS

Template and Checklist Consistency
→ PASS

Authority Boundary Consistency
→ PASS

Superseded·Discontinued Exclusion
→ PASS AFTER HUB CLEANUP

Document Hub Consistency
→ PASS AFTER HUB CLEANUP

Main System Guide Phase
→ COMPLETE

Implementation Specs Phase
→ READY TO START

Production Implementation
→ NOT STARTED
```

Main System Guide 단계는 현재 제품 범위에서 완료됐다.

Implementation Specs는 시작할 수 있지만, 이는 Production Implementation이 준비됐다는 의미가 아니다. 실제 구현 전에는 수직 단위별 Module·Type·Command·Network·Persistence·Error·Budget·Test 계약을 작성하고 검증해야 한다.

## 3. Guide 목록과 상태

| 순서 | Guide | 파일 | 상태 | 판정 |
|---:|---|---|---|---|
| 1 | Runtime Foundation과 Authority | [`guides/runtime/README.md`](../guides/runtime/README.md) | `CURRENT` | `PASS` |
| 2 | Session, Networking, Persistence와 Recovery | [`guides/session/README.md`](../guides/session/README.md) | `CURRENT` | `PASS` |
| 3 | Scene, Streaming, Runtime Object, Spatial Query와 Navigation | [`guides/scene/README.md`](../guides/scene/README.md) | `CURRENT` | `PASS` |
| 4 | Exploration, Selection, Interaction과 Perception | [`guides/exploration/README.md`](../guides/exploration/README.md) | `CURRENT` | `PASS` |
| 5 | Rules, Character Action, Spell, Dice와 Effect | [`guides/rules/README.md`](../guides/rules/README.md) | `CURRENT` | `PASS` |
| 6 | Combat와 Encounter | [`guides/combat/README.md`](../guides/combat/README.md) | `CURRENT` | `PASS` |
| 7 | Character, Inventory와 Downtime | [`guides/character/README.md`](../guides/character/README.md) | `CURRENT` | `PASS` |
| 8 | UI, Camera와 Presentation | [`guides/ui/README.md`](../guides/ui/README.md) | `CURRENT` | `PASS` |
| 9 | Journal과 Ping | [`guides/journal/README.md`](../guides/journal/README.md) | `CURRENT` | `PASS` |
| 10 | Scene Editor와 Authoring | [`guides/scene-editor/README.md`](../guides/scene-editor/README.md) | `CURRENT` | `PASS` |
| 11 | Diagnostics, Simulation과 Operations | [`guides/diagnostics/README.md`](../guides/diagnostics/README.md) | `CURRENT` | `PASS` |
| 12 | Extension, Plugin과 Content Pack | [`guides/extension/README.md`](../guides/extension/README.md) | `CURRENT` | `PASS` |

모든 Guide는 다음 Metadata를 가진다.

```text
Guide Status: CURRENT
적용 시스템 상태: GUIDE_CURRENT
작성일
마지막 권위 문서 검토일
Completion Audit
대체하는 Guide
대체된 Guide
```

## 4. Template 일관성

모든 Guide에서 다음 절을 확인했다.

```text
1. 시스템 목적과 사용자 결과
2. 전체 구조
3. 주요 데이터 흐름
4. 주요 실행 흐름
5. 문서 관계도
6. 다른 시스템과의 경계
7. 추천 읽기 순서
8. 구현·검증 순서
9. 변경 영향 지도
10. Authority Documents
11. ADR References
12. 알려진 비목표와 측정형 기본값
13. Guide 검증 체크리스트
```

각 Guide의 체크리스트는 완료 상태이며 최소한 다음을 검증한다.

- 핵심 설명이 Authority Document에 근거함
- 새로운 제품 규칙이나 Architecture 결정을 추가하지 않음
- 현재 저장소 경로의 링크를 사용함
- Parent·Children·References를 구분함
- 최신 ADR과 Completion Audit을 반영함
- 실제 Guide Status와 문서 상태가 일치함

판정: `PASS`

## 5. Authority 계층 감사

전체 Guide가 다음 계층을 유지한다.

```text
Product·Runtime Principles
→ Architecture
→ System·UI
→ Spec

Guide
→ 위 권위 문서의 관계·흐름·읽기 순서를 설명하는 비권위 Leaf
```

확인 결과:

- Guide를 Product·Architecture·System·Spec의 Parent로 기록하지 않았다.
- Guide 문장과 권위 문서가 충돌할 경우 권위 문서가 우선한다는 원칙이 Guide 허브에 명시돼 있다.
- Guide는 새로운 Command, Type, Schema, API, 실패 정책과 수치 기본값을 만들지 않는다.
- Guide 사이의 링크는 탐색 Reference이며 권위 상하 관계가 아니다.
- Implementation Spec은 Guide를 규칙 원본으로 사용하지 않고 Guide가 연결한 Authority Documents를 근거로 작성해야 한다.

판정: `PASS`

## 6. 시스템 경계 일관성

Guide 전체에서 반복되는 공통 경계는 서로 충돌하지 않는다.

### Source, Build와 State

```text
Authoring·Persistent Source
≠ Immutable Compiled Build
≠ Versioned Authoritative State
≠ Permission-aware Projection
≠ Client Presentation
```

### 변경 경로

```text
Intent
→ Command
→ Authorization·Validation
→ RuleExecution 또는 Domain Operation
→ Transaction
→ Domain Event
→ Projection
→ UI·Presentation
```

### 복구

```text
Validated Snapshot·Journal
→ Authority State 복구
→ 새 AuthorityEpoch
→ Derived Data·Projection 재생성
→ Full Resync 또는 검증된 Catch-up
```

### 확장

```text
Trusted Registry·Compiler·Provider
→ Candidate Validation
→ Versioned Build·Snapshot·Recipe
→ Safe Activation
```

확인 결과:

- UI·Presentation·Diagnostics·Simulation은 Gameplay State를 직접 수정하지 않는다.
- Subscriber는 다른 Domain Store를 직접 수정하지 않고 새 Command 또는 RuleExecution을 제출한다.
- Scene Source와 Runtime Quick Edit를 같은 권위 원본으로 취급하지 않는다.
- Character, Actor, Item, Effect, Encounter와 Scene Runtime의 Identity·State 소유권이 분리돼 있다.
- 진행 중 Encounter, Downtime, RuleExecution, Build와 Playback은 시작 당시 Version을 유지한다.
- Rollback은 역연산이 아니라 새 Branch와 AuthorityEpoch 복원이다.
- Player Client에 Raw Authority와 비밀 자료를 전달한 뒤 UI에서만 숨기지 않는다.

판정: `PASS`

## 7. Guide 사이의 책임 분리

| Guide | 주 책임 | 인접 Guide에 위임하는 경계 |
|---|---|---|
| Runtime | 공통 권위·버전·Command·Transaction·Projection | 개별 Domain 규칙과 UX |
| Session | 참가·Role·Control·Ready·Network·Recovery | Scene 내부 구조와 Gameplay 규칙 |
| Scene | Build·Runtime Object·Streaming·Spatial·Navigation | 저작 Tool UX와 행동 적격성 |
| Exploration | 실시간 이동·Selection·Interaction·Perception | 전투 Timeline과 규칙 해결 |
| Rules | Capability·Action·Spell·Roll·Effect 실행 | Character 성장과 Encounter 진행 |
| Combat | Encounter·Timeline·Opportunity·Damage·Death·Time | 개별 Action·Spell 콘텐츠 |
| Character | 성장·ItemInstance·Downtime | RuleExecution과 Scene Runtime |
| UI | Projection Replica·Input·Camera·Presentation | Domain Authority와 Authoring Source |
| Journal | 문서·Permission·Search·Anchor·Ping | Camera·Selection·Scene Transition 실행 |
| Scene Editor | Scene Source·Tool·Compile·Publish·Live Patch | 게시 이후 Scene Runtime 실행 |
| Diagnostics | Trace·Incident·Scenario·Operations | 실제 Recovery와 Gameplay Mutation |
| Extension | Pack·Registry·Trusted Module·Migration | 각 Domain의 기존 권위 Runtime |

중복 Authority 또는 새 Core Engine 공백은 발견되지 않았다.

판정: `PASS`

## 8. 문서 수명주기와 읽기 순서

현재 권위 읽기 순서에서 다음 종류의 문서를 제외한다.

```text
SUPERSEDED
DISCONTINUED
ARCHIVED
```

확인한 대표 사례:

- `systems/journal/linked-journal-and-two-mode-ping-model.md`는 현재 Journal·Ping 권위 읽기 순서에서 제외됨
- `systems/rules/condition-ongoing-effect-duration-and-concentration-model.md`는 현재 Effect Runtime Architecture로 대체됨
- 이전 Planning·Integration Audit은 현재 Completion Audit의 판단 근거로 사용하지 않고 역사 기록으로 보존됨

감사 중 `docs/remake/README.md`의 과거 추천 읽기 순서에 이전 Gap Audit 링크가 남아 있는 것을 발견했다. 문서 허브 갱신에서 해당 링크를 최신 Completion Audit과 이 감사로 교체한다.

판정: `PASS AFTER HUB CLEANUP`

## 9. 문서 허브 감사

### 발견한 문제

1. `docs/remake/README.md`의 문서 구조 표에 `guides/`가 없었다.
2. 같은 문서의 추천 읽기 순서가 Guide 작성 전의 직접 Architecture 목록을 기본 진입점으로 유지했다.
3. 추천 읽기 순서에 현재 판단에서 제외된 과거 Gap Audit가 남아 있었다.
4. 저장소 루트 `README.md`가 이동 전 경로인 `docs/remake/02-core-session-loop.md`를 참조했다.
5. `specs/README.md`가 Main System Guide 완료와 현재 Implementation Specs 단계 전환을 설명하지 않았다.

### 적용하는 정리

- 저장소 루트에서 현재 Work Order, Remake Hub와 Main System Guide Hub로 직접 이동 가능하게 한다.
- `docs/remake/README.md`의 기본 탐색 순서를 `작업 규약 → Work Order → 관련 Main System Guide → Authority Documents → Spec`으로 변경한다.
- 문서 구조에 `guides/`를 추가한다.
- Guide Hub에 12개 Guide의 정식 권장 읽기 순서와 Phase Completion 상태를 표시한다.
- Audit Hub에 이 완료 감사를 추가한다.
- Systems Hub에 Main System Guide Hub와 Extension 영역을 연결한다.
- Specs Hub에 현재 단계와 Guide·Authority 선행 읽기 규칙을 표시한다.
- 이동 전 Core Session Loop 링크를 현재 `product/core-session-loop.md`로 교정한다.

판정: `PASS AFTER HUB CLEANUP`

## 10. 정식 Guide 읽기 순서

전체 구현자가 처음 읽는 기본 순서는 다음과 같다.

```text
Runtime Foundation
→ Session Reliability
→ Scene Runtime
→ Exploration
→ Rules Execution
→ Combat
→ Character·Inventory·Downtime
→ UI·Camera·Presentation
→ Journal·Ping
→ Scene Editor·Authoring
→ Diagnostics·Simulation·Operations
→ Extension·Content Pack
```

모든 작업에서 12개 Guide 전체를 처음부터 끝까지 읽을 필요는 없다.

```text
Runtime Guide
+ 현재 작업의 Main System Guide
+ 직접 인접 Guide
+ Guide가 연결한 Authority Documents
→ 해당 Implementation Spec
```

을 기본으로 사용한다.

## 11. Implementation Specs 진입 판정

Main System Guide 단계 완료 후 다음 작업은 Implementation Specs다.

Spec이 정의해야 하는 항목:

- Package·Module·Service 경계
- Luau Type와 Versioned Schema
- Registry Definition과 Compiler Interface
- Command·Result·Error Code
- Network Envelope와 Projection Segment
- Persistence Chunk·Journal·Migration
- Ordering Key·Reservation·Transaction Node
- Trace Span·Budget·Health Probe
- Deterministic Scenario Fixture와 Acceptance Test
- Roblox Integration Boundary

기존 `specs/shared/001`, `002`는 현재 Architecture·Guide와 다시 대조한 뒤 후속 Spec 작업 순서에 포함해야 한다.

세부 Spec 작성 순서는 별도 작업에서 확정한다. 이 감사는 새로운 Spec 우선순위를 결정하지 않는다.

판정:

```text
Implementation Specs
→ READY TO START
```

## 12. 남은 비차단 항목

다음은 Guide 단계의 Blocker가 아니다.

- Runtime별 수치 Budget·Timeout·Batch·Cache 기본값
- 실제 Roblox Module과 Package 경로
- UI Pixel Layout과 Animation Curve
- Content Pack 실제 규칙 수치·Locale·Asset
- Scenario 반복 수와 Benchmark 환경
- DataStore Chunk 목표 크기와 Retention 기간
- 구현 순서와 수직 Slice 분할

이 항목은 Implementation Specs, UI Design, Content Production과 플레이테스트에서 확정한다.

## 13. 완료 조건 검증

- [x] 계획된 12개 Main System Guide가 존재한다.
- [x] 모든 Guide가 `CURRENT`와 `GUIDE_CURRENT` 상태다.
- [x] 모든 Guide가 표준 13개 절과 완료 체크리스트를 가진다.
- [x] Parent Authority, Child Authority와 References를 구분한다.
- [x] Guide가 Authority Tree의 Leaf로 유지된다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 현재 읽기 순서에서 제외한다.
- [x] Cross-System Authority 중복과 새 Core Engine 공백이 없다.
- [x] Root·Remake·Guide·System·Audit·Spec Hub 갱신 범위를 확정했다.
- [x] Main System Guide 단계를 완료로 판정했다.
- [x] Implementation Specs 단계를 시작 가능으로 판정했다.

## 14. 결론

RVTT 리메이크의 현재 제품 범위는 Architecture Completion 이후 필요한 12개 Main System Guide 통합을 완료했다.

```text
Architecture·Integration
→ COMPLETE FOR CURRENT PRODUCT SCOPE

Main System Guides
→ COMPLETE

Implementation Specs
→ NEXT ACTIVE PHASE

Production Implementation
→ QUEUED
```

이후 권위 Product·Architecture·System·ADR·Spec이 변경되면 영향받는 Guide를 `UPDATE_REQUIRED`로 전환하고 이 감사의 관련 판정을 다시 검토한다.
