# ADR-0033: 주사위 결과는 서버가 선결정하고 클라이언트 연출 완료 후 규칙 결과를 공개·확정한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0025`](ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0031`](ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md)
  - [`27. 주사위 굴림·연출·결과 확정 모델`](../systems/combat/dice-roll-presentation-and-resolution-gating-model.md)

## 배경

RVTT의 주사위 굴림은 단순한 숫자 생성이 아니라 플레이 경험의 핵심 연출이다.

사용자가 원하는 기본 연출은 다음과 같다.

- 주사위가 클라이언트 카메라 뒤쪽 또는 시야 바깥에서 등장한다.
- 주사위가 화면 중앙 앞으로 날아온다.
- 회전과 충돌 또는 감속 연출 후 결과 면이 보인다.
- 결과가 보인 뒤에야 이니셔티브 순서, 명중 여부, 내성 성공 여부와 후속 효과가 공개·확정된다.

그러나 물리 시뮬레이션 결과를 권위 값으로 사용하면 클라이언트 조작, 기기별 물리 차이, 프레임률과 네트워크 지연 때문에 공정성과 재현성을 보장할 수 없다.

반대로 서버가 결과를 즉시 확정하고 VFX만 나중에 재생하면, 주사위가 아직 굴러가는 동안 이니셔티브 순서나 피해 결과가 먼저 바뀌어 연출과 규칙 상태가 어긋난다.

## 결정

주사위의 권위 결과와 클라이언트 물리 연출을 분리한다.

```text
RollRequest
→ 서버 검증
→ 서버 RNG로 SealedRollResult 생성
→ RollPresentationSession 생성
→ 클라이언트가 결과에 맞춘 주사위 연출
→ reveal 조건 충족
→ RollRecord 공개
→ ResolutionOutcome 생성
→ 후속 규칙 Commit
```

서버는 연출 시작 전에 이미 최종 주사위 값을 알고 있지만, 이를 허용된 클라이언트에 즉시 공개하지 않는다.

클라이언트 주사위는 결과를 결정하는 물체가 아니라 서버 결과를 연출하는 프레젠테이션 객체다.

## SealedRollResult

```text
SealedRollResult
├─ rollId
├─ sourceExecutionId
├─ rollerActorId
├─ rollKind
├─ diceExpression
├─ rawDice[]
├─ selectedDice[]
├─ modifierBreakdown[]
├─ total
├─ outcomeInputs
├─ visibilityPolicy
├─ rngProofMetadata
├─ createdAt
└─ state
```

초기 state:

- `sealed`
- `presenting`
- `revealed`
- `resolved`
- `cancelled_before_reveal`

`sealed` 상태의 원시 주사위와 total은 서버 권위 저장소에만 존재한다.

## RollPresentationSession

```text
RollPresentationSession
├─ presentationId
├─ rollId
├─ audiencePlayerIds[]
├─ presentationProfileId
├─ diceDescriptors[]
├─ startServerTime
├─ revealNotBeforeServerTime
├─ hardTimeoutServerTime
├─ requiredAcksPolicy
├─ receivedAcks[]
├─ skipPolicy
└─ state
```

프레젠테이션 프로필은 다음을 정의한다.

- 카메라 기준 생성 위치
- 카메라 뒤 또는 시야 밖 시작 오프셋
- 화면 중앙 도착점
- 비행 시간
- 회전 속도
- 충돌·바운스 사용 여부
- 결과 면 정렬 방식
- 결과 유지 시간
- 사운드와 진동
- 축약 연출과 접근성 모드

## 결과에 맞춘 연출

클라이언트는 서버가 제공한 결과와 표시 seed를 사용해 주사위가 자연스럽게 굴러 최종 면이 결과와 일치하도록 연출한다.

```text
권위 결과
→ 목표 최종 orientation 계산
→ 시작 위치·회전·비행 궤적 생성
→ 화면 중앙 근처에서 감속
→ 목표 orientation으로 안정화
```

물리 엔진이 우연히 만든 윗면을 서버에 제출하지 않는다.

결과 면 정렬은 마지막 짧은 구간에서 보간할 수 있지만, 플레이어에게 강제 스냅처럼 보이지 않도록 회전 속도와 접촉 연출을 조절한다.

## 공개와 규칙 확정 게이트

규칙 결과는 `RollRevealGate`를 통과하기 전에는 외부 상태에 반영하지 않는다.

```text
RollRevealGate
├─ revealNotBeforeServerTime 도달
├─ 필수 클라이언트 연출 완료 ACK 충족
├─ 또는 hard timeout 도달
└─ 실행이 아직 유효함
```

게이트가 열리면 서버가 다음을 순서대로 수행한다.

```text
SealedRollResult 공개
→ RollRecord 생성 또는 공개 상태 전환
→ ResolutionOutcome 계산
→ 적절한 TimingWindow 개방
→ PendingEffect 생성·수정
→ CommitGroup 확정
```

따라서 이니셔티브는 d20이 화면에 결과를 드러낸 뒤 정렬되고, 공격은 결과 공개 후 명중·빗나감이 결정되며, 피해 주사위는 결과 공개 후 HP를 변경한다.

## 연출 ACK와 타임아웃

클라이언트 ACK는 결과 값이 아니라 `presentation complete` 신호만 포함한다.

