# RVTT Studio Greenfield — Ordered Foundation + Exploration 001

- 상태: `ACTIVE · CURRENT_COMMAND · READY_FOR_G0`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Pre-G0 authority: [`../implementation/roblox/GREENFIELD-PREFLIGHT.md`](../implementation/roblox/GREENFIELD-PREFLIGHT.md)
- Greenfield project: `implementation/roblox/greenfield.project.json`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Module authority: [`../implementation/roblox/MODULE-CONTRACTS.md`](../implementation/roblox/MODULE-CONTRACTS.md)
- System/function authority: [`../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`](../implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md)
- Acceptance promotion gate: [`../implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`](../implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md)
- Feedback mode: `TIGHT_USER_FEEDBACK_LOOP`

## 목표

새 RVTT를 안전한 dependency 순서로 시스템부터 구축한 뒤 가장 빠른 사용자 기능인 Selection을 보여준다.

Source를 보면서 Architecture/API를 즉석에서 발명하지 않는다. 현재 Foundation+Exploration 범위는 이미 다음 순서로 선언되어 있다.

```text
System Contract
→ Module Contract
→ Stable Function Contract
→ Source 구현
```

private/helper 분해만 구현 시점에 Source에서 결정한다.

## 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
4. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
5. `implementation/roblox/MODULE-CONTRACTS.md`
6. `implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`
7. `implementation/roblox/manifests/module-contracts.json`
8. `implementation/roblox/manifests/system-function-contracts.json`
9. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
10. `implementation/roblox/GREENFIELD-BUILD-POLICY.md`
11. `implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md`
12. 관련 Product·ADR·Spec
13. 필요한 Legacy Source — 읽기 참고만

## 0. PRE-G0 WORKBENCH GATE

G0 Source를 만들기 전에 다음을 실행한다.

```text
python implementation/roblox/tooling/validate_greenfield_boundary.py
python implementation/roblox/tooling/validate_module_contracts.py
rojo build implementation/roblox/greenfield.project.json --output <temp-place>
```

`validate_module_contracts.py`는 이제 Module/Stage뿐 아니라 System Contract와 Stable Function Contract까지 검사한다.

그 다음 Studio에서:

1. 현재 Place/Session identity를 확인한다.
2. Legacy Production Place를 Baseline으로 수정하려는 상태가 아닌지 확인한다.
3. MCP Capability Handshake를 수행한다.
4. 결과를 `GREENFIELD-PREFLIGHT.md` 형식으로 보고한다.

`READY_FOR_G0` 또는 fallback이 명확한 `DEGRADED_READY`일 때만 G0를 시작한다.

### 절대 사용하지 않는 구현 경로

```text
implementation/roblox/default.project.json
implementation/roblox/src/**
```

이 둘은 Legacy Reference다. 읽을 수는 있지만 Greenfield 구현을 위해 수정하지 않는다.

## 1. 모든 Stage 공통 구현 규칙

각 Module을 구현하기 직전에 해당 `moduleFunctionContracts`를 읽는다.

Stable Function은 계약에 적힌 다음 의미를 지켜야 한다.

```text
name
kind
purpose
inputs / output
authority
reads / writes
sideEffects
failureModes
idempotency
validation
permission
revisionBehavior
```

규칙:

- `entryPoints`에 있는데 Function Contract가 없거나 반대인 상태에서 구현 금지.
- 다른 Contract-bearing Module에서 호출할 함수가 필요하면 먼저 Function Contract를 만든다.
- undeclared cross-module method를 임시로 만든 뒤 나중에 문서화하는 방식 금지.
- private/local helper는 자유롭게 만들 수 있고 Registry에 쓰지 않는다.
- private helper가 다른 Module의 의존 대상이 되는 순간 Stable Function으로 승격한다.
- Function Contract 보완이 Authority/state owner/Module responsibility/System flow를 바꾸면 자동 적용하지 말고 사용자에게 먼저 제안한다.

## 2. 고정 실행 순서

### G0_SHARED_CONTRACTS

Pre-G0 Gate 통과 후 `system.shared-data-contracts`를 구현한다.

```text
CommandEnvelope.validate
ProjectionEnvelope.validate
WorldContract = DATA_ONLY_MODULE
```

bounded/serializable data만 허용하고 trusted role/owner/controller claim이나 Roblox Instance를 계약에 넣지 않는다.

### G1_SERVER_AUTHORITY_CORE

`system.server-authority-core`를 구현한다.

핵심 Stable Boundary:

```text
SessionAuthority.new/getRole/canControl/destroy
WorldState.new/getSnapshot/getRevision/transact
AuthorizationService.new/authorize
CommandRuntime.new/register/execute
```

특히 `WorldState.transact`만 authoritative world state mutation과 revision 증가를 소유한다. network payload에서 mutation callback/capability를 받지 않는다.

### G2_COMMAND_TRANSPORT

`system.command-transport`를 구현한다.

```text
CommandClient.new/submit/destroy
CommandGateway.new/start/destroy
CommandRuntime.execute
```

Gateway는 Roblox transport adapter일 뿐 gameplay authority가 아니다.

### G3_PROJECTION_PIPELINE

`system.projection-pipeline`을 구현한다.

```text
ProjectionService.new/buildForViewer
ProjectionGateway.new/start/publish/destroy
ProjectionReplica.new/start/getSnapshot/subscribe/destroy
```

