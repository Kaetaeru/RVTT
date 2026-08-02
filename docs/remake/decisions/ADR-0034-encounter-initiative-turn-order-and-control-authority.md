# ADR-0034: 인카운터·주도권·턴 순서와 제어권은 서버 권위 EncounterSession으로 관리한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0026`](ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0032`](ADR-0032-monster-npc-statblocks-and-safe-ingame-json-import.md)
  - [`ADR-0033`](ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../28-encounter-initiative-turn-and-control-authority-model.md)

## 배경

RVTT의 전투는 단순히 주도권 숫자를 정렬하는 기능이 아니다.

- 탐험 중인 장면을 그대로 유지한 채 전투로 진입해야 한다.
- 일부 Actor만 전투에 참여하고, 나중에 합류하거나 이탈할 수 있다.
- 이니셔티브 결과는 주사위 연출이 공개된 뒤에만 턴 순서에 반영되어야 한다.
- 플레이어 캐릭터, 동료 NPC, 적 NPC와 소환체는 서로 다른 제어권 정책을 가진다.
- DM은 여러 NPC를 직접 조종하거나 일부를 자동 행동에 맡길 수 있어야 한다.
- 전설적 행동, 준비 행동, 반응과 턴 외 행동이 현재 턴 소유자와 별개로 실행될 수 있어야 한다.
- 전투 종료는 마지막 적의 HP가 0이 되는 순간으로 고정할 수 없고 DM 판정과 장면 목적을 포함해야 한다.

## 결정

모든 전투는 서버 권위 `EncounterSession`으로 관리한다.

```text
탐험 장면
→ EncounterProposal
→ 참가자와 진영 검증
→ InitiativeRollBatch
→ 주사위 연출과 결과 공개
→ InitiativeOrder 확정
→ EncounterSession 활성화
→ 턴·라운드 진행
→ 종료 후보
→ DM 또는 정책 확정
→ 탐험 상태로 복귀
```

## EncounterSession

```text
EncounterSession
├─ encounterId
├─ sceneId
├─ state
├─ participantBindings[]
├─ factionBindings[]
├─ initiativeBatchId?
├─ initiativeEntries[]
├─ roundState
├─ activeTurnState?
├─ pendingOpportunities[]
├─ controlAssignments[]
├─ objectiveState?
├─ endCandidate?
├─ rulesetSnapshot
└─ revision
```

상태:

```text
proposed
collecting_participants
rolling_initiative
awaiting_reveal
ordering
active
paused
ending
ended
cancelled
```

## 이니셔티브 결과 확정

이니셔티브는 참가자마다 즉시 턴 순서에 삽입하지 않는다.

```text
참가자 스냅샷
→ 서버 SealedRollResult 생성
→ 클라이언트 주사위 연출
→ 필요한 결과 공개
→ 수정치와 동률 정책 적용
→ InitiativeOrder Commit
```

배치 전체가 확정되기 전까지 임시 턴 순서를 권위 상태로 노출하지 않는다.

## InitiativeEntry

```text
InitiativeEntry
├─ entryId
├─ participantActorIds[]
├─ rollRecordId?
├─ total
├─ tieBreakValues[]
├─ orderKey
├─ turnPolicy
├─ visibilityPolicy
└─ revision
```

개별 Actor 턴, 동일 종류 몬스터 묶음 턴, 소환체 공유 턴과 DM이 만든 커스텀 그룹을 지원한다.

## 턴과 라운드

```text
RoundState
├─ roundNumber
├─ sequenceRevision
└─ completedEntryIds[]

ActiveTurnState
├─ turnId
├─ initiativeEntryId
├─ actingActorIds[]
├─ phase
├─ actionEconomyStates[]
├─ movementStates[]
├─ openedOpportunities[]
└─ revision
```

턴 시작·종료는 타입 있는 `RuleEvent`를 방출하고, 상태 만료·재충전·죽음 내성·전설적 행동 기회가 이를 구독한다.

## 제어권

