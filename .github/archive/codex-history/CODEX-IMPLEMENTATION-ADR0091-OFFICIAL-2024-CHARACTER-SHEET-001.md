# Codex Implementation — ADR-0091 Official 2024 Interactive Character Sheet 001

- commandId: `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001`
- taskType: `IMPLEMENTATION`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- phase: `FULL_UI_UX_ALIGNMENT_PHASE_10_ADR0091_OFFICIAL_2024_CHARACTER_SHEET`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_RESULT -->`

## 1. 목적

ADR-0091 / ADR-0040의 **Interactive Official 2024 Character Sheet** Production Source gap을 닫는다.

현재 독립 검증 상태:

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader = FINAL STATIC PASS
Official 2024 Interactive Character Sheet = BLOCKED
Dice Slot Reveal Notice = BLOCKED
Phase 10 = PARTIAL / HOLD
Studio/Human Runtime = NOT_EXECUTED
```

이번 작업 성공 시에만:

```text
Official 2024 Interactive Character Sheet = STATIC_VERIFIED
remaining Final Contract gaps = 1
→ final.dice-slot-reveal-notice
Phase 10 = PARTIAL / HOLD
next = DICE_SLOT_REVEAL_NOTICE
```

Dice Slot Reveal Notice 구현은 이번 작업에서 시작하지 않는다.

## 2. 시작 시 필수 확인

1. 이 command를 가장 먼저 읽는다.
2. PR #2 최신 remote HEAD를 `targetShaAtStart`로 기록한다.
3. `.github/CODEX-ACTIVE-TASK.md`, `AGENTS.md`, `AGENT-TEST-STATUS.md`, `implementation/roblox/CURRENT-WORK-ORDER.md`를 읽는다.
4. 다음 authority를 직접 읽고 충돌 시 아래 순서를 따른다.
   1. `docs/remake/decisions/ADR-0091-asset-registry-interactive-sheet-dice-and-core-rules.md`
   2. `docs/remake/ui/shared/final-ui-content-implementation-contract.md`
   3. `docs/remake/decisions/ADR-0040-official-2024-character-sheet-and-live-player-view.md`
   4. 현재 Full UI·UX implementation-ready spec / review checklist
   5. 현재 Production Source와 테스트 계약
5. 최소 다음 Source를 직접 조사한다.
   - `implementation/roblox/src/StarterGui/RVTT/App.client.lua`
   - `implementation/roblox/src/StarterGui/RVTT/UI/Components/GameplayHud.lua`
   - `implementation/roblox/src/StarterGui/RVTT/UI/Components/ManagementPanel.lua`
   - `implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/ManagementViewModel.lua`
   - `implementation/roblox/src/ReplicatedStorage/RVTT/Shared/UI/GameplayHudViewModel.lua`
   - `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/CommandClient.lua`
   - `implementation/roblox/src/StarterPlayer/StarterPlayerScripts/RVTT/Client/ProjectionReplica.lua`
   - `implementation/roblox/src/ServerScriptService/RVTT/Server/Domains/CharacterDomain.lua`
   - `implementation/roblox/src/ServerScriptService/RVTT/Server/Domains/InventoryDomain.lua`
   - spell/resource/hotbar/roll/capability 관련 현재 Domain과 command registry
   - `implementation/roblox/tests/Unit/Management.spec.lua`
   - `implementation/roblox/tests/Unit/GameplayHud.spec.lua`
   - `implementation/roblox/tests/Unit/RemoteBootstrap.spec.lua`
   - `implementation/roblox/tests/TestRunner.server.lua`
   - `implementation/roblox/tooling/validate_full_ui_ux_acceptance.py`
   - `implementation/roblox/full-ui-ux-acceptance-matrix.json`

## 3. 절대 경계

Character Sheet는 저장소/권위 상태가 아니다.

