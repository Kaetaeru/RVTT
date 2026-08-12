# RVTT Agent Rules

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-12

## 1. 현재 실행할 일

실행 권위는 다음 순서만 가진다.

```text
사용자의 최신 명시적 지시
→ .github/CODEX-ACTIVE-TASK.md
→ commandPath
```

Archive, 과거 Codex Command, PR 댓글, Audit, Acceptance Snapshot에서 현재 TODO를 복구하지 않는다.

## 2. 현재 Build 방식

현재 Roblox 구현은 `GREENFIELD_ARCHITECTURE_FIRST`다.

```text
Product·ADR
→ System Contract
→ Module Contract
→ Stable Function Contract
→ Pre-G0 Workbench Gate
→ System Foundation / current Checkpoint 구현
→ Studio Play
→ 사용자 피드백
→ 즉시 수정 또는 수용
→ Authority Reconciliation
→ Canonical Source 정규화
→ Checkpoint Promotion Commit
→ 다음 Capability
```

상세 규칙은 다음을 따른다.

- `implementation/roblox/GREENFIELD-BUILD-POLICY.md`
- `implementation/roblox/GREENFIELD-PREFLIGHT.md`
- `implementation/roblox/MODULE-CONTRACTS.md`
- `implementation/roblox/SYSTEM-FUNCTION-CONTRACTS.md`
- `implementation/roblox/AUTHORITY-RECONCILIATION-POLICY.md`

## 3. GitHub Source와 Workbench 구분

현재 Greenfield 작업장은 다음으로 고정한다.

- `implementation/roblox/manifests/module-contracts.json`: Module/Stage/Checkpoint Architecture 계약
- `implementation/roblox/manifests/system-function-contracts.json`: System flow와 Stable Function 의미 계약
- `implementation/roblox/greenfield.project.json`: Greenfield 전용 Rojo Project
- `implementation/roblox/greenfield/src`: 새 Build Canonical Source Root
- `implementation/roblox/greenfield/tests`: 새 Build Focused Test Root
- `implementation/roblox/greenfield-boundary.json`: Greenfield/Legacy 경계와 Legacy Lock
- `implementation/roblox/src`: Legacy Source / 읽기 전용 참고
- `implementation/roblox/default.project.json`: Legacy Production Rojo Project / 읽기 전용 참고

Greenfield 구현 중 Legacy `src`와 `default.project.json`을 직접 수정하지 않는다. 기존 구현에서 재사용 가치가 있으면 읽고 현재 Contract에 맞는 Greenfield 경로로 선택적으로 옮긴다.

Legacy Lock을 갱신하거나 Legacy 쓰기 정책을 풀어야 한다면 사용자에게 먼저 제안한다.

## 4. G0 시작 전 Gate

첫 G0 구현 전에 `implementation/roblox/GREENFIELD-PREFLIGHT.md`를 실행한다.

필수:

- `validate_greenfield_boundary.py` PASS
- `validate_module_contracts.py` PASS
- `rojo build greenfield.project.json` PASS
- Studio Place/Session이 Greenfield Workbench인지 확인
- 실제 MCP Capability Handshake

이 Gate는 Foundation Stage가 아니며 `G0 → G1 → ...` 순서를 바꾸지 않는다.

## 5. System / Module / Function 선계약

현재 또는 다음 구현 범위의 코드 경계는 Source보다 먼저 선언한다.

```text
System
→ Module
→ Stable Function
→ Source
```

### System Contract

시스템 책임, Authority, state owner, input/output, invariant, Module flow를 선언한다.

### Module Contract

파일 경계, responsibility, dependency, Authority, state ownership, stable entry point index를 선언한다.

### Stable Function Contract

다른 Contract-bearing Module이 호출하는 함수는 반드시 `system-function-contracts.json`에 먼저 존재해야 한다.

각 함수는 최소 다음을 선언한다.

```text
name / kind / purpose / inputs / output
authority / reads / writes / sideEffects
failureModes / idempotency / validation
permission / revisionBehavior
```

`module-contracts.json.entryPoints`는 이름 요약이고 함수 의미 Authority는 `system-function-contracts.json`이다. Validator가 두 목록을 1:1로 맞춘다.

**Undeclared cross-module call은 금지한다.** 구현 중 다른 Module이 호출해야 하는 함수가 새로 필요하면 먼저 Stable Function Contract를 만든다.

단, 아직 가까운 구현 범위가 아닌 미래 P2~P10의 구체 Module/함수를 상상으로 미리 만들지 않는다. 큰 시스템 순서만 미리 고정하고 구체 Code Contract는 해당 범위 직전에 만든다.

## 6. Private/Internal 구현 자유도

다음은 Stable Contract로 미리 선언하지 않는다.

- 한 Module 안에서만 쓰는 local/private helper
- helper 개수와 이름
- 정확한 내부 call graph
- 모든 `require()`를 복제한 수동 graph

Stable System/Module/Function 계약이 유지되는 한 private helper 분해와 내부 구현은 Codex가 현재 Source와 Studio 결과를 보고 결정한다.

다른 Module이 private helper를 호출하게 되는 순간 더 이상 private가 아니므로 Stable Function Contract를 먼저 추가한다.

## 7. System-first 규칙

