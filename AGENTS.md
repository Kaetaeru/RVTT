# RVTT Agent Rules

- 상태: `CURRENT · IMPLEMENTATION_MODEL_RESET`
- 최종 갱신일: 2026-08-13

## 1. 현재 실행 권위

기본 읽기 순서는 이것만 사용한다.

```text
사용자의 최신 명시적 지시
→ .github/CODEX-ACTIVE-TASK.md
→ implementation/roblox/IMPLEMENTATION-MODEL.md
→ implementation/roblox/ARCHITECTURE-COVERAGE-POLICY.md
→ architecture-coverage.json + architecture-scenarios.json
```

필요한 근거가 있을 때만 Product/Accepted ADR/Architecture/UI 문서를 따라간다.

Archive, 과거 Codex Command, PR 댓글, 과거 Acceptance에서 현재 TODO를 복구하지 않는다.

## 2. 기존 Greenfield 구현 모델 폐기

이전에 선언한 다음 구현 모델은 현재 권위가 아니다.

```text
25 modules
10 systems
64 stable functions
G0~G5
기존 E0/E1 module classification
기존 greenfield controller/service wiring
```

관련 문서/Registry는 `RETIRED_IMPLEMENTATION_MODEL` 또는 historical reference로만 취급한다.

좋은 아이디어가 있어도 자동 재사용하지 않는다. 새 System Model에서 책임과 Scenario 압력을 다시 확인한 뒤 명시적으로 채택한다.

## 3. 새 구현 모델

```text
Product / Accepted ADR / Current Architecture / UI
+ 22 Capabilities
+ 61 Representative Scenarios
+ Cross-cutting Coverage
→ System Model From Scratch
→ End-to-End Scenario Pressure Review
→ Core Engine Boundary Freeze
→ E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ Repository Core Engine
→ CORE_ENGINE_COMPLETE
→ Roblox Runtime Engine / Integration
→ INTEGRATION_READY
→ U0 Product UI Shell Session
→ UI_SHELL_READY
→ Presentation / Feel Checkpoints
```

현재는 **System Model을 다시 만드는 Planning 단계**다. Source와 Studio 구현을 시작하지 않는다.

## 4. Future Compatibility

현재 Checkpoint만 통과하는 구조를 만들지 않는다.

미래 Character / Encounter / Inventory / Rules / Persistence / DM / Scene / Journal 시나리오는 지금 구현 Scope가 아니라 **현재 Architecture의 Compatibility Constraint**다.

각 구현 Checkpoint는 Future Consumers, Future Scenario Pressure, Extension Seams, Forbidden Shortcuts, Deferred Non-goals를 명시해야 한다.

## 5. Repository / Studio 순서

**Studio/MCP는 Repository Core Engine 전체 완료 전 사용하지 않는다.**

Roblox Runtime이 필요한 Pathfinding/Raycast/Physics도:

```text
Repository
→ contract / policy / permission / failure semantics

CORE_ENGINE_COMPLETE 이후 Studio
→ actual runtime provider / navmesh / collision / raycast / integration
```

순서를 따른다.

## 6. UI Shell

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
- Debug UI가 Domain Store/World State를 직접 수정하거나 별도 Authority/Remote path를 만들면 안 된다.

## 7. 기술 비협상 규칙

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
12. Persistence는 명시적 boundary 뒤에 둔다.
13. Studio-only production truth를 허용하지 않는다.
14. 구현 전 책임 경계를 선언한다. Private helper는 Source-derived다.
15. 더 좋은 Architecture가 보이면 자동 적용하지 않고 문제·대안·영향을 사용자에게 먼저 보고한다.

## 8. 사용자 승인 없이 바꾸지 않는 것

- Product 목표/비목표
- Accepted ADR
- 입력 문법
- Server/Client Authority와 state ownership
- 핵심 System/Module responsibility
- System sequence
- 개발 방식과 Checkpoint 시점
- Release scope/priority

명백한 bug, 기존 의도 안의 UX 미세 조정, private helper 분해는 즉시 수행 가능하다.

## 9. 현재 상태

```text
IMPLEMENTATION MODEL RESET = ACTIVE
OLD GREENFIELD MODEL = RETIRED
SOURCE = NOT STARTED
STUDIO = NOT STARTED
NEXT = WHOLE-PRODUCT SYSTEM MODEL FROM SCRATCH
```
