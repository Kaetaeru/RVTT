# 28. 인카운터·주도권·턴과 제어권 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`19. 트리거와 다른 턴 실행 모델`](../../../rules/feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`20. 능동형 특성과 행동 내부 실행 모델`](../../../rules/active-feature-and-action-container-execution-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`26. 몬스터·NPC 스탯블록과 JSON 가져오기 모델`](../../../character/monster-npc-statblock-and-ingame-json-import-model.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](../../../../dice-roll-presentation-and-resolution-gating-model.md)
  - [`ADR-0034`](../../../../decisions/ADR-0034-encounter-initiative-turn-order-and-control-authority.md)

## 1. 문서 목적

이 문서는 탐험 중인 장면을 전투 인카운터로 전환하고, 이니셔티브 주사위 결과 공개 이후 턴 순서를 확정하며, 플레이어·DM·자동화 사이의 Actor 제어권을 안전하게 관리하는 구조를 정의한다.

대상:

- 전투 시작 제안과 참가자 선택
- 진영과 적대 관계
- 이니셔티브 배치 굴림
- 개별·그룹 이니셔티브
- 동률 해결
- 턴과 라운드
- 행동 경제 초기화
- 반응·준비 행동·전설적 행동
- 전투 중 합류·이탈·도주·항복
- DM의 NPC 직접 제어
- 플레이어에게 NPC 임시 위임
- 서버 자동 행동
- 전투 일시정지와 강제 진행
- 종료 후보와 탐험 복귀

핵심 원칙:

```text
주사위 결과가 공개되기 전
→ 주도권 순서 미확정

주도권 배치가 확정된 후
→ 첫 턴 시작
```

```text
Actor 소유권
≠ 현재 조작 권한
≠ 정보 열람 권한
```

---

## 2. EncounterSession

```text
EncounterSession
├─ encounterId
├─ sceneId
├─ encounterDefinitionId?
├─ state
├─ participantBindings[]
├─ factionBindings[]
├─ initiativeConfiguration
├─ initiativeBatchId?
├─ initiativeEntries[]
├─ roundState?
├─ activeTurnState?
├─ opportunityStack[]
├─ controlAssignments[]
├─ objectiveState?
├─ endCandidate?
├─ auditMetadata
├─ rulesetSnapshot
└─ revision
```

`EncounterSession`은 장면을 복제하지 않는다. Actor의 위치, HP, 상태, 장비와 지속 효과는 기존 장면 상태를 그대로 사용한다.

---

## 3. 상태 기계

```text
proposed
→ collecting_participants
→ rolling_initiative
→ awaiting_reveal
→ ordering
→ active
→ ending
→ ended
```

보조 상태:

```text
paused
cancelled
failed_to_start
recovery_required
```

### proposed

DM 또는 규칙 트리거가 전투 시작을 제안한다.

### collecting_participants

참가 Actor, 진영, 숨김 여부와 이니셔티브 방식을 확정한다.

### rolling_initiative

서버가 모든 필요한 굴림을 생성하고 봉인한다.

### awaiting_reveal

클라이언트 주사위 연출과 공개 게이트를 기다린다.

### ordering

공개된 결과, 수정치와 동률 정책으로 최종 순서를 계산한다.

### active

턴과 라운드가 실제로 진행된다.

### ending

미해결 실행과 반응을 정리하고 종료 결과를 확정한다.

---

## 4. EncounterProposal

```text
EncounterProposal
├─ sceneId
├─ proposedBy
├─ participantCandidates[]
├─ factionSuggestions[]
├─ surpriseOrAwarenessInputs[]
├─ initiativeMode
├─ objectiveProposal?
├─ visibilityPolicy
└─ revisionSet
```

전투 시작 버튼을 눌렀다는 이유만으로 장면의 모든 토큰을 참가자로 넣지 않는다.

DM UI는 다음 후보를 보여준다.

