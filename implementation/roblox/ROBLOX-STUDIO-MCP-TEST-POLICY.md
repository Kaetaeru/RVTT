# Roblox Studio MCP 개발·Runtime 정책

- 상태: `ACTIVE_FUTURE_E1_PATH · CURRENTLY_BLOCKED`
- 최종 갱신일: 2026-08-13
- 상위 규칙: [`../../AGENTS.md`](../../AGENTS.md)
- 현재 실행 권위: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 실행 규칙: [`EXECUTION-TEST-RULES.md`](EXECUTION-TEST-RULES.md)

## 1. 현재 Gate

현재 R3는 검증 완료 상태지만 Freeze되지 않았다.

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다.**

## 2. Studio/MCP의 미래 역할

Studio/MCP는 폐기된 방식이 아니다. E1에서 Roblox-dependent provider와 실제 DataModel integration을 직접 구현·실행·관찰하는 핵심 개발 환경이다.

활성화 순서:

```text
사용자 R3 Freeze
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP 활성화
```

## 3. E1 직접 구현 루프

E1에 들어간 뒤에는 다음 루프를 사용한다.

```text
GitHub Authority + frozen E1 contract 확인
→ Studio/MCP DataModel 조사
→ Roblox-dependent provider/integration 직접 구현
→ Play
→ 관찰
→ 수정
→ GitHub greenfield source/Rojo mapping 정규화
→ focused runtime test
```

Studio 결과가 GitHub Source와 Rojo에서 재현되지 않으면 완료가 아니다.

## 4. 금지

- R3/R4/E0 중 Studio를 Architecture discovery의 숨은 권위로 사용하지 않는다.
- 기존 Production Place/UI를 새 Greenfield baseline으로 사용하지 않는다.
- 기존 `src/**`를 자동 재사용하지 않는다.
- Studio에서만 존재하는 production logic을 남기지 않는다.
- Bootstrap에 gameplay/authority/input logic을 몰아넣지 않는다.

## 5. 허용되는 E1 범위

E1은 PathfindingService/NavMesh/raycast/collision/physics/Roblox transport/input/camera/streaming 등 Roblox runtime provider와 integration을 구현한다. 해당 provider가 소비할 contract/policy/state-machine은 E0에서 먼저 완성되어야 한다.
