# Main System Guide: Rules, Character Action, Spell, Dice와 Effect

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 캐릭터·아이템·효과가 제공하는 규칙 Capability를 사용자가 행동과 주문으로 선언하고, 서버가 현재 Ruleset Policy와 Action Opportunity를 검증하며, 굴림·반응·효과 해결을 거쳐 권위 상태를 원자적으로 확정하고, 지속 효과가 종료될 때까지 관리하는 전체 흐름을 설명한다.

사용자에게 보장하는 결과:

- 기본 규칙 세트와 Source Pack·Campaign·Scope 설정은 결정적으로 합성된 Frozen Policy Snapshot으로 고정된다.
- 진행 중 Encounter·Downtime·RuleExecution은 생성 당시 Policy Snapshot을 유지하며 실행 중 최신 설정으로 조용히 바뀌지 않는다.
- Character, Item과 Effect가 제공하는 규칙 기능은 Capability와 타입 있는 Contribution으로 구성되며 UI 버튼이나 표시 이름이 권위 원본이 아니다.
- Attack, Dash, Disengage, Dodge, Help, Hide, Influence, Magic, Ready, Search, Study와 Utilize를 등록된 ActionCapability로 취급한다.
- Encounter는 행동 자체를 제공하지 않고 ActionOpportunity와 이동 Budget을 제공한다.
- Exploration에서도 같은 Capability와 RuleExecution을 사용하되, 규칙상 필요한 경우에만 행동 단위·정지·DM 판정을 요구한다.
- 같은 주문을 직업 슬롯, 무료 시전, 아이템 충전, 임시 효과와 Ritual 등 허용된 SpellCastRoute로 선택할 수 있다.
- 주문 접근·준비·시전 경로와 실제 슬롯·충전·재료 상태를 서로 다른 권위 계층으로 유지한다.
- 시전 가능성을 만들기 위해 무기·방패·장비를 자동으로 해제하거나 옮기지 않는다.
- 선택과 영역 Preview는 설명용이며 서버가 최신 Snapshot에서 Target·Range·Visibility·Line of Effect를 다시 검증한다.
- 반응 주문과 Trigger Feature는 임의 버튼으로 언제든 실행하지 않고 RuleEvent가 연 TimingWindow의 Capability Offer를 통해서만 실행한다.
- 공격, 주문, Feature, Item, Hazard와 상호작용이 공통 RuleExecution 상태기계와 Recipe Runtime을 사용한다.
- 비용은 먼저 예약하고 규칙상 확정 시점에 소비하며, 취소·검증 실패·실행 실패 정책에 따라 반환하거나 별도 검토한다.
- 주사위 원시 결과는 서버가 생성하고 봉인하며 Client의 3D 주사위 물리 결과를 RNG로 사용하지 않는다.
- Roll Generated, Roll Revealed와 Resolution Committed를 구분한다.
- 공개된 RollRecord는 후속 반응으로 결과가 달라져도 사후에 다른 값으로 덮어쓰지 않는다.
- 피해·회복·상태·자원·강제 이동·Runtime Object 변경은 즉시 Store를 수정하지 않고 PendingEffect와 CommitGroup을 거친다.
- 하나의 CommitGroup은 부분 성공하지 않으며 권위 Revision과 Client Projection은 Commit 이후에만 공개한다.
- 지속 효과, Condition, 집중, 변신, Aura, 지속 영역과 소환은 EffectRegistry가 소유하는 EffectInstance로 관리한다.
- EffectInstance는 Character·Actor·Encounter에 복사되지 않고 필요한 Reference와 파생 Contribution View만 제공한다.
- Suppression은 Effect 종료와 다르며 여러 억제 원인을 독립적으로 유지한다.
- 새 집중 효과 시작, 기존 집중 효과 종료와 새 Effect 활성화는 하나의 원자적 Transaction으로 처리할 수 있다.
- Reaction·Guided Input·DM Adjudication을 기다리는 실행은 저장 가능한 Pending Execution이며 열린 Remote 호출에 의존하지 않는다.
- 재접속·서버 복구 후 이미 Commit된 효과나 비용을 다시 적용하지 않는다.
- Rollback은 현재 실행을 역실행하지 않고 과거 Snapshot을 새 Branch·AuthorityEpoch에서 복원한다.
- 이전 Epoch의 Command, Prompt, Offer, Reservation, Timer와 Presentation ACK를 새 Branch에 적용하지 않는다.

적용 범위:

- Ruleset Policy Family·Implementation·Merger Registry
- Ruleset·Source Pack·Campaign·Scope Policy Composition과 Frozen Snapshot
- Character·Item·Effect의 Grant, Capability와 Modifier·RuleOverride Contribution
- 2024 Core Action과 ActionOpportunity·Usage Gate
- ActionContainer, Feature·Trigger와 다른 턴의 실행
- RuleExecution Identity·상태기계·부모·자식 실행
- Cost Reservation, Pending Input, TimingWindow와 Capability Offer
- EffectRecipe·표준 Step Runtime·BindingStore·Step Handler
- SpellDefinition, CompiledSpellBuild, SpellCastRoute와 SpellCastExecution
- Spell Resource·Payment, Verbal·Somatic·Material Component와 실제 Inventory 재료
- Targeting·Area·Frozen Binding과 Spell Attack·Save·자동 효과
- Ritual, Ready Spell, Reaction Spell과 장시간 시전
- RollIntent, RollPlan, SealedRollResult, RollRecord와 ResolutionOutcome
- Attack·Check·Save·Initiative·Death Save·Damage·Healing·Batch Roll
- Presentation Gate와 audience별 Roll Projection
- PendingEffect·CommitGroup과 원자적 Transaction
- CompiledEffectBuild, EffectRegistry, EffectInstance와 Contribution View
- Duration, End Condition, Stacking, Concentration, Suppression과 Form Overlay
- 저장·재접속·서버 Recovery·Rollback·Projection과 진단

명시적 비범위:

- Character 성장 Source, 레벨업, 준비 주문 변경과 영구 상태 Migration의 전체 흐름
- Encounter Timeline, Initiative Cursor, Turn 진행, Objective와 Encounter 종료의 전체 흐름
- Inventory·Equipment·ItemInstance와 World Presence의 전체 수명주기
- 개별 공식 주문·Feature·Feat·Item·Monster 능력의 실제 콘텐츠 데이터
- 모든 즉흥 행동과 모든 공식 콘텐츠의 완전 자동화
- HUD, Character Sheet, Dice UI와 Effect Icon의 구체적인 배치
- Camera, VFX, Token Motion과 3D Dice Animation의 내부 구현
- 실제 Roblox Module 경로와 최종 Luau Type 이름
- Runtime Budget, Timeout, Cache와 Presentation 시간의 측정형 기본값
- NPC 자동 대화 트리와 대화 AI
- 음악과 규칙 효과음

## 2. 전체 구조

### Policy와 콘텐츠 기반

```text
Ruleset Policy Pack
+ Source Pack Patch
+ Campaign·Scope Policy Binding
→ Candidate Policy Compile
→ Immutable Frozen Policy Snapshot
→ Domain Policy View
→ Execution Effective Policy View
```

```text
Character Progression Source
+ Item Definition·Item State
+ Active EffectInstance
→ Grant Graph·Capability Compiler
→ Character Capability View
+ Modifier·RuleOverride·Trigger Contribution
```

Policy는 여러 실행에 공통으로 적용할 규칙 방식과 제약을 제공한다. Capability와 Contribution은 특정 Character·Item·Effect가 현재 사용할 수 있는 기능과 실행 문맥 수정만 제공하며 Campaign Policy Snapshot을 다시 쓰지 않는다.

### 선언부터 권위 확정까지

```text
Semantic Intent
+ Frozen Selection Binding
+ Controller·Role
+ ActionOpportunity
+ Execution Effective Policy View
→ Capability Validation
→ RuleExecution
→ Cost Reservation
→ Recipe·Step Runtime
→ Roll·Outcome·TimingWindow
→ PendingEffect·CommitGroup
→ Authority Transaction
→ Journal·Domain Event·Projection
```

### 지속 효과

```text
Effect Definition Source
→ Effect Compiler
→ Immutable CompiledEffectBuild

RuleExecution·DM Command·Environment Trigger
→ PendingEffectCreation
→ Application·Stacking·Concentration Transaction
→ Authoritative EffectInstance
→ Modifier·Capability·Trigger·Runtime Object Contribution
→ Duration·End Condition
→ Ending Transaction
→ Tombstone·EndRecord·Projection
```

### 표현과 공개

```text
Authority RuleExecution·RollRecord·EffectInstance
→ Role·Disclosure·Perception Policy
→ Client-safe Projection
→ ViewModel·HUD·Prompt·Dice Presentation·Effect Presentation
```

UI와 Presentation은 Intent를 만들고 권위 결과를 표현한다. Client Animation, Dice Physics, Tooltip과 상태 아이콘 목록은 권위 원본이 아니다.

## 3. 주요 데이터 흐름

### 3.1 Policy Source에서 Effective Policy View까지

```text
Policy Family·Implementation Registry
+ Ruleset Policy Pack
+ Source Pack Policy Patch
+ Campaign·Scene·Encounter·Downtime Binding
→ 정적 Schema·Compatibility·Conflict 검증
→ Frozen Scope Policy Snapshot
+ Character·Item·Effect Rule Contribution
→ Execution Effective Policy View
```

저장 원본:

- Policy Pack과 Source Pack Patch
- Campaign·Scope Policy Binding
- Frozen Snapshot Identity·Hash·Version
- DM Override의 Scope·Reason·Expiry와 Audit Metadata

파생 데이터:

- Domain Policy View
- Execution Effective Policy View Cache
- Composition Trace와 UI 설명 View

Policy Evaluator는 권위 Store를 직접 변경하지 않는다. 실제 Mutation은 Domain Command, RuleExecution과 Transaction이 수행한다.

### 3.2 Grant와 Capability

```text
획득 출처 Definition
+ Character Progression Source
+ 저장된 Choice·Exceptional Grant
→ Grant Graph Resolver
→ ResolvedGrant
→ Capability Compiler
→ Character Capability View
```

저장하는 것:

- Species·Background·Class Level·Subclass·Feat 선택
- 선택형 Grant와 교체 기록
- 주문 습득·준비·교체 기록
- DM Exceptional Grant
- ItemInstance와 활성 EffectInstance

파생하는 것:

- 고정 Feature와 ResolvedGrant
- 현재 Action·Trigger·Spell Access·Passive Capability
- 최종 Derived Value와 Context Modifier 합계
- 현재 UI에 공개할 Action Projection

표시 이름이나 Character Sheet의 버튼 목록을 Capability 저장 원본으로 사용하지 않는다.

### 3.3 Recipe Source와 Runtime

```text
EffectRecipe Definition
+ StepDefinition Registry
+ 신뢰된 StepHandler Registry
→ Recipe Compiler
→ Immutable CompiledRecipe
→ RuleExecution BindingStore
→ Step 실행 결과
→ Roll·PendingInput·TimingWindow·PendingEffect
```

`BindingStore`는 한 RuleExecution 범위의 타입 있는 Blackboard다. Child Execution은 별도 BindingStore를 가지며 허용된 Typed Import·Export만 부모와 공유한다.

저장하지 않는 것:

- 임의 Roblox Instance
- Client Presentation 결과
- 제한 없는 자유 형식 Table
- Step Handler 내부 Coroutine 상태

### 3.4 Spell Source, Build, Route와 State

```text
SpellDefinitionSource
→ Spell Compiler
→ Immutable CompiledSpellBuild

Character Spell Acquisition·Preparation
+ Source Spellcasting Profile
+ Feature·ItemInstance
→ SpellCastRoute

SpellCastRoute
+ Resource·Equipment·Effect·Opportunity State
→ SpellCastOption Projection
```

`SpellDefinition`과 `CompiledSpellBuild`에는 현재 슬롯, 준비 상태, Item Charge와 시전자 수치를 넣지 않는다. `SpellCastRoute`도 실제 Resource State를 복사하지 않는다.

### 3.5 Roll 데이터

```text
RollIntent
→ RollPlan
→ SealedRollResult
→ audience별 Reveal Gate
→ Immutable RollRecord
→ OutcomeResolver
→ ResolutionOutcome
→ PendingEffect
```

