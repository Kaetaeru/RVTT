# RVTT Roblox Implementation 현재 작업 순서

- 상태: `GREENFIELD_ARCHITECTURE_FIRST_CONTEXT`
- 최종 갱신일: 2026-08-12
- 현재 실행 포인터: [`../../.github/CODEX-ACTIVE-TASK.md`](../../.github/CODEX-ACTIVE-TASK.md)
- 시스템 순서 권위: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- Greenfield 정책: [`GREENFIELD-BUILD-POLICY.md`](GREENFIELD-BUILD-POLICY.md)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)
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

사용자가 현재 동작을 최종 수용한 뒤에도 바로 다음 Checkpoint로 가지 않는다.

```text
사용자 최종 수용
→ Authority Reconciliation
→ 상위 Product·ADR·Architecture·Spec 정합화
→ Module Contract / Canonical Source / Focused Test
→ 현재 문서 충돌 없음 확인
→ ACCEPTED
→ 다음 Checkpoint
```

반복 수정 중에는 상위 Authority를 매번 수정하지 않는다. 확정된 뒤에는 충돌하는 현재 Authority를 방치하지 않는다.

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
5. 사용자 최종 수용 뒤 Authority Impact Scan과 Top-down Reconciliation이 완료된다.
6. 수용된 결과는 `greenfield/src`와 Rojo Mapping에서 재현된다.
7. Module/Checkpoint status가 실제 상태와 일치한다.
8. 필요한 Focused Test가 있다.
9. 현재 효력이 있는 문서에 확정 동작과 충돌하는 규칙이 남아 있지 않다.

화면/조작 수용을 미승인 내부 Architecture·Authority 변경의 승인으로 확대하지 않는다. 그런 변경이 필요하면 사용자에게 먼저 제안한다.

Legacy `src/`, Acceptance Harness, Grand Runner와 과거 Evidence는 Reference이며 현재 구현 순서나 PASS를 결정하지 않는다.
