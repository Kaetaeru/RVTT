# RVTT Planning Agent Addendum

- 상태: `CURRENT`
- 최종 갱신일: 2026-08-12
- 적용 범위: 기획, Product, Architecture, UI 정책, Implementation Spec

이 문서는 루트 `AGENTS.md`에 추가로 적용된다. 현재 작업 순서와 구현 방식은 `docs/remake/CURRENT-WORK-ORDER.md`와 `implementation/roblox/CURRENT-WORK-ORDER.md`가 소유한다.

## 1. 기획 문서의 목적

기획은 구현자가 제품 결정을 추측하지 않게 만드는 것이 목적이다. Roblox Studio에서 몇 분 안에 확인할 수 있는 시각·조작 세부까지 문서에서 미리 고정하는 것이 목적은 아니다.

새 문서와 실질적으로 수정한 기획 문서는 다음 중 하나로 준비도를 표시한다.

```text
즉시 구현 명세 가능성: READY
즉시 구현 명세 가능성: READY_WITH_DEFAULTS
즉시 구현 명세 가능성: BLOCKED
```

- `READY`: 추가 제품 결정 없이 구현·Studio 실험을 시작할 수 있다.
- `READY_WITH_DEFAULTS`: 구조는 확정됐고 되돌리기 쉬운 기본값만 남아 있다.
- `BLOCKED`: 구현자가 중요한 제품·Authority 결정을 추측해야 한다.

## 2. 문서에 반드시 고정할 것

- 사용자 목표와 비목표
- Authority 소유자
- 중요한 상태 전이
- 권한·Disclosure 경계
- 저장·Migration·Rollback이 필요한 의미
- 실패 시 지켜야 할 불변식
- 다른 System과의 공개 Contract

## 3. Studio에서 먼저 검증해도 되는 것

Accepted Product·Architecture 범위를 바꾸지 않는 한 다음은 Studio Implementation에서 빠르게 탐색할 수 있다.

- Panel 크기와 배치
- 정보 밀도
- Hover·Focus·Animation timing
- Camera 감각
- Cursor·Outline·Preview 표현
- 동일 의미를 전달하는 세부 Interaction 배치

Studio에서 좋은 결과가 확인되면 관련 UI·Spec 문서를 그 결과에 맞춰 정규화한다.

## 4. 사용자 결정 Gate

작업 중 더 좋아 보이는 방향이 발견되어 다음 중 하나를 바꿔야 하면 **적용하지 말고 사용자에게 먼저 제안한다.**

- 제품 목표·비목표
- Accepted ADR
- Authority 경계
- 공개 API·Data ownership
- 핵심 입력 문법
- 개발·검증 방식 자체
- Release 범위 또는 우선순위

제안에는 현재 문제, 대안, 영향받는 문서·Source를 짧게 포함한다. 사용자 승인 전에는 Accepted Authority를 수정하거나 구현으로 우회하지 않는다.

## 5. Codex 사용

Codex Review는 모든 기획 수정의 선행조건이 아니다.

독립 Review가 특히 필요한 경우:

- 새 ADR 또는 기존 Accepted ADR 변경
- 서버 Authority·Security·Disclosure 변경
- Persistence·Migration·Rollback 변경
- 여러 Slice의 소유권을 바꾸는 변경
- Merge·Release 전 고위험 검수

일반 UI 문구, 정리, 기존 Authority 안의 구현 세부는 필요에 따라 Focused Review만 사용한다.

과거 Codex Review Command와 Audit은 역사적 Evidence다. `.github/CODEX-ACTIVE-TASK.md`가 가리킬 때만 활성 지시로 취급한다.
