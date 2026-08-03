# 37. 전투 턴 스냅샷 타임라인과 DM 되돌리기 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../../../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](../../dice-roll-presentation-and-resolution-gating-model.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../../encounter-initiative-turn-and-control-authority-model.md)
  - [`29. 수동 Fog of War와 선택형 Assist 모델`](../../../perception/manual-fog-of-war-and-optional-assist-model.md)
  - [`30. 시야·감각·은신·탐지 모델`](../../../perception/visibility-senses-stealth-and-detection-model.md)
  - [`31. 무설정 상호작용 프리팹과 상태 전환 모델`](../../../interaction/zero-metadata-interaction-prefab-and-state-transition-model.md)
  - [`32. 무설정 함정·비밀문·파괴 오브젝트 모델`](../../../interaction/trap-secret-door-and-destructible-object-model.md)
  - [`36. 저장·자동 저장·재접속·서버 종료·세션 복구 모델`](../../../../architecture/persistence-and-session-recovery-model.md)
  - [`ADR-0043`](../../../../decisions/ADR-0043-encounter-turn-snapshot-timeline-and-dm-rollback.md)

## 1. 문서 목적

이 문서는 활성 전투의 모든 턴 경계를 복구 가능한 타임라인으로 남기고, DM이 전투를 중단하지 않은 채 과거의 안전한 턴으로 되돌리는 기능을 정의한다.

해결해야 하는 상황:

- DM이나 플레이어가 규칙을 잘못 적용함
- 잘못된 Actor, 대상, 주문 슬롯이나 Feature를 선택함
- 토큰을 잘못 이동하거나 문·함정을 잘못 작동함
- 반응이나 기회 공격을 누락함
- 네트워크 지연으로 같은 행동이 중복 처리됨
- 서버가 전투 도중 종료됨
- 숨겨진 Actor, 비밀문이나 Fog가 잘못 공개됨
- DM이 판정을 번복하고 해당 턴부터 다시 진행하려 함

핵심 원칙:

```text
전투 시작부터 종료까지
→ 모든 턴 경계를 복구 가능하게 유지
→ DM이 언제든 선택
→ 현재 이력을 보존한 새 분기로 복구
```

---

## 2. 타임라인 수명주기

인카운터가 생성될 때 전투 전용 복구 타임라인을 함께 생성한다.

```text
EncounterProposal 승인
→ EncounterSession 생성
→ EncounterRollbackTimeline 생성
→ encounter_start 체크포인트
→ 주도권 진행
→ 턴별 체크포인트 누적
→ encounter_end_candidate
→ DM 종료 확인
→ encounter_end_confirmed
→ recent_encounter_archive로 동결
```

타임라인 상태:

```text
collecting
→ 활성 전투의 턴 경계를 추가하는 중

rollback_pending
→ DM이 복구 지점을 검토하는 중

restoring
→ 서버가 선택 지점으로 복구하는 중

active_after_rollback
→ 새 분기에서 전투 진행 중

frozen
→ 전투 종료 후 변경 불가 아카이브

compacted
→ 세션 종료 후 장기 저장용 압축 상태
```

활성 전투가 끝나기 전에는 어떤 턴도 목록에서 제거하지 않는다.

전투 종료 후에는 즉시 삭제하지 않는다.

```text
기본 보존
→ 현재 세션이 끝날 때까지 전체 타임라인 유지

DM이 명시적으로 닫음
→ 장기 보관용 압축 가능

최종 세션 체크포인트 확정
→ 정책에 따라 오래된 세부 델타 정리 가능
```

다만 정리 후에도 최소한 다음은 남긴다.

- 전투 시작 상태
- 각 라운드 종료 상태
- 모든 DM 복구 지점
- 전투 종료 상태
- 감사 로그

---

## 3. 체크포인트 종류

```text
EncounterTurnCheckpoint
├─ checkpointId
├─ encounterId
├─ branchId
├─ sequence
├─ checkpointType
├─ roundNumber
├─ turnOrdinal
├─ activeActorIds
├─ initiativeGroupId
├─ authorityRevision
├─ journalSequence
├─ createdAt
├─ summary
├─ stateManifest
└─ integrityHash
```

`checkpointType`:

```text
encounter_start
turn_start
turn_end
round_end
manual_turn_marker
encounter_end_candidate
encounter_end_confirmed
```

### encounter_start

참가자, 주도권 굴림과 전투 시작 상태가 확정된 직후의 기준점이다.

다음 두 시점을 혼동하지 않는다.

```text
전투 제안 직전
→ 일반 Campaign RecoveryCheckpoint

주도권과 참가자가 확정된 전투 시작
→ encounter_start
```

