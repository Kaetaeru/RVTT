# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GREENFIELD_ARCHITECTURE_FIRST_CONTEXT`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 시스템 순서 권위: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Greenfield 정책: [`GREENFIELD-BUILD-POLICY.md`](GREENFIELD-BUILD-POLICY.md)
- Module Contract: [`MODULE-CONTRACTS.md`](MODULE-CONTRACTS.md)

## 현재 작업

Active Task는 `RVTT-GREENFIELD-FOUNDATION-EXPLORATION-001`이다.

현재 실행 순서는 고정되어 있다.

```text
G0 Shared Contracts
→ G1 Server Authority Core
→ G2 Command Transport
→ G3 Projection Pipeline
→ G4 Client World Shell
→ G5 Composition Boot
→ S1 Selection
→ 사용자 확인
```

현재 Foundation을 만들 때 이전 monolithic Studio prototype을 Canonical 기준으로 사용하지 않는다.

## Exploration Checkpoint

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint는 사용자 수용 전 다음 단계로 넘어가지 않는다. 수정 요청은 현재 Checkpoint에서 즉시 반영한다.

## 이후 큰 순서

```text
Foundation
→ Exploration
→ Session·Role·Reconnect·Recovery
→ Encounter + Character Console
→ Character Data Surfaces
→ DM Live Workspace
→ Rules·Content Runtime
→ Persistence·Migration·Rollback
→ ADR-0092
→ Hardening
→ Release Acceptance
```

세부 이유와 기술 안전 경계는 `GREENFIELD-SYSTEM-SEQUENCE.md`가 소유한다.

## 완료 방식

1. Stage dependency가 맞다.
2. 기능이 명확한 Module 책임을 통해 동작한다.
3. Studio에서 실제 Play된다.
4. 사용자 피드백은 다음 작업보다 먼저 반영된다.
5. 수용된 결과는 `greenfield/src`와 Rojo Mapping에서 재현된다.
6. Module/Checkpoint status가 실제 상태와 일치한다.
7. 필요한 Focused Test가 있다.

Legacy `src/`, Acceptance Harness, Grand Runner와 과거 Evidence는 Reference이며 현재 구현 순서나 PASS를 결정하지 않는다.