```text
Authoritative domains
+ Derived/Capability/Equipment/Spell/Vital/Resource projection data
→ CharacterSheetProjection
→ CharacterSheetViewModel
→ CharacterSheet UI
```

금지:

- Client가 HP, AC, spell slot, success, attack bonus, prepared state 등을 권위 값으로 계산/저장
- 종이 시트 UI의 TextBox 값을 Character Record 대용 저장소로 사용
- Sheet 전용 duplicate Inventory/Equipment state를 생성
- Client에서 equip/use/prepare/attune 결과를 선반영하고 서버 결과로 간주
- 새로운 직접 Remote를 Sheet 컴포넌트가 호출
- `CommandClient` / projection revision / server authorization을 우회
- Player에게 다른 캐릭터의 private 전체 sheet나 hidden feature/count/identifier를 복제
- 공식 D&D 로고·일러스트·고유 장식·폰트/상표 자산 복제
- 공식 수치나 현재 Source에 없는 character option 값을 UI 코드에 임의 하드코딩
- Dice Slot Reveal Notice 구현 시작

현재 authoritative Source가 특정 필드를 아직 갖고 있지 않으면 **값을 꾸며내지 않는다**. Projection에서 빈 값/`—`/viewer-safe unavailable 상태로 표현하거나, accepted interaction에 필수인 경우에만 server-owned generic state/command를 최소 확장하고 synthetic fixture로 검증한다.

## 4. 필수 CharacterSheetProjection 계약

명시적인 shared projection/view-model boundary를 추가한다. 이름은 repository convention에 맞추되 `CharacterSheetProjection` 개념이 Source와 test에서 식별 가능해야 한다.

Projection은 최소 다음을 viewer-safe하게 제공한다.

```text
revision
characterId
viewerRole
canReadFullSheet
identity
  name
  background
  species
  class
  subclass
  level
  xpOrProgress?
abilities[6]
saves
skills
proficiencyBonus
inspiration
training
combat
  armorClass
  initiative
  speed
  size
  passivePerception
vitals
  hpCurrent
  hpMax
  tempHp
  hitDice
  deathSaves
weaponsAndDamageCantrips
classFeatures
speciesTraitsAndFeats
spellcasting
  ability
  modifier
  saveDc
  attackBonus
  slots
  cantrips
  preparedSpells
appearance
backstoryAndPersonality
languages
equipment
coins
attunement
capability/action metadata
```

존재하지 않는 Source field는 fabricated value 대신 safe unavailable/empty projection을 사용한다.

### Revision parity

- Sheet의 `revision`은 별도 local counter가 아니다.
- VTT Inventory/Management와 같은 authoritative projection revision을 사용한다.
- 동일 projection envelope에서 Sheet와 Inventory가 서로 다른 revision을 표시하는 상태를 허용하지 않는다.
- 모든 mutable intent는 `candidateRevision`을 받고 stale이면 local intent 생성 단계 또는 server command pipeline에서 명확히 거부한다.
- receipt success와 projection reconciliation을 구분한다. receipt가 성공해도 projection revision이 반영되기 전까지 pending/awaiting-projection 상태를 유지한다.

## 5. Viewer / permission 계약

- Player: 자신의 전체 허가된 Sheet만 본다.
- DM: 현재 캠페인 권한에 따라 전체 Sheet를 read/control할 수 있다.
- Observer/다른 Player: full Sheet surface를 열 권한이 없으면 private 필드·hidden feature·count·internal id를 받지 않는다.
- UI에서 숨겼다고 끝내지 말고 projection builder 자체가 viewer-safe여야 한다.
- 권한이 취소되거나 selection/ownership이 stale해지면 Sheet는 safe unavailable/read-only 상태로 전환한다.

Focused test에서 Player owner / DM / Observer 또는 unrelated Player의 projection 차이를 직접 검증한다.

## 6. UI 정보 구조 — 비율은 Source constant + validator로 잠글 것

Reference Page Ratio:

```text
8.5 : 11 Portrait
```

### Page 1

```text
Top Header 13%
Main Content 87%

Main Left 35%
→ Proficiency
→ 6 Ability
→ Saves
→ Skills
→ Inspiration
→ Training

Main Right 65%
→ Initiative · Speed · Size · Passive Perception
→ Weapons & Damage Cantrips 24%
→ Class Features 43%
→ Species Traits / Feats 33%
```

Top Header reading order:

```text
Character Name
→ Background
→ Species
→ Class
→ Subclass
→ circular Level/XP
→ AC Shield
→ HP
→ Hit Dice
→ Death Saves
```

### Page 2

```text
Left 68%
Right 32%

Left Top
→ Spellcasting Ability 24%
→ Spell Slots 76%

Left Body
→ Cantrips & Prepared Spells

Right
→ Appearance 14%
→ Backstory & Personality 30%
→ Languages 10%
→ Equipment 34%
→ Coins 12%
```

Acceptance tolerance: **defined ratios ±2%**.

Production UI는 generic list/detail panel이 아니라 이 2-page sheet composition을 실제 Gui hierarchy/layout constants로 구현해야 한다.

### Responsive behavior

- `Wide` / `Reference`: two-page spread.
- `Compact`: Page Tab `1 / 2`.
- Compact에서 Page 내부 column을 재배치/reflow하여 정보 순서를 새로 만들지 않는다.
- 필요하면 scaling/scrolling을 사용하되 Page 1/2 내부 구조는 유지한다.
- 기본 상태는 paper-like visual density.
- Hover/Keyboard Focus 때만 Action Ring과 짧은 label을 추가한다.
- focusable control은 keyboard selection이 가능해야 한다.

RVTT DesignTokens/ThemeApplicator를 사용하고 외부 sheet asset을 복사하지 않는다.

## 7. 실제 interaction 계약

### Rollable fields

최소 다음 field는 client-side dice 계산 대신 authoritative Roll Request/기존 roll command pipeline을 사용한다.

- Ability
- Saving Throw
- Skill
- Initiative
- Weapon Attack
- Weapon Damage
- Damage Cantrip
- Spell Attack 관련 Roll
- Hit Dice
- Death Save
- Feature Roll

가능한 현재 roll/capability pipeline을 재사용한다. 새 command가 필요하면 server-authoritative domain/registry에 추가하고 client는 intent만 만든다.

### Mutable fields/actions

최소 다음 action의 ViewModel intent가 있어야 하며, authoritative backend가 실제 존재하는 action은 server command까지 연결한다.

- HP / Temporary HP mutation
- Equipment equip / unequip
- Magic Item attune / unattune
- Prepared / Memorized spell toggle
- Inventory item use / split / send
- Hotbar pin / unpin
- Inspiration spend

현재 domain에 기능이 없는 경우:

1. UI-only fake success 금지.
2. Accepted Final Contract를 만족하는 데 필요한 최소 server-owned generic command/state를 추가한다.
3. 권한/validation/revision/retry-safe 동작을 focused test로 잠근다.
4. 특정 class/item/spell 이름이나 공식 수치를 하드코딩하지 않는다.

### Equipment row popover

Page 2 Equipment Row는 `SheetItemActionPopover` 또는 동등한 명확한 component를 사용해 다음을 제공한다.

```text
equip / unequip
use
attune / unattune
Hotbar pin / unpin
details
send
```

Disabled action은 viewer-safe reason을 표시하고, unperceived action 자체는 placeholder/count를 남기지 않는다.

## 8. App / surface integration