### turn_start

이전 턴 종료 절차와 현재 턴 시작 절차가 모두 완료되고, 현재 Actor가 첫 입력을 받을 수 있는 시점이다.

포함되는 시작 절차 예시:

- 턴 시작 지속 피해·회복
- 턴 시작 자원 회복
- 턴 시작 상태 만료
- 시작 Trigger와 반응 해결
- 행동 경제 초기화
- 이동력 초기화

시작 Trigger가 아직 해결 중이면 `turn_start`를 만들지 않는다.

### turn_end

현재 Actor의 행동이 모두 끝나고 다음이 완료된 뒤 생성한다.

- 미확정 ActionIntent 없음
- 열린 반응 창 없음
- 피해·회복·자원 CommitGroup 완료
- 턴 종료 Trigger 완료
- 종료 상태 만료 완료
- 제어권·턴 완료 상태 확정

### round_end

마지막 턴 종료 후 라운드 종료 Trigger가 모두 해결된 시점이다.

`turn_end`와 상태가 같더라도 라운드 단위 탐색과 빠른 복구를 위해 별도 마커를 둔다.

### manual_turn_marker

DM이 현재 안전 경계에 이름을 붙인 체크포인트다.

예:

```text
용의 브레스 직전
다리 붕괴 전
증원 등장 직후
보스 2단계 시작
```

미확정 행동 중에는 만들 수 없다. 시스템은 가장 가까운 다음 안전 경계에서 생성한다.

---

## 4. 턴 스냅샷에 포함되는 상태

## 4.1 EncounterState

```text
encounterId
encounterState
roundNumber
turnOrdinal
activeActorIds
activeInitiativeGroupId
initiativeOrder
completedTurnActorIds
participantRecords
joinQueue
endCandidate
```

## 4.2 ActorRuntimeState

각 참가자와 전투 중 생성된 Actor에 대해:

```text
actorId
characterOrNpcDefinitionId
worldTransform
facing
occupancyProfile
currentHp
temporaryHp
deathSaveState
conditionInstances
concentrationState
activeEffects
movementRemaining
actionEconomy
resourceState
spellSlotState
featureUseState
equipmentState
inventoryDelta
ownership
controlAssignment
participationStatus
```

`worldTransform`은 시각 Mesh의 모든 Part 위치가 아니라 Actor의 권위 Pivot과 규칙 점유 상태를 저장한다.

## 4.3 DynamicSceneState

전투 중 바뀐 동적 오브젝트만 기록한다.

```text
DoorState
LeverState
ChestState
TrapState
SecretDoorWorldState
DestructibleDurabilityState
InteractionLinkState
TemporaryHazardState
SummonedSceneObjectState
```

정적 장면 모델은 원본 SceneRevision을 참조하고 복제하지 않는다.

## 4.4 VisibilityAndKnowledgeState

```text
CurrentRevealMask delta
DetectionRelation delta
ConcealmentAttempt state
LastKnownPosition state
SecretObjectDiscovery state
```

`DiscoveryMask`처럼 캠페인 영구 탐험 기록은 기본적으로 전투 복구 범위에 포함한다. 전투 중 잘못 공개된 지형을 되돌릴 수 있어야 하기 때문이다.

다만 이미 플레이어가 화면으로 본 정보는 인간의 기억에서 제거할 수 없다. 복구 UI는 이를 명확히 경고한다.

## 4.5 ResolutionLedger

```text
sealedRollIds
committedTransactionIds
committedStepIds
spentResourceTransactionIds
createdItemTransactionIds
invalidatedBranchTransactions
idempotencyKeys
```

이 원장은 복구 후 같은 피해, 회복, 아이템 생성과 자원 소비가 두 번 적용되는 것을 막는다.

---

## 5. 저장하지 않는 상태

```text
카메라 위치와 회전
선택 중인 UI 탭
마우스 Hover
열린 툴팁
대상 지정 미리보기
아직 제출하지 않은 이동 경로
물리 주사위 위치·속도
Tween 중간값
VFX 파티클 상태
사운드 재생 위치
클라이언트 배치 고스트
```

복구 후 필요한 연출은 현재 권위 상태에서 다시 생성한다.

문이 열린 상태라면 열린 상태 모델을 즉시 구성하고, 이전 Tween의 63% 지점으로 복원하지 않는다.

---

## 6. 델타 기반 구현

DM에게는 매 턴 완전한 스냅샷처럼 보이지만 내부 저장은 다음 구조를 사용한다.

