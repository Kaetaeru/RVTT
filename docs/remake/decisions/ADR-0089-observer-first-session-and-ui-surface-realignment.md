# ADR-0089: Observer 우선 세션 진입과 전술 콘솔 중심 UI 표면을 사용한다

- 상태: 확정
- 결정일: 2026-08-06
- 결정 종류: Session Entry · Ownership · Player UI · DM Workspace · Scene Editor Presentation
- 상위 사용자 결정: 2026-08-06 UI HTML 검토 피드백
- 직접 플레이 입력: [`ADR-0088`](ADR-0088-direct-play-pointer-grammar-and-feedback.md)
- 구현 직전 화면 명세: [`implementation-ready-ui-ux-and-settings-spec.md`](../ui/shared/implementation-ready-ui-ux-and-settings-spec.md)
- 충돌 감사: [`ui-html-authority-conflict-and-realignment-audit.md`](../audits/ui-html-authority-conflict-and-realignment-audit.md)

## 1. 배경

기존 HTML 예시는 화면 수를 빠르게 채우는 과정에서 이미 확정된 ADR의 정보 구조를 일부 무시했다. 또한 Session Entry, Player 상시 HUD와 DM 편집 작업공간은 이번 사용자 검토로 제품 방향이 더 구체화됐다.

이 결정은 다음 두 문제를 동시에 해결한다.

1. 기존 HTML이 상위 ADR을 잘못 표현한 부분을 바로잡는다.
2. 이번 사용자 결정으로 변경된 화면·세션 흐름을 최상위 계약으로 승격한다.

그래픽 자산, 로고, 고유 아이콘, 텍스처와 상표 표현은 외부 제품에서 복제하지 않는다. RVTT는 익숙한 정보 구조와 작업 흐름만 참고해 자체 디자인 시스템으로 구현한다.

## 2. 대체·보강 관계

이 ADR은 다음 문서의 **권위·도메인 의미는 유지**하고, 충돌하는 Session Entry와 화면 배치·Presentation 부분을 대체하거나 구체화한다.

- ADR-0033: 주사위 연출 이후 결과 공개 방식 보강
- ADR-0039: Player 하단 HUD와 Context Action 표현 대체
- ADR-0040: 공식형 Character Sheet에 VTT 관리 보기를 추가
- ADR-0041: Minimap 제거, Character Console과 Result Notice Layer로 레이어 재구성
- ADR-0044: Journal을 왼쪽 세로 문서 탭 중심으로 고정
- ADR-0045: DM 기본 작업공간을 왼쪽 Inspector·상단 도구·중앙 전장으로 고정
- ADR-0047: Quick Action을 작은 문맥 팝오버로 제한
- ADR-0049: 미배정 참가자의 Observer 진입과 DM 배정 시 Ownership 전환을 구체화
- ADR-0080: Downtime 활동 실행의 DM 주도 UI를 명시
- ADR-0088: Player Character Actor의 기본 의미 선택과 Q의 루트 복귀 규칙을 보강

충돌 시 이 ADR과 갱신된 구현 직전 UI·UX 명세가 우선한다.

## 3. Session Entry와 Character Ownership

### 3.1 기본 진입 역할

DM이 아닌 참가자는 세션에 연결되면 항상 Observer로 시작한다.

```text
Session 연결
→ Observer Projection 수신
→ 공개 Scene Ready
→ DM의 Character 배정 대기
```

Player가 Character 목록에서 스스로 소유권을 선택하는 Entry 화면은 사용하지 않는다.

### 3.2 DM Character 배정

DM이 참가자에게 Player Character를 배정하면 하나의 권위 명령 경계에서 다음을 처리한다.

```text
AssignCharacterToParticipant
→ Character Owner 생성·이전
→ 현재 Controller 배정
→ Viewer Role을 Player로 전환
→ Observer Projection 폐기
→ Player Projection 재구성
→ 해당 Character의 Scene Actor를 기본 의미 선택으로 설정
→ 사용 가능한 Gameplay Input 활성화
```

