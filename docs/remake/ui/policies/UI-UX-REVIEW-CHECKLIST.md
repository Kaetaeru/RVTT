# RVTT UI·UX Review Checklist

- 상태: CURRENT
- 문서 종류: UI·UX Policy·Screen Implementation Review Checklist
- 작성일: 2026-08-05
- 최종 개정일: 2026-08-06
- Policy Hub: [`UI·UX Global Policies`](README.md)
- 구현 직전 명세: [`구현 직전 UI·UX와 설정 명세`](../shared/implementation-ready-ui-ux-and-settings-spec.md)
- 구현 준비도 감사: [`UI·UX 구현 준비도 감사`](../../audits/ui-ux-implementation-readiness-gap-audit.md)
- 직접 플레이 결정: [`ADR-0088`](../../decisions/ADR-0088-direct-play-pointer-grammar-and-feedback.md)

이 Checklist는 새 화면, Shared Component, 사용자 Flow와 Slice Build Acceptance에서 사용한다.

판정:

```text
PASS
PASS_WITH_MEASURED_DEFAULTS
FAIL
NOT_APPLICABLE — 이유 필수
```

`FAIL` 항목이 하나라도 있으면 Production Build Acceptance를 통과시키지 않는다. 문서 존재만으로 PASS 처리하지 않고 실제 Build·Role·Viewport·Input Evidence를 남긴다.

## 1. 화면 목적과 전역 셸

- [ ] 사용자의 현재 Primary Surface와 결정이 명확하다.
- [ ] Exploration·Encounter·Downtime·Observer·DM Live·Authoring·Recovery Mode가 구분된다.
- [ ] Player·DM·Observer Role Badge와 Permission Projection이 명확하다.
- [ ] 현재 대상·비용·위험·예상 결과가 우선 표시된다.
- [ ] 같은 Authority 값을 여러 Surface에서 독립 편집하지 않는다.
- [ ] 중앙 전장 안전 영역을 지속 Panel이 가리지 않는다.
- [ ] Journal·System의 명시적 진입점이 있다.
- [ ] Inventory·Journal·Settings Panel을 Gameplay Mode로 사용하지 않는다.
- [ ] Player·Observer 상시 UI에 Minimap·별도 Map·Objective Tracker가 없다.
- [ ] Loading·Empty·Filtered Empty·Denied·Not Ready·Stale·Unavailable·Error가 구분된다.
- [ ] Panel 닫기 후 Actor Selection과 Gameplay Mode가 유지된다.

## 2. Visual Token과 Component 상태

- [ ] 임의 Hex·Font Size·Spacing·Corner·Stroke 대신 Semantic Token을 사용한다.
- [ ] `idle·hover·focused·pressed·selected·pending·disabled·denied·stale·success·warning·error` 중 필요한 상태가 정의됐다.
- [ ] 현재 불가능 Action은 비활성 색상이며 클릭할 수 없다.
- [ ] 비활성 Action의 이유를 Pointer Hover와 Keyboard Focus에서 확인할 수 있다.
- [ ] 권한에 없는 Action은 비활성 자리나 Count도 남기지 않는다.
- [ ] 색만으로 상태를 전달하지 않는다.
- [ ] 한국어 긴 Label과 큰 수치에서 Layout이 깨지지 않는다.
- [ ] UI Scale 0.80·1.00·1.40에서 핵심 조작이 유지된다.
- [ ] Layer가 World Feedback→HUD→Panel→Tooltip→Prompt→Modal→Recovery 순서를 지킨다.
- [ ] 중요한 선택·결과만 제한된 Glow·Gradient·Motion을 사용한다.

## 3. Accent와 설정 기본값

