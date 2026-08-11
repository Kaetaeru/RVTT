# RVTT Module Contracts

- 상태: `ACTIVE · GREENFIELD_V3`
- 최종 갱신일: 2026-08-12
- 현재 Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- Legacy Reference: [`manifests/legacy-module-contracts.json`](manifests/legacy-module-contracts.json)
- Pre-G0 Boundary: [`GREENFIELD-PREFLIGHT.md`](GREENFIELD-PREFLIGHT.md)
- 시스템 순서: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)
- Validator: [`tooling/validate_module_contracts.py`](tooling/validate_module_contracts.py)

## 1. 역할

`module-contracts.json`은 현재 새 RVTT의 **목표 Architecture + 시스템 구축 단계 + 사용자 Checkpoint 상태**를 기록한다.

기존 Production 계약은 `legacy-module-contracts.json`에 보존하며 현재 구현 Authority가 아니다.

Greenfield Source는 `greenfield/src`, Focused Test는 `greenfield/tests`, Rojo 재현은 `greenfield.project.json`을 사용한다. Legacy `src`와 `default.project.json`은 `greenfield-boundary.json`에 의해 읽기 전용 Reference로 잠긴다.

## 2. Module Lifecycle

```text
PLANNED
→ IMPLEMENTED
→ ACCEPTED
→ DEPRECATED
```

- `PLANNED`: 책임·Authority·예정 경로가 먼저 존재한다. Source는 없어도 된다.
- `IMPLEMENTED`: 실제 `greenfield/src` Source와 Stable Entry Point가 존재하고 Studio에 연결됐다.
- `ACCEPTED`: 관련 사용자 동작 수용 + Authority Reconciliation + Canonical Source + Focused Test + Checkpoint Promotion Commit까지 완료됐다.
- `DEPRECATED`: 새 구조에서 사용하지 않는다.

사용자가 `좋다`고 말한 순간 바로 Module을 `ACCEPTED`로 올리지 않는다.

## 3. System Stage

Registry의 `systemStages`가 Foundation 순서를 기계적으로 표현한다.

```text
G0_SHARED_CONTRACTS
→ G1_SERVER_AUTHORITY_CORE
→ G2_COMMAND_TRANSPORT
→ G3_PROJECTION_PIPELINE
→ G4_CLIENT_WORLD_SHELL
→ G5_COMPOSITION_BOOT
```

`GREENFIELD-PREFLIGHT.md`의 Workbench Gate는 Stage가 아니며 이 순서를 변경하지 않는다.

Validator는 다음을 막는다.

- Stage module 누락·중복
- Foundation dependency가 미래 Stage를 참조하는 구조
- 이전 Stage가 끝나기 전에 다음 Stage Module을 `IMPLEMENTED`로 승격
- `foundationRequired`와 Stage union의 불일치

## 4. User Checkpoint

`deliveryCheckpoints`는 별도 상태를 가진다.

```text
PLANNED
IMPLEMENTING
READY_FOR_USER
ACCEPTED
BLOCKED
```

- 이전 Checkpoint가 `ACCEPTED`가 아니면 다음 Checkpoint를 시작할 수 없다.
- `READY_FOR_USER`/`ACCEPTED`는 필요한 Module이 최소 `IMPLEMENTED`여야 한다.
- 사용자가 기능을 수용하면 `AUTHORITY-RECONCILIATION-POLICY.md`를 먼저 수행한다.
- `ACCEPTED` Checkpoint의 직접 Module은 Focused Test와 함께 `ACCEPTED` 상태여야 한다.
- 현재 상위 문서 충돌이나 미승인 Architecture 변경이 남아 있으면 Checkpoint를 `ACCEPTED`로 올리지 않는다.
- 최종 정합 상태는 `checkpoint(<CHECKPOINT_ID>): accept <summary>` Promotion Commit으로 고정하고 그 SHA를 복원 기준점으로 사용한다.

이 상태는 Codex가 임의로 사용자 수용을 추측하기 위한 것이 아니다.

## 5. Module 필드

```text
id
status
plannedPath
kind
responsibility
entryPoints
dependsOn
authority
stateOwnership
legacyCandidates
testRefs
```

`dependsOn`은 Architecture-level dependency만 기록한다. 모든 `require()`를 복제하지 않는다.

`legacyCandidates`는 참고할 이전 Source 경로이며 재사용 의무가 아니다. Legacy Candidate를 사용하더라도 Legacy 파일 자체를 수정하지 않고 Greenfield 경로에 현재 Contract에 맞게 구현한다.

## 6. 안전 경계

Registry의 `technicalSafety`는 개발 중에도 유지할 비협상 기술 규칙을 기계적으로 고정한다.

대표 규칙:

- Server authority
- untrusted client input
- client role claim 불신
- bounded network payload
- no Instance over network
- command idempotency / revision
- viewer-safe Projection
- Bootstrap gameplay logic 금지
- Studio-only Production truth 금지
- Foundation DataStore 비활성
- lifecycle cleanup

정확한 의미는 `GREENFIELD-SYSTEM-SEQUENCE.md`를 따른다.

## 7. Source 정합화

`IMPLEMENTED` 또는 `ACCEPTED` Module은:

- `greenfield/src/` 아래 Source가 존재한다.
- Stable Entry Point Token이 Source에 존재한다.
- `dependsOn` 대상이 Registry에 존재한다.
- 선언된 Focused Test가 있으면 실제 파일이 존재한다.

`ACCEPTED` Module은 최소 하나의 `greenfield/tests/` Focused Test를 가진다.

Rojo 재현은 Legacy `default.project.json`이 아니라 `greenfield.project.json`을 기준으로 확인한다.

사용자 확정으로 Module 책임이나 사용자 동작 의미가 바뀌었다면 Source만 바꾸지 않는다. Authority Impact Scan을 수행하고 영향을 받는 Product·ADR·Architecture·Spec·Module Contract를 위에서 아래로 정합화한다.

## 8. Call Graph

private/helper 호출 순서와 모든 `require()`는 현재 Source에서 읽는다. 수동 Call Graph를 별도 Authority로 유지하지 않는다.

## 9. Architecture 변경

Module 책임 분리·통합, Stage 순서, Authority, Command/Projection 방향, Greenfield/Legacy 경계를 바꾸려면 사용자에게 먼저 제안한다. helper 내부 구현은 Contract 경계가 유지되는 한 Codex가 판단할 수 있다.

사용자가 화면/조작 결과를 수용한 것을 미승인 내부 Architecture 변경의 승인으로 확대 해석하지 않는다.
