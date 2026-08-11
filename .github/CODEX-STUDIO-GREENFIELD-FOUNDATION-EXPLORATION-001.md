# RVTT Studio Greenfield — Ordered Foundation + Exploration 001

- 상태: `ACTIVE · CURRENT_COMMAND`
- Build mode: `GREENFIELD_ARCHITECTURE_FIRST`
- Sequence authority: [`../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`](../implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md)
- Acceptance promotion gate: [`../implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`](../implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md)
- Feedback mode: `TIGHT_USER_FEEDBACK_LOOP`

## 목표

새 RVTT를 **안전한 dependency 순서로 시스템부터 구축한 뒤** 가장 빠른 사용자 기능인 Selection을 보여준다.

성공 조건:

1. Foundation Stage가 순서대로 구현된다.
2. Bootstrap/Manager에 기능을 몰아넣지 않는다.
3. 네트워크 입력 전에 Server Authority가 존재한다.
4. Client는 viewer-safe Projection만 읽는다.
5. S1 Selection을 사용자가 직접 테스트하고 즉시 수정할 수 있다.
6. 사용자가 최종 수용한 뒤에는 현재 상위 문서·Contract·Source·Test를 정합화하고 Promotion Commit을 만든 후에만 S1을 `ACCEPTED`로 만든다.

## 구현 전 읽기

1. `AGENTS.md`
2. `.github/CODEX-ACTIVE-TASK.md`
3. `implementation/roblox/GREENFIELD-SYSTEM-SEQUENCE.md`
4. `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`
5. `implementation/roblox/GREENFIELD-BUILD-POLICY.md`
6. `implementation/roblox/MODULE-CONTRACTS.md`
7. `implementation/roblox/manifests/module-contracts.json`
8. 관련 Product·ADR·Spec
9. 필요한 Legacy Source

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

반복 수정 중에는 Product·ADR·Architecture 문서를 매번 수정하지 않는다. 현재 사용자 요청을 Working Truth로 두고 같은 Checkpoint에서 빠르게 반복한다.

## 사용자가 S1을 최종 수용했을 때

사용자가 `좋다`, `이걸로`, `확정`, `다음`처럼 최종 수용하면 Camera로 가지 않는다. 먼저 Authority Reconciliation과 Promotion을 수행한다.

```text
사용자 최종 수용
→ 확정된 Selection 동작을 한 문장으로 기록
→ 현재 Product·ADR·Architecture·Spec·Policy 전체에서 충돌 검색
→ 상위 Authority부터 수정 또는 Supersede
→ Module Contract 정합화
→ Studio 결과를 greenfield/src로 정규화
→ Rojo 재현 확인
→ Focused Test 추가·실행
→ 현재 문서 충돌 재검색
→ UNRESOLVED CONFLICTS = none 확인
→ S1 / 관련 Module을 ACCEPTED 상태로 준비
→ checkpoint(S1_SELECTION): accept <summary> Promotion Commit 생성
→ Promotion Commit SHA 기록
→ C1_CAMERA 시작
```

Promotion Commit은 확정 Authority + Module Contract + Canonical Source + Rojo Mapping + Focused Test를 한 기준점에 묶는다. 다음 기능이나 임시 디버그 변경을 섞지 않는다.

화면/조작 수용을 내부 Architecture·Authority 변경의 승인으로 확대 해석하지 않는다. Reconciliation 중 미승인 Architecture 변경이 필요하면 중단하고 사용자에게 먼저 제안한다.

Historical Audit·Acceptance·Review·과거 Codex Command는 새 결정에 맞춰 다시 쓰지 않는다.

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

Stage가 실제 구현되면 `greenfield/src`에 정리하고 `module-contracts.json` 상태를 맞춘다.

사용자 Checkpoint는 사용자 수용만으로 `ACCEPTED` 처리하지 않는다. `AUTHORITY-RECONCILIATION-POLICY.md`의 Top-down 문서 정합화, Canonical Source, Rojo 재현, Focused Test가 끝난 최종 상태를 Promotion Commit으로 고정하고 그 SHA를 복원 기준점으로 기록한 뒤 다음 Checkpoint로 간다.
