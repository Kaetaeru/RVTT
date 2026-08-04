# Main System Guide: Exploration, Selection, Interaction과 Perception

- Guide Status: CURRENT
- 적용 시스템 상태: GUIDE_CURRENT
- 작성일: 2026-08-05
- 마지막 권위 문서 검토일: 2026-08-05
- Completion Audit: [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)
- 대체하는 Guide: 없음
- 대체된 Guide: 없음

> 이 Guide는 기존 권위 문서를 연결하고 설명한다. 새로운 규칙·결정·API·데이터 구조를 정의하지 않는다.

## 1. 시스템 목적과 사용자 결과

이 Guide는 플레이어가 Exploration에서 캐릭터를 움직이고, 화면의 대상을 Hover·Focus·Selection하고, 자신에게 공개된 정보를 확인하며, 문·상자·함정·비밀문·아이템과 상호작용하고, Search·Study·Hide·공격·주문 등의 행동을 선언한 뒤, 위험이나 적대 상황이 필요한 경우 Encounter로 원자적으로 전환되는 전체 흐름을 설명한다.

사용자에게 보장하는 결과:

- Exploration은 자유롭게 움직일 수 있지만 Actor 하나가 서로 모순되는 이동·상호작용·장시간 행동을 무제한으로 동시에 Commit하지 않는다.
- 클릭 이동과 WASD 이동은 같은 Navigation과 서버 권위 위치를 사용하며 Client가 최종 CFrame을 결정하지 않는다.
- Hover, Keyboard Focus, Persistent Selection과 특정 행동의 Target을 서로 다른 상태로 관리한다.
- 물리 입력은 Semantic Input과 Input Context를 거치며, 가장 위의 유효 문맥 하나만 Q·E 입력을 소비한다.
- Q는 현재 문맥의 취소·거절·한 단계 복귀이고, E는 확정·승인·실행·기본 상호작용이다.
- Q와 E를 후보 순환에 사용하지 않고 별도의 Candidate Navigation 의미 입력을 사용한다.
- Client Preview와 Highlight는 권위 결과가 아니며 실행 전에 최신 서버 Snapshot에서 Frozen Selection Binding을 만든다.
- 상호작용 메뉴는 대상 Class별 하드코딩 목록이 아니라 행위자·대상·아이템·효과·현재 Mode가 제공하는 Capability를 합성한 Projection이다.
- 같은 문 열기 Capability도 Exploration에서는 실시간 Interaction이고 Encounter에서는 Action Opportunity와 비용을 사용하는 Contextual Command가 된다.
- 자동화하기 어려운 즉흥 행동, Help, Influence와 특수 장치는 저장 가능한 DM Adjudication 흐름을 사용한다.
- Visibility, Detection, Knowledge와 Disclosure를 하나의 Boolean으로 합치지 않고 관찰자별로 무엇을 알고 어떤 필드를 받을 수 있는지 결정한다.
- Fog는 지형의 탐험·현재 공개 상태를 관리하지만 Actor, 함정과 비밀문의 Detection을 대신하지 않는다.
- 발견하지 못한 함정, 비밀문, 숨은 Actor와 실제 HP·AC·비밀 DC를 Player Client에 미리 보내고 UI에서만 숨기지 않는다.
- Hover는 Client-safe Candidate의 공개 가능한 정보만 제공하며 숨은 권위 정보 조회 우회로가 아니다.
- 이동 중 상호작용은 필요한 접근 지점에서 안전하게 정지한 뒤 실행하고, 결과에 따라 기존 목적지를 재개·재계획하거나 취소한다.
- 함정과 위험 사건은 필요한 Actor·그룹·지역만 정지시킬 수 있으며 이유 없이 세션 전체를 항상 멈추지 않는다.
- 공격 입력만으로 모든 상황에서 즉시 Encounter를 시작하지 않고 적대 행동·탐지·위험·반응 순서 필요성을 Encounter Proposal로 평가한다.
- Encounter 전환은 진행 중 이동·Selection·RuleExecution·Long Action을 분류하고 관련 Actor의 신규 Command를 Gate한 뒤 하나의 권위 전환 경계에서 Commit한다.
- 재접속·Recovery·Rollback 이후 오래된 Selection, 대상 Revision, Hover Projection, Input Context와 Command를 새 권위 상태에 적용하지 않는다.

적용 범위:

- Exploration Base Play Mode와 Stealth·Travel·Hazard 등 Context
- Actor별 실시간 Movement·RuleExecution·Interaction·Long Action 실행 조정
- 클릭 이동과 WASD Intent의 Exploration 연결
- Semantic Input, Input Context와 Q·E 우선순위
- Hover, Focus, Selection, Target과 Inspection의 분리
- Selection Plan·Session·Candidate·Preview·Frozen Binding
- Observer별 Visibility·Detection·Knowledge·Disclosure
- Sense Capability, Stealth Evidence, Search·Study Discovery와 Noise Event
- Manual Fog Discovery·Current Reveal과 선택형 Assist의 Perception 경계
- Interaction Capability Provider·Query·Contextual Option·Command Proposal
- 기본 E Interaction, Context Action Menu와 DM Adjudication
- 문·레버·상자·Item Presence·함정·비밀문·파괴 Object 상호작용
- 이동 중 상호작용, Hazard Trigger와 Freeze Scope
- Exploration에서 Encounter로의 원자적 전환
- Projection, 저장·재접속·Rollback과 진단 경계

명시적 비범위:

- 공격·주문·2024 Action·주사위·피해·Effect의 구체적인 규칙 해결
- Encounter Initiative·Turn·Reaction·Objective의 전체 Runtime
- Scene Source 제작, Runtime Build, Navigation Layer와 Streaming 내부 계약
- Character Capability·Item Build·Effect Build의 생성 규칙
- Hover Card, Context Menu, HUD와 Inspection Panel의 구체적 화면 배치
- Camera Focus·Follow·벽·지붕 표시 보정의 전체 Presentation 정책
- Roblox Module, Remote, Store와 파일 구조
- Candidate 탐색 반경, Timeout, Cache TTL과 입력 주기의 측정형 기본값
- NPC 자동 대화 트리와 대화 AI

## 2. 전체 구조

### Exploration 실행 문맥

```text
Session Base Mode: exploration
+ Context Set
+ Overlay Stack
+ ActorExplorationExecutionState
→ 현재 Actor와 사용자가 제출할 수 있는 Intent 범위
```

### 입력부터 선택까지

```text
Physical Input
→ Semantic Input Action
→ Top Input Context
→ Intent
→ Spatial Query + Observer-relative Disclosure
→ Candidate Set
→ Hover·Focus·Selection Session
→ Preview
→ Server Revalidation
→ Frozen Selection Binding
```

