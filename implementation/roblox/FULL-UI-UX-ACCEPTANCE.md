# RVTT Full UI·UX Acceptance Contract

- 상태: `PHASE_10_PARTIAL_HOLD`
- Matrix: [`full-ui-ux-acceptance-matrix.json`](full-ui-ux-acceptance-matrix.json)
- Validator: [`tooling/validate_full_ui_ux_acceptance.py`](tooling/validate_full_ui_ux_acceptance.py)
- Authority snapshot: `899292844d58b4c691dffbf2ff9ce84de4104005`
- Runtime evidence: `NOT_EXECUTED`
- Human UI·Accessibility evidence: `NOT_EXECUTED`

## 판정

Phase 10은 49개 stable Acceptance 항목, 12개 실행 Batch 연결, 증거 상태 불변식과 drift validator를 등록했다. 현재 Source와 기존 자동 회귀 근거가 있는 43개 항목은 `STATIC_VERIFIED`다. 이는 Source·정적 계약만 확인했다는 뜻이며 Studio 또는 Human PASS가 아니다.

ADR-0091 Final Contract 중 Developer Asset Registry와 Rules Profile/Release Leak Gate는 Production Source와 focused regression으로 `STATIC_VERIFIED`다. 나머지 필수 구현 3개가 없으므로 Phase 10은 `DONE`이 아니라 `PARTIAL / HOLD`다. 다음 Gate는 Core Rules Reader focused correction이다.

## 증거 분류

| Evidence class | 연결 항목 수 | 현재 판정 |
|---|---:|---|
| `STATIC` | 46 | 43개 Source/Test mapping verified, 3개 gap registration verified |
| `STUDIO_SINGLE_CLIENT` | 21 | `NOT_EXECUTED` · G1 |
| `STUDIO_MULTI_CLIENT` | 17 | `NOT_EXECUTED` · G2 |
| `REAL_TRANSPORT` | 3 | `NOT_EXECUTED` · G3 |
| `HUMAN_UI_UX` | 4 | `NOT_EXECUTED` · Human evidence |
| `HUMAN_ACCESSIBILITY` | 4 | `NOT_EXECUTED` · Human evidence |
| `PERSISTENCE_DEFERRED` | 1 | `DEFERRED` · P1–P7 |
| `PERFORMANCE_DEFERRED` | 1 | `DEFERRED` |
| `CONTENT_DEFERRED` | 3 | `BLOCKED` final-contract gaps |

Matrix item 상태 합계는 `STATIC_VERIFIED=43`, `NOT_EXECUTED=1`, `DEFERRED=2`, `BLOCKED=3`다.

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

Developer Asset Registry는 다음 실제 경계와 검증으로 정적 해제했다.

```text
content-source/packages/rvtt.core.baseline/package.manifest.json
→ ServerStorage/RVTT/Content/Packs/rvtt.core.baseline
→ ReplicatedStorage/RVTT/ContentRuntime/AssetCatalog.lua
```

Production asset set은 승인된 실제 에셋이 없으므로 비어 있다. `AssetRegistryValidator.lua`, `ClientAssetViewBuilder.lua`, `AssetRegistry.spec.lua`, `validate_asset_registry.py`가 Stable ID·kind metadata·dependency·executable payload·source identity와 private/non-exportable negative disclosure를 고정한다.

Rules Profile/Release Leak Gate는 `BuiltinPackIndex.lua`를 유일한 package authority로 사용하며 `RulePackageResolver.lua`, `ReleaseContentLeakGate.lua`, `RuleProfileStatus.lua`와 두 focused Luau spec, `validate_rules_profile_release_gate.py`로 정적 해제했다. Private profile은 exact binding/revision/root/count readiness와 명시적 SRD fallback을 요구하고, public/release/artifact는 SRD-only이며 실제 output inventory leak gate와 client-safe allowlist를 통과해야 한다.

아래 나머지 필수 subsystem과 focused enforcement regression은 발견되지 않았다.

1. Official 2024 Interactive Character Sheet와 Inventory revision parity
2. Dice Slot Reveal Notice state machine
3. Core Rules Reader의 chunk·anchor·permission filtering

이 항목은 문서 존재나 matrix 등록으로 PASS 처리하지 않는다. Matrix의 실제 `BLOCKED` subset인 `finalContractGaps`가 후속 focused implementation correction의 입력이다.

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
- Asset Registry Production/focused evidence 없는 해제
- Rules Profile/Release Leak Gate Production/focused evidence 없는 해제
- 남은 ADR-0091 gap 누락 또는 거짓 해제
- Player persistent Minimap·별도 Map·Objective Tracker 재등록과 Source 재도입

Validator 자체는 위 실패 유형의 negative fixture를 매 실행마다 확인한다.