- `RollPlan`: 서버가 계산한 주사위, Modifier, Selection, Reroll과 공개 정책
- `SealedRollResult`: 생성됐지만 아직 공개되지 않은 원시 결과
- `RollRecord`: 공개 이후 보존하는 불변 굴림 기록
- `ResolutionOutcome`: 명중·성공·실패·치명타·Margin 등 규칙 결과

RollRecord가 HP, 상태, 자원이나 Encounter Store를 직접 수정하지 않는다.

### 3.6 Effect 데이터

```text
EffectDefinitionSource
→ CompiledEffectBuild
→ EffectInstanceState
→ Derived Contribution View
```

저장 원본:

- EffectInstance Identity·Incarnation·Revision
- Source·Owner·Controller·Target·Anchor Binding
- Frozen Parameter
- Duration·End Condition·Stacking·Concentration·Suppression State
- Parent·Child·Owned Runtime Object Reference
- Tombstone과 EndRecord

재생성하는 것:

- 최종 Modifier 합계
- 활성 Capability 복사본
- Trigger Candidate Cache
- Effect Icon 집계
- VFX·Tween·Camera 상태

## 4. 주요 실행 흐름

### 4.1 행동 목록과 Capability Projection

```text
Character Capability View
+ ActionOpportunity
+ Base Mode·Context
+ Resource·Item·Effect State
+ Disclosure Policy
→ 사용 가능한 Action·Feature·Spell·Item Option
→ Player·DM별 Action Projection
```

전투에서는 Action, Bonus Action, Reaction, Special Action, Movement Budget와 `no_action_required` Opportunity를 명시적으로 사용한다. 탐험에서는 같은 Capability를 사용하되 Action Economy가 필요하지 않은 상황의 UI를 단순화할 수 있다.

### 4.2 일반 Character Action

```text
Player Action Intent
→ Role·Controller 검증
→ ActionCapability·Usage Gate 조회
→ Target·Option·Path Selection
→ Frozen Selection Binding
→ ActionOpportunity Reservation
→ RuleExecution 생성
→ Recipe 실행
→ TimingWindow·Roll·PendingEffect
→ CommitGroup
→ Opportunity·Resource 소비와 상태 Transaction
→ Journal·Projection
```

실패 또는 취소 시 Opportunity 소비 여부는 해당 Capability의 Cancellation Policy가 결정한다.

### 4.3 Attack Action과 ActionContainer

```text
Attack ActionCapability
→ ActionContainer 생성
→ Attack Unit 수와 무기·Unarmed Strike 후보 계산
→ 각 Unit의 Target·Weapon 선택
→ Attack Roll RuleExecution
→ AttackOutcome
→ Damage Recipe
→ 공격 사이 Movement와 허용된 장비 전환
→ Container 종료
```

Extra Attack과 유사한 규칙은 UI가 공격 버튼을 복제하는 방식이 아니라 Capability와 ActionContainer의 Unit Capacity에 기여한다.

### 4.4 Guided·Assisted Action과 DM Adjudication

```text
Help·Influence·Search·Study·Utilize·Improvised Intent
→ 구조화된 Capability·Context 검증
→ Guided Input 또는 DM Adjudication Request
→ 저장 가능한 waiting_input 상태
→ DM Projection
→ 승인·수정·거절 또는 D20 Test 선택
→ 동일 RuleExecution 재개
→ 결과 Commit 또는 안전 종료
```

자유 텍스트는 참고 설명일 뿐 임의 Script나 무제한 PendingEffect가 아니다. 기계적 결과는 등록된 Schema와 Capability·Recipe를 사용한다.

### 4.5 주문 후보와 Cast Route 선택

```text
Character Capability View
+ SpellCastRoute[]
+ ActionOpportunity
+ Resource·Inventory·Equipment·Effect State
→ SpellCastOption[]
→ Route·Cast Level·Payment·Mode 선택
```

같은 주문이라도 Route별로 시전 능력치, 준비 요구, 슬롯·무료 시전·Item Charge, Component 면제와 Cast Level 정책이 다를 수 있다.

### 4.6 주문 시전

```text
Spell Cast Intent
→ Route·Access·Preparation 검증
→ Casting Time·Opportunity·턴당 Slot Gate 검증
→ Verbal·Somatic·Material Component 검증
→ Resource·Material Reservation
→ Targeting Plan과 Client Preview
→ 서버 Frozen Target Binding
→ SpellCastExecution RuleExecution
→ Attack·Save·Automatic Effect Recipe
→ Reaction TimingWindow
→ PendingEffect·CommitGroup
→ Resource 소비·Effect 활성화 Transaction
```

Client는 슬롯 소비, Component 충족, 대상 적격, 최종 피해와 성공 여부를 확정하지 않는다.

### 4.7 Ritual과 장시간 시전

```text
Ritual 또는 minutes_or_hours Cast 선택
→ 적격 Route·Ritual Tag 검증
→ LongCastExecution 생성
→ 반복 Magic Action·Concentration Channel 유지
→ Scheduler·논리 시간 Progress
→ 중단 조건 검사
→ 완료 시 Resource·Material·Effect Commit
```

Ritual은 별도 주문 복사본이 아니라 Route의 시전 모드다. 중단되면 권위 Progress 정책에 따라 종료하고 임의로 완료 처리하지 않는다.

### 4.8 Ready Action과 Ready Spell

일반 Ready:

```text
Action 소비
→ Perceivable Trigger 정의
→ Action 또는 Movement 선택
→ ReadyExecution 저장
→ Trigger Event
→ Reaction Offer
→ Release 또는 Pass
```

Ready Spell:

```text
Action 시전 주문 선택
→ 준비 시 정상 시전·비용 처리
→ Held Spell EffectInstance
→ Concentration 유지
→ Trigger 발생
→ Reaction Offer
→ Release 또는 종료
```

Ready Spell은 Trigger 시점에 새로 시전하거나 슬롯을 다시 소비하지 않는다.

### 4.9 Roll 생성과 공개

```text
Recipe·Capability가 RollIntent 생성
→ 서버가 Actor·Target·Policy Snapshot 고정
→ Advantage·Disadvantage·Modifier·Bonus Die 수집
→ RollPlan 검증
→ 서버 RNG로 SealedRollResult 생성
→ audience별 Dice Presentation Signal
→ Minimum Time + ACK Policy 또는 Hard Timeout
→ RollRecord Reveal
```