- Character가 배정된 시점부터 해당 참가자는 캠페인 범위 Owner가 된다.
- 이후 Owner와 Controller는 계속 분리한다. DM은 연결 종료, 위임, 안전 경계 변경을 위해 Controller만 임시 변경할 수 있다.
- Ownership 이전·박탈은 감사 로그와 저장 Revision을 남긴다.
- 진행 중 판정·트랜잭션 중간에는 Controller를 변경하지 않는다.

### 3.3 미배정·재접속

- 미배정 참가자는 Observer 상태를 유지한다.
- 기존 Owner가 재접속하면 권위 상태 확인 후 자신의 Player Projection으로 복귀한다.
- Ownership이 제거되었거나 다른 참가자에게 이전됐다면 Observer로 남는다.
- Character 배정 중 실패하면 기존 Observer Projection을 유지하고 빈 Player HUD로 진입하지 않는다.

## 4. Player Actor 기본 의미 선택

Player Character의 Scene Actor가 존재하고 조작 가능한 동안, 별도의 선택 가능한 Actor를 명시적으로 고르지 않았으면 그 Actor가 기본적으로 선택된 것으로 판정한다.

```text
Explicit Selected Actor 있음
→ 해당 Actor가 Acting Actor

Explicit Selected Actor 없음
+ Owned Player Actor 사용 가능
→ Owned Player Actor가 Default Semantic Selection

둘 다 없음
→ Actor-less Observer/Recovery Context
```

- Q가 최상위 선택 문맥까지 돌아오면 `none`으로 해제하지 않고 기본 Player Actor로 복귀한다.
- 위임 NPC·소환체·공유 턴 Actor를 명시적으로 선택할 수 있다.
- 권한 상실, Actor 제거 또는 Scene 미배치 시 기본 선택도 함께 사라진다.
- Camera Focus와 Actor Selection은 계속 별개다.

## 5. Player 전장 UI

### 5.1 제거하는 상시 표면

Player·Observer 상시 UI에서 다음을 제거한다.

- Objective Tracker
- Minimap
- 별도 Map 화면과 Map 진입 버튼

Fog, Scene 좌표, 이동 경로와 월드 링크의 권위 데이터는 유지하지만, Player용 Map UI로 제공하지 않는다.

### 5.2 하단 Character Console

Player의 핵심 HUD는 하단에 하나의 Baldur's Gate형 Character Console로 통합한다.

```text
[조작 Actor·Party Portrait]
[Portrait · HP · 상태 · 집중]
[행동·주문·아이템 Hotbar]
[행동 자원 · 이동력 · Turn Control]
```

기존의 분리된 `ActiveActorPanel`, `ActionHotbar`, `ResourceRail`, `EndTurnControl`은 데이터 컴포넌트로는 유지하되 하나의 연속된 콘솔 외형으로 조합한다.

- 현재 기본 Player Actor가 항상 콘솔의 기준 Actor다.
- 명시적 Actor 선택 시 같은 콘솔이 해당 Actor의 Capability와 상태로 전환된다.
- Character Sheet, Inventory와 VTT 관리 보기 진입은 Portrait·Console 내 버튼에서 제공한다.
- 중앙 전장 안전 영역을 침범하는 큰 하단 창으로 확장하지 않는다.

### 5.3 Context Action Table

Right Click의 Context Action Table은 작고 빠른 세로 메뉴다.

```text
공격
밀치기
살펴보기
이동
```

- 한 열만 사용한다.
- 간단한 동사·짧은 명사만 표시한다.
- Cursor 또는 대상 근처에 배치한다.
- 상세 비용·설명은 Hover·Keyboard Focus Tooltip에서 제공한다.
- 권한에 없는 Action은 표시하지 않는다.
- 권한은 있으나 현재 불가능한 Action은 비활성 색상으로 표시하고 Hover·Focus 시 이유를 표시한다.
- 화면 중앙을 점유하는 큰 패널이나 2열 버튼 테이블을 사용하지 않는다.

## 6. 주사위 연출과 결과 Notice

```text
Sealed Roll Result
→ 물리 주사위 Visual
→ 결과 면 안정화·Presentation Complete
→ 상단 Result Notice 표시
→ 규칙 결과와 후속 Projection 반영
```

