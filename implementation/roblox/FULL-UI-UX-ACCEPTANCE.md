# RVTT Full UI·UX Acceptance Contract

- 상태: `PHASE_10_PARTIAL_HOLD`
- Matrix: [`full-ui-ux-acceptance-matrix.json`](full-ui-ux-acceptance-matrix.json)
- Validator: [`tooling/validate_full_ui_ux_acceptance.py`](tooling/validate_full_ui_ux_acceptance.py)
- Matrix authority snapshot: `82dc4a1071a7147b0f2066f6246eff34259161ee`
- Runtime evidence: `NOT_EXECUTED`
- Human UI·Accessibility evidence: `NOT_EXECUTED`

## 판정

Phase 10은 49개 stable Acceptance 항목, 12개 실행 Batch 연결, 증거 상태 불변식과 drift validator를 등록했다. 현재 `STATIC_VERIFIED` 항목은 45개이며, 이는 Source·정적 계약만 확인했다는 뜻이다. Studio 또는 Human PASS가 아니다.

ADR-0091 Final Contract 중 Developer Asset Registry, Rules Profile/Release Leak Gate, Core Rules Reader, Official 2024 Interactive Character Sheet가 Production Source와 focused regression으로 `STATIC_VERIFIED`다. Dice Slot Reveal Notice 1개가 남아 있으므로 Phase 10은 `DONE`이 아니라 `PARTIAL / HOLD`다. 다음 focused correction은 Dice Slot Reveal Notice다.

## 증거 분류

| Evidence class | 연결 항목 수 | 현재 판정 |
|---|---:|---|
| `STATIC` | 46 | 45개 `STATIC_VERIFIED`, 1개 final gap의 정적 등록만 확인 |
| `STUDIO_SINGLE_CLIENT` | 21 | `NOT_EXECUTED` · G1 |
| `STUDIO_MULTI_CLIENT` | 17 | `NOT_EXECUTED` · G2 |
| `REAL_TRANSPORT` | 3 | `NOT_EXECUTED` · G3 |
| `HUMAN_UI_UX` | 4 | `NOT_EXECUTED` · Human evidence |
| `HUMAN_ACCESSIBILITY` | 4 | `NOT_EXECUTED` · Human evidence |
| `PERSISTENCE_DEFERRED` | 1 | `DEFERRED` · P1–P7 |
| `PERFORMANCE_DEFERRED` | 1 | `DEFERRED` |
| `CONTENT_DEFERRED` | 2 | `BLOCKED` final-contract gaps |

Matrix item 상태 합계는 `STATIC_VERIFIED=45`, `NOT_EXECUTED=1`, `DEFERRED=2`, `BLOCKED=1`다.

## Runtime Batch 연결

- `G1`: `unit-integration-baseline`, `slice01-world-interaction`
- `G2`: `multi-client-authority`
- `G3`: `real-transport-reconnect`
- `HUMAN`: `ui-visual-accessibility`
- `P1–P7`: 기존 Grand Persistence phase를 순서 그대로 유지
- `PERFORMANCE`: `performance-soak-capacity`

이 문서는 Batch를 실행하지 않는다. Studio, Studio MCP, Roblox Human Playtest는 모두 실행하지 않았다.

## Accepted stale-contract correction

Player와 Observer의 상시 UI에서 다음은 required Acceptance가 아니라 금지된 persistent surface다.

```text
Minimap
separate Player Map
Objective Tracker
```

DM Scene·World authoring 도구, Journal의 문서·Anchor navigation, 공개 World Link와 Ping 계약은 유지한다. Matrix validator는 위 세 Player surface를 required 항목으로 다시 등록하거나 Player runtime source에 재도입하면 실패한다.

## ADR-0091 Final Contract Static Evidence

### Developer Asset Registry

```text
content-source/packages/rvtt.core.baseline/package.manifest.json
→ ServerStorage/RVTT/Content/Packs/rvtt.core.baseline
→ ReplicatedStorage/RVTT/ContentRuntime/AssetCatalog.lua
```

