# Codex Command — ADR-0091 Official 2024 Character Sheet Focused Repair 002

- commandId: `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `0d151c8253cc36fa31f7582e845bbe184e780bbd`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_002_RESULT -->`
- taskType: `FOCUSED_IMPLEMENTATION_REPAIR`
- studioRuntime: `FORBIDDEN_IN_THIS_COMMAND`
- humanPlaytest: `FORBIDDEN_IN_THIS_COMMAND`

## 0. 시작 조건

작업 시작 시 반드시 PR #2의 current remote HEAD를 확인한다.

- HEAD가 이 command 파일을 포함하는 최신 branch HEAD라면 그 HEAD에서 진행한다.
- 다른 작업이 이미 branch를 전진시켰다면 변경 내용을 먼저 검사하고 충돌/중복 구현을 피한다.
- 새 PR/새 branch를 만들지 않는다. 기존 PR #2 branch에만 fast-forward push한다.
- 완료 전 current remote HEAD가 외부에서 바뀌면 rebase/재검증 후 결과를 게시한다.

## 1. 배경 — ChatGPT 독립 검증에서 발견된 차단 결함

직전 Codex 구현은 UI 구조·projection·command 이름·static validator와 CI는 만들었지만, 아래 이유로 `Official 2024 Character Sheet = STATIC_VERIFIED` 판정을 유지할 수 없다.

### FINDING-SHEET-AUTH-001 — `rules.sheet_roll`이 client-supplied rule semantics를 신뢰함

현재 `RulesDomain.lua`의 `rules.sheet_roll`은 actor control만 확인한 뒤 client payload의 다음 값을 규칙 의미로 사용한다.

- `ability`
- `proficient`
- `mode`
- 일부 `profileId`

따라서 악성/변조 client가 UI를 우회해 proficiency, ability, advantage/disadvantage를 임의 지정할 수 있다.

**필수 수정:** server가 authoritative state/profile에서 roll semantics를 해석해야 한다. Client는 opaque/stable roll intent identifier와 최소 target identity만 보낼 수 있다. Client가 modifier/proficiency/advantage/damage formula를 결정하면 안 된다.

### FINDING-SHEET-AUTH-002 — focused spec이 Production에서 생성 불가능한 synthetic fields를 직접 주입함

현재 `OfficialCharacterSheet.spec.lua`는 다음을 domain command/runtime hydration을 거치지 않고 직접 table에 넣는다.

- character `saves`, `skills`, `hitDice`, `classFeatures`, `attacks`, `spellcasting`, `preparedSpells`, `coins`
- inventory item `equipSlot`, `usable`, `attunable`, `hotbarCapable`

현재 `character.create_draft/activate`와 `inventory.create_item`만으로는 이 상태 일부를 생성할 수 없다. 따라서 positive interaction test 일부가 synthetic-only다.

**필수 수정:** Sheet가 읽는 authoritative data의 실제 Production constructibility를 만든다. 기존 content/domain authority를 우선 재사용하고, 없으면 최소 server-owned generic definition/state hydration boundary를 추가한다. Player client가 공식 수치/규칙 metadata를 임의 작성하는 경로를 만들지 않는다.

### FINDING-SHEET-AUTH-003 — 공격 projection이 authoritative profile과 분리됨

`ActorProfileResolver`는 canonical `profile.attacks`를 제공하지만 `CharacterSheetProjection`은 `character.attacks`만 열거한다. 실제 character state에 attacks가 없어도 authoritative profile에는 공격이 있을 수 있다.

**필수 수정:** Sheet attack/damage rows와 server roll resolution은 같은 authoritative attack source를 사용한다. label이 없으면 stable profile id를 표시할 수 있으나 수치/이름을 임의 발명하지 않는다.

### FINDING-SHEET-UI-004 — Final UI contract 정보 구조가 불완전함

Accepted Final UI contract:

```text
Reference Page Ratio = 8.5:11 portrait

Page 1 Top Header 13%
→ Character Name · Background · Species · Class · Subclass
→ circular Level/XP
→ AC Shield
→ HP
→ Hit Dice
→ Death Saves

Page 1 Main Left 35%
→ Proficiency · 6 Ability · Saves · Skills · Inspiration · Training

Page 1 Main Right 65%
→ Initiative · Speed · Size · Passive Perception
→ Weapons & Damage Cantrips 24%
→ Class Features 43%
→ Species Traits / Feats 33%

Page 2 Left 68%
→ Spellcasting Ability 24% · Spell Slots 76%
→ Cantrips & Prepared Spells

Page 2 Right 32%
→ Appearance 14%
→ Backstory & Personality 30%
→ Languages 10%
→ Equipment 34%
→ Coins 12%
```

