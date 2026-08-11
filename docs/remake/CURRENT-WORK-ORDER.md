# RVTT Remake 현재 작업 Context

- 상태: `ACTIVE · CONTEXT_ONLY`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)

## 역할

이 문서는 제품 단계와 장기 우선순위만 설명한다. 현재 실행할 Task는 `CODEX-ACTIVE-TASK.md`만 소유한다.

## 현재 결정

제품·Accepted ADR의 목표와 Authority 계약은 유지한다. **구현은 기존 Production Build를 이어서 고치는 방식이 아니라 Greenfield Studio Build로 다시 시작한다.**

```text
폐기된 개발 방식
기존 Source 대량 구현
→ Build
→ Acceptance
→ 뒤늦은 UX 확인

현재 개발 방식
Product·ADR
→ Module Contract
→ Legacy Source 역할 조사
→ 새 Studio Build를 처음부터 구축
→ Play·즉시 수정
→ 사용자 판단
→ 새 결과를 GitHub Canonical Source로 정규화
→ Focused Test
```

Legacy Source와 과거 Acceptance는 참고·회귀 자료이며 현재 구현 Baseline이 아니다.

## Product Authority

다음 Accepted 방향은 여전히 유효하다.

- ADR-0088 Direct Play
- ADR-0089 Observer-first Surface
- ADR-0090 Console Matrix·DM Windows
- ADR-0091 Asset·Official Sheet·Dice·Core Rules
- ADR-0092 Survival Logistics·DM Actor Token Authoring

Greenfield Build가 이 제품 결정을 자동으로 폐기한다는 뜻은 아니다.

## 장기 기능 우선순위 — Context only

1. Exploration·World Interaction
2. Encounter·Character Console
3. Inventory·Journal·Character Sheet·Settings
4. Entry·Role·Recovery
5. DM Workspace
6. ADR-0091 Runtime Surface
7. ADR-0092 Production

현재 실제 실행은 Active Task의 Exploration Greenfield Build 하나뿐이다.

## Legacy 처리

- 기존 Production Source: 역할 참고·선택적 재사용 후보
- 기존 Production Place/UI: 새 Build의 Baseline으로 사용하지 않음
- 기존 Acceptance Harness: Stabilization·Release 회귀 도구
- 기존 Runtime Evidence: Historical Evidence
- 과거 Codex Command: Archive

## 사용자 결정 보호

Greenfield Build 중 현재 Product·Architecture보다 더 나은 방향이 발견되면 자동 적용하지 않는다. 문제·대안·영향 범위를 사용자에게 먼저 제안한다.
