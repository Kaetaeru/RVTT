# Slice 03 Work Order — Exploration Interaction·Perception

- 상태: CHECKPOINT_COMPLETE
- 문서 종류: Slice Implementation Spec Work Order
- 즉시 구현 명세 가능성: BLOCKED
- 작성일: 2026-08-05
- 전체 Roadmap: [`SLICE-ROADMAP.md`](../../SLICE-ROADMAP.md)
- 선행 Slice: [`Slice 01`](../01-first-session-walking-skeleton/implementation-contract.md), [`Slice 02`](../02-core-rules-kernel/implementation-contract.md)
- 통합 계약: [`implementation-contract.md`](implementation-contract.md)
- 검수 감사: [`Slice 03 Spec Checkpoint Audit`](../../../audits/slices/03-exploration-interaction-perception-spec-checkpoint-audit.md)

## 1. 사용자 완료 결과

```text
탐험 이동
→ Hover·Focus·Selection
→ Door·Container·Lever·Ground Item 상호작용
→ Search·Study·Lock·Trap 판정
→ DM Adjudication 또는 Core Rules 실행
→ Object·Knowledge·Fog Commit
→ 사용자별 안전한 Projection
```

## 2. 명세 작업 순서

| 순서 | 상태 | 작업 | 완료 기준 |
|---:|---|---|---|
| 1 | DONE | Semantic Input·Context Stack | Camera·Token WASD, Q·E, Hover·Selection이 단일 Context에서 소비됨 |
| 2 | DONE | Selection·Preview·Frozen Binding | Hover·Focus·Selection·Target과 Client Preview가 분리됨 |
| 3 | DONE | Interaction Capability·Object State | Door·Container·Lever·Ground Item의 Versioned Interaction Route 정의 |
| 4 | DONE | Search·Study·Lock·Trap | Core Rules Check·Save와 DM Adjudication 연결 |
| 5 | DONE | Visibility·Knowledge·Detection·Fog | Observer별 Knowledge와 Manual Fog Projection 정의 |
| 6 | DONE | Exploration WASD Movement | 클릭 이동과 같은 Navigation·Position Commit 경로 사용 |
| 7 | DONE | Concurrency·Persistence·Recovery | 동시 Interaction, Scene Transition, Reconnect·Rollback 계약 정의 |
| 8 | DONE | Diagnostics·Security·Test | Secret Canary, Client Preview 변조, Fog·Selection Race Scenario 정의 |
| 9 | BLOCKED | Production Source Mapping | 실제 Input·Interaction·Visibility·Fog·Navigation Module 조사 필요 |

## 3. 구현 시 추출할 세부 명세

```text
ui/semantic-input-context
selection/session-preview-frozen-binding
interaction/capability-and-object-state
perception/search-study-detection
visibility/knowledge-manual-fog
navigation/exploration-wasd
persistence/exploration-state-recovery
testing/exploration-disclosure-races
```

## 4. 핵심 Gate

- Hover는 Target 확정이나 Camera 강제 이동이 아니다.
- Client Preview·Path·Range·Tooltip은 실행 근거가 아니다.
- Q·E와 WASD는 최상위 Input Context 하나만 소비한다.
- 문·상자·함정 상태는 Server Command·Transaction으로만 바뀐다.
- Search 실패가 존재하지 않는 Secret을 노출하지 않는다.
- Manual Fog와 Knowledge·Detection을 하나의 Boolean으로 합치지 않는다.
- Player Client는 DM Source·Secret Object·Hidden Actor Raw Data를 받지 않는다.
- Interaction·Fog·Item 동시성은 Revision·Ordering으로 해결한다.

## 5. 차단 사항

- 실제 Client Input Router와 Camera·Token Controller 구조
- Runtime Object Component와 Interaction Definition Schema
- Fog·Visibility·Knowledge 기존 저장 데이터
- Navigation Provider와 WASD Sampling 구현
- Scene Object·Ground Item의 Legacy Identity·Migration 대상