- Character Sheet는 ManagementPanel의 generic tab으로만 구현하지 않는다.
- ADR-0040대로 gameplay HUD와 평행한 독립 surface/large overlay로 연다.
- `OpenCharacterSheet` semantic action이 Source에서 식별 가능해야 한다.
- 최소 하나의 명확한 Player UI 진입점에서 Sheet를 열 수 있어야 한다.
- Q는 현재 context 하나만 닫는 기존 grammar를 보존한다.
- ESC에 gameplay 의미를 추가하지 않는다.
- Sheet가 열려도 encounter session을 pause하지 않는다.
- higher-priority recovery/modal 상태에서 click-through를 만들지 않는다.
- action/capability 실행으로 targeting flow가 필요한 경우 기존 TargetingPlan/preview flow로 넘기고 Sheet 자체가 결과를 확정하지 않는다.

## 9. Pending / receipt / reconciliation 상태

Sheet interaction은 최소 다음을 구분한다.

```text
idle
pending receipt
accepted / awaiting projection
denied
stale projection
reconciled
permission revoked / unavailable
```

- duplicate submit 방지
- stale revision은 명시적으로 거부
- terminal receipt failure는 viewer-safe feedback
- success receipt 직후 local state mutation 금지
- authoritative projection revision 도착 시에만 reconciled
- authority epoch/rebuild가 바뀌면 pending state invalidate

기존 Management/Gameplay reconciliation pattern을 재사용한다.

## 10. Focused regression 필수

새 focused spec을 추가한다. 이름 예:

```text
implementation/roblox/tests/Unit/OfficialCharacterSheet.spec.lua
```

최소 검증:

1. owner Player projection은 자신의 full authorized sheet를 얻는다.
2. unrelated Player/Observer는 private/full sheet data를 얻지 않는다.
3. DM authorized read/control path.
4. Sheet projection revision == authoritative envelope/Inventory view revision.
5. stale `candidateRevision` intent fail closed.
6. ability/save/skill/initiative/attack/damage/death-save 등 roll intent가 client total 계산 없이 server request로 변환된다.
7. equip/unequip/use/prepare/attune/hotbar/inspiration intent가 client state mutation 없이 authoritative command를 만든다.
8. receipt success 전/후와 projection reconciliation 상태가 구분된다.
9. Page 1 layout constants가 13/87, 35/65와 required section allocation을 가진다.
10. Page 2 layout constants가 68/32, 24/76, 14/30/10/34/12를 가진다.
11. Wide/Reference two-page spread, Compact page tab 1/2이며 compact column reflow가 없다.
12. `SheetItemActionPopover` action set과 disabled semantics.
13. Viewer-safe missing/unavailable fields; fabricated official values 없음.
14. direct Remote invocation / client dice adjudication / duplicate Sheet inventory storage 없음.

해당 spec을 실제 repository test runner chain에 등록한다. 단순 파일 존재로 끝내지 않는다.

## 11. Static validator 필수

새 validator를 추가한다. 이름 예:

```text
implementation/roblox/tooling/validate_official_character_sheet.py
```

검증기는 최소 다음 regression을 CI에서 막아야 한다.

- production Character Sheet component 존재
- projection/view-model boundary 존재
- App/surface integration 존재
- `OpenCharacterSheet` identifiable contract
- layout ratio constants 존재 및 ±2% validator
- `SheetItemActionPopover` equivalent 존재
- candidate revision / reconciliation markers
- command client/server pipeline wiring
- focused spec runner registration
- client dice calculation/adjudication 금지 marker
- direct remote bypass 금지
- Acceptance matrix automatedRefs에 새 validator/spec/source 포함

`validate_full_ui_ux_acceptance.py`가 새 validator를 실행하게 한다.

Validator를 문자열 존재만 확인하는 수준으로 만들지 말고, 가능한 한 source structure + focused synthetic/model tests를 함께 실행한다.

## 12. Acceptance 상태 갱신 규칙

**모든 focused/static/build gate가 통과한 경우에만** 다음을 변경한다.

`implementation/roblox/full-ui-ux-acceptance-matrix.json`

```text
final.official-2024-sheet-interactions
BLOCKED → STATIC_VERIFIED
STATIC = PASS
```

