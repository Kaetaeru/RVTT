# RVTT Agent Rules

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-13

## 1. 현재 실행 권위

```text
사용자의 최신 명시적 지시
→ .github/CODEX-ACTIVE-TASK.md
→ commandPath
```

Archive, 과거 Codex Command, PR 댓글, 과거 Acceptance에서 현재 TODO를 복구하지 않는다.

## 2. 현재 Build 방식

현재 Roblox 구현은 다음 방식이다.

```text
Product / ADR
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ E0 Repository Core Engine
→ E1 Roblox Runtime Integration
→ E2 Presentation / Feel
→ Human feedback
→ Authority Reconciliation
→ Promotion Commit
```

Execution environment authority는 `implementation/roblox/GREENFIELD-EXECUTION-LAYERS.md`와 `implementation/roblox/manifests/execution-layers.json`이다.

## 3. Execution Class

### CORE_ENGINE

Roblox Runtime 없이 correctness를 검증할 수 있는 보이지 않는 Engine.

- GitHub `greenfield/src`에서 먼저 구현.
- repository automated/negative tests를 먼저 통과.
- 사람에게 Studio Console로 함수 하나씩 검증시키지 않는다.

### ROBLOX_RUNTIME_ENGINE

Roblox Runtime 결과가 Engine correctness의 일부.

- Studio/MCP에서 구현·튜닝 loop 허용.
- 최종 Source는 반드시 `greenfield/src`에 canonicalize.
- Studio automated runtime test 필요.

대표: PathfindingService, raycast, physics/collision, streaming-sensitive behavior, DataStore adapter.

### ROBLOX_INTEGRATION

Core Engine을 Remote/Player/Input/Instance/lifecycle에 연결.

- Studio/MCP automated integration test가 1차 검증.
- 사용자 UX 판단을 요구하지 않는다.

### PRESENTATION_FEEL

사람이 보고 만져야 평가 가능한 UI/visual/control feel.

- Studio self-check 후 `READY_FOR_USER`.
- 사용자가 싫으면 같은 Checkpoint에서 즉시 수정.

## 4. Source 권위

- `implementation/roblox/greenfield/src`: Canonical Source.
- `implementation/roblox/greenfield/tests`: Greenfield tests.
- `implementation/roblox/greenfield.project.json`: Greenfield Rojo Project.
- `implementation/roblox/src`: Legacy read-only reference.
- `implementation/roblox/default.project.json`: Legacy read-only project.

Studio-only production truth는 금지한다.

## 5. Code Contract

Source보다 먼저:

```text
System
→ Module
→ Stable Function
→ Execution Class
```

다른 Contract-bearing Module이 호출하는 함수는 Stable Function Contract가 먼저 있어야 한다.

private/local helper와 정확한 내부 call graph는 Source-derived다.

## 6. 현재 Engine-first 범위

현재 Foundation + Exploration에서 보이지 않는 Engine은 사용자 UI보다 먼저 완성한다.

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

이들은 Repository에서 자동 테스트한다.

그 뒤 Studio Integration:

```text
CommandGateway / CommandClient
ProjectionGateway / ProjectionReplica
SemanticInputRouter / WorldSystem
ServerApp / Bootstrap
ClientApp / Bootstrap
```

그 다음 사용자 Checkpoint:

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

## 7. Pathfinding 규칙

Pathfinding은 통째로 Studio-only Engine으로 만들지 않는다.

```text
Repository
= data contract / permission / budget / failure / recompute / pure policy

Studio Runtime
= PathfindingService / NavMesh / Agent / Collision / Raycast / dynamic obstruction

Human
= preview readability / click response / movement smoothness
```

구체 Pathfinding Module split/API는 Movement Checkpoint 직전에 사용자에게 제안·확정한다.

## 8. 사용자 Feedback

`READY_FOR_USER`가 되면 다음 Presentation 기능 진행을 멈춘다.

```text
CHANGE_REQUESTED
→ 현재 Checkpoint 수정
→ Studio self-check
→ READY_FOR_USER
→ 사용자 재확인
```

Engine unit/negative test와 Studio automated integration은 사람이 직접 판정하지 않는다.

## 9. 사용자 확정 후

```text
사용자 최종 수용
→ Authority Impact Scan
→ Product / ADR / Architecture / Spec
→ Execution / System / Module / Stable Function Contract
→ Canonical Source / Tests
→ conflict re-scan
→ Promotion Commit
→ ACCEPTED
```

Promotion Commit 형식:

```text
checkpoint(<CHECKPOINT_ID>): accept <summary>
```

## 10. 사용자 승인 없이 바꾸지 않는 것

- Product 목표/비목표
- Accepted ADR
- 핵심 입력 문법
- Server/Client Authority / Data ownership
- Module responsibility 실질 분리/통합
- System flow
- Execution Class 정책/개발 방식
- Foundation/Checkpoint 순서
- Release scope/priority
- Legacy write lock

명백한 bug, 기존 intent 안의 UX 미세 조정, private helper 분해는 즉시 수행 가능하다.

## 11. 고정 제품 경계

- RVTT는 Roblox에서 DM이 실시간 진행하는 게임형 D&D VTT다.
- 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`다.
- 초기 입력은 PC keyboard/mouse다.
- Token은 rigless OBJ/MeshPart 기반 3D Token이다.
- 권위 이동은 연속 무격자 좌표이며 `5 ft = 4 studs`다.
- Exploration은 목적지 Click + Token WASD, Encounter는 Token WASD 직접 이동 없음.
- Left Click=Primary, Right Click=Context, Middle Drag=Camera Orbit, Q=한 단계 취소, E=확정, ESC=Gameplay 의미 없음.
- 중요한 rule/permission/roll/confirmed movement/persistent state는 Server authoritative다.
- Character Owner / Runtime Controller / Session Role은 분리한다.
- Private Rule Content와 Public Release Content는 분리한다.
- 공식 Stat Block/CR은 시스템이 자동 재조정하지 않는다.

## 12. Evidence

```text
Repository Engine Test
≠ Studio Runtime Integration Test
≠ Human Presentation/Feel Acceptance
≠ Multi-client
≠ Persistence
≠ Performance
≠ Release Acceptance
```
