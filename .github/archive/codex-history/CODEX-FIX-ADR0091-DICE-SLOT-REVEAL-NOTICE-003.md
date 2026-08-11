# Codex Command — ADR-0091 Dice Slot Reveal Notice Direction & Reduced Motion Repair 003

- commandId: `RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-FIX-003`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `e798f1ef56f022b231e344824eaa0fc583574d32`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_FIX_003_RESULT -->`
- taskType: `FOCUSED_IMPLEMENTATION_REPAIR`
- studioRuntime: `FORBIDDEN_IN_THIS_COMMAND`
- humanPlaytest: `FORBIDDEN_IN_THIS_COMMAND`

## 0. 시작 조건

PR #2 current remote HEAD를 확인하고 이 command를 포함한 최신 branch HEAD에서만 작업한다.

- 새 PR/branch 금지. 기존 PR #2 branch에 fast-forward push.
- FIX-002에서 이미 통과한 server projection authority, audience nondisclosure, queue/stack/replay suppression, Tween-based formula expansion, Natural 1/20 effects, Applied Cell emphasis, Production advantage/disadvantage server path를 회귀시키지 않는다.
- Studio/MCP/Human execution 금지.
- unrelated refactor 금지.

## 1. ChatGPT 독립 재검증 판정

pre-command HEAD `e798f1ef56f022b231e344824eaa0fc583574d32`에서 FIX-002의 대부분은 실제 Source에 반영되었으나 Dice Notice는 아직 HOLD다.

남은 blocker:

1. Full-motion slot strip이 `Y=0 -> Y=-verticalDistance`로 이동하여 화면상 숫자가 아래에서 위로 흐른다. Accepted contract는 **위에서 아래로 흐르는 slot presentation**이다.
2. Validator가 이 잘못된 negative-Y direction을 필수 marker로 요구하여 회귀를 오히려 보호한다.
3. Focused regression은 vertical movement 존재만 검사하고 방향을 검사하지 않는다.
4. Reduced Motion은 한 `LockedValue` Text를 즉시 교체한 뒤 fade-in하는 sequential fade에 가깝다. Accepted contract의 2–3-step crossfade를 outgoing/incoming visual property transition으로 명확히 구현하고 검증해야 한다.

현재 안전 상태:

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader = FINAL STATIC PASS
Official 2024 Character Sheet = FINAL STATIC PASS
Dice Slot Reveal Notice = HOLD
Effective Final Contract gaps = 1
Phase 10 = PARTIAL / HOLD
Broad current-HEAD Static Gate = NOT_STARTED
Studio/Human = NOT_EXECUTED
```

## 2. Full-motion slot direction — 위에서 아래

실제 화면에서 decorative numerals가 **위쪽에서 들어와 아래쪽으로 지나가도록** 구현한다.

허용 방식 예:

- numeral strip의 시작 Position을 negative Y로 두고 `0` 또는 positive Y 방향으로 tween
- 또는 numeral cells를 negative-to-positive Y로 tween
- 동등하게 실제 visible motion이 top -> bottom이면 허용

필수:

- `ClipsDescendants` boundary 유지.
- deterministic presentation-only sequence 유지.
- client RNG 금지.
- final server natural은 `natural_lock` 전에는 확정값으로 표시하지 않는다.
- normal/advantage/disadvantage 모두 동일 방향 semantics.
- 두 dual cells 모두 각자 server natural에 lock.
- `naturalResults`, `appliedIndex`, total/adjudication 계산은 절대 client에서 하지 않는다.

### 반드시 피할 것

현재 잘못된 형태:

```text
strip numerals: Y = 0, 56, 112, ...
strip tween:    Y = 0 -> negative
visible result: bottom -> top
```

Validator와 test에서 이 패턴을 PASS 기준으로 남기지 않는다.

## 3. Direction regression

Focused component test에서 단순 `verticalDistance > 0`만 검사하지 말고 실제 animation setup의 방향을 검증한다.

최소 증거 중 하나 이상:

- strip initial Y < final Y
- first visible decorative numeral enters from above and exits below
- equivalent helper/descriptor exposes `flowDirection = "top_to_bottom"`이며 Production component가 이를 실제 Position tween에 소비

중요: descriptor 문자열만 추가하고 component consumer가 반대 방향이면 FAIL이어야 한다.

Negative regression/self-test에서 top-to-bottom consumer를 bottom-to-top으로 변형하면 validator가 reject해야 한다.

## 4. Reduced Motion — true 2–3 step crossfade

Reduced Motion slot-spin은 shake/vertical scrolling 대신 **실제 outgoing + incoming crossfade**를 수행한다.

필수 observable behavior:

```text
value A visible
→ A fades out while B fades in (overlap allowed/expected)
→ B fades out while C fades in
→ natural_lock에서만 server natural 확정
```

구현 예:

- two alternating TextLabels/layers (`CrossfadeA`, `CrossfadeB`)
- TextTransparency tweens with overlapping fade-out/fade-in
- 2 또는 3 deterministic decorative presentation steps

금지:

- 한 TextLabel의 `.Text`를 즉시 바꾸고 매번 1 -> 0 fade-in만 하는 것을 crossfade 완료 증거로 사용
- final natural을 crossfade decorative value로 사용
- client RNG

Reduced Motion natural_lock의 기존 no-shake + outline pulse + tint fade는 보존한다.

## 5. Existing successful FIX-002 behavior regression 금지

반드시 보존:

- TweenService actual property animation
- square_enter 120ms
- slot_spin 420–720ms
- natural_lock 180ms
- formula_expand 260ms actual width tween
- adjudication_append 180ms
- hold 1600–2600ms
- dismiss 240ms
- Normal 64x64, dual >=148x64
- Natural 1 applied cell: damped horizontal shake + danger tint
- Natural 20 applied cell: same damped horizontal shake + success tint
- discarded cell critical visual 없음
- Applied Cell accent + scale + Formula Connector
- Reduced Motion zero shake + outline pulse + tint fade
- FIFO, stack cap 2, duplicate/stale/reconnect suppression
- audience/actor nondisclosure
- Production server-owned challenge diceMode for advantage/disadvantage
- rolling player payload cannot override diceMode
- no client rule math / max-min selection / RNG
- generation/tween cancellation

## 6. Validator hardening

`validate_dice_slot_reveal_notice.py`를 수정한다.

필수:

1. 기존 negative-Y movement marker를 정상 계약으로 요구하지 않는다.
2. Production component의 actual top-to-bottom Position consumer를 검사한다.
3. bottom-to-top 변형 fixture를 negative self-test로 reject한다.
4. Reduced Motion에서 two-layer/equivalent outgoing+incoming transparency consumers를 검사한다.
5. single-label text-replace + fade-in-only로 퇴행하면 reject한다.
6. 기존 Natural 1/20, formula tween, connector, server diceMode, disclosure, no-client-math guards를 유지한다.

## 7. Focused regression

`DiceSlotRevealNotice.spec.lua`에 최소 다음을 추가/강화한다.

- Production component top-to-bottom slot direction evidence.
- normal/dual 모두 direction semantics가 동일함.
- reduced motion has two visual layers or equivalent overlapping outgoing/incoming transition.
- reduced-motion decorative step 이후에도 final natural은 natural_lock 전 미표시.
- existing Production advantage/disadvantage server path remains covered.
- existing Natural 1/20 component tween assertions remain covered.

Roblox wall-clock visual PASS를 GitHub CI에서 과장하지 않는다. Static/component construction + tween configuration evidence까지만 주장한다.

## 8. Acceptance 상태 정직성

ChatGPT 재검증 전 Matrix는 계속:

```text
final.dice-slot-reveal-notice = BLOCKED
finalContractGaps = ["final.dice-slot-reveal-notice"]
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

Codex가 구현/validator/build/current-head CI를 모두 통과해도 결과는 다음까지만 주장한다.

```text
Dice Slot Reveal Notice = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Effective Source/Static gaps = 0_PENDING_CHATGPT_VERIFICATION
Broad current-head Static Gate = PENDING_CHATGPT
Studio/Human = NOT_EXECUTED
```

`FINAL_PASS`, `PHASE_10_PASS`, `STUDIO_PASS`, `HUMAN_PASS` 금지.

## 9. 검증

최소:

- focused Dice validator + negative self-tests
- full UI acceptance validator
- implementation validator
- private rules synthetic pipeline
- public release/leak staging gate
- StyLua
- Selene
- relevant Rojo builds
- Luau type analysis
- current-head PR-triggered Actions 전부 완료/success 확인

## 10. 성공 후 다음 단계 — 플레이테스트 직전 Gate

이 FIX-003를 ChatGPT가 독립 검증해 PASS하면 다음은 구현 작업이 아니라:

```text
CHATGPT_BROAD_CURRENT_HEAD_STATIC_REVALIDATION
```

이다.

그 Broad Static Gate에서 ADR-0088~0091, current Full UI matrix, build/security/release/private rules/Character Sheet/Dice Notice를 새 HEAD에 묶어서 재검증한다.

그 Gate가 PASS하면 **바로 다음 단계부터 Roblox Studio 플레이테스트/Runtime Evidence를 시작한다.** 첫 순서:

```text
Exploration · Context Input Studio Retest
→ Role · Recovery Runtime Evidence
→ Accessibility / UI·UX Human Playtest
→ DM · Player · Observer multi-client evidence
→ Grand Persistence Runtime
→ Performance · Soak
```

## 11. 결과 전달

PR #2 top-level Conversation에:

```text
<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_FIX_003_RESULT -->
```

필수 필드:

- commandId
- startHeadSha
- resultHeadSha
- resultStatus
- changedFiles
- slotDirectionEvidence
- reducedMotionCrossfadeEvidence
- componentRegressionEvidence
- validatorSelfTests
- productionAdvantageDisadvantageRegression
- currentHeadActions
- studioRuntimeState: NOT_EXECUTED
- humanUiUxState: NOT_EXECUTED
- remainingEffectiveFinalContractGaps
- next: CHATGPT_BROAD_CURRENT_HEAD_STATIC_REVALIDATION
