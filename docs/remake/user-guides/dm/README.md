# RVTT DM Guide

- 사용자 가이드 상태: `TARGET_EXPERIENCE`
- 대상: DM
- 최종 갱신일: 2026-08-05
- User Guide Hub: [`../README.md`](../README.md)
- 세부 작업 순서: [`../CURRENT-USER-GUIDE-WORK-ORDER.md`](../CURRENT-USER-GUIDE-WORK-ORDER.md)

> 이 문서는 구현 전 목표 사용자 경험이다. 실제 Release가 나온 뒤 화면 배치와 조작을 다시 검증해 `RELEASE_VERIFIED`로 갱신한다.

RVTT에서 DM은 플레이어와 같은 3D Scene을 보면서 세션을 진행한다. DM의 역할은 모든 결과를 직접 수정하는 것이 아니라, Scene·Character·NPC·비밀 정보·판정·Encounter와 시간 흐름을 안전한 도구로 조정하는 것이다.

## 1. DM 빠른 시작

첫 세션의 기본 흐름은 다음과 같다.

```text
Campaign 선택 또는 생성
→ Ruleset·Source Pack 확인
→ 시작 Scene과 Player Entry 확인
→ Character Owner·Control 확인
→ 숨은 Actor·Object·Fog·Journal 준비
→ Player 입장과 Ready 확인
→ 세션 시작
→ Exploration 진행
→ 필요하면 Encounter 전환
→ 결과 저장과 세션 종료
```

Scene이나 저장 상태가 준비되지 않았다면 정상 시작으로 표시하지 않는다. Player 화면이 열렸더라도 필요한 Scene·Character 자료의 동기화가 끝날 때까지 Gameplay 입력을 열지 않는다.

## 2. DM이 관리하는 것

DM은 다음을 관리한다.

- Campaign과 활성 Ruleset·Source Pack
- Session Role과 Character Control
- 시작 Scene과 Scene 전환
- NPC·Monster·Object의 현재 상태
- Fog, 발견 상태와 공개 범위
- 판정 요청과 구조화된 DM 결정
- Encounter 참가자·순서·Objective·종료
- Character·Item·Downtime의 DM 승인 흐름
- Journal 문서·권한·World Link
- Scene Authoring·Publish·Live Patch
- Checkpoint·Recovery·Rollback

DM도 시스템 권위를 우회하지 않는다. Workspace Model을 움직이거나 UI 값을 바꾸는 것만으로 HP, 위치, Item과 Encounter 결과가 확정되지 않는다.

## 3. 세션 전 준비

### Campaign 기준

세션 시작 전에 확인한다.

- 기본 Ruleset: `dnd5e-2024`
- 활성 Source Pack과 정확한 Version
- Campaign의 선택 규칙과 허용 콘텐츠
- Character와 NPC Definition의 호환 상태
- 최근 저장 상태와 Recovery 경고

사용 중인 Source Pack을 제거하거나 변경하면 Character, Item, Actor, Scene과 진행 중 활동에 영향을 줄 수 있다. 사용 중인 콘텐츠를 이름이 비슷한 다른 콘텐츠로 자동 교체하지 않는다.

### 시작 Scene

확인 항목:

- Published Scene Build가 준비됨
- Player Entry와 Actor 배치 위치
- 이동 가능한 바닥과 주요 통로
- 문·함정·상자·레버·파괴 Object
- 숨은 Actor와 비공개 Object
- Fog와 초기 공개 범위
- Scene 기본 Journal 문서
- Player에게 보일 정보와 DM 전용 정보
- Test Play와 Compiler Diagnostic 결과

Candidate Build가 실패했다면 실패한 일부를 활성 Scene에 섞지 않고 마지막 정상 Published Build를 유지한다.

### Character와 Player

확인 항목:

- Campaign Membership
- Session Role: DM·Player·Observer
- Character Owner
- 현재 Token Controller
- 현재 HP·Resource·Effect
- Inventory·Equipment·Attunement
- Scene Actor와 Character 연결

