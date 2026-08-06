# ADR-0091: 개발 에셋 레지스트리, 상호작용형 2024 공식 시트, 단계형 주사위 Notice와 프로필 분리형 Core Rules Reader를 사용한다

- 상태: 확정
- 결정일: 2026-08-06
- 결정 종류: Content Asset · Character Sheet · Dice Presentation · Journal Rules Reader · Test Content Profile · Final UI Closure
- 보강 대상:
  - [`ADR-0040`](ADR-0040-official-2024-character-sheet-and-live-player-view.md)
  - [`ADR-0044`](ADR-0044-linked-journal-and-two-mode-ping-system.md)
  - [`ADR-0089`](ADR-0089-observer-first-session-and-ui-surface-realignment.md)
  - [`ADR-0090`](ADR-0090-multi-row-action-matrices-and-modular-dm-tool-windows.md)
- 상세 계약:
  - [`final-ui-content-implementation-contract.md`](../ui/shared/final-ui-content-implementation-contract.md)
  - [`final-ui-surface-gap-audit.md`](../audits/final-ui-surface-gap-audit.md)

## 1. 배경

구현 직전 UI를 고정하려면 화면 배치뿐 아니라 개발자가 에셋을 어디에 추가하는지, 공식형 Character Sheet가 실제 명령을 어떻게 실행하는지, Dice 결과를 어떤 단계로 공개하는지, 대용량 Core Rules를 어떻게 저장·탐색하는지까지 정해야 한다.

기존 `rvtt.core.rules`와 `rvtt.core.baseline` 패키지를 유지하고 확장한다. 별도의 중복 Content 체계를 만들지 않는다.

개발·테스트에서는 SRD만으로는 다중 서브클래스·배경·재주·주문 조합의 UI와 규칙 연동을 충분히 검증하기 어렵다. 소유자 전용 비공개 저장소에 이미 조립된 한국어 2024 플레이어 통합본을 테스트 기본 콘텐츠로 사용하되, 공개 RVTT 저장소와 공개 Release 산출물에는 비-SRD 번역 본문을 포함하지 않는다.

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

## 5. Core Rules Reader 공통 구조

Journal에 `Core Rules` Collection을 기본 제공한다. `rvtt.core.rules`는 Meta Package이며 내부에 다수의 Rule Module을 가진다.

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
- Classes
- Backgrounds
- Species
- Feats
- Equipment
- Spells
- Rules Glossary
- Creatures
- Conditions

Journal Reader는 왼쪽 `Collection → Module → Document` Tree, 가운데 Virtualized Article, 오른쪽 Outline·Source·Backlink를 사용한다. Character Sheet·Action Hover·Dice Result·Condition에서 정확한 Rule Anchor로 이동할 수 있다.

## 6. 개발·테스트 기본 통합판

개발·테스트 기본 Rule Content는 다음 비공개 Source를 사용한다.

```text
Source repository
→ Kaetaeru/D-D-2024-

Pinned source revision
→ d3d574725e0ecdfd05cb69fa32cf66196e3a8ee4

Source root
→ 10-RULEBOOKS/integrated-2024

Runtime package
→ rvtt.test.rules.2024.integrated.ko
```

이 통합판의 테스트 기준 범위는 다음과 같다.

- 기본 클래스 12개
- 서브클래스 48개
- 배경 16개
- 종족 10개
- 재주 75개
- 주문 391개
- 플레이 규칙·캐릭터 생성·장비·규칙 용어집

`development`, `test`, `studio-acceptance` 프로필은 `rvtt.test.rules.2024.integrated.ko`를 기본 선택한다. 이는 UI 밀도, 여러 서브클래스·배경 선택, 시트 생성, Spell Matrix, Inventory, Rule Link와 Level-up 흐름을 검증하기 위한 Owner-only Test Pack이다.

공개 RVTT 저장소에는 통합판 Markdown이나 변환된 Rule Chunk를 커밋하지 않는다. 공개 저장소에는 Source Binding Key, Import Schema, Stable Anchor 규칙, 기대 Count와 Hash만 둔다. 실제 Source Path·Credential은 개발자 Local Secret 또는 CI의 비공개 Secret으로 주입한다.

Private Importer는 Markdown을 읽어 다음 산출물을 임시 Build Workspace에 생성한다.

```text
Source Markdown
→ normalized document manifest
→ stable document/section anchors
→ 4–16 KB semantic chunks
→ localized search index
→ RuleContentPackage
```

