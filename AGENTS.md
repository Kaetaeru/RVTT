# RVTT Agent Rules

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-08
- 적용 범위: RVTT 저장소에서 작업하는 모든 AI 에이전트와 자동화 도구

이 문서는 RVTT 저장소의 최상위 작업 규약이다.

목표는 많은 코드를 빠르게 생성하는 것이 아니다. 최신 확정 제품 방향과 권위 경계를 유지하면서 오류를 찾고 수정하기 쉽고, 장시간 세션에서도 안정적으로 동작하는 기능을 검증 가능한 단위로 완성하는 것이다.

이 문서는 현재 Phase나 임시 작업 번호를 복제하지 않는다. **현재 실행 순서와 테스트 상태는 항상 현재 Branch·Pull Request와 Work Order에서 다시 확인한다.**

현재 상태 진입점:

```text
AGENTS.md
→ 현재 Branch·Pull Request 확인
→ docs/remake/CURRENT-WORK-ORDER.md
→ 관련 Product·Architecture·UI·ADR
→ implementation/roblox/CURRENT-WORK-ORDER.md
→ AGENT-TEST-STATUS.md
→ 현재 Task·Manifest·Source·Test
```

---

## 1. 프로젝트의 고정 전제

별도의 새로운 사용자 결정과 확정 ADR이 있기 전까지 다음을 변경하지 않는다.

1. RVTT는 Roblox에서 D&D 세션을 진행하는 게임형 VTT다.
2. 제품 기준점은 **DM이 실시간으로 진행하는 Baldur's Gate형 D&D 세션**이다.
3. 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`다.
4. 내부 ID, 저장 데이터, 권위 상태와 실행 로직은 표시 언어와 분리한다.
5. 초기 지원 기기는 **PC 키보드·마우스**다. Touch·Controller 전용 UI를 현재 Release 범위에 억지로 추가하지 않는다.
6. Token은 Roblox Avatar가 아니라 **리그 없는 OBJ·MeshPart 기반 3D Token**을 기본으로 한다.
7. 권위 이동은 **연속 무격자 좌표**를 사용하고 월드 비율은 `5 ft = 4 studs`다. 5피트 논리 이동 격자와 격자 중심 강제 Snap을 사용하지 않는다.
8. Scene Editor의 가상 Grid가 존재하더라도 그것은 배치·정렬용 Authoring Cursor일 뿐, 이동·거리·규칙 판정의 권위 데이터가 아니다.
9. Exploration에서는 목적지 Click 이동과 Token WASD 이동을 허용한다. 두 입력은 같은 Traversal·Body Profile·Movement Authority를 사용한다.
10. Encounter에서는 Token WASD 직접 이동을 허용하지 않는다. 이동은 경로·비용·위험 Preview 뒤 확정하며 WASD는 자유 Camera 이동에 사용한다.
11. PC 직접 입력의 상위 의미는 다음과 같다.

```text
Left Click
→ Primary Pointer · 선택 또는 표시된 기본 행동

Right Click
→ Context Action Pointer

Middle Drag
→ Camera Orbit

Q
→ 최상위 Context 한 단계 닫기·취소

E
→ Preview·선택·승인·확정 실행