```text
EncounterBaseSnapshot
├─ encounter_start의 전체 권위 상태
└─ sceneRevision 참조

TurnDeltaJournal
├─ Checkpoint 1 이후 변경
├─ Checkpoint 2 이후 변경
└─ ...

MaterializedTurnSnapshot
├─ 라운드 종료
├─ 일정 델타 수 초과
├─ DM 수동 마커
└─ 복구 직전
```

델타는 도메인별로 분리한다.

```text
ActorDelta
EncounterDelta
ResourceDelta
InventoryDelta
DynamicObjectDelta
FogDelta
DetectionDelta
ControlDelta
ResolutionLedgerDelta
```

복구 비용이 너무 커지지 않도록 다음 조건 중 하나에서 전체 물질화 스냅샷을 만든다.

- 각 라운드 종료
- 마지막 전체 스냅샷 이후 설정된 턴 수 초과
- 델타 누적 크기 임계치 초과
- DM 수동 마커
- 서버 종료 준비

어떤 압축 정책도 활성 전투의 턴 선택 가능성을 없애서는 안 된다.

---

## 7. DM 타임라인 UI

전투 HUD의 이니셔티브 리본 근처에 DM 전용 `Encounter Timeline` 버튼을 둔다.

기본 목록:

```text
[전투 시작]
[라운드 1]
  전사 턴 시작
  전사 턴 종료
  고블린 그룹 턴 시작
  고블린 그룹 턴 종료
  마법사 턴 시작
  마법사 턴 종료
[라운드 1 종료]
[라운드 2]
  ...
```

각 항목은 다음을 표시한다.

```text
라운드·턴
Actor 초상화와 이름
시각
짧은 사건 요약
현재 분기 여부
저장 완료 여부
DM 수동 마커
```

사건 요약 예시:

```text
전사: HP 28 → 16, 넘어짐
마법사: 화염구 사용, 3레벨 슬롯 소모
고블린 2명 쓰러짐
북문 열림
숨은 도적 발견됨
```

플레이어가 볼 수 없는 정보는 DM 패널 안에서만 표시한다.

---

## 8. 차이 미리보기

체크포인트를 선택하면 현재 상태와 비교한다.

```text
RollbackDiff
├─ actorChanges
├─ encounterChanges
├─ resourceChanges
├─ inventoryChanges
├─ objectChanges
├─ visibilityChanges
├─ controlChanges
├─ invalidatedTransactions
└─ irreversibleKnowledgeWarnings
```

표시 예시:

```text
복구 대상: 라운드 2 · 마법사 턴 시작

Actor
- 전사 HP 12 → 26
- 고블린 A defeated → active
- 마법사 위치 18 ft 이전

자원
- 3레벨 주문 슬롯 1개 복구
- 격노 사용 횟수 1개 복구

장면
- 동쪽 문 open → closed
- 화염 지대 제거

정보
- 플레이어에게 공개된 비밀문은 시스템상 다시 숨겨지지만 기억은 지울 수 없음

무효화
- 굴림 8개
- 트랜잭션 14개
```

DM은 전체 세부 변경과 요약 보기를 전환할 수 있다.

---

## 9. 되돌리기 실행 상태기계

```text
idle
→ previewing
→ awaiting_confirmation
→ freezing_encounter
→ reaching_safe_boundary
→ restoring_snapshot
→ rebuilding_projections
→ resynchronizing_clients
→ resumed
```

### previewing

전투는 계속 진행할 수 있지만 선택한 체크포인트와 차이를 계산한다.

### awaiting_confirmation

DM 승인 팝업이 열리면 새 행동 접수를 일시 중지한다.

```text
E: 선택한 턴으로 복구
Q: 취소
```

### reaching_safe_boundary

현재 해결 중인 명령이 있다면 다음 정책 중 하나를 사용한다.

```text
이미 CommitGroup 확정 중
→ 원자적으로 완료 후 복구

아직 확정 전
→ 안전 취소 후 복구

주사위 결과 봉인·미공개
→ 해당 Resolution을 현재 분기에 기록하고 복구 시 무효화

주사위 결과 공개·효과 미확정
→ PendingResolution을 안전 취소하고 복구
```

DM이 애니메이션 도중 버튼을 눌러도 절반만 적용된 상태에서 복구하지 않는다.

### restoring_snapshot

```text
현재 Branch 동결
→ rollback fencing token 증가
→ 대상 MaterializedSnapshot 로드
→ 필요한 TurnDeltaJournal 재생
→ 무결성 검사
→ 새 Branch와 authorityRevision 생성
```

### rebuilding_projections

다음을 새 상태에서 다시 계산한다.