통합판 Source가 없거나 Pin·Count·Hash가 맞지 않으면 개발·테스트 Build는 실패한다. 조용히 SRD로 축소해 테스트 범위를 숨기지 않는다. 명시적으로 `allowSrdFallback=true`를 지정한 개발 작업만 SRD Fallback을 허용하고 UI에 `INTEGRATED TEST PACK UNAVAILABLE`를 표시한다.

## 7. 공개·Release SRD 제한

공개 배포 프로필은 다음과 같이 분리한다.

```text
public
release
artifact
→ rvtt.core.rules
→ SRD 5.2.1 한국어 재구성 범위만 포함
```

공개 Release 산출물은 다음 Gate를 통과해야 한다.

- `rvtt.test.rules.2024.integrated.ko` Package·Chunk·Search Index 부재
- 비-SRD Source Path·Repository Token·Private Commit Metadata 부재
- 비-SRD 서브클래스·배경·재주·주문 본문 부재
- SRD Attribution·CC BY 4.0 고지 존재
- Rule Link가 공개 Package Anchor로만 해석됨

개발 기본은 통합판이고 공개 배포 기본은 SRD다. 이 둘은 같은 Build에서 자동 혼합하지 않는다. 프로필 전환은 Package Resolver와 Release Gate가 명시적으로 수행한다.

## 8. 권리·접근 경계

비공개 통합판은 소유자 전용 개발·테스트 Source다. 다음 동작을 허용하지 않는다.

- 공개 RVTT Repository로 본문 복사
- GitHub Pages·Release·Artifact에 Private Rule Chunk 포함
- 일반 사용자 대상 Package Download·Export
- 권한 없는 계정에 제목·개수·검색 Snippet·본문 복제
- Source Repository Credential을 Client에 복제

다른 Core Book 전체 본문은 별도 권리 확인 없이 Built-in Package로 승격하지 않는다. 공개 기능과 상용·외부 배포를 준비할 때는 SRD Package 또는 별도 서면 권리가 확인된 Package만 사용한다.

## 9. 최종 UI 공백 폐쇄

이번 결정은 다음 화면·상태를 구현 대상에 추가한다.

- Invite·Join Code와 최근 Session 진입
- First-run Control Primer
- Content Package·Asset Registry Browser
- Missing Asset·Broken Dependency Repair
- Rules Reader Loading·Search·No Result·License State
- Rule Profile Badge: Integrated Test·SRD Release
- Private Source Missing·Revision Mismatch·Count Mismatch
- Official Sheet Hover·Focus·Pending·Denied
- Dice Normal·Advantage·Disadvantage·Natural 1·Natural 20·Reduced Motion
- Unsaved Window·Publish Conflict·Close Confirmation
- Key Binding Capture·Conflict Resolution
- Permission Revoked·Stale Projection·Reconnect Safe State
- Content Attribution·License Notice

Controller·Touch 전용 조작과 Audio Mixer는 현재 Release UI 범위 밖이다. 존재하지 않는 기능을 빈 Tab으로 표시하지 않는다.

## 10. Acceptance

- Token·Prop Prefab과 모든 개발 에셋이 Package·Stable ID·Rights Metadata를 가진다.
- Authoring Source와 Runtime Client-safe Asset가 분리된다.
- Official Sheet의 두 페이지 비율이 2024 Sheet 기준과 일치한다.
- Official Sheet에서 Roll·Equip·Unequip·Use·Prepare·Attune Command를 실행할 수 있다.
- Official Sheet와 VTT Inventory가 같은 Revision을 표시한다.
- 일반 d20 Notice가 Square Spin에서 Rectangle Formula로 확장된다.
- Natural 1·20과 Advantage·Disadvantage 변형이 Reduced Motion까지 동작한다.
- Journal에서 Core Rules Module을 검색·읽고 Stable Anchor로 이동한다.
- 200,000자 이상 Package도 전체 본문을 한 번에 Client에 보내지 않는다.
- 개발·테스트 기본은 Pin된 한국어 통합판이며 12/48/16/10/75/391 Count를 검증한다.
- 통합판 본문과 변환 Chunk가 공개 RVTT Git Tree에 존재하지 않는다.
- Private Source가 없거나 Revision·Count가 다르면 기본 Test Build가 Fail Closed한다.
- 공개 Release는 `rvtt.core.rules` SRD 범위만 포함하고 Private Package 누출 검사를 통과한다.
- 권리 없는 Rule Module은 제목·개수·검색 결과도 노출하지 않는다.
- Final UI Gap Audit의 Release-blocking 항목이 모두 문서·Acceptance에 연결된다.
