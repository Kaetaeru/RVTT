# RVTT Remake 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Planning Work Order
- 최종 갱신일: 2026-08-05
- 근거 감사: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

이 문서는 RVTT 리메이크 기획·명세·구현의 **단일 작업 순서 기준**이다.

## 운영 규칙

1. 둘 이상의 다음 작업 순서를 제안하거나 변경할 때는 작업을 시작하기 전에 이 문서를 먼저 갱신한다.
2. 별도 대화·메모·체크리스트가 이 문서와 충돌하면 이 문서의 순서를 따른다.
3. 기본적으로 가장 위의 `IN_PROGRESS` 항목을 먼저 끝내고, 완료 후 `DONE`으로 변경한 뒤 다음 `QUEUED` 항목을 `IN_PROGRESS`로 올린다.
4. 우선순위를 바꾸거나 중간에 새 항목을 삽입하면 이유와 날짜를 변경 기록에 남긴다.
5. 현재 항목 내부의 세부 체크리스트는 별도로 만들 수 있지만, 상위 작업 순서가 달라지면 반드시 이 문서도 갱신한다.
6. 각 항목은 권위 문서·ADR·인덱스 연결·문서 검증까지 끝나야 완료로 처리한다.
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
| 1 | `DONE` | Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime | Architecture 계약, ADR-0081, 인덱스 연결, Policy 우선순위·버전·충돌·Snapshot 계약과 문서 검증 완료 |
| 2 | `DONE` | Encounter–Game Time Boundary 통합 계약 | `TemporalBoundaryOccurrence`, Campaign Time 반영, Scheduler Due 역방향 연결과 직접 상호 호출 금지 확정 |
| 3 | `DONE` | UI Runtime | Projection→ViewModel→Component→Intent 흐름, Panel·Modal·Focus·Q/E·Reconnect·Rollback 복구 계약 완료 |
| 4 | `DONE` | Diagnostics와 Observability Runtime | Command→RuleExecution→Transaction→Event→Projection Trace, 권한별 진단, 성능·오류 Budget 계약 완료 |
| 5 | `DONE` | Deterministic Simulation과 Test Harness | 고정 Seed·Snapshot Scenario·동시성·Reconnect·Rollback·정보 누출 테스트 계약 완료 |
| 6 | `DONE` | Journal Anchor, Permission과 Projection 계약 | 문서·Section Identity, 월드 Anchor, 권한별 검색 Index, 안전한 Camera·Selection Intent 계약 완료 |
| 7 | `DONE` | Cross-System Integration Contracts와 Completion Audit | Damage·Death·Combat 및 남은 Runtime 연결 계약, 순환·중복·공백 재감사 완료 |
| 8 | `IN_PROGRESS` | Main System Guides | 권위 문서와 사용자 흐름을 영역별 Guide로 통합하고 폐기 문서를 제외한 읽기 순서 확정 |
| 9 | `QUEUED` | Implementation Specs | 수직 단위별 타입·모듈·Command·Network·Persistence·Test 계약 작성 |
| 10 | `QUEUED` | Production Implementation | 승인된 Spec 순서대로 구현·테스트·리뷰·마이그레이션 수행 |

## 작업 진행 방식

```text
CURRENT-WORK-ORDER 확인
→ 현재 IN_PROGRESS 항목 조사
→ 필요한 Architecture·ADR·System 문서 작성
→ README와 권위 링크 갱신
→ 문서 검증
→ 현재 항목 DONE
→ 다음 항목 IN_PROGRESS
→ CURRENT-WORK-ORDER 갱신
```

## Main System Guide 단계 원칙

