# ADR-0072: Contextual Interactions as Capability-Derived Commands

- 상태: Accepted
- 작성일: 2026-08-04

## Context

Selection Runtime은 무엇이 선택되었는지를 제공하지만, 문·상자·아이템·함정·환경 오브젝트마다 가능한 행동과 비용이 다르다. 이를 Object Class별 메뉴와 Remote로 구현하면 Exploration·Encounter·DM Override가 서로 다른 경로로 분기되고, 권한과 저장·복구 계약이 깨진다.

기존 RVTT는 다음 기반을 이미 채택했다.

- 등록된 Capability와 RuleExecution
- Selection Session과 Frozen Binding
- Exploration·Encounter·Downtime Base Mode
- Player 행동과 DM Override 분리
- Transaction Coordinator와 Runtime Object Identity

## Decision

모든 문맥 상호작용은 행위자·대상·아이템·효과·Scene·Encounter가 기여하는 Capability를 조회해 `ContextualInteractionOption`을 만들고, 선택된 Option을 서버 검증 가능한 Command Proposal로 변환한다.

```text
Frozen Selection
+ Actor Capability
+ Target Components
+ Session Context
→ Contextual Interaction Options
→ Command Proposal
→ RuleExecution 또는 DM Adjudication
→ Authority Transaction
```

추가 결정:

1. Selection과 UI는 상태를 직접 변경하지 않는다.
2. 같은 Capability는 Exploration과 Encounter에서 서로 다른 비용·Timing Policy를 사용할 수 있다.
3. 플레이어 행동과 DM 강제 조작은 별도 Command와 감사 기록을 사용한다.
4. E는 최상위 입력 문맥의 승인·확정·상호작용이며, Q는 거절·취소·한 단계 뒤로 사용한다.
5. NPC 대화 트리는 비목표이며 사회적 행동은 DM Adjudication으로 처리한다.
6. Workspace Instance와 ProximityPrompt는 권위 Capability Source가 아니다.
7. Context Action Menu는 Projection이며 저장 원본이 아니다.

## Consequences

### Positive

- 문·레버·상자·아이템·환경 행동이 하나의 실행 경로를 공유한다.
- Exploration과 Encounter의 차이를 Capability 복제가 아니라 Context Policy로 표현한다.
- DM 전용 숨김 행동과 Override가 플레이어에게 누출되지 않는다.
- AI·Trigger·Plugin도 같은 Command 경로를 사용할 수 있다.
- 저장·재접속·Rollback이 RuleExecution과 Transaction 계약을 그대로 사용한다.

### Negative

- Capability Query와 Projection Cache가 필요하다.
- 단순 오브젝트도 행위자·대상 결합 검증을 거쳐야 한다.
- DM 판정 대기 흐름과 timeout 정책이 필요하다.

## Rejected Alternatives

### Object Class별 Context Menu 하드코딩

새 Object와 Plugin마다 분기가 늘어나고 역할·모드 계약이 중복되므로 거부한다.

### Client ProximityPrompt가 상태 직접 변경

서버 권위, Action Economy, 비밀 정보와 Transaction을 우회하므로 거부한다.

### DM Override와 일반 Player Command 통합

권한 우회와 감사 불가능 상태를 만들므로 거부한다.

### Exploration과 Encounter용 별도 Interaction 시스템

동일 행동의 중복 구현과 상태 불일치를 만들므로 거부한다.

## Related

- [`Interaction Capability 계약`](../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)
- [`Selection과 Targeting Runtime`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Character Action Runtime`](../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Session Runtime`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Runtime Object System`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
