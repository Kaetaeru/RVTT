# RVTT Current Executable Task

- executionAuthority: `ONLY_CURRENT_EXECUTABLE_TASK`
- status: `R3_BOUNDARY_FREEZE`
- commandId: `RVTT-R3-BOUNDARY-FREEZE-001`
- repository: `Kaetaeru/RVTT`
- pullRequest: `2`
- branch: `agent/survival-logistics-token-authoring`
- taskMode: `CORE_RUNTIME_PRESENTATION_BOUNDARY_FREEZE`
- sourceImplementationAllowed: `false`
- studioImplementationAllowed: `false`
- systemModel: `33_SYSTEM_V1_APPROVED`
- capabilityCatalog: `34_CAPABILITY_V2_ACTIVE`
- scenarioPressureReview: `61_OF_61_COMPLETE`
- updatedAt: `2026-08-13`

## 1. 기본 읽기 경로

Codex는 기본적으로 다음만 읽는다.

```text
1. AGENTS.md
2. .github/CODEX-ACTIVE-TASK.md
3. implementation/roblox/IMPLEMENTATION-MODEL.md
4. implementation/roblox/SYSTEMS.md
```

R3의 특정 책임을 검증할 때만 다음을 선택적으로 읽는다.

```text
implementation/roblox/audits/IMPLEMENTATION-MODEL-R2-SCENARIO-PRESSURE-001.md
implementation/roblox/manifests/architecture-scenarios.json
implementation/roblox/manifests/architecture-coverage.json   # legacy requirement evidence only
docs/remake/product/**
docs/remake/decisions/**
docs/remake/architecture/**
docs/remake/ui/**
```

기존 Greenfield System/Module/Stable Function/Execution 문서는 기본 읽기 대상이 아니다.

## 2. 승인된 현재 모델

현재 구현 System 권위:

```text
implementation/roblox/SYSTEMS.md
33 systems
34 capability v2
```

R2 결과:

```text
61/61 scenarios reviewed
0 empty responsibility path
0 old Greenfield module assumption
```

기존 22 Capability는 legacy coverage vocabulary다. 새 구현 경계는 `SYSTEMS.md`의 Capability v2와 System mapping을 사용한다.

## 3. 현재 목표 — R3

33개 System의 책임을 다음 세 층으로 나눈다.

```text
Repository Core Engine
Roblox Runtime Engine / Adapter
Presentation / Human Feel
```

System 전체를 하나의 층에 강제로 배치하지 않는다.

각 System에 대해 다음을 작성한다.

```text
Core responsibilities
Roblox-runtime responsibilities
Presentation/human responsibilities
External adapter seams
Forbidden cross-boundary shortcuts
Future consumers
Scenario pressure
Test evidence class
```

## 4. 분류 기준

### Repository Core Engine

Roblox Runtime 없이 correctness를 자동 검증할 수 있는 책임.

예:

- policy
- state machine
- schema / contract
- deterministic orchestration
- revision/identity rules
- pure calculation
- serialization-neutral domain logic
- failure semantics

### Roblox Runtime Engine / Adapter

Roblox 서비스나 geometry/runtime 결과가 correctness의 일부인 책임.

예:

- PathfindingService / NavMesh
- raycast / overlap / collision / physics
- Instance / Player lifecycle
- Remote transport adapter
- StreamingEnabled / materialization
- Roblox input adapter

### Presentation / Human Feel

실제 사용자에게 보이는 감각과 읽기성 검토가 필요한 책임.

예:

- final UI layout / shell feel
- VFX timing
- camera feel
- path preview readability
- movement perceived intent
- hover/highlight readability

## 5. 절대 순서

```text
R3 Boundary Freeze
→ R4 E0 Checkpoint Freeze
→ R5 Dedicated Implementation Branch
→ E0 Repository Core Engine 전체 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Studio/MCP Runtime Engine + Integration
→ INTEGRATION_READY
→ U0 HTML/UI distillation + full Product UI Shell
→ UI_SHELL_READY
→ E2 user-facing checkpoints
```

**CORE_ENGINE_COMPLETE 전 Studio/MCP 작업 금지.**

Pathfinding/Raycast/Physics도 Core contract/policy/failure seam을 먼저 확정하고 실제 Roblox Provider는 E1에서 만든다.

## 6. 미래 호환성

R3/R4는 현재 Foundation만 보지 않는다.

최소 미래 소비 압력:

```text
Character creation / level-up / sheet
Encounter / reaction / ready / death save
Inventory / equipment / consumables
Spell / dice / concentration / effects
Rest / travel / crafting / survival settlement
Journal / scene authoring / live DM
Content migration / actor authoring
Reconnect / restart / rollback / branch recovery
Streaming / accessibility / low-end fallback
```

미래 기능 자체를 구현하지 않되, 미래 기능 때문에 shared public boundary를 재작성해야 하는 구조는 Reject한다.

## 7. 지금 하지 않는 것

- Source 생성.
- Studio/MCP 진입.
- Module/Stable Function 대량 설계.
- Controller/Manager 이름 확정.
- 폐기된 Greenfield 계약 복원.
- 기존 GAP 번호를 맞추기 위한 System 왜곡.
- UI Shell 조기 제작.

## 8. 다음 행동

**R3 Boundary Matrix를 작성하고 61 Scenario pressure에 다시 대조한다.**

R3 결과는 사용자 검토 전 R4 Module/Stable Function/Source 권위를 만들지 않는다.
