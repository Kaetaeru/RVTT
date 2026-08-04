# Exploration 실시간 이동, 행동과 Encounter 전환 Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - WASD Intent 전송·서버 확인 주기
  - Actor별 실시간 실행 Queue 상한
  - 이동 중 상호작용 자동 정지 거리
  - 적대 행동 후 Encounter 제안 지연 상한
  - Hazard Freeze 반응 시간과 동시 이동 정렬 기준
  - 장시간 탐험 행동의 기본 취소·중단 정책
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0048`](../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md)
  - [`ADR-0056`](../decisions/ADR-0056-hybrid-traversal-domain-and-checkpointed-movement-execution.md)
  - [`ADR-0061`](../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
  - [`ADR-0072`](../decisions/ADR-0072-contextual-interactions-as-capability-derived-commands.md)
  - [`ADR-0076`](../decisions/ADR-0076-real-time-exploration-with-actor-scoped-execution-and-atomic-encounter-transition.md)
- 상위 문서:
  - [`Session Play Mode, Context, Overlay와 Transition 계약`](session-play-mode-context-overlay-and-transition-contract.md)
  - [`Runtime Navigation 계약`](runtime-navigation-path-planning-and-movement-execution-contract.md)
  - [`Selection Runtime 계약`](selection-targeting-preview-and-frozen-binding-runtime-contract.md)
  - [`Interaction Capability 계약`](interaction-capability-contextual-command-and-adjudication-contract.md)
  - [`Visibility, Knowledge와 Detection Runtime 계약`](visibility-knowledge-detection-and-hover-information-runtime-contract.md)
  - [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)

## 1. 목적

이 문서는 Exploration Base Play Mode에서 여러 플레이어가 동시에 이동·상호작용·공격·주문·탐색을 수행할 때의 권위 실행과 Encounter 전환 경계를 정의한다.

```text
Player Input
→ Exploration Intent
→ Actor-scoped Command Policy
→ Movement 또는 RuleExecution
→ 실시간 Event·Hazard·Detection
→ Commit
```

Exploration은 턴과 Action Opportunity를 사용하지 않지만 무제한 동시 실행 상태도 아니다. Actor별 실행 충돌, 자원 예약, 이동 중단과 위험 사건은 서버가 조정한다.

## 2. 책임 경계

Exploration Runtime이 소유하는 것:

- Exploration Base Mode의 실시간 Command 허용 정책
- Actor별 Movement·Action 실행 충돌 조정
- 클릭 이동과 WASD 이동의 입력 전환
- 이동 중 상호작용·행동의 정지·접근 정책
- 실시간 위험·적대 행동에서 Encounter 전환 제안
- 전환 중 신규 Gameplay Command 차단
- Exploration 상태의 저장·재접속·복구 기준

Exploration Runtime이 직접 소유하지 않는 것:

- 경로 계산과 권위 위치 진행: Navigation Runtime
- 공격·주문·판정: Character Action, Spell, Resolution Runtime
- 문·상자·아이템 행동: Interaction Runtime
- 은신·탐지·함정 발견: Visibility·Detection Runtime
- 실제 상태 변경: RuleExecution과 Transaction
- 카메라와 VFX: Camera·Presentation Runtime

## 3. ExplorationModeState

```text
ExplorationModeState
├─ sessionId
├─ activeSceneIds[]
├─ actorExecutionStates[]
├─ activeContextBindings[]
├─ pendingEncounterProposals[]
├─ explorationClockBinding?
├─ commandPolicyRevision
└─ revision
```

```text
ActorExplorationExecutionState
├─ actorId
├─ controllerId?
├─ movementExecutionId?
├─ activeRuleExecutionId?
├─ activeInteractionExecutionId?
├─ activeLongActionId?
├─ movementInputMode
├─ actorLockSet[]
├─ pendingIntentQueue[]
└─ revision
```

Session 전체를 잠그지 않고 Actor 단위 실행 상태를 기본으로 사용한다.

## 4. 실시간 입력과 이동

지원 이동 입력:

```text
click_to_move
wasd_direct_intent
follow_command
forced_movement
teleport
```

### 클릭 이동

```text
Point Selection
→ NavigationRequest
→ Path Preview
→ E Confirm 또는 즉시 승인 정책
→ MovementExecution
```

### WASD 이동

```text
WASD Semantic Intent
→ 짧은 Horizon Navigation Intent
→ 서버 Traversal·Collision 검증
→ 권위 위치 진행
→ Client Prediction 보정
```

클라이언트는 최종 위치를 보내지 않는다. 방향·속도 의도와 입력 시퀀스만 제출한다.

### 입력 방식 전환

새 이동 의도가 들어오면 기존 자발적 이동을 안전하게 대체할 수 있다.

```text
click movement 중 WASD
→ 기존 Plan 취소 후보
→ 마지막 유효 Checkpoint 확정
→ WASD 실행 시작

