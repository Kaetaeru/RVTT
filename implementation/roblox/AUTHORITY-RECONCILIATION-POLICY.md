# RVTT Authority Reconciliation Policy

- 상태: `ACTIVE · ACCEPTANCE_PROMOTION_GATE`
- 최종 갱신일: 2026-08-13
- 적용 범위: 사용자-visible Checkpoint 최종 수용 뒤 현재 Authority·Architecture Coverage·Execution Layer·Code Contract·Source·Test를 정합화하는 절차

## 1. 핵심 원칙

보이지 않는 Engine/Integration은 자동 테스트로 검증하고, 사용자는 Presentation/Feel을 판단한다.

사용자가 visible behavior를 반복 수정하는 동안 Product/ADR/Architecture를 매번 고치지 않는다.

최종 수용 후에는 다음 기능 전에 Authority Reconciliation을 수행한다.

```text
READY_FOR_USER
→ 사용자 수정 반복
→ 사용자 최종 수용
→ AUTHORITY_RECONCILIATION
→ Architecture Coverage Capability / Scenario / Gap
→ Execution/System/Module/Stable Function Contract
→ Source/Test
→ Promotion Commit
→ ACCEPTED
```

## 2. 사용자 수용 범위

사용자가 UI/조작감을 수용한 것은 그 visible behavior의 승인이다.

자동으로 승인되지 않는 것:

- Server/Client Authority 이동
- state owner 변경
- Module split/merge
- System flow 변경
- Execution Class 변경이 Architecture 의미를 바꾸는 경우
- 새로운 Runtime Engine boundary
- Coverage Gap을 해소하기 위한 새 공통 Architecture 경계

이런 변경이 필요하면 사용자에게 먼저 제안한다.

## 3. Authority Impact Scan

확인 순서:

```text
1. 사용자의 최신 확정 결정
2. Accepted ADR
3. Product / Architecture / System / Global UI Policy
4. Implementation Spec
5. ARCHITECTURE-COVERAGE-POLICY / architecture-coverage.json
6. GREENFIELD-EXECUTION-LAYERS / execution-layers.json
7. GREENFIELD-SYSTEM-SEQUENCE / GREENFIELD-BUILD-POLICY
8. System Contract / system-function-contracts.json
9. Module Contract / module-contracts.json
10. Stable Function Contract
11. CURRENT-WORK-ORDER / CODEX-ACTIVE-TASK / current command
12. greenfield/src
13. greenfield/tests
14. 현재 Guide
```

변경된 behavior뿐 아니라:

- Product Capability 의미
- Representative Scenario 단계
- cross-cutting Authority/Permission/Projection/Persistence/Concurrency/Security/Test 판단
- Known Gap 상태
- Authority Corpus Tree Snapshot
- Execution Class
- authority owner
- System flow
- Module responsibility
- Stable Function 의미

까지 검색한다.

## 4. Top-down Reconciliation

```text
User Decision
→ ADR / Product / Architecture / System / UI
→ Implementation Spec
→ Architecture Coverage
→ Execution Layer / System Sequence / Build Policy
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Active Task / Work Order
→ Source
→ Tests
→ Guide
```

하위 Source에 맞추기 위해 상위 Product 의미를 임의로 바꾸지 않는다.

## 5. Architecture Coverage Reconciliation

사용자 확정 또는 상위 Authority 변경이 있으면 Coverage를 다시 확인한다.

### Capability

- 확정된 behavior가 어떤 Product Capability에 속하는가.
- Capability `coverageState`가 실제 System/Module 상태와 맞는가.
- 새 Capability가 생겼는데 Catalog에서 빠지지 않았는가.

### Scenario

- 대표 사용자 흐름의 단계가 실제 Authority/System 경계를 모두 통과하는가.
- 중간 단계에 owner가 없는 상태가 생기지 않았는가.
- negative case가 실제 Test로 연결되는가.

### Cross-cutting

다음을 모두 재검토한다.

```text
AUTHORITY
PERMISSION
STATE_OWNERSHIP
COMMAND
PROJECTION_DISCLOSURE
PERSISTENCE
RECONNECT
ROLLBACK
MULTIPLAYER_CONCURRENCY
FAILURE
OBSERVABILITY
SECURITY
AUTOMATED_TEST
HUMAN_TEST
```

### Gap

- 해결된 Gap은 Evidence와 사용자 결정/새 Contract를 확인한 뒤 `RESOLVED`로 바꾼다.
- 해결되지 않은 Blocking Gap을 단순히 Phase Gate에서 제거하지 않는다.
- 새로운 누락이 발견되면 새 Gap을 기록하고 필요한 Phase를 차단한다.

