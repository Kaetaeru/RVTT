# Main System Guide: Character, Inventory와 Downtime

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 캐릭터의 성장 원본과 현재 상태가 세션·Scene·Encounter를 넘어 유지되고, 아이템이 Inventory·Equipment·Container·Scene Ground 사이를 단일 ItemInstance로 이동하며, 휴식·레벨업·주문 준비·주문책 작업·제작·훈련·여행이 하나의 Campaign Time Window에서 안전하게 진행되고 원자적으로 완료되는 전체 흐름을 설명한다.

사용자에게 보장하는 결과:

- Character Progression Source, Compiled Character Build, Persistent Character State, Scene Actor State와 Encounter State를 서로 다른 권위 계층으로 유지한다.
- 종·배경·직업·하위직업·Feat·숙련·주문·Weapon Mastery 선택은 성장 Source에 기록하고, 최종 Capability·AC·DC·최대 Resource와 같은 파생값을 중복 저장하지 않는다.
- Character Compiler는 고정된 Ruleset·Source Pack Version에서 불변 Compiled Character Build를 만들며 Live State를 직접 수정하지 않는다.
- 현재 HP, Temporary HP, DeathSave, 장기 Resource, 준비 주문, 지속 Condition·Effect, Concentration, Inventory Binding과 Equipment·Attunement는 Persistent Character State로 보존한다.
- CharacterId와 Scene ActorId를 분리한다. Scene 전환으로 Actor Presence가 바뀌어도 Character 성장과 영구 상태를 복제하거나 잃지 않는다.
- Encounter의 Initiative·Action Economy·이번 Turn Movement는 Persistent Character State에 저장하지 않는다.
- Derived Statistic과 Effective Capability는 Build, 현재 State, Item, Effect, Scene·Encounter Context에서 계산하며 UI가 보낸 최종 수치를 권위로 저장하지 않는다.
- 레벨업·재구성은 Live Build를 제자리 수정하지 않고 새 Source Revision, Candidate Build와 State Migration을 검증한 뒤 하나의 Transaction으로 활성화한다.
- Compile 또는 Migration이 실패하면 기존 Source·Build·State를 유지한다.
- 하나의 실제 아이템은 하나의 ItemInstance만 가지며 같은 Authority Revision에서 하나의 권위 위치에만 존재한다.
- 바닥 아이템은 Inventory Item의 복사본이 아니라 동일 ItemInstance와 연결된 Item Presence Runtime Object다.
- Workspace Model, Client Streaming, 낙하 Physics와 Animation은 Item 존재·위치·소유권의 권위가 아니다.
- Pickup, Drop, Equip, Unequip, Transfer, Stack Split·Merge, Throw, Disarm와 Container Spill은 Reservation과 Transaction을 사용한다.
- 부분 Stack 분할처럼 실제 수량을 나누는 경우에만 새 ItemInstance Identity를 만든다.
- Equipment와 Attunement는 Character Build를 직접 수정하지 않고 현재 Item State에서 Modifier·Capability·Attack Profile을 파생한다.
- 미확인 아이템의 실제 Definition, 저주와 숨은 상태는 Permission-aware Projection에서 제거한다.
- 주문 자체, 주문을 얻은 출처, 준비 상태, 주문책 Repository와 실제 SpellCastRoute를 분리한다.
- 고정 주문 권한은 Source에서 파생하고 플레이어가 선택한 습득·준비·Repository Entry만 저장한다.
- 주문책은 ItemInstance와 결합된 영구 SpellRepository이며 준비 주문 목록의 저장 위치가 아니다.
- Downtime은 Exploration·Encounter와 구분되는 Base Play Mode이며 Pause·선택창·Character Sheet와 같은 Overlay와 동일하지 않다.
- Downtime Runtime은 휴식·레벨업·주문·제작 규칙을 다시 구현하지 않고 참가자, 활동, 시간, 선택, Reservation, Progress와 Completion을 조정한다.
- 참가자마다 별도의 Campaign Clock을 만들지 않는다. 독립적인 활동은 같은 Campaign Time Window에서 병렬 진행한다.
- 현실 시간 경과나 오프라인 상태만으로 휴식·제작·훈련·레벨업을 자동 완료하지 않는다.
- 장기 Activity 동안 Ordering Lock을 유지하지 않고 Item·Resource·Tool·Choice 같은 타입 있는 Domain Reservation을 사용한다.
- 긴 Time Advance는 가장 가까운 Activity·Scheduler·사건 Checkpoint에서 멈추며 중간 사건을 건너뛰지 않는다.
- 휴식은 버튼 클릭 즉시 전체 회복하지 않고 RestSession, Activity Ledger, Completion Candidate와 RecoveryPlan을 거친다.
- 레벨업은 Source·Build Ref·State Migration을 원자적으로 교체한다.
- 준비 주문 변경은 Persistent spellPreparationState를 변경하며 Character Progression Source를 직접 수정하지 않는다.
- 주문책 복사는 시간·비용·원본·대상 Repository를 예약하고 비용 소비와 Repository Entry 생성을 하나의 Completion으로 확정한다.
- 제작은 입력 Item·Resource 소비, Output ItemInstance 생성과 Container 또는 Ground Presence 배치를 하나의 Transaction으로 Commit한다.
- 훈련은 Capability를 직접 주입하지 않고 Progression Change·Exceptional Grant Proposal 또는 타입 있는 Training Record를 만든다.
- 여행은 Scene Navigation을 프레임별로 자동 재생하지 않고 Route·Watch·소모·시간·중간 사건·도착을 Activity와 Checkpoint로 해결한다.
- Downtime 중 Encounter가 발생하면 Activity를 `suspended`로 두고 사건 종료 후 자격·Reservation·Progress·남은 시간을 다시 검증한다.
- 재접속·Restart·Rollback 후 Character Source·Build·State, Item Location·Presence, Downtime Activity·Reservation·Progress·Pending Choice를 Snapshot과 Journal에서 복원한다.
- Rollback은 역연산이 아니라 새 Branch·AuthorityEpoch를 활성화하며 이전 Epoch의 Command, Choice, Scheduler Due, Completion 응답과 Projection ACK를 무효화한다.
- Player, DM과 Observer는 같은 Character·Item·Downtime 상태에서도 Ownership·Role·Identification·Disclosure에 맞는 Projection만 받는다.

적용 범위:

- Character identity, campaign ownership과 Progression Source
- Compiled Character Build, Grant, Capability, Modifier, Resource Definition과 Derived Statistic
- Persistent Character State, Scene Actor Binding과 Encounter State 경계
- Character Build 교체, Compatibility와 State Migration
- 주문 획득·준비·Repository·Cast Access의 Character 측 권위
- NPC·Monster Statblock Definition과 ActorInstance의 공통 Capability Runtime 연결
- ItemDefinitionSource, CompiledItemBuild와 ItemInstance State
- Inventory, Equipment, Attunement, Hand·Slot 점유와 Item Capability
- Item Location Binding, Container, Campaign Storage와 Scene Ground Presence
- Pickup, Drop, Transfer, Throw, Disarm, Stack과 Identification
- DowntimeSession, Activity Definition·Build·Instance와 Participant Window
- Domain Reservation, Progress, TimeAdvancePlan과 Scheduler Checkpoint
- Short Rest, Long Rest, Hit Dice와 Resource Recovery
- Level Up, Character 수정과 Migration
- Spell Preparation과 Spellbook Work
- Crafting, Training과 Travel Resolution
- Activity 중단·취소·실패, Encounter 전환과 재개
- Character Sheet·Inventory·Downtime Projection
- Persistence, Recovery, Rollback과 Cross-Domain Atomic Completion

명시적 비범위:

- 공격·주문·Feature·EffectRecipe의 세부 실행과 Dice Resolution
- Encounter Timeline·Turn·Objective와 전투 Rollback의 전체 구현
- Scene Source·Compiler, Spatial Query·Navigation과 Streaming의 내부 구현
- 상점 가격·거시 경제·거래 시장을 위한 별도 Economy Engine
- NPC 전술 AI와 자동 성장 의사결정
- 모든 Craft Recipe, Training Program, Travel Route와 Encounter 콘텐츠
- Character Sheet·Inventory·Downtime UI의 최종 픽셀 레이아웃
- Roblox Module 경로와 최종 Luau Type·Command·Persistence Schema
- 측정 전의 Cache, Batch, Timeout, Progress Checkpoint, Item 정리와 Tombstone 보존 수치
- 현실 오프라인 시간에 따른 자동 진행
- 음악, NPC 대화 시스템과 모든 규칙 효과음

## 2. 전체 구조

### Character 권위 구조

```text
Character Progression Source
+ Frozen Ruleset·Source Pack Version
→ Character Compiler
→ Immutable Compiled Character Build

Compiled Character Build
+ Persistent Character State
+ Item·Effect Contributions
+ Scene Actor·Encounter Context
→ Character Runtime Snapshot
→ Rule Runtime·Projection Builder
```

### Item 권위 구조

```text
ItemDefinitionSource
→ Item Compiler
→ Immutable CompiledItemBuild
→ ItemInstance State
→ Exclusive Item Location Binding
→ Inventory·Equipment·Container | Scene Ground Presence
→ Item·Character Projection
```

### Downtime 권위 구조

```text
Downtime Proposal
→ Participant·Activity Assignment
→ Compiled Activity Build와 Activity Instance
→ Domain Reservation·Choice·Progress
→ TimeAdvancePlan
→ Activity·Scheduler·Encounter Checkpoint
→ Domain Completion Plan
→ Cross-Domain Authority Transaction
→ Projection·Event·Presentation
```

### 영구 플레이 전체 흐름

```text
Campaign Character·Item Source 로드
→ Build Hash·State Revision 검증
→ Scene Actor와 Runtime Presence 연결
→ Exploration·Encounter에서 Capability 사용
→ Item·HP·Resource·Effect State Commit
→ Downtime에서 장기 변경 조정
→ Source·Build·State·Item·Time Atomic Completion
→ Snapshot·Journal·Projection 갱신
```

## 3. 주요 데이터 흐름

### 3.1 Character Source, Build와 State

```text
CharacterProgressionSource
├─ Identity·Species·Background
├─ Class Level Sequence·Subclass
├─ Ability Score Generation Record
├─ Feat·Proficiency·Weapon Mastery Selection
├─ Spell Acquisition Selection
├─ Exceptional Grant
└─ Ruleset·Source Pack Version

→ CharacterCompiler

CompiledCharacterBuild
├─ Resolved Grant Set
├─ Capability Set
├─ Passive Modifier·Rule Override Graph
├─ Proficiency·Spell Access Profile
├─ Resource Definition
├─ Derived Statistic Plan
└─ Movement·Body Profile

+ PersistentCharacterState
├─ HP·Temporary HP·DeathSave·Exhaustion
├─ Current Resource State
├─ Spell Preparation
├─ Persistent Condition·Effect·Concentration
├─ Inventory Binding
├─ Equipment·Attunement
└─ Long-lived Usage Gate
```

Source는 선택과 출처의 권위 원본이고, Build는 결정적으로 재생성 가능한 불변 파생 데이터이며, State는 Command와 Transaction으로 변경되는 현재값이다.

### 3.2 Character Runtime Snapshot과 Projection

```text
Build Reference·Hash
+ Persistent State Revision
+ Scene Actor Binding
+ Encounter State
+ Item·Effect·Aura Contribution
+ Frozen Policy Snapshot
→ Character Runtime Snapshot
→ Derived Character View
→ Ownership·Role·Disclosure
→ Character Sheet·Combat HUD·Action Projection
```

캐시와 UI ViewModel이 유실되어도 Source·Build Reference·State에서 다시 계산한다.

### 3.3 Character, Actor와 Encounter Identity

```text
CharacterId
→ Campaign 영구 Identity·Progression·State

ActorId / RuntimeObjectId
→ 특정 Scene의 Presence·Transform·Perception·Presentation

Encounter Participant Binding
→ Initiative·Opportunity·Movement·Turn Context
```

CharacterId를 ActorId와 동일시하지 않는다. 같은 Character가 Scene을 바꾸면 새 Actor Presence를 가질 수 있으며, NPC·Monster는 ActorDefinition에서 여러 독립 ActorInstance로 생성될 수 있다.

### 3.4 Item Definition, Build, Instance와 Location

```text
ItemDefinitionSource
→ ItemCompiler
→ CompiledItemBuild
→ ItemInstanceState
→ ItemLocationBinding
```

