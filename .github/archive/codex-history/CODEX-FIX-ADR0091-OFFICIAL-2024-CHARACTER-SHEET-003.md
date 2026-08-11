# Codex Command — ADR-0091 Official 2024 Character Sheet Eligibility Authority Repair 003

- commandId: `RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-003`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `fecf0f39ce964d60229818f685afdf23cb5059e8`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_003_RESULT -->`
- taskType: `FOCUSED_IMPLEMENTATION_REPAIR`
- studioRuntime: `FORBIDDEN_IN_THIS_COMMAND`
- humanPlaytest: `FORBIDDEN_IN_THIS_COMMAND`

## 0. 시작 조건

작업 시작 시 PR #2 current remote HEAD를 확인한다.

- 이 command를 포함한 최신 branch HEAD에서 작업한다.
- 새 PR/새 branch를 만들지 않는다. 기존 PR #2 branch에만 fast-forward push한다.
- 외부 변경으로 HEAD가 전진하면 먼저 diff를 검사하고 rebase/재검증한다.
- FIX-002에서 이미 닫힌 server-authoritative roll payload, Production content hydration, canonical attack source wiring, official two-page rendering, all-equipment rows, details/send, structured slots, receipt ordering을 회귀시키지 않는다.
- Studio/Human Runtime은 실행하지 않는다.

## 1. ChatGPT 독립 검증에서 남은 차단 결함

현재 HEAD `fecf0f39ce964d60229818f685afdf23cb5059e8`는 current-head Actions가 green이고 FIX-002의 큰 축은 개선됐다. 그러나 Official Sheet를 STATIC PASS로 인정하기 전에 아래 authority gaps를 닫아야 한다.

### FINDING-SHEET-ELIGIBILITY-001 — Hit Die remaining을 서버가 강제/소모하지 않음

현재 `rules.sheet_roll`의 `hit_die` 경로는 `character.hitDice.sides`만 확인한다.

- `remaining == 0`이어도 roll 가능하다.
- 성공한 Hit Die roll이 `remaining`을 1 감소시키지 않는다.
- `CharacterSheetProjection`도 `sides`만 있으면 `roll.hit_die` action을 노출한다.

FIX-002 계약은 사용할 수 없는 Hit Die를 fail closed 하도록 요구했다.

**필수 수정:**

- Hit Die availability는 authoritative Character state의 finite integer `remaining`으로 결정한다.
- `remaining <= 0`, malformed/missing remaining, malformed sides는 fail closed 한다.
- 성공한 Hit Die roll과 `remaining -= 1`은 같은 AuthorityRuntime transaction에서 원자적으로 반영한다.
- 실패한 roll/validation/authorization에서는 remaining을 변경하지 않는다.
- Projection은 실제로 사용 가능한 경우에만 enabled Hit Die action을 제공한다.
- Client가 remaining/count/sides/modifier를 지정할 수 없다.
- 다른 character/actor의 Hit Die state를 건드릴 수 없다.

### FINDING-SHEET-ELIGIBILITY-002 — inventory.equip이 trusted equipSlot을 강제하지 않음

`inventory.create_item`은 active server-owned Item definition에서 `equipSlot`을 snapshot하지만 `inventory.equip`은 현재 client payload의 `slot`을 그대로 location에 기록할 수 있다.

따라서 직접 command를 보내면:

- `equipSlot`이 없는 item을 equip 가능
- trusted `equipSlot`과 다른 forged slot으로 equip 가능
- Sheet projection이 action을 숨겨도 server boundary를 우회 가능

**필수 수정:**

- `inventory.equip`의 canonical slot은 trusted item snapshot `item.equipSlot`이다.
- item에 valid trusted equipSlot이 없으면 fail closed.
- client-supplied arbitrary slot을 authority로 사용하지 않는다. 가능하면 payload에서 slot을 제거하고 모든 call site를 갱신한다. 호환상 필드가 남아야 한다면 trusted slot과 불일치 시 명시적으로 거부한다.
- 현재 location/target character relation도 검증하여 다른 character의 item을 equip로 몰래 이동시키는 우회가 생기지 않게 한다. 정상 cross-character transfer는 기존 send/move authority를 사용한다.
- 실패 시 item/location/revision은 변경하지 않는다.

### FINDING-SHEET-ELIGIBILITY-003 — character.sheet_set_hotbar가 hotbar capability와 character-item relation을 강제하지 않음

현재 command는 character 소유권과 item 소유권만 확인한다.

따라서 직접 command로:

- `hotbarCapable ~= true` item을 pin 가능
- 같은 user가 가진 다른 character의 item을 target character hotbar에 pin 가능

**필수 수정:**

- target item이 실제 존재하고 trusted snapshot `hotbarCapable == true`여야 한다.
- item의 current authoritative location이 target `characterId`에 속하거나 그 character가 equipped한 item이어야 한다.
- 다른 character item, ground item, capability 없는 item은 fail closed.
- unpin도 존재/관계/capability authority를 우회하지 않는다.
- 실패 시 character revision/hotbarPins를 변경하지 않는다.

### FINDING-SHEET-ELIGIBILITY-004 — fabricated fallback은 Official Sheet 성공 증거가 될 수 없음

`CharacterSheetProjection`은 이제 canonical `ActorProfileResolver.resolve(...).attacks`를 사용한다. 이 자체는 맞다. 그러나 trusted Character/Content attack definition이 없는 경우 resolver의 generic fallback attack/stat을 Official Sheet completeness의 근거로 사용하면 안 된다.

**필수 가드:**

- focused acceptance의 positive attack path는 FIX-002처럼 active server-owned `original` generic content definition에서 hydrate된 explicit attack을 사용한다.
- trusted attack source가 없는 character에 대해 Official Sheet가 임의의 weapon/damage row를 새로 발명하지 않도록 한다.
- 이 repair에서 공식 D&D 수치, CR, unarmed damage formula 등을 새로 hardcode하지 않는다.
- 기존 broader resolver fallback을 변경해야 한다면 다른 runtime consumers를 조사하고 최소 안전 변경 + regression을 동반한다. 그렇지 않으면 Sheet projection에서 trusted attack provenance가 없는 fallback을 acceptance-visible attack으로 취급하지 않는 방식도 가능하다.

## 2. 필수 Production behavior

### Hit Die

권장 invariant:

```text
before: character.hitDice = { sides = S, remaining = N }, N > 0
rules.sheet_roll(hit_die)
→ server resolves S + CON modifier
→ roll result recorded
→ same transaction: remaining = N - 1
→ authority revision increments once
→ new projection exposes N - 1
```

`remaining == 0`에서는 command failure + no roll record + no state mutation.

### Equip

권장 invariant:

```text
item.equipSlot = trusted definition snapshot
inventory.equip(itemId, characterId)
→ server verifies item belongs to character
→ server resolves trusted equipSlot
→ equipped location uses trusted slot
```

Non-equippable item과 forged alternate slot은 거부한다.

### Hotbar

권장 invariant:

```text
item.hotbarCapable == true
AND item current location belongs to characterId
→ pin/unpin allowed
otherwise → fail closed
```

## 3. Focused regression requirements

기존 `tests/Unit/OfficialCharacterSheet.spec.lua`의 real `ScenarioRuntime` / `CommandRegistry` Production path를 유지한다. direct synthetic domain-table mutation을 성공 조건으로 사용하지 않는다.

반드시 추가할 negative/positive cases:

### Hit Die

1. remaining 1 이상에서 valid Hit Die roll succeeds.
2. 성공 후 authoritative character `hitDice.remaining`이 정확히 1 감소.
3. 새로운 Projection에서 remaining이 반영되고 0이면 enabled Hit Die action이 사라짐/disabled됨.
4. remaining 0에서 direct `rules.sheet_roll(hit_die)` fails.
5. 실패 후 remaining, rollRecords, authority-relevant state가 변하지 않음.
6. forged `sides/count/modifier/remaining` payload는 validation failure 또는 no authority effect.

### Equip capability

FIX-002 fixture의 두 번째 generic item처럼 `equipSlot`이 없는 Production-created item을 사용한다.

7. non-equippable item direct `inventory.equip` fails.
8. equippable item은 trusted slot에만 equip.
9. forged different slot이 trusted slot을 바꾸지 못하고 preferably fails.
10. 다른 character inventory item을 equip command로 target character에 우회 이동시키지 못함.

### Hotbar capability

11. `hotbarCapable` 없는 Production-created item direct pin fails.
12. hotbar-capable item belonging to character A를 character B hotbar에 pin fails.
13. valid own hotbar-capable item pin/unpin succeeds.

### No fabricated attack acceptance

14. explicit trusted `attack:generic` positive path는 계속 통과.
15. trusted attack definition이 없는 Production-created character에서는 Sheet가 새 attack row/formula를 발명하지 않는 negative regression을 추가하거나, 해당 provenance를 명시적으로 증명한다.

모든 failure case에서 관련 domain state/revision이 예상치 않게 mutate되지 않았는지 확인한다.

## 4. Validator hardening

`implementation/roblox/tooling/validate_official_character_sheet.py`를 강화한다.

최소 탐지 대상:

- Hit Die server path가 `remaining` availability를 확인하지 않는 regression
- 성공한 Hit Die가 authoritative remaining을 소비하지 않는 regression
- Projection이 remaining 0에서도 Hit Die action을 enabled로 노출하는 regression
- `inventory.equip`이 `slot = payload.slot` 같은 client slot authority를 다시 사용
- equip path에 trusted `item.equipSlot` guard가 없는 regression
- hotbar command에 `item.hotbarCapable == true` guard가 없는 regression
- hotbar command에 target character ↔ item location relation guard가 없는 regression

가능한 경우 helper-level validator functions와 negative self-tests로 broken snippets/fixtures를 실제 reject한다. 단순 파일 존재/marker 추가만으로 만족하지 않는다.

`validate_full_ui_ux_acceptance.py`가 strengthened Official Sheet validator/self-tests를 계속 실행하도록 유지한다.

## 5. 변경 허용 범위

필요 최소 범위:

- `implementation/roblox/src/ServerScriptService/RVTT/Server/Domains/RulesDomain.lua`
- `implementation/roblox/src/ServerScriptService/RVTT/Server/Domains/InventoryDomain.lua`
- `implementation/roblox/src/ServerScriptService/RVTT/Server/Domains/CharacterDomain.lua`
- `implementation/roblox/src/ServerScriptService/RVTT/Server/Projection/CharacterSheetProjection.lua`
- 필요 시 `ActorProfileResolver.lua` 또는 provenance helper — 최소 변경만
- 관련 UI projection payload/call-site가 slot payload 제거 때문에 필요한 경우만
- `implementation/roblox/tests/Unit/OfficialCharacterSheet.spec.lua`
- `implementation/roblox/tooling/validate_official_character_sheet.py`
- 상태/acceptance 문서는 검증 결과와 정확히 맞추는 범위

Dice Slot Reveal Notice, ADR-0092 Production, persistence, Studio/Human, unrelated refactor는 범위 밖이다.

## 6. Static/build gate

변경 후 최소:

1. strengthened `validate_official_character_sheet.py`
2. full UI/UX validator + self-tests
3. implementation validator
4. StyLua/Selene
5. 모든 현재 production/test Rojo builds 및 sourcemaps
6. Luau type analysis
7. public release leak gate
8. PR current HEAD의 모든 PR-triggered Actions가 `completed/success`

GitHub Actions가 green이어도 위 semantic negative regressions가 소스에서 실제로 잠기지 않으면 PASS로 기록하지 않는다.

## 7. Acceptance 상태

작업 시작 시 ChatGPT의 독립 판정은:

```text
Official 2024 Character Sheet = HOLD
Dice Slot Reveal Notice = BLOCKED
Effective Final Contract gaps = 2
Studio/Human = NOT_EXECUTED
```

모든 source/test/static/build 조건을 닫은 뒤에만 coordinator-facing 상태를:

```text
Official 2024 Character Sheet = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Effective Final Contract gaps = 1
→ final.dice-slot-reveal-notice
```

으로 올릴 수 있다. Codex는 `FINAL_PASS`를 쓰지 않는다.

## 8. 결과 댓글

PR #2 top-level Conversation에 정확히 다음 marker로 결과를 남긴다.

```text
<!-- RVTT_CODEX_ADR0091_OFFICIAL_2024_CHARACTER_SHEET_FIX_003_RESULT -->
```

최소 필드:

```text
commandId: RVTT-PR2-ADR0091-OFFICIAL-2024-CHARACTER-SHEET-FIX-003
targetShaAtStart: <sha>
resultHeadSha: <sha>
resultStatus: IMPLEMENTED_PENDING_CHATGPT_VERIFICATION
hitDieAuthority: <summary>
equipAuthority: <summary>
hotbarAuthority: <summary>
attackNonInventionGuard: <summary>
negativeRegressions: <summary>
validatorCoverage: <summary>
currentHeadActions: <summary>
acceptanceMatrixState: <summary>
studioRuntimeState: NOT_EXECUTED
```

불완전하면 `BLOCKED` 또는 `PARTIAL`로 기록하고 미해결 항목을 명시한다.