- 현재 선택된 Actor
- 특정 영역 안 Actor
- 적대 관계가 활성화된 Actor
- 사전에 정의된 인카운터 그룹
- 숨겨진 증원 후보

DM은 시작 전에 참가자와 진영을 수정할 수 있다.

---

## 5. ParticipantBinding

```text
ParticipantBinding
├─ actorId
├─ participantState
├─ factionId
├─ initiativeEntryPolicy
├─ controlAssignmentId
├─ awarenessState
├─ visibilityPolicy
├─ joinedAtRound?
├─ leftAtRound?
└─ revision
```

`participantState`:

```text
pending
active
defeated
unconscious
withdrawn
escaped
surrendered
removed
hidden_reserve
```

HP가 0이 되더라도 참가자 기록을 즉시 삭제하지 않는다.

---

## 6. 진영과 적대 관계

```text
FactionBinding
├─ factionId
├─ memberActorIds[]
├─ relationshipMatrix
├─ sharedVisionPolicy?
├─ controlGroupId?
└─ revision
```

진영은 단순 `ally/enemy` 불리언이 아니다.

```text
friendly
neutral
hostile
unknown
conditionally_hostile
```

정신 지배, 배신, 임시 동맹과 제3세력을 표현할 수 있어야 한다.

진영 변경은 대상 적격성, 기회 공격과 자동화 판단 캐시를 무효화한다.

---

## 7. InitiativeRollBatch

```text
InitiativeRollBatch
├─ batchId
├─ encounterId
├─ rollRequests[]
├─ presentationSessions[]
├─ revealedRollRecords[]
├─ requiredRevealPolicy
├─ tieBreakPolicyId
├─ state
└─ revision
```

흐름:

```text
1. 참가자와 InitiativeEntry 후보를 고정
2. 각 후보의 이니셔티브 수정치 스냅샷 계산
3. 서버 RNG로 SealedRollResult 생성
4. 클라이언트 연출 시작
5. 공개 게이트 충족
6. RollRecord 공개
7. 모든 필수 결과가 공개되면 순서 계산
8. InitiativeOrder Commit
```

결과가 아직 공개되지 않은 참가자는 이니셔티브 바에 임시 숫자로 삽입하지 않는다.

---

## 8. 개별·그룹 이니셔티브

```text
InitiativeEntryPolicy
├─ individual
├─ shared_by_definition
├─ shared_by_control_group
├─ shared_by_faction_group
├─ follow_owner_turn
├─ fixed_position
└─ custom_registered
```

### individual

Actor마다 별도 굴림과 턴을 가진다.

### shared_by_definition

동일 종류 일반 몬스터 여러 마리가 하나의 이니셔티브를 공유한다.

### shared_by_control_group

DM이 한 번에 조작할 NPC 묶음이 하나의 엔트리를 공유한다.

### follow_owner_turn

소환체나 동료가 소유자의 턴과 연결된다.

그룹 엔트리는 여러 Actor를 포함하지만 각 Actor의 HP, 행동 경제와 상태는 별도로 유지할 수 있다.

---

## 9. InitiativeEntry

```text
InitiativeEntry
├─ entryId
├─ participantActorIds[]
├─ rollRecordId?
├─ baseRoll?
├─ modifierBreakdown
├─ total
├─ tieBreakValues[]
├─ orderKey
├─ turnPolicy
├─ controllerSummary
├─ visibilityPolicy
└─ revision
```

최종 정렬은 단순 숫자 내림차순 이후 임의 순서가 아니다.

```text
initiative total
→ ruleset tie-break values
→ 사용자 선택이 필요한 동률 창
→ 안정적 final order key
```

동률 선택이 필요한 경우 순서 확정을 보류하고 DM 또는 해당 플레이어에게 선택 창을 연다.

---

## 10. 이니셔티브 연출

플레이어 캐릭터:

```text
개인 카메라 중앙에 큰 d20
→ 결과 공개
→ 자신의 InitiativeEntry 카드 생성
```

주요 NPC 또는 보스:

```text
DM 화면 또는 공개 대상 화면에 강조 주사위
```

일반 몬스터 묶음:

```text
compact batch presentation
→ 그룹 결과 하나 공개
```

모든 필수 결과 공개 후 이니셔티브 바가 한 번에 정렬된다.

```text
주사위 연출 중
→ 전투 UI 대기 상태

최종 결과 공개
→ 카드들이 정렬 위치로 이동
→ 첫 턴 강조
```

---

## 11. RoundState와 TurnState

```text
RoundState
├─ roundNumber
├─ startedAtEventId
├─ initiativeSequenceRevision
├─ completedEntryIds[]
└─ revision
```

```text
ActiveTurnState
├─ turnId
├─ roundNumber
├─ initiativeEntryId
├─ actingActorIds[]
├─ phase
├─ actionEconomyStates[]
├─ movementBudgetStates[]
├─ turnScopedUsageStates[]
├─ pendingExecutions[]
├─ pendingOpportunities[]
└─ revision
```

`phase`:

```text
starting
awaiting_controller
acting
resolving
ending
completed
```

턴 시작 시:

```text
TurnStarting
→ 턴 시작 효과·재충전·죽음 내성 해결
→ 행동 경제 생성
→ TurnStarted
→ controller 입력 활성화
```

턴 종료 시:

```text
EndTurnRequested
→ 미해결 실행 확인
→ 종료 전 TimingWindow
→ 턴 종료 효과 해결
→ TurnEnded
→ 다음 엔트리 선택
```

---

## 12. 행동 경제

각 행동 Actor는 기존 `ActionEconomyState`를 받는다.

```text
ActionEconomyState
├─ action opportunities
├─ bonus action opportunities
├─ reaction availability
├─ attack unit capacity
├─ object interaction opportunities
└─ turn-scoped limits
```

그룹 턴이라고 해서 모든 NPC가 하나의 행동 자원을 공유하지 않는다. 공유가 필요한 특수 인카운터만 명시적 공유 자원을 사용한다.

---

## 13. 제어권 분리

```text
ActorOwnership
→ 캐릭터 또는 Actor의 장기 소유 관계

ControlAssignment
→ 현재 누가 명령을 내릴 수 있는가

InformationVisibility
→ 누가 어떤 스탯과 비밀을 볼 수 있는가
```

세 책임을 하나의 `ownerUserId`로 합치지 않는다.

```text
ControlAssignment
├─ controlAssignmentId
├─ actorId
├─ controllerKind
├─ controllerUserId?
├─ controllerGroupId?
├─ scope
├─ allowedCommandKinds[]
├─ startCondition
├─ endCondition
├─ fallbackController
├─ issuedBy
└─ revision
```

`scope`:

```text
encounter
round
turn
single_action
until_revoked
scene
```

---

## 14. 플레이어 캐릭터

기본:

```text
controllerKind: player
controllerUserId: 해당 플레이어
fallbackController: DM
```

연결이 끊기면 정책에 따라:

- 입력 대기
- 일정 시간 후 DM에게 임시 이전
- 자동 방어 행동
- 턴 건너뛰기

중 하나를 사용한다.

DM은 강제로 제어권을 가져갈 수 있지만 감사 로그를 남긴다.

---

## 15. DM의 NPC 제어

적 NPC의 기본 제어자는 DM이다.

DM UI:

```text
현재 InitiativeEntry
├─ 조작 가능한 NPC 목록
├─ 각 NPC의 남은 행동·이동
├─ 빠른 행동 슬롯
├─ 대상 선택
├─ 턴 종료
└─ 자동 행동 위임
```

그룹 턴에서 DM은 NPC를 임의 순서로 하나씩 움직일 수 있다.

