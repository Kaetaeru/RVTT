# RVTT Studio Greenfield — Ordered Foundation + Exploration 001

- 상태: `ACTIVE · CURRENT_COMMAND`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Feedback mode: `TIGHT_USER_FEEDBACK_LOOP`

## 목표

새 RVTT를 **안전한 dependency 순서로 시스템부터 구축한 뒤** 가장 빠른 사용자 기능인 Selection을 보여준다.

성공 조건:

1. Foundation Stage가 순서대로 구현된다.
2. Bootstrap/Manager에 기능을 몰아넣지 않는다.
3. 네트워크 입력 전에 Server Authority가 존재한다.
4. Client는 viewer-safe Projection만 읽는다.
5. S1 Selection을 사용자가 직접 테스트하고 즉시 수정할 수 있다.

## 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
4. `implementation/roblox/GREENFIELD-BUILD-POLICY.md`
5. `implementation/roblox/MODULE-CONTRACTS.md`
6. `implementation/roblox/manifests/module-contracts.json`
7. 관련 Product·ADR·Spec
8. 필요한 Legacy Source

## 실행 순서

### G0_SHARED_CONTRACTS

`CommandEnvelope`, `ProjectionEnvelope`, `WorldContract`를 먼저 구현한다. pure data contract로 유지하고 bounded validation을 넣는다.

### G1_SERVER_AUTHORITY_CORE

`SessionAuthority → WorldState → AuthorizationService → CommandRuntime`을 구현한다.

- Client role claim을 신뢰하지 않는다.
- mutation은 authorization + revision 검증 뒤에만 실행한다.
- duplicate commandId와 stale revision을 안전하게 거부할 수 있게 한다.

### G2_COMMAND_TRANSPORT

`CommandGateway`와 `CommandClient`를 연결한다.

- Gateway는 Remote adapter다. Gameplay logic을 넣지 않는다.
- rate/size/type validation을 서버에서 적용한다.

### G3_PROJECTION_PIPELINE

`ProjectionService → ProjectionGateway → ProjectionReplica`를 연결한다.

- ProjectionService가 viewer-safe selection을 소유한다.
- Gateway는 전달만 한다.
- Replica는 epoch/revision 역행을 적용하지 않는다.

### G4_CLIENT_WORLD_SHELL

`SemanticInputRouter`와 `WorldSystem`을 구현한다.

- 물리 입력을 semantic action으로 바꾼다.
- WorldSystem은 controller lifecycle만 소유한다.

### G5_COMPOSITION_BOOT

`ServerApp/Bootstrap`, `ClientApp/Bootstrap`을 조립하고 새 Studio Build를 Boot한다.

Foundation Boot Gate:

- fatal error 없음
- Server Authority와 Gateway가 명확히 분리됨
- initial viewer projection 수신 가능
- Client가 무한 readiness wait를 하지 않음
- cleanup 가능한 lifecycle
- DataStore off
- Studio-only Production logic 없음

## S1_SELECTION

G5 이후 즉시 다음을 연결한다.

```text
SemanticInputRouter
→ SelectionController
→ local selection state
→ WorldPresenter
```

Selection이 실제 동작하면 Checkpoint를 `READY_FOR_USER`로 갱신하고 멈춘다.

사용자에게 보고:

```text
CHECKPOINT: S1_SELECTION
STATUS: READY_FOR_USER
테스트 방법
현재 Module 흐름
사용자가 판단할 항목
```

사용자가 수정 요청:

```text
S1 status → IMPLEMENTING
→ 즉시 수정
→ 같은 Selection 재Play
→ READY_FOR_USER
→ 사용자 재확인
```

S1이 `ACCEPTED`가 되기 전 `C1_CAMERA`를 시작하지 않는다.

## 이후 Exploration

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

Move의 필수 경로:

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

## 금지

- LocalScript 하나에 Input/Selection/Camera/Move/UI 결합
- ServerScript 하나에 Remote/Auth/Mutation/Projection 결합
- Bootstrap/App gameplay logic
- UI direct Remote
- Client authoritative position commit
- Network Instance reference
- client-provided role/owner/controller 신뢰
- Stage skip
- Checkpoint skip
- Legacy Acceptance를 Greenfield PASS로 사용

## Canonicalization

Stage/Checkpoint가 실제 구현되면 `greenfield/src`에 정리하고 `module-contracts.json` 상태를 맞춘다. 사용자 수용 후 Focused Test를 추가하고 관련 Module/Checkpoint를 `ACCEPTED`로 갱신한다.
