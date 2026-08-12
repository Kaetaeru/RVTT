# RVTT Roblox Implementation Workspace

- 상태: `R3_VALIDATED · NOT_FROZEN · SOURCE_BLOCKED · STUDIO_BLOCKED`
- 현재 실행 권위: [`../../AGENTS.md`](../../AGENTS.md) → [`.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 구현 모델: [`IMPLEMENTATION-MODEL.md`](IMPLEMENTATION-MODEL.md)
- System 권위: [`SYSTEMS.md`](SYSTEMS.md)

이 디렉터리는 현재와 과거의 Roblox Source/Test/Tooling을 함께 보존한다. **파일이 존재한다는 이유만으로 현재 구현 권위나 재사용 대상이 되지 않는다.**

## 현재 읽기 순서

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ IMPLEMENTATION-MODEL.md
→ SYSTEMS.md
→ current machine-readable manifests
```

현재 상태는 `R3_VALIDATED_AWAITING_FREEZE_DECISION`이다. Source와 Studio/MCP 구현을 시작하지 않는다.

## Source 경계

```text
src/**
= 기존 Production Source
= READ_ONLY_REFERENCE
= 새 Greenfield 구현 baseline 아님
= 자동 재사용 금지

greenfield/src/**
= 새 Greenfield Source root
= 현재 비어 있음
= R3/R4 동안 BLOCKED
```

`default.project.json`과 기존 `src/**`는 legacy reference/regression surface로 잠겨 있다. 새 구현은 R3 Freeze 후 R4 E0 Checkpoint를 확정하고 Dedicated Implementation Branch를 만든 뒤 `greenfield/src/**`에서 시작한다.

## 현재 실행 순서

```text
R3 validation complete
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Repository Core Engine 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Checkpoint Freeze
→ Studio/MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ E2 Presentation / Feel
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 구현은 금지한다.**

## Studio/MCP 역할

Studio/MCP는 폐기하지 않는다. E1에서 Roblox-dependent provider와 실제 DataModel integration을 직접 구현·실행·관찰하는 핵심 개발 환경으로 사용한다. 다만 현재 R3/R4와 E0 이전에는 사용하지 않는다.

## CI 해석 주의

`Validate RVTT implementation` 등 기존 Source/Test Workflow는 잠긴 legacy `src/**` reference의 regression/재현성 검증이다. 그 성공은 새 Greenfield Source가 구현되었거나 `CORE_ENGINE_COMPLETE`를 달성했다는 뜻이 아니다.

## Retired 문서

`MODULE-CONTRACTS.md`, `SYSTEM-FUNCTION-CONTRACTS.md`, `GREENFIELD-EXECUTION-LAYERS.md`, `GREENFIELD-SYSTEM-SEQUENCE.md`, `GREENFIELD-PREFLIGHT.md` 등 `RETIRED_IMPLEMENTATION_MODEL` 표기가 있는 문서는 역사적 reference다. R4에서 새 Module/Stable Function/Checkpoint를 처음부터 도출한다.
