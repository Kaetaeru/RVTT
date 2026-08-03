# 36. 저장·자동 저장·재접속·서버 종료·세션 복구 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`02. 핵심 세션 루프`](../../../product/core-session-loop.md)
  - [`04. 장면과 월드`](../../../systems/scene/scenes-and-world.md)
  - [`07. 장면 편집 상호작용과 레이아웃`](../../../ui/scene-editor/scene-editor-interaction-and-layout.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](../../effect-recipe-resolution-and-commit-model.md)
  - [`25. HP 0·죽음 내성·휴식·자원 회복 모델`](../../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](../../../systems/combat/dice-roll-presentation-and-resolution-gating-model.md)
  - [`28. 인카운터·주도권·턴과 제어권 모델`](../../../systems/combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`31. 무설정 상호작용 프리팹과 상태 전환 모델`](../../../systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md)
  - [`32. 무설정 함정·비밀문·파괴 오브젝트 모델`](../../../systems/interaction/trap-secret-door-and-destructible-object-model.md)
  - [`34. 공식 2024 형식 캐릭터 시트와 실시간 플레이어 UI 모델`](../../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)
  - [`ADR-0042`](../../../decisions/ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)

## 1. 문서 목적

이 문서는 RVTT에서 다음 상황이 발생해도 캐릭터, 장면, 전투와 규칙 결과가 손실되거나 중복 적용되지 않도록 저장·복구 구조를 정의한다.

- 플레이어가 잠시 연결을 잃고 재접속
- DM이 앱이나 서버를 종료
- 활성 서버가 예기치 않게 중단
- 주사위 연출 도중 연결 종료
- 공격·주문 효과의 일부 단계 처리 후 중단
- 장면 편집 중 서버 중단
- 같은 캠페인을 두 서버가 동시에 열려고 시도
- 저장 스키마가 업데이트된 이후 과거 캠페인 로드
- DM이 특정 체크포인트로 되돌리기

핵심 원칙:

```text
권위 상태는 서버만 확정한다.
확정된 명령은 한 번만 적용된다.
클라이언트 연출은 잃어도 규칙 결과는 잃지 않는다.
복구는 마지막 안전 경계부터 결정론적으로 진행한다.
```

---

## 2. 저장 데이터 분류

RVTT는 모든 데이터를 하나의 거대한 저장 객체로 취급하지 않는다.

### 2.1 CampaignPersistentState

캠페인을 닫았다가 며칠 뒤 다시 열어도 유지되어야 하는 상태다.

```text
CampaignPersistentState
├─ campaign metadata
├─ ruleset and source pack versions
├─ character records
├─ progression choices
├─ inventory ownership
├─ equipment and attunement
├─ spell learning and preparation configuration
├─ scene definitions
├─ published scene revisions
├─ draft scene revisions
├─ interaction object definitions and links
├─ discovery fog masks
├─ campaign settings
├─ journal and handout references
└─ named recovery checkpoints
```

### 2.2 ActiveSessionState

현재 진행 중인 세션을 복구하기 위해 필요한 상태다.

```text
ActiveSessionState
├─ session id and state
├─ active scene id
├─ actor instances and transforms
├─ current HP and temporary HP
├─ expended resources
├─ active effects and concentration
├─ encounter session
├─ initiative order
├─ current round and turn
├─ ownership and control assignment
├─ doors, traps, chests and destructible states
├─ current reveal fog masks
├─ pending prompts and reactions
└─ pending resolution recovery records
```

### 2.3 PlayerPreferenceState

규칙 결과와 무관한 개인 설정이다.

```text
PlayerPreferenceState
├─ UI scale
├─ hotbar layout
├─ collapsed panels
├─ character sheet view mode
├─ input bindings
├─ tooltip preferences
├─ accessibility options
└─ local camera preferences allowed for persistence
```

캐릭터가 아닌 플레이어 계정에 연결해서 저장한다.

### 2.4 EphemeralPresentationState

저장하지 않는다.

```text
EphemeralPresentationState
├─ current camera transform
├─ hover target
├─ open tooltip
├─ tween progress
├─ dice rigid body positions
├─ particles and sounds
├─ unsubmitted placement ghost
├─ drag preview
└─ local targeting preview cache
```