WASD 중 목적지 클릭
→ 현재 짧은 Horizon 실행 종료
→ 클릭 Navigation Plan 시작
```

강제 이동, 낙하, Teleport가 활성화된 동안 자발적 이동 입력은 Queue 또는 거부한다.

## 5. Actor별 실행 슬롯

Exploration은 Actor 하나가 서로 모순되는 실행을 동시에 Commit하지 못하게 한다.

기본 슬롯:

```text
movement_slot
primary_rule_execution_slot
interaction_slot
long_action_slot
reaction_or_interrupt_slot
```

슬롯은 모든 행동을 직렬화하는 단일 Lock이 아니다. 실행 계약이 안전하다고 선언한 조합은 병행할 수 있다.

예시:

```text
이동 + Hover·Inspection
→ 허용

이동 + 간단한 공개 Ping
→ 허용

이동 + 문 열기
→ 접근 지점에서 이동 일시 정지 후 실행

이동 + 복잡한 주문 시전
→ 주문 정책에 따라 정지 또는 취소

장시간 Ritual + WASD 이동
→ 금지
```

각 Capability는 `ExplorationConcurrencyPolicy`를 제공한다.

```text
continue_movement
pause_movement
stop_movement
replace_movement
requires_stationary
custom_registered
```

## 6. 이동 중 상호작용

```text
E Interact
→ Frozen Selection 재검증
→ 접근 가능 여부 확인
→ 필요하면 Interaction Approach Plan 생성
→ 유효 거리에서 정지
→ Interaction RuleExecution
→ 성공 후 이동 재개 정책 적용
```

정책:

```text
resume_previous_destination
remain_stopped
replan_to_previous_destination
cancel_previous_movement
```

문 상태 변경으로 기존 경로가 바뀌면 Navigation Runtime이 최신 Snapshot에서 재계획한다.

바닥 아이템 줍기, 문 열기와 레버 작동은 Interaction Capability를 사용하며 Exploration Runtime이 Item이나 Object 상태를 직접 수정하지 않는다.

## 7. 탐험 중 공격·주문·2024 행동

Exploration에서도 다음은 사용할 수 있다.

- Attack
- Magic
- Search
- Study
- Utilize
- Help
- Hide
- Item Capability
- 즉흥 행동

다만 Encounter Action·Bonus Action·Reaction Ledger는 사용하지 않는다.

각 Capability는 Exploration 사용 정책을 선언한다.

```text
allowed_realtime
allowed_with_stationary_requirement
allowed_as_long_action
requires_encounter
requires_dm_adjudication
prohibited
```

공격 버튼을 눌렀다는 이유만으로 즉시 Encounter를 시작하지 않는다. 공격 RuleExecution이 적대 관계·위험·순서 필요성을 발생시키면 Encounter Proposal을 만든다.

## 8. 장시간 행동

장시간 주문, 조사, 함정 해제와 환경 작업은 `LongExplorationAction`으로 유지할 수 있다.

```text
LongExplorationAction
├─ executionId
├─ actorId
├─ actionKind
├─ startLogicalTime
├─ requiredDuration
├─ progressPolicy
├─ concentrationRequirement?
├─ movementPolicy
├─ interruptionPolicy
├─ resourceReservations[]
└─ revision
```

중단 원인 예시:

- Actor 이동
- 피해
- Concentration 상실
- 대상 상태 변경
- Scene 전환
- Encounter 전환
- DM 취소

중단 시 자원 환불 여부는 행동별 Rule 정책이 결정한다.

## 9. Hazard와 Trigger

Exploration 중 함정·환경 Trigger는 실시간으로 발생할 수 있다.

```text
Movement Checkpoint
→ Trigger Query
→ Trigger Candidate
→ 권위 재검증
→ Actor 또는 관련 Scope Freeze
→ RuleExecution
→ 결과 Commit
→ 이동 재개·중단·Encounter 전환
```

함정 발동 시 모든 플레이어를 무조건 정지하지 않는다.

Freeze Scope:

```text
actor_only
affected_group
local_scene_region
session_wide
```

숨겨진 Trigger Identity는 플레이어 Client에 미리 전달하지 않는다.

## 10. 동시 실행과 경쟁 상태

여러 플레이어가 동시에 행동할 수 있다.

예시:

- 같은 바닥 아이템 줍기
- 같은 문 열기
- 좁은 통로 진입
- 같은 대상 공격
- 같은 컨테이너 이동

처리는 기존 Reservation·Revision·Transaction 규칙을 따른다.

```text
Command Ordering
→ 필요한 권위 Store 예약
→ 최신 Revision 재검증
→ 하나의 Commit만 성공
→ 나머지는 최신 결과 또는 멱등 성공 반환
```

Exploration Runtime은 결과를 임의로 선착순 Client 시간으로 결정하지 않는다.

## 11. Context

Exploration Context 예시:

```text
free_exploration
stealth
travel
hazard
social_adjudication
rest_preparation
underwater
mounted
```

Context는 다음에 기여할 수 있다.

- 허용 Capability와 자동화 수준
- 이동 속도·형태
- Detection·Noise 정책
- Hover·Selection 강조
- Encounter Proposal 민감도

Context 자체가 HP, 위치, Knowledge 또는 Item 상태를 직접 바꾸지 않는다.

## 12. Exploration → Encounter 전환

전환은 하나의 원자적 경계로 처리한다.

```text
EncounterTriggerCandidate
→ EncounterProposal
→ 참가자·진영·인지 상태 Snapshot
→ 관련 Actor 신규 Command Gate
→ 진행 중 실행 분류
→ Initiative Roll·Reveal
→ EncounterSession Commit
→ Encounter Base Mode 활성
```

### 진행 중 실행 분류

```text
complete_before_transition
freeze_and_resume_in_encounter
convert_to_encounter_execution
cancel_with_rule_policy
commit_partial_checkpoint
```

예시:

- 이미 Commit된 문 열기: 유지
- 이동 중인 Actor: 마지막 권위 Checkpoint에서 정지
- 날아가는 투사체: RuleExecution으로 계속 해결 가능
- 장시간 Ritual: Encounter 규칙에 맞춰 유지 또는 중단
- 아직 확정하지 않은 Selection: 취소 또는 Encounter Context로 재검증

전환 중 관련 Actor에게 새 이동·공격 Command를 허용하지 않는다.

## 13. Encounter Proposal 원인

```text
hostile_action
hostile_detection
hazard_requires_order
multiple_conflicting_reactions
dm_start
objective_timer
custom_registered
```

시스템은 Encounter 시작을 제안할 수 있지만, 일반 적대 상황의 최종 시작 정책은 Campaign 설정과 DM 권위를 따른다.

긴급 Trigger처럼 순서를 즉시 확정해야 하는 경우에도 참가자와 초기 상태를 기록하고 DM에게 사후 Override·Rollback 경로를 제공한다.

## 14. Encounter 종료 후 복귀

```text
Encounter 종료 Commit
→ Actor별 미완료 실행 정리
→ Exploration Command Policy 복원
→ 유효한 장시간 행동 재평가
→ Follow·Camera·Selection Context 복원 후보
```

Encounter 종료는 Actor 위치, 문 상태, 바닥 Item, Effect와 Knowledge를 초기화하지 않는다.

전투 전 클릭 목적지를 자동 재개하지 않는다. 사용자가 명시적으로 재개하거나 정책이 안전하다고 선언한 경우에만 새 NavigationRequest를 만든다.

## 15. 역할 경계

### PLAYER_ONLY

- 제어 중인 Actor의 WASD·클릭 이동
- 공개된 Exploration Capability 실행
- 공개 대상 상호작용
- 자신의 장시간 행동 시작·취소
- Encounter 제안에 필요한 선택 제출

### DM_ONLY

- 강제 이동·정지·위치 수정
- 숨은 Trigger 실행·공개
- Encounter 시작·참가자·진영 Override
- 진행 중 실행의 강제 완료·취소
- Exploration Context 강제 변경
- 거리·조건·비용 무시 Command

DM이 Actor를 정상 규칙으로 조작할 때는 Player Command 경로를 사용한다.

### SHARED

- 공개 Hover·Inspection
- Ping과 Measurement
- Character Sheet·Inventory·Journal 열람
- 공개 Dice와 결과 확인

### SYSTEM_ONLY

- Actor별 실행 슬롯과 Lock 조정
- Movement·RuleExecution 충돌 해소
- Trigger Query와 Freeze Scope
- Encounter Proposal 생성
- 전환 Gate와 Snapshot
- 저장·재접속·복구

## 16. 저장·재접속·복구

저장 대상:

- Base Mode와 Context
- Actor별 권위 위치와 이동 Checkpoint
- 진행 중 LongExplorationAction
- 저장 가능한 RuleExecution
- Resource Reservation
- Pending Encounter Proposal
- 전환 Gate 상태

일반 WASD 키 상태, Hover, 경로 Preview와 Camera Transform은 권위 저장 대상이 아니다.

재접속 시:

```text
Snapshot Sync
→ ActorExecutionState 복원
→ 진행 중 실행 재검증
→ 유효한 Projection 준비
→ 입력 허용
```

복구할 수 없는 자발적 이동은 마지막 Checkpoint에서 안전하게 종료한다.

## 17. 성능과 진단

- WASD Intent마다 전체 경로를 새로 계산하지 않는다.
- Actor 주변 짧은 Horizon과 지역 무효화를 사용한다.
- Trigger·Detection Query는 공간 인덱스로 후보를 제한한다.
- Actor Lock 대기 시간과 Navigation Replan 빈도를 기록한다.
- Encounter 전환 중 거부된 Command와 이유를 Trace한다.
- Client Prediction 오차와 보정 거리를 측정한다.

성능 측정 없이 입력 주기나 Queue 상한을 고정하지 않는다.

## 18. 금지 사항

- Exploration을 Action Economy가 없는 무제한 병렬 실행으로 구현하지 않는다.
- Client CFrame을 권위 위치로 수락하지 않는다.
- 공격 입력 즉시 모든 상황에서 Encounter를 강제 시작하지 않는다.
- 함정 발동 시 이유 없이 세션 전체를 정지하지 않는다.
- 진행 중 이동과 Encounter 시작을 서로 다른 비원자적 단계로 Commit하지 않는다.
- Exploration 전용 코드에서 공격·주문·Item 상태를 직접 변경하지 않는다.
- 전투 종료 후 이전 WASD 입력이나 경로를 자동 재생하지 않는다.