```text
DerivedValueSnapshot
CapabilitySnapshot
CharacterSheetProjection
Combat HUD Projection
Hotbar Projection
PerceptionProjection
Fog Projection
InteractionObject Presentation
```

### resynchronizing_clients

모든 클라이언트에 `FullEncounterResync`를 보낸다.

클라이언트는 다음을 폐기한다.

- 이전 revision의 대상 지정
- 이동 고스트
- 반응 선택
- 보류 중 Hotbar 입력
- 이전 HP·자원 캐시
- 이전 Actor 위치 보간

---

## 10. 분기 모델

복구는 파괴적 되감기가 아니다.

```text
Branch A
├─ Checkpoint A1
├─ Checkpoint A2
├─ Checkpoint A3
└─ Checkpoint A4

A2로 복구

Branch B
├─ base: A2
├─ Checkpoint B1
└─ Checkpoint B2
```

`activeBranchId`만 Branch B로 변경한다.

Branch A의 A3·A4는 다음 용도로 유지한다.

- DM 감사
- 잘못된 복구를 다시 원상 복구
- 오류 조사
- 향후 리플레이 도구

타임라인 UI에서는 비활성 분기를 접어서 표시한다.

---

## 11. 굴림 정책

일반 DM 복구 후에는 새 분기로 진행한다.

```text
이전 행동을 다시 선택
→ 새 ActionIntent
→ 새 resolutionId
→ 새 sealed roll
```

다음은 금지한다.

- 이전 분기의 성공 굴림만 선택해 재사용
- 실패 굴림만 다시 굴리고 성공 굴림은 유지
- 복구한 상태에서 이전 transactionId 재확정
- 플레이어가 클라이언트 캐시에 남은 결과를 제출

과거 굴림은 전투 로그의 비활성 분기 기록으로 남되 현재 규칙 상태에 영향을 주지 않는다.

정확히 같은 입력과 굴림을 재생하는 기능은 일반 DM 복구가 아니라 개발자용 결정론적 리플레이 기능으로 분리한다.

---

## 12. 전투 종료 처리

전투 종료 후보가 발생하면 다음 체크포인트를 만든다.

```text
encounter_end_candidate
```

DM이 종료를 확정하고 전투 종료 후 정리 절차가 끝나면:

```text
encounter_end_confirmed
```

을 생성한다.

그 뒤 전체 타임라인을 `recent_encounter_archive`로 동결한다.

DM은 최소한 현재 세션 동안 다음을 선택할 수 있다.

```text
종료 직전으로 복구
마지막 턴 시작으로 복구
전투 시작으로 복구
현재 종료 상태 유지
```

종료된 전투로 복구하면 새 활성 EncounterSession을 생성하는 것이 아니라 기존 Encounter의 새 Branch를 활성화하고 종료 정리로 제거된 전투 전용 상태를 복원한다.

전투 종료 뒤 획득한 전리품, 경험치와 장기 상태가 이미 다음 장면에서 사용된 경우에는 복구 영향이 커질 수 있으므로 차이 화면에서 강한 경고를 표시한다.

---

## 13. 서버 종료와 재접속

### 활성 서버 재접속

재접속 플레이어는 현재 활성 Branch와 authorityRevision을 받는다.

DM이 복구 중이면:

```text
복구 진행 중 화면
→ 새 입력 금지
→ FullEncounterResync 완료
→ 전투 HUD 복원
```

### 서버 전체 종료

새 서버는 다음 순서로 복원한다.

```text
CampaignLease 획득
→ EncounterBaseSnapshot 로드
→ 활성 Branch의 마지막 MaterializedSnapshot 로드
→ 이후 TurnDeltaJournal 재생
→ 마지막 정상 TurnCheckpoint 확인
→ PendingResolution 검사
→ 타임라인 UI 재구성
→ 플레이어 입장 허용
```

마지막 턴 종료 저장이 영속화되지 않았다면 DM에게 다음을 보여준다.

```text
메모리에는 존재했으나 영속화되지 않은 턴 경계가 있습니다.
마지막 영속 턴: 라운드 3 · 성직자 턴 종료
```

영속화되지 않은 상태를 저장됐다고 가장하지 않는다.

---

## 14. 긴 전투와 저장 한도

전투가 매우 길어도 모든 턴을 선택할 수 있어야 한다.

성능 정책:

- 변경된 Entity만 델타 기록
- 동일 Entity의 연속 변경은 체크포인트 구간 내부에서 압축
- 라운드 종료마다 전체 스냅샷 물질화
- 오래된 물질화 스냅샷은 압축하되 델타 경로 유지
- 비활성 Branch는 압축 우선순위를 높임
- 타임라인 UI는 가상화 목록 사용
- 상태 비교는 도메인별 해시로 변경 없는 영역 건너뜀

