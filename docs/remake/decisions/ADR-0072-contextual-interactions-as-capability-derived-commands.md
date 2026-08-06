# ADR-0072: Contextual Interactions as Capability-Derived Commands

- 상태: Accepted · ADR-0088로 직접 플레이 표현 보강
- 작성일: 2026-08-04
- 최종 갱신일: 2026-08-06
- 관련 결정: [`ADR-0088 직접 플레이 포인터 문법과 피드백 연속성`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)

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
+ Viewer Permission
→ Contextual Interaction Options
→ Default Action Projection + Context Action Table
→ Command Proposal
→ RuleExecution 또는 DM Adjudication
→ Authority Transaction
```

추가 결정:

1. Selection과 UI는 상태를 직접 변경하지 않는다.
2. 같은 Capability는 Exploration과 Encounter에서 서로 다른 비용·Timing Policy를 사용할 수 있다.
3. 플레이어 행동과 DM 강제 조작은 별도 Command와 감사 기록을 사용한다.
4. E는 최상위 입력 문맥의 승인·확정·상호작용이며, Q는 닫기·거절·취소·한 단계 뒤로 사용한다.
5. ESC에는 Gameplay 의미를 부여하지 않는다.
6. NPC 대화 트리는 비목표이며 사회적 행동은 DM Adjudication으로 처리한다.
7. Workspace Instance와 ProximityPrompt는 권위 Capability Source가 아니다.
8. Context Action Table과 좌클릭 Default Action은 Projection이며 저장 원본이 아니다.
9. 좌클릭 Default Action은 결정적인 우선순위를 사용하며 클릭 전에 이름·대상·비용·유효성을 표시한다.
10. 조작 가능한 다른 아군 Actor 클릭은 공격이나 상호작용보다 선택 전환을 우선한다.
11. 오른쪽 클릭은 Viewer에게 허용된 전체 행동을 2열 Action Table로 표시한다.
12. Viewer 권한에 없는 행동과 미인지 정보는 표시하지 않는다.
13. Viewer 권한에는 있으나 현재 실행할 수 없는 행동은 비활성 색상 버튼으로 표시하고 클릭을 차단한다.
14. 비활성 버튼 Hover 시 커서 옆에 짧고 구체적인 불가능 사유를 표시한다.
15. 버튼 옆에 가능·불가능 문장을 상시 표시하지 않는다.
16. 기본 행동, 행동, 추가 행동, 이동, 상호작용, 정보와 허용된 DM 행동 순으로 안정적인 정렬을 유지한다.
17. Action Table이 열린 동안 월드 좌클릭 기본 행동은 실행하지 않으며 Q로 표를 닫는다.
18. 마우스 휠 클릭 Camera Orbit과 WASD·Wheel Camera 입력은 Action Table이 열려 있어도 유지할 수 있다.
19. 서버는 최종 권한, Turn, Opportunity, 자원, 거리와 대상 유효성을 최신 Snapshot에서 다시 검증한다.
20. 일반 거부 사유는 커서·대상·관련 HUD 근처에 표시하고 Modal을 남용하지 않는다.

## Default Action 우선순위

```text
조작 가능한 다른 아군 Actor
→ 선택 전환

적대 Actor + 활성 Encounter
→ 기본 공격 또는 명시적으로 지정된 기본 전투 행동

우호·중립 Actor
→ 대화·도움·상호작용

Exploration Object
→ 현재 상태에 맞는 기본 상호작용

이동 가능한 표면
→ 이동

유효한 행동 없음
→ 실행하지 않고 이유 표시
```

최근 사용 행동만으로 기본 행동을 자동 변경하지 않는다. 사용자가 명시적으로 지정한 경우에만 변경하며, 지정된 행동이 현재 불가능하면 안전한 상황 기본 행동으로 돌아간다.

## Action Availability Projection

```text
권한 없음 또는 미인지
→ Option Projection 없음

권한 있음 + 현재 불가능
→ disabled
→ 비활성 색상
→ Pointer 실행 차단
→ Hover Tooltip에 disabledReason

권한 있음 + 현재 가능
→ enabled
→ 실행 또는 Targeting 진입 가능
```

대표 `disabledReason`:

- 현재 턴이 아닙니다
- 행동을 이미 사용했습니다
- 남은 이동 거리가 부족합니다
- 대상이 사거리 밖에 있습니다
- 시야가 확보되지 않았습니다
- 필요한 자원이 없습니다
- 이 대상을 조작할 권한이 없습니다

## Consequences

### Positive

- 문·레버·상자·아이템·환경 행동이 하나의 실행 경로를 공유한다.
- Exploration과 Encounter의 차이를 Capability 복제가 아니라 Context Policy로 표현한다.
- DM 전용 숨김 행동과 Override가 플레이어에게 누출되지 않는다.
- AI·Trigger·Plugin도 같은 Command 경로를 사용할 수 있다.
- 저장·재접속·Rollback이 RuleExecution과 Transaction 계약을 그대로 사용한다.
- 사용자는 행동이 사라진 것인지 현재 조건 때문에 비활성인지 구분할 수 있다.
- 월드 좌클릭과 전체 행동표가 같은 Capability Projection을 공유한다.

### Negative

- Capability Query, Availability Projection과 Hover Tooltip Cache가 필요하다.
- 단순 Object도 행위자·대상 결합 검증을 거쳐야 한다.
- DM 판정 대기 흐름과 timeout 정책이 필요하다.
- Default Action과 Action Table이 같은 Revision에서 갱신되어야 한다.

## Rejected Alternatives

### Object Class별 Context Menu 하드코딩

새 Object와 Plugin마다 분기가 늘어나고 역할·모드 계약이 중복되므로 거부한다.

### 실행 가능한 행동만 표시

사용자는 행동이 사라졌는지 현재 조건 때문에 사용할 수 없는지 알 수 없으므로 거부한다.

### 모든 불가능 사유를 버튼 옆에 상시 표시

Action Table의 정보 밀도를 과도하게 높이므로 거부한다. 비활성 색상과 Hover Tooltip을 사용한다.

### Client ProximityPrompt가 상태 직접 변경

서버 권위, Action Economy, 비밀 정보와 Transaction을 우회하므로 거부한다.

### DM Override와 일반 Player Command 통합

권한 우회와 감사 불가능 상태를 만들므로 거부한다.

### Exploration과 Encounter용 별도 Interaction 시스템

동일 행동의 중복 구현과 상태 불일치를 만들므로 거부한다.

## Related

- [`ADR-0088 직접 플레이 UX`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- [`Interaction Capability 계약`](../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)
- [`Selection과 Targeting Runtime`](../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Character Action Runtime`](../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Session Runtime`](../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Runtime Object System`](../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
