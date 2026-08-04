# Character Action Opportunity와 2024 Core Action Runtime 계약

- 상태: 확정
- 문서 종류: Architecture
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 즉흥 행동 Prompt의 기본 선택지 수
  - 반복 Search·Study 시 결과 재사용 시간
  - 탐험 상태에서 행동 단위 표시를 생략하는 기준
  - DM 판정 대기 알림의 기본 제한 시간
- 작성일: 2026-08-04
- 관련 ADR:
  - [`ADR-0025`](../decisions/ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md)
  - [`ADR-0026`](../decisions/ADR-0026-active-capabilities-action-containers-and-unit-replacements.md)
  - [`ADR-0034`](../decisions/ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0062`](../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md)
  - [`ADR-0067`](../decisions/ADR-0067-2024-core-actions-as-registered-action-capabilities.md)
- 상위 문서:
  - [`Character Runtime 계약`](character-runtime-and-compiled-character-build-contract.md)
  - [`Rule Runtime Orchestrator 계약`](rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Command Ordering과 Transaction Coordinator 계약`](command-ordering-logical-time-and-transaction-coordinator-contract.md)
- 관련 시스템:
  - [`능동형 특성과 행동 내부 실행 모델`](../systems/rules/active-feature-and-action-container-execution-model.md)
  - [`Encounter·Initiative·Turn 모델`](../systems/combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`표준 Recipe Step Library`](../systems/rules/standard-recipe-step-library.md)

## 1. 목적

RVTT는 D&D 2024 5e 기본 규칙의 주요 행동을 캐릭터가 실제로 사용할 수 있도록 지원한다.

공식 기본 행동은 다음과 같다.

```text
Attack
Dash
Disengage
Dodge
Help
Hide
Influence
Magic
Ready
Search
Study
Utilize
```

이 문서는 버튼 목록만 정의하지 않는다. 행동 기회, Capability, RuleExecution, DM 판정 대기, 이동·아이템·효과·주문 시스템의 연결을 하나의 권위 흐름으로 고정한다.

## 2. 핵심 원칙

```text
Character Capability View
+ Encounter ActionOpportunity
+ 현재 규칙 Context
→ 사용 가능한 행동 Projection
→ Player Command
→ RuleExecution
→ Transaction Commit
```

- UI 버튼이 행동의 권위가 아니다.
- 행동 이름을 하드코딩한 거대한 분기문을 만들지 않는다.
- 공식 기본 행동도 등록된 `ActionCapability`다.
- Class, Species, Feat, Spell, Item과 Effect가 추가 행동·대체 행동·제한 행동을 같은 Registry에 기여한다.
- 전투에서는 Action Economy를 소비하고, 탐험에서는 필요할 때만 논리적 행동 단위로 실행한다.

## 3. 역할 구분

### PLAYER_ONLY

- 자신이 제어하는 Actor의 행동을 선언한다.
- Target, 이동 경로, 사용할 Skill·Item·Spell과 Ready Trigger를 선택한다.
- DM 판정이 필요한 행동의 의도와 접근법을 제출한다.

### DM_ONLY

- 즉흥 행동의 가능 여부와 필요한 D20 Test를 판정한다.
- Influence, Help, Search, Study와 Utilize에서 상황상 가능한 접근을 승인·수정한다.
- 비밀 DC, 숨은 결과, 태도 변화와 발견 정보를 확정한다.
- 행동을 강제 실행·취소하거나 Action Economy를 Override한다.

### SHARED

- 공개된 행동 결과와 사용 가능한 행동을 확인한다.
- DM이 Actor를 일반 Controller로 조작할 때는 플레이어와 같은 Command 경로를 사용한다.

### SYSTEM_ONLY

- ActionOpportunity 생성·예약·소비
- Capability 적격성 계산
- Pending DM Adjudication 저장·복구
- TimingWindow, Transaction, Journal과 Projection 생성

## 4. 행동 기회

```text
ActionOpportunity
├─ opportunityId
├─ kind
├─ source
├─ allowedCapabilityPredicates[]
├─ restrictions[]
├─ lifecycleState
├─ reservedByExecutionId?
└─ consumedByExecutionId?
```

기본 종류:

```text
action
bonus_action
reaction
special_action
no_action_required
movement_budget
```

