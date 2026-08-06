# ADR-0091: 개발 에셋 레지스트리, 상호작용형 2024 공식 시트, 단계형 주사위 Notice와 모듈형 Core Rules Reader를 사용한다

- 상태: 확정
- 결정일: 2026-08-06
- 결정 종류: Content Asset · Character Sheet · Dice Presentation · Journal Rules Reader · Final UI Closure
- 보강 대상:
  - [`ADR-0040`](ADR-0040-character-sheet-and-official-sheet-ui.md)
  - [`ADR-0044`](ADR-0044-journal-and-ping-ui.md)
  - [`ADR-0089`](ADR-0089-observer-first-session-and-ui-surface-realignment.md)
  - [`ADR-0090`](ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 상세 계약:
  - [`final-ui-content-implementation-contract.md`](../ui/shared/final-ui-content-implementation-contract.md)
  - [`final-ui-surface-gap-audit.md`](../audits/final-ui-surface-gap-audit.md)

## 1. 배경

구현 직전 UI를 고정하려면 화면 배치뿐 아니라 개발자가 에셋을 어디에 추가하는지, 공식형 Character Sheet가 실제 명령을 어떻게 실행하는지, Dice 결과를 어떤 단계로 공개하는지, 대용량 Core Rules를 어떻게 저장·탐색하는지까지 정해야 한다.

기존 `rvtt.core.rules`와 `rvtt.core.baseline` 패키지를 유지하고 확장한다. 별도의 중복 Content 체계를 만들지 않는다.

## 2. 개발 에셋 위치

에셋은 Authoring Source, Server Registry, Client-safe Runtime Projection을 분리한다.

```text
implementation/roblox/content-source/packages/<packageId>/
→ 개발 원본·Manifest·Preview·Source Metadata

implementation/roblox/src/ServerStorage/RVTT/Content/Packs/<packageId>/
→ 권위 Package Manifest·Definition·Validation Metadata

implementation/roblox/src/ReplicatedStorage/RVTT/ContentRuntime/
→ 승인된 Client-safe Catalog·Thumbnail·UI Asset View
```

Token·Prop·Tile·Volume·Material·VFX·UI Icon·Gizmo·Thumbnail·Animation·Rules·Localization은 모두 Package ID와 Stable Asset ID를 가진다. Binary를 경로 이름이나 Roblox Instance 이름만으로 참조하지 않는다.

## 3. 공식 2024 Character Sheet

Official Sheet는 2024 Character Sheet의 두 페이지 정보 비율과 읽기 순서를 기준으로 한다. RVTT 로고·색상·Icon·서체를 사용하며 외부 로고·고유 장식·일러스트를 복제하지 않는다.

### Page 1 비율

```text
상단 Identity·Level·AC·HP·Hit Dice·Death Saves
→ 전체 폭

본문 Left 약 35%
→ Proficiency · 6 Ability · Save · Skill · Inspiration · Training

본문 Right 약 65%
→ Initiative · Speed · Size · Passive Perception
→ Weapons & Damage Cantrips
→ Class Features
→ Species Traits · Feats
```

### Page 2 비율

```text
Left 약 68%
→ Spellcasting Ability · Spell Slots
→ Cantrips & Prepared Spells 대형 표

Right 약 32%
→ Appearance
→ Backstory & Personality
→ Languages
→ Equipment · Attunement
→ Coins
```

시트는 읽기 전용 이미지가 아니다. 능력·내성·기술·Initiative·공격·피해·주문·Death Save는 서버 Roll Request를 만들고, Equipment·Attunement·Prepared 상태는 권한 있는 Command를 실행한다. 장착·해제·사용·Hotbar 고정은 VTT Inventory와 같은 Projection·Command를 사용한다.

## 4. Dice Result Notice

일반 d20 결과는 다음 단계로 공개한다.

```text
square_spin
→ natural_lock
→ formula_expand
→ adjudication_append
→ hold
→ dismiss
```

1. 상단 중앙에 정사각형 투명 Frame이 나타난다.
2. 숫자가 위에서 아래로 Slot Machine처럼 흐른다.
3. Natural d20 값에 멈춘다.
4. Frame이 오른쪽으로 부드럽게 확장되며 Modifier·Formula를 붙인다.
5. 서버가 확정한 성공·실패·명중·빗나감·Critical 결과를 마지막에 붙인다.

Natural 1은 한 번 큰 감쇠 Shake 후 붉은 Semantic Tint로 전환한다. Natural 20은 같은 방식으로 초록 Semantic Tint로 전환한다. Reduced Motion에서는 Shake를 제거하고 Outline·Scale Pulse·Tint만 사용한다.

Advantage·Disadvantage는 처음부터 직사각형 Frame과 두 Natural Cell을 사용한다. 적용된 Die에만 Natural 1·20 Effect와 Formula 연결 강조를 붙이고 버려진 Die는 낮은 대비로 남긴다.

Client는 성공·실패·Critical 여부를 추론하지 않는다. Notice Projection이 Natural Dice, Applied Dice, Formula, Adjudication과 Audience를 제공한다.

## 5. Core Rules Reader

Journal에 `Core Rules` Collection을 기본 제공한다. 기존 `rvtt.core.rules`는 Meta Package이며 내부에 다수의 Rule Module을 가진다.

```text
RuleContentPackage
→ RuleModule
→ RuleDocument
→ RuleSection
→ RuleChunk
```

200,000자를 넘는 전체 규칙을 하나의 String·Document로 저장하지 않는다. Module은 의미 단위로 나누고 Document는 제목·표·목록 경계를 보존한 Chunk로 Lazy Load한다.

기본 Module 예시:

- Playing the Game
- Character Creation
- Equipment
- Spells
- Rules Glossary
- Creatures
- Conditions

Journal Reader는 왼쪽 `Collection → Module → Document` Tree, 가운데 Virtualized Article, 오른쪽 Outline·Source·Backlink를 사용한다. Character Sheet·Action Hover·Dice Result·Condition에서 정확한 Rule Anchor로 이동할 수 있다.

배포 가능한 기본 내용은 권리 상태가 확인된 SRD 5.2.1 Module로 제한한다. 다른 Core Book의 전체 본문은 공개 저장소에 넣지 않고 License·Entitlement가 확인된 Package 또는 사용자 승인 Import로 제공한다.

## 6. 최종 UI 공백 폐쇄

이번 결정은 다음 화면·상태를 구현 대상에 추가한다.

- Invite·Join Code와 최근 Session 진입
- First-run Control Primer
- Content Package·Asset Registry Browser
- Missing Asset·Broken Dependency Repair
- Rules Reader Loading·Search·No Result·License State
- Official Sheet Hover·Focus·Pending·Denied
- Dice Normal·Advantage·Disadvantage·Natural 1·Natural 20·Reduced Motion
- Unsaved Window·Publish Conflict·Close Confirmation
- Key Binding Capture·Conflict Resolution
- Permission Revoked·Stale Projection·Reconnect Safe State
- Content Attribution·License Notice

Controller·Touch 전용 조작과 Audio Mixer는 현재 Release UI 범위 밖이다. 존재하지 않는 기능을 빈 Tab으로 표시하지 않는다.

## 7. Acceptance

- Token·Prop Prefab과 모든 개발 에셋이 Package·Stable ID·Rights Metadata를 가진다.
- Authoring Source와 Runtime Client-safe Asset가 분리된다.
- Official Sheet의 두 페이지 비율이 2024 Sheet 기준과 일치한다.
- Official Sheet에서 Roll·Equip·Unequip·Use·Prepare·Attune Command를 실행할 수 있다.
- Official Sheet와 VTT Inventory가 같은 Revision을 표시한다.
- 일반 d20 Notice가 Square Spin에서 Rectangle Formula로 확장된다.
- Natural 1·20과 Advantage·Disadvantage 변형이 Reduced Motion까지 동작한다.
- Journal에서 Core Rules Module을 검색·읽고 Stable Anchor로 이동한다.
- 200,000자 이상 Package도 전체 본문을 한 번에 Client에 보내지 않는다.
- 권리 없는 Rule Module은 제목·개수·검색 결과도 노출하지 않는다.
- Final UI Gap Audit의 Release-blocking 항목이 모두 문서·Acceptance에 연결된다.
