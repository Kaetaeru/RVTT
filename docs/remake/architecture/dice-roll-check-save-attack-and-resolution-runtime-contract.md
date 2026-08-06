# Dice Roll, Check, Save, Attack과 Resolution Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 중요 굴림별 최소 연출 시간과 hard timeout
  - 공개 굴림의 기본 audience ACK 정책
  - 대량 피해 주사위의 3D 표시 최대 개수와 축약 기준
  - 비밀 굴림 결과의 기본 로그 공개 범위
  - RollRecord·SealedRoll Tombstone 보존 기간
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0033`](../decisions/ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0067`](../decisions/ADR-0067-2024-core-actions-as-registered-action-capabilities.md)
  - [`ADR-0068`](../decisions/ADR-0068-2024-spell-casts-as-route-bound-pending-rule-executions.md)
  - [`ADR-0069`](../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md)
- 상위 문서:
  - [`Rule Runtime Orchestrator`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Command Ordering과 Transaction Coordinator`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
  - [`Character Action Runtime`](character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - [`Spell Runtime`](spell-casting-route-and-2024-spell-runtime-contract.md)
- 관련 시스템:
  - [`기존 주사위 굴림·연출·결과 확정 모델`](../systems/combat/dice-roll-presentation-and-resolution-gating-model.md)
  - [`Encounter·Initiative·Turn 모델`](../systems/combat/encounter-initiative-turn-and-control-authority-model.md)

## 1. 목적

이 문서는 RVTT의 모든 규칙 굴림과 결과 판정을 하나의 서버 권위 흐름으로 통합한다.

대상:

- 공격 굴림
- 능력 판정
- 내성 굴림
- 이니셔티브
- 죽음 내성
- 피해·회복·Hit Dice 굴림
- 재충전과 무작위 표 굴림
- 대결 또는 여러 참가자의 Batch 굴림
- Advantage·Disadvantage
- 재굴림, 주사위 교체, 최소값과 보너스 주사위
- 공개·비밀·DM 전용 굴림
- 카메라 뒤에서 화면 중앙으로 날아오는 3D 주사위 연출

핵심 원칙:

```text
클라이언트 물리 결과
≠ 권위 원시 주사위 결과
≠ 규칙상 ResolutionOutcome
```

```text
RuleExecution
→ RollIntent
→ 서버 RollPlan
→ SealedRollResult
→ Presentation Gate
→ RollRecord 공개
→ Outcome Resolution
→ PendingEffect
→ Atomic Commit
```

## 2. 책임 분리

### RollIntent

어떤 규칙 판정을 왜 요구하는지 설명한다. 플레이어가 임의 수정치나 최종 주사위 식을 제출하지 않는다.

### RollPlan

현재 규칙 Snapshot에서 서버가 계산한 실제 주사위 구성, 수정치, 선택·재굴림 정책과 공개 정책이다.

### SealedRollResult

서버가 생성했지만 아직 대상 audience에 공개되지 않은 권위 원시 결과다.

### RollRecord

공개가 허용된 이후 보존되는 불변 굴림 기록이다.

### ResolutionOutcome

RollRecord와 현재 판정 기준을 결합한 명중, 성공, 실패, 치명타, 피해량 등의 규칙 결과다.

### PendingEffect

실제 HP, 상태, 자원과 Encounter를 변경할 후보 결과다. RollRecord 자체가 권위 상태를 직접 수정하지 않는다.

## 3. 공통 흐름

```text
1. Capability 또는 Recipe가 RollIntent 생성
2. 서버가 Actor·Target·Rule Snapshot 고정
3. Advantage·Disadvantage와 Modifier Contribution 수집
4. RollPlan 검증
5. 서버 RNG로 원시 결과 생성
6. SealedRollResult 저장
7. audience별 Presentation 시작
8. Reveal Gate 개방
9. 불변 RollRecord 발행
10. 공격·판정·내성별 OutcomeResolver 실행
11. 반응과 결과 변경 TimingWindow 처리
12. PendingEffect와 CommitGroup 생성
13. Transaction Coordinator가 최종 상태 Commit
```

한 굴림이 공개됐다고 피해나 상태가 즉시 적용되는 것은 아니다. Shield와 같은 반응, 피해 저항, 성공 시 절반 피해처럼 공개 이후에도 규칙 단계가 남을 수 있다.

## 4. RollIntent와 RollPlan

```text
RollIntent
├─ sourceExecutionId
├─ rollPurpose
├─ rollerBinding
├─ targetBindings[]
├─ requestedVisibility
├─ sourceRulePoint
└─ contextBindings
```

```text
RollPlan
├─ rollId
├─ rollKind
├─ diceTerms[]
├─ d20SelectionPolicy?
├─ modifierContributions[]
├─ rerollPolicies[]
├─ replacementPolicies[]
├─ comparisonPlan?
├─ criticalPlan?
├─ visibilityPolicy
├─ presentationPolicy
├─ rulesetSnapshot
├─ revisionSet
└─ idempotencyKey
```

클라이언트는 일반 규칙 실행에서 `1d20+7` 같은 식을 권위 입력으로 보내지 않는다. DM 수동 굴림만 별도 `DM_ONLY` 명령으로 허용한다.

## 5. d20 Test 공통 구조

공격 굴림, 능력 판정과 내성 굴림은 공통 d20 Test 구조를 사용한다.

```text
d20 Test
= 선택된 d20
+ Ability·Proficiency·Expertise Contribution
+ 상황 Modifier
+ Bonus/Penalty Dice
```

`rollKind`는 다음을 구분한다.

```text
attack_roll
ability_check
saving_throw
initiative_check
death_saving_throw
custom_d20_test
```

공통 엔진을 사용하더라도 자연 1·20, 치명타, 죽음 내성처럼 종류별 의미는 각 OutcomeResolver가 소유한다.

## 6. Advantage와 Disadvantage

Advantage와 Disadvantage는 최종 Boolean을 여러 시스템이 직접 덮어쓰지 않는다.

```text
AdvantageContribution[]
DisadvantageContribution[]
→ d20SelectionPolicy
```

기본 정책:

- Advantage 출처가 하나 이상이고 Disadvantage가 없으면 d20 두 개 중 높은 값
- Disadvantage 출처가 하나 이상이고 Advantage가 없으면 낮은 값
- 둘 다 존재하면 개수와 무관하게 상쇄
- 같은 출처의 중복 기여는 출처 ID로 진단 가능

더 많은 d20을 굴리고 하나를 선택하는 특수 규칙은 등록된 Selection Override로 표현한다.

## 7. Modifier와 Bonus Dice

수정치는 출처가 있는 Contribution으로 저장한다.

```text
ModifierContribution
├─ sourceId
├─ rulePointId
├─ value
├─ stackingPolicy
├─ visibilityPolicy
└─ diagnostics
```

Bless, Bardic Inspiration과 Guidance 같은 추가 주사위는 단순 숫자 Modifier와 분리한다.

```text
BonusDieContribution
├─ diceExpression
├─ timingPolicy
├─ optionalUse
├─ resourceCost?
└─ sourceId
```

굴림 전·후 사용 가능 시점은 TimingWindow가 결정한다. 선택적 추가 주사위는 서버가 임의로 자동 소비하지 않는다.

## 8. 재굴림과 교체

재굴림, 주사위 하나 교체, 최소값 보장과 결과 대체를 구분한다.

```text
rawRoll
→ reroll relation
→ replacement relation
→ selected value
→ total
```

RollRecord는 원래 값과 변경 관계를 모두 보존한다.

이미 공개된 주사위를 재굴릴 때 기존 RollRecord를 수정하지 않고 Child RollRecord를 연결한다.

## 9. 공격 굴림 Resolution

```text
Attack RollRecord
+ Target Defense Snapshot
+ Cover·Range·Visibility Context
→ AttackOutcome
```

```text
AttackOutcome
├─ hit
├─ miss
├─ critical_hit
├─ critical_miss_if_ruleset_uses
└─ invalidated_before_resolution
```

공격 판정 흐름:

```text
공격 굴림 공개
→ 명중 후보 계산
→ 명중 전·후 반응 TimingWindow
→ 최종 Defense와 Override 재평가
→ AttackOutcome 고정
→ 피해 Roll 또는 후속 Recipe
```

자연 20과 자연 1의 의미는 공격 OutcomeResolver가 규칙 세트에 따라 처리한다. 공격 RollRecord가 대상 HP를 직접 변경하지 않는다.

## 10. 능력 판정과 내성 굴림

```text
RollRecord
+ DC 또는 Opposed Result
→ CheckOutcome / SaveOutcome
```

DC는 플레이어에게 공개되지 않을 수 있다. 서버는 실제 DC와 판정 근거를 유지하고 audience별 Projection만 제공한다.

지원 결과:

```text
success
failure
success_by_margin
failure_by_margin
partial_success
custom_registered
```

부분 성공이나 Margin은 해당 규칙이 요청한 경우에만 사용한다.

## 11. 피해·회복 굴림

피해와 회복은 d20 Test가 아니라 Value Roll이다.

```text
DamageRollPlan
├─ damageComponents[]
├─ criticalExpansionPolicy
├─ rerollPolicies[]
└─ visibilityPolicy
```

각 Damage Component는 타입과 출처를 유지한다.

```text
무기 기본 피해
+ 능력치
+ Smite
+ Sneak Attack
+ Magic Item 추가 피해
→ 개별 PendingDamage Component
```

저항·면역·취약성, 피해 감소와 임시 HP는 주사위 결과 생성 단계가 아니라 Damage Resolution 단계에서 처리한다.

회복도 동일하게 RollRecord와 Healing PendingEffect를 분리한다.

## 12. Batch와 동시 굴림

Fireball 내성처럼 여러 대상이 같은 실행에서 굴릴 수 있다.

```text
RollBatch
├─ sharedExecutionId
├─ memberRollIds[]
├─ orderingPolicy
├─ revealPolicy
└─ completionPolicy
```

각 대상은 독립 RollRecord를 가지며, Batch Presentation으로 묶어 보여줄 수 있다.

모든 대상의 클라이언트 ACK를 기다리지 않는다. 서버 Reveal Gate와 hard timeout이 진행을 보장한다.

## 13. Initiative

이니셔티브는 능력 판정 계열 RollPlan을 사용하지만 결과는 Encounter Ordering 후보로만 전달한다.

```text
Initiative RollRecord
→ InitiativeEntryCandidate
→ 모든 필수 결과 공개
→ Tie Break
→ Initiative Order Commit
```

주사위 연출이 끝나기 전 이니셔티브 순서를 확정하지 않는 기존 사용자 경험을 유지한다.

## 14. 죽음 내성

죽음 내성은 전용 OutcomeResolver를 사용한다.

- 자연 1의 실패 증가
- 자연 20의 회복
- 일반 성공·실패 누적
- 안정화와 사망 후보

실제 죽음 내성 상태 변경은 RollRecord 공개 후 PendingEffect와 Transaction으로 확정한다.

## 15. 비밀 굴림과 Projection

```text
Authority RollRecord
→ Visibility Policy
→ Audience별 Roll Projection
```

공개 수준:

```text
full_breakdown
result_and_total
outcome_only
roll_occurred_only
hidden
```

비밀 Perception, Search와 Study 굴림은 DM만 원시 값·DC·숨은 결과를 볼 수 있다. 플레이어에게는 DM이 공개한 결과만 보낸다.

비밀 굴림의 trajectory seed, 결과 면과 Modifier Breakdown을 권한 없는 Client에 보내지 않는다.

## 16. Presentation Gate

서버는 결과를 먼저 생성하고 봉인한다.

```text
sealed
→ presentation_dispatched
→ presenting
→ reveal_ready
→ revealed
→ resolved
```

Reveal 조건:

```text
minimumServerTimeSatisfied
AND (requiredAckPolicySatisfied OR hardTimeoutReached)
AND executionStillValidForReveal
```

연출 실패, 스킵, 저사양 모드와 연결 끊김 때문에 규칙 실행이 영구 정지하지 않는다.

## 17. 3D 주사위 프레젠테이션

주사위는 각 Client의 카메라 전용 Presentation Layer에 생성한다.

```text
카메라 뒤에서 온 것처럼 화면 가장자리 진입
→ 화면 중앙으로 비행·회전
→ 서버 결과 면으로 제어된 정착
→ Reveal
```

물리 시뮬레이션은 시각 효과일 뿐이다. 마지막 면은 서버 결과에 맞춰 정렬한다.

많은 피해 주사위는 성능 기준에 따라 일부 3D 주사위와 축약된 총합 UI를 함께 사용할 수 있다.

## 18. 결과 공개와 상태 Commit 분리

다음 세 시점을 구분한다.

```text
Roll Generated
→ Roll Revealed
→ Resolution Committed
```

- Generated: 서버만 결과를 앎
- Revealed: 허용 audience가 굴림을 앎
- Committed: 피해·상태·자원 등 권위 결과가 적용됨

공개된 굴림 이후 반응 때문에 최종 결과가 바뀔 수 있지만 공개 RollRecord 자체를 지우거나 다른 값으로 바꾸지 않는다.

## 19. 저장·재접속·롤백

저장 대상:

- RollPlan Snapshot
- SealedRollResult 또는 RollRecord
- Roll 상태와 Reveal Gate
- audience 공개 상태
- Reroll·Replacement 관계
- 연결된 RuleExecution
- 미해결 Outcome과 TimingWindow

재접속한 플레이어는 자신의 공개 범위에 맞는 현재 상태를 받는다. 진행 중 연출은 축약 재생하거나 결과 화면부터 이어갈 수 있다.

Rollback은 새 AuthorityEpoch에서 과거 Roll·Execution 상태를 복원한다. 폐기된 Branch의 RollRecord는 감사 기록으로 남지만 현재 Branch 결과로 재사용하지 않는다.

## 20. 역할 구분

### PLAYER_ONLY

- 자신의 굴림 실행 의도 제출
- 선택 가능한 Bonus Die·Reroll 사용 여부 결정
- 공개 연출 스킵
- Reaction과 결과 변경 Offer 수락·거절

### DM_ONLY

- 수동 공개·비밀 굴림 생성
- 굴림 공개 범위 지정
- 비밀 DC와 Modifier 확인
- 규칙상 허용된 Override·재굴림·결과 판정
- 오류 복구를 위한 Roll 무효화와 재실행

DM Override는 기존 RollRecord를 몰래 덮어쓰지 않고 별도 감사 관계를 남긴다.

### SHARED

- 허용된 Roll Projection 확인
- 공개 결과와 Outcome 확인
- 공개된 Breakdown과 출처 확인

### SYSTEM_ONLY

- RollPlan 구성
- 서버 RNG와 결과 봉인
- Reveal Gate와 Timeout
- Outcome Resolution
- PendingEffect·CommitGroup 생성
- Journal·Persistence·Rollback 처리

## 21. 실패 코드 예시

```text
ROLL_INTENT_INVALID
ROLL_SOURCE_STALE
ROLL_PLAN_INVALID
ROLL_ALREADY_EXISTS
ROLL_PRESENTATION_TIMEOUT
ROLL_REVEAL_NOT_ALLOWED
ROLL_EXECUTION_INVALIDATED
ROLL_RESOLUTION_FAILED
ROLL_VISIBILITY_DENIED
ROLL_OVERRIDE_NOT_ALLOWED
```

## 22. 비목표

- Client Physics를 RNG로 사용하지 않는다.
- 플레이어가 일반 실행에서 수정치와 주사위 식을 임의 제출하지 않는다.
- 모든 audience ACK를 기다리지 않는다.
- 공개된 RollRecord를 결과에 맞춰 사후 변경하지 않는다.
- RollService가 HP, Inventory, Effect와 Encounter Store를 직접 수정하지 않는다.
