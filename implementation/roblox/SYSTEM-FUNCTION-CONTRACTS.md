# RVTT System & Stable Function Contracts

- 상태: `ACTIVE · GREENFIELD_CODE_BOUNDARY_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Registry: [`manifests/system-function-contracts.json`](manifests/system-function-contracts.json)
- Module Registry: [`manifests/module-contracts.json`](manifests/module-contracts.json)
- Execution Registry: [`manifests/execution-layers.json`](manifests/execution-layers.json)
- Execution Policy: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)

이 문서는 시스템 책임과 다른 Module이 의존할 수 있는 **Stable Function의 의미**를 소유한다. 어느 환경에서 구현/테스트할지는 Execution Layer가 소유한다.

## 1. 설계 깊이

```text
System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class
→ Private/Internal Implementation
```

- System Contract: responsibility, authority, state owner, input/output, invariant, module flow.
- Module Contract: file boundary, dependency, authority, state ownership, stable entry-point index.
- Stable Function Contract: input/output, read/write, side effect, failure, permission, revision semantics.
- Execution Class: Repository / Studio runtime / Human review 중 어느 검증이 필요한지.
- Private/Internal: helper, local structure, private call graph.

## 2. 선언 시점

구현보다 계약이 먼저다.

```text
현재/다음 Product 범위 확정
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Execution Class 확인
→ Validator
→ Source 구현
```

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

API 보완이 기존 책임 안의 명백한 변화면 Contract를 먼저 갱신하고 구현한다.

Authority/state owner/Module responsibility/System flow를 바꾸면 사용자에게 먼저 제안한다.

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

## 6. Execution Layer와 함수 테스트

Stable Function을 전부 같은 방식으로 테스트하지 않는다.

### CORE_ENGINE

예: `WorldState.transact`, `AuthorizationService.authorize`, `CommandRuntime.execute`, `ProjectionService.buildForViewer`.

Repository에서 정상/실패/경계/negative case를 반복 가능한 test로 검증한다.

### ROBLOX_RUNTIME_ENGINE

예: 향후 PathfindingService adapter 같은 Runtime 의존 함수.

함수 Contract 자체는 GitHub에 존재하고, 실제 Roblox Service 결과는 Studio automated harness에서 검증한다.

### ROBLOX_INTEGRATION

예: Gateway/Replica/Input adapter lifecycle.

Remote/Player/Instance/Input 연결을 Studio에서 자동 검증한다.

### PRESENTATION_FEEL

사용자가 내부 함수 하나하나를 검증하는 것이 아니다. Studio self-check 후 실제 화면/조작감으로 Checkpoint를 평가한다.

## 7. Pathfinding 함수 계약 원칙

Pathfinding을 도입할 때 함수 계약을 다음처럼 섞지 않는다.

```text
pure policy / request/result semantics
→ Repository-testable Stable Function

PathfindingService / navmesh / raycast result
→ ROBLOX_RUNTIME_ENGINE Stable Function

preview / click response / smoothing
→ Presentation controller behavior
```

구체 함수 이름/API는 Movement Checkpoint 직전에 확정한다.

## 8. Module Surface

- `CALLABLE_MODULE`: Stable Function 존재.
- `DATA_ONLY_MODULE`: runtime callable API 없음.
- `AUTO_EXEC_SCRIPT`: Roblox Script/LocalScript entrypoint. gameplay public API 없음.

Bootstrap은 AUTO_EXEC_SCRIPT다.

## 9. entryPoints

`module-contracts.json.entryPoints`는 이름 요약 인덱스다.

```text
Module.entryPoints
== 해당 Module Function Contract name 목록
```

함수 의미 Authority는 `system-function-contracts.json`이다.

## 10. 구현 자유도

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

## 11. 사용자 수정과 확정

사용자 반복 수정은 주로 PRESENTATION_FEEL에 적용한다.

보이지 않는 Engine/Integration은 자동 테스트 결과를 기준으로 수정한다.

사용자가 visible behavior를 최종 수용하면 Authority Reconciliation에서 System/Module/Stable Function/Execution Layer와 최종 Source를 함께 확인한다.

## 12. Validator

`validate_module_contracts.py`는 System/Module/Stable Function 정합성을 검사한다.

`validate_execution_layers.py`는 현재 Module의 Execution Class, Phase coverage, Checkpoint order, Environment-specific Test Gate를 검사한다.

Validator는 private helper 이름이나 private call graph를 검사하지 않는다.