- Definition·Build: Item kind, Stack, Weight, Equipment·Hand, Attack Mode, Charge·Attunement·Identification·World Presence 정책
- Instance: 수량, Charge, Condition, Attunement, Identification, Custom Name, Instance Modifier와 Provenance
- Location: Character Inventory, Actor Equipment, Container, Scene Ground, Campaign Storage 또는 Consumed·Destroyed

ItemInstance의 현재 Owner, 수량, Charge와 바닥 위치를 CompiledItemBuild에 넣지 않는다.

### 3.5 Equipment와 Item Capability

```text
ItemInstance
+ EquipmentState·HandSlot·Attunement
+ Character Build·Proficiency
+ Current Context
→ Effective Item Contribution
→ Modifier·Capability·AttackProfile 후보
```

장착 변경은 Capability와 Attack Profile Cache를 무효화하지만 Character Progression Source나 Compiled Character Build를 제자리 수정하지 않는다.

### 3.6 Scene Ground와 Item Presence

```text
ItemInstance
+ locationKind: scene_ground
↔ ItemPresence RuntimeObject
→ Spatial·Selection·Interaction·Perception·Presentation
```

Item Presence가 Stream Out되거나 Workspace Model 생성에 실패해도 ItemInstance와 Ground Placement는 권위 상태로 남는다.

### 3.7 Spell Acquisition, Preparation과 Repository

```text
SpellDefinition
+ SpellcastingProfile Source
+ Spell Choice·Repository·Preparation State
+ Item·Effect Route Source
→ Resolved Spell Access
→ SpellCastRoute[]
→ 현재 Resource·Opportunity에서 SpellCastOption
```

다음을 분리한다.

```text
eligible
≠ acquired
≠ ready
≠ castable
```

주문책:

```text
Spellbook ItemInstance
↔ SpellRepositoryRecord
→ SpellRepositoryEntry[]

SpellcastingProfileState
→ primaryRepositoryRef·preparedSpellIds
```

Repository Entry는 SpellDefinition 사본이 아니라 Spell ID, Content Version과 획득 기록을 저장한다.

### 3.8 Downtime Definition, Build와 Instance

```text
DowntimeActivityDefinitionSource
→ Activity Compiler
→ CompiledDowntimeActivityBuild
→ DowntimeActivityInstance
```

Definition·Build는 Eligibility, Time, Input, Progress, Interruption과 Completion Provider를 고정한다. Instance는 참가자, 선택, Live Binding, Reservation, Progress, 중단 기록과 Completion Candidate를 보존한다.

### 3.9 Participant Window, Reservation과 Progress

```text
Participant Assignment
+ Activity Dependency Graph
+ Item·Resource·Tool·Choice Reservation
+ Scheduler Due·DM Stop Point
→ DowntimeWindow
→ TimeAdvancePlan
→ 다음 Safe Checkpoint
→ Activity Progress Ledger
```

같은 Character는 같은 시간 구간에 기본적으로 하나의 Primary Activity를 수행하며 Secondary·Support Activity는 Definition이 허용할 때만 결합한다.

### 3.10 Rest와 Recovery 데이터

```text
RestDefinition
→ RestSession
→ ParticipantRestState·ActivityLedger·InterruptionRecord
→ Completion Candidate
→ RecoveryPlan
→ RecoveryCommitGroup
```

RecoveryPlan은 자동 회복, 선택 회복, HP, Hit Dice, Resource, Effect 종료, Condition·Exhaustion 변경을 타입 있는 Entry로 모은다.

### 3.11 Completion Plan과 Cross-Domain Outcome

```text
Activity Completion Candidate
→ Domain Completion Provider
→ Read·Write Set·Precondition·Mutation Proposal
→ Reservation·Progress Settlement
→ Cross-Domain Outcome Plan
→ Authority Transaction
→ Journal·Outbox·Projection Barrier
```

Downtime Runtime은 Character·Inventory·Spell·Rest Store에 대한 Mutation을 직접 작성하지 않는다.

### 3.12 Persistence와 Recovery

저장 원본:

- Character Progression Source·Revision
- Character Build Reference·Hash와 Version Set
- Persistent Character State
- Actor·Encounter Binding Reference
- ItemInstance·Location·Container·Equipment·Attunement·Ground Placement
- DowntimeSession·Activity·Participant Window·Progress Ledger
- Domain Reservation·Pending Choice·Approval
- TimeAdvancePlan·Checkpoint Cursor
- Completion Candidate·Plan과 Migration Reference
- AuthorityEpoch·Revision·Transaction·Journal·Outbox

재생성 대상:

- Compiled Build Blob
- Derived Statistic·Capability·Attack Profile View
- Item World Bundle Presentation
- Character Sheet·Inventory·Downtime ViewModel
- Workspace Model, Animation, Hover와 Camera 상태

## 4. 주요 실행 흐름

### 4.1 Character 로드와 Scene Actor 연결

```text
Campaign Character Source·Persistent State 로드
→ Ruleset·Source Pack Version과 Build Hash 검증
→ Build 조회 또는 결정적 재컴파일
→ State Compatibility 검증
→ Scene Actor RuntimeObject 생성·연결
→ Item·Effect·Encounter Context 결합
→ Character Runtime Snapshot
→ Player·DM·Observer Projection
```

Actor Materialization 실패를 Character 손실로 처리하지 않는다. Scene Presence만 복구하고 영구 Character Source·State는 유지한다.

### 4.2 Character 생성·성장 Source 확정

```text
Player 선택·DM 승인
→ Progression Source Proposal
→ 후보군·선행조건·출처 검증
→ Candidate Compiled Character Build
→ Initial State Plan 또는 Migration Plan
→ Source·Build Ref·State 원자 Commit
→ Character Projection
```

고정 Grant와 최종 Derived 값을 선택 기록으로 중복 저장하지 않는다.

### 4.3 장착·해제·조율

```text
Equip·Unequip·Attune Intent
→ Character Control·Item Ownership 검증
→ Item·Equipment·Hand·Slot·Attunement Revision 검증
→ 전투 Opportunity 또는 Downtime 조건 검증
→ Item·Equipment Reservation
→ Atomic Equipment Transaction
→ Effective Capability·Modifier·Attack Profile 재계산
→ Character·Inventory Projection Barrier
```

DM이 일반 Controller로 수행하면 Player Command 경로를 사용하며 규칙을 우회하는 경우에만 별도 Override와 Audit를 사용한다.

### 4.4 Pickup, Drop와 Transfer