현재 구현은 Top Header가 identity text 위주이고 AC/HP/HD/Death Saves가 header contract와 분리되어 있으며, Main Left의 Proficiency/Inspiration/Training 표현이 부족하다.

### FINDING-SHEET-UI-005 — Equipment가 첫 row 하나만 실제 interaction surface임

현재 UI는 `state.equipment[1]`만 선택하여 popover를 렌더한다.

**필수 수정:** 모든 projected Equipment Row가 표시되고 각 row에서 `SheetItemActionPopover`를 열 수 있어야 한다.

Popover 필수 action:

- equip / unequip
- use
- attune / unattune
- hotbar pin / unpin
- details
- send

`details`가 local-only이면 실제 local details surface/action을 구현한다. 단순 dead button 금지.

`send`는 target 선택이 없다는 이유로 영구 disabled 상태로 남기지 않는다. 기존 Character/Management selection authority를 재사용하거나 최소 안전한 target-picker flow를 구현한다. 권한 없는 target/count를 노출하지 않는다.

### FINDING-SHEET-UI-006 — Spell Slots table을 `tostring(table)`로 표시할 수 있음

Spell slots가 structured table이면 user-readable rows/cells로 렌더한다. Lua table identity 문자열을 UI에 표시하지 않는다.

## 2. Server-authoritative roll contract

### 2.1 client payload 최소화

`rules.sheet_roll` 또는 대체 command는 client가 다음 rule-derived 값을 신뢰 경계 안으로 주입하지 못하게 한다.

금지된 trust:

- client-selected `ability`로 modifier 결정
- client-selected `proficient`로 proficiency bonus 결정
- client-selected `mode`로 advantage/disadvantage 결정
- client-selected damage dice/count/sides/modifier
- 존재하지 않는 attack/profile/feature/spell을 임의 지정

권장 형식 예:

```text
Sheet Roll Intent
├─ actorId
├─ rollKind
├─ sourceId?    # skill/save/attack/feature/spell stable id
└─ request metadata that is not rule math
```

server는 `rollKind + sourceId + authoritative domains/profile`로 실제 ability/proficiency/formula/mode를 resolve한다.

### 2.2 각 roll kind

다음을 authoritative source에서 resolve한다.

- Ability → actor/character authoritative ability
- Saving Throw → authoritative save definition + ability + proficiency
- Skill → authoritative skill definition + ability + proficiency
- Initiative → authoritative initiative source; client가 Dex를 지정하지 않음
- Weapon Attack → authoritative `ActorProfileResolver` attack profile
- Weapon Damage / Damage Cantrip → authoritative attack damage formula
- Spell Attack → authoritative spellcasting ability/proficiency state
- Hit Die → authoritative character hit-die state; 사용할 수 없는 경우 fail closed
- Death Save → authoritative actor/character death-save eligibility; HP > 0이면 fail closed
- Feature Roll → authoritative feature roll definition

현재 authority에 advantage/disadvantage source가 없다면 기본 normal roll만 허용하고 client `mode`를 무시하는 것이 아니라 **거부하거나 payload에서 제거**한다. 향후 server-owned roll context가 생길 때만 mode를 적용한다.

### 2.3 forged payload negative regressions

반드시 server command/domain 수준 regression을 추가한다.

최소 negative cases:

1. skill source가 Strength 기반인데 client가 Charisma를 보내도 modifier가 바뀌지 않거나 request가 거부됨
2. non-proficient source에 `proficient=true`를 보내도 bonus가 생기지 않거나 request가 거부됨
3. `mode="advantage"` forged payload가 임의 advantage를 만들지 못함
4. 존재하지 않는 attack/profile id 거부
5. weapon damage formula를 client가 바꾸지 못함
6. HP > 0 actor의 death save 거부
7. 다른 사용자의 actor roll 거부

테스트가 단순 source-string marker 검사만 해서는 안 된다. 가능하면 real command registry/Domain execute path를 사용한다.

## 3. Production constructibility contract

### 3.1 Character sheet data

먼저 기존 authoritative character/content/rules data flow를 조사해 재사용한다.

Sheet가 필요로 하는 항목:

- identity/level/progress
- abilities
- saves/skills/training/proficiency/inspiration
- vitals/hit dice/death saves
- attacks/features/species traits/feats
- spellcasting/slots/available/prepared spells
- appearance/backstory/languages/coins

