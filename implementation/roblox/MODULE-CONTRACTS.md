# RVTT Module Contracts

- 상태: `ACTIVE · GREENFIELD_V3`
- 최종 갱신일: 2026-08-12
- Module Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- System/Function Registry: [`manifests/system-function-contracts.json`](manifests/system-function-contracts.json)
- Stable Function Policy: [`SYSTEM-FUNCTION-CONTRACTS.md`](SYSTEM-FUNCTION-CONTRACTS.md)
- Legacy Reference: [`manifests/legacy-module-contracts.json`](manifests/legacy-module-contracts.json)
- Pre-G0 Boundary: [`GREENFIELD-PREFLIGHT.md`](GREENFIELD-PREFLIGHT.md)
- 시스템 순서: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)
- Validator: [`tooling/validate_module_contracts.py`](tooling/validate_module_contracts.py)

## 1. 역할

Greenfield code boundary는 두 개의 machine-readable Registry가 함께 소유한다.

```text
module-contracts.json
= Module / dependency / authority / state ownership / stage / checkpoint

system-function-contracts.json
= System flow / invariants / Stable Function meaning
```

기존 Production 계약은 `legacy-module-contracts.json`에 보존하며 현재 구현 Authority가 아니다.

Greenfield Source는 `greenfield/src`, Focused Test는 `greenfield/tests`, Rojo 재현은 `greenfield.project.json`을 사용한다. Legacy `src`와 `default.project.json`은 `greenfield-boundary.json`에 의해 읽기 전용 Reference로 잠긴다.

## 2. 설계 순서

현재 또는 다음 구현 범위에 들어오는 기능은 Source보다 먼저 다음을 가진다.

```text
System Contract
→ Module Contract
→ Stable Function Contract
→ Source
```

System/Module/Stable Function 계약 없이 기능부터 구현하지 않는다.

반대로 아직 멀리 있는 미래 Product System의 구체 Module/Function을 상상으로 미리 만들지 않는다. 큰 P0~P10 순서는 `GREENFIELD-SYSTEM-SEQUENCE.md`가 고정하고, 세부 Code Contract는 구현 범위에 들어오기 직전에 만든다.

현재 Registry는 Foundation G0~G5와 Exploration S1/C1/M1/X1/I1 범위를 완전히 선언한다.

## 3. Module Lifecycle

```text
PLANNED
→ IMPLEMENTED
→ ACCEPTED
→ DEPRECATED
```

- `PLANNED`: System/Module/Stable Function 책임이 먼저 존재한다. Source는 없어도 된다.
- `IMPLEMENTED`: 실제 `greenfield/src` Source와 모든 Stable Entry Point가 존재하고 Studio에 연결됐다.
- `ACCEPTED`: 관련 사용자 동작 수용 + Authority Reconciliation + Canonical Source + Focused Test + Checkpoint Promotion Commit까지 완료됐다.
- `DEPRECATED`: 새 구조에서 사용하지 않는다.

사용자가 `좋다`고 말한 순간 바로 Module을 `ACCEPTED`로 올리지 않는다.

## 4. System Stage

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

Validator는 Stage module 누락/중복, 미래 Stage dependency, 이전 Stage 완료 전 구현 승격, `foundationRequired` 불일치를 막는다.

## 5. User Checkpoint

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
- 현재 상위 문서 충돌이나 미승인 Architecture 변경이 남아 있으면 `ACCEPTED`로 올리지 않는다.
- 최종 정합 상태는 `checkpoint(<CHECKPOINT_ID>): accept <summary>` Promotion Commit으로 고정한다.

## 6. Module 필드

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

`entryPoints`는 Stable Function 이름의 **요약 인덱스**다. 함수의 실제 의미는 `system-function-contracts.json`이 소유하며 Validator가 이름 목록을 1:1 일치시킨다.

`legacyCandidates`는 참고할 이전 Source 경로이며 재사용 의무가 아니다. Legacy Candidate를 사용하더라도 Legacy 파일 자체를 수정하지 않고 Greenfield 경로에 현재 Contract에 맞게 구현한다.