Pickup:

```text
공개 Item Presence 선택
→ Item·Presence·Actor Incarnation 해결
→ 거리·접근·Control·Opportunity·Capacity 검증
→ Item·Presence·Inventory Reservation
→ scene_ground Binding 제거
→ Inventory 또는 Stack Binding 추가
→ Presence Archive
→ Atomic Commit
```

Drop:

```text
Item·수량 선택
→ 소유·Equipment·Stack 검증
→ Server Placement Query
→ 필요 시 Stack Split
→ Ground Location과 Presence 준비
→ Inventory·Equipment·Presence Atomic Commit
```

동시에 같은 Item을 획득하려는 요청은 먼저 최신 Revision에서 Commit된 하나만 성공한다.

### 4.5 Item 사용, 공격과 소비

```text
Item Capability 선택
→ 현재 ItemInstance·Equipment·Charge·Quantity 검증
→ Character Action·Spell Route
→ RuleExecution·Roll·PendingEffect
→ ConsumptionOrTransferPlan
→ Resource·Item·Effect Commit
```

Inventory Runtime은 공격·주문 결과를 직접 계산하지 않고 Item Source와 현재 State를 제공한다. 투척·탄약·귀환·파괴는 규칙 실행과 Item Transfer가 같은 Commit Graph에서 정산한다.

### 4.6 Downtime 진입

```text
Player 제안 또는 DM Start
→ 현재 Session Base Mode·적대 Encounter·Scene 조건 검증
→ DowntimeSession proposed
→ Scope·Participant 수집
→ 참가자별 Activity·Fallback 배정
→ Eligibility·Dependency·Reservation 검증
→ Downtime Base Mode 활성
→ ready_to_advance
```

Pause, Character Sheet와 Choice Prompt는 Downtime lifecycleState가 아니라 Overlay·Input Context다.

### 4.7 시간 진행과 Checkpoint

```text
Activity Time Requirement
+ Participant Window
+ Scheduler Due
+ Rest·Travel·DM Stop Point
→ TimeAdvancePlan
→ 가장 가까운 Safe Checkpoint까지 Campaign Time Commit
→ Progress Delta·Due Occurrence
→ 모든 Activity 재검증
→ 다음 Advance 또는 사건 해결
```

각 참가자의 활동 시간을 단순 합산하지 않는다. 같은 시간 구간에서 병렬로 진행되는 Activity는 Campaign Time을 한 번만 소비한다.

### 4.8 Short·Long Rest

```text
Rest Activity 선택
→ RestSession과 ParticipantRestState
→ 허용 활동·경계·중단 Policy 적용
→ Campaign Time Checkpoint 진행
→ Required Duration 충족
→ Completion Candidate
→ RecoveryEngine이 RecoveryPlan 구성
→ Hit Dice·Resource·Effect 선택
→ 최신 State 재검증
→ RecoveryCommitGroup
→ Rest·Character·Item Charge Projection
```

중단된 휴식은 자동 회복하지 않는다. 파티가 함께 쉬어도 합류 시점과 적격 시간에 따라 참가자별 결과가 다를 수 있다.

### 4.9 Level Up과 Character Migration

```text
Level Up Activity
→ Class·Subclass·Feat·Ability·Spell 선택
→ Progression Change Proposal
→ Candidate Source Revision
→ Candidate Build Compile
→ Old Build·State와 Compatibility 비교
→ State Migration Plan
→ 필요한 주문책·장비·Resource 검증
→ Player·DM 검토
→ Source + Build Ref + State Atomic Activation
→ Projection·Capability Cache 재구성
```

Compile·Migration 또는 필수 Repository 기록이 실패하면 Source 일부, 최대 Resource나 Capability 일부만 적용하지 않는다.

### 4.10 Spell Preparation 변경

```text
Preparation Activity 또는 허용 Boundary
→ SpellcastingProfile·Repository 후보 조회
→ Preparation Set 선택
→ 획득·접근·Readiness 검증
→ Persistent spellPreparationState Proposal
→ Capability·Spell Projection 무효화
→ Atomic Commit
```

준비 변경만으로 Class Level, Feat와 Spell Acquisition Source를 수정하지 않는다.

### 4.11 Spellbook 생성·기록·복사

기본 주문책:

```text
Spellbook ItemInstance 생성
+ SpellRepositoryRecord 생성
+ 양방향 Binding
+ 초기 Repository Entry
+ Profile primaryRepositoryRef
→ 하나의 Transaction
```

복사:

```text
Source Scroll·Repository Entry와 Destination 선택
→ Character Capability·Access·Spell Level 검증
→ 시간·화폐·재료·원본 Reservation
→ Downtime Progress와 중단 처리
→ Repository Entry Completion Plan
→ 비용·원본 소비 + Entry 생성 Atomic Commit
```

### 4.12 Crafting

```text
Craft Recipe·제작자·지원자·도구·시설 선택
→ 입력 Item·Resource·Currency Reservation
→ Campaign Time·Progress Checkpoint
→ Quality·Output 선택과 최신 검증
→ Input 소비
+ Output ItemInstance 생성
+ Container Binding 또는 Ground Presence
+ Activity Completion
→ Atomic Transaction
```

중간 진행을 영구 보존해야 하면 Recipe가 명시한 Work-in-Progress Item 또는 Progress Record를 사용한다.

### 4.13 Training

```text
Training Activity
→ 자격·교관·시설·비용 검증
→ Time·Milestone Progress
→ DM 승인과 Completion Candidate
→ Progression Change·Exceptional Grant 또는 Training Record Proposal
→ 필요한 Compile·Migration
→ Atomic Activation
```

훈련 완료 UI가 Character Capability를 직접 추가하지 않는다.

### 4.14 Travel Resolution

```text
Travel Plan과 참가자·운송 수단·Watch Assignment
→ Route Segment·예상 시간·소모 Policy
→ 다음 사건·구간까지 Time Advance
→ Resource·Effect·환경 결과
→ Encounter·Choice 발생 시 Downtime suspended
→ 해결 후 Eligibility·Reservation·남은 Route 재검증
→ Arrival Plan
→ 필요 시 Scene Transition
```

Travel은 Runtime Navigation Path를 장시간 프레임별로 재생하거나 Client 위치를 권위로 사용하지 않는다.

### 4.15 중간 사건과 Encounter 전환

