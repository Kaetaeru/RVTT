# RVTT Greenfield System Sequence

- 상태: `ACTIVE · BUILD_ORDER_AUTHORITY`
- 최종 갱신일: 2026-08-12
- 적용 범위: 새 `greenfield/` RVTT 구현의 시스템 구축 순서와 기술 안전 경계
- 기계 가독 계약: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

이 문서는 **어떤 시스템을 어떤 순서로 만들지**를 소유한다. 현재 Active Task는 이 순서를 건너뛸 수 없다.

목표는 두 가지를 동시에 만족하는 것이다.

1. 임시 Script가 권위를 가져 나중에 재설계하는 일을 막는다.
2. Architecture만 오래 만들지 않고 가능한 빨리 실제 사용자 기능을 보여준다.

따라서 **의존성이 낮고 보안상 먼저 필요한 경계부터 만들고, Foundation이 Boot되는 즉시 작은 사용자 Checkpoint로 넘어간다.**

## 1. 고정 Foundation 순서

```text
G0_SHARED_CONTRACTS
→ G1_SERVER_AUTHORITY_CORE
→ G2_COMMAND_TRANSPORT
→ G3_PROJECTION_PIPELINE
→ G4_CLIENT_WORLD_SHELL
→ G5_COMPOSITION_BOOT
→ S1_SELECTION
```

이 순서는 현재 RVTT Greenfield의 고정 기본값이다. 변경하려면 단순 구현 최적화가 아니라 개발 Architecture 변경으로 보고 사용자에게 먼저 제안한다.

### G0 — Shared Contracts

먼저 네트워크와 World에서 공유되는 **데이터 모양만** 고정한다.

```text
CommandEnvelope
ProjectionEnvelope
WorldContract
```

Gate:

- Shared Contract는 순수 데이터 계약이며 Roblox Instance, callback, 실행 코드 참조를 포함하지 않는다.
- Stable ID와 enum을 표시 문자열·Instance 이름과 분리한다.
- Command에는 `commandId`, `sessionEpoch`, `expectedWorldRevision`, `commandType`, 제한된 payload를 표현할 수 있어야 한다.
- Client가 보낸 Role, Owner, Controller 주장을 권위 정보로 사용하지 않는다.
- Projection에는 `sessionEpoch`, 단조 증가 revision과 viewer-safe payload 경계를 표현할 수 있어야 한다.
- 숫자·문자열·배열·중첩 깊이는 Validation에서 상한을 둘 수 있게 설계한다.

### G1 — Server Authority Core

네트워크 입력을 받기 **전에** 권위 코어를 만든다.

```text
SessionAuthority
WorldState
AuthorizationService
CommandRuntime
```

Gate:

- Session Role, Character Owner, Runtime Controller는 서버가 소유하고 서로 분리한다.
- `WorldState`만 authoritative world actor state와 world revision을 소유한다.
- `AuthorizationService`는 mutation을 수행하지 않는다.
- `CommandRuntime`은 authorization과 revision 검증이 끝나기 전 handler를 실행하지 않는다.
- mutation command는 `commandId` 중복과 stale `expectedWorldRevision`을 fail closed 처리할 수 있어야 한다.
- Client가 보낸 userId/role/controller 값을 신뢰하지 않는다. Roblox가 제공한 실제 `Player`와 서버 상태를 사용한다.
- 오류는 구조화된 failure로 반환하고 빈 `pcall`로 삼키지 않는다.

### G2 — Command Transport

권위 코어가 존재한 뒤 Remote 경계를 연다.

```text
Server CommandGateway
Client CommandClient
```

Gate:

- `CommandGateway`는 Remote 수신·coarse validation·payload limit·rate limit·runtime 호출만 담당한다.
- Gateway 안에 Gameplay rule, ownership 결정, state mutation을 넣지 않는다.
- UI/Presenter는 Remote를 직접 호출하지 않고 `CommandClient`를 거친다.
- 네트워크를 통해 Roblox Instance를 보내지 않는다. Stable ID와 bounded primitive/table data만 사용한다.
- malformed/oversized/flooded input은 서버에서 fail closed한다.

### G3 — Projection Pipeline

Client가 authoritative state를 직접 읽거나 추정하지 않도록 Projection 경계를 만든다.

```text
WorldState
→ ProjectionService
→ ProjectionGateway
→ ProjectionReplica
```

Gate:

- `ProjectionService`만 viewer별 공개 가능 데이터를 선택한다.
- 숨은 Actor, private Rule/DM state, 권한 없는 object 존재 정보가 Projection에 섞이지 않는다.
- `ProjectionGateway`는 이미 안전하게 만들어진 Projection을 전달만 한다.
- `ProjectionReplica`는 서버가 보낸 state의 replica이며 authoritative mutation을 만들지 않는다.
- epoch/revision이 뒤로 가는 Projection은 적용하지 않는다.
- Viewer 변경·reconnect 시 full resync가 가능한 계약을 유지한다.

### G4 — Client World Shell

Server/Projection 경계가 준비된 뒤 Client 입력과 World 조립기를 만든다.

```text
SemanticInputRouter
WorldSystem
```

Gate:

- 물리 입력은 Semantic Action으로 바뀐 뒤 Controller에 전달한다.
- Controller는 `UserInputService`를 제각각 직접 구독해 서로 경쟁하지 않는다.
- WorldSystem은 lifecycle/composition을 소유하고 Selection·Camera·Move 규칙 자체를 소유하지 않는다.
- 모든 connection/task/temporary Instance는 `destroy()`에서 정리할 수 있어야 한다.

### G5 — Composition + Boot

구성 요소를 마지막에 App과 Bootstrap으로 조립한다.

```text
ServerBootstrap → ServerApp
ClientBootstrap → ClientApp
```

Gate:

- Bootstrap은 `require/create → start → fatal boot report`만 담당한다.
- App은 dependency wiring과 lifecycle만 담당한다.
- Bootstrap/App에 Selection, Camera, Move, Authorization, Projection 계산을 넣지 않는다.
- `start()`/`destroy()` lifecycle이 중복 호출과 부분 실패에서 상태를 망가뜨리지 않도록 설계한다.
- Client는 Server readiness/initial projection을 명시적으로 기다리고 무한 대기하지 않는다.
- Foundation 개발 중 DataStore를 켜지 않는다. State module은 DataStore를 직접 호출하지 않도록 유지한다.

G5가 끝나면 Architecture Foundation을 더 확장하지 않고 즉시 `S1_SELECTION`으로 넘어간다.

## 2. Exploration 사용자 Checkpoint 순서

```text
S1_SELECTION
→ C1_CAMERA
→ M1_MOVE
→ X1_CONTEXT
→ I1_INTERACTION
```

각 Checkpoint 상태는 다음 중 하나다.

```text
PLANNED
IMPLEMENTING
READY_FOR_USER
ACCEPTED
BLOCKED
```

규칙:

- 이전 Checkpoint가 `ACCEPTED`가 아니면 다음 Checkpoint를 `IMPLEMENTING`으로 올리지 않는다.
- `READY_FOR_USER`가 되면 다음 기능 개발을 멈춘다.
- 사용자가 마음에 들지 않는다고 하면 같은 Checkpoint를 `IMPLEMENTING`으로 되돌려 즉시 수정한다.
- 사용자 피드백을 나중 UX backlog로 미루지 않는다.
- 사용자가 기능을 수용해도 즉시 `ACCEPTED`로 바꾸지 않는다. 먼저 Authority Reconciliation을 수행한다.
- `ACCEPTED`는 사용자 수용 + 현재 상위 문서 정합화 + Canonical Source + Focused Test가 모두 끝난 상태다.

### Checkpoint 확정 Gate

```text
READY_FOR_USER
→ 사용자 수정 요청이면 IMPLEMENTING으로 복귀
→ 사용자 최종 수용
→ Authority Impact Scan
→ 현재 상위 Authority부터 Top-down Reconciliation
→ Module Contract / Source / Test 정규화
→ 남은 현재 문서 충돌 없음 확인
→ ACCEPTED
```

정확한 절차는 `AUTHORITY-RECONCILIATION-POLICY.md`가 소유한다.

사용자가 화면 동작을 수용했다는 사실만으로 보이지 않는 Architecture·Authority 변경까지 승인받은 것으로 해석하지 않는다. 정합화 중 미승인 Architecture 변경이 필요하면 사용자에게 먼저 제안한다.

