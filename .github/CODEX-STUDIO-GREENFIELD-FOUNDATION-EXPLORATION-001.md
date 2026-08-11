# RVTT Studio Greenfield — Ordered Foundation + Exploration 001

- 상태: `ACTIVE · CURRENT_COMMAND · READY_FOR_G0`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Pre-G0 authority: [`../implementation/roblox/GREENFIELD-PREFLIGHT.md`](../implementation/roblox/GREENFIELD-PREFLIGHT.md)
- Greenfield project: `implementation/roblox/greenfield.project.json`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Acceptance promotion gate: [`../implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`](../implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md)
- Feedback mode: `TIGHT_USER_FEEDBACK_LOOP`

## 목표

새 RVTT를 안전한 dependency 순서로 시스템부터 구축한 뒤 가장 빠른 사용자 기능인 Selection을 보여준다.

이 Command가 시작될 때 Repository는 G0 구현 직전 상태다. **첫 행동은 G0 코딩이 아니라 Pre-G0 Workbench 확인**이다.

## 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/GREENFIELD-PREFLIGHT.md`
4. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
5. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
6. `implementation/roblox/GREENFIELD-BUILD-POLICY.md`
7. `implementation/roblox/ROBLOX-STUDIO-MCP-TEST-POLICY.md`
8. `implementation/roblox/MODULE-CONTRACTS.md`
9. `implementation/roblox/manifests/module-contracts.json`
10. 관련 Product·ADR·Spec
11. 필요한 Legacy Source — 읽기 참고만

## 0. PRE-G0 WORKBENCH GATE

G0 Source를 만들기 전에 다음을 실행한다.

```text
python implementation/roblox/tooling/validate_greenfield_boundary.py
python implementation/roblox/tooling/validate_module_contracts.py
rojo build implementation/roblox/greenfield.project.json --output <temp-place>
```

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

## 실행 순서

### G0_SHARED_CONTRACTS

Pre-G0 Gate 통과 후에만 `CommandEnvelope`, `ProjectionEnvelope`, `WorldContract`를 구현한다. pure data contract로 유지하고 bounded validation을 넣는다.

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

`ServerApp/Bootstrap`, `ClientApp/Bootstrap`을 조립하고 Greenfield Studio Build를 Boot한다.

Foundation Boot Gate:

- fatal error 없음
- Server Authority와 Gateway가 명확히 분리됨
- initial viewer projection 수신 가능
- Client가 무한 readiness wait를 하지 않음
- cleanup 가능한 lifecycle
- DataStore off
- Studio-only Production logic 없음
- `greenfield.project.json`에서 clean rebuild 가능

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

반복 수정 중에는 Product·ADR·Architecture 문서를 매번 수정하지 않는다. 현재 사용자 요청을 Working Truth로 두고 같은 Checkpoint에서 빠르게 반복한다.

## 사용자가 S1을 최종 수용했을 때

Camera로 가지 않는다. 먼저 Authority Reconciliation과 Promotion을 수행한다.

```text
사용자 최종 수용
→ 확정된 Selection 동작 기록
→ 현재 Product·ADR·Architecture·Spec·Policy 충돌 검색
→ 상위 Authority부터 수정 또는 Supersede
→ Module Contract 정합화
→ Studio 결과를 greenfield/src로 정규화
→ greenfield.project.json 재현 확인
→ Focused Test 추가·실행
→ 현재 문서 충돌 재검색
→ UNRESOLVED CONFLICTS = none
→ S1 / 관련 Module을 ACCEPTED 상태로 준비
→ checkpoint(S1_SELECTION): accept <summary> Promotion Commit
→ Promotion Commit SHA 기록
→ C1_CAMERA 시작
```

Promotion Commit에는 다음 기능이나 임시 디버그 변경을 섞지 않는다.

## 이후 Exploration

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint에서 동일하게 **수정 반복 → 사용자 최종 수용 → Authority Reconciliation → Promotion Commit → ACCEPTED → 다음** 순서를 사용한다.

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

## Canonicalization

Stage가 실제 구현되면 `greenfield/src`에 정리하고 `module-contracts.json` 상태를 맞춘다. Rojo 재현은 `greenfield.project.json`을 기준으로 한다.

사용자 Checkpoint는 사용자 수용만으로 `ACCEPTED` 처리하지 않는다. Top-down 문서 정합화, Canonical Source, Rojo 재현, Focused Test가 끝난 최종 상태를 Promotion Commit으로 고정하고 그 SHA를 복원 기준점으로 기록한 뒤 다음 Checkpoint로 간다.
