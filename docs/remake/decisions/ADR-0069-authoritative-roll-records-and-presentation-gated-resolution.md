# ADR-0069: 권위 RollRecord와 Presentation-gated Resolution을 사용한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Dice Roll, Check, Save, Attack과 Resolution Runtime 계약`](../architecture/dice-roll-check-save-attack-and-resolution-runtime-contract.md)
  - [`Rule Runtime Orchestrator`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`ADR-0033`](ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)

## 배경

RVTT는 서버 권위 주사위 결과와 화면 중앙으로 날아오는 3D 주사위 연출을 함께 제공해야 한다.

공격, 능력 판정, 내성, 이니셔티브, 죽음 내성, 피해와 회복은 모두 주사위를 사용하지만 결과 의미와 후속 규칙은 다르다.

클라이언트 물리를 RNG로 사용하면 조작과 동기화 문제가 생긴다. 반대로 서버가 즉시 결과를 적용하면 주사위 연출이 단순 장식이 되어 사용자가 결과를 보기 전에 명중·피해·이니셔티브가 확정되는 문제가 생긴다.

## 결정

모든 규칙 굴림은 다음 계층을 사용한다.

```text
RollIntent
→ 서버 RollPlan
→ SealedRollResult
→ Presentation Gate
→ 불변 RollRecord
→ 종류별 ResolutionOutcome
→ PendingEffect
→ Atomic Commit
```

서버가 RNG 결과를 생성한다. 클라이언트는 권위 주사위 값이나 결과 면을 결정하지 않는다.

RollRecord 공개와 게임 상태 Commit을 분리한다. 공개 후 반응과 결과 변경 규칙을 처리한 뒤 Transaction Coordinator가 최종 상태를 Commit한다.

## 공통 d20 Test

공격 굴림, 능력 판정, 내성, 이니셔티브와 죽음 내성은 공통 RollPlan과 RollRecord 구조를 사용한다.

각 종류의 자연 1·20, 치명타, DC 비교와 특수 결과는 타입별 OutcomeResolver가 소유한다.

## Advantage와 Modifier

Advantage·Disadvantage, 수정치, 추가 주사위, 재굴림과 교체는 출처가 있는 Contribution과 Relation으로 보존한다.

최종 합계만 저장하지 않는다.

## 공개 게이트

서버는 최소 연출 시간과 핵심 audience ACK 또는 hard timeout을 기준으로 결과를 공개한다.

느린 클라이언트, 관전자, 연출 실패와 연결 끊김이 규칙 진행을 무기한 막을 수 없다.

## 비밀 굴림

권위 RollRecord와 Client Projection을 분리한다.

비밀 DC, 원시 값, Modifier와 결과 면은 권한 없는 Client에 전송하지 않는다.

## 결과

장점:

- 주사위 연출 이후에 명중·피해·이니셔티브가 자연스럽게 확정된다.
- 공격, 판정, 내성과 피해가 하나의 추적 가능한 굴림 기반을 사용한다.
- 재굴림과 결과 변경의 원본 기록이 남는다.
- 비밀 굴림과 공개 굴림이 같은 권위 구조를 사용한다.
- 재접속, 복구와 Rollback에서 진행 중 굴림을 복원할 수 있다.

비용:

- Roll Generated, Revealed와 Resolution Committed 상태를 별도로 관리해야 한다.
- audience별 Projection과 Presentation Timeout 처리가 필요하다.
- 단순 즉시 RNG 호출보다 상태기계와 저장 구조가 복잡하다.

## 대안 검토

### Client 물리 결과를 권위로 사용

조작, 장치 차이와 네트워크 비결정성 때문에 거부한다.

### 서버 결과를 즉시 적용하고 연출은 비동기로 재생

사용자가 결과를 확인하기 전에 전투 상태가 바뀌어 핵심 사용자 경험과 맞지 않아 거부한다.

### 모든 주사위 규칙을 각 행동에 개별 구현

Advantage, 비밀 공개, 재굴림, 저장과 감사 로직이 중복되므로 거부한다.
