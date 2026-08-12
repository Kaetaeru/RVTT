# RVTT System & Stable Function Contracts

- 상태: `ACTIVE · GREENFIELD_CODE_BOUNDARY_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Registry: [`manifests/system-function-contracts.json`](manifests/system-function-contracts.json)
- Module Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- Execution Registry: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Execution Policy: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)

이 문서는 Coverage에서 필요성이 확인된 시스템 책임과 다른 Module이 의존할 수 있는 **Stable Function의 의미**를 소유한다. 어느 환경에서 구현/테스트할지는 Execution Layer가 소유한다.

## 1. 설계 깊이

```text
Product / ADR / Architecture
→ Capability / Scenario Coverage
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Private/Internal Implementation
```

- Coverage: 중요한 책임 자체가 구현 계획에서 빠지지 않았는지 확인.
- System Contract: responsibility, authority, state owner, input/output, invariant, module flow.
- Module Contract: file boundary, dependency, authority, state ownership, stable entry-point index.
- Stable Function Contract: input/output, read/write, side effect, failure, permission, revision semantics.
- Execution Class: Repository / Studio runtime / Human review 중 어느 검증이 필요한지.
- Private/Internal: helper, local structure, private call graph.

## 2. 선언 시점

구현보다 Coverage와 계약이 먼저다.

```text
현재/다음 Product 범위
→ Architecture Coverage 확인
→ 해당 Phase Blocking Gap 없음
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class 확인
→ Validators
→ Source 구현
```

현재 Capability가 UNMAPPED/PARTIAL이고 해당 Phase를 막는 Gap이 있으면 기존 Module에 임시 함수만 추가해 구현하지 않는다.

그 다음 실행은 Module 종류에 따라 갈린다.

```text
CORE_ENGINE
→ Repository automated tests

ROBLOX_RUNTIME_ENGINE
→ Studio automated runtime tests

ROBLOX_INTEGRATION
→ Studio automated integration tests

PRESENTATION_FEEL
→ Studio self-check + Human Acceptance
```

## 3. Stable Function 기준

다음은 Stable Function이다.

- 다른 Contract-bearing Module이 호출함.
- App/Bootstrap이 lifecycle/composition을 위해 호출함.
- Test가 안정 경계로 직접 호출함.
- Authority/Transport/Projection/Persistence/Runtime Engine boundary를 통과함.
- 반환값/side effect/failure/revision 의미가 Architecture 일부임.

다음은 Stable Function이 아니다.

- 한 Module 내부 local/private helper.
- 구현 편의용 작은 변환 함수.
- 호출 그래프 설명을 위해 억지로 노출한 함수.
- 필요성이 확인되지 않은 미래 API.

## 4. Cross-Module 규칙

Contract-bearing Module A가 B의 함수를 호출하면 B의 Function Contract가 먼저 존재해야 한다.

```text
undeclared cross-module call
= CONTRACT_DRIFT
```

API 보완이 기존 승인된 책임 안의 명백한 변화면 Contract를 먼저 갱신하고 구현할 수 있다.

하지만 Coverage Gap이 보여주는 새 Responsibility, Authority/state owner/Module responsibility/System flow 변경이라면 사용자에게 먼저 제안한다.

## 5. Function Contract 필드

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

Function Contract는 Execution Class와 무관하게 동일한 의미를 가져야 한다. Studio에서 구현했다는 이유로 API 의미가 달라지지 않는다.

## 6. Coverage와 Function Contract 관계

Function Contract는 Product Coverage의 최하위 설계 경계다.

```text
Capability / Scenario
→ System responsibility
→ Module responsibility
→ Stable Function
```

다음을 금지한다.

```text
UNMAPPED Capability
→ 기존 Module에 임의 method 추가
→ Source 구현
```

대신:

```text
UNMAPPED/PARTIAL Capability
→ Gap
→ 사용자 Architecture 결정
→ System/Module/Function Contract 정합화
→ Source
```

현재 `system-function-contracts.json`의 10개 System/64개 Stable Function은 Initial Coverage Audit 전의 Greenfield 계획이다. Gap 해결 전 Source 구현 권위로 직접 사용하지 않고, 사용자 결정 뒤 필요한 범위만 정합화한다.

## 7. Execution Layer와 함수 테스트

Stable Function을 전부 같은 방식으로 테스트하지 않는다.

### CORE_ENGINE

Repository에서 정상/실패/경계/negative case를 반복 가능한 test로 검증한다.

### ROBLOX_RUNTIME_ENGINE

함수 Contract 자체는 GitHub에 존재하고, 실제 Roblox Service 결과는 Studio automated harness에서 검증한다.

### ROBLOX_INTEGRATION

Remote/Player/Instance/Input 연결을 Studio에서 자동 검증한다.

### PRESENTATION_FEEL

사용자가 내부 함수 하나하나를 검증하는 것이 아니다. Studio self-check 후 실제 화면/조작감으로 Checkpoint를 평가한다.

## 8. Pathfinding 함수 계약 원칙

현재 Coverage `GAP-005`가 OPEN이므로 구체 Pathfinding 함수 이름/API를 만들지 않는다.

Gap 해결 뒤:

```text
pure policy / request/result semantics
→ Repository-testable Stable Function

Roblox navigation provider / PathfindingService / navmesh / spatial result
→ ROBLOX_RUNTIME_ENGINE Stable Function

preview / click response / smoothing
→ Presentation controller behavior
```

## 9. Module Surface

- `CALLABLE_MODULE`: Stable Function 존재.
- `DATA_ONLY_MODULE`: runtime callable API 없음.
- `AUTO_EXEC_SCRIPT`: Roblox Script/LocalScript entrypoint. gameplay public API 없음.

Bootstrap은 AUTO_EXEC_SCRIPT다.

## 10. entryPoints

`module-contracts.json.entryPoints`는 이름 요약 인덱스다.

```text
Module.entryPoints
== 해당 Module Function Contract name 목록
```

함수 의미 Authority는 `system-function-contracts.json`이다.

## 11. 구현 자유도

Stable Contract가 같다면 Codex가 자유롭게 결정할 수 있다.

- private/local helper
- 내부 자료구조
- 순수 계산 분해
- local cache
- 같은 Module 내부 호출 순서

자유도가 아닌 것:

- Stable Function 의미/입출력 변경
- Authority/state owner 변경
- 새 side effect 추가
- failure semantics 변경
- revision semantics 변경
- private helper를 cross-module API로 사용
- Coverage Gap을 private implementation으로 숨김

## 12. 사용자 수정과 확정

사용자 반복 수정은 주로 PRESENTATION_FEEL에 적용한다.

보이지 않는 Engine/Integration은 자동 테스트 결과를 기준으로 수정한다.

사용자가 visible behavior를 최종 수용하면 Authority Reconciliation에서 Coverage Capability/Scenario/Gap, System/Module/Stable Function/Execution Layer와 최종 Source를 함께 확인한다.

## 13. Validator

`validate_architecture_coverage.py`는 Product Capability/Scenario/Gap과 현재 System/Module mapping을 검사한다.

`validate_module_contracts.py`는 System/Module/Stable Function 정합성을 검사한다.

`validate_execution_layers.py`는 Module Execution Class, Phase coverage, Checkpoint order, Environment-specific Test Gate를 검사한다.

Validator는 private helper 이름이나 private call graph를 검사하지 않는다.