Production asset set은 승인된 실제 에셋이 없으므로 비어 있다. `AssetRegistryValidator.lua`, `ClientAssetViewBuilder.lua`, `AssetRegistry.spec.lua`, `validate_asset_registry.py`가 Stable ID·kind metadata·dependency·executable payload·source identity와 private/non-exportable negative disclosure를 고정한다.

### Rules Profile / Release Leak Gate

`BuiltinPackIndex.lua`를 유일한 package metadata authority로 사용하며 `RulePackageResolver.lua`, `ReleaseContentLeakGate.lua`, `RuleProfileStatus.lua`와 focused Luau spec으로 정적 해제했다. `build_public_release_staging.py`가 현재 public-safe source에서 실제 filesystem staging을 만들고, `validate_rules_profile_release_gate.py`가 staged file을 deterministic inventory로 검사하며 GitHub Actions가 실패를 nonzero로 전파한다. Private profile은 exact readiness와 명시적 SRD fallback을 요구하고 public/release/artifact는 SRD-only 및 client-safe allowlist를 유지한다.

### Core Rules Reader

Core Rules Reader는 다음 경계로 정적 해제했다.

```text
RuleContentPackage
→ server-only RuleReaderPackage / imported private package boundary
→ RuleReaderService viewer filtering
→ RuleReaderQuery manifest/search/open/chunk
→ Shared RuleReaderClient lazy cache
→ Journal Core Rules 3-column reader
```

핵심 정적 증거:

- `rvtt-rule://<packageId>/<moduleId>/<documentId>#<anchorId>` stable link build/parse
- manifest는 Rule body나 chunk graph를 복제하지 않음
- `open`은 현재 Section의 첫 semantic chunk만 반환
- adjacent chunk는 명시적인 `chunk` 요청으로만 lazy load
- 20만 자 초과 synthetic corpus에서도 초기 manifest가 body를 포함하지 않음
- viewer가 권한 없는 Module/Document는 title·count·snippet·related link·backlink·body가 모두 미노출
- unauthorized open/chunk는 `RULE_LINK_UNAVAILABLE` / `RULE_CHUNK_UNAVAILABLE`의 nondisclosing failure
- Session authoritative membership role 변경이 `RVTT_Role` server-owned marker로 동기화되어 reader filter에 전달됨
- UI component는 Remote를 직접 호출하지 않고 Shared reader adapter를 사용
- public repository에는 private 한국어 규칙 본문을 추가하지 않음
- Studio `development` profile은 private readiness가 없으면 fail closed하며 implicit SRD fallback을 사용하지 않음

Private integrated positive-path repair의 추가 Static/Build 증거:

```text
BuiltinPackIndex pinned revision + integrated source-tree digest + expected counts
→ build_private_rules_runtime.py
→ revision / subtree digest / 12·48·16·10·75·391 count / dirty-source fail closed
→ temporary RuleContentPackage + semantic chunks + localized search index
→ prepare_private_rules_runtime.py explicit server-only authorizedUserIds
→ temporary RVTTPrivateRuleContent/Readiness + RuleReaderPackage JSON Modules
→ generated Rojo project overlay
→ RuleRuntimePackageBinding
→ RuleReaderBoot profileAccessResolver
→ RuleReaderQuery nondisclosing owner-only access gate
```