복구 후 이 항목은 현재 권위 상태를 기준으로 새로 만든다.

---

## 3. 권위 revision

모든 권위 상태는 증가하는 revision을 가진다.

```text
AuthorityRevision = 15241
```

하나의 원자적 트랜잭션이 확정되면 revision이 한 번 증가한다.

```text
Revision 15241
→ 장검 공격 CommitGroup 확정
→ Revision 15242
```

트랜잭션 안에서 다음이 함께 바뀔 수 있다.

```text
공격자의 행동 자원
공격자의 무기 사용 상태
대상의 HP
새 상태 효과
집중 종료
전투 로그 항목
관련 Feature 사용 횟수
```

일부만 revision에 포함되는 것을 허용하지 않는다.

클라이언트는 자신의 마지막 수신 revision을 보낼 수 있지만, 서버는 클라이언트의 상태 내용을 신뢰하지 않는다.

---

## 4. 권위 스냅샷

스냅샷은 특정 revision에서 완전한 상태를 직렬화한 것이다.

```text
AuthoritativeSnapshot
├─ header
├─ campaign persistent section
├─ active session section
├─ index and reference table
└─ integrity information
```

### 4.1 SnapshotHeader

```text
SnapshotHeader
├─ snapshotId
├─ campaignId
├─ activeSessionId?
├─ schemaVersion
├─ rulesetVersion
├─ buildVersion
├─ authorityRevision
├─ lastJournalSequence
├─ createdAt
├─ reason
├─ parentSnapshotId?
└─ checksum
```

`reason` 예시:

```text
periodic
important_event
manual
before_encounter
encounter_ended
scene_published
server_shutdown
recovery_fork
```

### 4.2 참조 안정성

저장 데이터는 Workspace Instance 경로나 일시적 Roblox 객체 참조를 사용하지 않는다.

```text
잘못된 예
Workspace.Scenes.Dungeon.Door42

올바른 예
sceneObjectId = "obj_01K..."
```

Character, Actor, Item, SceneObject, Effect와 Encounter는 안정적인 ID를 가진다.

### 4.3 스냅샷 생성 방식

저장 시 게임 전체를 장시간 멈추지 않는다.

```text
안전 경계 도달
→ 현재 immutable state view 캡처
→ 다음 revision 진행 허용
→ 캡처된 view를 백그라운드 직렬화 큐에 전달
→ 무결성 검사
→ 저장
```

단, 캡처 이후의 변경은 저널에 계속 기록한다.

---

## 5. 명령 저널

명령 저널은 마지막 정상 스냅샷 이후의 확정 변경을 보존한다.

### 5.1 JournalEntry

```text
JournalEntry
├─ entryId
├─ sequence
├─ transactionId
├─ idempotencyKey
├─ commandType
├─ authorityRevisionBefore
├─ authorityRevisionAfter
├─ committedPayload
├─ affectedEntityIds
├─ committedAt
├─ sourceUserId?
├─ sourceActorId?
├─ sourceSystem
└─ auditFlags
```

### 5.2 저장하는 것은 의미 명령

```text
ApplyDamage
SpendResource
MoveActorCommitted
ChangeDoorState
TransferItemOwnership
CommitPreparedSpells
PublishSceneRevision
StartEncounter
EndEncounter
CreateFogMaskOperation
```

다음과 같은 저수준 변경 목록을 저널의 주된 계약으로 삼지 않는다.

```text
Part.CFrame 변경
TextLabel.Text 변경
Attribute 하나 변경
Tween 시작
```

의미 명령은 스키마 마이그레이션, 감사 로그와 장애 분석이 쉽다.

### 5.3 멱등성

서버는 다음 식별자를 이미 처리했는지 확인한다.

```text
transactionId
resolutionId
rollId
commitGroupId
journalEntryId
```

같은 요청이 네트워크 재전송이나 복구 재생으로 다시 도착해도 결과를 두 번 적용하지 않는다.

### 5.4 저널 압축

정상 스냅샷이 생성되고 검증되면 해당 스냅샷 이전 저널은 활성 복구 경로에서 압축할 수 있다.