### S1 — Selection

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
```

Selection은 Client local state이며 서버 gameplay mutation이 아니다.

### C1 — Camera

```text
SemanticInputRouter
→ CameraController
→ local camera state
```

Camera는 Client local state다. 서버 Remote를 사용하지 않는다.

### M1 — Move

```text
MovementController
→ CommandClient
→ CommandGateway
→ CommandRuntime
→ AuthorizationService
→ MovementDomain
→ WorldState
→ ProjectionService
→ ProjectionGateway
→ ProjectionReplica
→ WorldPresenter
```

Client가 Token CFrame/Position을 authoritative 결과로 직접 확정하지 않는다.

### X1 — Context

Right-click은 Client에서 현재 Projection을 이용해 메뉴 후보를 보여줄 수 있지만, 실제 gameplay action의 성공 여부는 서버 Command 경계가 최종 판정한다.

### I1 — Interaction

Interaction도 X1과 동일한 Command/Authority/Projection 경로를 재사용한다. 기능 하나를 위해 별도 Remote나 별도 authoritative state path를 만들지 않는다.

## 3. Exploration 이후 제품 시스템 순서

Exploration이 사용자에게 수용되고 Authority Reconciliation까지 끝난 뒤의 큰 순서는 다음으로 고정한다.

```text
P0 Foundation
→ P1 Exploration Core
→ P2 Session·Role·Reconnect·Recovery
→ P3 Encounter + Character Console
→ P4 Character Data Surfaces
   (Character Sheet · Inventory · Journal · Settings)
→ P5 DM Live Workspace
→ P6 Rules·Content Runtime
→ P7 Persistence·Migration·Rollback
→ P8 ADR-0092 Survival Logistics + Actor Authoring
→ P9 Multi-client·Disclosure·Accessibility·Performance Hardening
→ P10 Release Acceptance
```

이 순서의 이유:

- Session/Recovery를 늦추면 뒤의 모든 UI가 잘못된 Role 가정을 품게 된다.
- Encounter는 Exploration의 World·Command·Projection 경계를 재사용할 수 있을 때 만든다.
- Character surface는 Encounter와 공통 Character state 계약이 안정된 뒤 만든다.
- DM Workspace는 Player 흐름과 권한 경계를 먼저 체감한 뒤 확장한다.
- Persistence는 제품 흐름이 정해진 뒤 붙이되, 그 전부터 Domain/State가 DataStore를 직접 호출하지 않게 해 retrofit 비용을 막는다.
- Multi-client·성능·Release Acceptance는 일상 개발 Gate가 아니지만 Release 전에는 필수다.

사용자가 우선순위를 바꾸거나 더 좋은 제품 순서를 결정하면 이 문서를 갱신한다. 에이전트가 독단적으로 순서를 재배치하지 않는다.

## 4. 비협상 기술 안전 규칙

다음은 Greenfield Build 전체에서 고정한다.

1. **Server authoritative** — gameplay mutation 최종 권한은 Server에 있다.
2. **Client input is untrusted** — Client가 보낸 Role/Owner/Controller/결과 값을 신뢰하지 않는다.
3. **One command boundary** — authoritative mutation은 등록된 Command 경계를 통과한다.
4. **Bounded network data** — Remote payload에 size/type/depth/rate 제한을 둔다.
5. **No Instance over network** — Stable ID와 data contract만 사용한다.
6. **Optimistic concurrency** — mutation은 epoch/revision 불일치를 감지하고 stale write를 거부한다.
7. **Idempotent command identity** — commandId 중복을 안전하게 처리한다.
8. **Viewer-safe projection** — Client는 허용된 Projection만 받는다. 존재 정보 누출도 금지한다.
9. **UI cannot own transport** — UI/Presenter가 Remote를 직접 호출하지 않는다.
10. **Bootstrap is composition only** — Gameplay logic을 Bootstrap/App에 넣지 않는다.
11. **Lifecycle cleanup** — connection/task/Instance를 명확히 해제한다.
12. **Fail closed** — 권한·schema·revision을 확인할 수 없으면 성공시키지 않는다.
13. **Structured diagnostics** — 실패 원인과 Context를 남기며 오류를 조용히 삼키지 않는다.
14. **No Studio-only production truth** — 수용된 동작은 GitHub Source와 Rojo Mapping에서 재현 가능해야 한다.
15. **Persistence behind a boundary** — Domain/Controller가 DataStore를 직접 호출하지 않는다.
16. **No premature release gates** — 빠른 Human feedback은 유지하되 Security/Authority 규칙은 Prototype에서도 우회하지 않는다.

## 5. 변경 Gate

다음은 Codex가 임의로 바꾸지 않는다.

- G0→G5 Foundation 순서
- Server/Client Authority 경계
- Command/Projection 방향
- Checkpoint 순서
- Product System P0→P10 순서
- 위 비협상 안전 규칙

더 좋은 방향이 발견되면 현재 문제, 제안, 장점, 비용·위험, 영향 범위를 사용자에게 먼저 보고한다.