Result Notice는 화면 상단 중앙의 투명한 프레임이다.

표시 최소 정보:

- 굴림 종류와 주체
- 원시 주사위 또는 선택된 주사위
- 수정치
- 합계
- 성공·실패·명중·빗나감 등 공개 가능한 결과

규칙:

- 별도 결과 창이나 중앙 Modal을 열지 않는다.
- 전장과 Character Console을 가리지 않는다.
- 짧은 등장·유지·퇴장 Animation을 사용한다.
- Reduced Motion에서는 바로 또는 짧게 나타나지만 공개 순서는 유지한다.
- 비밀 굴림은 Audience Policy에 따라 숫자·결과를 제한한다.

## 7. Character Sheet 두 보기

### 7.1 Official Sheet View

공식 D&D 2024 Character Sheet의 정보 계층과 익숙한 읽기 순서를 최대한 유지한다.

- 한 화면 또는 넓은 펼침에서 핵심 능력, 내성, 기술, AC, Initiative, Speed, HP, Hit Dice, Death Save, 공격, 숙련, Feature, Spell, 장비와 인물 정보를 빠르게 훑을 수 있어야 한다.
- RVTT 자체 색상·테두리·아이콘·서체를 사용한다.
- 공식 로고, 일러스트, 고유 장식과 픽셀 단위 외형은 복제하지 않는다.
- 좁은 화면에서도 정보 순서를 유지한다.

### 7.2 VTT Management View

같은 Character Projection을 Baldur's Gate형 관리 화면으로 제공한다.

```text
왼쪽
→ Character·장비 Slot·핵심 능력

가운데
→ Inventory·Action·Spell Grid

오른쪽
→ 선택 Item·Feature·Spell Detail과 비교
```

- Official Sheet View와 VTT Management View는 별도 상태 원본을 만들지 않는다.
- 한 보기에서 변경된 장비·자원·Hotbar는 다른 보기와 즉시 동기화한다.
- 전투 중에는 축소된 Combat Side Sheet를 추가 제공할 수 있다.

## 8. Downtime

Downtime 활동의 생성·배정·시작·시간 진행은 DM이 결정한다.

Player 화면은 다음만 제공한다.

- DM이 배정한 현재 활동
- 예상 시간과 진행 상태
- 필요한 선택·재료·승인 Prompt
- 중단·완료·실패 결과

Player가 임의 활동을 시작하는 오른쪽 Activity Launcher·Activity Column은 제공하지 않는다. 필요 선택은 중앙 Prompt 또는 Character Console 위의 짧은 Context Surface로 표시한다.

## 9. Death Save Presentation

HP 0·Dying 상태는 일반 정보 카드가 아니라 생존 위기 Presentation으로 표시한다.

- 전장은 계속 보인다.
- 화면 가장자리에 낮은 강도의 Vignette·Pulse를 사용한다.
- Character Console은 응급 상태로 전환한다.
- 성공 3칸과 실패 3칸을 크고 즉각적으로 읽을 수 있게 표시한다.
- 현재 Turn의 Death Save가 필요하면 중앙을 막지 않는 긴박한 Prompt를 사용한다.
- 물리 주사위 연출 후 상단 Result Notice로 Death Save 결과를 표시한다.
- 과도한 Flash·Shake를 사용하지 않으며 Reduced Motion을 지원한다.

## 10. Journal

Journal은 문서 화면이며 왼쪽 세로 탭으로 정리한다.

```text
왼쪽 Vertical Document Tabs
→ 폴더·문서·현재 Scene 문서·최근 문서

가운데 Document Canvas
→ Markdown 문서·표·링크·이미지·권한별 내용

선택적 내부 패널
→ 현재 문서의 제목 목차·Backlink·링크 세부
```

- 왼쪽 탭은 항상 문서 탐색의 기준이다.
- 별도 Map Panel을 기본 구조에 포함하지 않는다.
- 권한 없는 문서는 탭·검색 결과·개수·Backlink로도 노출하지 않는다.

## 11. DM Workspace

### 11.1 Live DM 기본 배치