- private integrated source subtree digest는 `BuiltinPackIndex.lua`에서 package authority와 함께 pin한다.
- importer output은 RVTT public Git working tree 내부를 거부하고 OS temporary workspace에만 생성한다.
- `run-private-rules-studio.ps1`은 `RVTT_PRIVATE_DND2024_KO_SOURCE`와 `RVTT_PRIVATE_RULES_AUTHORIZED_USER_IDS`가 모두 없으면 fail closed하며 base project를 직접 build하지 않고 generated private overlay project만 Rojo build한다.
- public GitHub Actions는 private repository나 private rule body를 checkout하지 않는다.
- `validate_private_rules_runtime_pipeline.py`는 공개-safe synthetic Git source를 만들어 동일 importer/preparer를 실행하고 generated `.rbxlx`에 `RVTTPrivateRuleContent`, `Readiness`, `RuleReaderPackage` ModuleScript binding이 실제 포함되는지 확인한다.
- synthetic pipeline은 in-root document·README·same/cross-document fragment와 duplicate heading anchor를 stable `rvtt-rule://` URI로 정규화하고, 모든 `relatedLinks`가 실제 generated target의 first chunk에 정확히 하나의 reciprocal backlink를 만드는지 검증한다.
- missing local target, sourceRoot escape와 invalid `rvtt-rule://` 입력은 human label만 plain text로 보존하며 raw `.md` path나 related/backlink를 runtime package에 남기지 않는다. 명시적 external URL은 일반 Markdown으로만 보존한다.
- 같은 synthetic source를 두 번 import한 `RuleReaderPackage.json` byte output이 일치하고 모든 related/backlink URI가 generated catalog에서 resolve되며 각 chunk가 UTF-8 16KB 이하인지 확인한다.
- synthetic pipeline은 wrong revision, wrong source-tree digest, wrong content count, dirty source, missing source, missing viewer allowlist를 각각 fail-closed regression으로 계속 검증한다.
- private profile에서 allowlist에 없는 UserId는 RuleReader service에 도달하기 전에 `RULE_PROFILE_UNAVAILABLE`만 받고 manifest/search/open/chunk body를 얻지 못하도록 focused regression과 static validator에 연결한다.

현재 repository의 `rvtt.core.rules` Reader package에는 구조 검증용 공개-safe Reader Guide만 들어 있다. 전체 SRD corpus 또는 private 한국어 integrated corpus의 실제 content population/runtime evidence를 이 Static PASS로 확대하지 않는다. 특히 public CI의 synthetic importer/overlay PASS는 **실제 private corpus Studio Runtime PASS가 아니다**.

### Official 2024 Interactive Character Sheet

`CharacterSheetProjection.lua`는 owner/authorized DM만 전체 Character·Inventory·Rules authoritative state를 같은 revision으로 투영하고 Observer와 unrelated player에는 식별자·private field를 공개하지 않는다. Sheet roll payload는 `actorId + rollKind + sourceId`만 전달하고 서버가 ability/proficiency/mode/damage/eligibility를 active Content pack으로 수화된 Character state와 canonical `ActorProfileResolver` attack catalog에서 해석한다. Item capability도 active server-owned definition에서 `inventory.create_item` 시 snapshot된다. `OfficialCharacterSheet.lua`와 `CharacterSheetLayout.lua`는 8.5:11 Page 1/2, 정확한 Header/Left/Right 정보 구조, Wide/Reference spread, Compact page tab을 유지하며 모든 Equipment row, local details, authorized target send와 structured spell slots를 제공한다. focused real-command regression과 validator가 forged semantics, unauthorized actor, invalid attack, HP>0 death save, revision/permission/epoch 및 out-of-order terminal receipt 안전성을 정적으로 확인한다. Studio/Human 실행은 하지 않았다.

## 남은 ADR-0091 Final Contract Gap

1. Dice Slot Reveal Notice state machine

이 항목은 문서 존재나 matrix 등록으로 PASS 처리하지 않는다. Matrix의 실제 `BLOCKED` subset인 `finalContractGaps`가 후속 focused implementation correction의 입력이다.

## Validator 불변식

Validator는 최소 다음을 거부한다.

- duplicate Acceptance ID
- unknown Evidence class
- 존재하지 않는 Authority 또는 Automated reference
- 증거가 없는 PASS
- 실행하지 않은 Runtime·Human PASS
- reason 없는 Blocked·Deferred 항목
- Manifest에 없는 Runtime phase
- 필수 Role·Recovery·Negative Disclosure·DM reconciliation 항목 누락
- Asset Registry Production/focused evidence 없는 해제
- Rules Profile/Release Leak Gate Production/focused evidence 없는 해제
- Core Rules Reader lazy-load/nondisclosure evidence 없는 해제
- private importer/overlay/owner-access positive path 누락 또는 base-project bypass
- Session role→Reader permission marker wiring 누락
- 남은 ADR-0091 Dice Notice gap 누락 또는 거짓 해제
- Player persistent Minimap·별도 Map·Objective Tracker 재등록과 Source 재도입

Validator 자체는 위 실패 유형의 negative fixture를 매 실행마다 확인한다.