- [ ] 기본 Accent가 `gold`다.
- [ ] 승인된 Accent Preset만 노출된다.
- [ ] Settings > Interface에서 현재 Preset과 Sample Preview를 확인할 수 있다.
- [ ] UI Scale 기본 1.00, 범위 0.80–1.40이 적용된다.
- [ ] Text Scale 기본 1.00, 범위 0.90–1.30이 적용된다.
- [ ] Hotbar 기본 2행, 범위 1–4가 적용된다.
- [ ] PartyRail 기본 `auto`, CombatLog 기본 `recent`가 적용된다.
- [ ] Theme·Scale 변경 중 Focus·Selection·Pending·Modal·Input Context가 유지된다.
- [ ] Role·Authority·Success·Warning·Danger·Pending·Hidden·Content 의미색이 Accent로 변경되지 않는다.
- [ ] Category Reset과 전체 Reset이 구분된다.
- [ ] 알 수 없는 Preference가 안전한 기본값으로 복구된다.

## 4. Input·Pointer·Q/E

- [ ] Component가 물리 키와 마우스 버튼을 직접 감시하지 않는다.
- [ ] 현재 Input Context와 Q/E·Pointer 의미가 화면에 표시된다.
- [ ] 같은 입력을 두 Context가 동시에 소비하지 않는다.
- [ ] Text Input 중 Gameplay Shortcut과 Camera 입력이 실행되지 않는다.
- [ ] 1–5는 현재 Label이 보일 때만 활성화된다.
- [ ] Q가 최상위 Context 하나만 닫거나 취소한다.
- [ ] Q 한 번으로 Table·Targeting·Selection이 연쇄 해제되지 않는다.
- [ ] ESC에는 Gameplay 의미가 없다.
- [ ] E가 현재 공개된 Confirm 하나만 실행한다.
- [ ] Left Pointer 결과가 클릭 전에 Cursor·Outline·Action Label로 표시된다.
- [ ] 조작 가능한 다른 아군 Left Click은 선택 전환을 우선한다.
- [ ] Right Pointer가 Capability 기반 Context Action Table을 연다.
- [ ] Middle Pointer Drag가 Camera Orbit을 소유한다.
- [ ] Right Pointer Action Table과 Middle Pointer Camera가 충돌하지 않는다.
- [ ] Hover·Keyboard Focus·World Focus·Actor Selection·Action Target·Camera Focus가 구분된다.

## 5. Direct Play Preview와 연속성

- [ ] 기본 행동이 숨은 학습·최근 사용으로 예고 없이 변경되지 않는다.
- [ ] 이동 경로·거리·남은 이동력·도달 불가 이유가 표시된다.
- [ ] 공개된 위험·기회 공격·어려운 지형이 Preview에 표시된다.
- [ ] 공격·주문·Interaction의 사거리·범위·비용·영향 대상이 표시된다.
- [ ] 미인지 대상과 비밀 정보는 Disabled Outline조차 만들지 않는다.
- [ ] 단순 행동과 E 확인이 필요한 위험 행동의 경계가 일관된다.
- [ ] 이동·공격·상호작용 후 행동 주체 Actor Selection이 유지된다.
- [ ] 턴 전환 시 Camera가 강제로 이동하지 않는다.
- [ ] Turn Soft Focus 알림과 F·Space Frame 경로가 있다.
- [ ] Context Action Table이 열린 동안 World 기본 Left Action이 실행되지 않는다.

## 6. Tooltip·Notification·Error

- [ ] World 기본 Action 이름은 즉시 표시된다.
- [ ] Disabled Reason 초기 지연 0.15초가 적용되거나 측정 변경 근거가 있다.
- [ ] 일반 Tooltip 초기 지연 0.25초가 적용되거나 측정 변경 근거가 있다.
- [ ] 상세 Tooltip 초기 지연 0.75초가 적용되거나 측정 변경 근거가 있다.
- [ ] Tooltip이 Cursor·Token·경로·Persistent HUD를 가리지 않고 Flip한다.
- [ ] 최대 동시 Toast 3개와 동일 Event 병합이 적용된다.
- [ ] 일반 행동 실패는 Cursor·대상·Control 근처에 표시된다.
- [ ] 모든 오류를 Modal로 표시하지 않는다.
- [ ] Error 문구에 다음 행동과 안전한 Support Reference가 있다.
- [ ] 권한 거부 문구가 숨은 Entity 존재를 암시하지 않는다.

## 7. Authority Action Lifecycle

