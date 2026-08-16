# RVTT Planning Agent Addendum

- 상태: `CURRENT · SUBORDINATE_TO_ACTIVE_EXECUTION_GATE`
- 최종 갱신일: 2026-08-13
- 적용 범위: 기획, Product, Architecture, UI 정책, Implementation Spec

이 문서는 루트 `AGENTS.md`에 추가로 적용된다. **현재 실행 단계와 Source/Studio 시작 가능 여부는 `AGENTS.md`와 `.github/CODEX-ACTIVE-TASK.md`가 최우선으로 소유한다.**

현재는:

```text
R3 = VALIDATED · NOT FROZEN
SOURCE = BLOCKED
STUDIO/MCP = BLOCKED
NEXT = USER R3 FREEZE DECISION
```

따라서 아래의 `READY`나 Studio 탐색 허용 원칙은 현재 execution gate를 우회하지 않는다.

## 1. 기획 문서의 목적

기획은 구현자가 제품 결정을 추측하지 않게 만드는 것이 목적이다. Roblox Studio에서 빠르게 확인할 수 있는 시각·조작 세부까지 문서에서 미리 고정하는 것이 목적은 아니다.

새 문서와 실질적으로 수정한 기획 문서는 다음 중 하나로 준비도를 표시할 수 있다.

```text
즉시 구현 명세 가능성: READY
즉시 구현 명세 가능성: READY_WITH_DEFAULTS
즉시 구현 명세 가능성: BLOCKED
```

- `READY`: 추가 제품 결정이 필요 없으며 **현재 execution gate가 구현을 허용하는 시점에** 구현 가능하다.
- `READY_WITH_DEFAULTS`: 구조는 확정됐고 되돌리기 쉬운 기본값만 남아 있다.
- `BLOCKED`: 구현자가 중요한 Product·Authority 결정을 추측해야 한다.

`READY`는 R3/R4/E0 gate를 생략하거나 Studio를 조기 시작한다는 뜻이 아니다.

## 2. 문서에 반드시 고정할 것

- 사용자 목표와 비목표
- Authority 소유자
- 중요한 상태 전이
- 권한·Disclosure 경계
- 저장·Migration·Rollback 의미
- 실패 시 지켜야 할 불변식
- 다른 System과의 공개 Contract

## 3. Studio에서 검증 가능한 세부

Accepted Product·Architecture 범위를 바꾸지 않는 다음 항목은 **E1 Studio/MCP gate가 열린 뒤** 빠르게 탐색할 수 있다.

- Panel 크기와 배치
- 정보 밀도
- Hover·Focus·Animation timing
- Camera 감각
- Cursor·Outline·Preview 표현
- 동일 의미를 전달하는 세부 Interaction 배치

Studio에서 좋은 결과가 확인되면 관련 UI·Spec 문서를 그 결과에 맞춰 정규화한다. 현재 R3/R4/E0에서는 이 규칙으로 Studio를 조기 실행하지 않는다.

## 4. 사용자 결정 Gate

작업 중 더 좋아 보이는 방향이 발견되어 다음 중 하나를 바꿔야 하면 적용하지 말고 사용자에게 먼저 제안한다.

- 제품 목표·비목표
- Accepted ADR
- Authority 경계
- 공개 API·Data ownership
- 핵심 입력 문법
- 개발·검증 방식 자체
- Release 범위 또는 우선순위

제안에는 현재 문제, 대안, 영향받는 문서·Source를 포함한다. 사용자 승인 전에는 Accepted Authority를 수정하거나 구현으로 우회하지 않는다.

현재 합의 방향 안의 명백한 stale pointer, current-state drift, validator false-green, workflow trigger 누락은 발견 즉시 수정하고 최종 HEAD에서 재검증한다.

## 5. Codex 사용

Codex Review는 모든 기획 수정의 선행조건이 아니다. 새 ADR, Authority/Security/Disclosure, Persistence/Migration/Rollback, 여러 System 소유권 변경, Merge/Release 전 고위험 검수에는 독립 Review를 우선한다.

과거 Codex Review Command와 Audit은 historical evidence이며 Active Task가 현재 권위로 명시하지 않는 한 실행 지시로 취급하지 않는다.
