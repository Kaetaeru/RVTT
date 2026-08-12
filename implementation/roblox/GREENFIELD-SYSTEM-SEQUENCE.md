# RVTT Greenfield System Sequence

- 상태: `RETIRED_IMPLEMENTATION_MODEL`
- 퇴역일: 2026-08-13
- 대체 권위: [`IMPLEMENTATION-MODEL.md`](IMPLEMENTATION-MODEL.md)

기존 G0~G5와 Greenfield E0/E1 Module 순서는 현재 Build Order가 아니다.

현재 순서 권위는 다음이다.

```text
R0 Requirement Distillation
→ R1 Whole-product System Model From Scratch
→ R2 61 Scenario Pressure Review
→ R3 Core/Runtime/Presentation Boundary Freeze
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Engine / Integration
→ INTEGRATION_READY
→ U0 Product UI Shell Session
→ UI_SHELL_READY
→ E2 User-facing Checkpoint JIT
```

새 System/Module 순서는 R1~R4 결과로 다시 만든다.

기존 순서는 Git history의 참고 증거일 뿐 자동 승계하지 않는다.