감사와 DM 복구에 필요한 요약 기록은 별도 보존한다.

---

## 6. 안전 저장 경계

### 6.1 규칙 행동

```text
ActionIntent 수신
→ 대상과 비용 검증
→ 주사위 봉인
→ 연출
→ 결과 공개
→ EffectRecipe 해결
→ CommitGroup 원자적 확정
→ 안전 저장 경계
```

일반 스냅샷은 `CommitGroup` 확정 전후 중간에 상태를 잘라 저장하지 않는다.

### 6.2 턴

```text
TurnStarting 전체 처리 완료
→ 안전 경계

Action 또는 Opportunity 확정
→ 안전 경계

TurnEnding 전체 처리 완료
→ 안전 경계
```

### 6.3 장면 편집

```text
고스트 조정
→ 저장하지 않음

마우스 드래그 중
→ 저장하지 않음

서버 편집 명령 확정
→ 저널 기록
→ 안전 경계
```

다중 선택 작업은 전체가 성공하거나 전체가 실패한다.

### 6.4 Fog 편집

하나의 셀렉션 박스로 실행한 마스크 연산은 하나의 트랜잭션이다.

```text
AddDiscoveryVolume
RemoveDiscoveryVolume
AddCurrentRevealVolume
RemoveCurrentRevealVolume
```

박스 드래그 중간 크기는 저장하지 않는다.

---

## 7. PendingResolution 복구

규칙 해결이 시작됐지만 아직 전체 CommitGroup이 완료되지 않은 경우를 위한 별도 기록이다.

```text
PendingResolutionRecoveryRecord
├─ resolutionId
├─ actionIntentId
├─ initiatorActorId
├─ targetSnapshot
├─ capabilityId
├─ selectedVariantId
├─ sealedRolls
├─ presentationStage
├─ reservedResources
├─ committedStepIds
├─ unresolvedStepIds
├─ currentAuthorityRevision
├─ recoveryPolicy
└─ expiresAt
```

### 7.1 presentationStage

```text
prepared
roll_sealed
awaiting_presentation
result_revealed
resolving_effects
awaiting_reaction
ready_to_commit
committed
cancelled
```

### 7.2 recoveryPolicy

```text
resume
reveal_then_resume
skip_presentation_and_resume
abort_before_cost
rollback_reservation
require_dm_review
```

### 7.3 자원 예약

주문 슬롯이나 행동 자원은 해결 중 중복 사용을 막기 위해 예약할 수 있다.

```text
available
→ reserved by resolutionId
→ committed as spent
```

행동이 안전 취소되면 예약만 해제한다. 이미 규칙상 소비가 확정된 자원은 되돌리지 않는다.

### 7.4 효과 단계 중단

```text
화염 피해 확정
→ committedStepIds에 기록

추가 점화 효과 처리 전 중단
→ 점화 단계만 재개
```

화염 피해를 다시 적용하지 않는다.

---

## 8. 자동 저장 정책

### 8.1 저장 요청 종류

```text
journal_flush
snapshot_requested
checkpoint_requested
pre_shutdown_flush
manual_save
```

### 8.2 중요 사건

다음 사건은 즉시 저널 flush와 스냅샷 또는 체크포인트 예약을 발생시킨다.

```text
캐릭터 생성 완료
레벨업 선택 확정
Feat·특성·주문 습득 확정
아이템 소유권 이전
마법 아이템 조율 변경
긴 휴식 완료
Actor 장기 사망·부활
인카운터 시작
인카운터 종료
장면 게시
대규모 Fog 편집 완료
DM 수동 체크포인트
캠페인 설정 변경
```

### 8.3 연속 변화 debounce

다음 변경은 저널에는 즉시 기록하되 전체 스냅샷은 병합한다.

```text
여러 번의 피해·회복
짧은 시간 안의 이동 연속 확정
여러 문·상자 상태 변경
Hotbar 재배치
장면 오브젝트 반복 이동
```

### 8.4 정기 체크포인트

활성 세션에는 정기 안전 체크포인트가 필요하다. 정확한 간격은 운영 설정으로 두되, 빈번한 전체 저장보다 저널 flush를 우선한다.