```text
고블린 A 이동·공격
→ 고블린 B 이동
→ 고블린 C 공격
→ 고블린 B 공격
```

각 Actor의 상태와 남은 행동은 독립적으로 추적한다.

---

## 16. 플레이어에게 NPC 위임

동료 NPC나 소환체를 플레이어에게 맡길 수 있다.

```text
DM
→ DelegateControlCommand
→ 특정 Actor 선택
→ 플레이어 선택
→ 범위와 종료 조건 설정
```

예시:

```text
이번 전투 동안
이번 턴만
특정 행동 하나만
DM이 회수할 때까지
```

위임받은 플레이어는 허용된 명령만 사용할 수 있고 NPC의 DM 전용 비밀 정보는 자동으로 열리지 않는다.

---

## 17. 서버 자동 행동

```text
BehaviorProfile
├─ candidateActionPolicy
├─ targetScoringPolicy
├─ movementPolicy
├─ riskPolicy
├─ resourceUsePolicy
├─ retreatPolicy
└─ decisionBudget
```

자동 행동 흐름:

```text
현재 상태 스냅샷
→ 사용 가능한 ActionCapability 조회
→ 후보 생성
→ 제한된 점수 계산
→ ActionIntent 선택
→ 서버 일반 명령 검증
→ 일반 Roll·EffectRecipe 실행
```

금지:

- 임의 Luau 실행
- 전체 Workspace 무제한 순회
- 정의되지 않은 Remote 호출
- 규칙 검증 우회
- 결과 직접 적용

DM은 자동 행동 제안을 미리보기만 하고 직접 확정하는 모드도 사용할 수 있다.

---

## 18. 반응과 턴 외 행동

반응, 준비 행동, 전설적 행동은 `ActiveTurnState`를 교체하지 않는다.

```text
RuleEvent
→ TimingWindow
→ ActionOpportunity
→ 적격 Actor와 ControlAssignment 결정
→ 사용자 또는 자동화 선택
→ 독립 ActionExecution
→ 원래 턴 재개
```

`OpportunityStack`:

```text
OpportunityFrame
├─ opportunityId
├─ parentExecutionId
├─ eligibleActors[]
├─ offeredControllers[]
├─ deadlinePolicy
├─ resolutionOrder
└─ state
```

동시에 여러 반응이 가능하면 ADR-0025의 순서·재검증 정책을 사용한다.

---

## 19. 전설적 행동

```text
TurnEnded
→ 전설적 행동 적격 보스 조회
→ 남은 전설 자원 확인
→ DM에게 ActionOpportunity 제안
→ 선택 또는 패스
→ 비용 소비와 행동 실행
→ 다음 InitiativeEntry 진행
```

여러 보스가 적격하면 규칙 세트 또는 DM 순서 선택을 사용한다.

전설적 행동 제안 때문에 일반 플레이어의 턴 종료가 영구 정지되지 않도록 제한 시간과 빠른 패스를 지원한다.

---

## 20. 준비 행동

```text
Ready Action 실행
→ 실행할 Capability와 대상 바인딩 저장
→ TriggerCapability 생성
→ 반응 자원 예약 정책 설정
```

조건 발생 시:

```text
RuleEvent
→ 준비 행동 Trigger 평가
→ 실행 여부 선택
→ 반응 소비
→ StoredExecution 재검증
→ 실행
```

조건이 발생하지 않거나 새 턴이 시작되면 정책에 따라 저장 실행을 종료한다.

---

## 21. 전투 중 합류

```text
JoinEncounterRequest
├─ actorIds[]
├─ factionId
├─ initiativeJoinPolicy
├─ controlAssignment
├─ visibilityPolicy
└─ requestedBy
```

`initiativeJoinPolicy`:

```text
roll_new
use_existing_roll
join_existing_entry
insert_before_next_round
fixed_after_entry
DM_choose_position
```