### Authority Corpus Snapshot

Product/ADR/Architecture/System/UI/Spec Root가 바뀌었으면 Coverage 영향 검토가 끝난 후에만 새 Git Tree SHA를 기록한다.

Tree SHA만 갱신해 CI를 통과시키지 않는다.

## 6. Execution Layer Reconciliation

현재 기능과 관련된 Module의 Execution Class를 확인한다.

```text
CORE_ENGINE
ROBLOX_RUNTIME_ENGINE
ROBLOX_INTEGRATION
PRESENTATION_FEEL
```

최종 Source와 실제 검증 환경이 선언과 맞아야 한다.

예:

- CORE_ENGINE인데 Studio 수동 확인만 있음 → 미완료.
- ROBLOX_RUNTIME_ENGINE인데 Studio automated runtime evidence 없음 → 미완료.
- ROBLOX_INTEGRATION인데 Remote/Player/lifecycle Integration evidence 없음 → 미완료.
- PRESENTATION_FEEL인데 사용자 수용 없음 → 미완료.

## 7. Pathfinding 같은 Runtime Engine

사용자-visible Movement를 수용했다고 Pathfinding 내부 Architecture가 자동 승인되는 것은 아니다.

Pathfinding이 도입됐다면 Reconciliation에서:

- 관련 Navigation/Spatial Coverage Gap이 해결됐는지.
- pure policy/contract가 Repository testable한지.
- Roblox navigation provider/NavMesh/collision/raycast 부분이 Runtime Engine으로 분리됐는지.
- Studio-only Source가 남지 않았는지.
- Studio automated runtime test가 있는지.
- visible movement feel만 Human Acceptance 대상으로 남았는지.

확인한다.

## 8. Historical Evidence

과거 Codex Command, Audit, Acceptance Result, Runtime Log, 종료된 Review는 당시 Evidence다. 새 결정에 맞게 과거 내용을 다시 쓰지 않는다.

현재 Authority 역할이 끝난 문서는 `SUPERSEDED`/`ARCHIVED` 처리하고 새 Authority를 가리킨다.

## 9. Canonicalization Gate

Promotion Commit 전 필수:

1. accepted behavior 기록.
2. Authority Impact Scan 완료.
3. 상위 Authority 충돌 해결.
4. 관련 Architecture Coverage Capability/Scenario/Gap 정합화.
5. Authority Corpus Snapshot이 현재 Authority와 일치.
6. 현재/다음 Checkpoint 관련 OPEN Blocking Gap 없음.
7. `validate_architecture_coverage.py` PASS.
8. Execution Layer 정합화.
9. System Contract 정합화.
10. Module Contract 정합화.
11. Stable Function Contract 정합화.
12. `validate_module_contracts.py` PASS.
13. `validate_execution_layers.py` PASS.
14. 최종 Source가 `greenfield/src`에 존재.
15. `greenfield.project.json` 재현 가능.
16. 해당 Execution Class의 automated test gate PASS.
17. Presentation/Feel이면 사용자 수용 확인.
18. 남은 current conflict 없음.
19. 미승인 Architecture 변경 없음.

하나라도 미완료면 Promotion Commit/`ACCEPTED` 금지.

## 10. Promotion Commit

```text
checkpoint(<CHECKPOINT_ID>): accept <short behavior summary>
```

최소 Trailer:

```text
RVTT-Checkpoint: S1_SELECTION
RVTT-User-Acceptance: CONFIRMED
RVTT-Authority-Reconciliation: COMPLETE
RVTT-Unresolved-Conflicts: NONE
```

Promotion Commit에는 관련 Authority, Coverage, Execution/System/Module/Function Contract, Canonical Source, Tests를 함께 묶는다.

다음 기능이나 미확정 실험은 섞지 않는다.

## 11. Report

```text
ACCEPTED BEHAVIOR
COVERAGE UPDATED
COVERAGE GAPS
ENGINE TESTED
RUNTIME INTEGRATION TESTED
HUMAN ACCEPTED
AUTHORITY UPDATED
EXECUTION/CONTRACT UPDATED
CANONICALIZED
PROMOTION COMMIT
UNRESOLVED CONFLICTS
```

해당 항목이 적용되지 않으면 `N/A`로 명시한다.

`COVERAGE GAPS`에 현재/다음 Checkpoint를 막는 OPEN Gap이 있거나 `UNRESOLVED CONFLICTS`가 남아 있으면 `ACCEPTED` 처리하지 않는다.