3D 주사위는 서버 결과를 표현한다. 물리적으로 어떤 면에 멈췄는지를 서버 판정에 사용하지 않는다.

### 4.10 Outcome Resolution

```text
RollRecord
+ Attack Defense·DC·Comparison·Critical Policy
+ Context Modifier·RuleOverride
→ ResolutionOutcome 후보
→ 결과 변경 TimingWindow
→ 최종 Outcome 고정
→ Damage·Healing·Condition·Resource PendingEffect
```

공격, 능력 판정, 내성, 이니셔티브와 죽음 내성은 공통 d20 기반을 공유하지만 종류별 의미는 각 OutcomeResolver가 소유한다.

### 4.11 TimingWindow와 Reaction

```text
RuleEvent
→ Trigger Index 후보 조회
→ Grant·Usage·Role·Disclosure Filter
→ 결정적 Capability Offer 정렬
→ mandatory auto 처리와 optional Offer 분리
→ use | pass | delegate_to_dm 응답
→ Child RuleExecution
→ 부모 결과 기여
→ 부모 실행 재개
```

긴 입력 대기 중 Ordering Lock을 유지하지 않는다. Reservation과 Revision Token을 보존하고, 재개 시 최신 Snapshot을 다시 검증한다.

### 4.12 비용 예약과 소비

```text
Capability Declaration
→ Action·Reaction·Slot·Charge·Usage·Material Reservation
→ 실행 진행
→ CostCommitPolicy의 시점 도달
→ 상태 변경과 같은 CommitGroup 또는 명시적 선행 Commit
```

예약은 소비가 아니다. 선언 취소·검증 실패·안전 실패 시점과 규칙에 따라 반환한다. 규칙상 이미 시전·사용이 확정된 뒤 효과가 무효가 되었다는 이유만으로 자동 환불하지 않는다.

### 4.13 Recipe와 표준 Step

```text
CompiledRecipe
→ Step Runtime
→ Typed Binding Input 검증
→ 신뢰된 StepHandler 실행
→ Continue | Branch | Suspend | Fail
→ Binding Output Seal
→ 다음 Step 또는 Commit 준비
```

Step Handler는 다음만 생성한다.

- 타입 있는 Output
- Roll 요청
- PendingInput
- TimingWindow 요청
- PendingEffect
- Presentation 요청
- 구조화된 진단

Step Handler가 HP, Resource, EffectRegistry, Runtime Object와 DataStore를 직접 변경하지 않는다.

### 4.14 PendingEffect와 원자적 Commit

```text
Recipe·Child Execution의 PendingEffect 수집
→ 의존 관계와 동시 해결 그룹 확인
→ Passive Modifier·RuleOverride 적용
→ before_effect_commit TimingWindow
→ 최신 대상·Revision 재검증
→ CommitGroup과 비용 정산 구성
→ Transaction Coordinator
→ State Mutation + Journal + Outbox
→ Authority Revision 공개
```

하나의 CommitGroup은 일부만 성공하지 않는다. 여러 CommitGroup이 필요한 실행은 각 Group이 권위 문서에 정의된 독립 확정 경계여야 한다.

### 4.15 Effect 활성화

```text
PendingEffectCreation
→ CompiledEffectBuild·Schema 검증
→ Source·Target·Anchor·Incarnation 검증
→ 면역·적격성·Stacking 평가
→ Concentration Reservation
→ EffectInstanceId와 Owned Runtime Object Plan 예약
→ Contribution·Cleanup Plan 구성
→ 원자적 Transaction
→ EffectActivated Event·Projection
```

기존 집중 효과 종료, 새 Effect 생성, Resource 소비와 Runtime Object Spawn이 한 규칙 결과라면 같은 Commit Graph에서 처리한다.

### 4.16 Effect 기여와 Query

```text
Active EffectInstance
→ Compiled Modifier·Capability·Trigger Contribution
→ Character·Actor·Scene Context Resolver
→ Derived Value·Capability·Rule Event View
```

Effect가 Character의 AC, Speed, Action 목록과 Sense 값을 직접 덮어쓰지 않는다. Query 결과는 출처와 Revision을 유지해 설명·진단·무효화할 수 있어야 한다.

### 4.17 Duration, Concentration과 종료

```text
Turn·Round Boundary 또는 Game Time Deadline
→ Duration Scheduler의 만료 후보
→ 최신 End Condition 재검증
→ EndEffect Transaction
→ Contribution 제거·Child·Owned Object Cleanup
→ EffectEnded Event·Tombstone·Projection
```

피해로 인한 집중 검사는 `DamageApplied` Commit 이후 별도 Child RuleExecution으로 시작한다. 실패 결과가 Commit되면 Concentration Root와 연결된 Effect Graph를 결정적 순서로 종료한다.

### 4.18 Stacking과 Suppression

```text
새 Effect 후보
+ 기존 EffectInstance의 StackingIdentity
→ Stacking Policy
→ 독립 유지 | 교체 | Duration 갱신 | Contribution 억제 | 거부
```

```text
Suppression Source 추가·제거
→ Suppression Plan 평가
→ Contribution·Duration·Concentration·Owned Object 상태 계산
→ Transaction
```

낮은 효과가 현재 적용되지 않는다는 이유로 EffectInstance를 삭제하지 않는다. Suppression Source 하나가 사라져도 다른 원인이 남으면 재활성화하지 않는다.

### 4.19 취소·거부·안전 실패

사용자 취소:

```text
규칙상 취소 가능 단계
→ Prompt·Offer 닫기
→ Child 취소 전파
→ Reservation 반환 정책
→ 비권위 Presentation 정리
→ cancelled Terminal Summary
```

검증 거부:

```text
Capability·Target·Cost·Opportunity 조건 실패
→ rejected
→ 기존 권위 상태 변경 없음
```

안전 실패:

```text
Handler·Provider 오류 또는 Budget 초과
→ 미Commit PendingEffect 폐기
→ Reservation 반환 또는 DM Recovery
→ 이미 Commit된 Group 보존
→ failed_safe + Trace·RecoveryRecord
```

Presentation 실패는 기본적으로 RuleExecution 실패가 아니다.