### 상호작용 실행

```text
Frozen Selection
+ Actor·Target·Item·Effect Capability
+ Base Mode·Context·Role·Control
→ Interaction Query
→ Contextual Interaction Option Projection
→ Command Proposal
→ RuleExecution 또는 DM Adjudication
→ Authority Transaction
→ Projection·Presentation
```

### 인식과 정보 공개

```text
Authority Entity
+ Spatial Visibility Evidence
+ Sense·Stealth·Detection Evidence
+ Fog·Knowledge Record
+ Observer Context
→ Perception Relation
→ Information Disclosure Evaluation
→ Candidate·Hover·Selection·Interaction Projection
```

### 실시간 위험과 Encounter 전환

```text
Movement·Action·Detection·Hazard Event
→ Trigger Candidate 또는 Hostile Outcome
→ Encounter Proposal
→ 참가자·진영·인식 상태 Snapshot
→ 관련 Actor Command Gate
→ 진행 중 실행 분류
→ Initiative·Encounter State Commit
→ Encounter Base Mode
```

### 핵심 구성 요소

- **Exploration Mode Runtime**: Exploration에서 Actor별 실시간 실행 슬롯, Movement 입력 전환, Long Action, Hazard와 Encounter Proposal을 조정한다.
- **Input Context Stack**: 현재 Text Input, Modal, Selection, Overlay와 Base Mode 가운데 가장 높은 유효 문맥 하나에 Semantic Input을 전달한다.
- **Selection Runtime**: Intent별 후보를 만들고 Hover·Focus·Selection·Target을 구분하며 Selection Session과 Frozen Binding을 관리한다.
- **Spatial Query Service**: 거리, 접근, 포함, 점유, 시야와 영역의 공간 Evidence를 Snapshot-bound Query로 제공한다.
- **Perception Runtime**: Observer별 Visibility·Detection·Knowledge Relation과 Client-safe Disclosure를 계산한다.
- **Manual Fog Runtime**: Audience별 Discovery와 Current Reveal 지형 마스크를 소유하며 Actor Detection과 분리된다.
- **Interaction Runtime**: 행위자와 대상의 Capability를 결합해 현재 문맥에서 가능한 Option을 만들고 Command Proposal로 변환한다.
- **Rule Runtime·Transaction Coordinator**: 판정, 비용, Reservation, 상태 변경과 원자 Commit을 수행한다.
- **Encounter Transition Coordinator**: Exploration 실행을 안전 경계에서 분류하고 Encounter Mode로 원자 전환한다.
- **Projection·UI·Presentation**: 허용된 후보·정보·Option·결과를 표시하며 권위 Selection·상태·인식을 직접 만들지 않는다.

## 3. 주요 데이터 흐름

### 3.1 Base Mode, Context, Overlay와 Actor 실행 상태

```text
Base Play Mode
→ exploration

Context Set
→ stealth | travel | hazard | social_adjudication | underwater | mounted | ...

Overlay Stack
→ selection | character_sheet | inventory | system_prompt | dm_authoring | ...

Actor Execution State
→ movement | active rule execution | interaction | long action | locks | pending intent
```

Context는 Capability Filter, Perception·Noise 정책, Selection 강조와 Encounter Proposal 민감도에 기여할 수 있지만 HP, 위치, Knowledge와 Item State를 직접 변경하지 않는다.

Selection과 DM Authoring은 Overlay이며 Exploration Base Mode를 다른 Mode로 바꾸지 않는다. DM에게 승인 요청이 도착해 Input Context 최상단을 차지해도 다른 참가자의 Exploration 실행은 자동으로 중단되지 않는다.

### 3.2 Semantic Input과 Input Context

```text
Physical Key or Pointer
→ Semantic Action
→ Input Context Stack
→ 단일 소비
```

고정 의미:

```text
Q
→ Universal Back / Cancel / Reject

E
→ Universal Confirm / Approve / Execute / Interact
```

우선순위:

```text
Text Input
→ Modal·DM Adjudication Prompt
→ Active Selection·다단계 Interaction
→ Top Overlay
→ Exploration Interaction
→ Global Camera·일반 입력
```

Q 한 번은 가장 가까운 미완성 상태 하나만 취소한다. E는 현재 가장 높은 문맥에서 유효한 행동 하나만 실행한다. 후보 전환은 `CycleCandidateNext`, `CycleCandidatePrevious` 등 별도 의미 입력이다.

### 3.3 Candidate와 Selection 상태

```text
Hover
≠ Focus
≠ Persistent Selection
≠ Action Target
```

- Hover는 Pointer가 가리키는 일시적 Candidate다.
- Focus는 Candidate Navigation의 현재 대상이다.
- Selection은 Inspection 또는 다중 작업을 위해 보존된 Binding이다.
- Target은 특정 Capability 실행에 제출할 Binding이다.

Candidate 생성:

```text
Pointer·Focus Ray·Navigation Intent
→ Snapshot-bound Spatial Query
→ Observer-relative Disclosure Filter
→ Intent별 Eligibility Filter
→ Stable Candidate Ordering
→ Client-safe Candidate Projection
```

Workspace 자식 순서와 숨은 Runtime Object 전체를 Client에서 순회해 후보를 만들지 않는다.

### 3.4 Selection Session, Preview와 Frozen Binding

```text
Intent
→ Compiled Selection Plan
→ Selection Session
→ Draft Bindings
→ Preview Projection
→ Awaiting Confirmation
→ 최신 서버 Snapshot 재검증
→ Frozen Selection Binding
→ Command 또는 RuleExecution
```

Preview는 Highlight, Range, Area, Path, 예상 대상, 비용과 경고를 표시할 수 있지만 권위 결과가 아니다.

Frozen Binding은 선택 단계, Scene, Ruleset Snapshot, Spatial·Visibility Snapshot과 Revision을 고정한다. Capability 정책에 따라 Declaration, Roll, Commit 또는 Trigger 시점에 다시 검증하거나 영역을 재계산한다.

Selection이 Action Opportunity나 Resource와 결합되면 Reservation을 가질 수 있다. Q로 취소할 때 아직 Commit되지 않은 Reservation만 해제한다. 이미 공개·확정된 Roll과 Commit은 단순 Selection 취소로 되돌리지 않는다.

### 3.5 Perception Relation과 Knowledge

```text
Visible
≠ Detected
≠ Known
≠ Disclosed
```

Observer별 Relation은 다음을 결합한다.

- 현재 시각적 관측 상태
- 감각별 Detection 수준
- 이전 발견과 식별 Knowledge
- Sense와 Stealth Evidence
- 마지막 확인 시점과 만료 정책

