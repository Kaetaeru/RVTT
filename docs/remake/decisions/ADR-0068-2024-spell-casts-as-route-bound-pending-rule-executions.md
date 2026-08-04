# ADR-0068: 2024 주문 시전은 Route에 결합된 Pending RuleExecution으로 처리한다

- 상태: 확정
- 결정일: 2026-08-04
- 관련 문서:
  - [`Spell Runtime 계약`](../architecture/spell-casting-route-and-2024-spell-runtime-contract.md)
  - [`Character Action Runtime 계약`](../architecture/character-action-opportunity-and-2024-core-action-runtime-contract.md)
  - [`Rule Runtime Orchestrator 계약`](../architecture/rule-runtime-orchestrator-and-pending-execution-contract.md)
  - [`Effect Runtime 계약`](../architecture/effect-condition-and-ongoing-runtime-contract.md)
  - [`주문 자원 풀과 시전 결제 모델`](../systems/rules/spell-resource-pools-and-cast-payment-model.md)
  - [`주문 구성요소 계약`](../systems/rules/spell-components-and-material-inventory-contract.md)

## 배경

주문 시전은 단순히 주문 ID와 슬롯 하나를 받아 피해를 적용하는 작업이 아니다.

- 같은 주문을 여러 직업, 특성, 아이템과 무료 시전권으로 사용할 수 있다.
- 시전 능력치, 준비 상태, 구성요소, 자원과 시전 레벨이 Route마다 다르다.
- 대상 지정, 굴림, 반응, 집중과 지속 효과가 시전 도중 여러 번 중단·재개될 수 있다.
- Ready Spell과 장시간 시전은 서버 저장·복구가 가능한 Pending 상태를 요구한다.
- 2024 규칙은 한 턴에 주문 슬롯을 소비하는 시전을 하나로 제한한다.

주문마다 별도 Server 흐름을 만들면 자원 소비, Counterspell, 재접속과 롤백 규칙이 달라진다.

## 결정

모든 주문 시전은 다음 구조를 사용한다.

```text
CompiledSpellBuild
+ SpellCastRoute
+ 현재 Authority State
→ SpellCastOption
→ Route-bound RuleExecution
→ Reservation·Targeting·Roll·Reaction
→ PendingEffect CommitGroup
→ Atomic Transaction
```

`SpellCastRoute`는 캐릭터가 해당 주문을 어떤 출처와 규칙으로 사용할 수 있는지 설명한다. 실제 슬롯, 충전과 재료 State를 복사하지 않는다.

`SpellCastExecution`은 별도 독립 엔진이 아니라 Rule Runtime Orchestrator의 저장 가능한 실행 Context다.

## 세부 결정

1. Spell Definition, Compiled Spell Build, Cast Route와 Cast Execution을 분리한다.
2. 같은 주문의 여러 Route를 허용하며 Route마다 준비, 능력치, 결제와 구성요소 정책을 가진다.
3. 자원과 소비 재료는 먼저 예약하고 규칙상 확정 시점에 원자적으로 소비한다.
4. 2024 턴당 슬롯 시전 제한은 타입 있는 Usage Gate로 관리한다.
5. Ritual은 별도 주문 복사본이 아니라 Route의 시전 모드다.
6. Reaction Spell은 TimingWindow Offer로만 시작한다.
7. Ready Spell은 준비 시 정상 시전하고 Held Effect와 Concentration으로 유지한다.
8. 장시간 시전은 각 턴 Magic Action과 Concentration을 요구하는 Pending Execution이다.
9. 대상 Preview는 Client 보조이며 서버가 최종 Snapshot에서 재검증한다.
10. 집중·지속 영역·소환·변신은 Effect Runtime을 사용한다.
11. 마법 아이템 시전은 Route 정책이 다를 수 있지만 공통 RuleExecution을 사용한다.
12. DM Override도 Reservation, Journal과 Atomic Commit을 우회하지 않는다.

## 결과

- 주문 출처와 자원 결제가 명시적으로 추적된다.
- Counterspell과 반응 주문이 부모 실행을 직접 변조하지 않는다.
- Ready, Ritual과 장시간 시전을 재접속 후 복구할 수 있다.
- 공식 주문과 Homebrew 주문이 같은 등록·실행 경계를 사용한다.
- 구성요소, Inventory, Effect와 Character Runtime이 하나의 권위 흐름으로 연결된다.

## 채택하지 않은 대안

### 주문 ID별 전용 Server Handler

공식 주문 수가 늘수록 중복과 예외 분기가 폭증하므로 채택하지 않는다.

### Spell Definition에 캐릭터 준비·슬롯 상태 저장

콘텐츠 정의와 캐릭터 권위 상태가 섞이므로 채택하지 않는다.

### Client가 결제와 최종 대상을 확정

보안, 동시성, 롤백과 재현성을 보장할 수 없으므로 채택하지 않는다.

### 모든 시전 자원을 하나의 Mana로 통합

2024 규칙의 슬롯, 무료 시전, Item Charge와 특성 자원을 보존할 수 없으므로 채택하지 않는다.
