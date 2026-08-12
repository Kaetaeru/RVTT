# RVTT Greenfield Preflight Gates

- 상태: `ACTIVE · EXECUTION_PREFLIGHT_AUTHORITY`
- 최종 갱신일: 2026-08-13
- Execution Layers: [`GREENFIELD-EXECUTION-LAYERS.md`](GREENFIELD-EXECUTION-LAYERS.md)
- System Sequence: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Boundary Validator: [`tooling/validate_greenfield_boundary.py`](tooling/validate_greenfield_boundary.py)
- Execution Validator: [`tooling/validate_execution_layers.py`](tooling/validate_execution_layers.py)

Preflight를 두 개로 분리한다.

```text
E0 Repository Engine Gate
→ Core Engine 구현·Repository Test
→ E1 Studio Integration Gate
→ Runtime Integration
```

Core Engine을 시작하기 위해 Studio/MCP가 먼저 준비되어 있을 필요는 없다.

## 1. 고정 작업장

```text
Rojo Project  = implementation/roblox/greenfield.project.json
Source Root   = implementation/roblox/greenfield/src
Test Root     = implementation/roblox/greenfield/tests
Legacy Source = implementation/roblox/src · READ_ONLY_REFERENCE
Legacy Project= implementation/roblox/default.project.json · READ_ONLY_REFERENCE
```

모든 최종 Source는 `greenfield/src`가 권위다.

## 2. E0 Repository Engine Gate

Core Engine 구현을 시작하기 전 다음만 필수다.

1. `greenfield.project.json` 존재.
2. Rojo `$path`가 `greenfield/src` 아래만 가리킴.
3. `greenfield/src`와 `greenfield/tests` 존재.
4. Legacy Source/Project lock 유지.
5. `validate_greenfield_boundary.py` PASS.
6. `validate_module_contracts.py` PASS.
7. `validate_execution_layers.py` PASS.

Rojo build는 가능하면 여기서도 확인하지만, Studio/MCP identity나 Play capability는 E0 시작 blocker가 아니다.

E0 결과:

```text
REPOSITORY ENGINE GATE
- greenfield boundary: PASS|FAIL
- module/system/function contracts: PASS|FAIL
- execution layers: PASS|FAIL
- legacy lock: PASS|FAIL

RESULT
- READY_FOR_E0|BLOCKED
```

`READY_FOR_E0`이면 Core Engine Source와 repository automated tests를 시작한다.

## 3. E0에서 하지 않는 것

- Studio Place identity 확인을 이유로 Core Engine 구현을 미룸.
- MCP capability가 없다는 이유로 pure Authority/State/Command/Projection/Domain test를 미룸.
- 사용자가 Engine 함수를 수동 Console로 검증하도록 요구.

## 4. E1 Studio Integration Gate

Core Engine repository gate를 통과하고 Runtime Integration을 시작하기 직전에 Studio를 확인한다.

필수:

1. `rojo build greenfield.project.json` 성공.
2. 현재 Place/Session이 Greenfield Workbench인지 확인.
3. Legacy Production Place를 Baseline으로 수정하지 않음.
4. 필요한 MCP/Studio capability 확인.
5. Play Start/Stop 및 Server/Client Output을 확인할 경로가 있음.
6. Runtime/Integration automated harness를 실행할 경로가 있음.

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

## 5. E1 결과

```text
STUDIO INTEGRATION GATE
- greenfield rojo build: PASS|FAIL
- place/session: GREENFIELD|LEGACY|UNKNOWN
- required runtime capabilities: PASS|DEGRADED|FAIL
- play/output path: PASS|FAIL

RESULT
- READY_FOR_E1|DEGRADED_READY|BLOCKED
```

`READY_FOR_E1` 또는 fallback이 명확한 `DEGRADED_READY`일 때 Runtime Integration을 시작한다.

## 6. Runtime-coupled Engine

PathfindingService, raycast, physics/collision처럼 실제 Roblox Runtime에 의존하는 Engine은 E1 Studio Gate 이후 구현·튜닝할 수 있다.

단:

- Contract는 GitHub에 먼저 존재.
- 최종 Source는 `greenfield/src`에 canonicalize.
- Studio automated runtime test가 필요.
- visible feel만 Human Checkpoint로 넘긴다.

## 7. E2 Presentation Gate

사용자에게 기능을 보여주기 전:

- 해당 Core Engine ready.
- 필요한 Runtime Engine/Integration ready.
- Studio self-check PASS.
- 실제 visible behavior 존재.

그 뒤에만 `READY_FOR_USER`다.

## 8. 변경 보호

Preflight 중 Execution Class, Architecture, Authority, Module responsibility 또는 개발 방식 변경이 필요하면 사용자에게 먼저 제안한다.
