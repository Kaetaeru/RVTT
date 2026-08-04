# Interaction Capability, Contextual Command와 Adjudication 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Context Action Menu 정렬 가중치
  - 자동 초점 상호작용 거리와 화면 중심 가중치
  - DM 승인 요청 timeout
  - 반복 상호작용 debounce 기본값
  - 상호작용 후보 최대 표시 수
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0026`](../decisions/ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`ADR-0037`](../decisions/ADR-0037-zero-metadata-interaction-prefabs-and-state-snapshot-transitions.md)
  - [`ADR-0047`](../decisions/ADR-0047-contextual-dm-quick-actions-and-safe-command-execution.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0067`](../decisions/ADR-0067-2024-core-actions-as-registered-action-capabilities.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0071`](../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md)
  - [`ADR-0072`](../decisions/ADR-0072-contextual-interactions-as-capability-derived-commands.md)
- 상위 문서:
  - [`Character Action Runtime`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - [`Selection과 Targeting Runtime`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Session Runtime`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Rule Runtime Orchestrator`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Transaction Coordinator`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Runtime Object System`](runtime-object-system-and-entity-lifecycle-contract.md)
- 관련 시스템:
  - [`Interaction 시스템`](../systems/interaction/README.md)
  - [`Inventory 시스템`](../systems/inventory/README.md)
  - [`DM Workspace`](../ui/dm-workspace/README.md)

## 1. 목적

Selection은 무엇을 선택했는지만 확정한다. Interaction Runtime은 선택된 대상과 현재 행위자가 사용할 수 있는 행동을 계산하고 안전한 Command로 변환한다.

```text
Input Intent
→ Frozen Selection
→ Interaction Capability Query
→ Contextual Interaction Option
→ Command Proposal
→ RuleExecution 또는 DM Adjudication
→ Authority Transaction
```

Selection Runtime, UI와 Runtime Object가 직접 문을 열거나 아이템을 옮기지 않는다.

## 2. 핵심 원칙

1. 상호작용은 대상 타입별 하드코딩 메뉴가 아니라 Capability 기여의 결과다.
2. 같은 Capability라도 Exploration과 Encounter에서 비용·검증·표시가 달라질 수 있다.
3. UI는 Capability를 실행하지 않고 Command Proposal만 만든다.
4. 플레이어 일반 행동과 DM Override는 별도 Command와 감사 경로를 사용한다.
5. E는 현재 최상위 입력 문맥의 유효한 `Confirm` 또는 `Interact`만 실행한다.
6. Q는 현재 최상위 입력 문맥을 한 단계 취소하거나 DM 요청을 거절한다.
7. NPC 대화 시스템은 만들지 않는다. `Influence`와 사회적 상호작용은 DM 판정 보조 흐름이다.

## 3. Interaction Capability

```text
InteractionCapability
├─ capabilityId
├─ sourceRef
├─ verbId
├─ subjectPredicate
├─ targetPredicate
├─ modePolicies
├─ contextPredicates
├─ disclosurePolicy
├─ costPlan
├─ selectionPlanRef?
├─ executionRecipeRef?
├─ adjudicationPolicy
├─ repeatPolicy
└─ presentationHints
```

`verbId` 예시:

```text
open
close
lock
unlock
inspect
search
study
utilize
pick_up
drop
move_object
equip
unequip
consume
loot
attack_object
disarm
activate
deactivate
repair
force_open
force_move
journal_link
```

`verbId` 자체가 구현 함수를 뜻하지 않는다. Capability는 실행 Recipe 또는 등록된 Command Builder를 참조한다.

## 4. Capability Provider

상호작용 후보는 여러 Provider가 동시에 기여할 수 있다.

```text
Character Capability Set
Item Compiled Build
Runtime Object Components
Effect와 Condition
Scene Context
Encounter Policy
Campaign Policy
DM Override Registry
```

예시:

```text
Door Runtime Object
+ StateMachineComponent
+ LockComponent
+ DurabilityComponent
→ Open, Close, Unlock, Attack Object
```

```text
Character
+ Thieves' Tools Proficiency
+ Lockpicks ItemInstance
→ Attempt Unlock
```

Object가 모든 행동을 소유하지 않는다. 행위자와 대상의 Capability 기여를 결합한다.

## 5. Interaction Query

```text
InteractionQuery
├─ requesterUserId
├─ actingCharacterId?
├─ actingActorRef?
├─ frozenSelectionRef
├─ baseMode
├─ contexts[]
├─ activeOverlays[]
├─ role
├─ controlAssignment
├─ disclosureSnapshot
└─ revisionSet
```

결과:

```text
ContextualInteractionOption[]
├─ optionId
├─ capabilityId
├─ verbId
├─ availability
├─ failureReasons[]
├─ costPreview
├─ requiresFurtherSelection
├─ requiresDMAdjudication
├─ disclosureLevel
├─ commandBuilderId
└─ presentationHints
```

`availability`:

```text
available
available_with_warning
requires_selection
requires_dm_adjudication
blocked_visible
hidden
```

플레이어에게 존재 자체가 비밀인 행동은 `blocked_visible`이 아니라 `hidden`으로 Projection한다.

## 6. Exploration과 Encounter

Capability는 동일하되 Contextual Command가 달라진다.

### Exploration

```text
Open Door
→ 실시간 Interaction Command
→ 거리·접근·공개 상태 검증
→ 필요 시 이동 후 실행
```

### Encounter

```text
Open Door
→ Utilize 기반 Action Capability
→ 현재 턴·행동 기회·거리 검증
→ Opportunity와 Trigger 처리
→ Command Commit
```

Encounter가 시작되었다는 이유로 문·상자·바닥 아이템 상호작용을 금지하지 않는다. 비용과 Timing이 Encounter 규칙으로 바뀐다.

## 7. 기본 상호작용과 메뉴

현재 초점 대상에 명확하고 안전한 기본 행동이 하나뿐이면 E로 실행할 수 있다.

```text
닫힌 잠기지 않은 문
→ E: 열기

열린 문
→ E: 닫기

바닥 공개 아이템
→ E: 줍기
```

다음 경우 E는 즉시 실행하지 않고 선택 또는 확인을 연다.

- 가능한 주요 행동이 둘 이상임
- 파괴적이거나 되돌리기 어려움
- 자원 소비가 큼
- 비밀 정보 또는 DM 판정이 필요함
- 추가 대상·경로·수치 입력이 필요함

Context Action Menu는 Option Projection이며 권위 원본이 아니다.

## 8. Q와 E 입력 계약

입력 우선순위는 공통 입력 문맥 스택을 따른다.

```text
텍스트 입력
→ 모달·DM 승인 요청
→ 진행 중 Selection·다단계 Interaction
→ 최상위 Overlay
→ 현재 Base Mode Interaction
```

### Q

```text
DM 승인 요청
→ 거절

추가 대상 선택 중
→ 현재 Selection Step 취소

상호작용 확인창
→ 닫기

열린 Inventory·Journal·Character Sheet
→ 최상위 Overlay 하나 닫기
```

### E

```text
DM 승인 요청
→ 승인

상호작용 확인창
→ 현재 선택 승인

유효한 기본 Interaction Focus
→ Command Proposal 제출

다단계 상호작용 완료
→ 최종 확정
```

Q/E는 후보 순환에 사용하지 않는다.

## 9. Command Proposal

```text
InteractionCommandProposal
├─ clientIntentId
├─ requesterUserId
├─ actorRef
├─ targetBinding
├─ capabilityId
├─ optionId
├─ selectedParameters
├─ expectedRevisions
├─ roleContext
├─ baseModeContext
└─ disclosureProof
```

Client는 성공 여부, 최종 상태, 최종 위치나 소비 결과를 보내지 않는다.

서버는 다음을 다시 계산한다.

- 역할과 제어권
- Capability 존재와 활성 상태
- 대상 Identity·Incarnation·Revision
- 거리·접근·시야·공개 정책
- 현재 Base Mode와 Action Opportunity
- Item·Resource·Tool 요구 조건
- Lock·StateMachine·Durability 상태
- Transition·Pause Gate

## 10. DM Adjudication

자동 해결이 부적절한 Interaction은 저장 가능한 판정 요청을 만든다.

```text
InteractionCommandProposal
→ AdjudicationRequest
→ DM Projection
→ E 승인 / Q 거절 / 수정안 선택
→ RuleExecution 재개
```

사용 예시:

- 즉흥적인 물체 사용
- 가능한지 애매한 Help
- Influence
- 비밀 함정 조사
- 특수 잠금장치 해제
- 규칙에 없는 환경 조작

DM 승인 요청이 열리면 해당 요청이 DM 입력 문맥 최상단을 차지한다. Scene Editor 작업은 보존된다.

## 11. 역할별 권한

### PLAYER_ONLY

- 제어 중인 Character로 공개된 상호작용 실행
- 자신의 ItemInstance 사용·장착·버리기
- 공개 바닥 아이템 줍기
- Ready·Utilize·Search·Study 등 규칙 행동 선언
- DM 판정이 필요한 의도 제출

### DM_ONLY

- 숨겨진 Object와 Trigger 상호작용
- Force Open·Force Lock·Force Move
- 조건·거리·행동 비용 무시 Override
- Item·Object 생성·삭제·복원
- 실제 숨김 정보 확인
- Journal Link 작성
- Interaction Capability 강제 추가·회수
- Adjudication 승인·거절·수정

### SHARED

- 공개 대상 Inspect
- 공개 Context Action 확인
- 공개 Roll·결과·상태 전환 확인
- 공개 위치 Ping

### SYSTEM_ONLY

- Capability 수집과 조건 평가
- Contextual Option Projection
- Command 재검증
- Reservation·RuleExecution·Transaction
- 반복 입력 방지
- 재접속·복구·Rollback

DM이 Player 행동을 정상 규칙으로 실행할 때는 Player Command 경로를 사용한다. DM Override는 별도 Command와 Audit Record를 사용한다.

## 12. Item과 World Presence

바닥 아이템 상호작용은 Item Presence Runtime Object를 선택하지만 실제 이전 대상은 ItemInstance다.

```text
Item Presence Selection
→ Pick Up Capability
→ ItemInstance Location Transfer
→ Presence 제거
```

상자 열기와 Loot 이전도 Container State와 ItemInstance Transfer를 하나의 Transaction으로 처리한다.

## 13. 상태형 Scene Object

문·레버·상자 프리팹의 상태 전환은 기존 Compiled Interaction Prefab과 StateMachine Component를 사용한다.

```text
Open Capability
→ Transition Proposal
→ Navigation·Visibility·Collision 변경 예약
→ Presentation Transition
→ Commit Point
→ Current State Commit
```

Tween 완료 자체가 권위 상태가 아니다. 실패 복구 시 권위 Current State에 맞춰 Presentation을 재생성한다.

## 14. Interaction과 공격

Object 공격은 Interaction State를 직접 수정하지 않는다.

```text
Attack Object Capability
→ Attack RuleExecution
→ Damage Resolution
→ Durability State 변경
→ 파괴 Threshold
→ State Transition 또는 Runtime Object Lifecycle
```

Force Open과 Attack Object는 다른 Capability다.

## 15. 반복·동시성

각 Command는 대상 Revision과 Interaction Commit Key를 가진다.

```text
actorId
+ targetRuntimeObjectId
+ capabilityId
+ occurrenceId
→ interactionCommitKey
```

두 사용자가 동시에 같은 문을 열거나 같은 아이템을 주우면 Transaction Coordinator가 최신 상태에서 하나만 Commit하거나, 이미 원하는 상태가 된 경우 멱등 성공으로 정규화한다.

## 16. Projection

플레이어 Projection에는 다음만 포함한다.

- 공개 가능한 행동 이름
- 현재 사용할 수 있는지
- 공개 가능한 실패 이유
- 예상 Action·Resource 비용
- 필요한 추가 선택

다음은 DM 전용이다.

- 숨겨진 Capability
- 실제 함정·비밀문 Identity
- 비밀 DC
- Override 옵션
- 강제 Command
- Journal Link

## 17. 저장과 복구

저장 대상:

- 진행 중 RuleExecution과 AdjudicationRequest
- Reservation
- Runtime Object Interaction State
- ItemInstance와 Container Transfer State
- Revision과 Commit Marker

저장하지 않는 대상:

- Hover
- Interaction Menu
- 버튼 정렬
- Highlight와 Tooltip
- E 기본 행동 Cache

재접속 시 진행 중 판정 요청과 실행을 복원하되 Client Menu는 최신 Projection에서 다시 만든다.

## 18. 실패 코드

```text
ROLE_NOT_ALLOWED
CONTROL_NOT_ALLOWED
CAPABILITY_UNAVAILABLE
TARGET_NOT_DISCLOSED
TARGET_STALE
TARGET_IN_WRONG_SCENE
OUT_OF_RANGE
NO_VALID_ACCESS_PATH
ACTION_OPPORTUNITY_UNAVAILABLE
REQUIRED_ITEM_MISSING
RESOURCE_UNAVAILABLE
STATE_CHANGED
TRANSITION_BLOCKED
DM_ADJUDICATION_REQUIRED
SESSION_TRANSITION_ACTIVE
```

실패 메시지는 역할과 공개 정책에 따라 축약한다.

## 19. 비목표

- 자동 NPC 대화 트리
- Client가 직접 상태를 변경하는 ProximityPrompt 권위
- Object Class별 별도 Remote
- UI 메뉴를 저장 원본으로 사용
- DM Override와 Player 행동을 같은 Command로 위장
- Workspace Instance 직접 탐색으로 Capability 생성

## 20. 후속 문서

이 계약 이후 다음 문서를 정리한다.

1. Exploration Runtime
2. Encounter Runtime 최신화
3. Perception과 Disclosure Runtime
4. Camera Runtime
5. Interaction 구현 명세