대상은 Actor에 한정되지 않는다. Scene Object, Item Presence, Trap, Secret Feature, Illusion, Scene Effect, Noise Source와 Area Feature도 Perceivable Entity가 될 수 있다.

은신은 전역 Hidden Boolean이 아니다.

```text
Hide RuleExecution
→ Stealth RollRecord·Evidence
→ Observer별 Detection Contest
→ 각 Perception Relation 갱신
```

한 관찰자의 발견이 다른 관찰자에게 자동 전파되는지는 Knowledge Scope와 공유 정책이 결정한다.

### 3.6 Fog, Discovery와 Current Reveal

```text
Fog Discovery Mask
→ 이전에 탐험한 지형을 기억하는가

Fog Current Reveal Mask
→ 현재 지형을 표시할 수 있는가

Perception Relation
→ 현재 Actor·함정·비밀문·효과를 인식하는가
```

지형 상태:

```text
Unexplored
Remembered
Revealed
```

Remembered 지형은 라이브 Runtime Object와 현재 문 상태의 전체 복사본이 아니다. 안전한 지형 Projection 또는 허용된 기억 표현을 사용한다.

Fog Assist는 Fog Command 후보를 만드는 DM 선택형 보조 기능이다. Assist가 꺼져 있으면 자동 공개하지 않으며, 승인 또는 사전 승인된 Region 정책도 같은 Fog Command·Revision·이력 경로를 사용한다.

### 3.7 Discovery와 정보 공개

```text
Search 또는 Study RuleExecution
→ Roll·DM Adjudication
→ Discovery Proposal
→ Authority Transaction
→ Knowledge Record
→ Observer Projection 갱신
```

Knowledge Record는 일시적 UI 알림이 아니라 저장 가능한 권위 상태다.

정보 Field Group 예시:

- 존재
- 대략적 또는 정확한 위치
- 공개 이름과 식별된 이름
- 진영
- 체력 단계
- 공개 상태
- 실제 HP·AC
- 저항·면역
- Item Rarity·Definition
- Interaction Summary

Observer Context, Detection·Knowledge 수준, 역할과 Mode가 각 Field Group의 공개 여부를 결정한다.

### 3.8 Hover와 Inspection Projection

```text
Pointer Hover
→ Client-safe Selection Candidate
→ Observer-relative Disclosure Evaluation
→ Hover Information Projection
→ Hover Card Presentation
```

```text
Hover
→ 일시적 간략 정보

Selection
→ Binding 보존

Inspection
→ 별도 공개 정책을 통과한 상세 Panel

Target
→ Capability 실행 입력
```

Hover에서 Selection 또는 Inspection으로 전환해도 더 상세한 필드는 새 Projection Policy를 다시 통과한다. Player Client는 Hover에 포함되지 않은 숨은 필드를 로컬 데이터에서 복원할 수 없어야 한다.

### 3.9 Interaction Capability와 Contextual Option

상호작용 Capability는 다음 Source의 기여를 합성한다.

- Character Capability Set
- Item Compiled Build
- Runtime Object Component
- Effect·Condition
- Scene Context
- Encounter·Campaign Policy
- DM Override Registry

```text
Frozen Selection
+ Acting Actor
+ Current Mode·Context·Role·Control
→ Interaction Query
→ Contextual Interaction Option[]
```

Option은 사용 가능, 경고와 함께 사용 가능, 추가 Selection 필요, DM Adjudication 필요, 공개된 차단 또는 숨김 상태를 가진다.

존재 자체가 비밀인 행동은 `blocked`로 설명하지 않고 Projection에서 숨긴다.

### 3.10 Interaction Command와 권위 검증

```text
Contextual Option 선택
→ Interaction Command Proposal
→ Role·Control·Capability·Target Ref 재검증
→ 거리·접근·Visibility·Disclosure 재검증
→ Mode·Opportunity·Item·Resource·Object State 재검증
→ RuleExecution 또는 Domain Command
→ Reservation·Transaction
→ State·Event·Projection
```

Client는 최종 성공 여부, 목표 상태, 최종 위치, 소비량과 피해 결과를 보내지 않는다.

Player 일반 행동과 DM Override는 서로 다른 Command와 감사 경로를 사용한다.

### 3.11 상태형 Object, Item Presence와 Secret Object

문·레버·상자:

```text
Interaction Capability
→ State Transition Proposal
→ Navigation·Visibility·Interaction Binding 변경 준비
→ Authority Commit Point
→ Current State Commit
→ Presentation Transition
```

Tween 완료가 권위 상태가 아니다. 재접속과 Presentation 실패 시 현재 권위 State에 맞춰 Model을 재생성한다.

바닥 아이템:

```text
Item Presence Selection
→ Pick Up Capability
→ ItemInstance Location Transfer Transaction
→ World Presence 정리
```

함정과 비밀문:

- 실제 World State와 Observer별 발견 상태를 분리한다.
- 발견 전 Runtime Identity, Trigger Volume, DC, Recipe와 Interaction Prompt를 Player Client에 보내지 않는다.
- 발견 수준에 따라 단서, 대략적 위치, 정확한 위치, 발동·해제 정보와 Capability를 단계적으로 공개한다.

파괴 Object:

- Attack Object Capability가 Rules Runtime으로 Attack과 Damage를 해결한다.
- Interaction Runtime이 공격 결과를 직접 내구도에 적용하지 않는다.
- 파괴 결과의 이동·시야·엄폐·상호작용 변경은 권위 State와 Binding을 통해 갱신한다.

## 4. 주요 실행 흐름

### 4.1 Exploration 이동 중 Hover와 Inspection

```text
클릭 이동 또는 WASD Intent
→ Navigation Movement Execution 진행
→ Pointer Hover
→ Spatial Candidate Query
→ Observer Disclosure Filter
→ Hover Projection
→ 선택적 Inspection Selection
```

Hover·Inspection은 이동과 병행할 수 있다. Inspection은 대상의 권위 State를 변경하지 않으며, Actor Movement Slot을 자동 점유하지 않는다.

### 4.2 E 기본 상호작용

```text
현재 Focus Candidate
→ Disclosure·Interaction Candidate 확인
→ 안전하고 명확한 기본 Option 하나 확인
→ E Interact
→ Frozen Selection 재검증
→ Interaction Command Proposal
→ 서버 권위 검증
→ RuleExecution·Transaction
→ State·Projection 갱신
```

대표 사례:

```text
닫힌 잠기지 않은 문
→ 열기

열린 문
→ 닫기

공개된 바닥 아이템
→ 줍기
```

주요 Option이 둘 이상이거나 파괴적·고비용·추가 대상 필요·DM 판정 필요 상태라면 E 즉시 실행 대신 Menu·Selection·Confirmation을 연다.