기존 state에 없는 값을 UI fixture에만 새로 넣지 않는다.

필요 시 minimal server-owned sheet metadata/definition hydration을 추가하되:

- 공식 D&D class/item/spell 수치를 임의 hardcode하지 않는다.
- existing Ruleset/Content definition에서 derivable한 값은 그 source를 사용한다.
- 아직 authoritative source가 없는 optional field는 `nil/empty/unavailable`로 안전 표시한다.
- fake complete sheet를 만들기 위해 10/30/1d8 같은 임의 수치를 추가하지 않는다.

### 3.2 Inventory item capability metadata

`inventory.create_item`로 생성된 실제 item이 Sheet action eligibility를 표현할 수 있어야 한다.

우선순위:

1. existing trusted Item/Content Definition lookup 재사용
2. server-owned definition registry/state
3. 최후에 DM-authorized create boundary가 필요하면 strict server validation + immutable capability snapshot

Player-owned client가 `usable=true`, `attunable=true`, damage/stat metadata 등을 arbitrary payload로 만들 수 있게 하지 않는다.

Focused regression은 **실제 inventory create/setup path로 만든 item**에서 equip/use/split/attune/hotbar/details/send eligibility를 확인한다.

### 3.3 Attack source parity

Projection과 `rules.sheet_roll`이 동일한 authoritative attack catalog를 사용한다.

`ActorProfileResolver.resolve(...).attacks`가 canonical이면 Sheet도 그 catalog를 사용한다.

## 4. Official sheet rendering repair

### 4.1 Page 1 Top Header

13% 안에서 다음 semantic controls/fields가 모두 존재해야 한다.

- Character Name
- Background
- Species
- Class
- Subclass
- Level/XP
- AC
- HP / Temp HP
- Hit Dice
- Death Saves

`HP +/-`, Temp HP, Hit Die, Death Save 등 interaction은 해당 field와 의미상 연결한다.

### 4.2 Page 1 Main Left

다음을 실제 렌더한다.

- Proficiency Bonus
- 6 Abilities
- Saves
- Skills
- Inspiration
- Training

Hover/keyboard focus 때 action affordance가 드러나는 기존 계약을 유지한다.

### 4.3 Page 1 Main Right

- Initiative
- Speed
- Size
- Passive Perception
- Weapons & Damage Cantrips 24%
- Class Features 43%
- Species Traits / Feats 33%

### 4.4 Page 2

Spell slots는 structured rendering.

Equipment 34%는 모든 row를 표시한다. 각 row에 selection/focus/Popover 진입이 있어야 한다.

Compact는 Page Tab 1/2만 사용하고 내부 column reflow 금지.

Wide/Reference는 2-page spread 유지.

## 5. Revision / receipt / recovery

기존 좋은 부분을 보존한다.

- `CharacterSheetProjection.revision == authority envelope revision`
- Inventory와 Sheet는 같은 authoritative envelope revision
- `pending_receipt`
- `accepted_awaiting_projection`
- `reconciled`
- stale revision fail closed
- permission revoke closes/purges Sheet
- authority epoch change invalidates pending Sheet commands

단, multi-command 상황에서 terminal receipt가 왔을 때 현재 feedback이 다른 command의 상태라면 잘못 reconcile하지 않는지 확인한다. 필요하면 feedback을 commandId별 또는 latest-action semantics로 안전하게 만든다.

## 6. Disclosure / permissions

보존 + 강화:

- owner Player: own full Sheet only
- authorized DM: permitted full Sheet/control
- unrelated Player: character id/name/private fields/count/action 없음
- Observer: unavailable projection only
- hidden/private inventory rows: placeholder/count조차 노출 금지
- send target picker가 있으면 authorized visible targets만 나열

## 7. Test requirements

기존 `OfficialCharacterSheet.spec.lua`를 유지/개선하되 synthetic-only fixture가 성공 조건의 전부가 되면 안 된다.

필수 새 coverage:

### A. Domain/server authority regression

실제 CommandRegistry 또는 domain handlers를 통해:

- forged roll semantics 차단
- authoritative attack formula 사용
- unauthorized actor 차단
- death-save eligibility
- vitals mutation

### B. Production constructibility regression

실제 Character/Inventory setup path를 사용해 생성된 state에서 Projection을 build한다.

최소 검증:

- inventory create/setup → Sheet equipment row
- equip/unequip
- use/split
- attune/unattune
- hotbar pin/unpin
- send target flow
- prepare/unprepare where authoritative spell source exists

