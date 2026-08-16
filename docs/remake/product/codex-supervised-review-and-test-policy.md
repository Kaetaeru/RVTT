# Codex 구현·검수 정책

- 상태: `확정 · STAGED_BY_CURRENT_EXECUTION_GATE`
- 문서 종류: Product·Engineering Process Policy
- 최종 갱신일: 2026-08-13
- 최종 제품 결정: 사용자
- 구현 환경: GitHub + Roblox Studio MCP

## 1. 목적

RVTT에서 Codex를 단순 코드 생성기나 자동 승인자로 사용하지 않는다. Codex는 현재 execution gate에 따라 **Planning/Repository Implementer/Studio Implementer/Fixer/Reviewer** 역할을 수행한다.

현재 개발 순서:

```text
R3 validation complete
→ 사용자 R3 Freeze
→ R4 E0 Checkpoint Freeze
→ Dedicated Implementation Branch
→ E0 Repository Core Engine 구현/자동 검증
→ CORE_ENGINE_COMPLETE
→ E1 Runtime Checkpoint Freeze
→ Roblox Studio MCP Runtime Provider + Integration
→ INTEGRATION_READY
→ U0 Product UI Shell
→ UI_SHELL_READY
→ E2 Presentation / Feel
```

GitHub는 영구 Source of Truth다. Studio는 **E1 이후** Roblox-dependent integration의 실제 작업장이다.

현재 R3에서는 Source와 Studio/MCP 구현을 시작하지 않는다.

## 2. 역할

### 사용자

- 제품 방향과 최종 수용을 결정한다.
- 새로운 방향, 범위, 우선순위, Architecture/Authority/개발 순서 변경을 승인하거나 거부한다.
- 실제 조작 감각, 가독성, DM 부담, 재미처럼 Human Judgment가 필요한 항목을 판단한다.

### ChatGPT

- 현재 Authority와 GitHub 상태를 해석한다.
- current-state drift와 validator/workflow false-green을 정리한다.
- Codex Finding과 Runtime 결과를 제품 Authority에 대조한다.
- 사용자 결정이 필요한 변경을 먼저 보고한다.

### Codex Repository Implementer

R4 E0 Checkpoint Freeze와 Dedicated Implementation Branch 생성 후 활성화한다.

- frozen E0 contract와 current System/Requirement/Scenario pressure를 읽는다.
- `greenfield/src/**`에 Roblox runtime 없이 검증 가능한 E0 Core를 구현한다.
- focused/negative/future-compatibility contract test를 함께 작성한다.
- 기존 `src/**`는 `READ_ONLY_REFERENCE`이며 자동 재사용하지 않는다.
- Module/Stable Function은 frozen Checkpoint 범위에서 JIT로 선언한다.
- `CORE_ENGINE_COMPLETE` 전 Studio/MCP를 사용하지 않는다.

### Codex Studio Implementer

`CORE_ENGINE_COMPLETE` 후 E1 Runtime Checkpoint가 Freeze된 뒤 활성화한다.

- GitHub Authority와 frozen E1 contract를 먼저 읽는다.
- MCP로 실제 Studio DataModel과 Roblox runtime surface를 조사한다.
- Pathfinding/Raycast/Physics/Transport/Input/Camera/Streaming 등 Roblox-dependent provider/integration을 직접 구현한다.
- Play·관찰·수정을 반복한다.
- 결과를 `greenfield/src/**`와 Rojo mapping에서 재현 가능하게 정규화한다.
- Studio-only hidden production truth를 남기지 않는다.

### Codex Reviewer

구현자와 별도의 검수가 필요할 때 Authority drift, Security·Disclosure, Persistence·Migration, 회귀, Evidence 과장을 검사한다. 직접 Merge나 최종 제품 수용을 결정하지 않는다.

## 3. Codex 작업 모드

```text
PLANNING_VALIDATION
E0_REPOSITORY_IMPLEMENTATION
E1_STUDIO_IMPLEMENTATION
FOCUSED_FIX
REVIEW
POST_RUNTIME_REVIEW
```

현재 R3에서 허용되는 기본 모드는 `PLANNING_VALIDATION`과 합의된 방향 안의 정합성 `FOCUSED_FIX`다.

