# Codex Command — ADR-0091 Dice Slot Reveal Notice Presentation Repair 002

- commandId: `RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-FIX-002`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `e7a8adf6ef142b55aa08020f2075928b5b2f44e9`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_FIX_002_RESULT -->`
- taskType: `FOCUSED_IMPLEMENTATION_REPAIR`
- studioRuntime: `FORBIDDEN_IN_THIS_COMMAND`
- humanPlaytest: `FORBIDDEN_IN_THIS_COMMAND`

## 0. 시작 조건

작업 시작 시 PR #2 current remote HEAD를 확인한다.

- 이 command를 포함한 최신 branch HEAD에서만 작업한다.
- 새 PR/새 branch를 만들지 않는다. 기존 PR #2 branch에 fast-forward push한다.
- 외부 변경으로 HEAD가 전진했으면 먼저 diff를 확인하고 현재 HEAD 기준으로 재검증한다.
- 이미 독립 검증된 Asset Registry, Rules Profile/Release Leak Gate, Core Rules Reader, Official 2024 Character Sheet를 회귀시키지 않는다.
- Dice Notice의 기존 server projection authority, audience nondisclosure, queue/stack/reconciliation을 보존한다.
- Studio/Human Runtime은 실행하지 않는다.

## 1. ChatGPT 독립 재검증 판정

current pre-command HEAD `e7a8adf6ef142b55aa08020f2075928b5b2f44e9`에서 다음을 독립 확인했다.

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader = FINAL STATIC PASS
Official 2024 Character Sheet = FINAL STATIC PASS
Dice Slot Reveal Notice = HOLD — presentation animation incomplete
Effective ADR-0091 Source/Static finalContractGaps = 1
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

기존 Dice 구현에서 다음은 이미 통과했다. 반드시 보존한다.

- server-authored `DiceNoticeProjection`
- server-authored `naturalResults`, `appliedIndex`, `modifierTerms`, `total`, `adjudication`, `semanticCritical`, `audience`
- raw `rules.rollRecords`와 `diceNotices` 모두 viewer-safe audience/actor filtering
- normal state order/timing plan
- FIFO queue, stack cap 2, duplicate/stale/reconnect suppression
- recovery suspend
- 64×64 normal / 148×64 dual initial layout
- discarded contrast 0.5
- no client roll math / no client appliedIndex max/min selection

현재 Matrix의 `final.dice-slot-reveal-notice = STATIC_VERIFIED`, `finalContractGaps = []`는 ChatGPT 독립 판정 기준으로 **stale overstatement**다. 이 기록 자체를 성공 증거로 사용하지 않는다.

## 2. 이번 FIX-002의 정확한 blocker

현재 Production component는 phase별 `task.delay`와 visibility/size assignment 및 attribute marker만 사용한다.

- slot 숫자가 실제로 위→아래로 흐르지 않는다.
- final natural 값을 `natural_lock`에서 시각적으로 lock하는 실제 slot animation이 없다.
- `formula_expand`가 260ms animation이 아니라 즉시 size assignment다.
- Natural 1/20 full-motion critical effect가 실제 property animation으로 구현되지 않았다.
- Reduced Motion의 2–3-step crossfade / outline pulse / tint fade가 실제 property animation이 아니라 marker 수준이다.
- Natural 20은 full-motion에서 Natural 1과 동일한 감쇠 Horizontal Shake 경로를 갖지 않는다.
- Advantage/Disadvantage Applied Cell의 Accent + Scale + Formula Connector가 실제 presentation으로 구현되지 않았다.
- Advantage/Disadvantage focused regression은 synthetic notice table 중심이며 실제 Production `RulesDomain` mode path를 증명하지 않는다.
- focused validator가 실제 animation primitive/consumer를 요구하지 않아 marker-only 구현을 통과시킨다.

## 3. 실제 animation primitive 구현

`DiceSlotRevealNotice`는 marker-only가 아니라 실제 GUI property animation을 수행해야 한다.

Roblox 표준 animation primitive를 사용한다. 예:

```text
TweenService
+ clipped slot strip / moving numeral cells
+ property tweens
+ deterministic cancellation generation
```

구현 방식은 repository style에 맞춰도 되지만 아래 observable behavior는 필수다.

### 3.1 square_enter — 120ms

- normal은 실제 initial frame `64×64`.
- dual은 처음부터 최소 `148×64`.
- enter phase가 120ms presentation boundary를 실제로 소비한다.
- 결과 arithmetic/판정은 하지 않는다.

### 3.2 slot_spin — 420–720ms

숫자가 **위에서 아래로 흐르는 실제 slot presentation**을 구현한다.

필수:

- `ClipsDescendants` 또는 동등한 clipping boundary를 사용한다.
- 실제 GUI numeral cell/strip의 Y position 또는 equivalent visual property를 animation한다.
- client RNG (`Random.new`, `math.random`) 금지.
- decorative intermediate number sequence는 deterministic presentation-only sequence여야 하며 roll 결과를 계산하지 않는다.
- server `naturalResults[]`를 적용 결과 계산에 사용하지 않는다. 최종 값은 server 값 그대로 lock할 뿐이다.
- `natural_lock` 전에는 final natural result가 시각적으로 확정되어 보이지 않는다.
- Advantage/Disadvantage는 두 cell 모두 각자의 server natural에 lock한다.

### 3.3 natural_lock — 180ms

- slot movement가 끝나고 server-projected natural 값을 정확히 lock한다.
- formula/total/adjudication은 아직 숨긴다.
- Applied Cell만 `semanticCritical` visual을 받을 수 있다.
- discarded natural 1/20은 critical effect를 절대 받지 않는다.

### 3.4 formula_expand — 260ms

- frame width를 즉시 360으로 assignment해서 끝내지 않는다.
- 높이 64를 유지한 채 실제 260ms width expansion animation을 수행한다.
- Subject + Formula + Total은 이 boundary에서만 나타난다.
- client는 total이나 modifier arithmetic을 재계산하지 않는다.

### 3.5 adjudication_append — 180ms

- server-projected adjudication만 표시한다.
- client natural 값에서 success/failure/critical을 추론하지 않는다.

### 3.6 hold / dismiss

- server timingProfile의 1600–2600ms hold, 240ms dismiss boundary를 유지한다.
- dismiss/cancel/recovery/frame destroy 후 이전 tween/task callback이 stale frame에 effect를 적용하지 않도록 generation/cancellation을 보장한다.

## 4. Natural 1 / Natural 20 — 실제 full-motion 효과

Accepted Final UI contract를 그대로 구현한다.

### Natural 1

Applied Cell의 `semanticCritical == "natural_1"`일 때:

```text
natural_lock
→ 한 번의 큰 감쇠 Horizontal Shake
→ Danger Red transition
```

### Natural 20

Applied Cell의 `semanticCritical == "natural_20"`일 때:

```text
natural_lock
→ Natural 1과 같은 방식의 한 번 큰 감쇠 Horizontal Shake
→ Success Green transition
```

필수:

- 단순 attribute 설정만으로 PASS하지 않는다.
- Position / UIScale / Color / UIStroke 등 실제 visible property가 시간에 따라 변해야 한다.
- 두 semantic 모두 Applied Cell만 대상으로 한다.
- discarded natural 1/20에는 shake/tint/pulse가 없다.
- natural value 자체가 semanticCritical을 생성하지 않는다. server projection 값만 따른다.

## 5. Advantage / Disadvantage Applied Cell presentation

Dual notice에서는 server `appliedIndex`만 사용해 Applied Cell을 정한다.

Applied Cell에 실제로 다음을 표시한다.

- Accent
- Scale emphasis
- Formula Connector

Discarded Cell:

- 45–55% contrast 유지
- critical visual 없음
- formula connector 없음

`max`, `min`, natural 값 비교로 Applied Cell을 client에서 다시 선택하지 않는다.

Formula Connector는 Applied Cell과 formula 영역의 관계가 실제 UI object/line/stroke/connector로 표현되어야 하며 marker-only attribute로 끝내지 않는다.

## 6. Reduced Motion 실제 구현

Reduced Motion은 animation을 제거하는 것이 아니라 contract 방식으로 축약한다.

필수:

```text
slot_spin
→ 2–3 step actual Crossfade