Actor의 소유권, 표시 권한과 현재 조작 권한을 분리한다.

```text
ActorOwnership
≠ ControlAssignment
≠ InformationVisibility
```

```text
ControlAssignment
├─ actorId
├─ controllerKind
├─ controllerUserId?
├─ controllerGroupId?
├─ scope
├─ startCondition
├─ endCondition
├─ fallbackController
└─ revision
```

`controllerKind`:

```text
player
DM
delegated_player
server_automation
shared_prompt
uncontrolled
```

DM은 NPC를 직접 조종하거나 특정 플레이어에게 임시 위임하거나 서버 자동 행동에 맡길 수 있다.

## NPC 자동 행동

자동화는 자유 코드를 실행하지 않는다.

```text
BehaviorProfile
→ 현재 ActionCapability 후보 조회
→ 제한된 의사결정 정책
→ 서버 검증 가능한 ActionIntent 생성
→ 일반 행동 실행 엔진
```

자동화가 선택한 행동도 플레이어나 DM이 선택한 행동과 동일한 검증·주사위·EffectRecipe 절차를 사용한다.

## 턴 외 행동

반응, 전설적 행동, 준비 행동과 강제 행동은 별도 임시 턴을 만들지 않는다.

```text
현재 턴 진행
→ TimingWindow 또는 ActionOpportunity 생성
→ 적격 Actor와 Controller에게 제안
→ 선택 또는 타임아웃
→ 독립 ActionExecution
→ 원래 턴으로 복귀
```

중첩 깊이, 우선순위, 재검증과 순환 방지는 ADR-0025 규칙을 따른다.

## 참가자 합류와 이탈

전투 중 Actor가 합류하면 `JoinEncounterTransaction`으로 처리한다.

- 기존 이니셔티브 결과 사용
- 새 이니셔티브 굴림
- 특정 순서에 삽입
- 기존 그룹에 합류

중 하나를 규칙 세트와 DM이 선택한다.

이탈은 Actor를 삭제하지 않고 참가 상태를 `withdrawn`, `escaped`, `removed`, `defeated` 등으로 변경한다.

## 전투 종료

종료 후보:

- 적대 세력 전멸 또는 무력화
- 한쪽의 도주·항복
- 목표 달성 또는 실패
- 장면 전환
- DM 수동 종료
- 규칙 정의 종료 조건

종료 후보가 생겨도 즉시 EncounterSession을 삭제하지 않는다.

```text
EndCandidate 생성
→ 미해결 실행·반응·동시 효과 정리
→ DM 또는 자동 정책 확인
→ EncounterEndTransaction
→ 턴 상태 종료
→ 전투 전용 효과와 UI 정리
→ 탐험 상태 복귀
```

활성 지속 효과, HP, 위치, 시체, 소환체와 장면 오브젝트는 각각의 수명주기 정책에 따라 유지하거나 종료한다.

## 서버 권한

- 서버가 참가자, 진영, 이니셔티브, 현재 턴, 행동 경제와 제어권을 확정한다.
- 클라이언트는 자신의 턴 시작, NPC 제어권과 턴 종료를 독자적으로 확정하지 않는다.
- 모든 명령은 `encounterId`, `turnId`, Actor revision과 ControlAssignment revision을 포함한다.
- 늦게 도착한 명령은 현재 상태와 맞지 않으면 거부한다.
- DM 강제 턴 이동, 주도권 수정과 제어권 이전은 감사 로그를 남긴다.

## 결과

- 주사위 연출과 실제 이니셔티브 순서가 어긋나지 않는다.
- 탐험 장면을 복제하지 않고 같은 Actor 상태에서 전투를 시작·종료할 수 있다.
- 플레이어, DM, 위임 플레이어와 자동화의 NPC 제어권을 명확히 분리할 수 있다.
- 반응과 전설적 행동을 가짜 턴 없이 기존 TimingWindow에 연결할 수 있다.
- 전투 중 합류·도주·항복·목표 종료를 안정적으로 처리할 수 있다.