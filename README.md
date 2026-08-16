# RVTT

Roblox 기반의 DM 중심 D&D/TRPG 가상 테이블탑 프로젝트입니다.

현재 RVTT 리메이크는 **34 System / 30 Requirement Capability / 61 Scenario R3 모델 검증을 완료했고, 사용자 R3 Freeze 결정을 기다리는 단계**입니다.

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

## 현재 진입점

- [에이전트 작업 규약](AGENTS.md)
- [현재 실행 권위](.github/CODEX-ACTIVE-TASK.md)
- [RVTT Remake 문서 허브](docs/remake/README.md)
- [현재 작업 순서](docs/remake/CURRENT-WORK-ORDER.md)
- [현재 Roblox 구현 모델](implementation/roblox/IMPLEMENTATION-MODEL.md)
- [현재 System Authority](implementation/roblox/SYSTEMS.md)
- [Production Workspace](implementation/README.md)

Player·DM 목표 플레이 방식은 [한눈에 보는 Player·DM 세션 흐름](docs/remake/user-guides/QUICK-FLOW.md)과 역할별 User Guide를 참고합니다.

## 현재 개발 순서

```text
사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime / Studio MCP Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ E2 Presentation / Feel
```

기존 `25 Modules / 10 Systems / 64 Stable Functions / G0~G5` 구현 모델과 기존 `implementation/roblox/src/**`는 새 Greenfield 구현의 기본값이 아닙니다. legacy Source는 `READ_ONLY_REFERENCE`로 보존하고, 새 Source는 현재 gate가 열린 뒤 `implementation/roblox/greenfield/src/**`에서 시작합니다.

**CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않습니다.**
