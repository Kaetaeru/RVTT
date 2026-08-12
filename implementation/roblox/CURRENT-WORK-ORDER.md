# RVTT Roblox Implementation 현재 작업 순서

- 상태: `R3_VALIDATED_AWAITING_FREEZE_DECISION`
- 최종 갱신일: 2026-08-13
- 현재 실행 권위: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 구현 모델: [`IMPLEMENTATION-MODEL.md`](IMPLEMENTATION-MODEL.md)
- System 권위: [`SYSTEMS.md`](SYSTEMS.md)
- Coverage Policy: [`ARCHITECTURE-COVERAGE-POLICY.md`](ARCHITECTURE-COVERAGE-POLICY.md)

## 현재 상태

34 System / 30 Requirement Capability / 61 Scenario R3 모델과 semantic/authority hygiene 검증이 완료됐다. R3는 아직 Freeze되지 않았다.

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

기존 Greenfield 25 Module / 10 System / 64 Stable Function 실행 모델은 `RETIRED_IMPLEMENTATION_MODEL`이다. 기존 `src/**`는 `READ_ONLY_REFERENCE`이며 새 구현 baseline이 아니다.

## 다음 순서

```text
사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Repository Core Engine 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ E2 Presentation / Feel
```

현재 단계에서는 Source 파일 생성/수정, Studio/MCP 구현, 새 Module/Stable Function 대량 확정을 하지 않는다.

## Canonical planning inputs

```text
IMPLEMENTATION-MODEL.md
SYSTEMS.md
manifests/implementation-system-model.json
manifests/scenario-semantic-audit-v3.json
manifests/scenario-semantic-audit.json
manifests/scenario-base-catalog.json
manifests/scenario-expanded-catalog.json
```

Retired Greenfield contracts와 historical Scenario/coverage registries는 근거 추적용 reference일 뿐 현재 구현 입력으로 사용하지 않는다.
