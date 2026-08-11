# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GREENFIELD_ARCHITECTURE_FIRST_CONTEXT`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- Greenfield 정책: [`GREENFIELD-BUILD-POLICY.md`](GREENFIELD-BUILD-POLICY.md)
- Module Contract: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md)

## 현재 작업

Active Task는 `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`이다.

```text
System Foundation
→ Boot
→ S1 Selection
→ 사용자 확인
→ 수정 반복 또는 수용
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

## 완료 방식

각 Checkpoint는 다음을 만족해야 한다.

1. 기능이 명확한 Module 책임을 통해 동작한다.
2. Studio에서 실제로 Play된다.
3. 사용자 피드백이 있으면 다음 작업보다 먼저 반영된다.
4. 사용자가 수용한 결과는 `greenfield/src`에 정규화된다.
5. Module Contract status가 실제 구현 상태와 일치한다.
6. 필요한 Focused Test가 추가된다.

## Legacy

기존 `src/`, Acceptance Harness, Grand Runner, 과거 Evidence는 보존하지만 현재 Build의 구현 순서와 PASS를 결정하지 않는다.
