# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning Work Order
- 최종 갱신일: 2026-08-05
- Architecture 완료 근거: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- Guide 완료 근거: [`Main System Guide 일관성과 문서 허브 완료 감사`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)
- User Guide 최초 완료 근거: [`Player·DM User Guide 완료 감사`](audits/player-and-dm-user-guide-completion-audit.md)

이 문서는 RVTT 리메이크 기획·사용자 가이드·명세·구현의 **단일 작업 순서 기준**이다.

## 운영 규칙

1. 둘 이상의 다음 작업 순서를 제안하거나 변경할 때는 작업을 시작하기 전에 이 문서를 먼저 갱신한다.
2. 별도 대화·메모·체크리스트가 이 문서와 충돌하면 이 문서의 순서를 따른다.
3. 가장 위의 `IN_PROGRESS` 항목을 먼저 끝내고, 완료 후 `DONE`으로 변경한 뒤 다음 `QUEUED` 항목을 `IN_PROGRESS`로 올린다.
4. 우선순위를 바꾸거나 중간에 새 항목을 삽입하면 이유와 날짜를 변경 기록에 남긴다.
5. 현재 항목 내부의 세부 작업 순서는 별도 Work Order로 만들 수 있지만 상위 단계가 달라지면 이 문서도 갱신한다.
6. 각 항목은 권위 문서·인덱스 연결·완료 검사와 문서 검증까지 끝나야 완료로 처리한다.
7. `BLOCKED` 항목을 건너뛸 때는 차단 이유와 임시 진행 대상을 기록한다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
DEFERRED
```

## 현재 순서

| 순서 | 상태 | 작업 | 완료 조건 |
|---:|---|---|---|
| 1 | `DONE` | Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime | Architecture 계약, ADR-0081, 인덱스 연결, Policy 우선순위·Version·Conflict·Snapshot 계약과 문서 검증 완료 |
| 2 | `DONE` | Encounter–Game Time Boundary 통합 계약 | `TemporalBoundaryOccurrence`, Campaign Time 반영, Scheduler Due 역방향 연결과 직접 상호 호출 금지 확정 |
| 3 | `DONE` | UI Runtime | Projection→ViewModel→Component→Intent 흐름, Panel·Modal·Focus·Q/E·Reconnect·Rollback 복구 계약 완료 |
| 4 | `DONE` | Diagnostics와 Observability Runtime | Command→RuleExecution→Transaction→Event→Projection Trace, 권한별 진단, 성능·오류 Budget 계약 완료 |
| 5 | `DONE` | Deterministic Simulation과 Test Harness | 고정 Seed·Snapshot Scenario·동시성·Reconnect·Rollback·정보 누출 테스트 계약 완료 |
| 6 | `DONE` | Journal Anchor, Permission과 Projection 계약 | Document·Section Identity, World Anchor, 권한별 Search Index, 안전한 Camera·Selection Intent 계약 완료 |
| 7 | `DONE` | Cross-System Integration Contracts와 Completion Audit | Damage·Death·Combat 및 남은 Runtime 연결 계약, 순환·중복·공백 재감사 완료 |
| 8 | `DONE` | Main System Guides | 12개 Guide, 권위 읽기 순서, 상태·책임 경계, 문서 Hub와 완료 감사 확정 |
| 9 | `IN_PROGRESS` | Player·DM User Guide 간소화 | 코딩 용어 없는 Quick Flow, 전체·Player·DM Flowchart와 상세 Guide 연결 완료 |
| 10 | `QUEUED` | Implementation Specs | 수직 단위별 Type·Module·Command·Network·Persistence·Migration·Diagnostics·Test 계약 작성 |
| 11 | `QUEUED` | Production Implementation | 승인된 Spec 순서대로 구현·테스트·리뷰·마이그레이션 수행 |

## 현재 단계

```text
Player·DM User Guide 간소화와 Flowchart
```

현재 세부 작업:

```text
간단한 전체 Session Flow 작성
→ Player·DM 역할별 Flowchart 작성
→ Exploration·Encounter·Scene 전환·Reconnect 분기 작성
→ User Guide Hub와 상세 Guide 연결
→ 간소화 보완 감사와 문서 검증
```

세부 순서는 [`user-guides/CURRENT-USER-GUIDE-WORK-ORDER.md`](user-guides/CURRENT-USER-GUIDE-WORK-ORDER.md)를 따른다.

## 현재 작업 진행 방식

```text
현재 확정 사용자 경험 확인
→ 사용자 행동과 보이는 상태만 추출
→ 전체 Session Flowchart 작성
→ Player와 DM Flowchart 분리
→ 예외 흐름 연결
→ 상세 Guide로 후속 링크
→ 문서 검증
→ User Guide 간소화 DONE
→ Implementation Specs IN_PROGRESS 복귀
```

## 완료된 Main System Guide 단계

- 완료된 세부 순서: [`guides/CURRENT-GUIDE-WORK-ORDER.md`](guides/CURRENT-GUIDE-WORK-ORDER.md)
- Guide 허브: [`guides/README.md`](guides/README.md)
- 완료 감사: [`audits/main-system-guide-consistency-and-document-hub-completion-audit.md`](audits/main-system-guide-consistency-and-document-hub-completion-audit.md)

완료 Guide:

1. [`Runtime Foundation과 Authority`](guides/runtime/README.md)
2. [`Session, Networking, Persistence와 Recovery`](guides/session/README.md)
3. [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](guides/scene/README.md)
4. [`Exploration, Selection, Interaction과 Perception`](guides/exploration/README.md)
5. [`Rules, Character Action, Spell, Dice와 Effect`](guides/rules/README.md)
6. [`Combat와 Encounter`](guides/combat/README.md)
7. [`Character, Inventory와 Downtime`](guides/character/README.md)
8. [`UI, Camera와 Presentation`](guides/ui/README.md)
9. [`Journal과 Ping`](guides/journal/README.md)
10. [`Scene Editor와 Authoring`](guides/scene-editor/README.md)
11. [`Diagnostics, Simulation과 Operations`](guides/diagnostics/README.md)
12. [`Extension, Plugin과 Content Pack`](guides/extension/README.md)

권위 문서가 변경되면 영향받는 Guide를 `UPDATE_REQUIRED`로 다시 연다.

## Player·DM User Guide 단계

- 세부 순서: [`user-guides/CURRENT-USER-GUIDE-WORK-ORDER.md`](user-guides/CURRENT-USER-GUIDE-WORK-ORDER.md)
- User Guide Hub: [`user-guides/README.md`](user-guides/README.md)
- 최초 완료 감사: [`audits/player-and-dm-user-guide-completion-audit.md`](audits/player-and-dm-user-guide-completion-audit.md)

기존 상세 문서:

1. [`Player Guide`](user-guides/player/README.md)
2. [`DM Guide`](user-guides/dm/README.md)

현재 보완 작업은 두 상세 Guide를 대체하지 않는다. 처음 읽는 사용자가 내부 구조를 전혀 몰라도 세션 전체를 이해하도록 짧은 Quick Flow와 명확한 Mermaid Flowchart를 앞에 추가한다.

User Guide가 확정한 새 Product 동작은 없다. 모든 흐름은 현재 Product Scope, UI, Main System Guide와 ADR을 사용자 언어로 통합한다.

## Implementation Specs 단계 원칙

User Guide 보완 완료 후 다음 원칙으로 복귀한다.

1. Spec은 관련 Player·DM User Guide의 목표 흐름을 Acceptance Scenario로 연결한다.
2. Spec은 관련 Main System Guide가 연결한 권위 문서를 근거로 작성한다.
3. User Guide와 Main System Guide 자체를 Type·Command·Schema의 권위 원본으로 사용하지 않는다.
4. 새 제품 동작이나 Architecture 결정이 필요하면 Spec을 멈추고 관련 Product·Architecture·ADR을 먼저 수정한다.
5. Source·Build·State·Projection·Presentation을 하나의 Type이나 Store로 혼합하지 않는다.
6. Client 입력과 Server Authority 검증을 구분한다.
7. Version, Migration, Deprecation, Recovery와 Rollback 영향을 포함한다.
8. Ordering Key, Reservation, Transaction과 Projection Barrier를 필요한 범위에서 명시한다.
9. Trace Span, Error Code, Budget와 Health Probe를 포함한다.
10. 사용자에게 보이는 성공·대기·거부·재시도·Resync 상태를 정의한다.
11. Deterministic Scenario와 실제 Roblox Integration Test 경계를 포함한다.
12. 수치 기본값은 측정 근거 없이 확정하지 않는다.
13. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED`와 오래된 Draft를 권위 근거로 사용하지 않는다.
14. 승인된 Spec 없이 Production Code를 작성하지 않는다.