다음은 서로 다른 관계다.

```text
Character Owner
≠ 현재 Controller
≠ Session Role
≠ 정보 공개 범위
```

## 4. Lobby와 세션 시작

Player가 접속하면 다음을 확인한다.

- 올바른 Campaign에 참가했는가
- 허용된 Character를 선택했는가
- Player가 Ready를 눌렀는가
- Client 동기화와 Scene 준비가 끝났는가
- 현재 Control Assignment가 안전하게 적용 가능한가

Player의 Ready와 기술적 Gameplay Ready는 다르다. Player가 준비를 눌렀어도 동기화 중이면 아직 행동할 수 없다.

### 시작

DM이 시작을 승인하면:

```text
Session 상태 확인
→ 시작 Scene 활성화
→ Player별 공개 정보 동기화
→ Token과 Camera 초기 View 준비
→ Control Assignment 활성화
→ Exploration 시작
```

세션이 이미 존재하면 새 세션을 덮어쓰지 않고 Resume 흐름을 사용한다.

### 중도 참가

늦게 참가한 Player는 현재 권위 상태와 자신에게 공개 가능한 정보만 받는다.

- 동기화 중에는 Observer View를 제공할 수 있다.
- 진행 중 공격·반응·Commit 중간에 새 Controller를 즉시 삽입하지 않는다.
- 안전한 행동·Turn 경계에서 Control을 활성화한다.

## 5. DM Workspace

DM Workspace는 Player HUD와 같은 전장을 사용하면서 추가 관리 Panel을 제공한다. Panel은 이동·Dock·접기·Tab 결합이 가능하고 기본 배치로 초기화할 수 있다.

주요 작업 영역:

- Session 상태·Pause·Save
- Scene·Actor·Asset
- Inspector·Journal·Player Control
- Fog·Encounter·Timeline·Roll

최종 픽셀 배치는 구현과 사용성 테스트에서 확정한다.

### Live DM Mode

Player 진행을 유지하면서 수행하는 작업이다.

- Actor와 NPC 조작
- Fog 공개·숨김
- 판정과 Roll 요청
- Control Assignment
- Journal 열기·공개
- Ping과 Camera Focus 요청
- 문·함정·Light·Object의 작은 상태 변경
- Runtime Quick Edit

### Full Scene Edit

Scene 구조를 바꾸는 작업이다.

- 벽·바닥·계단·도로
- 대규모 Asset 배치
- Navigation·Visibility에 영향을 주는 구조
- Lighting Profile과 Environment Volume
- Region·Entry·Exit·Critical Route

Full Scene Edit는 세션을 Pause하거나 안전한 전환 상태에서 수행한다. Player가 움직이는 동안 Scene 구조 전체를 조용히 교체하지 않는다.

## 6. 공통 DM 입력

### Q

```text
Q
→ 현재 단계 취소
→ 요청 거절
→ 한 단계 뒤로
```

예:

- Player 승인 요청 거절
- 현재 Target 지정 취소
- 미완성 배치 Preview 취소
- Quick Action 하위 단계에서 이전으로

### E

```text
E
→ 승인
→ 확정
→ 실행
```

예:

- 현재 DM 판정 승인
- 위험 Command 확인
- Scene Tool의 최종 결과 확정
- 현재 선택한 Quick Action 실행

### 1–5

현재 화면에 Label이 표시된 경우 주요 진행 선택지로 사용한다.

예:

```text
[1 그대로 처리]
[2 수정 후 처리]
[3 Roll 요구]
[4 세부 정보]
[5 규칙 근거]
```

Scene Editor는 기본적으로 1–5를 점유하지 않는다.

## 7. Camera와 Player View

DM Camera는 Character Control과 분리된 자유 전술 Camera다.

가능한 경험:

- 자유 이동·회전·확대·높이 조절
- Actor·Object·Bookmark로 Focus
- 특정 Actor Follow
- 숨은 Actor와 DM 전용 Marker 확인
- Player가 보고 있는 Camera View 참고
- 특정 Player의 공개 범위 Preview

### Player View Preview

Player Audience Preview는 선택한 Player가 실제로 받을 Projection과 같은 공개 범위를 사용한다.

Preview에서 반드시 확인할 것:

- 숨은 Actor가 보이지 않는가
- 발견하지 못한 함정·비밀문이 노출되지 않는가
- 실제 비밀 HP·AC·DC가 보이지 않는가
- DM 전용 Journal과 Anchor가 검색되지 않는가
- 비공개 Roll과 Objective가 노출되지 않는가

DM Camera가 비밀 위치를 보고 있다는 이유로 Player Camera와 공개 정보가 바뀌지 않는다.

## 8. Exploration 진행

Exploration에서는 Player가 클릭 또는 WASD로 Token을 이동하고 주변을 조사한다.

DM의 주요 역할:

- NPC와 환경 반응 진행
- Player 이동 잠금이 필요한 상황 판단
- 문·함정·위험 영역 상태 관리
- Perception·Search·Study 결과 처리
- Fog와 발견 정보 공개
- 즉흥 행동 판정
- Encounter 전환 필요 여부 판단

### 실시간 진행과 안전 경계

Player의 이동과 행동이 동시에 발생할 수 있지만 한 Actor가 모순되는 행동을 동시에 확정하지 않도록 한다.

예:

- 이동 중 문을 열면 접근 지점에서 멈춘 뒤 상호작용
- 함정이 발동하면 관련 Actor·지역만 필요한 범위에서 정지
- 적대 행동이 발생하면 관련 신규 입력을 잠시 막고 Encounter 전환

모든 위험에서 세션 전체를 자동 Pause하지 않는다. 실제 필요한 Actor와 범위를 선택한다.

## 9. Fog, Perception과 비밀 정보

다음은 분리해서 관리한다.

```text
지형이 공개됨
Actor가 보임
숨은 대상을 발견함
대상의 정체를 앎
상세 수치가 공개됨
```

### Fog

Fog는 지형의 탐험 상태다.

- Discovery: 과거에 탐험한 지형
- Current Reveal: 지금 공개되는 지형
- Remembered: 현재 보지 않지만 기억된 지형

Fog를 열어도 함정·비밀문·숨은 Actor를 자동 발견시키지 않는다.

### Manual Fog와 Assist

DM은 Manual Fog를 직접 편집할 수 있다. 선택형 Assist는 현재 Visibility와 Scene 정보를 바탕으로 공개 후보를 제안하지만 DM이 끄거나 승인 흐름을 선택할 수 있다.

Assist가 직접 비밀 정보를 권위적으로 공개하지 않는다. 승인된 Fog 변경은 같은 이력과 Command 흐름을 사용한다.

### 정보 누출 방지

Player Client에 비밀 정보를 먼저 보내고 `Visible=false`로 숨기지 않는다.

다음 경로에서도 비밀이 나오지 않아야 한다.

- Hover와 Tooltip
- Search Result와 Backlink
- Error Message
- Quick Action Label
- Diagnostic Reference
- Camera Target
- VFX와 Floating Text

## 10. 판정과 DM Adjudication

자동화하기 어려운 즉흥 행동은 DM Adjudication 요청으로 처리한다.

요청에는 가능한 범위에서 다음을 표시한다.

- 요청 Player와 Character
- 선언한 행동
- Target과 위치
- 사용하려는 Resource
- 자동으로 확인된 조건
- DM이 판단해야 하는 예외
- 현재 선택 가능한 구조화된 결과

DM은 설명 메모를 남길 수 있지만 기계적 결과는 등록된 선택지와 안전한 Override를 사용한다.

예:

```text
성공
실패
추가 Roll 필요
대상 변경 필요
기계적 효과 없이 허용
거절
```

