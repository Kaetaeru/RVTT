# Main System Guide 현재 작업 순서

- 상태: ACTIVE
- 문서 종류: Guide Work Order
- 최종 갱신일: 2026-08-05
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 근거 감사: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

이 문서는 `CURRENT-WORK-ORDER.md`의 **8. Main System Guides** 단계에서 사용할 단일 세부 작업 순서 기준이다.

## 운영 규칙

1. Main System Guide를 둘 이상 작성하거나 순서를 변경할 때는 이 문서를 먼저 갱신한다.
2. 가장 위의 `IN_PROGRESS` Guide를 우선 완료한다.
3. Guide는 새로운 제품 규칙·Architecture·Schema·Command를 정의하지 않는다.
4. 새로운 권위 공백이 발견되면 해당 Guide를 `BLOCKED`로 표시하고 Architecture·ADR 작업을 상위 작업 순서에 삽입한다.
5. `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 Authority Documents와 추천 읽기 순서에서 제외한다.
6. Guide는 표준 Template, 권위 링크, 변경 영향 지도와 검증 체크리스트를 모두 충족해야 `DONE`이다.
7. 권위 문서가 변경되면 관련 Guide를 `UPDATE_REQUIRED`로 되돌린다.

상태 값:

```text
IN_PROGRESS
QUEUED
BLOCKED
DONE
UPDATE_REQUIRED
DEFERRED
```

## 현재 순서

| 순서 | 상태 | Guide | 완료 조건 |
|---:|---|---|---|
| 1 | `DONE` | Runtime Foundation과 Authority | Source·Build·State·Policy·Command·RuleExecution·Transaction·Event·Projection·Recovery 전체 기반 흐름과 권위 읽기 순서 통합 |
| 2 | `DONE` | Session, Networking, Persistence와 Recovery | Lobby·Join·Control·Mode·Transition·Reconnect·Snapshot·Rollback 사용자·권위 흐름 통합 |
| 3 | `DONE` | Scene, Streaming, Runtime Object, Spatial Query와 Navigation | Scene Source부터 Live Presence·Chunk·Query·Path·Movement까지 월드 Runtime 흐름 통합 |
| 4 | `DONE` | Exploration, Selection, Interaction과 Perception | 실시간 이동·행동·대상 지정·상호작용·시야·탐지·Encounter 전환 통합 |
| 5 | `DONE` | Rules, Character Action, Spell, Dice와 Effect | Capability·Opportunity·Spell Route·Roll·Resolution·Effect 수명주기 통합 |
| 6 | `IN_PROGRESS` | Combat와 Encounter | Initiative Timeline·Turn·Reaction·Damage·Death·Objective·Time·Rollback 통합 |
| 7 | `QUEUED` | Character, Inventory와 Downtime | 성장 Source·Build·State·Item·Equipment·Rest·Level Up·Crafting·Travel 통합 |
| 8 | `QUEUED` | UI, Camera와 Presentation | Projection Replica·ViewModel·Input Context·Panel·CameraRequest·Presentation Recipe 통합 |
| 9 | `QUEUED` | Journal과 Ping | Document·Section·Anchor·Permission·Search·Navigation과 비권위 Ping 흐름 통합 |
| 10 | `QUEUED` | Scene Editor와 Authoring | DM Authoring Source·Tool Module·Publish·Validation·Live Patch 경계 통합 |
| 11 | `QUEUED` | Diagnostics, Simulation과 Operations | Trace·Incident·Budget·Scenario·Fault Injection·Support·Recovery 검증 통합 |
| 12 | `QUEUED` | Extension, Plugin과 Content Pack | Registry·Compiler·Policy·Recipe·Provider·Presentation Module 확장 경계 통합 |
| 13 | `QUEUED` | Guide 일관성 감사와 문서 허브 갱신 | 전체 Guide 링크·권위 중복·상태·추천 읽기 순서 검사와 Main Guide 단계 완료 판정 |

## 순서 원칙

```text
Runtime Authority Foundation
→ Session Reliability
→ World Runtime
→ Real-time Exploration
→ Rules Execution
→ Encounter
→ Persistent Character Play
→ Client Experience
→ Knowledge Tools
→ Authoring Tools
→ Diagnostics·Testing
→ Extension
→ Guide Completion Audit
```

앞 단계 Guide가 뒤 단계의 공통 용어와 권위 흐름을 제공한다. 뒤 단계 Guide는 앞 Guide를 권위 Parent로 삼지 않고 탐색 참고로만 연결한다.

## 공통 Guide 완료 조건

- [`../templates/main-system-guide-template.md`](../templates/main-system-guide-template.md)의 필수 절을 포함한다.
- 시스템 목적, 사용자 결과, 데이터 흐름과 실행 흐름을 설명한다.
- Parent Authority, Child Authority와 References를 구분한다.
- 인접 시스템의 제공·소유 경계를 표로 정리한다.
- 추천 읽기 순서와 이미 확정된 구현·검증 의존 순서를 제공한다.
- 변경 영향 지도와 Authority Documents를 포함한다.
- 최신 Completion Audit와 관련 ADR을 연결한다.
- 새로운 결정이나 임의 기본값을 만들지 않는다.
- 문서 검증 Workflow가 성공한다.

## 변경 기록

| 날짜 | 변경 |
|---|---|
| 2026-08-05 | Rules·Character Action·Spell·Dice·Effect Guide를 완료하고 5번을 `DONE`, Combat·Encounter Guide를 `IN_PROGRESS`로 전환했다. |
| 2026-08-05 | Exploration·Selection·Interaction·Perception Guide를 완료하고 4번을 `DONE`, Rules·Character Action·Spell·Dice·Effect Guide를 `IN_PROGRESS`로 전환했다. |
| 2026-08-05 | Scene·Streaming·Runtime Object·Spatial Query·Navigation Guide를 완료하고 3번을 `DONE`, Exploration·Selection·Interaction·Perception Guide를 `IN_PROGRESS`로 전환했다. |
| 2026-08-05 | Session·Networking·Persistence·Recovery Guide를 완료하고 2번을 `DONE`, Scene·Streaming·Runtime Object·Spatial Query·Navigation Guide를 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Runtime Foundation과 Authority Guide를 완료하고 1번을 `DONE`, Session·Networking·Persistence·Recovery Guide를 `IN_PROGRESS`로 전환했다. |
| 2026-08-04 | Main System Guide 단계의 최초 세부 순서를 확정하고 Runtime Foundation과 Authority Guide를 `IN_PROGRESS`로 지정했다. |
