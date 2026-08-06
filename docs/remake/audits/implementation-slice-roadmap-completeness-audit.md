# Implementation Slice Roadmap 완전성 감사

- 상태: COMPLETE
- 문서 종류: Roadmap Completeness Audit
- 감사일: 2026-08-05
- 대상 Roadmap: [`Implementation Slice Roadmap`](../specs/SLICE-ROADMAP.md)
- Spec 작업 순서: [`CURRENT-SPEC-WORK-ORDER`](../specs/CURRENT-SPEC-WORK-ORDER.md)
- 상위 작업 순서: [`CURRENT-WORK-ORDER`](../CURRENT-WORK-ORDER.md)

## 1. 목적

Implementation Specs와 Production Implementation을 시작하기 전에 전체 제품 범위가 수직 Slice로 배정됐는지 확인한다.

검사 대상:

- Quick Flow와 Player·DM User Guide의 주요 사용자 흐름
- 12개 Main System Guide
- 공식 `dnd5e-2024` Player Content 최종 범위
- Scene Authoring·DM Workspace·Journal·Extension·Operations
- Persistence·Reconnect·Rollback·Diagnostics·Security·Accessibility

이 Audit은 새 제품 동작이나 Architecture 결정을 만들지 않는다. 이미 확정된 사용자 결과와 권위 문서를 구현 순서에 배치한다.

## 2. 판정 기준

Roadmap은 다음을 만족해야 한다.

- 각 Slice가 독립적으로 검증 가능한 Player·DM 결과를 가진다.
- 선행 Runtime 없이 Domain 기능을 먼저 배치하지 않는다.
- Core Rules가 Interaction·Encounter·Content보다 먼저 배치된다.
- 모든 Main Guide가 하나 이상의 주 Slice에 배정된다.
- UI·Persistence·Diagnostics·Security가 마지막에만 몰리지 않는다.
- 공식 콘텐츠 작성과 Content Platform 구현을 분리한다.
- Scene Authoring과 Live Session DM Operation을 분리한다.
- 전체 통합·성능·마이그레이션·릴리스 검증을 별도 마지막 Slice로 둔다.

## 3. 사용자 흐름 범위 검사

| 사용자 흐름 | 담당 Slice | 판정 |
|---|---:|---|
| 세션 참가·Character 선택·Ready | 01 | 충족 |
| Scene 입장·Token 이동·재접속 | 01 | 충족 |
| 능력 판정·굴림·피해·회복 | 02 | 충족 |
| 조사·상호작용·Fog·비밀 정보 | 03 | 충족 |
| Encounter 시작·Turn·Reaction·종료 | 04 | 충족 |
| Character 생성과 Sheet | 05 | 충족 |
| Inventory·Equipment·Loot | 06 | 충족 |
| Rest·Level Up·Downtime·Travel | 07 | 충족 |
| HUD·Camera·Presentation·Accessibility | 08 | 충족 |
| Journal·Search·World Link·Ping | 09 | 충족 |
| Scene 제작·Compile·Test Play·Publish | 10 | 충족 |
| DM Live Tool·Quick Edit·Recovery | 11 | 충족 |
| Source Pack·Localization·Extension | 12 | 충족 |
| 공식 Character Option 콘텐츠 | 13 | 충족 |
| 공식 Spell·Equipment·Rules 콘텐츠 | 14 | 충족 |
| NPC·Monster·Campaign Authored Content | 15 | 충족 |
| 장시간 전체 Session·Release | 16 | 충족 |

Quick Flow의 정상 흐름과 재접속·Rollback 예외 흐름이 모두 배정됐다.

## 4. Main System Guide 범위 검사

| Main System Guide | 주 Slice | 결과 |
|---|---|---|
| Runtime Foundation과 Authority | 01, 02, 16 | 충족 |
| Session, Networking, Persistence와 Recovery | 01, 11, 16 | 충족 |
| Scene, Streaming, Runtime Object, Spatial Query와 Navigation | 01, 03, 10 | 충족 |
| Exploration, Selection, Interaction과 Perception | 03 | 충족 |
| Rules, Character Action, Spell, Dice와 Effect | 02, 14 | 충족 |
| Combat와 Encounter | 04 | 충족 |
| Character, Inventory와 Downtime | 05, 06, 07 | 충족 |
| UI, Camera와 Presentation | 08 | 충족 |
| Journal과 Ping | 09 | 충족 |
| Scene Editor와 Authoring | 10, 11 | 충족 |
| Diagnostics, Simulation과 Operations | 16 및 모든 Slice 공통 레일 | 충족 |
| Extension, Plugin과 Content Pack | 12 | 충족 |

