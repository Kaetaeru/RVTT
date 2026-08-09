# Codex Command — ADR-0091 Dice Slot Reveal Notice Implementation 001

- commandId: `RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- targetShaAtCommandCreation: `a942f8187ef5535d8e74374433e4c134747dd83a`
- resultMarker: `<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_001_RESULT -->`
- taskType: `FOCUSED_IMPLEMENTATION`
- studioRuntime: `FORBIDDEN_IN_THIS_COMMAND`
- humanPlaytest: `FORBIDDEN_IN_THIS_COMMAND`

## 0. 시작 조건

작업 시작 시 PR #2 current remote HEAD를 확인한다.

- 이 command를 포함한 최신 branch HEAD에서 작업한다.
- 새 PR/새 branch를 만들지 않는다. 기존 PR #2 branch에만 fast-forward push한다.
- 외부 변경으로 HEAD가 전진하면 먼저 diff를 확인하고 current HEAD 기준으로 재검증한다.
- Official 2024 Character Sheet FIX-003, Core Rules Reader, Rules Profile/Release Gate, Asset Registry의 현재 Static/Build contract를 회귀시키지 않는다.
- Studio/Human Runtime은 실행하지 않는다.

## 1. 현재 독립 검증 상태

ChatGPT는 current pre-command HEAD `a942f8187ef5535d8e74374433e4c134747dd83a`에서 다음을 독립 검증했다.

```text
Asset Registry = STATIC PASS
Rules Profile / Release Leak Gate = STATIC PASS
Core Rules Reader = FINAL STATIC PASS
Official 2024 Character Sheet = FINAL STATIC PASS
Dice Slot Reveal Notice = BLOCKED / NOT IMPLEMENTED
Effective Final Contract gaps = 1
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
```

이번 작업은 ADR-0091의 마지막 Source/Static gap인 `final.dice-slot-reveal-notice`만 구현한다.

## 2. 권위 계약 — DiceNoticeProjection

Accepted Final UI contract의 projection shape를 Production server boundary에 구현한다.

```text
DiceNoticeProjection
├─ rollId
├─ audience
├─ diceMode
├─ naturalResults[]
├─ appliedIndex
├─ modifierTerms[]
├─ total
├─ adjudication
├─ semanticCritical
├─ subjectLabel
├─ actionLabel
├─ revealRevision
└─ timingProfile
```

### 필수 authority invariant

Client는 다음을 절대 계산하거나 판정하지 않는다.

- Applied Die 선택
- Advantage/Disadvantage 적용 결과
- Modifier arithmetic
- Total
- Success/Failure
- Critical/semanticCritical
- Adjudication text/semantic

Server-authoritative roll/rules state에서 위 projection을 완성한다. 기존 roll record가 필요한 정보를 갖지 않는다면 RulesDomain/RuleResolver의 server record contract를 최소 확장하고 기존 소비자를 회귀시키지 않는다.

`naturalResults[]`, `appliedIndex`, `modifierTerms[]`, `total`, `adjudication`, `semanticCritical`, `audience`는 모두 server-authored다.

Client는 animation/presentation만 수행한다.

## 3. 정확한 Reveal state machine

Normal d20의 상태 순서를 정확히 구현한다.

```text
hidden
→ square_enter        120 ms
→ slot_spin           420–720 ms
→ natural_lock        180 ms
→ formula_expand      260 ms
→ adjudication_append 180 ms
→ hold                1600–2600 ms
→ dismiss             240 ms
```

필수 조건:

- 첫 frame은 `64×64 px` square.
- slot spin 숫자는 위→아래 흐름이며 server natural result에서 lock.
- natural result가 Formula/Total/Adjudication보다 먼저 시각적으로 확정된다.
- `natural_lock` 전에는 Formula/Total/Adjudication을 노출하지 않는다.
- `formula_expand`에서 높이를 유지한 채 오른쪽으로 확장한다.
- 이후 Subject · Formula · Total을 표시한다.
- `adjudication_append`에서만 server adjudication을 붙인다.
- timing은 `timingProfile`을 projection에서 받아 contract 범위 안에서 결정한다. Client가 임의로 결과에 따라 timing을 바꾸지 않는다.

## 4. Advantage / Disadvantage

처음부터 최소 `148×64 px` rectangle과 Natural Cell 두 개를 표시한다.

- 두 natural result 모두 server projection의 `naturalResults[]` 그대로 사용.
- `appliedIndex`가 Applied Cell의 유일한 권위다.
- Applied Cell은 Accent + Scale + Formula Connector로 강조.
- Discarded Cell은 45–55% 대비로 낮춘다.
- Client에서 max/min으로 applied die를 다시 고르지 않는다.
- Advantage/Disadvantage 여부도 `diceMode`에서 표시만 한다.
- Applied Cell만 Natural 1/20 visual semantic 대상이다.

## 5. Natural 1 / Natural 20

Natural 1/20은 presentation semantic이며 adjudication authority가 아니다.

- `semanticCritical` 및 server-applied natural result를 기준으로 visual state를 결정한다.
- Natural 1: lock 직후 1회 큰 감쇠 Horizontal Shake → Danger Red.
- Natural 20: lock 직후 성공 강조 animation → Success Green.
- Natural 값만 보고 Client가 자동 실패/성공/critical damage를 판정하지 않는다.
- Discarded natural 1/20은 critical visual semantic을 트리거하지 않는다.

특정 D&D 규칙 수치/CR/critical adjudication을 이 UI task에서 새로 hardcode하지 않는다.

## 6. Reduced Motion

기존 User preference/reduced-motion boundary와 연결한다.

Reduced Motion에서:

- Slot Spin은 2–3단계 Crossfade로 축약.
- Shake는 완전히 제거.
- Outline Pulse + Tint Fade 사용.
- state 공개 순서와 server-authored 정보 공개 시점은 full motion과 동일.
- reduced motion 때문에 natural/formula/adjudication 순서를 합치거나 건너뛰지 않는다.

Client-side preference는 motion 표현만 바꾸고 roll semantics를 바꾸지 않는다.

## 7. Placement / Initiative collision

- 기본 위치: Top Center.
- Initiative surface와 겹치는 경우 아래로 deterministic offset.
- 화면 밖으로 밀어내지 않는다.
- Compact/Wide 모두 gameplay input을 가리지 않는 notice overlay로 유지한다.
- Dice Notice가 persistent Player HUD 기능으로 변하지 않도록 한다.

## 8. Queue / simultaneous Stack

여러 roll의 presentation policy:

- 기본은 FIFO Queue로 순차 표시.
- 동일 presentation boundary에서 동시에 보여야 하는 경우 최대 Stack 2개.
- Stack > 2 금지. 초과 roll은 queue에 남긴다.
- 동일 `rollId`는 중복 enqueue/중복 reveal하지 않는다.
- stale `revealRevision` 또는 이미 소비한 roll projection이 재도착해도 duplicate notice를 만들지 않는다.
- projection epoch/reconnect 시 이미 acknowledged/revealed roll을 무한 재생하지 않도록 deterministic reconciliation을 둔다.
- private/audience-filtered roll은 권한 없는 viewer에게 placeholder/count/subject/action/result를 노출하지 않는다.

## 9. Server projection / disclosure

새 production projection layer를 추가한다. 이름은 기존 구조와 조화되는 범위에서 결정하되 `DiceNoticeProjection` contract를 명시적으로 만족해야 한다.

필수:

- viewer audience/permission filtering은 server에서 수행.
- unauthorized viewer는 roll title, subject, action, natural count, natural value, total, adjudication을 받지 않는다.
- 공개 roll과 viewer-private roll을 구분한다.
- `revealRevision`은 authoritative projection ordering/reconciliation에 사용 가능해야 한다.
- Character Sheet roll뿐 아니라 기존 authoritative roll record 중 Dice Notice 대상인 roll을 안전하게 정규화한다.
- unsupported/incomplete roll record는 fabricated fields로 채우지 말고 fail closed / non-presentable 상태로 제외한다.

## 10. Client implementation surface

Production Client에는 최소 다음 책임 분리를 둔다.

```text
DiceNoticeProjection (server data)
→ DiceNoticeViewModel / queue reconciler
→ DiceSlotRevealNotice presentation component
→ animation state machine
```

권장 경계:

- Shared ViewModel은 deterministic state transitions/queue/stack/reduced-motion plan을 계산하되 rule math는 계산하지 않는다.
- StarterGui component는 layout/animation만 담당한다.
- App integration은 projection update를 ViewModel로 전달하고 local notice state를 렌더링한다.
- `Random.new`, `math.random`, Shared.Rules.Dice, client formula/adjudication helper를 Dice Notice path에서 사용하지 않는다.

## 11. Focused regression requirements

새 focused spec을 만들고 established TestRunner에 실제 등록한다. 이름은 `DiceSlotRevealNotice.spec.lua` 또는 repository naming convention에 맞춘다.

최소 케이스:

1. Normal d20 state order가 정확히 `hidden → square_enter → slot_spin → natural_lock → formula_expand → adjudication_append → hold → dismiss`.
2. timing 값/범위가 contract와 일치.
3. natural result가 formula/total/adjudication보다 먼저 공개됨.
4. Client ViewModel은 projection total을 그대로 쓰고 arithmetic으로 재계산하지 않음.
5. Advantage 두 cell 표시 + projection `appliedIndex`만 적용.
6. Disadvantage 두 cell 표시 + projection `appliedIndex`만 적용.
7. discarded natural 1/20은 semanticCritical visual을 트리거하지 않음.
8. applied Natural 1 visual semantic.
9. applied Natural 20 visual semantic.
10. semanticCritical=false이면 natural value만으로 Client adjudication을 만들지 않음.
11. Reduced Motion은 2–3 crossfade, no shake, 동일 state disclosure order.
12. FIFO queue ordering.
13. simultaneous stack max 2, overflow queue.
14. duplicate rollId suppression.
15. stale revealRevision suppression/reconciliation.
16. authorized public/owner/DM projection behavior.
17. unauthorized viewer nondisclosure: no placeholder/count/subject/result.
18. initiative collision offset deterministic behavior.
19. incomplete/unsupported server roll record가 fabricated projection으로 노출되지 않음.
20. no client dice/adjudication APIs on notice path.

가능하면 production-created real RulesDomain roll record를 사용해 positive path를 증명한다. 단순 synthetic `DiceNoticeProjection` table만 직접 주입해서 server normalization을 건너뛰는 테스트만으로 PASS하지 않는다.

## 12. Static validator

`implementation/roblox/tooling/validate_dice_slot_reveal_notice.py` 같은 focused validator를 추가하고 `validate_full_ui_ux_acceptance.py` / `validate_implementation.py`의 established gate에 연결한다.

Validator는 최소 다음 회귀를 탐지한다.

- state 이름 또는 순서 누락/변경
- exact/range timing contract 위반
- 64×64 normal square / 148×64 advantage-disadvantage minimum 위반
- discarded contrast 45–55% 범위 위반
- stack cap != 2
- client `Random.new`, `math.random`, Dice helper 사용
- client max/min 또는 arithmetic으로 appliedIndex/total/adjudication을 재결정하는 패턴
- reduced motion에서 shake가 남는 회귀
- projection에서 naturalResults/appliedIndex/modifierTerms/total/adjudication/semanticCritical/audience 누락
- unauthorized projection nondisclosure regression
- focused spec이 TestRunner에 등록되지 않은 상태

가능하면 helper-level validator + negative self-tests를 사용해 broken fixture/snippet을 실제 reject한다. marker-only validator로 끝내지 않는다.

## 13. Acceptance Matrix / 상태 문서

작업 시작 시:

```text
final.official-2024-sheet-interactions = STATIC_VERIFIED
final.core-rules-reader-filtering = STATIC_VERIFIED
final.rules-profile-release-leak-gate = STATIC_VERIFIED
final.dice-slot-reveal-notice = BLOCKED
finalContractGaps = [final.dice-slot-reveal-notice]
```

모든 source/focused/static/build/current-head Actions 성공 후에만 coordinator-facing 상태를:

```text
final.dice-slot-reveal-notice = STATIC_VERIFIED_PENDING_CHATGPT_VERIFICATION
Effective ADR-0091 Source/Static Final Contract gaps = 0
Phase 10 = PARTIAL / HOLD
Studio/Human = NOT_EXECUTED
next = CHATGPT_BROAD_CURRENT_HEAD_STATIC_REVALIDATION
```

으로 올릴 수 있다.

Codex는 `FINAL_PASS`, `PHASE_10_PASS`, `STUDIO_PASS`, `HUMAN_PASS`를 쓰지 않는다. ChatGPT가 diff/projection authority/regressions/validator/current-head Actions를 독립 검증한다.

## 14. 변경 허용 범위

필요 최소 범위에서만 수정한다.

예상 범위:

- server Rules/roll record normalization 또는 Dice Notice projection
- ProjectionBuilder wiring
- shared Dice Notice ViewModel/state machine
- StarterGui Dice Notice presentation component
- App/HUD overlay integration
- focused Unit/Integration spec + TestRunner registration
- focused validator + full UI/static gate wiring
- acceptance/status docs

범위 밖:

- Official Sheet 재설계
- Core Rules Reader 변경
- Dice physics/3D dice simulation
- client-side rule calculation
- Persistence
- ADR-0092 Production
- Studio/Human execution
- unrelated refactor

## 15. Static/build gate

변경 후 최소:

1. focused Dice Notice validator + negative self-tests
2. Full UI/UX validator + self-tests
3. implementation validator
4. existing Asset/Rules/Reader/Official Sheet validators 회귀 없음
5. public release leak gate
6. StyLua
7. Selene
8. 모든 current production/test Rojo builds + sourcemaps
9. Luau type analysis
10. PR current HEAD의 모든 PR-triggered Actions `completed/success`

GitHub Actions green만으로 semantic PASS를 주장하지 않는다.

## 16. 결과 댓글

PR #2 top-level Conversation에 정확히 다음 marker를 사용한다.

```text
<!-- RVTT_CODEX_ADR0091_DICE_SLOT_REVEAL_NOTICE_001_RESULT -->
```

최소 필드:

```text
commandId: RVTT-PR2-ADR0091-DICE-SLOT-REVEAL-NOTICE-001
targetShaAtStart: <sha>
resultHeadSha: <sha>
resultStatus: IMPLEMENTED_PENDING_CHATGPT_VERIFICATION
projectionAuthority: <summary>
stateMachine: <summary>
advantageDisadvantage: <summary>
naturalCriticalPresentation: <summary>
reducedMotion: <summary>
queueStackReconciliation: <summary>
disclosure: <summary>
focusedRegressions: <summary>
validatorCoverage: <summary>
currentHeadActions: <summary>
acceptanceMatrixState: <summary>
studioRuntimeState: NOT_EXECUTED
humanUiUxState: NOT_EXECUTED
```

불완전하면 `BLOCKED` 또는 `PARTIAL`로 기록하고 미해결 항목을 명시한다.