클라이언트가 ACK를 보내지 않거나 연결이 끊겨도 규칙 진행이 영구 정지하지 않는다.

- 공개 최소 시간 이전에는 ACK가 와도 공개하지 않는다.
- 필요한 ACK가 모두 오면 최소 시간 이후 즉시 공개할 수 있다.
- ACK가 부족해도 hard timeout이 되면 서버가 강제 공개한다.
- 느린 클라이언트는 이후 결과를 즉시 동기화하고 연출을 축약하거나 생략한다.

DM과 플레이어 전체의 ACK를 모두 필수로 요구하지 않는다. 중요한 공개 대상과 로컬 롤러를 중심으로 정책을 정한다.

## 배치 굴림과 이니셔티브

여러 Actor의 이니셔티브는 `RollBatch`로 묶을 수 있다.

```text
InitiativeRollBatch
├─ participantRollIds[]
├─ presentationMode
├─ revealPolicy
└─ batchResolutionGate
```

지원 모드:

- `sequential_focus`: 한 명씩 중앙에 연출
- `parallel_compact`: 여러 주사위를 동시에 축소 연출
- `local_focus_remote_compact`: 내 주사위는 크게, 다른 참가자는 로그·작은 연출
- `dm_fast_resolve`: DM 선택 시 축약

이니셔티브 순서는 필요한 RollRevealGate가 열린 뒤 한 번에 계산하고 표시한다. 일부 참가자 결과가 아직 봉인된 상태에서 임시 순위를 노출하지 않는다.

## 공격과 피해 굴림

기본 공격 흐름:

```text
공격 선언
→ d20 SealedRollResult
→ 공격 주사위 연출
→ 결과 공개
→ 명중 여부 ResolutionOutcome
→ 명중 시 피해 RollRequest
→ 피해 주사위 연출
→ 피해 공개
→ PendingDamage 확정
```

공격과 피해를 한꺼번에 굴리는 빠른 모드도 지원할 수 있으나, 공격이 빗나갔을 때 피해 숫자를 불필요하게 공개하지 않도록 공개 정책을 분리한다.

## 이점·불리점과 다중 주사위

이점과 불리점은 실제 d20 두 개를 함께 연출할 수 있다.

```text
rawDice: [7, 16]
selectedDice: [16]
```

결과 공개 시 두 주사위 값을 모두 보여주고 선택된 주사위를 강조한다.

피해의 여러 주사위, 재굴림, 폭발 주사위와 드롭 규칙도 `rawDice`, `selectedDice`, `discardedDice`, `rerollRelations`로 표시할 수 있다.

## 비밀 굴림

DM 전용 또는 숨겨진 굴림은 동일하게 서버에서 생성하지만 audience와 공개 정보를 제한한다.

예시:

- DM에게만 전체 주사위 연출과 결과 공개
- 플레이어에게는 주사위 연출 없이 결과 효과만 공개
- 플레이어에게 굴림 발생만 보여주고 숫자는 숨김
- 결과가 규칙상 드러날 때까지 sealed 상태 유지

권한 없는 클라이언트에는 원시 결과, total, 목표 orientation과 결과를 추론할 수 있는 seed를 보내지 않는다.

## 취소와 재검증

연출 중 대상이 사라지거나 실행이 무효화될 수 있다.

- 굴림 자체가 이미 발생한 기록은 감사 로그에 남길 수 있다.
- 결과 적용 전에 실행과 대상 revision을 재검증한다.
- 무효화되면 `cancelled_before_reveal` 또는 `revealed_but_invalidated`로 종료한다.
- 이미 공개한 굴림을 숨기거나 다른 값으로 바꾸지 않는다.

## 빠른 진행과 접근성

플레이어별 프레젠테이션 설정을 지원한다.

- 전체 3D 주사위
- 짧은 3D 주사위
- 2D 숫자 카드
- 애니메이션 최소화
- 화면 흔들림·모션 블러 비활성화
- 자동 스킵

개인 설정이 달라도 서버의 공개 최소 시간과 규칙 확정 순서는 동일하다. 축약 모드 사용자는 즉시 완료 ACK를 보낼 수 있다.

## 서버 권한과 보안

- 서버 RNG만 권위 결과를 생성한다.
- 클라이언트는 주사위 값, total, 선택 주사위와 명중 여부를 제출하지 않는다.
- 동일 rollId는 멱등적으로 한 번만 공개·해결한다.
- 결과와 공개 시점은 서버 시간이 기준이다.
- 클라이언트 ACK 위조는 최소 공개 시간을 앞당길 수 없다.
- hard timeout으로 악의적인 진행 방해를 막는다.
- 롤 기록은 실행 ID, 규칙 버전, 수정치 출처와 RNG 감사 정보를 보존한다.

## 결과

- 카메라 뒤에서 화면 중앙으로 날아오는 주사위 연출을 규칙 결과와 정확히 동기화할 수 있다.
- 주사위가 결과 면을 보여주기 전에 이니셔티브, 명중과 피해가 먼저 확정되는 문제를 막는다.
- 클라이언트 물리 차이와 조작이 실제 결과에 영향을 주지 않는다.
- 느린 기기, 연결 끊김과 연출 스킵에서도 전투가 멈추지 않는다.
- 공개 굴림, 비밀 굴림, 이점·불리점과 배치 이니셔티브를 같은 모델로 처리할 수 있다.