### 4.20 재접속과 서버 Recovery

```text
Snapshot + Commit Journal 복구
→ Frozen Policy·Build Hash 확인
→ Pending RuleExecution Directory 복원
→ BindingStore·Reservation·Roll·PendingEffect 복원
→ 이미 Commit된 Group 확인
→ TimingWindow·PendingInput·EffectRegistry 재구성
→ 새 Execution Incarnation 필요 여부 결정
→ 사용자별 Projection 재생성
→ 원래 대기 지점 또는 안전 경계에서 재개
```

Client의 로컬 Prompt 선택, Dice Animation 진행률, UI Button 상태와 VFX를 권위 복구 원본으로 사용하지 않는다.

### 4.21 Rollback

```text
DM이 과거 Checkpoint 선택
→ 새 Branch·AuthorityEpoch 활성화
→ 해당 시점의 Policy Ref·RuleExecution·Roll·Effect Snapshot 복원
→ 현재 Branch Prompt·Offer·Command·Timer 무효화
→ Derived Capability·Contribution·Projection 재구성
→ Client Full Resync
```

폐기 Branch의 RollRecord와 실행 Trace는 감사 기록으로 보존할 수 있지만 현재 Branch 결과로 재사용하지 않는다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 신뢰된 Registry, Snapshot Query, Command Mutation과 Projection 불변식
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Source·불변 Build·버전된 State와 활성 Reference 분리
- [`Character Runtime과 Compiled Character Build 계약`](../../architecture/character-runtime-and-compiled-character-build-contract.md) — Character Source·Build·State와 Capability View 기반
- [`Selection, Targeting, Preview와 Frozen Binding Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md) — Action·Spell 실행 전 대상 고정과 Revision 증거
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Reservation, Commit Graph, 원자적 Mutation과 Journal
- [`Persistence와 Session Recovery 모델`](../../architecture/persistence-and-session-recovery-model.md) — Pending Execution·Snapshot·Journal·AuthorityEpoch 복구

### Child Authority

- [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — 전역·Scope Policy 합성과 실행 Snapshot 고정
- [`규칙 콘텐츠 Grant Graph와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md) — 획득 출처에서 Capability View까지의 파생 모델
- [`패시브 특성, Modifier와 Rule Override 모델`](../../architecture/passive-modifier-and-rule-override-model.md) — Derived Value, Context Modifier와 RulePoint 기여
- [`Character Action Opportunity와 2024 Core Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md) — 기본 행동, Opportunity, ActionContainer와 DM 판정
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — 공통 실행 상태기계, TimingWindow, Child와 Commit 조정
- [`Spell Casting Route와 2024 Spell Runtime`](../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md) — Route, Payment, Component, Targeting, Ritual·Ready·Reaction Spell
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md) — 서버 Roll, Reveal, Outcome와 PendingEffect
- [`EffectRecipe와 효과 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md) — 타입 있는 Recipe Graph, RollScope, PendingEffect와 CommitGroup
- [`Effect, Condition과 Ongoing Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md) — Effect Build·Registry·Instance·Duration·Concentration·Suppression
- [`Rules 시스템 인덱스`](../../systems/rules/README.md) — Rules 세부 문서와 구현 명세 진입점
- [`Ruleset와 Policy 시스템 인덱스`](../../systems/ruleset/README.md) — Policy Authority와 Runtime 연결 진입점

### References

- [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — Source·Build·State·Command·Transaction·Event·Projection 공통 용어
- [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Role·Control·Command·Reconnect·Rollback 문맥
- [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation Guide`](../scene/README.md) — Scene Snapshot, Query와 Runtime Object 기반
- [`Exploration, Selection, Interaction과 Perception Guide`](../exploration/README.md) — Intent·Frozen Selection·Interaction·Perception에서 Rules 진입까지
- [`Encounter Timeline, Turn, Opportunity와 Objective Runtime`](../../architecture/encounter-timeline-turn-opportunity-and-objective-runtime-contract.md) — Encounter가 제공하는 ActionOpportunity와 Boundary
- [`Inventory, ItemInstance와 World Presence Runtime`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md) — Component Material, Item Charge와 Item Capability Source
- [`Spatial Query Engine과 Provider`](../../architecture/spatial-query-engine-and-provider-contract.md) — Range·LoS·LoE·Area·Cover와 Snapshot Evidence
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Damage·HP·VitalState·Effect·Encounter의 Immediate Closure와 Follow-up
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Commit 이후 Event와 후속 실행
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — Versioned Command와 audience Projection
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Prompt·Action·Dice·Effect UI의 Projection과 Input
- [`Presentation Recipe Playback Runtime`](../../architecture/presentation-recipe-playback-priority-and-extension-runtime-contract.md) — 권위 Outcome과 비권위 Playback 분리
- [`Recipe Step Runtime Foundation Spec`](../../specs/shared/001-recipe-step-runtime-foundation.md) — 준비 완료된 Step Registry·Compiler·BindingStore·Executor 명세
- [`Standard Recipe Step Handler Contracts Spec`](../../specs/shared/002-standard-step-handler-contracts.md) — 준비 완료된 Handler Interface와 안전 경계
- [`현재 Guide 작업 순서`](../CURRENT-GUIDE-WORK-ORDER.md) — Main System Guide 단계 진행 순서

## 6. 다른 시스템과의 경계