### 4.3 이동 중 상호작용 접근

```text
이동 중 E Interact
→ 현재 Selection 재검증
→ 대상 접근 가능성 확인
→ 필요하면 Interaction Approach Plan
→ 유효 거리의 Progress Checkpoint에서 정지
→ Interaction 실행
→ Object·Path Revision 갱신
→ 재개 정책 적용
```

재개 정책은 권위 Capability·Exploration 계약에 이미 정의된 `resume`, `remain stopped`, `replan`, `cancel` 계열을 사용한다. 문 상태 변경으로 기존 경로가 달라지면 Navigation Runtime이 최신 Snapshot에서 재계획한다.

### 4.4 다단계 Interaction

```text
Context Action Menu Option
→ 추가 대상·점·도구·수치 Selection Plan
→ Selection Session
→ Q로 현재 Step 하나 취소 또는 E로 확정
→ Frozen Binding
→ Interaction Command Proposal
→ 권위 실행
```

Selection Runtime은 대상만 고정한다. 잠금 해제, 함정 해제, Item Transfer와 Object State 변경은 Interaction·Rules·Transaction이 수행한다.

### 4.5 DM Adjudication

```text
Player의 즉흥 Interaction Intent
→ Capability가 DM Adjudication 요구
→ 저장 가능한 Adjudication Request
→ DM Projection·Input Context 최상단
→ E 승인 / Q 거절 / 수정안 선택
→ RuleExecution 재개 또는 종료
```

DM이 Scene Authoring Overlay를 사용 중이어도 승인 문맥이 Q·E를 우선 소비하며 편집 Draft는 보존된다.

NPC 대화 트리를 자동 실행하지 않는다. Influence와 사회적 상호작용은 같은 판정 보조 경계를 사용한다.

### 4.6 Search·Study와 발견

```text
Search 또는 Study Capability 선택
→ Area·Object Selection
→ Frozen Binding
→ RuleExecution·Roll·DM Adjudication
→ Discovery Proposal
→ Knowledge Transaction
→ 해당 Observer·Scope Projection 갱신
→ Hover·Interaction Candidate 갱신
```

발견 결과는 Character, Player, Party, Faction, Global 또는 DM-only Scope를 가질 수 있다. 개인 발견의 Party 공유 기본값은 측정형 기본값이 아니라 Campaign Policy가 소유하는 설정이다.

### 4.7 Hide와 Observer별 Detection

```text
Hide Action
→ Stealth RollRecord
→ Stealth Evidence
→ 관련 Observer Relation 무효화
→ Sense·Spatial Evidence와 Detection Contest
→ Observer별 Detection Level 갱신
→ Candidate·Hover·Target Projection 갱신
```

한 Player가 대상을 발견했다고 모든 Player의 Relation을 자동으로 같은 값으로 바꾸지 않는다.

### 4.8 Manual Fog 편집과 Assist

수동 편집:

```text
DM Fog Tool
→ Discovery 또는 Current Reveal 선택
→ 3D Volume Selection
→ E 확정 / Q 취소
→ Fog Command 검증·Commit
→ Audience Projection 갱신
```

Assist:

```text
적격 Actor의 Region 진입 또는 Portal 변화
→ Assist Proposal
→ DM Preview
→ E 승인 / Q 거절
→ 동일 Fog Command 경로
```

Fog 변경으로 지형이 공개되어도 숨은 함정과 비밀문은 별도의 Detection·Knowledge 조건을 통과해야 한다.

### 4.9 함정 Trigger와 Freeze Scope

```text
Movement Checkpoint·Swept Path
→ Trigger Candidate Query
→ Trap State·Eligibility·Disclosure와 권위 조건 재검증
→ actor_only | affected_group | local_region | session_wide Freeze
→ Trap RuleExecution
→ Effect·State Transaction
→ 이동 Resume·Stop·Encounter Proposal
```

함정은 모든 Actor를 매 프레임 순회하지 않고 이동·상호작용·상태 변화의 의미 Event에서 후보를 평가한다.

### 4.10 같은 Object에 대한 동시 상호작용

```text
두 Actor가 같은 Item·Door·Container Command 제출
→ Authority Ordering
→ 필요한 Store·Object Reservation
→ 최신 Revision 재검증
→ 한 Commit 성공 또는 멱등 결과
→ 나머지 요청에 최신 결과·구조화된 실패 Projection
```

Client Timestamp 선착순을 권위 Ordering으로 사용하지 않는다.

### 4.11 적대 행동과 Encounter Proposal

```text
Exploration Attack·Spell·Hazard·Detection 결과
→ RuleExecution·Event Commit
→ 적대 관계·순서 필요성 평가
→ Encounter Proposal
```

Encounter Proposal 원인에는 적대 행동, 적대 탐지, 순서가 필요한 Hazard, 충돌하는 Reaction, DM Start와 Objective Timer가 포함될 수 있다.

공격 버튼을 눌렀다는 사실만으로 결과 검증 전에 Encounter를 강제 시작하지 않는다.

### 4.12 Exploration → Encounter 원자 전환

```text
Encounter Proposal
→ 참가자·진영·Perception State Snapshot
→ 관련 Actor 신규 Command Gate
→ 진행 중 실행 분류
→ 이동은 마지막 권위 Checkpoint 확정
→ 미완료 Selection 취소 또는 Encounter Context 재검증
→ RuleExecution·Long Action 유지·변환·취소 정책 적용
→ Initiative Roll·Reveal
→ Encounter Session Transaction Commit
→ Encounter Base Mode 활성
```

이미 Commit된 문 상태, Item Transfer, Actor 위치, Effect와 Knowledge는 유지된다. 전환 중 새 이동·공격·상호작용 Command를 관련 Actor에게 허용하지 않는다.

### 4.13 Encounter 종료 후 Exploration 복귀

```text
Encounter 종료 Commit
→ Encounter 전용 Opportunity·실행 정리
→ Exploration Command Policy 복원
→ Long Action 재평가
→ Selection·Follow·Camera Context 복원 후보
```

전투 전 클릭 목적지와 WASD 입력을 자동 재생하지 않는다. 새 Navigation Intent가 필요하다.

### 4.14 재접속과 Recovery

```text
Projection Snapshot·Event Catch-up
→ Base Mode·Context·Actor Execution State 복원
→ Pending Selection·Adjudication·RuleExecution 재검증
→ Observer Context로 Perception·Hover Projection 재생성
→ Runtime Object·Target Incarnation·Revision 확인
→ Input Context와 Command Gate 재구성
→ 안전한 입력 재활성화
```

복구할 수 없는 자발적 이동은 마지막 Movement Checkpoint에서 끝낸다. 일반 Hover, Candidate Highlight, Context Menu 정렬과 Camera Transform은 권위 복구 대상이 아니다.