ProjectionService가 disclosure를 결정하고 Gateway는 전달만 한다. Replica는 accepted epoch/revision만 보관하고 `subscribe`는 immutable change observation만 제공한다.

### G4_CLIENT_WORLD_SHELL

`system.client-world-shell`을 구현한다.

```text
SemanticInputRouter.new/subscribe/start/destroy
WorldSystem.new/start/destroy
```

Controller는 raw physical input을 각각 직접 구독하지 않고 `SemanticInputRouter.subscribe`를 사용한다.

### G5_COMPOSITION_BOOT

`system.composition-boot`를 구현한다.

```text
ServerApp.new/start/destroy
ServerBootstrap = AUTO_EXEC_SCRIPT
ClientApp.new/start/destroy
ClientBootstrap = AUTO_EXEC_SCRIPT
```

Bootstrap/App은 composition/lifecycle만 담당한다.

Foundation Boot Gate:

- fatal error 없음
- Server Authority와 Gateway가 명확히 분리됨
- initial viewer projection 수신 가능
- Client가 무한 readiness wait를 하지 않음
- cleanup 가능한 lifecycle
- DataStore off
- Studio-only Production logic 없음
- `greenfield.project.json`에서 clean rebuild 가능

## 3. S1_SELECTION

G5 이후 즉시 `system.selection`을 구현한다.

```text
SemanticInputRouter.subscribe
→ SelectionController.start
→ SelectionController local selected actor id
→ SelectionController.subscribe/getSelection
→ WorldPresenter.start
```

Stable Boundary:

```text
SelectionController.new/start/getSelection/subscribe/destroy
WorldPresenter.new/start/destroy
```

Selection은 client-local state이며 서버 gameplay mutation이 아니다.

Selection이 실제 동작하면 Checkpoint를 `READY_FOR_USER`로 갱신하고 멈춘다.

사용자에게 보고:

```text
CHECKPOINT: S1_SELECTION
STATUS: READY_FOR_USER
테스트 방법
현재 System / Module / Stable Function 흐름
사용자가 판단할 항목
```

사용자 수정 요청:

```text
S1 status → IMPLEMENTING
→ 즉시 수정
→ 같은 Selection 재Play
→ READY_FOR_USER
→ 사용자 재확인
```

private/helper 변경은 빠르게 반복한다. Stable Function 의미가 달라지면 Source보다 Contract를 먼저 맞춘다.

## 4. 사용자가 S1을 최종 수용했을 때

Camera로 가지 않는다. 먼저 Authority Reconciliation과 Promotion을 수행한다.

```text
사용자 최종 수용
→ 확정된 Selection 동작 기록
→ 현재 Product·ADR·Architecture·Spec·Policy 충돌 검색
→ System Contract 정합화
→ Module Contract 정합화
→ Stable Function Contract 정합화
→ Studio 결과를 greenfield/src로 정규화
→ greenfield.project.json 재현 확인
→ Focused Test 추가·실행
→ 현재 문서/Contract 충돌 재검색
→ UNRESOLVED CONFLICTS = none
→ S1 / 관련 Module을 ACCEPTED 상태로 준비
→ checkpoint(S1_SELECTION): accept <summary> Promotion Commit
→ Promotion Commit SHA 기록
→ C1_CAMERA 시작
```

Promotion Commit에는 다음 기능이나 임시 디버그 변경을 섞지 않는다.

## 5. 이후 Exploration

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

현재 System/Function Registry에는 이 범위도 미리 선언되어 있다.

- `system.camera`: CameraController `new/start/destroy`.
- `system.movement`: MovementController → CommandClient → Gateway → Runtime → Authorization → MovementDomain → WorldState.transact → Projection pipeline → Presenter.
- `system.context-interaction`: ContextActionController → standard Command/Authority/WorldState/Projection path.

각 Checkpoint에서 동일하게 **수정 반복 → 사용자 최종 수용 → Authority Reconciliation → Promotion Commit → ACCEPTED → 다음** 순서를 사용한다.

## 6. 금지

- Contract 없이 Source/API부터 생성
- undeclared cross-module function 호출
- private helper를 암묵적인 cross-module API로 사용
- 미래 P2~P10 세부 API 선행 발명
- Legacy `src` 또는 `default.project.json` 수정
- 기존 Production Place를 Greenfield Baseline으로 사용
- LocalScript 하나에 Input/Selection/Camera/Move/UI 결합
- ServerScript 하나에 Remote/Auth/Mutation/Projection 결합
- Bootstrap/App gameplay logic
- UI direct Remote
- Client authoritative position commit
- Network Instance reference
- client-provided role/owner/controller 신뢰
- Stage skip
- Checkpoint skip
- 사용자 수용 직후 Authority Reconciliation 생략
- Promotion Commit 없이 다음 Checkpoint 진행
- Legacy Acceptance를 Greenfield PASS로 사용

## 7. Canonicalization

Stage가 실제 구현되면 `greenfield/src`에 정리하고 Module/Function Contract와 실제 Source를 맞춘다. Rojo 재현은 `greenfield.project.json`을 기준으로 한다.

사용자 Checkpoint는 사용자 수용만으로 `ACCEPTED` 처리하지 않는다. Top-down 문서 정합화, System/Module/Stable Function Contract, Canonical Source, Rojo 재현, Focused Test가 끝난 최종 상태를 Promotion Commit으로 고정한 뒤 다음 Checkpoint로 간다.
