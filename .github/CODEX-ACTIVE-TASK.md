# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `READY_FOR_E0_REPOSITORY_ENGINE`
- commandId: `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `HYBRID_ENGINE_INTEGRATION_PRESENTATION`
- buildMode: `GREENFIELD_ARCHITECTURE_FIRST`
- executionAuthorityDoc: `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
- executionRegistry: `implementation/roblox/manifests/execution-layers.json`
- preflightAuthority: `implementation/roblox/GREENFIELD-PREFLIGHT.md`
- canonicalSourceRoot: `implementation/roblox/greenfield/src`
- canonicalTestRoot: `implementation/roblox/greenfield/tests`
- greenfieldProject: `implementation/roblox/greenfield.project.json`
- sequenceAuthority: `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
- moduleContractRegistry: `implementation/roblox/manifests/module-contracts.json`
- systemFunctionContractRegistry: `implementation/roblox/manifests/system-function-contracts.json`
- acceptancePromotionGate: `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
- feedbackMode: `TIGHT_USER_FEEDBACK_LOOP`
- legacySourcePolicy: `READ_ONLY_REFERENCE_LOCKED`
- legacyPlacePolicy: `DO_NOT_USE_AS_BASELINE`
- commandPath: `.github/CODEX-STUDIO-GREENFIELD-FOUNDATION-EXPLORATION-001.md`
- targetMode: `CURRENT_PR_HEAD_AT_START`
- updatedAt: `2026-08-13`

## 현재 Handoff

현재 첫 구현 대상은 Studio UI가 아니라 **E0 Repository Core Engine**이다.

```text
Contracts + Execution Class
→ E0 Repository Core Engine
→ E1 Studio Runtime Integration
→ E2 Presentation / Feel
```

## 다음 실행의 첫 행동

1. `AGENTS.md`와 이 파일을 읽는다.
2. `GREENFIELD-EXECUTION-LAYERS.md`와 `execution-layers.json`을 읽는다.
3. Module/System/Stable Function Contract를 읽는다.
4. E0 Repository Gate를 실행한다.
5. PASS하면 Core Engine을 `greenfield/src`에 구현한다.
6. `greenfield/tests`에 repository automated/negative tests를 추가한다.
7. Core Engine test가 통과하기 전 Studio UI/Feel 구현을 시작하지 않는다.

**Studio/MCP Handshake는 E0 시작 전 필수가 아니다.** E1 Runtime Integration 직전에 수행한다.

## E0 Repository Core Engine

현재 먼저 완성할 보이지 않는 Engine:

```text
CommandEnvelope
ProjectionEnvelope
WorldContract
SessionAuthority
WorldState
AuthorizationService
CommandRuntime
ProjectionService
MovementDomain
ExplorationDomain
```

검증 예:

- malformed envelope
- unauthorized command
- duplicate commandId
- stale expected revision
- `WorldState.transact` success/failure revision semantics
- viewer-safe projection/disclosure
- movement domain validation
- exploration domain validation
- structured failures

순수 Engine 함수를 사용자에게 Console로 수동 테스트시키지 않는다.

## E1 Roblox Runtime Integration

E0가 준비된 뒤 Studio Gate를 실행하고 다음을 연결한다.

```text
CommandGateway / CommandClient
ProjectionGateway / ProjectionReplica
SemanticInputRouter / WorldSystem
ServerApp / ServerBootstrap
ClientApp / ClientBootstrap
```

Codex/MCP가 Remote/Player/Instance/Input/lifecycle를 자동 통합 테스트한다.

사용자 UI 판단은 요구하지 않는다.

## Runtime-coupled Engine 예외

PathfindingService, raycast, physics/collision처럼 실제 Roblox Runtime이 correctness의 일부면 `ROBLOX_RUNTIME_ENGINE`으로 다룬다.

```text
Contract / pure policy → GitHub
actual Roblox service behavior → Studio/MCP automated runtime test
visible preview / response / feel → Human checkpoint
```

Studio에서 구현·튜닝해도 최종 Source는 반드시 `greenfield/src`에 canonicalize한다.

구체 Pathfinding Module split/API는 M1 Movement 설계 직전에 사용자에게 제안·확정한다.

## E2 Presentation / Feel

```text
S1_SELECTION
→ C1_CAMERA
→ M1_MOVE
→ X1_CONTEXT
→ I1_INTERACTION
```

Presentation Module을 연결하고 Studio self-check가 끝난 뒤에만 `READY_FOR_USER`다.

사용자가 수정 요청하면 같은 Checkpoint에서 즉시 수정한다.

## 구현 전 Code Contract Gate

```text
System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Validator
→ Source
```

- undeclared cross-module call 금지.
- private helper는 자유.
- Execution Class 변경이 Authority/state owner/Module responsibility/System flow를 바꾸면 사용자에게 먼저 제안.

## 사용자 확정 처리

```text
사용자 최종 수용
→ Authority Impact Scan
→ Product / ADR / Architecture / Spec
→ Execution / System / Module / Stable Function Contract
→ Canonical Source / Tests
→ conflict re-scan
→ Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

## 스캔 순서

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`
4. `implementation/roblox/manifests/execution-layers.json`
5. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
6. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
7. `implementation/roblox/MODULE-CONTRACTS.md`
8. `implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`
9. `implementation/roblox/manifests/module-contracts.json`
10. `implementation/roblox/manifests/system-function-contracts.json`
11. 현재 `commandPath`
12. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
13. 관련 Product/ADR/Spec
14. Legacy Source는 필요한 경우 읽기 참고만

## 지금 하지 않는 것

- Studio Handshake를 기다리느라 E0 Core Engine 구현을 미루기
- pure Engine을 Studio Console 수동 테스트만으로 완료 처리
- E0 Engine test 전 Presentation 구현
- undeclared cross-module function 추가
- 미래 P2~P10 미확정 Domain/API 선행 구현
- Legacy Source/Project 수정
- 기존 Production Place를 Baseline으로 사용
- user-visible Checkpoint skip
- Authority Reconciliation 없이 다음 Checkpoint 진행
- ready-for-review / merge / force push

더 좋은 Architecture/Execution Class/Authority 방향이 보이면 자동 적용하지 말고 사용자에게 먼저 제안한다.