- [ ] Local Preview와 Authority Result가 시각적으로 구분된다.
- [ ] `submitted·receipt·processing·awaiting_projection·reconciled`를 필요한 범위에서 표현한다.
- [ ] Pending 동안 중복 제출을 차단한다.
- [ ] Command Result만으로 HP·Item·Turn·Position을 확정하지 않는다.
- [ ] Denied·Stale·Retryable·Resync Required의 다음 행동이 명확하다.
- [ ] Correction을 조용히 숨기지 않고 이유를 보여준다.
- [ ] 동일 멱등성 Key가 아닌 위험 행동을 자동 재시도하지 않는다.

## 8. Exploration HUD

- [ ] InitiativeRibbon·EndTurn 없이 Exploration 셸이 구성된다.
- [ ] Character Console·World Feedback이 전장 안전 영역을 지킨다.
- [ ] Exploration Hotbar가 Capability·Item·Pinned Action에서 생성된다.
- [ ] Player 연결·제어권·Summon Group 상태가 구분된다.
- [ ] World Action Label과 Movement Preview가 실제 Pointer 결과와 일치한다.

## 9. Encounter HUD

- [ ] InitiativeRibbon, Turn ResourceRail과 EndTurn이 Exploration 셸에 안전하게 추가된다.
- [ ] 현재 Turn·Opportunity·Movement Budget이 즉시 보인다.
- [ ] EndTurn은 미해결 필수 Context가 있을 때만 Disabled되고 이유를 제공한다.
- [ ] 남은 Resource가 있으면 Turn End Preview에 표시되지만 무조건 차단하지 않는다.
- [ ] Targeting·Reaction·Dice Reveal이 Input Context를 명확히 소유한다.
- [ ] HP 0·의식 없음·안정화·사망 상태가 구분된다.
- [ ] Dice·Critical 연출이 결과 의미색과 Authority 순서를 침범하지 않는다.

## 10. Inventory·Equipment·Loot

- [ ] Character·Container Source, Item 목록, Equipment, Detail·Comparison 영역이 구분된다.
- [ ] Item Definition·ItemInstance·Location·Owner가 혼동되지 않는다.
- [ ] 장착·조율·식별·수량·무게·Capacity 상태가 보인다.
- [ ] 미식별 Item의 실제 이름·희귀도·효과를 누출하지 않는다.
- [ ] Take·Take All·Send To·Split·Equip·Drop의 대상·수량·비용이 Preview된다.
- [ ] Pickup이 자동 Equip을 실행하지 않는다.
- [ ] Drag 없이 Click 기반 전체 경로를 사용할 수 있다.
- [ ] 동시 획득·Transfer 충돌을 Pending과 Transaction 결과로 처리한다.
- [ ] 절도·소유권 분쟁은 공개 가능한 경고와 DM Adjudication 경로를 가진다.
- [ ] Filtered Empty와 실제 Empty가 구분된다.

## 11. Journal·Ping

- [ ] Journal Folder·Recent·Search, Document, Outline·Backlink 영역이 구분된다.
- [ ] Stable Document·Section·Anchor ID를 사용한다.
- [ ] 화면 내 Back History와 Q 취소가 충돌하지 않는다.
- [ ] 비공개 문서가 Search·Recent·Count·Backlink에 나타나지 않는다.
- [ ] World Link가 Camera·Selection·Transition Proposal만 만든다.
- [ ] Ping이 Movement·Targeting·Journal Anchor를 자동 생성하지 않는다.

## 12. Character·Rest·Death·Downtime

- [ ] Character Sheet가 Source·Compiled Build·Current State를 구분한다.
- [ ] Sheet에서 선택한 Roll·Attack·Spell이 공통 Action Runtime으로 이어진다.
- [ ] Short·Long Rest가 시간·회복·참가자·정책·비용을 Preview한다.
- [ ] Rest 결과를 Projection 전에 낙관적으로 적용하지 않는다.
- [ ] HP 0이 전체 화면 Game Over Modal로 UI를 제거하지 않는다.
- [ ] 허용된 Death Save·Reaction·정보 Action만 표시한다.
- [ ] Downtime Activity가 기간·비용·참가자·결과 종류를 보여준다.

