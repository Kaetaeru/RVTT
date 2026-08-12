# RVTT Remake 현재 작업 순서

- 상태: `ACTIVE · CONTEXT_ONLY · R3_VALIDATED_AWAITING_FREEZE_DECISION`
- 최종 갱신일: 2026-08-13
- 현재 실행 포인터: [`.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)

## 현재 결정

기존 Product·Accepted ADR·Current Architecture·Global UI 요구는 제품 권위로 보존한다. Roblox 구현은 Greenfield로 처음부터 재구축하며 기존 Production Source는 `READ_ONLY_REFERENCE`다.

현재 실행 순서는 이 문서의 과거 Slice/Module 순서가 아니라 Active Task와 `implementation/roblox/IMPLEMENTATION-MODEL.md`가 소유한다.

## 현재 상태

```text
34 Systems / 30 Requirement Capabilities / 61 Scenarios
R3 semantic + authority hygiene validation = COMPLETE
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

## 현재 구현 순서

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

과거 `Greenfield Module Contract → Foundation → S1/C1/M1/X1/I1` 순서는 폐기된 Greenfield implementation model의 historical context다. 현재 TODO나 구현 순서로 사용하지 않는다.

## 이후 기능군

Character, Encounter, Inventory, Downtime, Journal, DM, Content, Logistics, Actor Authoring 등은 현재 System Model의 future compatibility pressure다. 실제 구현 scope와 checkpoint 순서는 R4에서 JIT로 확정한다.

## Historical Tooling

기존 Acceptance, Grand, Persistence, Production Source와 과거 Runtime Evidence는 regression/reference evidence다. 새 Greenfield 구현의 현재 PASS를 대신하지 않는다.
