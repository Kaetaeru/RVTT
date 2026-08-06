# RVTT Player·Observer UI HTML 예시

- 상태: `CURRENT · TARGET_EXPERIENCE`
- 대상: Player, Observer
- 최종 갱신일: 2026-08-06
- Player Guide: [`README.md`](README.md)
- 전체 HTML Gallery: [`../html/index.html`](../html/index.html)

이 문서는 Player Guide의 상황별 설명을 인터랙티브 HTML 화면 예시로 연결한다.

```text
HTML 예시
→ 화면 구성과 사용자 흐름 설명

Roblox Runtime
→ 실제 입력·Projection·성능과 접근성 검증
```

HTML 예시는 Runtime PASS가 아니다.

## 처음 참가할 때

- [`세션 참가·Character 선택`](../html/index.html#session-entry)
- [`System Menu·세션 나가기`](../html/index.html#system-menu)
- [`Tooltip·Toast·Component 상태`](../html/index.html#component-states)

확인할 것:

- Campaign·Role·Character와 연결 단계를 구분한다.
- Gameplay Ready 전에는 Authority-bound 입력을 활성화하지 않는다.
- Character 사용 중·잠김·DM 승인 필요·Observer 선택을 서로 다르게 표시한다.

## Exploration

- [`Exploration HUD`](../html/index.html#exploration)
- [`Context Action Table`](../html/index.html#context-actions)
- [`이동 경로 Preview`](../html/index.html#movement-preview)

확인할 것:

- 전장 중앙은 지속 Panel이 가리지 않는다.
- Left Click 결과는 클릭 전에 World Action Label로 보인다.
- Right Click은 전체 행동표, Middle-button Drag는 Camera Orbit이다.
- 권한 밖 Action은 자리도 없고, 현재 불가능 Action은 Disabled Reason을 가진다.

## Encounter

- [`Encounter HUD`](../html/index.html#encounter)
- [`공격·주문 Targeting`](../html/index.html#targeting)
- [`Reaction Authority Prompt`](../html/index.html#reaction)
- [`Dice Result·계산 상세`](../html/index.html#dice)

확인할 것:

- Initiative, Turn Resource, Movement와 End Turn을 즉시 읽을 수 있다.
- 범위·자원·명중 예상·아군 피해 위험을 실행 전에 표시한다.
- Q는 현재 Targeting 또는 Prompt 한 단계만 취소·거절한다.
- 주사위 Animation은 실제 난수 원본이 아니다.

## Character와 Item 관리

- [`Character Sheet`](../html/index.html#character-sheet)
- [`Inventory·Equipment`](../html/index.html#inventory)
- [`Loot·Container·Transfer`](../html/index.html#loot)
- [`Downtime·Short/Long Rest`](../html/index.html#downtime)
- [`HP 0·Death Save`](../html/index.html#death-save)

확인할 것:

- Item Definition, Item Instance, 위치, 장착·조율·식별 상태를 구분한다.
- Take All·Transfer·Rest는 비용과 결과 종류를 Preview한다.
- HP 0에서도 전체 화면을 제거하지 않고 현재 허용된 행동과 Party 상태를 유지한다.

## Journal·Map·Ping

- [`Journal·Objective·World Link`](../html/index.html#journal)
- [`Map·Fog·Ping`](../html/index.html#map)

확인할 것:

- 권한 없는 문서는 검색 결과, 최근 목록과 Backlink에도 나타나지 않는다.
- Map 클릭은 Camera Focus 또는 Ping Proposal이며 Character 이동과 분리한다.
- Fog 공개와 숨은 Entity 발견은 같은 상태가 아니다.

## 설정과 복구

- [`Settings · Interface`](../html/index.html#settings-interface)
- [`Settings · Camera·Accessibility`](../html/index.html#settings-accessibility)
- [`Key Binding 충돌`](../html/index.html#binding-conflict)
- [`Reconnect·Resync·Recovery`](../html/index.html#reconnect)

확인할 것:

- 기본 Accent는 Gold이며 승인된 여섯 Preset을 사용한다.
- UI Scale·Text Scale·Hotbar·Camera·Motion 설정을 즉시 Preview할 수 있다.
- Binding 충돌은 교체 결과를 저장 전에 보여 준다.
- Reconnect 중 Last Known Good 화면을 읽을 수 있어도 Authority 입력은 Gate한다.

## Observer

- [`Observer 공개 HUD`](../html/index.html#observer)

Observer는 공개 정보, Map·Journal·Log와 Camera Focus를 사용할 수 있다. 이동·공격·Item 사용 Action과 권한 밖 행동 자리는 제공하지 않는다.

## 공통 입력 요약

```text
Left Click
→ 선택 또는 표시된 기본 행동

Right Click
→ Context Action Table

Middle-button Drag
→ Camera Orbit

Q
→ 최상위 Context 한 단계 취소

E
→ 현재 Confirm 하나 제출

ESC
→ Gameplay 의미 없음
```