### 4.15 Rollback

```text
과거 Authority Snapshot을 새 Branch·AuthorityEpoch에서 복원
→ Actor Position·Object State·Fog·Knowledge·Detection Evidence 복원
→ Pending Execution·Reservation 재구성
→ 기존 Selection·Frozen Binding·Hover Projection·Context Token 무효화
→ Client Full Resync
```

Rollback을 UI Selection History 복원이나 현재 Branch의 역방향 Command 연속 실행으로 처리하지 않는다.

## 5. 문서 관계도

### Parent Authority

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 서버 권위, Snapshot Query, Command Mutation, Projection과 Roblox Instance 경계
- [`Session Play Mode, Context, Overlay와 Transition 계약`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Exploration Base Mode, Context, Selection·DM Authoring Overlay와 Transitional Gate
- [`Spatial Query Engine과 Provider 계약`](../../architecture/spatial-query-engine-and-provider-contract.md) — Candidate, Visibility Evidence, 거리·접근·영역과 Snapshot-bound Query
- [`Rule Runtime Orchestrator와 Pending Execution 계약`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md) — Selection 이후 Action·Interaction·Discovery·Hazard 실행의 지속 수명주기
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md) — Revision, Reservation, Ordering과 원자적 Commit

### Child Authority

- [`Exploration 실시간 이동, 행동과 Encounter 전환 Runtime 계약`](../../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md) — Actor별 실시간 실행과 Encounter 전환
- [`Selection, Targeting, Preview와 Frozen Binding Runtime 계약`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md) — Input Context, Candidate, Selection Session, Preview와 Frozen Binding
- [`Interaction Capability, Contextual Command와 Adjudication 계약`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md) — Capability Query, Contextual Option, Command Proposal와 DM 판정
- [`Visibility, Knowledge, Detection과 Hover Information Runtime 계약`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md) — Observer별 Perception, Knowledge, Disclosure와 Hover Projection
- [`Exploration 시스템 인덱스`](../../systems/exploration/README.md) — Exploration 기능별 권위 진입점
- [`Interaction 시스템 인덱스`](../../systems/interaction/README.md) — Interaction 기능별 권위와 세부 모델 진입점
- [`Perception 시스템 인덱스`](../../systems/perception/README.md) — Fog·Perception 기능별 권위 진입점

### References

- [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 Source·State·Command·RuleExecution·Transaction·Projection 용어
- [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Mode·Ready·Command·Projection·Recovery 문맥
- [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation Guide`](../scene/README.md) — Runtime Object Presence, Scene Snapshot, Query와 Movement 기반
- [`Runtime Navigation, Path Planning과 Movement Execution 계약`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md) — 클릭·WASD 이동, Approach Plan, Checkpoint와 Trigger Evidence
- [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md) — Interaction·Perception 대상의 Stable Runtime Identity와 Lifecycle
- [`Networking Command, Event와 Client Synchronization 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md) — 사용자별 Projection, Event Catch-up과 Epoch-safe 재접속
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md) — Semantic Input Router, Context Token과 Client Recovery
- [`공통 입력 UI 인덱스`](../../ui/common-input/README.md) — Q·E와 Input Context UI 진입점
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md) — 물리 키와 Semantic Action, Q·E·1–5 표시 규칙
- [`수동 Fog of War와 선택형 Assist 모델`](../../systems/perception/manual-fog-of-war-and-optional-assist-model.md) — Discovery·Current Reveal 지형 마스크와 DM Assist
- [`무설정 상호작용 프리팹과 상태 전환 모델`](../../systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md) — 문·레버·상자 Asset 제작과 상태 Presentation
- [`함정·비밀문·파괴 Object 모델`](../../systems/interaction/trap-secret-door-and-destructible-object-model.md) — Secret Detection, Trigger, Durability와 Object Link의 세부 제작 모델
- [`현재 Guide 작업 순서`](../CURRENT-GUIDE-WORK-ORDER.md) — Main System Guide 단계의 진행 순서

## 6. 다른 시스템과의 경계

| 인접 시스템 | Exploration·Selection·Interaction·Perception이 제공하는 것 | 상대 시스템이 제공하는 것 | 권위 경계 문서 |
|---|---|---|---|
| Session Runtime | Exploration Intent Gate, Context·Overlay 기여, Encounter Proposal | Base Mode, Transition State, Role·Control·Ready Gate | Session Mode, Exploration 계약 |
| Scene·Navigation | 목적지·Approach Intent, Trigger Query 시점, Movement 중단 요구 | Runtime Scene Snapshot, Path, Checkpoint, Occupancy와 권위 위치 | Scene Guide, Navigation 계약 |
| Runtime Object | Selection Binding, Interaction·Perception Candidate와 공개 View 요구 | Stable RuntimeObjectRef, Component, State, Lifecycle와 Incarnation | Runtime Object, Selection·Interaction 계약 |
| Spatial Query | Intent별 후보·Visibility·접근 Query 요청 | 거리·형상·차단·점유와 공간 Evidence | Spatial Query 계약 |
| Character Action·Spell | Frozen Target, Exploration 사용 문맥, DM Adjudication 진입 | Capability, 비용, Roll, 공격·주문·Action 실행 | Character Action, Spell, Rule Runtime |
| Dice·Effect | Detection·Discovery·Trap·Object Action의 실행 요청 | RollRecord, Effect, Damage, Condition과 결과 | 다음 Rules Guide 영역 |
| Encounter | 참가자·진영·인식 Snapshot과 전환 후보 | Initiative, Turn·Opportunity·Reaction와 Encounter 종료 | Exploration, Encounter Runtime |
| Inventory | Item Presence·Container Interaction Intent | ItemInstance, Location·Ownership Transfer와 Container State | Interaction, Inventory Runtime |
| Fog·Knowledge | Audience별 지형 마스크, Perception Relation과 공개 Field | Scene Geometry, Character Sense·Rule Result와 Campaign Policy | Visibility Runtime, Manual Fog |
| UI·Input | Client-safe Candidate, Hover, Option, Prompt와 Validation State | ViewModel, Input Context, Panel·Card·Highlight와 Semantic Intent | Selection, UI Runtime, Common Input |
| Camera·Presentation | 공개 대상 Focus·Inspection·Transition Hint | Camera Request, Highlight, Tween, VFX와 화면 효과 | Camera·Presentation Runtime |
| Journal·Ping | 공개된 Object·Point Selection과 safe navigation Intent | Document·Anchor·Permission·Search와 비권위 Ping | Journal Runtime, Selection 계약 |
| Persistence·Network | 저장 가능한 Selection·Knowledge·Execution Ref와 Projection 요구 | Snapshot·Journal·Epoch·Catch-up·Full Resync | Networking, Persistence, 각 Runtime 계약 |
| Diagnostics·Simulation | Intent·Selection·Query·Interaction·Detection·Transition Correlation | Trace, Fault Injection, Scenario와 Assertion | Diagnostics·Simulation Runtime |