Bootstrap Script는 Client/Server 하나씩 둘 수 있다. 역할은 Composition Root와 App start/fatal report로 제한한다.

다음을 한 Script에 몰아넣지 않는다.

```text
Input
Selection
Camera
Movement
Context Action
Authorization
Authoritative Mutation
Projection
Presentation
```

기능은 `System Contract → Module flow → Stable Function`으로 설명 가능해야 한다.

Architecture를 과도하게 미리 만드는 것도 금지한다. 다음 Playable Checkpoint에 필요한 책임만 먼저 세운다.

## 8. 사용자 피드백이 최우선

사용자가 실제 기능을 테스트한 뒤 수정 요청을 하면 현재 Checkpoint 수정이 다음 작업보다 우선한다.

```text
CHANGE_REQUESTED
→ 다음 기능 착수 중단
→ 현재 기능 즉시 수정
→ Play 재확인
→ 사용자 재검토
```

같은 Checkpoint 반복 중에는 private 구현을 빠르게 바꿀 수 있다.

Stable Function Contract 보완이 필요하더라도 기존 Architecture 의미 안의 명백한 API 보완이면 Contract를 먼저 갱신하고 구현한다. Product·Accepted ADR·Authority·state owner·Module 책임·System flow가 바뀌어야 하면 자동 적용하지 않고 먼저 사용자에게 대안과 영향을 설명한다.

## 9. 사용자 확정 후 Authority Reconciliation

사용자가 현재 변경을 최종 수용해도 즉시 Checkpoint를 `ACCEPTED`로 만들지 않는다.

```text
사용자 최종 수용
→ 현재 Product·ADR·Architecture·Spec 충돌 검색
→ System/Module/Stable Function Contract 정합화
→ greenfield/src 정규화
→ Focused Test
→ 남은 현재 문서/Contract 충돌 재검색
→ Checkpoint Promotion Commit
→ ACCEPTED
→ 다음 Checkpoint
```

Promotion Commit은 `checkpoint(<CHECKPOINT_ID>): accept <summary>` 형식의 복원 기준점이다. Promotion Commit이 생성되기 전에는 다음 Checkpoint를 시작하지 않는다.

## 10. Contract Drift

다음은 모두 `CONTRACT_DRIFT`다.

- System flow와 구현 구조 불일치
- Module responsibility/dependency/authority/state owner 불일치
- `entryPoints`와 Stable Function Contract 이름 불일치
- Stable Function의 입력/출력/side effect/failure/revision 의미 불일치
- 다른 Module이 undeclared 함수를 호출

Source가 있다는 이유로 Source를 자동 정답으로 삼지 않는다. 현재 Authority를 확인하고 정합화한다.

## 11. 사용자 승인 없이 바꾸지 않는 것

- 제품 목표·비목표
- Accepted ADR
- 핵심 입력 문법
- Server/Client Authority·Data ownership
- Module 책임의 실질적인 분리·통합
- System flow
- Foundation/Checkpoint 시스템 순서
- 개발 방식
- Release 범위·우선순위
- Legacy Write Lock 정책

기존 결정 안에서의 버그 수정, UX 미세 조정, private helper 분해는 즉시 수행할 수 있다.

## 12. 설계 권위

제품·Architecture 의미가 충돌하면:

1. 사용자의 최신 명시적 결정
2. Accepted/확정 ADR
3. Product·Architecture·System·Global UI Policy
4. 준비 완료 Implementation Spec
5. Greenfield System Contract
6. Greenfield Module Contract
7. Greenfield Stable Function Contract
8. Greenfield Source·Test
9. Legacy Source·Historical Evidence

Function Contract는 상위 Product/Architecture 의미를 바꾸는 권위가 없다.

## 13. 고정 제품 경계

별도 사용자 결정 없이 다음을 바꾸지 않는다.

- RVTT는 Roblox에서 DM이 실시간 진행하는 게임형 D&D VTT다.
- 기본 Ruleset은 `dnd5e-2024`, 기본 표시 언어는 `ko-KR`다.
- 초기 지원 입력은 PC 키보드·마우스다.
- Token은 Roblox Avatar가 아닌 리그 없는 OBJ·MeshPart 기반 3D Token을 기본으로 한다.
- 권위 이동은 연속 무격자 좌표이며 `5 ft = 4 studs`다.
- Exploration은 목적지 Click과 Token WASD 이동을 지원하고 Encounter는 Token WASD 직접 이동을 지원하지 않는다.
- Left Click=Primary, Right Click=Context, Middle Drag=Camera Orbit, Q=한 단계 취소, E=확정, ESC=Gameplay 의미 없음이다.
- 중요한 규칙, 권한, Roll, 확정 이동과 영구 상태는 Server authoritative다.
- Character Owner, Runtime Controller, Session Role을 분리한다.
- Private Rule Content와 Public Release Content를 분리한다.
- 공식 Stat Block·CR을 시스템이 임의로 자동 재조정하지 않는다.

## 14. Evidence

```text
Development Observation
≠ Contract Validation
≠ Static·Unit·Integration
≠ Human UI·UX Acceptance
≠ Multi-client
≠ Persistence
≠ Performance
≠ Release Acceptance
```

개발 중에는 현재 Checkpoint의 빠른 Play와 수정이 우선이다. 종합 Acceptance는 Stabilization·Release에서 수행한다.