```text
짧은 간격
→ Journal flush

더 긴 간격
→ 검증된 Snapshot
```

### 8.5 저장 큐

```text
PersistenceCoordinator
├─ DirtyDomainTracker
├─ JournalBuffer
├─ SnapshotScheduler
├─ CheckpointManager
├─ SaveWorker
├─ RetryPolicy
├─ IntegrityValidator
└─ RecoveryIndex
```

동일 캠페인에 대한 저장은 순서를 유지한다. 오래 걸리는 스냅샷 때문에 최신 저널 flush가 막히지 않도록 우선순위를 구분한다.

---

## 9. 체크포인트

### 9.1 자동 체크포인트

```text
Autosave 01
Before Encounter: Goblin Cave
After Encounter: Goblin Cave
Before Scene Publish: Cragmaw Entrance
After Long Rest
Before Level Up Commit
Server Shutdown
```

### 9.2 이름 지정 체크포인트

DM은 이름과 메모를 지정할 수 있다.

```text
이름: 성문 전투 직전
메모: 경비병과 협상 실패 후
```

### 9.3 보존 정책

```text
latest authoritative snapshot
recent rolling autosaves
important event checkpoints
named checkpoints
migration backups
```

자동 저장은 설정된 개수나 기간 이후 정리할 수 있다. 이름 지정 체크포인트는 DM이 명시적으로 삭제하기 전까지 별도 취급한다.

### 9.4 복구는 새 revision

```text
Revision 2000의 체크포인트 선택
현재 Revision 2350
→ 체크포인트 상태를 기반으로 Revision 2351 recovery fork 생성
```

과거 기록을 직접 수정하지 않는다.

---

## 10. 플레이어 연결 종료

### 10.1 DisconnectState

```text
connected
connection_lost_grace
absent
rejoining
recovered
```

짧은 네트워크 단절에는 grace 기간을 둘 수 있다.

### 10.2 Actor 상태

플레이어가 나가도 Actor를 즉시 삭제하지 않는다.

```text
ActorOwnership
→ 원래 플레이어 유지

ControlAssignment
→ disconnect policy에 따라 변경 가능
```

### 10.3 전투 이탈 정책

캠페인 또는 현재 인카운터에서 선택한다.

```text
pause_on_actor_turn
suggest_dm_takeover
auto_transfer_to_dm
delegate_to_selected_player
server_automation
hold_position_and_skip
```

기본 권장값:

```text
현재 처리 중 행동은 안전 경계까지 완료
→ 다음 입력이 필요한 순간 일시정지
→ DM에게 제어권 인수 제안
```

자동으로 공격하거나 자원을 소비하는 AI 위임은 DM이 사전에 허용한 경우에만 사용한다.

### 10.4 반응 대기 중 이탈

```text
Ask 반응 대기
→ grace 기간
→ 사전 설정된 반응 정책 확인
→ DM 결정 또는 건너뛰기
```

무한정 세션을 멈추지 않는다.

---

## 11. 같은 서버 재접속

```text
플레이어 인증
→ 활성 세션 참가 권한 확인
→ ownership 조회
→ 최신 AuthorityRevision 전송
→ 필요한 Projection 생성
→ 입력 문맥 복원
```

복원 대상:

```text
현재 Actor 선택
캐릭터 시트 실시간 값
Hotbar 구성
현재 턴과 이니셔티브
지속 효과
현재 Fog 가시성
대기 중 Prompt
대기 중 Reaction
RollPresentation 결과 상태
```

카메라와 Hover 상태는 복원하지 않고 현재 Actor 주변으로 안전하게 재초기화한다.

### 11.1 재접속 시 PendingResolution

```text
awaiting_presentation
→ 주사위 연출 다시 보기 또는 결과 표시

result_revealed
→ 결과 카드와 다음 단계 복구

awaiting_reaction
→ 남은 시간과 선택지 복구

committed
→ 최신 결과만 동기화
```

---

## 12. 새 서버에서 세션 재개

활성 서버가 사라진 경우 캠페인 로비에서 `세션 복구`가 가능해야 한다.