```text
Top Authoring Strip
→ Scene 선택·Scene Editor·Quick Edit·Fog·Time·Encounter Start·Journal·Players·Rollback

Left Inspector
→ 현재 Actor·Object·Player·Scene Selection의 속성·권한·상태

Center World View
→ Player와 같은 Scene + DM 전용 Projection

Context Popover
→ DM Quick Action
```

- Journal과 반복 수정 도구는 상단 Strip에서 연다.
- Inspector의 기본 위치는 왼쪽이다.
- 자주 쓰는 기능을 오른쪽·하단의 상시 큰 패널로 분산하지 않는다.
- 필요한 상세 도구는 도킹 가능하되 기본 읽기 흐름을 유지한다.

### 11.2 DM Quick Action

Quick Action은 별도 큰 창이 아니다.

- 선택 대상·Cursor 옆의 작은 세로 Popover 또는 Inspector 근처 Inline Menu로 표시한다.
- 가장 자주 쓰는 Action을 짧은 Label로 바로 실행한다.
- 추가 값이 필요하면 작은 Inline Stepper·Popover를 연다.
- 위험한 작업만 변경 요약 Confirmation Surface를 연다.
- Full Workspace나 Modal을 먼저 열어야 한다면 Quick Action으로 분류하지 않는다.

## 12. Scene Editor

Scene Editor는 TaleSpire형 전장 중심 Build Mode의 작업 흐름을 참고한다.

```text
Top
→ Scene·Build Mode·Select·Move·Rotate·Scale·Measure·Undo·Redo·Publish

Left
→ Selection Inspector·Hierarchy·Transform·Properties

Center
→ 전체 3D Build Viewport와 Placement Ghost

Bottom
→ Tile·Prop·Prefab·Blueprint Catalog, Search, Category, Recent
```

- Catalog는 하단에 고정 또는 확장 가능한 Tray로 둔다.
- Inspector 기본 위치는 왼쪽이다.
- Asset 선택 후 Placement Mode가 명시적으로 종료될 때까지 연속 배치한다.
- Scene 선택창은 Scene Editor 진입과 현재 Scene 전환을 함께 제공한다.
- Live DM의 Scene Quick Edit는 전체 편집기를 열지 않고 제한된 Transform·상태 변경만 제공한다.
- TaleSpire의 고유 자산·아이콘·텍스처·브랜드 표현은 복제하지 않는다.

## 13. Acceptance

최소 Human·Runtime Evidence:

- 미배정 참가자가 Observer Projection으로 진입한다.
- DM 배정 후 Owner·Controller·Player Projection이 같은 Revision 경계에서 갱신된다.
- 기본 Player Actor가 명시적 선택 없이 Acting Actor로 사용된다.
- Objective·Map·Minimap Player Surface가 존재하지 않는다.
- Character Console이 하단의 단일 연속 표면으로 표시된다.
- Context Action Table은 한 열·짧은 Label·Cursor 인접 배치다.
- 물리 주사위 완료 뒤 상단 투명 Result Notice가 나타난다.
- Official Sheet와 VTT Management View가 같은 Revision을 표시한다.
- Player가 Downtime Activity를 임의 시작할 수 없다.
- Death Save의 긴급 상태가 색상 외 형태·Text로 구분된다.
- Journal 문서 탭이 왼쪽에 있다.
- DM Inspector가 왼쪽, 주요 도구가 상단에 있다.
- Quick Action이 큰 창을 열지 않는다.
- Scene Editor Catalog가 하단에 있고 Placement Mode가 유지된다.
- Player·Observer·DM 권한 밖 정보가 자리도 남기지 않는다.

## 14. 결과

- 참가자는 관전 상태로 안전하게 들어오고 DM 배정을 통해 Player가 된다.
- Player 조작은 항상 자신의 Character Actor를 기준으로 시작한다.
- 전장 중심의 하단 Character Console이 직접 플레이를 유지한다.
- 상세 정보는 공식형 시트와 VTT 관리형 시트 두 방식으로 제공된다.
- DM Live 진행과 Full Scene Edit가 같은 도구를 공유하되 서로 다른 밀도로 표시된다.
- HTML User Guide는 이 계약을 기준으로 다시 작성한다.