해당 capability의 authoritative source가 아직 repository에 없으면 server-owned minimal definition path를 구현하고 그 path를 테스트한다. 단순 test table direct injection 금지.

### C. UI contract static/focused regression

- Top Header required fields
- Main Left Proficiency/Inspiration/Training
- all equipment rows selectable
- each selected row popover
- details actually acts locally
- send flow not permanently disabled
- structured spell slots
- Wide two-page / Compact 1/2 tabs / no compact reflow

### D. receipt/reconciliation

- stale
- denial
- accepted awaiting projection
- reconcile
- permission revoked
- epoch rebuild
- two pending sheet commands or out-of-order terminal receipts must not corrupt each other

## 8. Validator hardening

`validate_official_character_sheet.py`를 단순 marker gate보다 강화한다.

반드시 탐지할 regression:

- `RulesDomain`이 `payload.proficient`, `payload.ability`, `payload.mode`를 roll modifier/mode authority로 직접 사용하는 형태
- Projection이 canonical attack profile 대신 synthetic-only `character.attacks`만 요구하는 형태
- UI의 `state.equipment[1]` 단일 row shortcut
- spell slots에 `tostring(spellcasting.slots)` 같은 raw table rendering
- Top Header required semantic markers 누락
- domain-level authoritative regression spec 미등록

가능한 항목은 Python self-test/negative fixture로 validator 자체도 검증한다.

`validate_full_ui_ux_acceptance.py`가 strengthened validator를 계속 호출하도록 유지한다.

## 9. Acceptance state handling

ChatGPT 독립 검증 결과 현재 실제 판정은:

```text
Core Rules Reader = FINAL STATIC PASS
Rules Profile / Release = STATIC PASS
Official 2024 Character Sheet = HOLD_PENDING_AUTHORITY_REPAIR
Dice Slot Reveal Notice = BLOCKED
Effective Final Contract gaps = 2
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

현재 matrix가 Official Sheet를 이미 `STATIC_VERIFIED`로 기록하고 있더라도 이를 성공 증거로 사용하지 않는다.

작업 시작 시 또는 변경 과정에서 matrix/status docs를 실제 HOLD 상태에 맞추고, **아래 모든 gate가 통과한 뒤에만** Official Sheet를 다시 `STATIC_VERIFIED`로 올려도 된다.

성공 후:

```text
Official 2024 Character Sheet = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Final Contract gaps = [final.dice-slot-reveal-notice]
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

Codex는 `FINAL_PASS`를 쓰지 않는다. 최종 판정은 ChatGPT 독립 검증 후에만 가능하다.

## 10. Scope exclusions

이번 repair에서 하지 않는다.

- Dice Slot Reveal Notice 구현 시작
- Roblox Studio execution
- Human UI/UX execution
- Persistence campaign
- performance/soak
- ADR-0092 Production
- private rules body를 public Git에 복사
- 공식 D&D 수치 임의 생성/밸런싱

## 11. Required validation before result publication

최소:

- strengthened Official Character Sheet validator PASS
- full UI/UX static validator PASS
- implementation structure/policy PASS
- focused Luau specs registered
- StyLua `--check` PASS
- Selene PASS
- all existing Rojo builds PASS
- sourcemaps PASS
- Luau type analysis PASS
- public release leak gate PASS
- current remote HEAD의 모든 PR-triggered GitHub Actions `completed/success`

Studio runtime는 이 command에서 실행하지 않는다.

## 12. 결과 댓글

PR #2 top-level Conversation에 정확히 아래 marker를 사용한다.

```text
<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_002_RESULT -->
```

필수 결과 필드:

```text
commandId: RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-002
targetShaAtStart: <sha>
resultHeadSha: <sha>
resultStatus: IMPLEMENTED_PENDING_CHATGPT_VERIFICATION | BLOCKED
implementedScope: <summary>
serverRollAuthority: <what is authoritative now>
productionConstructibility: <how real state is built>
uiContractRepair: <summary>
negativeRegressions: <forged payload tests>
focusedTests: <tests>
staticValidation: <commands/results>
currentHeadActions: <all workflow results>
acceptanceMatrixState: <state and final gaps>
studioRuntimeState: NOT_EXECUTED
humanUiUxState: NOT_EXECUTED
remainingRisk: <honest limits>
```

`resultStatus=IMPLEMENTED_PENDING_CHATGPT_VERIFICATION`은 current result HEAD의 모든 required static/build/CI gate가 완료 성공한 경우에만 사용한다.
