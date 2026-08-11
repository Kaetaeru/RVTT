# RVTT Greenfield Pre-G0 Workbench Gate

- 상태: `ACTIVE · PRE_G0_EXECUTION_GATE`
- 최종 갱신일: 2026-08-12
- 적용 범위: G0 구현을 시작하기 직전 Repository·Rojo·Studio MCP 작업장 확인
- 시스템 순서 권위: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Build 정책: [`GREENFIELD-BUILD-POLICY.md`](GREENFIELD-BUILD-POLICY.md)
- 기계 검증: [`tooling/validate_greenfield_boundary.py`](tooling/validate_greenfield_boundary.py)
- Boundary 설정: [`greenfield-boundary.json`](greenfield-boundary.json)

이 Gate는 새로운 Foundation Stage가 아니다. `G0_SHARED_CONTRACTS`보다 먼저 **작업장과 실행 Capability가 올바른지 확인**하기 위한 준비 단계다.

## 1. 고정 작업장

Greenfield Build의 현재 작업장은 다음으로 고정한다.

```text
Rojo Project  = implementation/roblox/greenfield.project.json
Source Root   = implementation/roblox/greenfield/src
Test Root     = implementation/roblox/greenfield/tests
Module Map    = implementation/roblox/manifests/module-contracts.json
```

기존 Production 자산은 다음처럼 취급한다.

```text
implementation/roblox/src
implementation/roblox/default.project.json
= LEGACY · READ_ONLY_REFERENCE
```

Legacy Source를 읽는 것은 허용한다. Greenfield 구현을 위해 Legacy Source를 직접 수정하거나 `default.project.json`에 새 Build를 얹는 것은 금지한다.

재사용할 코드가 있으면 내용을 읽고 **Greenfield 책임에 맞는 새 경로로 선택적으로 옮긴다.** Legacy 파일 자체를 현재 구현으로 승격하지 않는다.

## 2. Repository Gate

G0 시작 전 다음이 모두 만족되어야 한다.

1. `greenfield.project.json`이 존재한다.
2. 모든 Rojo `$path`가 `greenfield/src/` 아래만 가리킨다.
3. `greenfield/src`와 `greenfield/tests`가 존재한다.
4. `module-contracts.json.sourceRoot == greenfield/src`다.
5. Legacy `src` Git tree가 Greenfield Lock 시점과 동일하다.
6. Legacy `default.project.json` Git blob이 Greenfield Lock 시점과 동일하다.
7. `validate_greenfield_boundary.py`가 PASS한다.
8. `validate_module_contracts.py`가 PASS한다.
9. `rojo build greenfield.project.json`이 독립적으로 성공한다.

현재 Legacy Lock 기준은 `greenfield-boundary.json`이 소유한다. Lock 값을 바꾸는 행위는 단순 구현 편의가 아니라 Legacy 쓰기 정책 변경이므로 사용자 승인 없이 수행하지 않는다.

## 3. Studio Workbench Gate

G0를 구현할 Studio는 기존 Production Place를 이어 고치는 작업장으로 취급하지 않는다.

첫 Studio 접근에서 Codex는 먼저 현재 Place/Session을 식별한다.

- 기존 Legacy RVTT가 들어 있는 Production Place를 Baseline으로 보고 수정 시작 → 금지
- Greenfield 전용 빈 Workbench/Session에서 시작 → 허용
- 현재 Place가 어느 쪽인지 판별 불가 → `BLOCKED` 또는 `HUMAN_REQUIRED`

기존 Place를 참고해야 하면 읽기 Evidence로만 사용하고, Greenfield 결과는 `greenfield.project.json`과 `greenfield/src`에서 재현 가능해야 한다.

## 4. MCP Capability Handshake

실제 제공 Tool 이름을 추측하지 않는다. G0 시작 직전 아래 Capability를 확인하고 각각 분류한다.

```text
MCP_AVAILABLE
HUMAN_REQUIRED
UNAVAILABLE
```

| Capability | G0 시작 판단 |
|---|---|
| Place / Session identity 확인 | 필수 |
| Instance Tree 읽기 | 필수 |
| Instance 생성·수정·삭제 | Studio-first 구현에 필수 |
| Script Source 읽기 | 필수 |
| Script Source 수정 | Studio-first 구현에 필수 |
| Play Start / Stop | 필수 |
| Server / Client Output 읽기 | 필수 |
| Property / Attribute 읽기 | 필수 |
| Screenshot / 화면 확인 | G0 비필수, 이후 UI Checkpoint에서 필요 |
| Multi-client 실행 | G0 비필수 |
| Local Save / Export | G0 비필수, Canonical Source 대체 불가 |

MCP Capability가 일부 없더라도 GitHub Source + Rojo + 일반 Studio 경로로 동일한 검증이 가능하면 `DEGRADED`로 진행할 수 있다. 다만 사용하지 못한 Capability를 사용한 것처럼 보고하지 않는다.

다음이면 G0를 시작하지 않는다.

- 현재 Place가 Legacy Baseline인지 Greenfield Workbench인지 판별할 수 없음
- Script Source를 어떤 경로로도 수정·정규화할 수 없음
- 실행 결과를 어떤 경로로도 Play/Output으로 확인할 수 없음
- Repository Boundary 검증이 실패함

## 5. Pre-G0 결과 형식

G0 구현을 시작하기 직전 Codex는 짧게 다음 상태를 남긴다.

```text
PRE-G0 REPOSITORY
- greenfield boundary: PASS|FAIL
- module contracts: PASS|FAIL
- greenfield rojo build: PASS|FAIL
- legacy source lock: PASS|FAIL

STUDIO WORKBENCH
- place/session: GREENFIELD|LEGACY|UNKNOWN

MCP CAPABILITIES
- required available: [...]
- human required: [...]
- unavailable: [...]

PRE-G0 RESULT
- READY_FOR_G0|DEGRADED_READY|BLOCKED

NEXT ACTION
- G0_SHARED_CONTRACTS 또는 blocker
```

## 6. G0 Handoff

Repository Gate와 Studio/MCP Handshake가 허용 상태이면 그 다음 행동은 정확히 하나다.

```text
G0_SHARED_CONTRACTS
```

이 문서 준비 과정에서는 `CommandEnvelope`, `ProjectionEnvelope`, `WorldContract` Source를 만들지 않는다. G0 구현은 다음 실행에서 시작한다.

## 7. 변경 보호

Preflight 중 더 나은 Architecture, Authority, 시스템 순서, 개발 방식이 보이면 직접 바꾸지 않는다. 현재 문제·대안·효과·비용·영향받는 Authority를 사용자에게 먼저 보고한다.