## 7. Stable Function Contract

다른 Contract-bearing Module이 호출하는 함수는 반드시 구현 전에 `system-function-contracts.json`에 선언한다.

각 Stable Function은 최소 다음 의미를 가진다.

```text
name
kind
purpose
inputs
output
authority
reads
writes
sideEffects
failureModes
idempotency
validation
permission
revisionBehavior
```

Cross-module 호출인데 Function Contract가 없으면 `CONTRACT_DRIFT`다.

`WorldState.transact`, `ProjectionReplica.subscribe`, `SemanticInputRouter.subscribe`, `SelectionController.subscribe`처럼 시스템 연결에 필요한 API도 Stable Boundary로 명시한다. Codex가 구현 편의상 숨은 cross-module method를 만드는 방식은 허용하지 않는다.

정확한 정의는 `SYSTEM-FUNCTION-CONTRACTS.md`를 따른다.

## 8. Private/Internal Implementation

다음은 GitHub Stable Contract로 미리 선언하지 않는다.

- 한 Module 안에서만 쓰는 local/private helper
- helper 개수/이름
- 정확한 private call order
- 모든 `require()`를 복제한 수동 call graph
- 구현 전에 필요성이 확인되지 않은 미래 API

Stable Contract가 유지되는 한 이 내부 분해는 Codex가 현재 Source와 Studio 결과를 보고 결정한다.

다른 Module이 private helper를 호출하게 되는 순간 더 이상 private가 아니므로 Stable Function Contract를 먼저 추가해야 한다.

## 9. 안전 경계

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

Function Contract가 이 안전 경계를 약화할 수 없다.

## 10. Source 정합화

`IMPLEMENTED` 또는 `ACCEPTED` Module은:

- `greenfield/src/` 아래 Source가 존재한다.
- Module의 모든 Stable Function token이 Source에 존재한다.
- `entryPoints`와 Function Contract name 목록이 정확히 일치한다.
- `dependsOn` 대상이 Registry에 존재한다.
- 선언된 Focused Test가 있으면 실제 파일이 존재한다.

`ACCEPTED` Module은 최소 하나의 `greenfield/tests/` Focused Test를 가진다.

Rojo 재현은 Legacy `default.project.json`이 아니라 `greenfield.project.json`을 기준으로 확인한다.

사용자 확정으로 System flow, Module 책임, Stable Function 의미가 바뀌었다면 Source만 바꾸지 않는다. Authority Impact Scan을 수행하고 영향을 받는 상위 Authority와 Code Contract를 위에서 아래로 정합화한다.

## 11. Validator가 강제하는 것

`validate_module_contracts.py`는 기존 Module/Stage/Checkpoint/Safety 검증에 더해 다음을 검사한다.

- 모든 현재 Module에 Function Contract record가 정확히 하나 존재.
- 모든 현재 Module이 최소 하나의 System Contract에 포함됨.
- System Contract가 존재하는 Module만 참조함.
- `Module.entryPoints == Function Contract names`.
- Function kind/authority/idempotency 및 필수 의미 필드가 유효함.
- Stable Function Authority가 Module Authority와 어긋나지 않음.
- IMPLEMENTED/ACCEPTED Source에서 Stable Function token이 사라지지 않음.

Validator는 private helper 이름이나 private call graph를 검사하지 않는다.

## 12. Architecture 변경

Module 책임 분리/통합, System flow, Stage 순서, Authority, Command/Projection 방향, Greenfield/Legacy 경계를 바꾸려면 사용자에게 먼저 제안한다.

기존 Architecture 안에서 필요한 명백한 Stable API 보완은 Function Contract를 먼저 갱신한 뒤 구현할 수 있다. 그러나 그 API가 Authority, state owner 또는 Module 책임을 바꾸면 자동 적용하지 않는다.

사용자가 화면/조작 결과를 수용한 것을 미승인 내부 Architecture 변경의 승인으로 확대 해석하지 않는다.
