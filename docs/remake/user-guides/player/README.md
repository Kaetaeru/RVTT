# RVTT Player·Observer Guide

- 상태: `CURRENT · TARGET_EXPERIENCE`
- 최종 갱신일: 2026-08-06
- User Guide Hub: [`../README.md`](../README.md)
- HTML 순서: [`UI-EXAMPLES.md`](UI-EXAMPLES.md)
- 상위 결정: [`ADR-0089`](../../decisions/ADR-0089-observer-first-session-and-ui-surface-realignment.md)

## 1. 처음 세션에 들어올 때

세션에 연결하면 먼저 Observer가 된다.

```text
연결
→ 공개 Scene과 공개 정보 동기화
→ Observer Ready
→ DM의 Character 배정 대기
```

Character 선택 목록에서 자신이 사용할 Character를 고르지 않는다. DM이 Character를 배정하면 다음이 함께 바뀐다.

- 해당 Character의 Owner
- 현재 Controller
- Observer에서 Player로 역할 Projection
- Player Character Console
- Owned Actor 기본 의미 선택

전환이 완료되기 전에는 Character 행동을 할 수 없다.

## 2. Observer일 때

가능:

- 공개 Scene과 Camera 확인
- 공개 Dice Result Notice·Event Log 확인
- 공개 Journal 문서 읽기
- System·Accessibility 설정

불가능:

- Character Console 사용
- Actor 이동·행동
- Character Sheet·Inventory 열기
- 권한 없는 Actor·문서·Action 확인

## 3. 기본 Player Actor

Character가 배정되면 그 Character의 Scene Actor가 기본적으로 선택된 것으로 판정된다.

- 다른 조작 Actor를 명시적으로 선택할 수 있다.
- Q로 선택 문맥을 끝내면 아무것도 없는 상태가 아니라 자신의 Character로 돌아온다.
- Camera가 다른 곳을 보고 있어도 Acting Actor는 바뀌지 않는다.

## 4. 하단 Character Console

하단 Console에는 다음이 한 표면에 모인다.

- 조작 Actor 전환
- Portrait·HP·임시 HP·상태·집중
- 행동·주문·아이템·특성 Hotbar
- 행동·추가 행동·반응·이동력과 직업 자원
- Turn 종료
- Character Sheet·Inventory 진입

Objective·Map·Minimap UI는 없다.

## 5. 마우스와 키

```text
Left Click
→ Actor 선택 또는 화면에 미리 표시된 기본 행동

Right Click
→ Cursor 옆 작은 세로 Action Menu

Middle-button Drag
→ Camera Orbit

Wheel
→ Zoom

Q
→ 현재 Targeting·Menu·Preview 한 단계 취소
→ 명시 Actor 선택 종료 시 자신의 Character로 복귀

E
→ 화면에 보이는 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```

## 6. Context Action Menu

우클릭 Menu는 짧은 Action 이름을 한 열로 표시한다.

```text
공격
밀치기
대화
살펴보기
문 열기
```

현재 할 수 없는 Action은 비활성 색상이며 Hover·Keyboard Focus 시 이유가 Cursor 근처에 나타난다. 권한 자체가 없는 Action은 표시되지 않는다.

## 7. 이동·공격·주문

실행 전에 전장에서 확인한다.

- 이동 경로·거리·위험
- Target 유효성·사거리·범위
- 공개 가능한 명중 예상
- Action Resource와 Spell Slot
- 아군 피해·집중 종료·기회 공격

Preview는 확정 결과가 아니다. 서버 승인 후 실제 Token·HP·자원이 갱신된다.

## 8. 주사위

주사위 값은 서버가 결정한다.

```text
물리 주사위 Visual
→ 결과 면 표시
→ 상단 투명 Result Notice
→ 규칙 결과 반영
```

Notice에는 굴림 이름, 주사위, 수정치, 합계와 공개 가능한 성공·실패가 표시된다. 별도 큰 결과 창을 열지 않는다.

## 9. Character Sheet

두 보기를 지원한다.

### Official Sheet View

공식 D&D 2024 시트형 정보 순서로 능력치, 내성, 기술, 전투 수치, HP, Death Save, 공격, Feature, 주문, 장비와 인물 정보를 한눈에 확인한다.

### VTT Management View

Baldur's Gate형 관리 화면에서 장비 Slot, Inventory, Action, Spell과 Item Detail을 다룬다.

두 보기는 같은 Character 상태를 사용한다.

## 10. Downtime

Player가 오른쪽 활동 목록에서 Downtime을 시작하지 않는다. DM이 활동을 배정하고 Campaign Time 진행을 결정한다.

Player에게 필요한 선택이 있을 때만 Prompt가 열린다.

- Hit Dice 사용
- 재료·장비 선택
- 주문 준비 선택
- 중단 또는 진행 확인

## 11. HP 0와 Death Save

HP 0에서 전장은 사라지지 않는다.

- 화면 가장자리 긴급 표현
- Character Console 응급 상태
- 성공 3칸·실패 3칸
- Death Save Prompt
- 주사위 뒤 상단 결과 Notice

Reduced Motion에서는 Pulse와 Vignette를 줄인다.

## 12. Journal

Journal은 왼쪽 세로 문서 탭과 가운데 문서 Canvas로 구성된다.

- Scene 문서
- Character·세력 문서
- Handout
- 최근 문서
- 검색

권한 없는 문서는 탭·검색·관련 문서 개수로도 나타나지 않는다.

## 13. 재접속

```text
연결 복구
→ Owner·Role 확인
→ Scene Snapshot
→ Player 또는 Observer UI 재구성
→ 기본 Actor와 Console 복구
```

이전 연결의 Targeting·Prompt·Pending은 재사용하지 않는다.