자유 텍스트를 임의 상태 변경 코드로 실행하지 않는다.

## 11. Quick Action

Quick Action은 현재 선택한 Actor·Object·Player·World Position에 가능한 명령을 빠르게 보여준다.

```text
명시적 Selection
→ Hover 대상
→ Cursor 위치
→ 현재 Actor
→ Scene 전체
```

순서로 문맥을 찾는다.

### Actor 예시

- Sheet 열기
- 피해·회복·Temporary HP
- Condition 추가·제거
- 숨기기·공개
- 이동·Teleport
- Initiative 추가·제거
- Control 배정·회수
- Roll 요청

### Object 예시

- Door 열기·닫기·잠금
- Chest 내용 확인·공개
- Trap 활성화·해제·즉시 발동
- Light 켜기·끄기
- Fog 공개·숨김
- Journal Link 열기

### 위험도

```text
safe
caution
high
critical
```

위험한 Command는 변경 요약과 확인을 요구한다.

예:

- Door 열기: 즉시 또는 짧은 확인
- Actor 피해 적용: 결과 Preview
- Actor 삭제: 명시적 확인
- Encounter Rollback: 상태 Diff 확인

Quick Action이 직접 상태를 바꾸지 않는다. 현재 Target과 상태를 다시 확인한 뒤 기존 Domain Command로 실행한다.

## 12. NPC와 Control Assignment

DM은 NPC·Monster를 직접 조작하거나 Player에게 임시 Control을 줄 수 있다.

Control 변경 시점을 선택할 수 있다.

- 즉시 가능한 안전 경계
- 현재 행동 종료 후
- 현재 Turn 종료 후
- 다음 Round 시작

Player 연결이 끊겨도 Character Owner를 자동으로 바꾸지 않는다. 필요하면 DM Takeover 또는 대기 정책을 사용한다.

DM이 Player View를 관찰하거나 Camera를 따라가도 해당 Character의 Control을 얻는 것은 아니다.

## 13. Encounter 시작

Encounter는 Combat뿐 아니라 Chase, Hazard, Escape와 Timed Objective를 처리할 수 있다.

### 시작 후보

다음 상황에서 Encounter Proposal을 만들 수 있다.

- 적대 행동
- 상대 진영의 탐지
- 함정·Hazard
- 제한 시간 Objective
- DM의 명시적 시작

공격 버튼을 눌렀다는 이유만으로 모든 상황에서 즉시 Encounter를 시작하지 않는다. 참가자, Awareness, Faction과 Reaction 순서가 필요한지 판단한다.

### 준비

확인 항목:

- Scene Scope
- 참가 Actor와 Nonparticipant
- Faction
- Awareness와 Surprise 관련 정보
- Character·NPC Controller
- Objective
- 필요한 Initiative 방식
- 현재 진행 중인 이동·행동·Prompt

관련 Actor의 새 입력을 Gate하고 진행 중 실행을 안전한 상태로 분류한 뒤 Encounter를 활성화한다.

## 14. Encounter 진행

DM Workspace에서 확인한다.

- 참가자와 Faction
- Timeline과 현재 Turn
- Initiative Roll·동률 처리
- Action Opportunity와 이동력
- 열린 Reaction·Prompt
- Objective 진행
- Round와 Campaign Time
- 중도 합류·이탈
- Player 연결 상태와 Control

### Initiative

필수 Roll이 공개되고 Tie Resolution이 끝난 뒤 첫 Turn을 시작한다. 임시 배열 순서로 진행하지 않는다.

### Turn

Encounter는 Turn과 Opportunity를 제공한다. 실제 공격·주문·Item·상호작용은 각 Character와 NPC의 현재 Capability에서 나온다.

DM은 다음을 확인할 수 있다.

- 현재 Controller가 맞는가
- 필요한 Action·Bonus Action·Reaction이 남았는가
- 이동력이 남았는가
- 열린 Rule Prompt가 있는가
- Turn 종료를 막는 필수 처리가 남았는가