고정 경계:

- Exploration Runtime이 Attack, Spell, Item, Trap Effect와 Object Damage를 직접 계산하지 않는다.
- Selection Runtime이 이동·공격·상호작용·Knowledge State를 직접 변경하지 않는다.
- Client Preview와 Hover Projection을 권위 Binding·정보 원본으로 사용하지 않는다.
- Interaction UI와 Context Menu가 Capability·Object State의 저장 원본이 아니다.
- Perception Runtime이 Capability의 최종 대상 적격성과 Interaction 성공 여부를 단독 결정하지 않는다.
- Spatial Query의 Line of Sight Evidence가 곧 최종 Detection이나 정보 공개를 뜻하지 않는다.
- Fog Reveal이 숨은 Actor·Trap·Secret Door 발견을 자동 의미하지 않는다.
- Camera 위치와 Streaming Interest가 Visibility·Knowledge·Disclosure를 우회하지 않는다.
- 발견 전 Secret Runtime Identity와 Capability를 Player Projection에 포함하지 않는다.
- DM Full View를 Player Preview Client에 전송한 뒤 UI에서만 숨기지 않는다.
- DM Override와 Player 일반 행동을 같은 Command로 위장하지 않는다.
- Encounter 전환이 이미 Commit된 Actor·Object·Item·Effect·Knowledge State를 초기화하지 않는다.

## 7. 추천 읽기 순서