현재 Spec Hub: [`specs/README.md`](specs/README.md)

## 현재 알려진 문서 정리 대상

- [`product/core-session-loop.md`](product/core-session-loop.md)
  - 오래된 `상태: 초안`
  - 현재 확정 범위와 다른 Encounter Token WASD·Audio 표현이 남아 있음
  - 현재 User Guide와 Implementation Spec 권위 읽기 순서에서 제외
  - 후속 문서 수명주기 정리에서 대체 또는 갱신

현재 이동과 제외 기능은 다음 확정 문서가 소유한다.

- [`플랫폼·이동·입력 범위`](product/platform-movement-and-input-scope.md)
- [`콘텐츠 범위·자동화·Rollback·저장·제외 기능`](product/content-automation-rollback-storage-and-exclusions.md)

## Production Implementation Gate

Production Implementation은 다음 조건 전에는 시작하지 않는다.

- Player·DM User Guide와 Quick Flow 완료
- 현재 수직 Slice의 Implementation Specs 완료
- Type·Command·Network·Persistence·Migration 계약 완료
- Acceptance Scenario와 Failure·Recovery Test 정의
- 영향받는 User Guide·Main Guide와 Authority 문서 정합성 확인
- 문서 검증 성공
- 사용자의 명시적 구현 요청

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | 사용자 요청에 따라 Implementation Specs를 잠시 대기시키고, 코딩 용어 없는 간단한 Session Flow와 확실한 Player·DM Flowchart 보완을 `IN_PROGRESS`로 전환했다. |
| 2026-08-05 | Player Guide, DM Guide, User Guide Hub와 최초 Completion Audit을 완료했다. |
| 2026-08-05 | 사용자의 요청에 따라 Implementation Specs 전에 Player·DM User Guide 단계를 삽입했다. |
| 2026-08-05 | 12개 Main System Guide와 일관성·문서 Hub 감사를 완료했다. Main System Guides를 `DONE`으로 전환했다. |
| 2026-08-05 | Extension·Plugin·Content Pack Guide를 완료하고 최종 Guide 감사로 전환했다. |
| 2026-08-05 | Diagnostics·Simulation·Operations, Scene Editor·Authoring, Journal·Ping, UI·Camera·Presentation, Character·Inventory·Downtime, Combat·Encounter, Rules, Exploration과 Scene Guide를 순서대로 완료했다. |
| 2026-08-04 | Runtime Foundation·Session Guide를 시작으로 Main System Guide 단계의 세부 순서를 확정했다. |
| 2026-08-04 | Cross-Domain Outcome Integration과 Completion Audit을 완료하고 Main System Guides를 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Policy, Encounter–Time, UI, Diagnostics, Simulation, Journal과 Cross-System Integration의 마지막 공통 Runtime 계약을 완료했다. |
| 2026-08-04 | 통합 감사 결과를 기준으로 최초 작업 순서를 확정했다. |