```text
CampaignLease 상태 확인
→ 마지막 Snapshot 로드
→ 이후 JournalEntry 순서대로 재생
→ PendingResolution 검사
→ 무결성 검사
→ 새 AuthorityRevision 발행
→ 활성 장면 생성
→ 플레이어 참가 허용
```

### 12.1 복구 전 검사

```text
모든 참조 ID 존재
Actor와 Character 연결 유효
Item 소유권 중복 없음
Encounter 현재 entry 유효
Effect source와 target 유효
SceneObject prefab 해석 가능
Fog volume 데이터 유효
Journal sequence 누락 없음
```

심각한 문제가 있으면 자동으로 플레이를 시작하지 않고 DM 복구 화면으로 이동한다.

---

## 13. 서버 종료 절차

### 13.1 ShutdownStateMachine

```text
running
→ draining
→ reaching_safe_boundary
→ flushing_journal
→ writing_snapshot
→ marking_resumable
→ closed
```

### 13.2 draining

- 새 플레이어 입장을 제한한다.
- 새 장시간 행동과 대규모 편집 트랜잭션 시작을 막는다.
- 현재 진행 중인 짧은 명령은 안전 경계까지 처리한다.
- UI에 저장 중 상태를 표시한다.

### 13.3 안전 취소

안전 경계까지 끝낼 수 없는 작업은 정책에 따라 취소한다.

```text
제출되지 않은 대상 지정
→ 취소

고스트 배치
→ 취소

예약만 된 자원
→ 예약 해제

이미 공개된 주사위와 규칙상 확정된 비용
→ 유지

절반 적용 EffectRecipe
→ RecoveryRecord 기록
```

### 13.4 최종 저장 우선순위

```text
1. JournalBuffer
2. CommitGroup 상태와 Character 장기 데이터
3. ActiveSessionState
4. Scene draft and fog edits
5. Player preferences
```

최종 Snapshot 쓰기에 실패해도 저널이 보존되면 이전 스냅샷에서 재생할 수 있다.

---

## 14. 단일 권위 서버와 Lease

### 14.1 CampaignLease

```text
CampaignLease
├─ campaignId
├─ authorityServerId
├─ fencingToken
├─ acquiredAt
├─ renewedAt
├─ expiresAt
└─ mode
```

`mode`:

```text
read_write
read_only_recovery
migration
```

### 14.2 fencingToken

새 서버가 권한을 인수할 때 더 높은 token을 받는다.

```text
Server A token 17
Server B token 18
```

Server A의 늦은 저장 요청은 거절된다.

### 14.3 중복 실행 감지

DM이 같은 캠페인을 다른 서버에서 열려고 하면:

```text
활성 세션으로 참가
읽기 전용으로 열기
기존 서버 종료 요청
복구 권한 인수
취소
```

권한 인수는 만료 또는 명시적 안전 절차를 요구한다.

---

## 15. 장면 초안과 게시본

### 15.1 SceneRevision

```text
SceneRevision
├─ sceneId
├─ revisionId
├─ parentRevisionId
├─ status
├─ objectGraph
├─ navigationDataRef
├─ interactionGraph
├─ fogDefinitions
├─ createdBy
└─ createdAt
```

`status`:

```text
draft
published
archived
recovery_copy
```

### 15.2 편집 중 종료

- 마지막 확정 편집 명령까지 초안에 복원한다.
- 드래그 중간값과 고스트는 버린다.
- 게시본은 영향받지 않는다.
- 초안 무결성 검사 실패 시 마지막 정상 초안 또는 게시본을 제공한다.

### 15.3 게시

```text
초안 검사
→ 이동·차단 데이터 검사
→ 상호작용 링크 검사
→ 참조 프리팹 검사
→ PublishSceneRevision Commit
→ 게시 전·후 체크포인트
```

---

## 16. 캐릭터와 인벤토리 일관성

### 16.1 아이템 이전

```text
소유자 A에서 제거
+ 소유자 B에 추가
+ 장착 상태 갱신
+ 파생 수치 재계산
= 하나의 CommitGroup
```

아이템이 양쪽에 동시에 존재하거나 사라지는 중간 상태를 저장하지 않는다.

### 16.2 레벨업