ESC
→ Gameplay 의미 없음
```

12. 비-DM 참가자는 Session 연결 시 기본적으로 **Observer**로 시작하고, DM의 Character Assignment 뒤 Player Projection으로 전환한다.
13. Character Owner, Runtime Controller와 Session Role을 서로 다른 권위 개념으로 유지한다.
14. 중요한 규칙, 영구 상태, 권한, Transaction, Roll 결과와 확정 이동의 최종 권한은 서버가 가진다.
15. Source, Compiled Build, Authoritative State, Projection과 Presentation을 분리한다. UI·Workspace Instance·VFX·Camera는 권위 원본이 아니다.
16. Character Sheet는 영구 데이터 저장 원본이 아니라 **Character Progression Source·Compiled Character Build·Persistent Character State를 읽고 Command를 제출하는 Projection·Control Surface**다.
17. Official Sheet, VTT Management View, Character Console과 Inventory는 같은 권위 Character Projection·Revision·Command 경계를 사용한다.
18. Player의 상시 전장 UI는 Character Console 중심이다. Player·Observer 상시 UI에 Minimap·별도 Map 화면·Objective Tracker를 다시 추가하지 않는다.
19. Character Console은 Attack/Action Matrix와 Spell Matrix를 분리하고, 상단 Resource Rail과 사용자 설정 1–4행 Action Matrix를 사용한다.
20. DM Workspace는 독립 Window Module을 사용한다. Top Authoring Strip과 Left Inspector는 기본 Layout이지 고정 단일 Panel 구조가 아니다.
21. 완전 자동화가 부적절한 규칙은 `Guided` 또는 `Assisted` 흐름과 DM 승인·판정 보조로 구현한다. 어려운 규칙을 임의 단순화해 `Executable`로 표시하지 않는다.
22. 2024 기본 규칙의 Player Character 콘텐츠 전체를 최종 지원 범위로 추적한다. 한 번에 모두 구현한다는 뜻은 아니며 각 콘텐츠는 명시적인 구현·검증 상태를 가진다.
23. 개발·테스트 Rule Profile과 공개 Release Rule Profile을 분리한다. Owner-only Private Rule Content를 공개 Git Tree·Release Artifact·권한 없는 Projection에 포함하지 않는다.
24. 공개 Release Rule Content는 재배포 권한이 확인된 Public Profile을 사용하며 현재 기본은 `rvtt.core.rules` SRD 범위다.
25. Campaign Survival은 모든 Campaign에 강제하지 않는다. Narrative·Standard·Survival·Custom Profile과 Versioned Policy Snapshot을 사용하고 정확한 소비량·결핍 수치는 활성 Ruleset·Source Pack Definition이 소유한다.
26. DM-authored Actor·Token은 검증된 Asset Registry와 Strict Data Schema를 사용한다. AI 결과는 항상 Untrusted Draft이며 Script·Remote·URL Callback·미등록 Recipe 실행과 자동 Publish를 허용하지 않는다.
27. 공식 Stat Block과 CR을 시스템이 임의로 자동 재조정하지 않는다.
28. NPC 자동 대화 시스템, 음악, 환경음, 공격·주문·UI SFX, 음성 채팅과 음성 대사는 현재 제품 비목표다.
29. 중도 참가·재접속·서버 복구·Rollback·Migration·Permission-safe Resync를 제품 완료 조건에 포함한다.
30. 최적화, 안정성, 접근성, 오류 격리와 수정 가능한 코드 구조는 모든 기능의 완료 조건이다.

확정된 세부 제품 결정은 `docs/remake/decisions/`의 최신 ADR과 연결된 권위 문서를 따른다.

---

## 2. 지시와 문서의 우선순위

저장소 내부 내용이 충돌할 때 다음 순서를 따른다.

1. 사용자가 현재 작업에서 명시적으로 내린 최신 결정
2. 상태가 `확정` 또는 `Accepted`인 ADR
3. 확정 Product·Architecture·System·Global UI Policy
4. 준비 완료 Implementation Spec·승인된 Additive Delta
5. 현재 Work Order·Task·Issue·Manifest
6. 이 `AGENTS.md`
7. 기존 코드의 관행

이 순서는 저장소와 제품 결정에 적용한다. 플랫폼의 시스템 지시, 보안 정책과 도구 제한보다 우선하지 않는다.

추가 규칙:

- User Guide, HTML Mockup과 Main System Guide는 권위 Reference다. 상위 Product·Architecture·ADR과 충돌하면 상위 권위를 따른다.
- Work Order와 Status 문서는 **실행 순서와 현재 상태**를 소유하지만 Product·Architecture 결정을 새로 만들거나 상위 ADR을 약화하지 않는다.
- 기존 Source가 확정 문서와 충돌하면 기존 Source를 무조건 보존하지 않는다. 충돌을 보고하고 최신 확정 방향에 맞춘다.
- 오래된 `SUPERSEDED`, `DISCONTINUED`, `ARCHIVED` 문서는 현재 판단의 권위 근거로 사용하지 않는다.
- 확정 문서끼리 충돌하면 중요한 동작을 추측하지 않는다. 안전하게 진행 가능한 범위만 수행하고 충돌을 명시한다.

---

## 3. Branch, 기획과 구현을 분리한다

### Branch를 하드코딩하지 않는다

`planning/rvtt-remake` 같은 과거 Branch 이름을 현재 작업 Branch라고 가정하지 않는다.

작업 시작 시 다음을 실제 Repository에서 확인한다.

```text
Default Branch
Current Branch
Open Pull Request
PR Base / Head
Current Work Order
Current Task
```

현재 Feature Branch 또는 Pull Request가 존재하면 그 Branch의 최신 권위 문서와 기존 변경을 먼저 읽는다.

### 기획 작업

- 목표와 비목표를 구분한다.
- 사용자가 실제로 수행하는 흐름을 먼저 정의한다.
- 확정, 제안과 보류를 표시한다.
- 상태, 예외, 실패 흐름과 완료 조건을 적는다.
- 되돌리기 어려운 제품·Architecture 결정은 ADR로 기록한다.
- 구현 세부사항을 제품 요구보다 먼저 확정하지 않는다.

기획만 요청받았는데 Production Source를 만들지 않는다.

### 구현 작업

사용자가 구현을 요청했을 때만 Production Source를 변경한다.

- 관련 기획, 최신 ADR과 현재 Work Order를 먼저 읽는다.
- 연결된 기존 Source·Type·Registry·Schema·Remote·Migration·Test를 조사한다.
- 같은 책임을 가진 기존 모듈을 재사용한다.
- 가장 작은 응집된 수직 기능 단위를 선택한다.
- 서버, 클라이언트, UI, 저장, 번역, 오류 처리와 검증을 함께 고려한다.
- 문서에 없는 중대한 규칙을 구현 과정에서 몰래 확정하지 않는다.
- Production Source, Test, Migration과 Build 정의는 `implementation/` Root가 소유한다.

다른 사람이나 에이전트의 기존 변경을 임의로 되돌리거나 덮어쓰지 않는다.

---

## 4. 작업 시작 절차

모든 작업은 다음 순서로 시작한다.

1. 이 `AGENTS.md`를 읽는다.
2. 현재 Branch·Open PR·PR Head를 확인한다.
3. `docs/remake/CURRENT-WORK-ORDER.md`와 관련 ADR을 읽는다.
4. 구현·Runtime 작업이면 `implementation/roblox/CURRENT-WORK-ORDER.md`와 `AGENT-TEST-STATUS.md`를 읽는다.
5. 변경 대상과 연결된 Product·Architecture·System·UI·Spec 문서를 읽는다.
6. 같은 책임을 가진 기존 Source, 콘텐츠 ID, 번역 키, Schema, Remote와 데이터 구조를 검색한다.
7. 현재 Branch의 기존 변경과 병행 작업을 확인한다.
8. 작업 범위와 완료 조건을 짧게 정의한다.
9. 필요한 Static·Unit·Integration·Studio·Human 검증 경계를 정한다.

파일명, 모듈 위치, API와 권위 소유자를 추측해 중복 구조를 만들지 않는다.

현재 작업 상태가 바뀌면 해당 상태를 소유하는 Work Order 또는 `AGENT-TEST-STATUS.md`도 같은 변경에서 갱신한다.

---

## 5. 작업 단위 원칙

### 세로로 완성한다

여러 기능을 얕게 만들지 말고 사용자가 검증할 수 있는 기능 하나를 끝까지 연결한다.

예를 들어 Character Feature를 구현한다면 필요한 범위에서 다음을 함께 확인한다.

- 획득과 Level Up
- Character Projection과 Action UI
- 사용 조건
- 대상과 판정
- 자원 소비와 회복
- 서버 검증
- 실제 규칙 효과
- Journal·Trace·Presentation
- 한국어 Localization
- 저장과 재접속
- 오류 처리
- 테스트와 성능 영향

### 미완성을 숨기지 않는다

다음 상태를 완성으로 표시하지 않는다.

- 버튼만 있고 실행되지 않음
- 설명만 있고 규칙 효과가 없음
- Client Presentation만 있고 Authoritative State가 바뀌지 않음
- 저장·재접속·Migration이 필요한데 없음
- 번역 키가 누락됨
- 잘못된 요청을 검증하지 않음
- 임시 데이터와 임의 상수에 의존함
- 프로파일링하지 않고 최적화됐다고 주장함
- 테스트하지 않고 오류가 없다고 주장함
- 문서·HTML·Static PASS를 Runtime PASS로 주장함

부분 구현이면 지원 범위와 미지원 범위를 명시한다.

### 범위를 몰래 넓히지 않는다

요청과 직접 관련 없는 전면 리팩터링, 대량 이름 변경과 파일 이동을 함께 하지 않는다.

큰 리팩터링이 필요하면 이유와 경계를 분리해 별도 작업으로 관리한다.

---

## 6. 권위 Architecture 원칙

### 데이터 계층

기본 방향은 다음과 같다.

```text
Authoring Source
→ Compiler / Validation
→ Immutable Compiled Definition
→ Authoritative Dynamic State
→ Permission-aware Projection
→ Presentation
```

- Authoring Source는 편집 가능한 원본이다.
- Compiled Definition은 Source와 Compiler Version으로 다시 만들 수 있는 파생 데이터다.
- Authoritative Dynamic State는 Command·Transaction·Commit을 통해서만 변경한다.
- Projection은 Viewer별 권한과 공개 상태를 반영한다.
- UI, Workspace Instance, VFX와 Camera는 Presentation이며 권위 원본이 아니다.

### 서버 권한

서버는 다음의 최종 권한을 가진다.

- Character Progression Source와 Persistent State
- HP, Resource, Spell Slot과 Charge
- Inventory, Equipment와 Attunement
- 확정 Token 위치와 Movement Cost
- Encounter Timeline, Turn과 Action Economy
- Attack, Check, Save, Damage와 Healing 결과
- Condition, Effect, Concentration과 Duration
- Character Creation과 Level Up Commit
- Content Package와 Source Pack 사용 가능 여부
- Ownership, Controller와 Permission
- Campaign Policy Snapshot
- 저장, Migration과 Recovery

Client가 보낸 수치, 성공 여부, 피해량, 위치, 소유권과 Capability를 그대로 신뢰하지 않는다.

Client는 Input, Camera, Preview, Local Preference, UI와 승인된 결과의 부드러운 Presentation을 담당한다.

### 책임 분리

다음 책임을 가능한 한 분리한다.

- Input과 Camera
- UI·ViewModel·Presentation
- Intent와 Network Command
- Rule Definition과 Rule Execution
- Character Source·Build·Persistent State
- Derived Statistic
- Encounter Runtime State
- Inventory·ItemInstance
- Scene Source·Compiler·Runtime Scene
- Spatial Query·Navigation·Movement Execution
- Persistence·Migration·Recovery
- Content Package·Registry·Rights
- VFX·Token Motion·Camera·Screen Effect
- Localization
- Diagnostics·Trace·Audit

하나의 거대한 Manager나 Controller가 모든 책임을 처리하게 하지 않는다.

### 공통 Engine과 전용 Content

Damage, Healing, Roll, Resource, Targeting, Area, Movement, Condition, Duration, Rest와 Time은 공통 Runtime 계약을 사용한다.

Content 고유 예외는 신뢰된 Definition·Recipe·전용 실행 모듈로 연결한다.

모든 Content를 하나의 거대한 선언형 데이터와 조건문에 강제로 넣지 않는다. 반대로 같은 규칙을 Content마다 복사하지 않는다.

### Stable ID와 Registry

Class, Subclass, Feature, Spell, Item, Condition, Asset, Package, Rule Anchor와 Policy는 표시 언어와 무관한 Stable ID를 가진다.

예:

```text
class.fighter
subclass.fighter.champion
feature.fighter.action_surge
spell.fireball
condition.prone
item.weapon.longbow
```

Package 사이에서 임의 File Path나 Roblox Instance 이름을 계약 ID처럼 사용하지 않는다. Registry와 명시된 Dependency를 사용한다.

---

## 7. Input·UI·Projection 규약

### Semantic Input

물리 입력을 Domain Command에 직접 결합하지 않는다.

```text
Physical Input
→ Semantic Action
→ Input Context
→ UI / World Intent
→ Server Validation
→ Receipt / Projection
```

Q는 한 번에 최상위 Context 하나만 닫는다. E는 현재 Context에서 승인·확정 가능한 의미를 수행한다. ESC에 Gameplay 의미를 추가하지 않는다.

### 직접 플레이 피드백

좌클릭으로 실행될 기본 행동은 클릭 전에 사용자가 알 수 있어야 한다.

필요한 범위에서 다음을 제공한다.

- Cursor·Outline·Action Label
- Movement Path·Distance·Remaining Movement
- Range·Area·Target Preview
- 비용과 현재 사용 가능 여부
- Disabled Reason
- Pending·Denied·Stale·Reconciliation 상태

권한 밖이거나 아직 인지하지 못한 Action·Actor·Count·Placeholder는 비활성 표시조차 만들지 않는다.

### Projection과 권한

```text
권한 없음·미인지
→ 노출하지 않음

