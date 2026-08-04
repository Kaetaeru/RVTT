# Exploration 시스템

실시간 자유 이동, 탐색 행동, 상호작용, 위험 사건과 Encounter 전환을 다룬다.

## 권위 문서

### Exploration Runtime

- [`../../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md`](../../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md)
  - 클릭 이동과 WASD 토큰 이동
  - Actor별 실시간 실행 슬롯과 동시 실행 정책
  - 이동 중 상호작용·공격·주문·장시간 행동
  - Hazard Trigger와 Freeze Scope
  - Exploration에서 Encounter로의 원자적 전환

### 공통 Session Mode

- [`../../architecture/session-play-mode-context-overlay-and-transition-contract.md`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - Exploration Base Play Mode
  - Stealth·Travel·Hazard Context
  - Overlay와 Transitional State

### 이동과 공간

- [`../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
  - 클릭·WASD 공통 Navigation과 Movement Execution
  - Traversal Domain, Checkpoint, Replan과 Occupancy
- [`../../architecture/spatial-query-engine-and-provider-contract.md`](../../architecture/spatial-query-engine-and-provider-contract.md)
  - 접근·점유·Trigger·거리 판정

### 행동과 상호작용

- [`../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)
- [`../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md`](../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md)

### 탐지와 정보 공개

- [`../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)

## 고정 경계

- Exploration은 턴을 사용하지 않지만 무제한 병렬 실행 상태도 아니다.
- Actor별 실행 충돌은 Exploration Runtime이 조정하고 실제 규칙 결과는 기존 RuleExecution과 Transaction이 확정한다.
- 클라이언트 WASD 입력은 방향 의도이며 최종 CFrame이 아니다.
- 공격 입력만으로 모든 상황에서 Encounter를 즉시 시작하지 않는다.
- 함정·위험 사건은 필요한 Actor 또는 지역만 정지시키며 이유 없이 세션 전체를 멈추지 않는다.
- 전투 전환 시 이동·주문·상호작용의 진행 상태를 명시적으로 분류하고 하나의 전환 경계에서 처리한다.

## Guide Status

```text
READY_TO_WRITE
```

최신 Completion Audit와 Main System Guide 작업 순서에서 Exploration·Selection·Interaction·Perception 통합 Guide의 작성 가능성이 확인되었다.