새 굴림이 필요하면 주사위 연출 후에만 순서에 삽입한다.

순서 변경 중 현재 실행 중인 턴은 취소하지 않는다.

---

## 22. 이탈·도주·항복

```text
LeaveEncounterTransaction
├─ actorId
├─ reason
├─ preserveSceneActor
├─ endTurnPolicy
├─ effectPolicy
└─ visibilityPolicy
```

이탈 사유:

```text
escaped
surrendered
removed_by_DM
scene_transition
defeated
no_longer_relevant
```

Actor는 장면에 남아 있을 수도 있으며, 전투 참가자 목록에서만 제외될 수 있다.

---

## 23. 일시정지

DM은 전투를 일시정지할 수 있다.

```text
EncounterSession.state = paused
```

일시정지 중:

- 새 행동 명령 차단
- 진행 중 연출은 안전 지점에서 정지 또는 완료
- 실제 시간 제한 일시정지
- 캠페인 게임 시간 진행 정책 적용
- 지속 효과의 전투 시간은 별도 정책 적용

일시정지는 현재 턴이나 이니셔티브를 초기화하지 않는다.

---

## 24. 강제 진행과 DM 개입

지원 명령:

```text
ForceEndTurn
MoveInitiativeEntry
SetInitiativeTotal
TransferControl
RemoveParticipant
AddParticipant
PauseEncounter
ResumeEncounter
EndEncounter
```

각 명령은:

- DM 권한 검증
- 현재 revision 검증
- 영향 미리보기
- 감사 로그
- 가능한 경우 되돌리기 정보

를 가진다.

이니셔티브 수정은 이미 진행 중인 실행을 중간 취소하지 않고 다음 안전 경계부터 적용한다.

---

## 25. 종료 후보

```text
EncounterEndCandidate
├─ reason
├─ detectedAtEventId
├─ remainingHostileParticipants[]
├─ unresolvedExecutions[]
├─ unresolvedOpportunities[]
├─ objectiveOutcome?
├─ suggestedCleanupPolicy
└─ requiresDMConfirmation
```

후보 사유:

```text
all_hostiles_defeated
all_hostiles_incapacitated
all_hostiles_fled
party_defeated
surrender
objective_completed
objective_failed
scene_transition
manual_DM
custom_registered
```

적이 모두 쓰러졌더라도 증원, 지속 위험과 목표가 남아 있으면 전투를 유지할 수 있다.

---

## 26. EncounterEndTransaction

```text
1. 새 행동 입력 차단
2. 현재 CommitGroup 완료 또는 안전 취소
3. 열린 반응 창 종료
4. 종료 시점 Trigger 해결
5. 턴·라운드 상태 종료
6. 전투 한정 Capability와 EffectInstance 정리
7. 전투 종료 회복·자원 정책 실행
8. 참가자 결과 기록
9. 탐험 UI와 제어 문맥 복구
10. EncounterRecord 확정
```

HP, 위치, 장비, 시체와 일반 지속 효과는 그대로 유지한다.

`until_end_of_encounter` 효과만 명시적으로 종료한다.

---

## 27. EncounterRecord

```text
EncounterRecord
├─ encounterId
├─ startedAtGameTime
├─ endedAtGameTime
├─ participants[]
├─ initiativeHistory[]
├─ roundCount
├─ outcome
├─ objectiveOutcome?
├─ defeatedActors[]
├─ escapedActors[]
├─ resourceSummary?
├─ DMOverrides[]
└─ auditReferences[]
```

전투 재생 전체를 영구 보존하지 않더라도 주요 결과와 DM 개입은 기록한다.

---

## 28. UI 원칙

### 전투 시작

```text
참가자 패널
→ 진영 확인
→ 이니셔티브 방식 확인
→ 전투 시작
```

### 이니셔티브 굴림

```text
주사위 연출
→ 결과 카드
→ 전체 결과 공개 후 정렬 애니메이션
```

