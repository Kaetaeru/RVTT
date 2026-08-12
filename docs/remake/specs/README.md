# 구현 명세

- 상태: `REFERENCE_SPEC_CORPUS · NOT_CURRENT_IMPLEMENTATION_MODEL`
- 문서 종류: Implementation Spec Index
- 최종 갱신일: 2026-08-13
- Slice Specification Checkpoint: `16 / 16 HISTORICAL BASELINE COMPLETE`
- Current Greenfield Source: `NOT STARTED`

이 디렉터리는 16개 Slice Baseline Spec과 관련 Delta를 보존한다. 현재 구현자는 이 문서들의 Product/Architecture 요구와 edge case를 reference로 사용할 수 있지만, 과거 Module/Type/Command/Network/Execution split을 현재 구현 권위로 자동 재사용하지 않는다.

현재 구현 권위는 다음 순서다.

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ Product / Accepted ADR / Current Architecture / Global UI
→ implementation/roblox/IMPLEMENTATION-MODEL.md
→ implementation/roblox/SYSTEMS.md
→ current Scenario/Requirement/System manifests
```

## 현재 Gate

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

R3 Freeze 후 R4 E0 Checkpoint에서 현재 34-System / 30-Requirement / 61-Scenario 압력으로 Module/Stable Function을 JIT로 다시 도출한다.

## 핵심 진입점

- [`전체 Slice Roadmap`](SLICE-ROADMAP.md) — requirement/reference coverage
- [`16개 Slice Package Index`](slices/README.md) — reference package index
- [`Spec 현재 역할`](CURRENT-SPEC-WORK-ORDER.md)
- [`UI·UX Global Policies`](../ui/policies/README.md)
- [`Production Workspace`](../../../implementation/roblox/README.md)
- [`Current Implementation Model`](../../../implementation/roblox/IMPLEMENTATION-MODEL.md)

## 해석 규칙

- `READY`, `COMPLETE`, 과거 handoff 표기는 해당 시점의 spec 준비 상태다.
- 기존 Production Source/Studio 결과와 과거 Acceptance PASS는 새 Greenfield 구현 완료 증거가 아니다.
- current Architecture/Authority와 충돌하는 과거 implementation detail은 폐기한다.
- `CORE_ENGINE_COMPLETE` 전 Studio/MCP 구현을 시작하지 않는다.