기본적으로 자신의 턴에 Action 하나를 사용한다. Bonus Action은 규칙이 명시적으로 제공할 때만 사용할 수 있고, Reaction은 사용 후 다음 자기 턴 시작까지 다시 사용할 수 없다.

## 5. 공식 기본 행동 계약

### Attack

`ActionContainerCapability`를 사용한다.

- 무기 공격 또는 Unarmed Strike를 실행한다.
- Extra Attack 등으로 여러 공격 Unit을 가질 수 있다.
- 공격 사이 이동을 허용한다.
- 각 공격 전후 규칙이 허용하는 무기 장착·해제를 처리한다.
- Unarmed Strike의 Damage, Grapple, Shove 선택을 지원한다.
- 무기 공격 프로필, Weapon Mastery, 탄약·투척과 Item Transfer를 연결한다.

### Dash

현재 턴의 이동 Budget에 Speed만큼 추가 기여를 생성한다.

```text
Dash Effect
→ current turn movement budget 증가
→ 턴 종료 시 자동 소멸
```

### Disengage

현재 턴 동안 자신의 이동이 Opportunity Attack을 유발하지 않도록 이동 Context Override를 부여한다.

### Dodge

다음 자기 턴 시작까지 EffectInstance를 생성한다.

- 자신에 대한 Attack Roll에 Disadvantage
- Dexterity Save에 Advantage
- Incapacitated이거나 Speed 0이면 이익을 잃는다.

### Help

세 가지 모드를 지원한다.

```text
assist_ability_check
assist_attack_roll
administer_first_aid
```

DM은 실제로 도움을 줄 수 있는 상황인지 최종 판정한다. Attack Help는 유효한 적과 거리 조건을 사용한다. First Aid는 대상 안정화 규칙과 연결한다.

### Hide

Stealth Check, 현재 Obscurement·Cover와 적의 Line of Sight를 검증한다.

성공하면 숨김 EffectInstance와 발견 DC를 저장한다. 공격, 큰 소리, Verbal Component 주문, 적의 발견 등 종료 조건을 Effect Runtime으로 처리한다.

### Influence

자동 NPC 대화 트리를 만들지 않는다.

```text
Player가 목적·접근법·대상 제출
→ DM Adjudication
→ 필요한 Charisma 또는 Animal Handling Check
→ 태도·행동 결과 기록
```

NPC 대화 시스템은 비목표지만, DM이 자유 역할극 중 Influence 판정을 요청하고 결과를 확정하는 행동 보조는 지원한다.

### Magic

다음 Capability를 여는 상위 행동 분류다.

- Spell Cast
- Magic Item Activation
- Magical Feature

Magic이라는 하나의 범용 Recipe를 실행하지 않는다. 실제 Spell·Item·Feature Capability가 자신의 Targeting, 비용, Timing과 Recipe를 가진다.

### Ready

```text
Action 소비
→ perceivable Trigger 정의
→ Action 또는 Speed까지 이동 선택
→ ReadyExecution 저장
→ Trigger 발생 시 Reaction Offer
```

준비한 주문은 선언 시 정상적으로 시전 비용을 지불하고 Concentration으로 유지한다. Trigger가 발생하지 않거나 Concentration이 깨지면 효과 없이 종료될 수 있다.

### Search

Wisdom 기반 탐색 행동이다.

지원 Skill 후보:

```text
Insight
Medicine
Perception
Survival
```

비밀 정보와 DC는 DM Projection에만 유지한다. 발견 결과는 Perception·Fog·Runtime Object Disclosure와 연결한다.

### Study

Intelligence 기반 지식 행동이다.

지원 Skill 후보:

```text
Arcana
History
Investigation
Nature
Religion
```

책, 단서, 기억, 생물과 장치에 대한 지식을 DM이 공개하거나 Rules Content가 알려진 정보를 제공한다.

### Utilize

비마법 물체를 사용한다.

- 문, 레버, 밧줄, 도구와 장치 상호작용
- 상자 열기와 잠금 해제
- 함정 해제 시도
- 깨지기 쉬운 물체 파괴

Magic Item 사용은 Utilize가 아니라 Magic이다. 실제 Object Interaction은 Runtime Object와 Interaction Capability를 사용한다.

