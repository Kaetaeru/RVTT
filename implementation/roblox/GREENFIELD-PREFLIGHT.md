# RVTT Greenfield Preflight Gates

- 상태: `ACTIVE · EXECUTION_PREFLIGHT_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Architecture Coverage: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)
- Coverage Registry: [`manifests/architecture-coverage.json`](manifests/architecture-coverage.json)
- Coverage Validator: [`tooling/validate_architecture_coverage.py`](tooling/validate_architecture_coverage.py)
- Execution Layers: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- System Sequence: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Boundary Validator: [`tooling/validate_greenfield_boundary.py`](tooling/validate_greenfield_boundary.py)
- Execution Validator: [`tooling/validate_execution_layers.py`](tooling/validate_execution_layers.py)

Preflight를 세 개로 분리한다.

```text
P0 Architecture Coverage Gate
→ E0 Repository Engine Gate
→ Core Engine 구현·Repository Test
→ E1 Studio Integration Gate
→ Runtime Integration
```

Core Engine을 시작하기 위해 Studio/MCP가 먼저 준비되어 있을 필요는 없지만, **Architecture Coverage Gate는 먼저 통과해야 한다.**

## 1. 고정 작업장

```text
Rojo Project  = implementation/roblox/greenfield.project.json
Source Root   = implementation/roblox/greenfield/src
Test Root     = implementation/roblox/greenfield/tests
Legacy Source = implementation/roblox/src · READ_ONLY_REFERENCE
Legacy Project= implementation/roblox/default.project.json · READ_ONLY_REFERENCE
```

모든 최종 Source는 `greenfield/src`가 권위다.

## 2. P0 Architecture Coverage Gate

Source를 만들기 전에:

```text
python implementation/roblox/tooling/validate_architecture_coverage.py
```

확인 항목:

1. Product/ADR/Architecture/System/UI/Spec Authority Tree Snapshot이 현재 Checkout과 일치.
2. 현재 Module/System이 Product Capability에 매핑됨.
3. Representative Scenario가 존재하는 Capability만 참조.
4. Cross-cutting Matrix에 빈 항목이 없음.
5. 현재 Phase의 OPEN Blocking Gap이 무엇인지 명시돼 있음.
6. OPEN Blocker가 있는데 `implementationGate=READY`로 위장하지 않음.

중요:

Validator PASS와 구현 READY는 다르다.

```text
Validator PASS
+ implementationGate=BLOCKED
= Coverage 기록은 정합적이지만 Source 구현 금지
```

현재 Initial Audit 상태:

```text
implementationGate = BLOCKED_BY_FOUNDATION_COVERAGE_GAPS
E0 blockers = GAP-001, GAP-002, GAP-003, GAP-005, GAP-007, GAP-008
```

Gap은 사용자 결정 없이 Codex가 자동 해소하지 않는다.

P0 결과:

```text
ARCHITECTURE COVERAGE
- authority snapshot: PASS|FAIL
- coverage registry: PASS|FAIL
- current phase blocking gaps: [ids]
- implementationGate: READY_FOR_E0|BLOCKED_...

RESULT
- READY_FOR_E0_REPOSITORY_GATE|BLOCKED
```

## 3. E0 Repository Engine Gate

P0가 `READY_FOR_E0_REPOSITORY_GATE`인 경우에만 실행한다.

Core Engine 구현을 시작하기 전:

1. `greenfield.project.json` 존재.
2. Rojo `$path`가 `greenfield/src` 아래만 가리킴.
3. `greenfield/src`와 `greenfield/tests` 존재.
4. Legacy Source/Project lock 유지.
5. `validate_greenfield_boundary.py` PASS.
6. `validate_module_contracts.py` PASS.
7. `validate_execution_layers.py` PASS.
8. `validate_architecture_coverage.py` PASS 및 E0 phase blocker 없음.

Rojo build는 가능하면 여기서도 확인하지만, Studio/MCP identity나 Play capability는 E0 시작 blocker가 아니다.

E0 결과:

```text
REPOSITORY ENGINE GATE
- architecture coverage: READY
- greenfield boundary: PASS|FAIL
- module/system/function contracts: PASS|FAIL
- execution layers: PASS|FAIL
- legacy lock: PASS|FAIL