1. [`Runtime Foundation과 Authority Guide`](../runtime/README.md) — 공통 권위·실행·Projection 용어
2. [`Session, Networking, Persistence와 Recovery Guide`](../session/README.md) — Base Mode, Role·Control, Client Ready와 Recovery 문맥
3. [`Scene, Streaming, Runtime Object, Spatial Query와 Navigation Guide`](../scene/README.md) — 월드 Presence, Snapshot, Query와 Movement 기반
4. [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md) — 서버 권위와 Query·Mutation·Projection 불변식
5. [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md) — Exploration Mode와 Selection·DM Authoring Overlay
6. [`ADR-0071`](../../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md) — Input Context, Selection Session과 Frozen Binding 결정
7. [`Selection, Targeting, Preview와 Frozen Binding Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md) — 후보부터 실행 대상 고정까지
8. [`ADR-0073`](../../decisions/ADR-0073-observer-relative-visibility-knowledge-and-hover-projections.md) — Observer-relative Perception·Knowledge·Hover 결정
9. [`Visibility, Knowledge, Detection과 Hover Information Runtime`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md) — 공개 가능한 후보와 정보 Field
10. [`ADR-0035`](../../decisions/ADR-0035-manual-fog-masks-and-optional-region-assist.md) — 수동 Fog 마스크와 선택형 Assist
11. [`수동 Fog of War와 선택형 Assist 모델`](../../systems/perception/manual-fog-of-war-and-optional-assist-model.md) — 지형 공개와 DM 편집 흐름
12. [`ADR-0072`](../../decisions/ADR-0072-contextual-interactions-as-capability-derived-commands.md) — Capability-derived Contextual Interaction 결정
13. [`Interaction Capability, Contextual Command와 Adjudication`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md) — 선택에서 Command·판정까지
14. [`Interaction 시스템 인덱스`](../../systems/interaction/README.md) — 프리팹·Trap·Secret·Destructible 세부 모델
15. [`ADR-0076`](../../decisions/ADR-0076-real-time-exploration-with-actor-scoped-execution-and-atomic-encounter-transition.md) — Actor-scoped Exploration과 원자 Encounter 전환
16. [`Exploration 실시간 이동, 행동과 Encounter 전환 Runtime`](../../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md) — 실시간 실행·Hazard·전환
17. [`공통 입력 UI 인덱스`](../../ui/common-input/README.md) — UI Input Context 진입점
18. [`Completion Audit`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md) — Architecture 공백 해소와 Guide 작성 가능 판정

`visibility-senses-stealth-and-detection-model.md`는 `SUPERSEDED`이므로 현재 권위 읽기 순서에서 제외한다.

## 8. 구현·검증 순서

다음은 권위 문서의 의존 관계와 후속 구현 항목을 통합한 Spec 작성 순서다.

```text
Semantic Input Router·Input Context Spec
→ Selection Plan·Session·Candidate·Preview Spec
→ Frozen Selection Binding·Reservation·Revision Spec
→ Observer Context·Perception Relation·Sense·Stealth Spec
→ Knowledge Record·Disclosure·Hover Projection Spec
→ Manual Fog Mask·Audience·Assist Command Spec
→ Interaction Capability Registry·Query·Option Projection Spec
→ Interaction Command·DM Adjudication·Concurrency Spec
→ Door·Container·Item Presence·Secret Object Integration Spec
→ Exploration Actor Execution Slot·Long Action Spec
→ Movement Interaction Approach·Hazard Freeze Spec
→ Encounter Proposal·Atomic Transition Spec
→ Reconnect·Rollback·Projection Recovery Spec
→ Diagnostics·Simulation·Security Integration
```

필수 검증 흐름:

- 가장 위의 Input Context 하나만 Q·E를 소비
- Q 한 번이 Selection Step 또는 Overlay 하나만 취소
- Q·E와 Candidate Next·Previous 입력 분리
- Hover·Focus·Selection·Target 상태가 서로 오염되지 않음
- Intent별 Candidate만 포함되고 Stable Ordering을 사용
- 미공개 Runtime Object가 Candidate·Hover 응답에 포함되지 않음
- Client Preview와 오래된 Frozen Binding이 권위 실행에 사용되지 않음
- Selection 취소가 미Commit Reservation만 해제
- Player·DM·Observer가 서로 다른 Disclosure Projection을 받음
- Visible·Detected·Known·Disclosed의 독립 상태 검증
- Tremorsense·Hearing 등 감각이 허용된 정보 정밀도만 공개
- 한 Observer의 Detection이 다른 Observer에게 자동 전파되지 않음
- Search·Study Discovery와 Knowledge Scope 저장·재접속 복구
- Fog Revealed 영역 안의 숨은 Trap이 Detection 전에는 미공개
- Remembered 지형이 라이브 Object State를 노출하지 않음
- Hover가 실제 HP·AC·비밀 DC 조회 우회로로 작동하지 않음
- 안전한 기본 Interaction 하나일 때만 E 즉시 실행
- 다중·파괴적·고비용 Interaction이 Selection·Confirmation을 요구
- DM Adjudication 중 Q·E가 Authoring Context보다 우선하되 Draft 보존
- Client가 목표 상태·성공·비용 결과를 제출해도 서버가 신뢰하지 않음
- 같은 Door·Item에 대한 동시 Command가 하나의 Commit 또는 멱등 결과로 정규화
- 문 상태 변경이 Navigation·Visibility·Interaction Binding에 일관되게 반영
- Item Presence 제거와 ItemInstance Transfer의 부분 성공 방지
- 감지 전 Trap·Secret Door Identity·Prompt·DC·Recipe 미복제
- Exploration 이동 중 Hover·Inspection 병행
- 이동 중 Interaction이 접근 Checkpoint에서 정지하고 결과 후 재개 정책 적용
- Hazard가 필요한 Freeze Scope만 적용하고 Effect를 중복 실행하지 않음
- 공격 선언만으로 Encounter가 무조건 즉시 시작되지 않음
- Encounter 전환 중 신규 관련 Actor Command 거부
- 이동·Selection·Long Action·RuleExecution을 전환 정책에 따라 안전하게 분류
- Encounter 종료 후 이전 WASD·목적지를 자동 재생하지 않음
- 재접속 후 Pending Selection·Adjudication·Perception Projection 재검증
- Rollback 후 이전 Epoch Selection·Hover·Context Token·Command 거부

Guide는 실제 키 바인딩, Module·Remote·Store 이름과 알고리즘을 정하지 않는다. 이는 Implementation Specs 단계가 소유한다.

## 9. 변경 영향 지도

| 변경 유형 | 함께 확인할 권위 문서 | 영향받을 Specs | Guide 조치 |
|---|---|---|---|
| Exploration Mode·Context·실행 슬롯 의미 변경 | Session Mode, Exploration Runtime | Command Gate·Actor Execution·Long Action | `UPDATE_REQUIRED` |
| Q·E·Semantic Input·Context 우선순위 변경 | Selection Runtime, UI Runtime, Common Input | Input Router·Context Token·Prompt | `UPDATE_REQUIRED` |
| Selection Step·Candidate·Frozen Binding 변경 | Selection, Spatial Query, Rule Runtime | Candidate·Preview·Binding·Reservation | `UPDATE_REQUIRED` |
| Visibility·Detection·Knowledge 의미 변경 | Visibility Runtime, Effect·Rules, Perception Index | Relation·Sense·Contest·Persistence | `UPDATE_REQUIRED` |
| Disclosure Field·Hover 정보 변경 | Visibility Runtime, Networking, UI | Projection Schema·Hover ViewModel·Security Test | `UPDATE_REQUIRED` |
| Fog Mask·Audience·Assist 변경 | Manual Fog, Visibility Runtime, Scene·UI | Fog Command·Projection·Undo | `UPDATE_REQUIRED` |
| Interaction Capability·Option 의미 변경 | Interaction, Character Action, Runtime Object | Registry·Query·Command Builder | `UPDATE_REQUIRED` |
| DM Adjudication·Override 경계 변경 | Interaction, Rule Runtime, UI Input | Prompt·Execution Resume·Audit | `UPDATE_REQUIRED` |
| Door·Trap·Secret·Destructible 상태 의미 변경 | Interaction Models, Runtime Object, Scene Compiler | Object State·Binding·Disclosure | `UPDATE_REQUIRED` |
| Movement 중 Interaction·Hazard 정책 변경 | Exploration, Navigation, Interaction | Approach·Checkpoint·Freeze | `UPDATE_REQUIRED` |
| Encounter Proposal·전환 분류 변경 | Exploration, Session, Encounter Runtime | Transition Coordinator·Recovery | `UPDATE_REQUIRED` |
| Knowledge·Selection·Execution 저장 정책 변경 | Visibility, Selection, Persistence | Snapshot·Journal·Migration | `UPDATE_REQUIRED` |
| 후보 반경·Timeout·TTL·전송 주기 변경 | 각 Architecture의 남은 기본값 | Configuration·UX·Load Test | 필요 시 갱신 |

## 10. Authority Documents

### Product

- [`플랫폼·이동·입력 범위`](../../product/platform-movement-and-input-scope.md)

### Architecture

- [`Runtime Architecture Principles`](../../architecture/runtime-architecture-principles.md)
- [`Session Play Mode, Context, Overlay와 Transition`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
- [`Exploration 실시간 이동, 행동과 Encounter 전환 Runtime`](../../architecture/exploration-real-time-movement-action-and-encounter-transition-runtime-contract.md)
- [`Selection, Targeting, Preview와 Frozen Binding Runtime`](../../architecture/selection-targeting-preview-and-frozen-binding-runtime-contract.md)
- [`Interaction Capability, Contextual Command와 Adjudication`](../../architecture/interaction-capability-contextual-command-and-adjudication-contract.md)
- [`Visibility, Knowledge, Detection과 Hover Information Runtime`](../../architecture/visibility-knowledge-detection-and-hover-information-runtime-contract.md)
- [`Spatial Query Engine과 Provider`](../../architecture/spatial-query-engine-and-provider-contract.md)
- [`Runtime Navigation, Path Planning과 Movement Execution`](../../architecture/runtime-navigation-path-planning-and-movement-execution-contract.md)
- [`Runtime Object System과 Entity Lifecycle`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
- [`Rule Runtime Orchestrator와 Pending Execution`](../../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
- [`Command Ordering, Logical Time와 Transaction Coordinator`](../../architecture/command-ordering-logical-time-and-transaction-coordinator-contract.md)
- [`Networking Command, Event와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- [`UI Projection, ViewModel, Input Context와 Recovery Runtime`](../../architecture/ui-projection-view-model-input-context-and-recovery-runtime-contract.md)

### Systems·UI

- [`Exploration 시스템 인덱스`](../../systems/exploration/README.md)
- [`Interaction 시스템 인덱스`](../../systems/interaction/README.md)
- [`Perception 시스템 인덱스`](../../systems/perception/README.md)
- [`공통 입력 UI 인덱스`](../../ui/common-input/README.md)
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
- [`수동 Fog of War와 선택형 Assist 모델`](../../systems/perception/manual-fog-of-war-and-optional-assist-model.md)
- [`무설정 상호작용 프리팹과 상태 전환 모델`](../../systems/interaction/zero-metadata-interaction-prefab-and-state-transition-model.md)
- [`함정·비밀문·파괴 Object 모델`](../../systems/interaction/trap-secret-door-and-destructible-object-model.md)

### Specs

- 아직 없음. 이 Guide의 구현·검증 순서를 기준으로 `specs/` 단계에서 작성한다.

### Audits

- [`Runtime Architecture Completion과 Main System Guide 준비도 감사`](../../audits/runtime-architecture-completion-and-main-guide-readiness-audit.md)

### 현재 권위에서 제외

- `systems/perception/visibility-senses-stealth-and-detection-model.md` — `SUPERSEDED`; 현재 권위는 Visibility·Knowledge·Detection Architecture와 ADR-0073이다.

## 11. ADR References

- [`ADR-0023`](../../decisions/ADR-0023-composable-targeting-and-spatial-query-model.md) — 조합 가능한 Targeting과 공통 Spatial Query
- [`ADR-0035`](../../decisions/ADR-0035-manual-fog-masks-and-optional-region-assist.md) — 수동 Fog Mask와 선택형 Region Assist
- [`ADR-0036`](../../decisions/ADR-0036-observer-relative-perception-senses-stealth-and-rule-points.md) — Observer-relative Perception, Sense, Stealth와 Rule Point
- [`ADR-0037`](../../decisions/ADR-0037-zero-metadata-interaction-prefabs-and-state-snapshot-transitions.md) — 무설정 Interaction Prefab과 State Snapshot Transition
- [`ADR-0038`](../../decisions/ADR-0038-zero-metadata-hazards-secret-passages-and-destructible-objects.md) — 무설정 Trap, Secret Passage와 Destructible Object
- [`ADR-0048`](../../decisions/ADR-0048-continuous-gridless-movement-pc-only-and-no-combat-wasd.md) — PC 전용 연속 무격자 이동과 전투 WASD 제외
- [`ADR-0055`](../../decisions/ADR-0055-snapshot-bound-typed-spatial-query-and-navigation-boundary.md) — Snapshot-bound Spatial Query와 Navigation 경계
- [`ADR-0061`](../../decisions/ADR-0061-persistent-rule-execution-orchestrator-and-nested-timing-windows.md) — 지속 RuleExecution과 중첩 Timing Window
- [`ADR-0062`](../../decisions/ADR-0062-ordered-reservations-and-atomic-authority-transactions.md) — Ordered Reservation과 Atomic Authority Transaction
- [`ADR-0070`](../../decisions/ADR-0070-orthogonal-session-modes-contexts-overlays-and-transitions.md) — Base Mode·Context·Overlay·Transition의 직교 분리
- [`ADR-0071`](../../decisions/ADR-0071-input-context-selection-sessions-and-frozen-bindings.md) — Input Context, Selection Session과 Frozen Binding
- [`ADR-0072`](../../decisions/ADR-0072-contextual-interactions-as-capability-derived-commands.md) — Contextual Interaction을 Capability-derived Command로 구성
- [`ADR-0073`](../../decisions/ADR-0073-observer-relative-visibility-knowledge-and-hover-projections.md) — Observer-relative Visibility·Knowledge와 Hover Projection
- [`ADR-0076`](../../decisions/ADR-0076-real-time-exploration-with-actor-scoped-execution-and-atomic-encounter-transition.md) — Actor-scoped Real-time Exploration과 Atomic Encounter Transition

## 12. 알려진 비목표와 측정형 기본값

### 비목표

- Exploration을 행동 경제가 없다는 이유로 무제한 병렬 실행 상태로 만들지 않는다.
- Client 최종 CFrame, Preview Target과 Hover 데이터를 권위 상태로 사용하지 않는다.
- Q·E를 Candidate 순환 키로 사용하지 않는다.
- Selection Runtime이 공격·이동·상호작용을 직접 실행하지 않는다.
- Interaction을 Object Class별 Remote와 하드코딩 Menu로 만들지 않는다.
- ProximityPrompt와 Workspace Model을 상호작용 권위 원본으로 사용하지 않는다.
- NPC 자동 대화 트리를 만들지 않는다.
- Visible·Detected·Known·Disclosed를 하나의 Boolean으로 합치지 않는다.
- Fog를 Actor·Trap·Secret Door Detection Engine으로 사용하지 않는다.
- 실제 HP·AC·비밀 DC·숨은 상태를 Player Client에 전송한 뒤 UI에서만 숨기지 않는다.
- Hover를 숨은 Entity 검색 API로 사용하지 않는다.
- 발견 전 Secret Runtime Identity를 Player Projection에 포함하지 않는다.
- 공격 Input만으로 모든 상황에서 Encounter를 즉시 시작하지 않는다.
- 함정 발동 시 이유 없이 항상 Session 전체를 Freeze하지 않는다.
- 전투 전환과 진행 중 이동·실행 정리를 서로 다른 비원자적 상태로 Commit하지 않는다.
- Encounter 종료 후 이전 WASD 입력과 목적지를 자동 재생하지 않는다.

### 측정형 기본값

다음은 Architecture 의미를 바꾸지 않는 구현·측정 기본값이며 각 권위 문서가 소유한다.

- Candidate 탐색 반경, 화면 가중치, Grouping과 Next·Previous 기본 물리 키
- Preview 갱신 주기, 후보 축약 기준과 Selection Session Timeout
- Context Action Menu 정렬 가중치와 후보 최대 표시 수
- 자동 Focus 상호작용 거리, 반복 입력 Debounce와 DM Adjudication Timeout
- Perception Relation 재평가 주기와 공간 무효화 Batch 크기
- Hover Projection Cache TTL과 체력 단계 임계값
- 개인 발견의 Party 자동 공유 Campaign 기본값
- Noise Event 감쇠 곡선
- WASD Intent 전송·서버 확인 주기와 Actor별 실행 Queue 상한
- 이동 중 상호작용 자동 정지 거리
- 적대 행동 후 Encounter Proposal 지연 상한
- Hazard Freeze 반응 시간과 동시 이동 정렬 기준
- Long Exploration Action의 기본 취소·중단 정책
- Manual Fog Volume·Assist Proposal의 편집·표시 수치

이 값은 기준 Scene, 후보 수, 동시 Actor, Network 지연과 권한별 Projection Scenario를 측정한 뒤 Implementation Spec에서 확정한다.

## 13. Guide 검증 체크리스트

- [x] 모든 핵심 문장이 Authority Document에 근거한다.
- [x] 새로운 제품 규칙이나 Architecture 결정을 추가하지 않았다.
- [x] 모든 링크가 존재한다.
- [x] Parent·Children·References를 구분했다.
- [x] 최신 ADR을 반영했고 Specs가 아직 없음을 명시했다.
- [x] `SUPERSEDED` Perception 문서를 권위 읽기 순서에서 제외했다.
- [x] 권위 문서와 충돌하는 요약이 없다.
- [x] 변경 영향 지도가 최신이다.
- [x] Guide Status가 실제 상태와 일치한다.
