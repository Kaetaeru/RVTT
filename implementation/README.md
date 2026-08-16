# RVTT Production Implementation Workspace

- 상태: `CURRENT · R3_VALIDATED · SOURCE_NOT_STARTED`
- 최종 갱신일: 2026-08-13
- 현재 실행 권위: [`.github/CODEX-ACTIVE-TASK.md`](../.github/CODEX-ACTIVE-TASK.md)
- 현재 Roblox 구현 모델: [`roblox/IMPLEMENTATION-MODEL.md`](roblox/IMPLEMENTATION-MODEL.md)

이 폴더는 Production Source/Test/Migration/Build tooling을 보존한다. **기존 Source가 존재한다고 해서 새 Greenfield 구현 baseline이 되는 것은 아니다.**

```text
docs/remake/
→ Product / Accepted ADR / Architecture / UI / Guide / requirement-reference corpus

implementation/roblox/src/**
→ legacy Production Source
→ READ_ONLY_REFERENCE

implementation/roblox/greenfield/src/**
→ new Greenfield Source root
→ 현재 NOT STARTED / BLOCKED
```

## 현재 Gate

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

현재는 Slice 01 Script Manifest, retired Module Contract, G0 Script 구현을 시작하는 단계가 아니다.

## 현재 개발 순서

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

## 운영 원칙

1. 새 Greenfield Production Source는 current frozen Checkpoint와 Dedicated Implementation Branch가 준비된 뒤 `roblox/greenfield/src/**`에 작성한다.
2. legacy `roblox/src/**`와 `default.project.json`은 `READ_ONLY_REFERENCE`다.
3. Module/Stable Function은 R4 Checkpoint에서 current 34-System / 30-Requirement / 61-Scenario 압력으로 JIT 도출한다.
4. Client는 Domain Store/DataStore/authority result를 직접 소유하지 않는다.
5. Authority/Schema/Persistence/Remote 변경은 frozen contract와 focused tests를 함께 갱신한다.
6. CORE_ENGINE_COMPLETE 전 Studio/MCP 구현을 시작하지 않는다.
7. E1 Studio 결과는 GitHub greenfield Source와 Rojo mapping에서 재현 가능해야 한다.
8. legacy Regression PASS를 new Greenfield implementation PASS로 해석하지 않는다.

## 현재 하위 Workspace

- [`roblox/`](roblox/README.md) — current model, historical reference Source, Greenfield source root, Test/Build tooling