`automatedRefs`에는 실제 Production Source, focused spec, validator를 넣는다.

`finalContractGaps`는 성공 시 정확히:

```text
[
  "final.dice-slot-reveal-notice"
]
```

다음도 동일 상태로 정합화한다.

- `implementation/roblox/FULL-UI-UX-ACCEPTANCE.md`
- `implementation/roblox/CURRENT-WORK-ORDER.md`
- `AGENT-TEST-STATUS.md`
- 필요한 README/status 문서

단, Source/Static/Build 성공을 Studio/Human Runtime PASS로 쓰지 않는다.

## 13. 현재 PASS 영역 보존

다음을 회귀시키면 작업 실패다.

- ADR-0088 pointer/input grammar
- observer-first role/entry/recovery
- Character Console / Inventory / Journal / Settings existing authority flow
- Player persistent Minimap / separate Player Map / Objective Tracker prohibition
- DM Workspace behavior
- Asset Registry / release staging
- Rules Profile / release leak gate
- Core Rules Reader private importer/stable links/owner-only nondisclosure
- public release SRD-only gate
- current Grand/Persistence contracts

특히 Character Sheet 구현 때문에 기존 Inventory command semantics를 복제하거나 약화하지 않는다.

## 14. 검증

최소:

```text
focused OfficialCharacterSheet regression
validate_official_character_sheet.py
validate_full_ui_ux_acceptance.py
validate_implementation.py / repository-required structure validators
StyLua check
Selene
all required Rojo builds
sourcemap checks
Luau type analysis
current-head PR-triggered GitHub Actions
```

GitHub Actions 중 failure/pending/cancelled가 남아 있으면 PASS 주장 금지.

Studio/Human 실행은 이번 Codex task에서 요구하지 않는다.

## 15. 완료 후 Active Task 상태

작업 완료 후 `.github/CODEX-ACTIVE-TASK.md`를 이전 stale stable-link task로 남겨두지 않는다.

성공 주장 시 최소:

```text
status: RESULT_READY_FOR_CHATGPT_VERIFICATION
commandId: RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-001
resultStatus: IMPLEMENTED_PENDING_CHATGPT_VERIFICATION
resultHeadSha: <current remote HEAD>
effectiveRemainingFinalContractGaps: 1
nextCorrectionOnVerifiedSuccess: DICE_SLOT_REVEAL_NOTICE
studioRuntimeState: NOT_EXECUTED
humanUiUxState: NOT_EXECUTED
```

ChatGPT 독립 검증 전에는 `FINAL_PASS` 같은 표현을 사용하지 않는다.

## 16. 결과 댓글

PR #2 top-level Conversation에 다음 marker로 결과를 하나 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_RESULT -->
```

최소 포함:

- commandId
- targetShaAtStart
- resultHeadSha
- resultStatus (`IMPLEMENTED_PENDING_CHATGPT_VERIFICATION` 또는 failure)
- changed files
- CharacterSheetProjection/revision parity evidence
- Page 1/Page 2 ratio evidence
- Wide/Reference/Compact evidence
- roll intent/server authority evidence
- inventory/equip/use/prepare/attune/hotbar evidence
- permission/nondisclosure evidence
- pending/receipt/reconciliation evidence
- focused regression result
- validator result
- current-head GitHub Actions result
- Acceptance matrix resulting gap count
- Studio/Human `NOT_EXECUTED`

## 17. 증거 경계

이번 task 결과가 성공해도 다음은 여전히 별도다.

```text
Studio Runtime = NOT_EXECUTED
Human UI/UX / Accessibility = NOT_EXECUTED
Multi-client Runtime = NOT_EXECUTED
Real interactive visual verification = NOT_EXECUTED
Persistence Runtime = DEFERRED
Performance / Soak = PENDING
Dice Slot Reveal Notice = BLOCKED
```

Source/Static/Build evidence와 Runtime/Human evidence를 혼동하지 않는다.