레벨업 마법사 선택은 초안으로 저장할 수 있지만 실제 캐릭터에는 확정 전 적용하지 않는다.

```text
LevelUpDraft
→ 선택 검증
→ 미리보기
→ E 확정
→ CharacterProgression CommitGroup
→ 중요 체크포인트
```

### 16.3 HP와 자원

현재 HP, 주문 슬롯, Feature 횟수는 ActiveSessionState에 즉시 반영한다. 캠페인을 닫을 때 장기 상태로 함께 보존한다.

---

## 17. Fog 저장

```text
DiscoveryMask
→ CampaignPersistentState

CurrentRevealMask
→ ActiveSessionState
```

장면을 다시 시작할 때 정책에 따라 `CurrentRevealMask`를 유지하거나 Discovery 기반 기본 공개 상태로 초기화할 수 있다.

Fog Assist의 제안 미리보기는 저장하지 않는다. DM이 승인한 마스크 연산만 저장한다.

---

## 18. DM 저장·복구 화면

### 18.1 저장 상태 표시

```text
저장됨
변경 사항 있음
저장 중
저장 재시도 중
저장 실패
복구 필요
```

평상시 화면을 방해하지 않는 작은 상태 아이콘으로 표시하고, 오류 시만 확장한다.

### 18.2 체크포인트 목록

```text
시간
이름
생성 이유
장면
인카운터 상태
AuthorityRevision
빌드·스키마 버전
무결성 상태
```

### 18.3 비교 미리보기

복구 전에 현재 상태와 체크포인트 차이를 요약한다.

```text
캐릭터 4명 중 2명 HP 변경
아이템 소유권 3건 변경
장면 오브젝트 12개 변경
Fog volume 4건 변경
현재 인카운터 제거
지속 효과 6개 변경
```

### 18.4 복구 범위

기본은 전체 일관 복구다. 제한적 부분 복구는 참조 관계를 깨뜨릴 수 있으므로 별도 안전 작업으로 제공한다.

초기 지원:

```text
전체 캠페인·활성 세션 복구
현재 장면 초안만 복구
플레이어 환경설정 초기화
```

캐릭터 한 명의 HP만 과거로 되돌리는 식의 부분 복구는 일반 체크포인트 UI가 아니라 DM Override 명령으로 처리한다.

### 18.5 복구 확정

```text
영향 요약 확인
→ 복구 사유 입력
→ E 길게 누르기 또는 명시적 확인
→ 새로운 recovery fork 생성
→ 감사 로그 기록
```

---

## 19. 오류 처리

### 19.1 저장 실패

```text
일시 오류
→ 지수적 backoff 재시도
→ 저널 버퍼 유지

반복 실패
→ DM 경고
→ 위험한 장기 작업 제한 가능
→ 로컬 상태를 저장됐다고 표시하지 않음
```

### 19.2 무결성 실패

```text
checksum 불일치
journal sequence 누락
참조 ID 누락
중복 Item ownership
잘못된 schemaVersion
```

자동 수리가 확실한 경우에만 수행한다. 불명확한 경우 원본을 보존하고 이전 정상 스냅샷을 제안한다.

### 19.3 콘텐츠 누락

저장된 Actor가 참조하는 사용자 JSON 정의나 프리팹이 현재 빌드에 없을 수 있다.

```text
원본 저장 유지
→ MissingDefinition placeholder 생성
→ DM에게 누락 항목 표시
→ 대체 정의 연결 또는 콘텐츠 복구
```

데이터를 임의 삭제하지 않는다.

---

## 20. 스키마 마이그레이션

### 20.1 순차 마이그레이션

```text
v12
→ migrate v12 to v13
→ migrate v13 to v14
→ validate v14
→ runtime model
```

중간 버전을 건너뛰는 거대한 변환보다 작은 순차 변환을 유지한다.

### 20.2 마이그레이션 백업

마이그레이션 전 읽기 전용 백업 체크포인트를 만든다.

```text
pre_migration_v12
```

변환 실패 시 원본을 덮어쓰지 않는다.

### 20.3 콘텐츠 버전

저장 스키마와 규칙 콘텐츠 버전은 분리한다.

```text
schemaVersion
rulesetVersion
sourcePackVersions
```