| 인접 시스템 | Rules·Action·Spell·Dice·Effect가 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Ruleset·Policy | Effective Policy View를 소비해 실행 규칙을 고정 | Family·Implementation·Binding·Frozen Snapshot | Policy Runtime, Rule Orchestrator |
| Character | Capability·Modifier·Resource Definition을 실행하고 Effect Contribution을 반영 | Progression Source, Compiled Character Build, Persistent State와 Spell Access | Character Runtime, Grant·Action·Spell 계약 |
| Encounter | Capability 실행과 Opportunity 예약·소비, Roll·Effect 결과 | Timeline, Turn, ActionOpportunity, Movement Budget와 Boundary | Character Action, Encounter Runtime |
| Exploration | 실시간 Action·Spell·Search·Hide·Hazard RuleExecution | Base Mode, Actor 실행 Slot, Encounter Proposal | Exploration Guide, Character Action·Rule Runtime |
| Selection·Perception | Target Policy와 공개 조건을 사용 | Frozen Binding, Candidate, Visibility·Knowledge Evidence | Selection, Spell, Dice 계약 |
| Spatial Query | Query Result를 규칙 Target·Range·Area·Cover에 사용 | Snapshot-bound Geometry와 Evidence | Spatial Query, Spell Targeting |
| Inventory | Item·Material·Charge 변화 PendingEffect와 Capability 사용 | ItemInstance, Equipment, Ownership, Container와 World Presence | Inventory Runtime, Spell Component 계약 |
| Runtime Object | Effect·Recipe가 Lifecycle Command와 Binding을 요청 | Stable Runtime Identity, Component, Lifecycle와 Incarnation | Runtime Object, Effect Runtime |
| HP·Vital State | Damage·Healing·Condition 후보와 Follow-up Event를 제공 | HP·Temporary HP·VitalState·DeathSave 권위 상태 | Dice·Effect, Cross-Domain Integration |
| Game Time·Scheduler | Duration·Long Cast·Deadline 후보와 End Command | Campaign Time, Boundary Occurrence와 Scheduled Due | Effect Runtime, Time Runtime |
| Interaction | Utilize·Object Attack·Trap 실행 Recipe와 규칙 결과 | Contextual Capability·Object State·Adjudication 진입 | Interaction, Character Action, Rule Runtime |
| Network·Persistence | Command·Pending Execution·Roll·Effect Snapshot과 Projection 요구 | Epoch, Journal, Snapshot, Catch-up와 Full Resync | Networking, Persistence, Orchestrator |
| UI·Presentation | Client-safe Action·Prompt·Roll·Effect Projection과 Playback 요청 | ViewModel, Input Context, Dice·VFX·Camera Playback | UI, Dice, Presentation Runtime |
| Diagnostics·Simulation | Execution Tree, Policy Decision, Roll, Commit과 Effect Trace 지점 | Correlated Trace, Budget, Scenario·Fault Injection | Diagnostics·Simulation Runtime |

고정 경계:

- Policy Evaluator가 Domain Store를 직접 변경하지 않는다.
- Character Capability View가 Progression Source나 Persistent State를 대체하지 않는다.
- Encounter Runtime이 Attack·Spell·Interaction 행동 구현을 소유하지 않는다.
- RuleExecution이 Character·Item·Effect Definition의 영구 원본을 소유하지 않는다.
- Recipe와 Step Handler가 Orchestrator State, TimingWindow Stack과 권위 Store를 직접 수정하지 않는다.
- RollService가 HP·Inventory·Effect·Encounter Store를 직접 수정하지 않는다.
- EffectInstance가 Character·Actor·Encounter에 전체 복사되지 않는다.
- Effect Runtime이 Workspace를 직접 Query하거나 Model을 직접 Spawn·Destroy하지 않는다.
- UI Button, Prompt, Dice Animation과 Effect Icon이 권위 상태를 결정하지 않는다.
- Client Preview, Client Dice Physics와 Client가 제출한 최종 Total을 신뢰하지 않는다.
- DM Override도 Disclosure·Authorization·Transaction·Journal·Operational Hard Cap을 우회하지 않는다.
- Event Subscriber가 이미 Commit된 Root Outcome을 역으로 수정하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 Authority·Transaction·Projection 용어
2. [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Role·Control·Epoch·Recovery 문맥
3. [`Exploration, Selection, Interaction과 Perception Guide`](../exploration/README.md) — Intent와 Frozen Target이 Rules에 들어오는 경계
4. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Query·Mutation·Registry 불변식
5. [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Definition·Build·State 분리
6. [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Policy Composition과 Frozen Snapshot 결정
7. [`Ruleset Policy Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — 실행 Baseline Policy
8. [`규칙 콘텐츠 Grant Graph와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md) — Character 기능 획득과 Capability View
9. [`패시브 Modifier와 Rule Override 모델`](../../architecture/passive-modifier-and-rule-override-model.md) — 실행 문맥 기여와 RulePoint
10. [`ADR-0067`](../../decisions/ADR-0067-2024-core-actions-as-registered-action-capabilities.md) — 2024 Core Action 결정
11. [`Character Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md) — Action·Opportunity·ActionContainer·DM 판정
12. [`ADR-0061`](../../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md) — Pending Execution과 중첩 TimingWindow 결정
13. [`Rule Runtime Orchestrator`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — 공통 실행 수명주기
14. [`ADR-0068`](../../decisions/ADR-0068-2024-spell-casts-as-route-bound-pending-rule-executions.md) — Route 기반 Spell Execution 결정
15. [`Spell Runtime`](../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md) — Payment·Component·Targeting·Ritual·Ready
16. [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md) — 서버 Roll과 Reveal Gate 결정
17. [`Dice와 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md) — RollPlan·Record·Outcome
18. [`EffectRecipe 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md) — Recipe Graph와 PendingEffect
19. [`ADR-0065`](../../decisions/ADR-0065-compiled-effect-builds-and-authoritative-effect-instances.md) — Effect Build·Instance 결정
20. [`Effect Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md) — Duration·Stacking·Concentration·Suppression
21. [`Rules 시스템 인덱스`](../../systems/rules/README.md) — 세부 Spell·Feature·Recipe 문서
22. [`Recipe Step Runtime Foundation Spec`](../../specs/shared/001-recipe-step-runtime-foundation.md) — 첫 준비 완료 구현 진입점
23. [`Standard Step Handler Spec`](../../specs/shared/002-standard-step-handler-contracts.md) — Handler 확장 경계
24. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — Architecture 공백 해소와 Guide 단계 승인

다음 문서는 현재 권위 읽기 순서에서 제외한다.

- `systems/rules/condition-ongoing-effect-duration-and-concentration-model.md` — `SUPERSEDED`
- `systems/combat/dice-roll-presentation-and-resolution-gating-model.md` — `SUPERSEDED`
- `systems/combat/encounter-initiative-turn-and-control-authority-model.md` — `SUPERSEDED`

## 8. 구현·검증 순서

권위 문서와 현재 준비 완료 Spec이 확정한 의존 순서:

```text
Policy Family·Implementation Registry와 Frozen Snapshot Foundation
→ Ordering Key Registry와 Transaction Foundation
→ RuleExecution Registry와 상태기계
→ Action Opportunity·Usage Gate·Capability Resolver
→ Recipe Step Runtime Foundation Spec 001
→ Standard Step Handler Contracts Spec 002
→ Cost Reservation·Pending Input
→ RuleEvent·TimingWindow·Capability Offer·Child Execution
→ 서버 RollPlan·Sealed Result·Reveal·Outcome Resolver
→ Spell Route·Payment·Component Foundation
→ Spell Targeting·Ready·Ritual·Long Cast
→ PendingEffect·CommitGroup 조정
→ Effect Build Schema·Compiler·Registry
→ Effect Application·Stacking·Contribution
→ Duration·End Condition·Concentration·Suppression·Form Overlay
→ Persistence·Projection·Diagnostics
→ Reconnect·Restart·Rollback Scenario
→ 개별 Action·Spell·Feature·Item·Monster Content Slice
```

검증 흐름:

- 일반 무기 공격 선언부터 피해 Commit까지
- Attack Roll 공개 후 Shield Reaction이 결과에 기여
- Movement Checkpoint의 Opportunity Attack Child Execution
- 같은 Offer 응답 재전송 시 비용 중복 소비 방지
- Cantrip, Slot, Free Cast와 Item Charge Route 분리
- Component·Material·손 점유 실패와 Reservation 반환
- Ready Spell의 준비 시 비용·집중과 Trigger Release
- Fireball과 같은 Batch Save·Damage Resolution
- 비밀 Roll의 audience Projection Negative Assertion
- Client Dice Presentation 실패·Timeout 후 서버 진행
- 집중 교체 Transaction과 피해 후 Concentration Child Execution
- Effect Stacking·Suppression·Expiration·Owned Object Cleanup
- Commit 중 실패 시 부분 상태 미노출
- Reconnect 중 TimingWindow·Guided Input 복구
- Restart 후 이미 Commit된 Group 재적용 방지
- Rollback 이후 이전 Epoch Prompt·Offer·Timer 거부
- Execution Depth·Step·Offer·PendingEffect Budget 초과 안전 실패

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Policy Family·Plane·Composition 변경 | Policy Runtime, ADR-0081, 사용하는 Domain Runtime | Policy Registry·Snapshot Specs | `UPDATE_REQUIRED` |
| Grant·Capability 종류 변경 | Grant Graph, Character Runtime, Action·Spell Runtime | Character Build·Capability Specs | `UPDATE_REQUIRED` |
| ActionOpportunity·2024 Action 변경 | Character Action, Encounter Timeline, ADR-0067 | Action·Encounter Specs | `UPDATE_REQUIRED` |
| RuleExecution 상태·Phase·TimingWindow 변경 | Orchestrator, ADR-0061, Networking·Persistence | RuleExecution·Recovery Specs | `UPDATE_REQUIRED` |
| Recipe Step·Handler 계약 변경 | EffectRecipe, Standard Step Library, ADR-0053 | Shared Specs 001·002 | `UPDATE_REQUIRED` |
| Spell Route·Payment·Component 변경 | Spell Runtime, Character Spell Access, Inventory | Spell·Inventory Specs | `UPDATE_REQUIRED` |
| Roll·Reveal·Outcome 변경 | Dice Runtime, ADR-0069, Presentation | Roll·Resolution·UI Specs | `UPDATE_REQUIRED` |
| PendingEffect·CommitGroup 경계 변경 | EffectRecipe, Orchestrator, Transaction, Cross-Domain Integration | Effect Resolution·Transaction Specs | `UPDATE_REQUIRED` |
| Effect Identity·Lifecycle·Contribution 변경 | Effect Runtime, ADR-0065, Character·Runtime Object | Effect Registry·Lifecycle Specs | `UPDATE_REQUIRED` |
| Duration·Concentration·Suppression 변경 | Effect Runtime, Time·Encounter·Spell | Effect Duration·Scheduler Specs | `UPDATE_REQUIRED` |
| Persistence·Epoch·Rollback 변경 | Orchestrator, Dice, Effect, Persistence·Recovery | Snapshot·Migration·Recovery Specs | `UPDATE_REQUIRED` |
| Budget·Timeout·Cache·Presentation 시간 변경 | 해당 Architecture의 남은 기본값 | 운영·성능 Specs | 의미가 바뀌면 갱신 |
| 개별 콘텐츠 수치·번역 변경 | Rules Content Pack·Localization | Content Pack Specs | 공통 흐름이 같으면 유지 |

## 10. Authority Documents

### Product

- [`핵심 세션 흐름과 플레이 모드`](../../product/core-session-loop.md)
- [`Campaign Material Component Policy`](../../product/campaign-material-component-policy.md)
- [`Content Automation, Rollback, Storage와 Exclusions`](../../product/content-automation-rollback-storage-and-exclusions.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot Runtime`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Character Runtime과 Compiled Character Build`](../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`규칙 콘텐츠 Grant Graph와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md)
- [`Passive Modifier와 Rule Override 모델`](../../architecture/passive-modifier-and-rule-override-model.md)
- [`Character Action Opportunity와 2024 Core Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Spell Casting Route와 2024 Spell Runtime`](../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md)
- [`Dice Roll, Check, Save, Attack과 Resolution Runtime`](../../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
- [`EffectRecipe와 효과 해결·확정 모델`](../../architecture/effect-recipe-resolution-and-commit-model.md)
- [`Effect, Condition과 Ongoing Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Cross-Domain Outcome Cascade와 Integration Boundary`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery 모델`](../../architecture/persistence-and-session-recovery-model.md)

### Systems·UI

- [`Rules 시스템 인덱스`](../../systems/rules/README.md)
- [`Ruleset와 Policy 시스템 인덱스`](../../systems/ruleset/README.md)
- [`Standard Recipe Step Library`](../../systems/rules/standard-recipe-step-library.md)
- [`Active Feature와 Action Container`](../../systems/rules/active-feature-and-action-container-execution-model.md)
- [`Feat·Feature Trigger와 Cross-turn Execution`](../../systems/rules/feat-feature-trigger-and-cross-turn-execution-model.md)
- [`Spell Resource Pools와 Cast Payment`](../../systems/rules/spell-resource-pools-and-cast-payment-model.md)
- [`Spell Components와 Material Inventory`](../../systems/rules/spell-components-and-material-inventory-contract.md)
- [`Spell Targeting, Area와 Spatial Query`](../../systems/rules/spell-targeting-area-and-spatial-query-model.md)
- [`Spell Acquisition, Preparation과 Cast Access`](../../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
- [`공통 입력 UI`](../../ui/common-input/README.md)
- [`Combat HUD`](../../ui/combat-hud/README.md)

### Specs

- [`001. Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md) — `READY`
- [`002. Standard Recipe Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md) — `READY`

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0001`](../../decisions/ADR-0001-authored-rules-content.md) — 공식 규칙 콘텐츠를 RVTT가 직접 저작·구현
- [`ADR-0002`](../../decisions/ADR-0002-integrated-character-progression.md) — 성장 Source와 실행 규칙의 통합
- [`ADR-0003`](../../decisions/ADR-0003-ruleset-source-packs-localization.md) — `dnd5e-2024`, Source Pack과 Localization 분리
- [`ADR-0025`](../../decisions/ADR-0025-typed-rule-events-timing-windows-and-usage-gates.md) — 타입 있는 RuleEvent·TimingWindow·Usage Gate
- [`ADR-0026`](../../decisions/ADR-0026-active-capabilities-action-containers-and-unit-replacements.md) — Active Capability와 ActionContainer
- [`ADR-0027`](../../decisions/ADR-0027-passive-modifiers-rule-overrides-and-conditional-activation.md) — Modifier·Override·Conditional Capability
- [`ADR-0028`](../../decisions/ADR-0028-effect-recipes-pending-effects-and-commit-groups.md) — EffectRecipe·PendingEffect·CommitGroup
- [`ADR-0029`](../../decisions/ADR-0029-unified-effect-instances-duration-concentration-and-suppression.md) — 통합 EffectInstance 수명주기
- [`ADR-0033`](../../decisions/ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md) — 서버 권위 주사위와 Presentation Gate
- [`ADR-0053`](../../decisions/ADR-0053-step-level-automation-and-standard-recipe-step-library.md) — Step 단위 자동화와 표준 Step Library
- [`ADR-0061`](../../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md) — 저장 가능한 RuleExecution과 중첩 TimingWindow
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Ordered Reservation과 원자 Transaction
- [`ADR-0064`](../../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md) — 불변 Build와 버전된 State
- [`ADR-0065`](../../decisions/ADR-0065-compiled-effect-builds-and-authoritative-effect-instances.md) — Effect Build·Registry·Instance
- [`ADR-0067`](../../decisions/ADR-0067-2024-core-actions-as-registered-action-capabilities.md) — 2024 Core Action Capability
- [`ADR-0068`](../../decisions/ADR-0068-2024-spell-casts-as-route-bound-pending-rule-executions.md) — Route 기반 Pending Spell Execution
- [`ADR-0069`](../../decisions/ADR-0069-authoritative-roll-records-and-presentation-gated-resolution.md) — 불변 RollRecord와 Reveal Gate
- [`ADR-0081`](../../decisions/ADR-0081-versioned-policy-composition-and-frozen-ruleset-snapshots.md) — Versioned Policy Composition과 Frozen Snapshot

## 12. 알려진 비목표와 측정형 기본값

### 비목표

- UI Button이나 Action Bar Slot을 Capability 권위 원본으로 사용하지 않는다.
- 행동·주문·Effect 이름별 거대한 Server 분기문을 만들지 않는다.
- NPC 자동 대화 트리와 모든 즉흥 행동의 완전 자동화를 만들지 않는다.
- Client가 주사위 식, 최종 Total, 성공 여부, 피해와 상태 결과를 확정하지 않는다.
- Client Dice Physics를 RNG로 사용하지 않는다.
- 시전 가능성을 위해 장비를 자동으로 변경하지 않는다.
- 모든 효과를 단순 Modifier 또는 Character 문자열 Condition Set으로 축약하지 않는다.
- 집중을 주문별 Boolean으로 저장하지 않는다.
- Suppression과 Effect End를 같은 상태로 처리하지 않는다.
- Recipe·Step Handler가 임의 Luau, 제한 없는 반복과 직접 Store Mutation을 실행하지 않는다.
- Presentation·VFX·Camera·Dice Animation 완료를 권위 결과의 필수 성공 조건으로 사용하지 않는다.
- 진행 중 RuleExecution이 최신 Policy·Recipe·Build로 자동 전환되지 않는다.

### 남은 측정형 기본값

- Policy Snapshot Family·Binding 수와 직렬화 크기 상한
- Policy Trace와 이전 Snapshot 보존 기간
- DM Policy Override 기본 만료와 경고 기준
- 즉흥 행동 Prompt 기본 선택지와 DM 판정 대기 제한 시간
- RuleExecution Child 깊이, TimingWindow·Offer·Prompt 수와 Execution Budget
- Pending Execution Snapshot 주기와 보존 기간
- Spell 후보 Cache, AoE Candidate Cap과 Long Cast 갱신 주기
- 다중 Cast Route 기본 정렬·선택 UI
- Dice Presentation 최소 시간, ACK Policy와 Hard Timeout
- 대량 3D Dice 축약 기준과 비밀 Roll 로그 공개 기본값
- EffectInstance·Index 경고 기준과 Duration Scheduler Batch Budget
- Effect Tombstone·Journal 보존 기간과 Icon 집계 표시 순서
- Form Overlay Derived View Cache 상한

이 값들은 Implementation Spec, 프로파일링과 플레이테스트에서 정한다. Rules 의미, Authority 경계와 저장 수명주기를 바꾸면 먼저 해당 Architecture와 ADR을 갱신한다.

### 남은 비차단 작업

- Policy·RuleExecution·Roll·Effect의 수직 Implementation Specs
- 공식 2024 Action·Spell·Feature·Feat·Item Content Pack 구현
- 한국어 Localization과 규칙 설명 작성
- UI Layout과 Dice·Effect Presentation 설계
- Production-parity Scenario Fixture와 성능 기준 수치 확정

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 저장소의 현재 경로를 사용한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 준비 완료 Specs를 반영했다.
- [x] `SUPERSEDED` 문서를 현재 권위 읽기 순서에서 제외했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