보존 공간이 임계치에 접근하면 DM에게 경고하되 활성 전투의 턴 항목을 삭제하지 않는다.

```text
전투 복구 기록의 저장량이 큽니다.
비활성 분기를 압축합니다.
현재 활성 분기의 모든 턴은 유지됩니다.
```

---

## 15. 권한과 공개

```text
DM
→ 타임라인 전체 조회
→ 숨겨진 변경 조회
→ 복구 실행
→ 분기 조회
→ 수동 마커 생성

플레이어
→ 현재 전투가 복구되었다는 알림
→ 자신에게 공개 가능한 변경 결과
→ 복구 실행 권한 없음
```

플레이어 알림 예시:

```text
DM이 전투를 라운드 2 · 전사 턴 시작으로 복구했습니다.
현재 상태를 다시 동기화했습니다.
```

다음은 알림에 포함하지 않는다.

- 복구로 다시 숨겨진 적
- 함정 위치
- 비밀문 정보
- DM 전용 상태
- 비공개 굴림

---

## 16. 감사 로그

```text
EncounterRollbackAuditEntry
├─ rollbackId
├─ encounterId
├─ requestedBy
├─ reason
├─ sourceBranchId
├─ sourceRevision
├─ targetCheckpointId
├─ targetBranchId
├─ newRevision
├─ invalidatedTransactionIds
├─ affectedDomainCounts
├─ requestedAt
├─ confirmedAt
└─ completedAt
```

복구 실패도 기록한다.

예:

```text
missing_snapshot
journal_gap
schema_mismatch
source_pack_missing
integrity_hash_failed
lease_lost
client_resync_timeout
```

복구 실패 시 기존 활성 Branch를 손상시키지 않고 전투를 일시정지한 채 DM에게 안전 선택지를 제공한다.

---

## 17. 테스트 조건

필수 테스트:

### 일반 턴 복구

- 3라운드 진행 후 라운드 1의 특정 턴 시작으로 복구
- HP, 위치, 자원, 상태와 주도권 일치 확인
- 이전 분기 보존 확인

### 그룹 턴

- 공유 Initiative의 NPC가 행동을 섞은 뒤 그룹 턴 시작으로 복구
- 개별 NPC HP와 자원은 분리 유지

### 반응 중 복구

- 기회 공격 반응창이 열린 상태에서 과거 턴 복구
- 미확정 반응 취소와 클라이언트 입력 폐기 확인

### 주사위 연출 중 복구

- 굴림 봉인 후 공개 전에 복구
- 과거 굴림이 현재 분기에 적용되지 않는지 확인

### 오브젝트 포함 복구

- 문 열기, 함정 발동, 상자 아이템 획득과 벽 파괴 후 복구
- 충돌, 시야, 아이템 소유권과 오브젝트 상태 복원 확인

### Fog와 은신

- 숨은 적 발견과 방 공개 후 복구
- DetectionState와 Fog 마스크 복원 확인
- 이미 공개된 정보 경고 확인

### 서버 종료

- 턴 종료 직후 서버 강제 종료
- 새 서버에서 마지막 영속 TurnCheckpoint로 복원
- 피해와 자원 중복 적용 없음 확인

### 다중 복구

- Branch A에서 A2로 복구해 Branch B 생성
- Branch B에서 다시 A4로 복구
- 모든 분기와 감사 기록 보존 확인

### 오래된 클라이언트 명령

- 복구 전 revision의 공격과 이동 패킷 재전송
- 서버 거절 확인

---

## 18. 완료 조건

- 활성 전투에서 모든 턴 경계가 타임라인에 보인다.
- DM이 전투 시작, 턴 시작, 턴 종료와 라운드 종료를 선택할 수 있다.
- 복구 전에 변경 요약과 비밀 정보 경고가 표시된다.
- 복구가 현재 이력을 삭제하지 않고 새 Branch를 만든다.
- HP, 자원, 위치, 상태, 아이템, 오브젝트, Fog와 탐지가 함께 복원된다.
- 과거 분기의 굴림과 트랜잭션이 중복 적용되지 않는다.
- 복구 이전 revision의 클라이언트 입력이 거절된다.
- 서버 종료 후 마지막 영속 턴 경계와 전체 타임라인을 복원할 수 있다.
- 전투 종료 후에도 현재 세션 동안 최근 전투 타임라인을 열 수 있다.
- 활성 전투에서는 저장 최적화를 이유로 턴 항목을 삭제하지 않는다.
