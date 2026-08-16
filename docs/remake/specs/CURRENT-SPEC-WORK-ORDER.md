# RVTT Implementation Specs 현재 상태

- 상태: `REFERENCE_BASELINE_COMPLETE · NOT_CURRENT_IMPLEMENTATION_AUTHORITY`
- 최종 갱신일: 2026-08-13
- 상위 작업 순서: [`../CURRENT-WORK-ORDER.md`](../CURRENT-WORK-ORDER.md)
- 현재 구현 권위: [`../../../implementation/roblox/IMPLEMENTATION-MODEL.md`](../../../implementation/roblox/IMPLEMENTATION-MODEL.md)

## 역할

이 문서는 16개 Slice Baseline Spec과 ADR Delta의 준비·역사 상태를 기록한다. **현재 Runtime 개발 순서, Module split, Stable Function, Source/Studio 시작 시점을 소유하지 않는다.**

기존 Spec은 Product/Architecture 요구를 추적하는 reference corpus로 사용할 수 있지만, 폐기된 Greenfield 구현 모델의 Module/Type/Command/Execution 구조를 새 구현에 자동 재사용하지 않는다.

## 현재 상태

```text
16 Slice Baseline
→ HISTORICAL/REQUIREMENT REFERENCE COMPLETE

Current System Model
→ 34 Systems

Requirement Capability
→ 30

Clean Scenario
→ 61

R3
→ VALIDATED · NOT FROZEN

Source
→ NOT STARTED / BLOCKED

Studio/MCP
→ BLOCKED UNTIL CORE_ENGINE_COMPLETE
```

## 현재 인계 규칙

```text
사용자 R3 Freeze
→ R4 E0 Checkpoint Freeze
→ 현재 System/Requirement/Scenario pressure에서 Module/Stable Function JIT 도출
→ Dedicated Implementation Branch
→ E0 Repository 구현
→ CORE_ENGINE_COMPLETE
→ E1 Studio/MCP Runtime Integration
```

과거 `Studio-first handoff`, 기존 Source Mapping, Slice별 implementation sequence는 현재 실행 명령이 아니다.

## 사용 방법

R4에서 특정 Checkpoint를 설계할 때 필요한 Product/Architecture 요구를 확인하기 위한 근거로 선택적으로 읽는다. 현재 권위와 충돌하면 `AGENTS.md`, Active Task, Accepted ADR, Current Architecture, Current Implementation Model이 우선한다.
