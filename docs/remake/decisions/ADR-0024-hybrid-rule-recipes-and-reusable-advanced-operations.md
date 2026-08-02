# ADR-0024: 주문은 공통 RuleRecipe와 재사용 고급 연산으로 구현한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0023`](ADR-0023-composable-targeting-and-spatial-query-model.md)
  - [`11. 공통 실행 계약과 마법 처리 모델`](../11-rules-content-execution-and-spell-contract.md)
  - [`17. 주문 대상 지정·영역·공간 질의 모델`](../17-spell-targeting-area-and-spatial-query-model.md)

## 배경

주문마다 전용 실행 코드를 작성하면 주문 수에 비례해 구현과 유지보수 비용이 증가한다.

반대로 모든 주문을 지나치게 작은 범용 노드만으로 표현하면 폴리모프, 안티매직 필드, 글리프 오브 워딩과 같은 주문의 레시피가 지나치게 복잡하고 읽기 어려워진다.

## 결정

주문과 기타 규칙 콘텐츠는 공통 `RuleRecipe` 실행 그래프를 사용한다.

```text
RuleRecipe
├─ targeting and validation
├─ rolls and branches
├─ effects and state changes
├─ persistent effects and triggers
├─ reactions and interruptions
└─ transaction commit and rollback
```

일반적인 주문은 작은 공통 노드의 조합으로 표현한다.

복잡하지만 여러 콘텐츠에서 반복되는 규칙은 재사용 가능한 고급 연산으로 제공한다.

초기 고급 연산 후보:

- `ApplyFormLayer`
- `CreatePersistentArea`
- `ApplySuppressionZone`
- `StoreExecution`
- `TransferControl`
- `TransitionEntities`
- `CreateDerivedEntity`
- `OpenReactionWindow`
- `InterruptExecution`
- `RequestDMAdjudication`

전용 처리기는 공통 그래프와 고급 연산으로 표현할 수 없는 주문 고유의 마지막 정책에만 사용한다.

전용 처리기가 대상 선택, 비용 결제, 굴림, 지속시간과 로그를 다시 구현하게 하지 않는다.

```text
공통 대상 지정
→ 공통 비용 결제
→ 공통 효과 및 고급 연산
→ 필요한 경우에만 작은 SpellPolicyHandler
```

## 구현 원칙

- 주문 ID를 기준으로 한 중앙 거대 분기문을 만들지 않는다.
- 고급 연산은 특정 주문 이름이 아니라 재사용 가능한 규칙 의미로 이름 짓는다.
- 주문 데이터는 사용할 노드, 고급 연산, 파라미터와 정책 처리기 ID만 선언한다.
- 모든 연산은 서버 권위 실행 트랜잭션, 취소와 롤백 규약을 따른다.
- DM 판정이 필요한 결과를 임의 자동화하지 않고 구조화된 판정 요청으로 전환한다.
- 전용 정책 처리기의 범위와 이유를 콘텐츠 검증 단계에서 기록한다.

## 결과

- 대부분의 주문은 데이터 조합만으로 추가할 수 있다.
- 복잡한 주문도 공통 고급 연산을 공유할 수 있다.
- 극소수의 주문별 예외를 허용하면서 중앙 엔진의 복잡도 폭증을 막을 수 있다.
- 공통 엔진, 고급 연산과 전용 정책 처리기의 경계를 지속적으로 관리해야 한다.