natural_lock
→ no shake
→ actual Outline Pulse + Tint Fade
```

- TextTransparency / ImageTransparency / BackgroundTransparency / UIStroke.Transparency / Color 등 실제 visible property 변화로 구현한다.
- `RVTTReducedMotionCrossfadeSteps = 3` 같은 attribute만 놓는 것으로 PASS하지 않는다.
- full motion과 동일한 disclosure 순서를 유지한다.
- natural → formula/total → adjudication 순서를 합치거나 건너뛰지 않는다.
- reduced motion preference는 presentation만 바꾸고 semantics를 바꾸지 않는다.

## 7. Production Advantage / Disadvantage server path

Synthetic `notice(...)` table만으로 dual mode를 증명하지 않는다.

최소 하나의 실제 Production `RulesDomain` 경로에서 server-owned `diceMode`가 `advantage` / `disadvantage`를 생성하도록 한다.

권장 최소 변경:

```text
DM-authorized rules.create_challenge
→ validated diceMode: normal | advantage | disadvantage
→ server challenge state stores diceMode
→ rules.ability_check / saving_throw reads challenge.diceMode
→ RuleResolver.rollCheck(..., challenge.diceMode)
→ record() stores diceMode + two naturalResults + applied natural
→ DiceNoticeProjection publishes them
```

동등하게 더 적절한 existing server-owned adjudication source가 있으면 사용할 수 있다.

불변 조건:

- rolling player의 `ability_check` / `saving_throw` payload가 diceMode를 직접 지정할 수 없어야 한다.
- client Sheet/ViewModel이 advantage/disadvantage mode를 임의 지정하지 않는다.
- server state가 mode의 유일한 roll authority다.
- 특정 D&D 공식 수치/CR/규칙 수치를 새로 hardcode하지 않는다.

## 8. Focused regression 강화

`DiceSlotRevealNotice.spec.lua`를 실제 Production path와 component presentation까지 강화한다.

### Server-path required cases

1. normal challenge → Production RulesDomain roll → one natural.
2. advantage challenge → Production RulesDomain roll → two naturals + server appliedIndex.
3. disadvantage challenge → Production RulesDomain roll → two naturals + server appliedIndex.
4. rolling player payload cannot override diceMode.
5. DiceNoticeProjection preserves server mode/results/appliedIndex/total/adjudication.
6. unauthorized viewer still receives no placeholder/count/subject/action/natural/total/adjudication.

### Presentation required cases

Pure helper/descriptor tests are allowed only if the component demonstrably consumes them with real animation primitives.

At minimum assert:

1. slot spin has real vertical visual movement descriptor/primitive.
2. final natural is locked only at `natural_lock` presentation boundary.
3. formula expansion consumes 260ms and is not an instantaneous-only size assignment.
4. full-motion Natural 1 has damped horizontal shake + danger tint.
5. full-motion Natural 20 has damped horizontal shake + success tint.
6. discarded 1/20 has neither shake nor critical tint/pulse.
7. reduced motion has 2–3 actual crossfade steps and zero shake.
8. reduced motion has actual outline pulse + tint fade.
9. dual Applied Cell has Accent + Scale + Formula Connector.
10. client never recalculates appliedIndex/total/adjudication.
11. generation cancellation prevents stale tween/task mutation after dismissal/recovery.
12. FIFO/stack/replay suppression existing regressions remain green.

가능하면 component를 TestRunner에서 instantiate하여 animation setup 결과(clip container, numeral strip/cells, connector, UIScale/UIStroke/tween descriptor)를 직접 검증한다. Roblox wall-clock animation 완료를 GitHub CI에서 실행했다고 과장하지 않는다.

## 9. Validator hardening

`validate_dice_slot_reveal_notice.py`를 marker-only validator에서 실제 implementation-shape gate로 강화한다.

최소 탐지 대상:

- component가 실제 animation primitive (`TweenService:Create` 또는 동등한 repository-approved consumer)를 사용하지 않는 회귀
- slot strip/numeral vertical movement consumer 삭제
- clipping boundary 삭제
- `formula_expand`가 다시 direct-only size assignment로 퇴행
- Natural 20 full-motion shake/tint branch 삭제
- Natural 1 branch 삭제
- discarded critical effect guard 삭제
- Reduced Motion actual crossfade consumer 삭제
- Reduced Motion no-shake guard 삭제
- outline pulse/tint fade consumer 삭제
- Applied Cell scale/accent/connector 삭제
- Production challenge/server diceMode path 삭제
- player roll payload에 diceMode를 다시 허용하는 회귀
- client `Random.new`, `math.random`, Dice helper, max/min/applied arithmetic 도입
- focused spec TestRunner 등록 누락

Negative self-tests에서 위 핵심 implementation marker/consumer를 의도적으로 깨뜨린 fixture가 실제 reject되는지 증명한다.

Validator는 단순 comment나 attribute 이름 존재만으로 실제 animation 구현을 PASS시키지 않는다.

## 10. Acceptance 상태 정직성

작업 중에는 현재 over-cleared matrix를 성공 근거로 사용하지 않는다.

ChatGPT 최종 검증 전 안전 상태:

```text
final.dice-slot-reveal-notice = BLOCKED / HOLD
finalContractGaps = [final.dice-slot-reveal-notice]
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