```text
Scheduler Due·Hazard·Enemy Encounter·시설 상실
→ 현재 Checkpoint Commit
→ DowntimeSession·Activity suspended
→ Encounter Proposal 또는 RuleExecution
→ 사건 해결
→ Character·Item·Time 최신 State 검증
→ Progress 유지·부분 유지·초기화·취소 Policy
→ DM 또는 Policy에 따라 재개
```

사건 종료만으로 남은 시간을 자동 진행하지 않는다.

### 4.16 취소, 중단과 안전 실패

```text
Cancel·Eligibility Loss·Provider Failure
→ 미Commit Output 폐기
→ Cancellation·Interruption Policy
→ Progress Settlement
→ Reservation Release·Partial Settlement·Forfeit
→ Activity Terminal Record
→ Player·DM Projection과 Trace
```

이미 Commit된 중간 사실을 조용히 역연산하지 않는다. Character Compile 실패, Item Reservation 유실과 Completion Provider 오류는 기존 Last Known Good 상태를 유지하고 필요한 Scope를 Gate한다.

### 4.17 재접속과 서버 Recovery

```text
Snapshot + Commit Journal
→ Character Source·Build Ref·Persistent State 복원
→ ItemInstance·Location·Presence·Equipment 복원
→ DowntimeSession·Window·Progress·Reservation 복원
→ Campaign Time·Scheduler·Outbox 재검증
→ Pending Choice·Approval 재Projection
→ Derived View와 Character Sheet·Inventory·Downtime UI 재구성
→ 안전 상태에서 입력 재개
```

Client의 로컬 시트 값, Inventory Slot, Progress Bar와 Animation을 권위 복구 원본으로 사용하지 않는다.

### 4.18 Rollback

```text
DM이 Authority Checkpoint 선택
→ 새 Branch·AuthorityEpoch 활성화
→ Source·Build Ref·State·Item·Time·Downtime Snapshot 복원
→ 이전 Branch의 Reservation·Choice·Command·Due·Completion 무효화
→ Build·Capability·Attack Profile·Projection 재구성
→ Full Client Resync
```

Rollback 대상 Character Build와 State Hash가 맞지 않으면 최신 Build를 조용히 결합하지 않고 호환 재컴파일·Migration 또는 DM Recovery를 요구한다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — Source·Build·State, Snapshot Query, Command Mutation, Registry와 Projection 불변식
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Character·Item·Activity Source, 불변 Build와 변경 가능한 State의 공통 계층
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md) — 성장·휴식·시간·Item Policy의 Version과 진행 중 Snapshot 고정
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Exploration·Encounter·Downtime Base Mode와 Overlay·Transition 경계
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Build 활성화, Item Transfer, Recovery와 Crafting의 원자적 Commit
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md) — Commit 이후 Event, Follow-up Command와 Projection 전달
- [`Persistence와 Session Recovery 모델`](../../architecture/persistence-and-session-recovery-model.md) — Source·State·Item·Activity Snapshot, Journal, Restart와 Branch Rollback

### Child Authority