권한 있음·현재 불가능
→ Disabled
→ 실행 차단
→ Hover·Focus에서 이유

권한 있음·현재 가능
→ Active
```

UI가 Domain Store나 DataStore를 직접 수정하지 않는다. UI는 ViewModel·Intent·Command Binding을 통해 서버 권위 경계를 사용한다.

### Character Console

- Attack/Action Matrix와 Spell Matrix를 분리한다.
- `Action Matrix Rows`는 1–4행이며 기본값은 현재 UI Authority를 따른다.
- Console은 하단 Anchor를 유지하고 위쪽으로 확장한다.
- Action, Bonus Action, Reaction, Movement, Class Resource, Prepared/Memory Capacity, Spell Slot과 Turn State를 Resource Rail에서 읽을 수 있게 한다.
- 존재하지 않는 Resource의 빈 Placeholder를 만들지 않는다.

### DM Window

DM Tool은 독립 Module Instance다.

- Move·Resize·Dock·Undock·Tab·Close 상태는 Local Preference다.
- 실제 Domain 변경은 서버 Command다.
- Permission·Role·Scene 변경으로 권한을 잃은 Window는 민감 내용을 남긴 채 Stale 상태로 유지하지 않는다.
- Quick Action은 작은 Context Popover다. 큰 고정 Panel로 바꾸지 않는다.

### 접근성

UI Scale, Text Scale, Keyboard Focus, Reduced Motion, Flash 제한과 Camera Comfort를 처음부터 고려한다.

Theme·Scale·Motion Preference 변경이 Actor Selection, Keyboard Focus와 Authoritative State를 불필요하게 초기화하지 않게 한다.

---

## 8. 이동·Scene·Performance 구조

### 이동 System

5피트 논리 Cell을 Runtime 권위 이동 모델로 사용하지 않는다.

기본 구조:

```text
Semantic Scene Source
→ Scene Compiler
→ Compiled Traversal Domain
→ Transition Graph / Spatial Index
→ Movement Profile Query
→ Authority Movement Execution
```

- 권위 위치는 연속 좌표다.
- 권위 거리와 이동 비용은 규칙 단위로 계산한다.
- Actor 통과 가능성은 `SpatialBodyProfile`과 구성 공간 판정으로 계산한다.
- 크기별 고정 NavMesh만으로 Clearance를 해결하지 않는다.
- 일반 Model 내부에 `Walkable`, `Deniable`, `DifficultTerrain` 같은 Runtime Attribute를 강제하지 않는다.
- DM에게 Navigation Polygon·Portal 폭·Clearance 숫자를 일상적으로 수동 편집하게 하지 않는다.
- Humanoid·Roblox Physics를 Token 권위 이동 원본으로 사용하지 않는다.

정적 Scene 정보는 가능한 범위에서 Compile하고, 문·장애물·상태 변화 등 영향 범위만 증분 무효화한다.

### 성능에서 금지하는 패턴

- 모든 Token과 Object를 매 Frame 순회
- 이동 공간을 촘촘한 Part·Script·Event Cell로 물리 인스턴스화
- 상태 변화가 없는데 반복 Polling
- 매 Frame 대량 Raycast와 Path Planning
- 닫힌 UI의 지속 갱신
- 동일한 전체 State의 반복 복제
- Connection, Task와 Instance를 해제하지 않음

### 우선하는 패턴

- Event-driven Update
- Spatial Index와 범위 Query
- Delta Projection
- Visibility·Distance 기반 활성화
- Streaming·Culling·LOD
- Object Pooling
- Cache와 명확한 Invalidation
- Static Navigation·Scene 파생 데이터 사전 Compile
- 필요한 Authoring Grid·Overlay만 시각화

### 성능 예산

기준 Scene과 기준 Device를 정의한 뒤 최소 다음을 측정한다.

- Client Frame Time
- Server Script Time
- Memory와 증가 추세
- Instance Count
- Network Payload와 Rate
- Spatial Query·Path Planning Time
- Scene Load·Compile Time
- Save·Recovery Time

초기 Desktop 목표는 부드러운 60 FPS다. 정확한 하한과 기준 Scene 규모는 측정 기반 성능 예산 문서와 Acceptance가 소유한다.

---

## 9. Character Runtime 규약

Character의 권위 구조를 UI Sheet 하나로 축약하지 않는다.

```text
Character Progression Source
+ Ruleset·Source Pack Version
+ Item·Effect Activation Source
→ Character Compiler
→ Compiled Character Build

