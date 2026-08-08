# RVTT Full UI·UX Acceptance Contract

- 상태: `PHASE_10_PARTIAL_HOLD`
- Matrix: [`full-ui-ux-acceptance-matrix.json`](full-ui-ux-acceptance-matrix.json)
- Validator: [`tooling/validate_full_ui_ux_acceptance.py`](tooling/validate_full_ui_ux_acceptance.py)
- Authority snapshot: `e20853c3bc1e36fb78a1888809e13a8c8577ebb0`
- Runtime evidence: `NOT_EXECUTED`
- Human UI·Accessibility evidence: `NOT_EXECUTED`

## 판정

Phase 10은 49개 stable Acceptance 항목, 12개 실행 Batch 연결, 증거 상태 불변식과 drift validator를 등록했다. 현재 Source와 기존 자동 회귀 근거가 있는 41개 항목은 `STATIC_VERIFIED`다. 이는 Source·정적 계약만 확인했다는 뜻이며 Studio 또는 Human PASS가 아니다.

ADR-0091 Final Contract의 필수 구현 5개가 현재 Production Source에 없으므로 Phase 10은 `DONE`이 아니라 `PARTIAL / HOLD`다. 다음 Gate는 new current-HEAD Static Gate가 아니라 focused implementation correction이다.

## 증거 분류

| Evidence class | 연결 항목 수 | 현재 판정 |
|---|---:|---|
| `STATIC` | 46 | 41개 Source/Test mapping verified, 5개 gap registration verified |
| `STUDIO_SINGLE_CLIENT` | 21 | `NOT_EXECUTED` · G1 |
| `STUDIO_MULTI_CLIENT` | 17 | `NOT_EXECUTED` · G2 |
| `REAL_TRANSPORT` | 3 | `NOT_EXECUTED` · G3 |
| `HUMAN_UI_UX` | 4 | `NOT_EXECUTED` · Human evidence |
| `HUMAN_ACCESSIBILITY` | 4 | `NOT_EXECUTED` · Human evidence |
| `PERSISTENCE_DEFERRED` | 1 | `DEFERRED` · P1–P7 |
| `PERFORMANCE_DEFERRED` | 1 | `DEFERRED` |
| `CONTENT_DEFERRED` | 5 | `BLOCKED` final-contract gaps |

Matrix item 상태 합계는 `STATIC_VERIFIED=41`, `NOT_EXECUTED=1`, `DEFERRED=2`, `BLOCKED=5`다.

## Runtime Batch 연결

- `G1`: `unit-integration-baseline`, `slice01-world-interaction`
- `G2`: `multi-client-authority`
- `G3`: `real-transport-reconnect`
- `HUMAN`: `ui-visual-accessibility`
- `P1–P7`: 기존 Grand Persistence phase를 순서 그대로 유지
- `PERFORMANCE`: `performance-soak-capacity`

이 문서는 Batch를 실행하지 않는다. Phase 10 명령에 따라 Studio, Studio MCP, Roblox TestRunner와 Human Playtest는 모두 실행하지 않았다.

## Accepted stale-contract correction

Player와 Observer의 상시 UI에서 다음은 required Acceptance가 아니라 금지된 persistent surface다.

```text
Minimap
separate Player Map
Objective Tracker
```

DM Scene·World authoring 도구, Journal의 문서·Anchor navigation, 공개 World Link와 Ping 계약은 유지한다. Matrix validator는 위 세 Player surface를 required 항목으로 다시 등록하거나 Player runtime source에 재도입하면 실패한다.

## ADR-0091 Final Contract Gap Audit

다음 문자열·구조를 Production Source와 Test에서 조사했다.

```text
AssetRegistry / ContentRuntime
Official Sheet / CharacterSheetProjection
DiceNotice / square_enter / slot_spin
RulePackageResolver / RuleReader
private/public rules profile leak gate
```

현재 Source에서 확인된 것은 `BuiltinPackIndex.lua`의 `rvtt.test.rules.2024.integrated.ko` Package ID뿐이다. 아래 필수 subsystem과 focused enforcement regression은 발견되지 않았다.

1. Developer Asset Registry의 Source·Server·Client-safe 분리와 leak gate
2. Official 2024 Interactive Character Sheet와 Inventory revision parity
3. Dice Slot Reveal Notice state machine
4. Core Rules Reader의 chunk·anchor·permission filtering
5. Private integrated test profile과 public SRD release profile의 fail-closed leak gate

이 항목은 문서 존재나 matrix 등록으로 PASS 처리하지 않는다. Matrix의 `finalContractGaps`와 각 `BLOCKED` 항목이 후속 focused implementation correction의 입력이다.

## Validator 불변식

Validator는 최소 다음을 거부한다.

- duplicate Acceptance ID
- unknown Evidence class
- 존재하지 않는 Authority 또는 Automated reference
- 증거가 없는 PASS
- Phase 10에서 실행하지 않은 Runtime·Human PASS
- reason 없는 Blocked·Deferred 항목
- Manifest에 없는 Runtime phase
- 필수 Role·Recovery·Negative Disclosure·DM reconciliation 항목 누락
- ADR-0091 gap 누락 또는 거짓 해제
- Player persistent Minimap·별도 Map·Objective Tracker 재등록과 Source 재도입

Validator 자체는 위 실패 유형의 negative fixture를 매 실행마다 확인한다.
