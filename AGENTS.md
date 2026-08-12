# RVTT Agent Rules

- 상태: `CURRENT · SYSTEM_MODEL_V2_REPAIRED · R3_NOT_FROZEN`
- 최종 갱신일: 2026-08-13

## 1. 현재 실행 권위

기본 읽기 순서는 이것만 사용한다.

```text
사용자의 최신 명시적 지시
→ .github/CODEX-ACTIVE-TASK.md
→ implementation/roblox/IMPLEMENTATION-MODEL.md
→ implementation/roblox/SYSTEMS.md
→ implementation/roblox/manifests/implementation-system-model.json
→ 현재 R3/R4 audit 또는 Scenario Working Set
```

필요한 근거가 있을 때만 Product/Accepted ADR/Architecture/UI/Scenario 원문을 따라간다.

Archive, 과거 Codex Command, PR 댓글, 과거 Acceptance에서 현재 TODO를 복구하지 않는다.

## 2. 기존 Greenfield 구현 모델 폐기

다음 구현 모델은 현재 권위가 아니다.

```text
25 modules
10 systems
64 stable functions
G0~G5
기존 E0/E1 module classification
기존 greenfield controller/service wiring
WorldState.transact 중심 모델
```

관련 문서/Registry는 `RETIRED_IMPLEMENTATION_MODEL` 또는 historical reference로만 취급한다.

좋은 아이디어가 있어도 자동 재사용하지 않는다. 현재 System/Requirement Capability/Scenario 압력에서 다시 정당화되어야 한다.

## 3. 현재 구현 모델

```text
34 System Responsibility Model v2
30 Requirement Capability Catalog v3
61 Representative Scenario machine trace
```

중요:

```text
Requirement Capability ≠ System alias
System ≠ Manager/Service/Controller/Module count
REPOSITORY_LOGIC ≠ E0_CORE_ENGINE
A3 Outbox ≠ A8 Event Delivery
```

Canonical machine-readable 구조는 `implementation-system-model.json`이다.

## 4. 개발 순서

```text
R3 repaired model validation
→ 사용자 R3 Freeze 결정
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Core Engine
→ CORE_ENGINE_COMPLETE
→ E1 Roblox Runtime Engine / Integration
→ INTEGRATION_READY
→ U0 Product UI Shell Session
→ UI_SHELL_READY
→ E2 Presentation / Feel Checkpoints
```

현재는 **R3 repaired model 검증 단계**다. Source와 Studio 구현을 시작하지 않는다.

## 5. REPOSITORY_LOGIC와 E0_CORE_ENGINE

`REPOSITORY_LOGIC`는 Roblox 없이 구현 가능한 모든 production logic의 분류다.

`E0_CORE_ENGINE`은 Studio 전에 반드시 완성해야 하는 Foundation subset이다.

따라서 미래 Character/Journal/Actor Authoring 로직이 Repository에서 구현 가능하다고 해서 전부 `CORE_ENGINE_COMPLETE` 조건이 되는 것은 아니다.

반대로 E1 Provider가 소비할 Core contract/policy/state-machine은 E0에서 빠질 수 없다.

## 6. Future Compatibility

현재 Checkpoint만 통과하는 구조를 만들지 않는다.

미래 Character / Encounter / Inventory / Rules / Persistence / DM / Scene / Journal / Logistics / Actor Authoring 시나리오는 지금 구현 Scope가 아니라 **현재 Architecture의 Compatibility Constraint**다.

각 구현 Checkpoint는 다음을 명시한다.

```text
Future Consumers
Future Scenario Pressure
Requirement Capability Set
Extension Seams
Forbidden Shortcuts
Deferred Non-goals
Future Compatibility Tests
```

## 7. Event / Ready / Reservation / Provider 불변식

### Event

```text
A3 Transaction + transactional Outbox
→ A8 committed-only delivery / subscription / retry / receipt
→ A5/S1/authorized follow-up subscriber
```

A8이 상태를 바꾸려면 새 Command/RuleExecution을 제출한다.

### Ready