`E0_REPOSITORY_IMPLEMENTATION`은 R4 Freeze + Dedicated Branch 이후, `E1_STUDIO_IMPLEMENTATION`은 `CORE_ENGINE_COMPLETE` 이후에만 허용한다.

## 4. GitHub-first 조사 규칙

모든 구현 모드에서 GitHub의 현재 Authority를 먼저 읽는다.

최소 순서:

```text
AGENTS.md
→ .github/CODEX-ACTIVE-TASK.md
→ Product / Accepted ADR / Current Architecture / Global UI
→ implementation/roblox/IMPLEMENTATION-MODEL.md
→ implementation/roblox/SYSTEMS.md
→ current Scenario/Requirement/System manifests
→ 현재 frozen Checkpoint contract
→ 대상 greenfield Source/Test
```

Retired Module Contract, old Stable Function registry, legacy `src/**`는 현재 구현 권위가 아니다. 좋은 아이디어도 current model에서 다시 정당화한 뒤에만 선택적으로 재사용한다.

## 5. Studio MCP 규칙

Studio MCP는 E1에서 직접 구현·실행·관찰 환경으로 사용한다.

```text
E1 frozen contract
→ Studio MCP DataModel 조사
→ provider/integration 구현
→ Play
→ 관찰
→ 수정
→ GitHub greenfield Source/Rojo 정규화
→ focused runtime verification
```

MCP Capability가 없으면 가능한 척하지 않는다. Studio 결과는 작업 종료 전에 Repository Source와 Project Mapping으로 환원한다.

## 6. Rojo의 역할

Rojo는 GitHub Source와 Roblox DataModel Mapping, 재현 가능한 Place Build, CI 구조 검증을 담당한다. Studio-only production state를 canonical truth로 사용하지 않는다.

## 7. 사용자 결정 보호

Codex, ChatGPT 또는 다른 에이전트가 현재 방향보다 낫다고 판단한 아이디어가 다음을 바꾸면 자동 적용하지 않는다.

- 제품 목표·비목표
- Accepted ADR
- 핵심 UX·입력 문법
- Authority·Data ownership
- 핵심 System/Module responsibility
- 개발 프로세스·Checkpoint 순서
- Release 범위·우선순위

현재 문제, 대안, 장단점, 영향받는 Authority·Source를 사용자에게 먼저 보고한다.

반면 현재 합의 방향 안의 명백한 bug, stale pointer, current-state drift, validator false-green, workflow trigger 누락은 즉시 수정하고 최종 HEAD에서 재검증한다.

## 8. Active Task

`.github/CODEX-ACTIVE-TASK.md`는 현재 실행 권위다. 고정된 `commandPath` schema를 요구하지 않는다. Active Task의 실제 필드와 canonical read path를 그대로 따른다.

과거 `.github/CODEX-*`, PR 댓글, Audit, Acceptance는 Active Task가 현재 권위로 명시하지 않는 한 historical evidence다.

## 9. Review 결과

독립 Review Finding은 최소 다음을 포함한다.

```text
findingId
severity
claim
evidence
minimalCorrection
requiredTest
```

대표 분류:

```text
CONFIRMED
VALID_RISK
CONTRACT_DRIFT
DESIGN_DECISION_REQUIRED
INTENTIONALLY_QUEUED
DUPLICATE
FALSE_POSITIVE
OUT_OF_SCOPE
```

`DESIGN_DECISION_REQUIRED`는 사용자 결정 전 자동 수정하지 않는다.

## 10. Test·Evidence 경계

서로 다른 Evidence를 섞지 않는다.

```text
Planning/Static Validation
Repository Unit·Contract Test
Legacy Reference Regression
E1 Studio Runtime
Human UI·UX
Multi-client
Persistence·Migration
Performance·Soak
Release Acceptance
```

Legacy Source/Studio/Acceptance PASS는 새 Greenfield 구현 PASS나 `CORE_ENGINE_COMPLETE`를 의미하지 않는다.

## 11. Merge·Release

Merge·Release 후보에서는 변경 위험에 맞는 CI, Authority/Security, Runtime, Persistence/Migration, Multi-client, Human UX evidence를 수행한다.

Codex는 사용자 요청 없이 PR을 Ready, Merge 또는 Force Push하지 않는다.
