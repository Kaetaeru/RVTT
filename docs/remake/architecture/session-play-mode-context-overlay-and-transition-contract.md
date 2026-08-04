# Session Play Mode, Context, Overlay와 Transition 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - Pause Gate 기본 허용 Command 목록
  - Overlay 동시 활성 상한과 우선순위 기본표
  - Transition별 Client Ready timeout
  - Downtime 참가자 응답 timeout과 DM 강제 진행 기본값
  - Context 자동 제안 임계값
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0034`](../decisions/ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0048`](../decisions/ADR-0048-continuous-gridless-movement-and-combat-input-policy.md)
  - [`ADR-0052`](../decisions/ADR-0052-mid-session-join-observer-and-control-assignment.md)
  - [`ADR-0059`](../decisions/ADR-0059-versioned-command-event-and-projection-streams.md)
  - [`ADR-0061`](../decisions/ADR-0061-scene-streaming-interest-and-ready-activation.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0063`](../decisions/ADR-0063-manifest-chunk-snapshots-commit-journal-and-branch-recovery.md)
  - [`ADR-0070`](../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md)
- 상위 문서:
  - [`Runtime Architecture Principles`](runtime-architecture-principles.md)
  - [`Networking Command, Event와 Client Synchronization 계약`](networking-command-event-and-client-synchronization-contract.md)
  - [`Command Ordering, Logical Time와 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Persistence와 Session Recovery 모델`](persistence-and-session-recovery-model.md)
- 관련 시스템:
  - [`Scene 시스템`](../systems/scene/README.md)
  - [`Combat 시스템`](../systems/combat/README.md)
  - [`HP 0·죽음 내성·휴식·자원 회복 모델`](../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)

## 1. 목적

이 문서는 세션 진행 상태를 하나의 거대한 `mode` 열거형으로 만들지 않고 다음 네 축으로 분리한다.

```text
Base Play Mode
+ Context Set
+ Overlay Stack
+ Transitional State
```

목표:

- 탐험과 Encounter의 입력·시간·행동 경제 차이를 명확히 한다.
- Downtime과 휴식을 실시간 Scene 플레이와 분리한다.
- DM Scene Editor, Pause, Selection과 Camera Focus를 별도 게임 모드로 오인하지 않는다.
- Scene 전환, 중도 참여, 재접속과 복구 중 일반 Command를 안전하게 차단한다.
- 기능 추가 시 새로운 전역 모드를 남발하지 않는다.

## 2. 핵심 원칙

### 2.1 Base Play Mode는 하나만 활성이다

```text
exploration
encounter
downtime
```

한 Session Scope 또는 Participant Scope에는 같은 시점에 하나의 Base Play Mode만 권위적으로 활성화된다.

### 2.2 Context는 모드를 대체하지 않는다

Context는 현재 Mode의 일부 규칙·자동화·UI 강조만 조정한다.

```text
Exploration + stealth context
Encounter + chase context
Downtime + long_rest context
```

Context가 Character·Actor·Encounter 상태의 새 권위 원본이 되지 않는다.

### 2.3 Overlay는 현재 Mode 위에 겹친다

```text
Current Base Mode
+ Selection Overlay
+ DM Authoring Overlay
+ Presentation Focus Overlay
```

Overlay는 자신이 소유한 입력 Scope만 가로챈다. 관련 없는 권위 실행을 자동으로 멈추지 않는다.

### 2.4 Transitional State는 안전 Gate다

Scene Transition, Join, Reconnect, Recovery와 Build Migration 중에는 일반 Gameplay Command를 허용하지 않는다.

```text
stable mode
→ transition state
→ validation / synchronization
→ stable mode
```

### 2.5 UI 화면과 Runtime Mode를 동일시하지 않는다

Character Sheet, Inventory, Journal, Settings와 Dice Presentation은 화면 상태이지 Base Play Mode가 아니다.

## 3. Session Runtime State

```text
SessionRuntimeState
├─ sessionId
├─ authorityEpoch
├─ baseModeState
├─ contextBindings[]
├─ overlayBindings[]
├─ transitionState?
├─ pauseGateState?
├─ participantRuntimeBindings[]
├─ activeSceneBindings[]
├─ activeEncounterIds[]
├─ activeDowntimeSessionIds[]
├─ commandPolicyRevision
└─ revision
```

세션 전체와 참가자별 상태를 혼합하지 않는다. DM만 Authoring Overlay를 켤 수 있고 다른 플레이어는 Exploration을 계속할 수 있다.

## 4. Base Play Mode

### 4.1 Exploration

실시간 Scene 탐색과 일반 상호작용의 기본 모드다.

```text
ExplorationModeState
├─ activeSceneId
├─ explorationClockPolicy
├─ movementPolicyId
├─ interactionPolicyId
├─ activeContextIds[]
└─ revision
```

기본 특성:

- 클릭 이동과 WASD 토큰 이동 허용
- 실시간 연속 무격자 이동
- 문, 레버, 컨테이너와 Item Presence 상호작용
- Action Economy 없이 가능한 일반 행동
- 규칙상 비용이 있는 행동은 Capability가 별도로 선언
- Encounter 시작 후보를 만들 수 있음

탐험 중에도 공격, 주문, 판정과 Effect Runtime은 사용할 수 있다. 다만 Encounter Action Opportunity가 없는 상태에서 실행 가능한 Capability만 허용한다.

### 4.2 Encounter

턴, 순서, Action Opportunity와 Reaction Window가 필요한 상황이다.

```text
EncounterModeBinding
├─ encounterId
├─ encounterKind
├─ participantIds[]
├─ nonParticipantPolicy
├─ sceneScope
└─ revision
```

`encounterKind`:

```text
combat
chase
hazard
escape
timed_objective
custom_registered
```

Encounter는 Scene 상태를 복제하지 않는다. Actor 위치, HP, Item과 Effect는 기존 권위 Store를 사용한다.

전투 중 토큰 WASD 이동은 금지하고 Path Preview와 Movement Budget을 사용하는 Command만 허용한다.

Encounter에 참여하지 않는 같은 Scene의 Actor와 플레이어 정책은 명시한다.

```text
observe_only
continue_limited_exploration
join_candidate
blocked_by_dm
```

### 4.3 Downtime

실시간 Scene 입력보다 Campaign Time, Character Source·State와 장기 Transaction이 중심인 모드다.

```text
DowntimeModeState
├─ downtimeSessionId
├─ downtimeKind
├─ participantStates[]
├─ timeAdvancePlan
├─ pendingChoices[]
├─ pendingBuildChanges[]
├─ completionPlan
└─ revision
```

초기 종류:

```text
short_rest
long_rest
level_up
spell_preparation
spellbook_work
crafting
training
travel_resolution
custom_registered
```

Downtime은 별도 3D 월드를 요구하지 않는다. 현재 Scene을 배경으로 UI를 열 수 있지만 권위 진행은 DowntimeSession이 소유한다.

Character Source 변경은 Candidate Build, State Migration과 원자적 교체를 사용한다.

## 5. Mode 전환

### Exploration → Encounter

```text
Encounter Proposal
→ 참가자·진영·인식 상태 확정
→ Initiative Roll and Reveal
→ Encounter State Commit
→ Encounter Mode 활성
```

주사위 공개 전에 Turn Order를 활성화하지 않는다.

### Encounter → Exploration

```text
End Candidate
→ 열린 RuleExecution·Reaction 정리
→ 종료 결과 Commit
→ Encounter Snapshot 확정
→ Encounter Overlay 제거
→ Exploration 복귀
```

전투 종료가 Actor, Effect와 바닥 Item을 초기화하지 않는다.

### Exploration / Encounter → Downtime

기본적으로 활성 적대 Encounter가 있으면 Downtime 시작을 차단한다. DM Override 또는 규칙 예외는 감사 기록을 남긴다.

```text
Downtime Proposal
→ 참가자와 적격성 확인
→ 진행 중 실행 정리
→ DowntimeSession 시작
```

### Downtime → Exploration

```text
필수 시간 충족
→ Recovery / Build / Activity 결과 후보
→ 선택 완료
→ Atomic Completion Commit
→ Exploration 복귀
```

## 6. Context

Context는 겹칠 수 있는 타입 있는 규칙 힌트다.

```text
ContextBinding
├─ contextId
├─ contextKind
├─ scope
├─ source
├─ policyContributions[]
├─ presentationHints[]
├─ startedAtLogicalTime
├─ endConditions[]
└─ revision
```

초기 Context:

```text
stealth
travel
hazard
social_adjudication
rest_preparation
chase
underwater
mounted
custom_registered
```

### Context가 할 수 있는 것

- Perception·Noise·Stealth 정책 기여
- 사용 가능한 Capability Filter 기여
- Selection 후보와 Preview 힌트 조정
- Camera와 UI Presentation Profile 제안
- 자동화 수준 제안
- Encounter Proposal 후보 생성

### Context가 할 수 없는 것

- HP, Item, Effect와 Actor 위치를 직접 수정
- Action Opportunity를 Transaction 없이 생성
- 다른 Mode로 조용히 전환
- 권한 없는 정보를 Client에 공개

## 7. Overlay

```text
OverlayBinding
├─ overlayId
├─ overlayKind
├─ ownerScope
├─ inputCaptureScope
├─ commandAllowanceProfile
├─ stackingPriority
├─ closePolicy
├─ persistencePolicy
└─ revision
```

초기 Overlay:

```text
selection
dm_authoring
pause
presentation_focus
rollback_review
journal_editor
character_sheet
inventory
system_prompt
custom_registered
```

### 7.1 Selection Overlay

Selection Session의 입력과 Preview를 소유한다. Exploration과 Encounter의 검증 정책은 각각 유지한다.

### 7.2 DM Authoring Overlay

`DM_ONLY`다.

- Scene Source Authoring
- Runtime Quick Edit
- Fog 편집
- 숨은 Object 공개
- 임시 Token·Obstacle 배치

Scene Source 편집과 Runtime Quick Edit를 같은 Commit으로 섞지 않는다.

DM Authoring Overlay가 켜져 있어도 다른 참가자의 Base Mode는 바뀌지 않는다.

### 7.3 Pause Overlay와 Pause Gate

Pause는 Base Mode가 아니다.

```text
Current Mode
+ PauseGateState
```

Pause Gate는 Command 종류별로 허용 여부를 선언한다.

허용 후보:

- Character Sheet·Journal 열람
- 공개 정보 확인
- DM Resume·Recovery 명령
- 설정 변경

차단 후보:

- Movement
- RuleExecution 시작
- Item Transfer
- Turn 종료
- Scene Interaction

열린 Pending Execution과 Reservation을 즉시 삭제하지 않는다.

### 7.4 Presentation Focus Overlay

Dice, Spell, Reaction과 DM Camera Focus를 위한 Client Presentation 상태다. 권위 결과를 결정하지 않는다.

### 7.5 Rollback Review Overlay

DM이 Checkpoint와 Branch 후보를 검토하는 UI다. 확정 전에는 현재 Authority Branch를 바꾸지 않는다.

## 8. Transitional State

```text
TransitionState
├─ transitionId
├─ transitionKind
├─ sourceStableState
├─ targetStableState?
├─ participantStates[]
├─ requiredReadyConditions[]
├─ timeoutPolicy
├─ failurePolicy
└─ revision
```

초기 종류:

```text
scene_transition
joining
reconnecting
snapshot_sync
recovery
rollback_commit
build_migration
server_shutdown
custom_registered
```

### 8.1 Scene Transition

Target Scene의 Entry Essential과 Controlled Actor Presentation이 준비되기 전 Gameplay Command를 허용하지 않는다.

### 8.2 Join·Reconnect

```text
connected
→ authority handshake
→ snapshot sync
→ projection ready
→ presentation ready
→ active participant
```

Encounter 도중 합류하면 현재 Encounter, Turn, Opportunity와 공개 정보가 모두 동기화된 뒤 조작을 허용한다.

### 8.3 Recovery

Manifest·Chunk Snapshot, Commit Journal과 Pending Execution 복구가 끝나기 전 일반 입력을 차단한다.

### 8.4 Rollback Commit

Rollback Review와 다르다.

```text
Checkpoint 선택
→ 새 Branch 생성
→ 새 AuthorityEpoch
→ State 복원
→ Full Resync
→ Stable Mode 복귀
```

### 8.5 Build Migration

새 Compiled Build와 State Migration이 하나의 Authority Transaction으로 확정될 때까지 기존 Build를 유지하거나 안전 Gate를 활성화한다.

## 9. Command Policy Resolution

Command 허용 여부는 단일 `mode == combat` 검사로 결정하지 않는다.

```text
Session Role
+ Control Assignment
+ Base Mode
+ Context Contributions
+ Overlay Capture
+ Pause Gate
+ Transition Gate
+ Capability
→ EffectiveCommandPolicy
```

평가 우선순위:

1. Transitional State hard gate
2. Role·Permission
3. Pause Gate
4. Overlay input capture
5. Base Mode policy
6. Context contribution
7. Capability와 현재 State

Client는 표시용 결과만 사용하고 서버가 같은 정책을 다시 계산한다.

## 10. 역할 구분

### PLAYER_ONLY

- 제어 Actor의 Exploration 이동
- 자신의 Turn Action과 Movement 확정
- Downtime 참가·선택 응답
- Selection Overlay 조작
- 자신의 Sheet·Inventory 열람과 허용된 수정

### DM_ONLY

- Encounter 시작·종료·참가자 수정
- Downtime 강제 시작·완료·중단
- DM Authoring Overlay
- Pause·Resume
- Rollback Review와 Commit
- Mode·Context·Overlay Override
- 숨은 Transition 진단과 실패 복구

### SHARED

- 공개된 현재 Mode·Turn·Downtime 상태 확인
- Journal·Character Sheet·공개 Inventory 열람
- 공개 Roll·Effect·Area와 Session 상태 확인

### SYSTEM_ONLY

- Command Policy Resolution
- Context 자동 제안
- Overlay Stack 조정
- Transition Ready Gate
- Snapshot Sync와 Recovery
- AuthorityEpoch·Revision 검증

## 11. Persistence와 Rollback

저장 대상:

- 현재 Base Mode와 Mode별 권위 ID
- Context Binding과 종료 조건
- 권위에 영향을 주는 Overlay 상태
- Pause Gate
- Transitional State 진행도
- Encounter·Downtime Session 참조
- Participant Ready·Control Binding
- Revision과 AuthorityEpoch

저장하지 않는 것:

- 단순 Window 위치
- Hover·Highlight
- Camera Tween
- 임시 Preview Mesh
- 로컬 메뉴 열림 상태

Presentation 전용 Overlay는 필요할 경우 복구하지 않고 현재 권위 상태에서 다시 생성한다.

Rollback은 Base Mode, Encounter·Downtime, Context와 권위 Overlay를 선택한 Checkpoint 상태로 복원한다. 일반 UI 창 상태는 복원하지 않는다.

## 12. 실패 코드 예시

```text
BASE_MODE_CONFLICT
MODE_TRANSITION_NOT_ALLOWED
ACTIVE_ENCOUNTER_BLOCKS_DOWNTIME
TRANSITION_IN_PROGRESS
CLIENT_NOT_READY
COMMAND_BLOCKED_BY_PAUSE
COMMAND_CAPTURED_BY_OVERLAY
CONTEXT_REQUIREMENT_NOT_MET
OVERLAY_NOT_ALLOWED_FOR_ROLE
STALE_SESSION_MODE_REVISION
STALE_AUTHORITY_EPOCH
RECOVERY_REQUIRED
```

## 13. 성능 원칙

- Mode·Context·Overlay마다 Heartbeat Loop를 만들지 않는다.
- Command Policy는 Revision 기반 Cache를 사용할 수 있다.
- Context는 Event와 Query 결과로 갱신하고 매 Frame 전체 재평가하지 않는다.
- Overlay Presentation은 Client 로컬로 처리하되 권위 입력 Gate는 서버가 검증한다.
- Transition Ready는 참가자별 상태를 Batch로 관리한다.

## 14. 비목표

- 모든 UI 화면을 별도 Runtime Mode로 만들지 않는다.
- Cinematic을 규칙 Mode로 만들지 않는다.
- DM Scene Editor를 모든 참가자의 Gameplay Mode로 강제하지 않는다.
- Encounter 종료 시 Scene State를 초기화하지 않는다.
- Downtime을 단순 즉시 회복 버튼으로 처리하지 않는다.
- Context 문자열 비교로 권위 규칙을 직접 변경하지 않는다.
