# RVTT Greenfield Build Policy

- 상태: `ACTIVE · CURRENT_IMPLEMENTATION_POLICY`
- 최종 갱신일: 2026-08-12
- 시스템 순서 권위: [`GREENFIELD-SYSTEM-SEQUENCE.md`](GREENFIELD-SYSTEM-SEQUENCE.md)
- 확정 동기화 Gate: [`AUTHORITY-RECONCILIATION-POLICY.md`](AUTHORITY-RECONCILIATION-POLICY.md)

## 1. 기본 방식

새 RVTT는 **Architecture-first Greenfield + Tight Human Feedback**으로 만든다.

```text
다음 기능에 필요한 시스템 경계
→ 고정 System Sequence에 따라 Foundation 구현
→ 작은 Playable Capability
→ 사용자 직접 테스트
→ 즉시 수정 반복
→ 사용자 최종 수용
→ Authority Reconciliation
→ Canonical Source·Focused Test
→ 다음 Capability
```

구조 없이 기능만 빠르게 만드는 것도, 실제 제품 없이 Architecture만 오래 만드는 것도 실패다. 시스템은 다음 사용자 Checkpoint보다 한 단계만 먼저 만든다.

## 2. 순서는 선택 사항이 아니다

현재 Foundation 순서는 다음과 같다.

```text
G0 Shared Contracts
→ G1 Server Authority Core
→ G2 Command Transport
→ G3 Projection Pipeline
→ G4 Client World Shell
→ G5 Composition Boot
→ S1 Selection
```

정확한 Module, Gate와 기술 안전 규칙은 `GREENFIELD-SYSTEM-SEQUENCE.md`가 소유한다. Codex는 편의를 위해 순서를 건너뛰거나 임시 Remote/authoritative path를 만들지 않는다.

## 3. Bootstrap / App

```text
ClientBootstrap.client.lua → ClientApp.start()
ServerBootstrap.server.lua → ServerApp.start()
```

Bootstrap/App은 Composition Root와 lifecycle만 담당한다. Gameplay rule, input semantics, authorization, authoritative mutation, projection selection을 넣지 않는다.

## 4. 사용자 Feedback Loop

Exploration 첫 Checkpoint:

```text
S1 Selection
→ C1 Camera
→ M1 Move
→ X1 Context
→ I1 Interaction
```

각 Checkpoint가 `READY_FOR_USER`가 되면 다음 기능을 멈춘다.

- 수정 요청 → 같은 Checkpoint를 즉시 수정·재Play
- Block → 원인 해결 후 같은 Checkpoint 재시도
- 좋음 / 이걸로 / 다음 → 사용자 수용으로 기록하고 Authority Reconciliation 시작

사용자 수용 자체는 아직 `ACCEPTED`가 아니다.

```text
사용자 수용
→ 현재 Authority 충돌 검색
→ 상위 문서부터 정합화
→ Module Contract / Source / Test 정규화
→ 남은 충돌 없음 확인
→ ACCEPTED
→ 다음 Checkpoint
```

피드백을 여러 기능 뒤에 모아서 고치지 않고, 확정된 결정의 문서 정합화도 다음 기능 뒤로 미루지 않는다.

## 5. 반복 중 문서 Churn 금지

사용자가 같은 기능을 여러 차례 수정하게 하는 동안 Product·ADR·Architecture를 매 반복마다 갱신하지 않는다.

현재 Checkpoint가 `IMPLEMENTING`/`READY_FOR_USER`인 동안에는 방금 요청된 동작이 임시 Working Truth가 될 수 있다. 사용자가 최종 수용한 뒤에만 영구 Authority를 갱신한다.

단, 비협상 Security·Authority 규칙은 반복 중에도 항상 유지한다.

## 6. Legacy Source

기존 `src/`와 과거 Acceptance는 Reference다.

```text
역할·실패 경험 읽기
→ 현재 Greenfield Contract와 비교
→ 가치가 있을 때만 opt-in 재사용
```

Legacy 파일 구조를 복제하는 것이 목표가 아니다.

## 7. Canonicalization

사용자가 수용한 구현은 `AUTHORITY-RECONCILIATION-POLICY.md`에 따라 현재 Authority를 먼저 맞춘 뒤 `greenfield/src`로 정규화한다.

- Studio-only Production logic 제거
- Rojo로 재현 가능한 Instance 구조
- Module Contract status 갱신
- Focused Test 추가
- 현재 Authority 문서의 충돌 제거
- 관련 Checkpoint를 마지막에 `ACCEPTED`로 기록

사용자가 화면 동작을 수용했다고 해서 내부 Architecture·Authority 변경이 자동 승인되는 것은 아니다. 정합화 중 미승인 구조 변경이 발견되면 사용자에게 먼저 제안한다.

## 8. 기술 안전

Prototype 단계에서도 다음은 우회하지 않는다.

- Server authority
- untrusted client input
- bounded Remote payload
- command id / epoch / revision 검증
- viewer-safe Projection
- UI→Remote 직접 호출 금지
- Bootstrap gameplay logic 금지
- lifecycle cleanup
- fail closed permission/schema handling

세부 안전 규칙은 `GREENFIELD-SYSTEM-SEQUENCE.md` 4절이 유일한 현재 기준이다.

## 9. 변경 Gate

현재보다 더 좋아 보이는 Architecture, 순서, 핵심 UX, Authority 또는 개발 방식이 발견되면 자동 적용하지 않는다. 먼저 사용자에게 제안한다.