### 이동

Encounter Token 이동은 경로를 확인한 뒤 클릭으로 실행한다. Token WASD는 허용하지 않는다.

이동 중 Reaction·Trap·Hazard·Door와 동적 차단이 발생하면 안전한 Progress Checkpoint에서 멈춘다. 경로의 의미가 크게 달라지면 Player에게 다시 확인한다.

### Reaction과 Ready

Reaction은 규칙 사건이 연 Prompt를 통해 처리한다. DM이 임의 Stack 순서를 화면에서 직접 수정하지 않는다.

기본 `dnd5e-2024` Policy에서는 Ready를 지원하고 일반 Delay 행동은 제공하지 않는다.

### 피해와 HP 0

Damage Roll, 최종 Damage, Temporary HP, Current HP, Vital State, Death Save와 사망을 분리한다.

DM이 피해를 적용할 때 다음이 함께 정리될 수 있다.

- HP와 Temporary HP
- 의식불명·죽어감·사망 상태
- 사용할 수 없게 된 행동과 Reservation
- 현재 Turn 진행 가능 여부

Concentration Check, Objective 재평가와 Morale처럼 새 판정이 필요한 결과는 후속 처리로 이어진다.

## 15. Encounter Objective와 종료

Objective 예:

- 모든 적대 세력 무력화
- 특정 Actor 보호
- 탈출 지점 도달
- 일정 Round 버티기
- 장치 해제
- 추격 대상 포획

Objective 조건이 충족돼도 End Policy 또는 DM 확인을 거쳐 종료한다.

종료 전 확인:

- 열린 행동과 Reaction
- 현재 Turn과 Temporal Boundary
- 참가자 상태
- Encounter 한정 Effect와 Control
- Reward·Journal·후속 Scene

Encounter 종료는 전투 전 상태 초기화가 아니다. 현재 위치, HP, 시체, Item, 문·함정, Effect와 발견 정보가 유지된다.

## 16. Round와 Campaign Time

기본 `dnd5e-2024` 기준에서 완전히 끝난 한 Round는 Campaign Time 6초다.

- 각 Turn마다 6초를 추가하지 않는다.
- Reaction이나 추가 Timeline Entry마다 별도 6초를 추가하지 않는다.
- 같은 Campaign 시간축의 여러 Encounter가 각각 시간을 중복 추가하지 않도록 조정한다.

Round 경계에서 Scheduler 사건이 Due가 될 수 있다. 필수 사건이 남아 있으면 다음 Round 시작을 잠시 막고 먼저 처리한다.

## 17. Character, Item과 Downtime 관리

### Character

DM은 Character Owner, 현재 Controller와 Scene Actor를 구분한다.

레벨업이나 Character 재구성은 현재 수치를 직접 덮어쓰는 방식이 아니다.

```text
새 선택 작성
→ Candidate Build 검증
→ 현재 State Migration 확인
→ 성공 시 교체
→ 실패 시 기존 Character 유지
```

### Item

Item은 한 시점에 하나의 권위 위치를 가진다.

- Inventory
- Equipment
- Container
- Scene Ground
- Campaign Storage

Pickup·Drop·Transfer·Equip·Stack Split은 기존 Item 흐름으로 처리한다. Workspace Model 복제만으로 새 Item을 만들지 않는다.

### Downtime

Downtime에서 다음을 조정한다.

- Short Rest·Long Rest
- Level Up
- Spell Preparation
- Spellbook 작업
- Crafting
- Training
- Travel

DM은 참가자, 활동, 필요한 Resource와 시간, 중간 사건과 완료 후보를 확인한다. 현실 시간이 지났다는 이유로 자동 완료하지 않는다.

Encounter가 발생하면 관련 활동을 Suspend하고 이후 재검증해 재개한다.

## 18. Journal 관리

Journal은 Campaign 지식과 Scene 진행 정보를 관리한다.

DM이 할 수 있는 일:

- Folder·Document·Section 작성
- 현재 Scene 기본 문서 지정
- Actor·Object·Scene·Region·Encounter·Item·Spell Link
- World Anchor 생성
- Player·Party·Campaign·명시 ACL 설정
- Search와 Backlink 확인
- Player Audience Preview
- Markdown Import·Export 검토

문서 제목이나 Heading을 바꾸어도 Stable Link가 유지되도록 한다.

### 권한

다음을 별도로 설정할 수 있다.

- 존재 발견
- 읽기
- 검색
- Link 이동
- Link 생성
- Comment
- 편집
- 권한 관리
- Export

비공개 문서는 본문뿐 아니라 제목, 검색 Hit, Result Count, Backlink와 Anchor 정보도 Player에게 노출하지 않는다.

### Journal과 Recovery Journal

사용자가 작성하는 Journal과 서버 복구용 Commit Journal은 다른 시스템이다. Encounter Rollback이 Campaign Journal Source를 자동으로 과거 상태로 되돌리지 않는다.

## 19. Scene Quick Edit

Live DM Mode에서 작은 Runtime 변경을 할 수 있다.

예:

- 임시 차단 영역
- 위험 Region
- 임시 Light 상태
- Trigger 상태
- Door·Trap·Object 상태
- Actor 이동과 Spawn

Quick Edit는 현재 Runtime 상태다. Scene Source에 자동 저장되지 않는다.

영구 요소로 남기려면 `Source로 승격`한다.

```text
Runtime Quick Edit
→ Source Promotion 검토
→ 새 Source Object 작성
→ Candidate Build
→ Test·Publish
```

현재 Runtime State 전체를 Scene Source로 그대로 복사하지 않는다.

## 20. Full Scene Editor

### 편집 시작

Full Scene Edit는 DM Authoring Overlay와 Pause·Transition Gate를 사용한다.

DM은 다음을 직접 다룬다.

- 벽·바닥·방·계단·도로
- Prefab과 일반 Asset
- Door·Trap·Chest·Lever
- Region·Entry·Exit
- Lighting과 Environment Volume
- Scene Metadata와 Journal Binding

DM은 내부 Navigation Polygon, Spatial Index, Portal 폭과 Actor별 Clearance Graph를 직접 편집하지 않는다.

### 배치

- Pointer와 Ghost로 Preview
- Snap과 Grid는 제작 보조
- Shift를 누르는 동안 현재 Snap만 해제
- ViewY와 작업 높이는 DM 개인 표시
- Q로 미완성 작업 취소
- 필요한 최종 단계에서 E로 확정

가상 Grid는 Token 이동 규칙의 Grid가 아니다.

### Undo·Redo

Authoring Undo·Redo는 Scene Source 편집 이력이다. Encounter 결과 Rollback과 다르다.

- Wall 이동 취소: Authoring Undo
- 공격 결과 복원: Encounter Timeline Rollback
- HP Override 수정: 감사 기록이 있는 새 Override

## 21. Compile, Test Play와 Publish

Scene Source는 직접 플레이 Runtime이 아니다.

```text
Scene Source
→ Validation·Compile
→ Candidate Build
→ Diagnostic 확인
→ Test Play
→ Publish
→ 새 Session 또는 명시적 Live Patch
```

### Diagnostic

오류는 가능한 범위에서 다음을 보여준다.

- 관련 Source Object
- World 위치와 Bounds
- 원인
- Player에게 미치는 영향
- 수정 선택지

내부 Node 번호만 표시하지 않는다.

### Test Play

Candidate Build를 실제 Campaign State와 분리해 검증한다.

확인 예:

- Entry에서 이동 가능
- Door 열기·닫기
- Visibility와 Fog
- Interaction
- Trap·Trigger
- Exit와 Scene 전환
- Player 공개 범위

### Publish

모든 필수 Layer와 검사가 통과한 완전한 Build만 게시한다. 실패한 Layer 일부와 이전 Build를 혼합하지 않는다.