Compiled Character Build
+ Persistent Character State
+ Scene Actor State
+ Encounter State
→ Runtime Snapshot
→ Rule Runtime·Projection
```

### Progression Source

다시 계산할 수 없는 성장 선택과 기록을 소유한다.

예:

- Species·Background Selection
- Class Level Sequence
- Subclass Selection
- Ability Generation Record
- Feat·Proficiency Selection
- Spell Acquisition Selection
- Exceptional Grant

최종 AC, Capability, 최대 Resource처럼 다시 계산 가능한 파생값을 Source에 중복 저장하지 않는다.

### Compiled Build

Source와 고정된 Content Version에서 만든 불변 파생 Build다.

- Capability
- Passive Modifier와 Rule Override
- Proficiency
- Spell Access
- Resource Definition
- Derived Statistic Plan
- Spatial Body·Movement Profile

현재 HP, 소비된 Slot, Scene 위치와 Condition Instance를 Build에 저장하지 않는다.

### Persistent State

현재 HP, Temp HP, Death Save, Resource State, Prepared State, Persistent Condition, Inventory Binding, Equipment·Attunement처럼 Campaign을 넘어 유지되는 현재 상태를 소유한다.

Persistent State를 성장 Source로 사용하지 않는다.

### UI Sheet

Official Sheet와 VTT Management View는 위 상태의 Projection이다.

- Roll 가능한 Field는 `RollRequest` 또는 서버 Command를 제출한다.
- Equip·Use·Prepare·Attune·Hotbar 변경은 Inventory·Character Command를 사용한다.
- Client에서 새로운 Character truth를 만들지 않는다.
- 두 View는 같은 Revision과 Command 결과를 사용한다.

### Level Up

```text
현재 Source에서 Draft 생성
→ 선택·조건 검증
→ 결과 Preview
→ 사용자 Confirm
→ 서버 재검증
→ Source Revision Commit
→ Character Recompile
→ Persistent State Migration
```

취소와 실패 시 이전 권위 상태와 Last Known Good를 유지한다.

---

## 10. Rules·Content·Rights 규약

### 구현 수준

Rule Content는 구현 수준을 명시한다.

- `Executable`: 결과까지 System 처리
- `Guided`: System이 절차를 진행하고 사용자 또는 DM 선택을 요구
- `Assisted`: 도구·정보·기록을 제공하고 DM이 실제 결과를 확정

`Assisted`를 미완성의 다른 이름으로 사용하지 않는다.

### 공식 Content Coverage

2024 Player Character Content는 최종 범위에서 임의로 제외하지 않는다.

Content Tracking 상태 예:

```text
not_started
specified
implemented
verified
```

`implemented`와 `verified`를 같은 의미로 사용하지 않는다.

### Rule Profile 분리

Development·Test와 Public·Release Profile을 명확히 분리한다.

- Private Test Content는 Owner-only이며 공개 Repository·Artifact로 재배포하지 않는다.
- 공개 Release는 권리와 Attribution이 확인된 Public Content만 포함한다.
- Private Source Missing·Revision Mismatch·Count Mismatch를 조용히 SRD로 축소해 숨기지 않는다.
- 명시적 Fallback이 허용된 경우에도 UI와 Test Report에서 Fallback 상태를 표시한다.
- 권한 없는 Rule Module의 제목·Count·Search Snippet도 누출하지 않는다.

### Campaign Survival

- Preset은 Narrative·Standard·Survival·Custom이다.
- 정확한 Supply Requirement와 Shortage Consequence는 Content Definition이 소유한다.
- Time Advance와 Inventory Consumption·Shortage Result를 하나의 Settlement 계획으로 Commit한다.
- Toggle 변경은 Candidate Frozen Policy Snapshot·Impact Preview·Safe Boundary를 사용한다.
- 기본 변경은 비소급이다.
- Quest·Key·Protected·Reserved·Private Item을 기본 자동 소비하지 않는다.
- Hidden Consumer·Storage를 Player Projection에 누출하지 않는다.

### DM-authored Actor·Token

다음을 분리한다.

```text
ActorModelAssetDefinition
ActorStatBlockDefinition
TokenPrefabDefinition
ActorTemplateDefinition
SceneNpcInstance
```

- Model Import는 Rights·Provenance·Bounds·Feet Pivot·Performance Budget를 검증한다.
- Script·LocalScript·ModuleScript·Remote와 실행 가능한 외부 Callback을 금지한다.
- AI Prompt 결과는 Untrusted Draft다.
- 존재하지 않는 Model ID와 미등록 Trusted Recipe를 거부한다.
- AI 결과를 자동 Publish하지 않는다.
- 새 Template Version이 기존 SceneNpc를 조용히 자동 Migration하지 않는다.

---

## 11. 오류 처리와 Diagnostics

### 오류를 삼키지 않는다

빈 `pcall`로 오류를 숨기지 않는다.

- 복구 가능한 실패는 구조화된 실패 결과로 반환한다.
- 예상하지 못한 오류는 Context와 함께 기록한다.
- 사용자에게는 이해 가능한 메시지를 표시한다.
- 부분 적용된 상태는 Rollback하거나 안전 상태로 전환한다.

### 구조화된 Trace

중요 Command와 상태 변경에는 가능한 범위에서 다음을 연결한다.

- Stable Error Code
- Module·Feature
- actorId·tokenId·contentId
- packageId·sourcePack·version
- campaignId·sceneId·sessionId
- role·mode·authorityEpoch·revision
- commandId·executionId·transactionId
- request player 또는 viewer scope

민감 정보, Private Rule Content와 전체 Save Data를 불필요하게 기록하지 않는다.

### 오류 격리

하나의 Spell, Feature, Actor Ability, Content Pack 또는 Presentation 오류가 전체 Session과 Encounter Loop를 중단시키지 않게 한다.

- Content Load·Compile 시 Schema와 Reference를 검증한다.
- 잘못된 Content는 안전하게 비활성화하고 원인을 표시한다.
- 실행 실패 시 해당 Execution을 안전하게 취소한다.
- Resource 소비와 State 적용은 원자적으로 처리하거나 Rollback한다.

### Timeout과 Cancel

Data Load, Save, Remote Response와 Async Task를 무한히 기다리지 않는다.

Scene Transition, Role Change, Reconnect, Recovery와 Session 종료 시 진행 중인 Task·Connection·Preview를 정리한다.

---

## 12. Localization

- 기본 Locale은 `ko-KR`다.
- 사용자용 한국어 문구를 내부 ID로 사용하지 않는다.
- 이름과 설명은 Localization Key로 표시한다.
- Rule 수치와 실행 로직을 번역 파일에 넣지 않는다.
- UI는 한국어 긴 Text와 다른 Locale의 길이 변화를 견뎌야 한다.
- Log 문장은 Localization Template과 변수로 구성한다.
- 번역 누락은 개발 환경에서 즉시 표시하고 기록한다.

---

## 13. Persistence·Migration·Recovery

- 모든 저장 Schema는 Version을 가진다.
- Schema 변경에는 Migration이 필요하다.
- Migration은 반복 실행해도 중복 변경되지 않게 한다.
- Save Generation과 Chunk를 사용하는 Domain은 불완전 Generation을 Current로 승격하지 않는다.
- Character Level Up, Equipment 변경, Reward, Supply Settlement와 다른 복합 작업은 Partial Commit을 허용하지 않는다.
- 중복 요청이 중복 Reward와 Resource·Item 소비를 만들지 않게 한다.
- Reconnect와 Server Restart는 최신 권위 State와 Version에서 복구한다.
- Save 실패를 성공으로 표시하지 않는다.
- Auto Save와 Explicit Save의 충돌을 제어한다.
- Lease·Fence가 필요한 Persistence Writer는 Ownership 없이 Authority Document를 쓰지 않는다.
- Rollback은 과거 권위 State에서 새 Branch를 만들며 기존 Audit Log를 물리적으로 삭제하지 않는다.

---

## 14. Network·Security·Disclosure

모든 Remote·Command 요청에서 필요한 범위에 따라 확인한다.

- Caller Role·Ownership·Capability
- Input Type·Size·Schema
- 현재 Campaign·Session·Scene
- Mode·Context·Authority Epoch·Revision
- Distance·Visibility·Knowledge·Target Validity
- Action Economy·Turn·Resource
- Duplicate Execution ID·Idempotency
- Rate Limit
- Lease·Persistence Readiness가 필요한 Command Guard

Client가 전달한 Instance, ID, Position, Roll Result와 Ownership을 그대로 신뢰하지 않는다.

### Negative Disclosure

권한 없는 정보는 값만 숨기는 것으로 끝내지 않는다.

가능한 경우 다음에서도 존재를 누출하지 않는다.

- Count
- Placeholder
- Disabled Action
- Search Result·Snippet
- Backlink
- Hidden Actor·Container·Asset 이름
- Error Message
- Diagnostic Projection

Untrusted 사용자 문자열, AI Draft와 Campaign-authored Data를 Log Key, Localization Key, File Path, Module 이름이나 실행 Code로 사용하지 않는다.

---

## 15. Test·Acceptance·Evidence 규약

### 상태를 항상 추적한다

루트 `AGENT-TEST-STATUS.md`는 현재 구현·테스트 상태 대시보드다.

- 구현·Runtime·Acceptance·Release 작업을 시작하기 전에 읽는다.
- 실제 테스트를 수행했거나 PASS·FAIL·BLOCKED·DEFERRED·PENDING·IN_PROGRESS 상태, 다음 Gate, 테스트 가능 범위가 바뀌면 같은 작업에서 갱신한다.
- 세부 테스트 계약 원본은 `implementation/roblox/EXECUTION-TEST-RULES.md`, `implementation/roblox/GRAND-ACCEPTANCE-CAMPAIGN.md`, `implementation/roblox/grand-acceptance-manifest.json`을 따른다.
- 상태 Dashboard가 원본 Test Contract를 임의로 다시 정의하지 않는다.

### Evidence를 확대 해석하지 않는다

```text
Document PASS
≠ Static PASS
≠ Build PASS
≠ Studio Runtime PASS
≠ Human UI·UX PASS
≠ Multi-client PASS
≠ Persistence PASS
≠ Performance·Soak PASS
≠ Release PASS
```

- Static·Build·Lint·Type PASS를 Studio Runtime PASS로 확대하지 않는다.
- Single-client PASS를 Multi-client·Persistence·Accessibility·Performance·Release PASS로 확대하지 않는다.
- 실행하지 않은 테스트는 체크하거나 PASS로 기록하지 않는다.
- Historical Head의 Runtime PASS를 새 Input·UI·Authority Contract의 PASS로 재사용하지 않는다.

### 자동화 우선 영역

- Rule Calculation
- Derived Statistic
- Content Definition·Schema Validation
- Character Compile·Level Up
- Serialization·Migration
- State·Effect Lifecycle
- Action Economy
- Allocation·Reservation·Idempotency
- Projection·Negative Disclosure
- Deterministic Fault·Recovery Scenario

Production Path에 테스트용 Fake Data와 우회 로직을 남기지 않는다.

### Codex와 Studio 역할

현재 운영 기본값:

```text
Codex
→ 코드·문서 독립 검수
→ 구현 반복 탐색·수정
→ 구조·권한·회귀 검수
→ Static Gate와 자동 검증