```text
A7 authorityRecoveryReady
A6 projectionSyncReady
W7 sceneEssentialReady
C1 clientReplicaReady
→ A1 EffectiveGameplayReady
→ A1 only final gameplay Command gate
```

### Reservation

```text
OrderingReservation              → A3
ResourceReservation              → R3 orchestration
OccupancyReservation             → W6
ActivityReservation              → D5
LogisticsAllocationReservation   → D7
```

범용 ReservationManager 하나로 합치지 않는다.

### Shared Platform Provider

```text
AuthorityMonotonicClock
DeterministicIdFactory
RngProvider
TransportAdapter
StorageAdapter
```

각 System이 직접 제각각의 clock/GUID/Random/Remote/Storage authority path를 만들지 않는다.

## 8. Repository / Studio 순서

**Studio/MCP는 E0 Core Engine 전체 완료 전 사용하지 않는다.**

Roblox Runtime이 필요한 Pathfinding/Raycast/Physics/Input/Camera/Streaming도:

```text
R4/E0
→ contract / policy / state machine / permission / failure semantics

CORE_ENGINE_COMPLETE 이후 E1 Studio
→ actual runtime provider / integration
```

순서를 따른다.

## 9. UI Shell

`INTEGRATION_READY` 뒤 E2 전에 U0를 한 번 수행한다.

```text
HTML/UI Reference Distillation
→ Product UI Surface Inventory
→ Design Philosophy / IA / Visual Language / States / Accessibility / Roblox Mapping
→ 실제 Product UI Shell 전체 Scaffold
→ Human Shell Review
→ UI_SHELL_READY
```

`UI_SHELL_READY` 이후 throwaway Test ScreenGui를 만들지 않는다.

- UI 표현 테스트: 실제 Product Shell + dev Fixture Projection/ViewModel.
- Gameplay 테스트: 실제 Product Shell Debug Control + 실제 Command/Server Authority path.
- Debug UI가 Domain Store를 직접 수정하거나 별도 Authority/Remote path를 만들면 안 된다.

## 10. 기술 비협상 규칙

1. Gameplay mutation 최종 권한은 Server다.
2. Client Role/Owner/Controller/result claim은 untrusted다.
3. Authoritative mutation은 승인된 Command/Transaction 경계를 통과한다.
4. Remote payload type/size/depth/rate를 제한한다.
5. Network에 Roblox Instance를 보내지 않는다.
6. command identity / epoch / typed precondition을 검증한다.
7. duplicate/stale mutation은 fail closed다.
8. Projection은 viewer-safe이며 existence leakage를 막는다.
9. UI/Presenter는 Remote나 Domain Store를 직접 소유하지 않는다.
10. Bootstrap/App은 composition/lifecycle만 담당한다.
11. lifecycle cleanup을 명시한다.
12. Persistence는 A7 boundary 뒤에 둔다.
13. Studio-only production truth를 허용하지 않는다.
14. 구현 전 책임 경계를 선언한다. Private helper는 Source-derived다.
15. 더 좋은 Architecture가 보이면 자동 적용하지 않고 문제·대안·영향을 사용자에게 먼저 보고한다.
16. A8 Event Delivery를 두 번째 Command Bus로 만들지 않는다.
17. technical monotonic time을 Campaign Game Time으로 사용하지 않는다.

## 11. 사용자 승인 없이 바꾸지 않는 것

- Product 목표/비목표
- Accepted ADR
- 입력 문법
- Server/Client Authority와 state ownership
- 핵심 System/Module responsibility
- System sequence
- 개발 방식과 Checkpoint 시점
- Release scope/priority

명백한 bug, 기존 의도 안의 UX 미세 조정, private helper 분해는 즉시 수행 가능하다.

## 12. 현재 상태

```text
OLD GREENFIELD MODEL = RETIRED
SYSTEM MODEL = V2 · 34 · REPAIRED
REQUIREMENT CAPABILITY = V3 · 30
SCENARIO TRACE = 61/61 MACHINE-READABLE
R3 = NOT FROZEN
SOURCE = NOT STARTED
STUDIO = NOT STARTED
NEXT = FULL REPAIRED-MODEL VALIDATION, THEN USER FREEZE DECISION
```