새 Build를 Publish했다고 현재 진행 중 Session이 자동으로 교체되지는 않는다.

## 22. Live Patch

활성 Session은 현재 Build에 고정된다. 구조적 변경을 적용하려면 Live Patch를 명시적으로 시작한다.

```text
새 Published Build 선택
→ 호환성 검사
→ 안전 Checkpoint 또는 Pause
→ 현재 Dynamic State Rebase 검토
→ Player 재동기화 계획
→ 적용
```

실패하면 이전 Build를 유지하거나 복구한다. 문·Actor·Item 같은 현재 상태를 조용히 잃지 않는다.

## 23. Content Pack과 Campaign Authored Content

### Source Pack

DM은 Campaign에서 허용된 Pack과 Version을 선택한다. Pack 업데이트는 Character·Item·Actor·Scene·Journal과 진행 중 실행에 대한 영향 분석을 요구할 수 있다.

### NPC JSON Import

DM이 NPC JSON을 붙여 넣을 수 있는 목표 흐름:

```text
JSON 입력
→ 구문·크기·Schema 검사
→ Content Reference 검사
→ 수치·Graph·Budget 검사
→ Preview
→ DM 확인
→ Campaign Content로 등록
```

검사 실패 시 활성 Catalog와 Scene은 바뀌지 않는다.

Campaign Authored Content는 등록된 공격·Roll·Damage·Effect·Capability와 Prefab만 사용할 수 있다. 임의 Luau, Module 경로, Remote와 DataStore 접근을 허용하지 않는다.

## 24. 저장, 재접속과 서버 복구

세션 중 연결이 끊긴 Player는 Character Owner와 현재 상태를 잃지 않는다.

DM이 확인하는 복구 상태:

- Player 연결과 새 Connection
- 현재 Control Assignment
- 최근 Command 결과
- Projection 동기화
- 열린 Prompt와 Encounter Turn
- Scene Essential 준비

서버 재시작 시 검증된 Snapshot과 Commit Journal을 기준으로 복구한다. Workspace 복사본과 Client Cache를 저장 원본으로 사용하지 않는다.

자동 복구가 안전하지 않다면 `recovery_review_required` 상태로 들어가 손상 범위와 선택 가능한 Checkpoint를 DM에게 보여준다.

## 25. Encounter Rollback

Rollback은 현재 상태에 반대 명령을 하나씩 적용하는 기능이 아니다.

DM 흐름:

```text
Timeline에서 Checkpoint 선택
→ 현재 상태와 대상 상태 Diff 확인
→ 영향받는 Character·Actor·Item·Effect·Scene·Time 검토
→ E로 승인 또는 Q로 취소
→ 안전 경계에서 새 Branch 복원
→ 모든 Client Full Resync
→ 새 Branch에서 진행
```

Rollback 후:

- 이전 Prompt·Reaction·Command는 무효
- 이전 Branch의 지연 작업과 Timeout은 적용되지 않음
- Player UI와 Control을 새 상태에서 다시 구성
- 현재 Build·Policy·Content Version 호환성 재검증

### Rollback과 별도로 유지되는 것

Encounter Rollback이 자동으로 되돌리지 않는 대표 자료:

- 사용자가 작성한 Journal Source
- Scene Authoring History
- 외부에서 이미 전달한 사람의 기억
- 별도 Campaign 관리 기록

필요하면 각각의 권위 흐름에서 별도로 변경한다.

## 26. 오류와 Diagnostics

DM 화면에는 내부 Stack Trace 대신 안전한 상태와 다음 행동을 표시한다.

예:

- 다시 시도
- 잠시 기다림
- Client Resync
- View 다시 열기
- 안전 Checkpoint까지 대기
- Scene Candidate 수정
- Recovery Review 열기
- Support Reference 생성

DM은 현재 Campaign의 권한 있는 Diagnostic을 볼 수 있지만 다른 Campaign 자료, Secret Credential과 무제한 Raw Log를 받지 않는다.