## 13. Settings·Bindings·Accessibility

- [ ] System Button 또는 재설정 가능한 Semantic Action으로 Settings에 진입한다.
- [ ] ESC를 Settings 진입·종료에 하드코딩하지 않는다.
- [ ] Interface·Gameplay UX·Camera·Accessibility·Bindings·Performance·Session Category가 구분된다.
- [ ] Camera 초기값과 사용자 조정 범위가 구현 직전 명세와 일치한다.
- [ ] Turn Focus 기본이 `soft_notification`, Edge Pan 기본이 Off다.
- [ ] Motion Profile 기본이 `full`이며 Reduced·Minimal에서도 같은 결과를 이해한다.
- [ ] Cursor Scale·Icon Label·Focus Ring 설정이 적용된다.
- [ ] Key Binding 충돌에서 교체·취소를 선택할 수 있다.
- [ ] Preference 저장 실패가 Gameplay를 막지 않는다.
- [ ] Account·Device·Character·Ephemeral 저장 범위가 구분된다.

## 14. Entry·Role·Reconnect·Recovery

- [ ] Session Entry가 Campaign·Role·Character Assignment·Observer·Ready 단계를 표시한다.
- [ ] Not Ready 이유와 다음 행동이 있다.
- [ ] Role Change 후 이전 권한 Action·Prompt·Selection·Pending이 남지 않는다.
- [ ] Local Layout·Accent·Accessibility·Camera Preference는 유지된다.
- [ ] Reconnect가 연결→인증→Role→Snapshot→Scene Ready→Input 단계로 표시된다.
- [ ] Projection Gap에서 부분 Replica를 적용하지 않는다.
- [ ] Last Known Good 상태를 표시하더라도 Authority Input은 Gate한다.
- [ ] Panel 오류가 다른 HUD와 Session을 종료하지 않는다.
- [ ] 이전 Epoch의 Prompt·Command·Selection·ACK를 폐기한다.

## 15. DM Workspace

- [ ] Player View Preview와 DM-only Source가 별도 Projection·Viewport다.
- [ ] User Accent와 DM Authority Accent·Label이 혼동되지 않는다.
- [ ] 일반 Player Action과 DM Override가 섹션·Label로 구분된다.
- [ ] Quick Action의 대상·공개 범위·영향·Revision·Audit이 보인다.
- [ ] Tier 3 Override가 별도 영향 Preview와 Confirm을 사용한다.
- [ ] Request Queue가 대상·우선순위·만료를 표시한다.
- [ ] Recovery Review가 Store를 직접 수정하지 않는다.

## 16. Performance·Responsive·Onboarding

- [ ] 긴 Party·Initiative·Hotbar·Inventory·Journal 목록은 가상화 또는 Paging한다.
- [ ] ViewModel은 같은 Replica Revision에서 결정적으로 생성된다.
- [ ] Projection Batch를 한 UI Commit으로 적용한다.
- [ ] Theme 변경은 전체 Gameplay UI를 불필요하게 재생성하지 않는다.
- [ ] 1280×720부터 3440×1440까지 축약 순서가 일관된다.
- [ ] Context Hint가 AuthorityPrompt보다 낮은 우선순위다.
- [ ] Hint는 성공한 Semantic Action으로 완료되고 Q로 하나만 닫을 수 있다.
- [ ] Onboarding을 꺼도 Input Hint·Accessible Label이 유지된다.
- [ ] 실제 Roblox Frame·Memory·Network·UI Commit 측정 계획이 있다.

## 17. Review 기록 Template

```text
Surface 또는 Flow:
Slice:
Reviewer:
Build·Commit:
Viewport·UI Scale:
Role·Projection:
Accent Theme:
Motion Profile:
Input Device:
결과: PASS | PASS_WITH_MEASURED_DEFAULTS | FAIL

FAIL 항목:
근거 Screenshot·Scenario·Summary:
측정으로 변경한 초기값:
수정 책임:
재검수 결과:
```