- [`Character Runtime과 Compiled Character Build 계약`](../../architecture/character-runtime-and-compiled-character-build-contract.md) — Character Source·Build·Persistent State·Actor·Encounter와 Migration
- [`Inventory, ItemInstance와 World Presence Runtime 계약`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md) — 단일 ItemInstance, Location Binding, Equipment, Transfer와 Ground Presence
- [`Downtime Activity, Time Coordination과 Atomic Completion Runtime 계약`](../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md) — Activity Session, Participant Window, Reservation, Progress, Time와 Completion
- [`Rules Content Grant와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md) — Character·Item·Effect Source가 제공하는 Grant·Capability와 저장 선택 경계
- [`HP 0·죽음 내성·휴식·자원 회복 모델`](../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md) — RestSession, RecoveryPlan, HP·DeathSave와 Resource 회복
- [`주문 획득·준비·시전 권한 모델`](../../systems/character/spell-acquisition-preparation-and-cast-access-model.md) — SpellcastingProfile, Acquisition, Preparation, Repository와 Cast Access
- [`주문책 저장소와 복사 모델`](../../systems/character/spellbook-repository-and-copying-model.md) — Item-bound Repository, Entry와 Copy Completion
- [`몬스터·NPC 스탯블록과 인게임 JSON 가져오기 모델`](../../systems/character/monster-npc-statblock-and-ingame-json-import-model.md) — ActorDefinition·ActorInstance와 공통 Capability Runtime
- [`무기·아이템·공격 프로필과 Weapon Mastery 모델`](../../systems/inventory/item-weapon-attack-profile-and-mastery-model.md) — Equipment·Hand·Attack Profile과 Item Capability
- [`인벤토리·전리품·아이템 이전 모델`](../../systems/inventory/inventory-loot-and-item-transfer-model.md) — Loot, Currency, Identification과 Transfer 사용자 흐름

### References

- [`Character Action·2024 Core Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md) — Character·Item Capability를 실제 행동으로 실행하는 경계
- [`Spell Casting Route와 2024 Spell Runtime`](../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md) — Character Spell Access를 Route-bound RuleExecution으로 실행
- [`Effect, Condition과 Ongoing Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md) — Character·Item·Rest 결과의 지속 Effect와 Contribution
- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md) — Character Actor와 Item Presence의 Scene Identity·Lifecycle
- [`Game Time, Calendar, Duration과 Scheduler Runtime`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md) — Downtime Campaign Time Advance와 Scheduler Checkpoint
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Build Activation, Crafting, Rest와 Item·Character Atomic Closure
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Character Sheet·Inventory·Downtime UI의 Projection·Intent 경계
- [`공식 2024 형식 Character Sheet와 실시간 UI`](../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md) — CharacterProjection과 시트 사용자 흐름
- [`Combat와 Encounter Guide`](../combat/README.md) — Damage·Death·Encounter State와 Downtime 중 Encounter 경계 탐색
- [`Rules, Character Action, Spell, Dice와 Effect Guide`](../rules/README.md) — Capability·Spell Route·Roll·Effect 실행 경계 탐색

## 6. 다른 시스템과의 경계

| 인접 시스템 | 이 시스템이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Rules·Action·Spell | Effective Capability, Resource·Item·Spell Route Source와 현재 State | Selection, RuleExecution, Roll, PendingEffect와 Cost Commit | Character Runtime, Character Action, Spell Runtime |
| Effect | Character·Item Owner·Target Binding과 Persistent State 연결 | EffectInstance, Modifier·Capability Contribution, Duration·Concentration | Effect Runtime, Character Runtime |
| Scene·Runtime Object | CharacterId·ItemInstanceId와 필요한 Presence Binding | Actor·Item Presence Identity, Transform, Lifecycle와 Materialization | Runtime Object, Inventory Runtime |
| Spatial·Navigation·Interaction | Actor·Item Capability와 Location Reference | Drop Placement, Pickup Range·Path, Selection과 Interaction Command | Inventory Runtime, Interaction·Spatial·Navigation 계약 |
| Encounter | Persistent Character·Item State와 Capability | Initiative, Opportunity, Turn Movement와 Participant Context | Character Runtime, Encounter Runtime |
| Session | Character Ownership과 Downtime 참가 후보 | Base Mode, Control Assignment, Overlay·Transition과 Join·Reconnect | Session Mode 계약 |
| Game Time | Activity Time Requirement와 Completion Checkpoint 후보 | Campaign Instant, TimeAdvance Commit와 Scheduler Due | Downtime Runtime, Game Time Runtime |
| Cross-Domain Integration | Character·Inventory·Rest Domain Mutation Proposal | Immediate Closure, Atomic Outcome Plan, Follow-up와 Projection Barrier | Cross-Domain Outcome 계약 |
| Events | Commit된 Character·Item·Downtime 사실 | Outbox 전달, 멱등 Subscriber와 Follow-up Command | Domain Event 계약 |
| Persistence·Recovery | 저장할 Source·State·Item·Activity와 Migration Reference | Snapshot, Journal, Branch, AuthorityEpoch와 Recovery Gate | Persistence 계약 |
| UI·Character Sheet | Permission-aware Character·Item·Downtime Projection | ViewModel, Input Context, Intent와 Epoch-safe 복구 | UI Runtime, Character Sheet UI |
| Journal·Ping | Stable Character·Actor·Item Reference와 공개 Projection | 문서 Anchor, 검색, 안전한 Navigation과 비권위 Ping | Journal Runtime과 Item Presence 계약 |

직접 Store 접근을 금지한다. Downtime은 Character·Item을 직접 수정하지 않고, Inventory는 Character Build를 수정하지 않으며, Character Compiler는 Actor·Encounter·Item Live State를 수정하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 공통 권위, Registry, Snapshot, Command와 Projection 기준
2. [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md) — Source·Build·State 계층을 먼저 이해한다.
3. [`ADR-0002`](../../decisions/ADR-0002-integrated-character-progression.md), [`ADR-0011`](../../decisions/ADR-0011-persistent-character-current-state.md), [`ADR-0014`](../../decisions/ADR-0014-character-data-and-scene-actor-separation.md) — 성장·현재 상태·Actor 분리의 제품 결정
4. [`Character Runtime과 Compiled Character Build 계약`](../../architecture/character-runtime-and-compiled-character-build-contract.md) — Character 전체 권위 구조와 Migration
5. [`Rules Content Grant와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md) — 성장·Item·Effect가 Runtime 기능을 제공하는 방식
6. [`Inventory, ItemInstance와 World Presence Runtime 계약`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md) — Item Instance·Location·Presence와 Transfer
7. [`무기·아이템·공격 프로필 모델`](../../systems/inventory/item-weapon-attack-profile-and-mastery-model.md), [`전리품·아이템 이전 모델`](../../systems/inventory/inventory-loot-and-item-transfer-model.md) — Equipment·Attack·Loot 사용자 규칙
8. [`주문 획득·준비·시전 권한 모델`](../../systems/character/spell-acquisition-preparation-and-cast-access-model.md), [`주문책 저장소와 복사 모델`](../../systems/character/spellbook-repository-and-copying-model.md) — Character와 Item이 만나는 주문 권위
9. [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Downtime Base Mode 진입·중단·복귀
10. [`Game Time, Calendar, Duration과 Scheduler Runtime`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md) — Campaign Time와 Checkpoint
11. [`Downtime Activity, Time Coordination과 Atomic Completion Runtime`](../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md) — Activity·Reservation·Completion 전체 조정
12. [`HP 0·죽음 내성·휴식·자원 회복 모델`](../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md) — Rest와 RecoveryPlan
13. [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md) — Level Up·Crafting·Recovery Atomic Closure
14. [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md), [`UI Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — 저장·재접속·Rollback과 Client 복구
15. [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — Architecture·Integration 완료와 Guide 작성 가능 판정

`SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 이 권위 읽기 순서에 포함하지 않는다.

## 8. 구현·검증 순서

현재 Repository에는 Character·Inventory·Downtime 전용 Implementation Spec이 아직 없다. Main System Guide 단계 완료 후 [`Implementation Specs`](../../specs/README.md) 단계에서 권위 문서의 의존 순서를 타입·모듈·Command·Network·Persistence·Test 계약으로 변환한다.

확정된 의존 관계:

```text
Compiled Build·State·Policy Foundation
→ Character Source·Compiler·Build Registry·State Store
→ Item Build·Instance·Location·Equipment·Presence
→ Effective Capability·Derived View·Spell Repository
→ Game Time·Downtime Session·Activity·Reservation·Progress
→ Rest·Level Up·Preparation·Spellbook·Crafting·Training·Travel Completion Provider
→ Cross-Domain Transaction·Event·Projection Barrier
→ Character Sheet·Inventory·Downtime Projection과 UI
→ Persistence·Migration·Reconnect·Rollback
→ Deterministic Integration Scenario
```

현재 공통 Spec 진입점:

- [`Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md) — Character·Item·Rest RuleExecution이 사용하는 Step Runtime
- [`Standard Recipe Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md) — Resource·Item·Effect 결과를 직접 Store Mutation 없이 Pending Output으로 반환하는 Handler 계약

필수 검증 Scenario:

- Source 변경 없이 Derived Character 수치를 재생성
- Level Up Compile 실패와 기존 Build·State 보존
- Build Migration 중 Resource Identity 보존·제거
- Scene 전환 후 같은 CharacterId와 새 ActorId 연결
- Equip·Unequip와 Capability·Attack Profile 갱신
- 동일 Item 동시 Pickup 경쟁
- Stack Split·Merge 수량 보존
- Ground Presence Stream Out·Materialization 실패와 Item 보존
- 미확인 Item 정보 Negative Disclosure
- Spellbook Item Transfer와 Repository 접근 변경
- Spell Copy 비용·원본·Entry Atomic Commit
- 병렬 Downtime Activity의 Campaign Time 중복 방지
- Rest 중 Encounter와 참가자별 Progress·Recovery
- Level Up Source·Build·State Atomic Activation
- Crafting Input·Output·Ground Presence 원자성
- Travel 중 Scheduler Event·Encounter 중단과 재검증
- Reconnect 중 Pending Choice·Reservation 복구
- Rollback 이전 Epoch Completion·Due·응답 차단
- Character·Inventory·Downtime Projection Barrier와 정보 누출 검사

## 9. 변경 영향 지도

| 변경 유형 | 영향받는 권위 문서 | 영향받는 Specs | Guide 조치 |
|---|---|---|---|
| Character Source·Build·Migration Schema | Character Runtime, Compiled Build Pattern, Rules Grant, Persistence | 향후 Character Compiler·Migration Specs | `UPDATE_REQUIRED` |
| Resource·HP·Preparation State 변경 | Character Runtime, Rest·Recovery, Spell Access, Cross-Domain Integration | 향후 Character State·Recovery Specs | `UPDATE_REQUIRED` |
| CharacterId·ActorId·Ownership 경계 | Character Runtime, Runtime Object, Session, Encounter | 향후 Character Binding·Session Specs | `UPDATE_REQUIRED` |
| ItemDefinition·ItemInstance Schema | Inventory Runtime, Item·Weapon Model, Persistence | 향후 Item Build·Instance Specs | `UPDATE_REQUIRED` |
| Location·Equipment·Presence 경계 | Inventory Runtime, Runtime Object, Interaction·Spatial·Streaming | 향후 Inventory Transfer·Presence Specs | `UPDATE_REQUIRED` |
| SpellRepository·Preparation 정책 | Spell Access, Spellbook, Character Runtime, Inventory | 향후 Spell Access·Repository Specs | `UPDATE_REQUIRED` |
| Downtime Activity·Reservation·Completion 구조 | Downtime Runtime, Game Time, Transaction, Cross-Domain Integration | 향후 Downtime Session·Provider Specs | `UPDATE_REQUIRED` |
| Rest·Level Up·Crafting 결과 경계 | Rest Model, Character Runtime, Inventory Runtime, Cross-Domain Integration | 향후 Domain Completion Specs | `UPDATE_REQUIRED` |
| Time Advance·Scheduler Checkpoint | Game Time, Downtime Runtime, Events, Persistence | 향후 Time·Downtime Integration Specs | `UPDATE_REQUIRED` |
| Projection·Permission·UI 입력 | UI Runtime, Character Sheet, Inventory·Downtime README | 향후 Projection·UI Specs | `UPDATE_REQUIRED` |
| Cache·Batch·Timeout·Retention 수치 | 각 Runtime의 `READY_WITH_DEFAULTS` 항목 | 해당 Operational·Performance Specs | 의미 변화가 있을 때만 갱신 |
| ADR 대체·권위 문서 Lifecycle 변경 | 해당 ADR, Document Lifecycle, Completion Audit | 모든 영향 Spec | `UPDATE_REQUIRED` |

## 10. Authority Documents

### Product

- [`핵심 세션 흐름과 플레이 모드`](../../product/core-session-loop.md)
- [`콘텐츠 자동화, Rollback, 저장과 비목표`](../../product/content-automation-rollback-storage-and-exclusions.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Compiled Build와 Authoritative State 분리 패턴`](../../architecture/compiled-build-and-authoritative-state-pattern.md)
- [`Ruleset Policy Registry, Composition과 Frozen Snapshot`](../../architecture/ruleset-policy-registry-composition-and-frozen-snapshot-runtime-contract.md)
- [`Character Runtime과 Compiled Character Build`](../../architecture/character-runtime-and-compiled-character-build-contract.md)
- [`Inventory, ItemInstance와 World Presence Runtime`](../../architecture/inventory-item-instance-and-world-presence-runtime-contract.md)
- [`Downtime Activity, Time Coordination과 Atomic Completion Runtime`](../../architecture/downtime-activity-time-coordination-and-atomic-completion-runtime-contract.md)
- [`Game Time, Calendar, Duration과 Scheduler Runtime`](../../architecture/game-time-calendar-duration-and-scheduler-runtime-contract.md)
- [`Rules Content Grant와 Capability 모델`](../../architecture/rules-content-grant-capability-model.md)
- [`Character Action·2024 Core Action Runtime`](../../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
- [`Spell Casting Route와 2024 Spell Runtime`](../../architecture/spell-casting-route-and-2024-spell-runtime-contract.md)
- [`Effect, Condition과 Ongoing Runtime`](../../architecture/effect-condition-and-ongoing-runtime-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Cross-Domain Outcome Cascade와 Integration Boundary Runtime`](../../architecture/cross-domain-outcome-cascade-and-integration-boundary-runtime-contract.md)
- [`Domain Event, Outbox, Subscription과 Projection Runtime`](../../architecture/domain-event-outbox-subscription-and-projection-runtime-contract.md)
- [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

### Systems·UI

- [`Character 시스템`](../../systems/character/README.md)
- [`주문 획득·준비·시전 권한 모델`](../../systems/character/spell-acquisition-preparation-and-cast-access-model.md)
- [`주문책 저장소와 복사 모델`](../../systems/character/spellbook-repository-and-copying-model.md)
- [`HP 0·죽음 내성·휴식·자원 회복 모델`](../../systems/character/zero-hit-points-death-saves-rest-and-resource-recovery-model.md)
- [`몬스터·NPC 스탯블록과 JSON Import 모델`](../../systems/character/monster-npc-statblock-and-ingame-json-import-model.md)
- [`Inventory 시스템`](../../systems/inventory/README.md)
- [`무기·아이템·공격 프로필과 Weapon Mastery 모델`](../../systems/inventory/item-weapon-attack-profile-and-mastery-model.md)
- [`인벤토리·전리품·아이템 이전 모델`](../../systems/inventory/inventory-loot-and-item-transfer-model.md)
- [`Downtime 시스템`](../../systems/downtime/README.md)
- [`Time 시스템`](../../systems/time/README.md)
- [`Cross-System Integration 시스템`](../../systems/integration/README.md)
- [`공식 2024 형식 Character Sheet와 실시간 UI`](../../ui/character-sheet/official-2024-character-sheet-and-live-player-ui.md)

### Specs

- [`Implementation Specs Index`](../../specs/README.md)
- [`Recipe Step Runtime Foundation`](../../specs/shared/001-recipe-step-runtime-foundation.md)
- [`Standard Recipe Step Handler Contracts`](../../specs/shared/002-standard-step-handler-contracts.md)
- Character·Inventory·Downtime 전용 Specs: Main System Guide 단계 이후 작성 예정

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

## 11. ADR References

- [`ADR-0002`](../../decisions/ADR-0002-integrated-character-progression.md) — Character 생성·성장과 규칙 콘텐츠 통합
- [`ADR-0011`](../../decisions/ADR-0011-persistent-character-current-state.md) — 캠페인에 유지되는 Character 현재 상태
- [`ADR-0012`](../../decisions/ADR-0012-campaign-scoped-character-ownership.md) — Campaign Character Ownership
- [`ADR-0014`](../../decisions/ADR-0014-character-data-and-scene-actor-separation.md) — Character 영구 데이터와 Scene Actor 분리
- [`ADR-0017`](../../decisions/ADR-0017-derived-fixed-grants-and-stored-selections.md) — 고정 Grant 파생과 선택 결과 저장
- [`ADR-0018`](../../decisions/ADR-0018-source-scoped-spellcasting-profiles.md) — 출처별 SpellcastingProfile
- [`ADR-0019`](../../decisions/ADR-0019-item-bound-persistent-spellbook-repositories.md) — Item-bound Spellbook Repository
- [`ADR-0030`](../../decisions/ADR-0030-item-instances-attack-profiles-and-weapon-mastery.md) — ItemInstance·Attack Profile·Weapon Mastery
- [`ADR-0031`](../../decisions/ADR-0031-zero-hit-points-death-saves-rests-and-resource-recovery.md) — HP 0·DeathSave·Rest·Recovery
- [`ADR-0032`](../../decisions/ADR-0032-monster-npc-statblocks-and-safe-ingame-json-import.md) — Monster·NPC 공통 ActorDefinition과 안전한 Import
- [`ADR-0040`](../../decisions/ADR-0040-official-2024-character-sheet-and-live-player-view.md) — 공식 2024 정보 구조의 실시간 Character Sheet
- [`ADR-0049`](../../decisions/ADR-0049-campaign-character-ownership-hot-join-and-control-assignment.md) — Ownership·Hot Join·Control Assignment 분리
- [`ADR-0051`](../../decisions/ADR-0051-inventory-loot-transfer-and-identification.md) — Loot·Transfer·Identification
- [`ADR-0064`](../../decisions/ADR-0064-immutable-compiled-builds-and-versioned-authoritative-state.md) — 불변 Build와 Versioned State
- [`ADR-0066`](../../decisions/ADR-0066-single-item-instance-with-transactional-world-presence.md) — 단일 ItemInstance와 Transactional World Presence
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Downtime Base Mode와 Overlay·Transition 분리
- [`ADR-0077`](../../decisions/ADR-0077-transactional-domain-events-with-outbox-and-projection-boundaries.md) — Atomic State·Outbox와 Projection Boundary
- [`ADR-0078`](../../decisions/ADR-0078-authoritative-game-time-boundary-durations-and-scheduled-execution.md) — Campaign Time·Duration·Scheduler 권위
- [`ADR-0080`](../../decisions/ADR-0080-downtime-as-time-coordinated-activity-sessions-with-domain-owned-completion.md) — Downtime Activity Session과 Domain-owned Completion
- [`ADR-0087`](../../decisions/ADR-0087-atomic-immediate-closure-and-event-driven-deferred-consequences.md) — Character Build·Crafting·Recovery의 Atomic Closure와 후속 실행

## 12. 알려진 비목표와 측정형 기본값

권위 문서에서 확정된 비목표:

- Source, Build, State, Projection과 Workspace Instance를 하나의 Character·Item Record로 합치지 않는다.
- Live Character Build를 레벨업 중 제자리 수정하지 않는다.
- Actor에 Character 영구 HP·Inventory 복사본을 독립 원본으로 유지하지 않는다.
- UI가 계산한 AC·DC·Capability·Item 위치·Activity Progress를 권위로 저장하지 않는다.
- Item을 Inventory와 Ground에 동시에 존재시키지 않는다.
- Roblox Physics·Animation·Streaming 결과를 Item 위치나 Transfer 완료의 권위로 사용하지 않는다.
- Downtime Runtime이 Character·Inventory·Spell·Rest Store를 직접 수정하지 않는다.
- 현실 시간·오프라인 시간으로 Downtime을 자동 완료하지 않는다.
- 참가자별 독립 Campaign Clock을 만들지 않는다.
- 제작 입력을 먼저 삭제하고 Output을 나중에 생성하지 않는다.
- 대규모 Time Advance에서 Scheduler·Activity·Encounter Checkpoint를 건너뛰지 않는다.
- 상점·경제, AI 전술, Audio와 NPC 대화를 이 시스템의 Core Engine으로 추가하지 않는다.

Implementation Spec에서 측정·확정할 기본값:

- Character Build Cache 보존 수·메모리·Compile Budget
- Projection Debounce와 Derived View Cache 기간
- Character Migration 자동 승인 범위
- Item Presence 정리·보존 기간과 Chunk 목표 수
- Stack 병합 거리·묶음 수, Drop 배치 탐색 반경·재시도
- 전투 중 Pickup·Drop·Transfer 비용의 표시 기본값
- DowntimeSession Participant·Activity 상한
- Choice·Approval Timeout과 DM Fallback
- Activity Progress Checkpoint 간격
- 취소·중단 시 비용·재료·Progress 반환 정책
- Travel 중간 사건 빈도·연쇄 깊이
- Activity·Reservation·Item·Migration Tombstone 보존 기간
- Character·Inventory·Downtime 전용 Implementation Spec 파일과 최종 Module·Type 배치

남은 비차단 작업:

- Character·Inventory·Downtime 도메인 Implementation Specs 작성
- 위 측정형 기본값의 플레이테스트·프로파일링
- Character Sheet·Inventory·Downtime UI의 상세 Spec
- Deterministic Scenario와 CI Test Suite 구현

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR과 현재 존재하는 Specs를 반영했다.
- [x] `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서를 권위 읽기 순서에서 제외했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