Diagnostic 화면에서 Recovery를 제안할 수는 있지만 자동으로 HP·Item·Turn·Scene을 수정하지 않는다.

## 27. 세션 종료

종료 전 확인한다.

- 열린 Rule Prompt와 Transaction
- 진행 중 Encounter·Downtime
- Player Control과 연결 상태
- Scene 전환·Live Patch
- Snapshot과 Commit Journal 상태
- Journal·Campaign 변경 저장
- Recovery 경고

종료 흐름:

```text
새 Gameplay 입력 Gate
→ 열린 필수 처리 정리
→ 최종 저장 Candidate
→ Integrity 확인
→ Session 종료
→ Campaign 상태 보존
```

저장 실패를 정상 종료로 표시하지 않는다.

## 28. 현재 제품 범위가 아닌 것

DM Guide에서 다음 기능을 기대하지 않는다.

- NPC 자동 대화 Tree와 AI 대화 진행
- 음악 재생·Playlist 관리
- 환경음과 모든 규칙 효과음
- 일반 사용자의 임의 Luau Plugin 설치
- 외부 URL에서 Code·Content 자동 다운로드
- Player Client 물리 결과를 권위 판정으로 사용
- 모든 D&D 즉흥 행동의 완전 자동화
- 모바일·게임패드·터치 초기 지원
- Scene Editor를 정밀 3D Modeling 프로그램으로 사용하는 기능
- Encounter Rollback으로 사람의 기억이나 모든 Campaign 문서를 자동 복원하는 기능

## 29. DM Quick Reference

```text
세션 전
→ Pack·Scene·Character·비밀 정보·저장 상태 확인

Player 입장
→ Membership·Role·Owner·Control·Ready·동기화 확인

Live 진행
→ Actor·Fog·판정·Journal·Quick Action

Q
→ 취소·거절·한 단계 뒤로

E
→ 승인·확정·실행

Encounter 시작
→ 참가자·Faction·Awareness·Objective·Initiative 확인

Encounter 종료
→ 열린 실행 정리 → 결과 유지 → 다음 Mode 전환

Scene 구조 변경
→ Pause → Full Scene Edit → Compile → Test → Publish

현재 Session에 새 Build 적용
→ 명시적 Live Patch와 Rebase

Rollback
→ Checkpoint·Diff 확인 → 새 Branch 복원 → Full Resync

오류
→ 직접 Store 수정 대신 안내된 Retry·Resync·Recovery 흐름 사용
```

## 30. 근거 문서

이 DM Guide는 다음 현재 문서를 사용자 언어로 통합한다.

- [`Session, Networking, Persistence와 Recovery Guide`](../../guides/session/README.md)
- [`Exploration, Selection, Interaction과 Perception Guide`](../../guides/exploration/README.md)
- [`Combat와 Encounter Guide`](../../guides/combat/README.md)
- [`Character, Inventory와 Downtime Guide`](../../guides/character/README.md)
- [`UI, Camera와 Presentation Guide`](../../guides/ui/README.md)
- [`Journal과 Ping Guide`](../../guides/journal/README.md)
- [`Scene Editor와 Authoring Guide`](../../guides/scene-editor/README.md)
- [`Diagnostics, Simulation과 Operations Guide`](../../guides/diagnostics/README.md)
- [`Extension, Plugin과 Content Pack Guide`](../../guides/extension/README.md)
- [`플랫폼·이동·입력 범위`](../../product/platform-movement-and-input-scope.md)
- [`공통 입력 교과서`](../../ui/common-input/common-input-grammar.md)
- [`DM Workspace와 Scene Lighting`](../../ui/dm-workspace/dm-workspace-and-scene-lighting.md)
- [`DM Quick Action`](../../ui/dm-workspace/dm-quick-action-and-context-command.md)

이 문서와 권위 문서가 충돌하면 Product·Architecture·System·UI·ADR이 우선한다.