## 6. 파생 공통 행동

### Escape Grapple

Grappled Actor가 Action을 사용해 Athletics 또는 Acrobatics Check로 탈출을 시도한다.

### Opportunity Attack

모든 적격 Creature가 가질 수 있는 Reaction Capability다. 보이는 대상이 자신의 Reach를 떠나기 직전에 한 번의 Melee Attack을 제안한다.

### Improvised Action

공식 목록에 없는 행동도 허용한다.

```text
Player Intent
→ DM Adjudication Request
→ 승인 / 수정 요청 / 거부
→ 선택적 D20 Test와 Targeting Plan
→ Assisted 또는 Guided RuleExecution
```

즉흥 행동을 막거나 모든 경우를 사전 버튼으로 만들지 않는다.

### Release Grapple와 단순 의사소통

규칙상 행동 비용이 없는 경우 `no_action_required` Capability 또는 일반 Communication으로 처리한다. Action을 억지로 소비하지 않는다.

## 7. 전투와 탐험

### 전투

- ActionOpportunity와 이동 Budget을 명시적으로 소비한다.
- 행동 사이 이동, 공격 Unit 사이 이동과 Reaction 중단을 지원한다.
- 전투 중 WASD 이동은 허용하지 않고 권위 클릭 경로 이동을 사용한다.

### 탐험

- 같은 Capability와 RuleExecution을 사용한다.
- 턴 UI를 강제하지 않는다.
- 경쟁, 위험, Trigger 또는 시간 압박이 없으면 Action Economy 표시를 간소화할 수 있다.
- 반복 행동의 결과가 변하지 않는 경우 DM이 자동 성공·시간 경과·일괄 판정을 선택할 수 있다.

## 8. 권위 실행 흐름

```text
Action Intent
→ Role·Controller 검증
→ Capability와 Opportunity 조회
→ Targeting·Input 수집
→ Opportunity Reservation
→ 필요 시 DM Adjudication Pending
→ RuleExecution
→ Reaction·TimingWindow
→ CommitGroup
→ Authority Transaction
→ Opportunity 소비
→ Journal·Projection
```

실패하거나 취소되었을 때 Opportunity 소비 여부는 행동별 Cancellation Policy가 정한다.

## 9. Projection과 UI

Player HUD는 다음을 역할별로 구분한다.

- 현재 사용 가능한 기본 행동
- Character Build가 제공하는 Feature·Spell·Item 행동
- Bonus Action
- Reaction 상태
- 이동 가능량
- 제한·불가 사유

DM UI는 추가로 다음을 표시한다.

- 비밀 적격 조건과 DC
- Pending Adjudication
- 강제 승인·거부·수정
- 행동 기회 추가·회수
- 결과 공개 범위

플레이어 UI에 DM 전용 판정과 Override 버튼을 보내지 않는다.

## 10. 저장·재접속·롤백

다음을 저장한다.

- ActionOpportunity State
- 예약·소비 Execution ID
- ActionContainer 진행 상태
- Ready Trigger와 Reaction Offer
- Pending DM Adjudication
- 현재 턴 이동 Budget
- 관련 RuleExecution과 Authority Revision

롤백 시 행동 기회, Ready 상태, Reaction 사용 여부와 공개된 결과를 해당 Checkpoint로 복원한다. 일반 로그는 보존하고 폐기 Branch 표시를 남긴다.

## 11. 자동화 수준

```text
Executable
→ Attack, Dash, Disengage, Dodge와 구조화된 Magic·Utilize

Guided
→ Help, Hide, Ready, Search, Study와 일부 Utilize

Assisted
→ Influence, 자유로운 즉흥 행동, 상황 의존적 Help·Utilize
```

동일 행동도 상황에 따라 자동화 등급이 달라질 수 있다. 엔진이 의미를 모르는 경우 임의 성공이나 임의 실패를 만들지 않고 DM 판정으로 전환한다.

## 12. 비목표

- NPC 대화 트리와 자동 분기 대화 시스템
- 모든 즉흥 행동의 완전 자동화
- UI 버튼을 권위 Capability로 취급
- 행동 이름별 서버 거대 분기문
- DM 판정 없이 숨은 정보와 태도 변화를 자동 공개