- 활성 세부 작업 순서: [`guides/CURRENT-GUIDE-WORK-ORDER.md`](guides/CURRENT-GUIDE-WORK-ORDER.md)
- 현재 완료 Guide:
  - [`Runtime Foundation과 Authority`](guides/runtime/README.md)
  - [`Session, Networking, Persistence와 Recovery`](guides/session/README.md)
  - [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation`](guides/scene/README.md)
  - [`Exploration, Selection, Interaction과 Perception`](guides/exploration/README.md)
  - [`Rules, Character Action, Spell, Dice와 Effect`](guides/rules/README.md)
  - [`Combat와 Encounter`](guides/combat/README.md)
  - [`Character, Inventory와 Downtime`](guides/character/README.md)
  - [`UI, Camera와 Presentation`](guides/ui/README.md)
  - [`Journal과 Ping`](guides/journal/README.md)
- 현재 세부 작업: `Scene Editor와 Authoring Guide`

1. Guide는 새로운 Authority 결정을 만들지 않고 확정된 Architecture·ADR을 통합한다.
2. 각 Guide는 권위 원본, 역할별 사용자 흐름, Command·Transaction·Projection 경로, 실패·복구와 구현 Spec 진입점을 포함한다.
3. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 권위 읽기 순서에서 제외한다.
4. 여러 Guide의 작성 순서를 정하거나 변경할 때는 [`guides/CURRENT-GUIDE-WORK-ORDER.md`](guides/CURRENT-GUIDE-WORK-ORDER.md)를 먼저 갱신한다.
5. Guide가 새로운 Architecture 공백을 발견하면 해당 Guide를 완료 처리하지 않고 Architecture·ADR 작업을 삽입한다.

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | Journal·Ping Guide를 완료하고 Main System Guide 세부 작업을 Scene Editor·Authoring Guide로 전환했다. |
| 2026-08-05 | UI·Camera·Presentation Guide를 완료하고 Main System Guide 세부 작업을 Journal·Ping Guide로 전환했다. |
| 2026-08-05 | Character·Inventory·Downtime Guide를 완료하고 Main System Guide 세부 작업을 UI·Camera·Presentation Guide로 전환했다. |
| 2026-08-05 | Combat·Encounter Guide를 완료하고 Main System Guide 세부 작업을 Character·Inventory·Downtime Guide로 전환했다. |
| 2026-08-05 | Rules·Character Action·Spell·Dice·Effect Guide를 완료하고 Main System Guide 세부 작업을 Combat·Encounter Guide로 전환했다. |
| 2026-08-05 | Exploration·Selection·Interaction·Perception Guide를 완료하고 Main System Guide 세부 작업을 Rules·Character Action·Spell·Dice·Effect Guide로 전환했다. |
| 2026-08-05 | Scene·Streaming·Runtime Object·Spatial Query·Navigation Guide를 완료하고 Main System Guide 세부 작업을 Exploration·Selection·Interaction·Perception Guide로 전환했다. |
| 2026-08-04 | Main System Guide 세부 순서를 `guides/CURRENT-GUIDE-WORK-ORDER.md`에 확정했다. Runtime Foundation과 Authority Guide를 완료하고 Session·Networking·Persistence·Recovery Guide를 현재 세부 작업으로 전환했다. |
| 2026-08-04 | Cross-Domain Outcome Cascade·Integration Boundary Runtime 계약과 ADR-0087을 확정하고 Completion Audit에서 현재 제품 범위의 Architecture·Integration을 완료로 판정했다. 7번을 `DONE`, Main System Guides를 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Journal Document·Section·Anchor·Permission·Search·Projection Runtime 계약과 ADR-0086을 완료했다. 기존 Journal·Ping 결합 문서를 분리하고 6번을 `DONE`, Cross-System Integration Contracts와 Completion Audit을 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Deterministic Simulation·Scenario·Test Harness Runtime 계약과 ADR-0085를 완료했다. 5번을 `DONE`으로 변경하고 Journal Anchor·Permission·Projection 계약을 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Diagnostics·Observability·Correlated Trace·Incident Runtime 계약과 ADR-0084를 완료했다. 4번을 `DONE`으로 변경하고 Deterministic Simulation과 Test Harness를 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | UI Projection·ViewModel·Input Context·Recovery Runtime 계약과 ADR-0083을 완료했다. 3번을 `DONE`으로 변경하고 Diagnostics와 Observability Runtime을 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Encounter–Game Time Temporal Boundary 통합 계약과 ADR-0082를 완료했다. 2번을 `DONE`으로 변경하고 UI Runtime을 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Policy Registry·Composition·Frozen Snapshot 계약과 ADR-0081을 완료했다. 1번을 `DONE`으로 변경하고 Encounter–Game Time Boundary 통합 계약을 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | 통합 감사 결과를 기준으로 최초 작업 순서를 확정했다. Policy Composition Runtime을 현재 작업으로 지정했다. |