배정되지 않은 Main Guide가 없다.

## 5. 의존 순서 검사

### Core Runtime

```text
Session·Protocol·Scene·Movement
→ Core Rules
→ Interaction
→ Encounter
```

첫 Slice는 Rules 없이 이동 가능한 최소 Session Skeleton만 만든다. Slice 02에서 Core Rules Kernel을 완성한 뒤 Interaction과 Encounter가 이를 재사용하므로 임시 Domain별 굴림 엔진이 생기지 않는다.

### Character와 Content

```text
Character Foundation
→ Inventory
→ Progression·Downtime
→ Content Platform
→ 공식 Character Content
→ 공식 Spell·Item Content
→ NPC·Campaign Content
```

Runtime·Compiler·Migration 기반과 실제 대량 Content 작성이 분리됐다. Content가 Runtime 계약을 예외로 우회하지 않는다.

### Scene와 DM Operation

```text
Runtime Scene 사용
→ Scene Source Authoring·Compile·Publish
→ Live DM Quick Edit·Patch·Recovery
```

Offline/Candidate Authoring과 활성 Session Mutation을 같은 Slice로 합치지 않았다.

### Client Surface

UI·Camera·Presentation의 최소 기능은 Slice 01부터 각 Slice에 포함한다. Slice 08은 앞선 기능 전체를 공통 Client Runtime과 접근성·Presentation으로 통합하는 단계이며, 그 전까지 UI를 전혀 미루는 단계가 아니다.

## 6. 공통 품질 레일 검사

다음 항목이 Roadmap의 모든 Slice 공통 레일에 포함됐다.

- Stable ID·Version·Epoch·Revision
- Source·Build·State·Projection·Presentation 분리
- Transaction·Outbox·Projection Barrier
- Migration·Last Known Good·Rollback
- Loading·Denied·Retrying·Resync 사용자 상태
- Snapshot·Journal·Reconnect·Restart
- Trace·Stable Error·Health·Support Reference
- Negative Disclosure·역할별 Projection
- Deterministic·Fault·Roblox Integration Test
- Performance·Memory·Network 측정

따라서 Diagnostics·Security·Persistence·Accessibility를 마지막 Slice까지 미루지 않는다.

## 7. 누락·과대 Slice 검사

### 분리해서 유지한 영역

- Character Foundation과 대량 공식 Character Content
- Inventory Runtime과 공식 Equipment Content
- Scene Authoring과 Live DM Operation
- Content Platform과 실제 Content 작성
- 각 Slice 품질 검증과 최종 Release Hardening

### Slice 내부에서 세부 Work Order가 필요한 영역

다음 Slice는 범위가 크므로 시작 전에 별도 Slice Work Order를 작성한다.

- 04 Encounter Core Loop
- 07 Rest·Time·Downtime·Progression
- 08 Player UI·Camera·Presentation
- 10 Scene Authoring·Compile·Publish
- 12 Content Pack·Localization·Trusted Extension Platform
- 13–15 Content Coverage Slice
- 16 Full-session Integration·Release Hardening

이는 Roadmap 누락이 아니라 Slice 내부 Spec 순서를 별도로 관리해야 한다는 뜻이다.

## 8. 최종 판정

```text
Implementation Slice Roadmap
→ COMPLETE

전체 제품 범위 배정
→ COMPLETE

현재 실행 대상
→ Slice 01 First Session Walking Skeleton

다음 Slice
→ Slice 02 Core Rules Kernel
```

16개 Slice는 현재 확정된 제품과 Architecture 범위를 모두 배정한다. 앞으로 새 범위가 추가되거나 기존 권위 문서가 변경되면 새 Slice를 즉시 뒤에 붙이지 않고, 기존 Slice 책임과 의존 관계를 먼저 재검토한다.

## 9. 후속 조치

- `CURRENT-SPEC-WORK-ORDER.md`는 현재 Slice 01의 세부 순서만 소유한다.
- 전체 Slice 순서는 `SLICE-ROADMAP.md`를 단일 기준으로 사용한다.
- 각 Slice 시작 시 전용 Work Order와 Spec Completion Audit을 만든다.
- Slice 01 명세 작업을 `runtime/001`부터 재개한다.