### 현재 턴

- 현재 엔트리와 Actor 강조
- 남은 행동·이동·반응 표시
- DM 그룹 턴에서는 Actor별 사용 상태 표시
- 위임된 NPC는 제어자 배지 표시
- 열린 반응 창은 원래 턴과 분리 표시

### 종료

DM에게 종료 이유와 유지·종료될 효과 요약을 보여준 뒤 확정한다.

---

## 29. 서버 권한과 동시성

모든 전투 명령은 최소한 다음을 포함한다.

```text
encounterId
encounterRevision
turnId?
turnRevision?
actorId
actorRevision
controlAssignmentRevision
clientCommandId
```

서버는 다음을 검증한다.

- 현재 전투와 턴이 맞는가
- 요청자가 현재 제어자인가
- Actor가 아직 참가 중인가
- 행동 기회와 자원이 남아 있는가
- 같은 명령이 이미 처리되지 않았는가

중복 명령은 멱등적으로 기존 결과를 반환한다.

---

## 30. 성능

- 참가자와 진영은 인덱스로 조회한다.
- 매 프레임 전체 참가자를 검사하지 않는다.
- 턴 경계, HP 변화, 진영 변화와 장면 이탈 사건으로 종료 후보를 갱신한다.
- 이니셔티브 UI는 전체 스냅샷보다 revision 기반 델타를 사용한다.
- 자동화는 Actor별 제한된 결정 예산을 가진다.
- 숨겨진 참가자는 권한 없는 클라이언트에 동기화하지 않는다.

---

## 31. 검증 사례

### 일반 전투 시작

```text
PC 2명 + 고블린 3명
→ PC 개별 이니셔티브
→ 고블린 그룹 이니셔티브
→ 주사위 결과 공개
→ 3개 InitiativeEntry 정렬
→ 첫 턴 시작
```

### DM 그룹 턴

```text
고블린 3명 그룹 턴
→ DM이 A 공격
→ C 이동·공격
→ B 이동
→ B 공격
→ 그룹 턴 종료
```

### 플레이어에게 동료 위임

```text
DM이 동료 NPC를 플레이어에게 encounter 범위로 위임
→ 플레이어가 해당 NPC 턴 조작
→ 비밀 DM 정보는 숨김 유지
→ 전투 종료 시 제어권 DM에게 복귀
```

### 증원 합류

```text
2라운드 종료 Trigger
→ 숨겨진 증원 Actor 활성화
→ 새 이니셔티브 굴림 연출
→ 결과 공개
→ 다음 안전 경계에 순서 삽입
```

### 전설적 행동

```text
PC 턴 종료
→ 보스 전설적 행동 창
→ DM 선택
→ 행동 해결
→ 다음 InitiativeEntry 시작
```

### 전투 종료

```text
마지막 적 항복
→ EndCandidate 생성
→ 열린 반응 없음 확인
→ DM 종료 승인
→ until_end_of_encounter 효과 종료
→ 탐험 상태 복귀
```

---

## 32. 구현 완료 기준

- 주사위 공개 전 이니셔티브 순서가 확정되지 않는다.
- 개별·그룹·소유자 연동 이니셔티브가 같은 모델에서 동작한다.
- DM이 여러 NPC를 한 그룹 턴에서 자유 순서로 조종할 수 있다.
- NPC 제어를 플레이어에게 범위 제한으로 위임하고 회수할 수 있다.
- 자동 행동이 일반 행동 검증과 Roll·EffectRecipe를 우회하지 않는다.
- 반응과 전설적 행동이 현재 턴을 잃지 않고 중첩 실행된다.
- 전투 중 합류·도주·항복과 DM 강제 수정이 revision 안전하게 처리된다.
- 전투 종료 후 장면 위치, HP와 일반 지속 효과가 보존된다.
- 서버 재접속 후 EncounterSession과 현재 턴을 복원할 수 있다.