사용자 Human Runtime
→ Roblox Studio 실제 실행
→ 실제 화면·입력·Play
→ UI·UX·가독성·플레이 감각
```

Codex Review 성공은 Merge 승인이나 Runtime PASS가 아니다.

Codex ↔ Roblox Studio MCP 자동화는 현재 기본 사용자 흐름이 아니다. 사용자가 명시적으로 요청하거나 반복 자동화의 이득이 명확할 때만 사용한다.

사용자에게 작은 수정마다 Studio를 실행하게 하지 않는다. 현재 Work Order와 Execution Test Rules의 Batch Acceptance Gate가 준비된 뒤 필요한 Runtime 검증을 묶는다.

---

## 16. Clean Code·Performance 규약

### 하나의 중심 책임

Module, Service와 Controller는 이름으로 설명할 수 있는 하나의 중심 책임을 가진다.

함수가 여러 단계의 서로 다른 일을 수행하면 작은 명명된 함수나 Service로 분리한다.

### 순수 계산

Roll Modifier, Spell DC, Movement Cost, Supply Allocation과 다른 Rule Calculation은 가능한 한 Roblox Instance와 UI에 의존하지 않는 순수 함수·Module로 만든다.

동일한 Frozen Input에는 동일한 결과가 나와야 하며 Unit Test가 가능해야 한다.

### 명시적인 Dependency

- 숨겨진 Global State를 사용하지 않는다.
- Singleton과 Service Locator를 남용하지 않는다.
- 필요한 Dependency를 생성자나 함수 인수로 전달한다.
- Circular Dependency를 만들지 않는다.
- Module Load Order에 우연히 의존하지 않는다.

### Type과 Contract

- 공개 함수의 Input·Return Type을 명시한다.
- Serialized Data와 Runtime Object Type을 구분한다.
- Remote Input은 Schema Validation을 거친다.
- `any`와 무분별한 Type Assertion을 피한다.
- nil 가능성과 실패 결과를 Caller가 처리하게 한다.
- Production Luau는 가능한 파일에서 `--!strict`를 유지한다.

### 측정 우선

- CPU, Frame Time, Memory, Network와 Instance Count를 측정한다.
- 병목을 Profile한 뒤 수정한다.
- 최적화 전후 결과를 비교한다.
- 측정하지 않은 성능 개선을 사실처럼 보고하지 않는다.

---

## 17. 완료 조건과 완료 보고

작업은 필요한 범위에서 다음이 확인되어야 완료다.

1. 최신 Product·ADR 요구 충족
2. 서버 권위·Permission·Input Validation 충족
3. 정상 흐름과 주요 실패 흐름 확인
4. Projection·Negative Disclosure 확인
5. 저장·Reconnect·Migration·Rollback 영향 확인
6. Localization 준비
7. 필요한 Static·Unit·Integration·Runtime Test 상태 기록
8. 성능 Budget 또는 미측정 항목 명시
9. Connection·Task·Instance Lifetime 정리
10. 오류 원인을 찾을 Trace·Error Context 존재
11. 코드 책임과 Dependency 설명 가능
12. 남은 제한·Blocker·미지원 범위 명시

실행할 수 없는 테스트는 실행한 것처럼 보고하지 않는다.

완료 보고에는 최소 다음을 포함한다.

1. 변경한 목표
2. 변경 파일과 핵심 구조
3. 검증하거나 실행한 테스트
4. 성능 확인 결과 또는 미측정 항목
5. 남아 있는 제한, 위험과 다음 Gate

테스트 상태가 바뀐 작업이면 완료 보고 전에 `AGENT-TEST-STATUS.md`가 같은 상태를 반영하는지 확인한다.

---

## 18. 금지 사항

- 서버 검증 생략
- Client가 권위 Rule·State·Ownership을 직접 확정
- 5피트 논리 이동 Grid 또는 Grid Center Snap을 Runtime Authority로 재도입
- Encounter Token WASD 직접 이동 재도입
- ESC에 Gameplay 의미 추가
- Player Minimap·별도 Map·Objective Tracker를 현재 Release UI에 재도입
- Controller·Touch 전용 Surface를 현재 PC 범위 때문에 필요하다고 가정해 추가
- NPC 대화·음악·환경음·공격·주문·UI SFX를 현재 범위에 몰래 추가
- Private Rule Content·Credential·Search Index를 Public Repository·Artifact·Client에 누출
- AI Draft·Campaign Data를 Code·Remote·URL Callback으로 실행
- AI 결과 자동 Publish
- 공식 Stat Block·CR 자동 재조정
- 빈 `pcall`과 오류 무시
- 거대한 Manager에 책임 계속 추가
- 같은 Rule Code 복사
- 무제한 Loop, Connection과 Task 방치
- 전체 Scene 매 Frame 검색
- 한국어 문자열을 내부 Identifier로 사용
- 저장 Schema를 Migration 없이 변경
- 성능 측정 없이 최적화됐다고 주장
- 테스트 없이 오류가 없다고 주장
- 문서·Static PASS를 Runtime·Human PASS로 확대 해석
- 미완성 기능을 정상 기능처럼 노출
- 확정 문서와 다른 결정을 구현에 몰래 포함
- 현재 Branch·PR·Work Order를 확인하지 않고 과거 Branch·상태 문구를 사실로 가정