RESULT
- READY_FOR_E0|BLOCKED
```

`READY_FOR_E0`이면 Core Engine Source와 repository automated tests를 시작한다.

## 4. E0에서 하지 않는 것

- Coverage blocker를 코드로 우회.
- Spatial Query가 없는데 Controller/Domain에서 Workspace 직접 조회를 임시 정답으로 사용.
- Transaction/Event 경계가 미결인데 `WorldState.transact`를 전체 Architecture의 최종 Transaction Coordinator로 간주.
- Studio Place identity 확인을 이유로 Core Engine 구현을 미룸.
- MCP capability가 없다는 이유로 pure Engine test를 미룸.
- 사용자가 Engine 함수를 수동 Console로 검증하도록 요구.

## 5. E1 Studio Integration Gate

Coverage와 E0 Core Engine gate를 통과하고 Runtime Integration을 시작하기 직전에 Studio를 확인한다.

필수:

1. E1 phase Coverage blocker 없음.
2. `rojo build greenfield.project.json` 성공.
3. 현재 Place/Session이 Greenfield Workbench인지 확인.
4. Legacy Production Place를 Baseline으로 수정하지 않음.
5. 필요한 MCP/Studio capability 확인.
6. Play Start/Stop 및 Server/Client Output을 확인할 경로가 있음.
7. Runtime/Integration automated harness를 실행할 경로가 있음.

Capability는 다음처럼 분류한다.

```text
MCP_AVAILABLE
HUMAN_REQUIRED
UNAVAILABLE
```

E1에 필요한 대표 capability:

- Place/Session identity
- Instance Tree 읽기
- 필요한 Instance 생성/수정
- Script Source 읽기/수정 또는 GitHub/Rojo sync 경로
- Play Start/Stop
- Server/Client Output
- Property/Attribute 확인

Screenshot은 Presentation/Feel 전에는 필수가 아니다.

## 6. E1 결과

```text
STUDIO INTEGRATION GATE
- architecture coverage: READY
- greenfield rojo build: PASS|FAIL
- place/session: GREENFIELD|LEGACY|UNKNOWN
- required runtime capabilities: PASS|DEGRADED|FAIL
- play/output path: PASS|FAIL

RESULT
- READY_FOR_E1|DEGRADED_READY|BLOCKED
```

`READY_FOR_E1` 또는 fallback이 명확한 `DEGRADED_READY`일 때 Runtime Integration을 시작한다.

## 7. Runtime-coupled Engine

PathfindingService, raycast, physics/collision처럼 실제 Roblox Runtime에 의존하는 Engine은 해당 Coverage Gap과 Contract가 먼저 해결된 후 E1 Studio Gate에서 구현·튜닝할 수 있다.

단:

- Contract는 GitHub에 먼저 존재.
- 최종 Source는 `greenfield/src`에 canonicalize.
- Studio automated runtime test가 필요.
- visible feel만 Human Checkpoint로 넘긴다.

## 8. E2 Presentation Gate

사용자에게 기능을 보여주기 전:

- 해당 Checkpoint Coverage phase blocker 없음.
- 해당 Core Engine ready.
- 필요한 Runtime Engine/Integration ready.
- Studio self-check PASS.
- 실제 visible behavior 존재.

그 뒤에만 `READY_FOR_USER`다.

## 9. Authority Corpus 변경 시

Product/ADR/Architecture/System/UI/Spec이 바뀌면 Authority Tree SHA가 달라진다.

```text
Coverage Validator FAIL
→ 변경 Authority 검토
→ Capability/Scenario/Gap 영향 반영
→ 필요한 Architecture 결정
→ Coverage Snapshot 갱신
→ Validator PASS
```

Tree SHA만 갱신하고 영향 분석을 생략하지 않는다.

## 10. 변경 보호

Preflight 중 Coverage Gap 해결에 새로운 Architecture, Authority, Module responsibility, System flow 또는 개발 방식 변경이 필요하면 사용자에게 먼저 제안한다.