구현·focused regression·validator·build/type·current-head Actions가 모두 성공해도 Codex result는 다음까지만 주장한다.

```text
Dice Slot Reveal Notice = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Effective source/static gap after Codex implementation = 0_PENDING_CHATGPT_VERIFICATION
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

**Matrix schema가 pending 상태를 지원하지 않으면 ChatGPT 검증 전에는 Dice item을 `BLOCKED`로 유지하고 `finalContractGaps`에 남겨라.** `STATIC_VERIFIED` / empty gaps를 미리 다시 쓰지 않는다.

## 11. 필수 검증

최소 다음을 실행한다.

- focused Dice Notice validator + negative self-tests
- strengthened DiceSlotRevealNotice focused regression의 static registration/analysis
- `validate_full_ui_ux_acceptance.py`
- `validate_implementation.py`
- private rules synthetic runtime pipeline
- public release staging/leak gate
- StyLua check
- Selene
- required Rojo builds + sourcemaps
- production/tests Luau analysis
- 관련 PowerShell/self-test가 established gate에 있으면 유지

Push 후 **result HEAD의 모든 PR-triggered GitHub Actions**를 확인한다.

- pending/failing/cancelled가 하나라도 있으면 성공 주장 금지.
- hosted-runner/infrastructure cancellation은 PASS가 아니다.
- Studio TestRunner를 GitHub Actions에서 실행하지 않았다면 Runtime PASS라고 쓰지 않는다.

## 12. 범위 밖

- Official Character Sheet 재설계
- Core Rules Reader 변경
- private rules source 변경
- Persistence
- ADR-0092 Production
- 3D dice physics
- physics dice simulation
- unrelated refactor
- Studio/MCP/Human 실행
- test 삭제/skip/assertion 약화
- validator/CI bypass
- force push
- PR ready/approve/merge

## 13. 결과 전달

PR #2 top-level Conversation에 정확히 다음 marker를 사용한다.

```text
<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_FIX_002_RESULT -->
```

필수 결과 필드:

```text
commandId
startHeadSha
resultHeadSha
resultStatus
changedFiles
slotSpinImplementation
formulaExpandImplementation
naturalOneFullMotion
naturalTwentyFullMotion
reducedMotionImplementation
dualAppliedPresentation
productionAdvantagePath
productionDisadvantagePath
audienceNondisclosure
queueStackReconciliation
focusedRegressions
validatorCoverage
localValidation
currentHeadActions
acceptanceMatrixState
studioRuntimeState
humanUiUxState
remainingRisks
```

`resultStatus`는 성공 시에도 `STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION`까지만 사용한다.

ChatGPT가 result diff, animation primitive consumption, server mode authority, regressions, validator, current-head Actions를 다시 독립 검증한 뒤에만 Final Static PASS를 결정한다.