공식 규칙 데이터가 변경되더라도 기존 캐릭터 선택과 생성 당시 출처를 추적할 수 있어야 한다.

---

## 21. 감사 로그

다음 작업은 감사 로그에 남긴다.

```text
DM 수동 저장
체크포인트 생성·삭제
복구 실행
캐릭터 수치 Override
아이템 소유권 강제 변경
인카운터 강제 종료
중복 서버 권한 인수
마이그레이션
저장 무결성 자동 수리
```

감사 로그는 플레이어에게 공개되는 전투 로그와 분리한다.

---

## 22. 성능 원칙

- 매 프레임 전체 상태를 직렬화하지 않는다.
- Dirty domain과 의미 명령을 기반으로 저장한다.
- 스냅샷 생성 중 규칙 처리 전체를 장시간 정지하지 않는다.
- 큰 장면 object graph는 변경된 revision 단위로 분할할 수 있다.
- PlayerPreference 저장 실패가 전투 권위 저장을 막지 않는다.
- 저장 큐가 밀리면 낮은 우선순위 스냅샷을 합치되 저널 항목은 누락하지 않는다.
- 저장 크기, 직렬화 시간, 재시도 횟수와 복구 재생 시간을 측정한다.

관측 지표:

```text
journal flush latency
snapshot serialization time
snapshot write latency
pending dirty bytes
retry count
checkpoint count
recovery replay duration
migration duration
integrity failure count
```

---

## 23. 테스트 요구사항

### 23.1 규칙 해결

- 공격 굴림 봉인 직후 서버 종료
- 명중 공개 후 피해 굴림 전 종료
- 피해 적용 후 상태 효과 적용 전 종료
- 반응 선택 대기 중 종료
- 동일 resolution 재전송
- 자원 예약 상태에서 안전 취소

### 23.2 인카운터

- 턴 시작 효과 처리 도중 종료
- NPC 그룹 턴 중 플레이어 재접속
- 참가자 추가 도중 종료
- 인카운터 종료 처리 도중 종료
- 현재 턴 Actor 연결 종료

### 23.3 장면

- 오브젝트 다중 이동 드래그 중 종료
- 편집 트랜잭션 확정 직후 종료
- 장면 게시 검사 중 종료
- Fog 셀렉션 박스 조정 중 종료
- 문 Tween 도중 종료
- 파괴 오브젝트 상태 전환 도중 종료

Tween 중 종료 후에는 저장된 논리 상태에 해당하는 최종 스냅샷 상태로 즉시 생성한다. Tween 중간 프레임을 복원하지 않는다.

### 23.4 저장 인프라

- Snapshot 저장 실패 후 저널 기반 복구
- JournalEntry 중복
- Journal sequence 누락
- 오래된 서버의 fencing token 쓰기
- 두 서버 동시 권한 요청
- checksum 실패
- 마이그레이션 실패
- 누락된 사용자 콘텐츠 정의

### 23.5 사용자 경험

- 재접속 후 시트와 Hotbar 일치
- 재접속 후 Fog 비밀 정보 누출 없음
- 반응창 복구
- 저장 실패 상태 표시
- 복구 비교 화면
- UI 설정만 별도로 초기화

---

## 24. 완료 기준

이 기능은 다음이 증명되어야 완료로 본다.

- 확정된 규칙 명령이 장애 후 유실되지 않는다.
- 동일 명령이 복구 과정에서 두 번 적용되지 않는다.
- 캐릭터, 인벤토리, 장면과 인카운터가 같은 revision으로 복원된다.
- 주사위 연출 중 장애가 발생해도 봉인된 결과와 적용 여부를 판단할 수 있다.
- 미완성 고스트와 Tween 중간 상태가 저장되지 않는다.
- 플레이어 재접속 후 권한·제어권·시트·Hotbar가 서버 상태와 일치한다.
- 활성 캠페인을 두 서버가 동시에 수정할 수 없다.
- DM이 체크포인트 차이를 확인하고 새 revision으로 복구할 수 있다.
- 마이그레이션 실패가 원본 저장을 파괴하지 않는다.
- 저장 실패와 복구 필요 상태가 DM에게 명확히 표시된다.
