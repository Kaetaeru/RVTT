# 27. 주사위 굴림·연출·결과 확정 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`19. 트리거와 다른 턴 실행 모델`](19-feat-feature-trigger-and-cross-turn-execution-model.md)
  - [`22. EffectRecipe와 효과 해결·확정 모델`](22-effect-recipe-resolution-and-commit-model.md)
  - [`25. HP 0·죽음 내성·휴식·자원 회복 모델`](25-zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
  - [`26. 몬스터·NPC 스탯블록과 JSON 가져오기 모델`](26-monster-npc-statblock-and-ingame-json-import-model.md)
  - [`ADR-0033`](decisions/ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)

## 1. 문서 목적

이 문서는 RVTT의 모든 주사위 굴림이 서버 권위를 유지하면서도, 클라이언트 카메라 뒤에서 화면 중앙으로 날아오는 3D 주사위 연출과 규칙 결과를 정확히 동기화하는 방법을 정의한다.

대상은 다음을 포함한다.

- 공격 굴림
- 피해·회복 굴림
- 내성 굴림과 능력 판정
- 이니셔티브
- 죽음 내성
- 재충전 굴림
- 비밀 DM 굴림
- 이점·불리점과 재굴림
- 여러 주사위와 배치 굴림
- 연출 스킵, 느린 클라이언트와 연결 끊김

핵심 원칙:

```text
클라이언트 물리 결과
≠ 권위 주사위 결과
```

```text
서버가 결과를 생성
→ 결과를 봉인
→ 클라이언트가 연출
→ 결과 면 공개
→ 규칙 결과 확정
```

---

## 2. 전체 아키텍처

```text
RollService
├─ RollRequestValidator
├─ ServerRngProvider
├─ SealedRollStore
├─ RollPresentationCoordinator
├─ RollRevealGate
├─ RollRecordStore
├─ OutcomeResolver
└─ RollAuditLog
```

### RollService

모든 굴림의 단일 진입점이다.

### ServerRngProvider

권위 원시 주사위 값을 생성한다.

### SealedRollStore

공개 전 결과를 서버에 보관한다.

### RollPresentationCoordinator

각 클라이언트에 허용된 연출 명령을 보낸다.

### RollRevealGate

연출과 규칙 확정 사이의 관문이다.

### OutcomeResolver

공개된 RollRecord를 명중, 성공, 실패, 치명타 등의 `ResolutionOutcome`으로 변환한다.

---

## 3. RollRequest

```text
RollRequest
├─ requestId
├─ sourceExecutionId
├─ sourceNodeId
├─ rollerActorId
├─ rollKind
├─ diceExpression
├─ rollScope
├─ targetBindings[]
├─ contextSnapshot
├─ visibilityPolicy
├─ presentationPolicy
├─ expectedRevisions
└─ idempotencyKey
```

클라이언트가 직접 굴림 표현식이나 수정치를 임의 제출하는 일반 경로는 허용하지 않는다.

클라이언트는 보통 다음 의도만 보낸다.

```text
이 공격 실행
이 내성 굴림 수행
이 능력 판정 수행
이니셔티브 굴림 참여
```

서버가 콘텐츠 정의, Capability, 규칙 문맥과 현재 상태에서 실제 RollRequest를 구성한다.

DM 수동 굴림은 별도의 권한 있는 명령으로 지원하되, 허용된 주사위 표현식과 공개 범위를 서버가 검증한다.

---

## 4. 굴림 상태 기계

```text
requested
→ validated
→ sealed
→ presentation_dispatched
→ presenting
→ reveal_ready
→ revealed
→ resolving
→ resolved
```

예외 상태:

```text
rejected
cancelled_before_roll
cancelled_before_reveal
revealed_but_invalidated
presentation_timed_out
resolution_failed
```

### sealed

서버가 원시 결과를 생성했지만 audience에 공개하지 않은 상태다.

### presenting

클라이언트가 3D 또는 축약 연출을 재생 중이다.

### reveal_ready

최소 연출 시간과 ACK 정책을 만족했거나 hard timeout에 도달했다.

### revealed

권한 있는 audience에 결과가 공개되었다.

### resolved

결과가 `ResolutionOutcome`과 후속 규칙 상태에 반영되었다.

---

## 5. 서버 RNG와 봉인 결과

```text
SealedRollResult
├─ rollId
├─ diceTerms[]
├─ rawDice[]
├─ selectedDice[]
├─ discardedDice[]
├─ modifierContributions[]
├─ total
├─ criticalInputs
├─ rerollRelations[]
├─ randomSourceMetadata
├─ visibilityPolicy
├─ createdAtServerTime
└─ state
```

`randomSourceMetadata`는 감사와 재현 진단을 위한 서버 정보다. 결과를 예측할 수 있는 비밀 seed를 일반 클라이언트에 전송하지 않는다.

굴림 결과는 다음과 분리한다.

```text
raw dice
+ 선택·제외 규칙
+ 수정치
= total
```

이 구조는 이점, 불리점, 재굴림, 최소값 대체와 여러 주사위 선택을 설명할 수 있게 한다.

---

## 6. 프레젠테이션 명령

클라이언트에 보내는 명령은 권한에 따라 결과 노출 수준이 다르다.

```text
RollPresentationCommand
├─ presentationId
├─ rollId
├─ presentationProfileId
├─ diceVisualDescriptors[]
├─ trajectorySeed
├─ finalFaceDescriptors?
├─ startAtServerTime
├─ revealNotBeforeServerTime
├─ hardTimeoutServerTime
├─ cameraSpaceSpawnProfile
├─ centerTargetProfile
├─ visibilityPayload
└─ skipAllowed
```

공개 굴림에서는 `finalFaceDescriptors`를 결과 연출용으로 받을 수 있다.

비밀 굴림의 권한 없는 audience에는 결과 면 정보나 이를 추론할 수 있는 trajectory seed를 보내지 않는다. 필요하면 결과가 없는 추상 연출만 보여준다.

---

## 7. 카메라 기준 주사위 생성

주사위는 Workspace의 일반 전투 물체가 아니라 각 클라이언트 전용 프레젠테이션 레이어에 생성한다.

권장 구조:

```text
CurrentCamera
└─ LocalPresentationRoot
   └─ DicePresentationWorld
```

주사위 생성 위치는 카메라 좌표계로 계산한다.

```text
spawnPosition
= cameraPosition
+ cameraLookVector × behindOrNearOffset
+ cameraRightVector × horizontalOffset
+ cameraUpVector × verticalOffset
```

실제로 카메라 뒤에 두면 기본 카메라 절두체에 보이지 않을 수 있으므로 프로필은 두 방식을 지원한다.

### behind_camera_arc

카메라 뒤쪽에서 시작한 것처럼 보이는 곡선 궤적으로 시야 가장자리에서 진입한다.

### near_camera_launch

카메라 바로 앞의 시야 밖 또는 화면 가장자리 근처에서 빠르게 중앙으로 발사한다.

사용자가 보는 체감은 “카메라 뒤에서 날아옴”이지만, 렌더링 누락 없이 안정적으로 보이도록 실제 생성점은 프레젠테이션 프로필이 결정한다.

---

## 8. 화면 중앙 도착점

도착점은 고정 월드 좌표가 아니라 카메라 앞의 프레젠테이션 평면에 둔다.

```text
centerPoint
= cameraPosition
+ cameraLookVector × centerDepth
+ cameraRightVector × screenOffsetX
+ cameraUpVector × screenOffsetY
```

여러 주사위는 중앙점 주변에 작은 원, 호 또는 가로 배열로 배치한다.

```text
single die
→ 정확한 중앙 근처

2 dice advantage
→ 중앙 좌우

many damage dice
→ 중앙 주변 compact cluster
```

카메라가 굴림 도중 움직일 때의 정책:

- `camera_locked_relative`: 주사위가 계속 화면 중앙을 따라감
- `camera_snapshot`: 굴림 시작 시 카메라 좌표를 고정
- `soft_follow`: 제한된 범위에서 부드럽게 따라감

기본은 `camera_locked_relative`로 하되 멀미 방지를 위해 급격한 카메라 회전에서는 soft follow로 전환한다.

---

## 9. 궤적과 회전

연출은 세 구간으로 나눈다.

```text
Launch
→ Tumbling Flight
→ Settle and Reveal
```

### Launch

카메라 뒤 또는 화면 가장자리에서 빠르게 등장한다.

### Tumbling Flight

곡선 궤적, 회전, 약한 충돌과 사운드를 재생한다.

### Settle and Reveal

화면 중앙에서 감속하고 결과 면을 위 또는 카메라 방향으로 명확히 보인다.

물리 기반 연출과 보간 기반 연출을 혼합할 수 있다.

```text
초기 구간
→ 시각적 물리·회전

마지막 구간
→ 목표 orientation을 향한 제어된 안정화
```

완전한 Roblox 물리 결과를 신뢰하지 않는다.

---

## 10. 결과 면 정렬

각 주사위 메시에는 면 값과 로컬 방향의 매핑이 필요하다.

```text
DiceFaceMap
├─ faceValue
├─ localNormal
├─ labelOrientation
└─ materialRegion?
```

서버 결과가 17인 d20이라면 클라이언트는 `17`의 localNormal이 지정된 표시 방향을 향하도록 최종 회전을 계산한다.

표시 방향 정책:

- `face_up`: 결과 면이 위를 향함
- `face_toward_camera`: 결과 면이 카메라를 향함
- `angled_readable`: 위쪽이면서 카메라에서도 읽기 쉬운 각도

기본은 `angled_readable`이다.

---

## 11. RollPresentationSession

```text
RollPresentationSession
├─ presentationId
├─ rollId
├─ audienceEntries[]
├─ startServerTime
├─ revealNotBeforeServerTime
├─ hardTimeoutServerTime
├─ requiredAcksPolicy
├─ receivedAcks
├─ state
└─ diagnostics
```

### AudienceEntry

```text
AudienceEntry
├─ playerId
├─ visibilityLevel
├─ presentationMode
├─ ackRequired
└─ connectionState
```

### visibilityLevel

```text
full_result
result_only
roll_occurred_only
hidden
```

### presentationMode

```text
full_3d
short_3d
compact_2d
minimal
none
```

---

## 12. ACK 정책

클라이언트는 다음만 보낸다.

```text
RollPresentationAck
├─ presentationId
├─ playerId
├─ status
├─ completedAtClientTime
└─ clientPresentationMode
```

status:

```text
completed
skipped
failed
not_visible
```

클라이언트는 주사위 결과나 최종 면을 ACK에 포함하지 않는다.

기본 ACK 정책:

- 굴림을 직접 수행한 로컬 플레이어는 중요 audience다.
- DM은 공개·전투 중요 굴림에서 중요 audience가 될 수 있다.
- 모든 관전자 ACK를 기다리지 않는다.
- 최소 공개 시간은 서버 시간이 기준이다.
- hard timeout 이후에는 ACK 없이 진행한다.

---

## 13. RollRevealGate

```text
RollRevealGate
├─ rollId
├─ minimumTimeSatisfied
├─ ackPolicySatisfied
├─ hardTimeoutReached
├─ executionStillValid
└─ decision
```

공개 조건:

```text
executionStillValid
AND
minimumTimeSatisfied
AND
(ackPolicySatisfied OR hardTimeoutReached)
```

공개 직전 서버는 다음 revision을 재검증한다.

- 실행 상태
- Actor 존재 여부
- 대상 상태
- 장면 상태
- 규칙 버전
- 취소 또는 인터럽트 여부

굴림 이후 상황이 변했더라도 이미 발생한 주사위 결과를 임의로 다시 굴리지 않는다. 결과 적용 가능 여부만 별도로 판단한다.

---

## 14. 결과 공개

게이트가 열리면 서버가 audience별 공개 패킷을 만든다.

```text
RollRevealPayload
├─ rollId
├─ visibleRawDice
├─ visibleSelectedDice
├─ visibleModifiers
├─ visibleTotal
├─ outcomePreview?
└─ presentationHoldDuration
```

공개 후 중앙 주사위 위에 다음 정보를 표시할 수 있다.

```text
17
+ 공격 보너스 5
= 22
```

이점이라면:

```text
7   16
    ↑ 선택
+5
=21
```

수정치의 세부 출처는 로그 또는 확장 패널에서 확인한다.

---

## 15. 결과 확정 순서

### 공격 굴림

```text
Attack Roll 공개
→ 공격 total 계산 공개
→ 대상 AC와 규칙 문맥 비교
→ AttackHitConfirmed 또는 AttackMissed
→ 명중 후 TimingWindow
→ 피해 굴림 시작
```

주사위가 멈추기 전에 대상 HP를 줄이지 않는다.

### 내성 굴림

```text
Save Roll 공개
→ 성공·실패 Outcome
→ 결과 수정 반응 창
→ 효과 분기
```

### 피해 굴림

```text
Damage Roll 공개
→ PendingDamage 생성
→ 피해 감소·면역·저항 처리
→ 적용 직전 반응
→ HP Commit
```

### 이니셔티브

```text
모든 필요 굴림 공개
→ 수정치 포함 total 계산
→ 동률 정책 적용
→ InitiativeOrder Commit
→ 전투 UI 공개
```

---

## 16. 이니셔티브 배치 굴림

많은 NPC가 있으면 모든 d20을 순차 전체 화면으로 보여주는 것은 느리다.

```text
InitiativeBatchPresentationPolicy
├─ playerCharacters: local_focus
├─ importantNpcs: featured
├─ minorNpcs: compact_group
└─ hiddenActors: dm_only
```

권장 UX:

- 자신의 캐릭터 d20은 화면 중앙에 크게 연출
- 다른 플레이어는 작은 병렬 연출 또는 로그
- 주요 보스는 DM과 플레이어에게 별도 강조 가능
- 일반 몬스터 다수는 그룹 단위 compact 연출
- 모든 결과가 공개 준비되면 이니셔티브 바가 한 번에 정렬

NPC가 같은 이니셔티브를 공유하는 캠페인 옵션도 배치 정책에서 지원한다.

---

## 17. 공격과 피해 연속 연출

기본 모드:

```text
공격 d20 등장
→ 결과 공개
→ 명중 강조
→ 피해 주사위가 뒤이어 등장
→ 피해 공개
→ 대상 HP 변경
```

공격 실패:

```text
공격 d20 공개
→ 빗나감
→ 피해 주사위 생성 안 함
```

빠른 모드:

```text
공격과 피해 주사위를 미리 준비
→ 공격 결과 먼저 공개
→ 명중 시 피해 주사위 공개
→ 실패 시 피해 주사위 폐기 또는 비공개
```

빠른 모드에서도 피해 결과가 공격 성공 전에 규칙 상태에 반영되지 않는다.

---

## 18. 다중 공격

추가 공격과 다중공격의 각 공격은 별도 RollPresentationSession을 가진다.

```text
공격 1 굴림·공개·확정
→ 이동 또는 대상 변경 가능
→ 공격 2 굴림·공개·확정
```

DM이 속도 향상을 선택하면 compact queue를 사용할 수 있다.

```text
공격 1 d20
공격 2 d20
공격 3 d20
→ 짧은 간격으로 연속 표시
```

하지만 각 공격의 규칙 CommitGroup은 분리한다.

---

## 19. 이점·불리점

두 개의 d20을 함께 던진다.

```text
advantage
→ 높은 값 선택 강조

disadvantage
→ 낮은 값 선택 강조
```

두 주사위는 색상 대신 위치, 테두리, 크기와 선택 화살표로도 구분하여 접근성을 확보한다.

상쇄된 이점·불리점은 최종 RollMode를 계산한 뒤 필요한 주사위 수만 연출한다.

---

## 20. 재굴림과 결과 교체

재굴림은 기존 주사위를 몰래 바꾸지 않는다.

```text
원래 RollRecord
→ 재굴림 Trigger 또는 선택
→ 새 child RollRequest
→ 새 주사위 연출
→ replacement relation 기록
→ 최종 선택 결과 공개
```

로그에는 다음 관계가 남는다.

```text
roll B rerolls die 1 of roll A
roll C replaces total of roll A
```

원래 공개된 결과는 기록에서 사라지지 않는다.

---

## 21. 비밀 굴림

### DM 완전 비밀

- DM에게만 3D 연출과 숫자를 공개한다.
- 플레이어는 아무 정보도 받지 않는다.

### 발생만 공개

- 플레이어에게 주사위가 굴러갔다는 짧은 효과만 보여준다.
- 결과 면과 total은 숨긴다.

### 결과 효과만 공개

- 주사위 연출 없이 이후 발생한 게임 결과만 보여준다.

### 지연 공개

- 굴림은 봉인된 채 유지한다.
- 규칙상 결과를 알아야 하는 시점에 공개한다.

비밀 결과가 포함된 물리·애니메이션 파라미터도 권한 없는 클라이언트에 보내지 않는다.

---

## 22. 클라이언트 실패와 연결 끊김

### 프레임 드롭

연출이 늦어도 hard timeout에서 서버 진행은 계속된다.

### 연결 끊김

해당 audience의 ACK 요구를 연결 상태 정책에 따라 해제한다.

### 재접속

이미 공개된 굴림은 현재 RollRecord와 결과를 즉시 동기화한다.

아직 봉인된 굴림이면 권한과 남은 시간을 확인해 축약 연출 또는 현재 단계부터 재생한다.

### 프레젠테이션 오류

클라이언트는 `failed` ACK를 보내고 2D 결과 카드로 대체한다.

---

## 23. 연출 스킵과 접근성

플레이어별 설정:

```text
DicePresentationPreference
├─ mode
├─ motionIntensity
├─ cameraShakeEnabled
├─ soundEnabled
├─ hapticsEnabled
├─ autoSkipAfter
└─ highContrastFaces
```

`minimal` 또는 `none` 모드 사용자는 즉시 ACK할 수 있다.

그러나 서버는 공개 최소 시간 정책을 적용해 다른 중요 audience의 연출과 규칙 순서를 보호한다.

전투 전체 속도 설정:

```text
cinematic
standard
fast
instant_dm
```

이 설정은 권위 결과가 아니라 연출 길이와 ACK 정책만 바꾼다.

---

## 24. VFX와 UI

권장 화면 구성:

```text
화면 중앙
→ 3D 주사위
→ 선택된 결과 강조

주사위 아래
→ 굴림 이름
→ 수정치와 total

화면 측면 Dice Log
→ 모든 공개 RollRecord
→ 클릭 시 상세 계산 근거
```

예시:

```text
장검 공격
[d20: 17] + 5 = 22
명중
```

피해:

```text
장검 피해
[1d8: 6] + 4 = 10 검격
```

DM 비밀 굴림은 DM 로그에서만 표시한다.

---

## 25. 동시 굴림과 큐

여러 굴림이 동시에 요청될 수 있으므로 클라이언트는 `RollPresentationQueue`를 가진다.

```text
RollPresentationQueue
├─ priority entries
├─ active presentations
├─ maximumConcurrentDice
├─ grouping policy
└─ overflow policy
```

우선순위 예시:

1. 현재 플레이어가 직접 실행한 굴림
2. 현재 대상이 된 내성 굴림
3. 중요한 보스·치명타 굴림
4. 다른 플레이어 굴림
5. 일반 NPC 배치 굴림

큐가 길면 낮은 우선순위 굴림은 compact UI로 묶는다.

규칙 서버는 클라이언트 큐 순서에 의존하지 않고 각 RollRevealGate와 batch policy로 진행한다.

---

## 26. 서버 API 경계

```text
RequestRuleExecution
→ 서버가 RollRequest 생성

RollPresentationCommand
→ 서버에서 클라이언트

RollPresentationAck
→ 클라이언트에서 서버

RollRevealed
→ 서버 내부 RuleEvent

RollRecordPublished
→ 허용 audience 동기화
```

금지:

- 클라이언트가 최종 주사위 값 제출
- 클라이언트가 물리 윗면 제출
- 클라이언트가 명중·실패 여부 제출
- 결과 공개 전 target HP 변경
- ACK가 없으면 무한 대기
- 비밀 결과 seed 전송

---

## 27. 성능

- 주사위 모델은 풀링한다.
- 로컬 프레젠테이션 객체는 서버 Workspace에 복제하지 않는다.
- 일반 NPC 굴림은 필요에 따라 compact group으로 묶는다.
- 주사위 수에 상한을 두고 초과분은 2D 집계로 전환한다.
- 카메라 상대 좌표 갱신은 활성 프레젠테이션에만 수행한다.
- 물리 충돌은 전용 로컬 프레젠테이션 공간 또는 제한된 수의 가상 충돌로 처리한다.
- 결과 계산과 VFX 프레임 루프를 분리한다.

---

## 28. 저장과 감사 로그

RollRecord는 다음을 보존한다.

```text
rollId
sourceExecutionId
rollerActorId
rollKind
rawDice
selectedDice
modifiers
total
visibilityPolicy
revealedAt
resolvedAt
presentationModeSummary
rulesetSnapshot
```

프레젠테이션의 모든 프레임이나 위치를 영구 저장하지 않는다.

오류 진단이 필요할 때만 제한된 presentation diagnostics를 남긴다.

---

## 29. 대표 시나리오

### 시나리오 A: 플레이어 공격

```text
플레이어가 장검 공격 확정
→ 서버 d20 결과 봉인
→ 카메라 가장자리 뒤쪽에서 d20 등장
→ 중앙으로 회전하며 이동
→ 17 면으로 안정화
→ 17 + 5 = 22 공개
→ 명중 확정
→ d8 피해 주사위 연출
→ 피해 공개 후 HP 감소
```

### 시나리오 B: 이니셔티브

```text
전투 시작
→ 참가자 전원 RollRequest
→ 각 플레이어는 자신의 d20 크게 표시
→ 일반 NPC는 compact group
→ 모든 필수 결과 공개
→ 동률 처리
→ InitiativeOrder 한 번에 확정
```

### 시나리오 C: 이점 공격

```text
d20 두 개 등장
→ 각각 7, 16으로 정지
→ 16 강조
→ 수정치 적용
→ 명중 결과 확정
```

### 시나리오 D: 비밀 지각 판정

```text
서버 결과 봉인
→ DM 클라이언트만 연출
→ 플레이어에게 숫자 미공개
→ 실패 또는 성공에 따른 장면 정보만 후속 공개
```

### 시나리오 E: 클라이언트 연결 끊김

```text
굴림 결과 봉인
→ 연출 명령 전송
→ 롤러 연결 끊김
→ ACK 정책 재평가
→ hard timeout 또는 DM audience 완료
→ 결과 공개·규칙 진행
→ 재접속 시 RollRecord 동기화
```

---

## 30. 테스트 요구사항

1. 클라이언트가 원하는 결과를 제출해도 무시한다.
2. 같은 rollId가 두 번 해결되지 않는다.
3. 최소 공개 시간 전 ACK로 결과가 조기 공개되지 않는다.
4. ACK가 없어도 hard timeout 후 진행된다.
5. 결과 공개 전에 이니셔티브 순서가 노출되지 않는다.
6. 공격 결과 공개 전에 명중 후 효과가 실행되지 않는다.
7. 피해 결과 공개 전에 HP가 변경되지 않는다.
8. 이점 두 주사위와 선택 결과가 일치한다.
9. 비밀 굴림 결과가 권한 없는 클라이언트에 전송되지 않는다.
10. 재굴림이 원래 RollRecord를 덮어쓰지 않는다.
11. 연결 끊김 후 전투가 멈추지 않는다.
12. 연출 실패 시 2D fallback으로 결과가 공개된다.
13. 카메라 이동 중 주사위가 화면 중앙을 안정적으로 따른다.
14. 대량 이니셔티브 굴림이 compact mode로 전환된다.
15. 여러 동시 굴림의 우선순위 큐가 규칙 결과를 바꾸지 않는다.
16. 결과 면과 서버 rawDice가 항상 일치한다.
17. 비밀 seed나 목표 면 정보가 비인가 audience에 포함되지 않는다.
18. 이미 공개된 결과가 실행 무효화 후에도 로그에서 변조되지 않는다.

---

## 31. 비목표

이 문서는 다음을 확정하지 않는다.

- 최종 주사위 3D 모델과 텍스처 디자인
- 정확한 비행 시간과 사운드 파일
- 물리 기반과 보간 기반 구현의 최종 비율
- 주사위 스킨 상점 또는 수익화
- 인카운터 시작 UI 전체

이 문서는 주사위 결과, 연출과 규칙 확정 사이의 권위 경계와 상태 순서를 확정한다.