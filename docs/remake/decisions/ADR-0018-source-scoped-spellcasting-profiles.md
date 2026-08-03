# ADR-0018: 주문 출처별 SpellcastingProfile과 시전 경로를 사용한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0002`](ADR-0002-integrated-character-progression.md)
  - [`ADR-0017`](ADR-0017-derived-fixed-grants-and-stored-selections.md)
  - [`12. 주문 획득·준비·시전 권한 모델`](../systems/character/spell-acquisition-preparation-and-cast-access-model.md)

## 배경

한 캐릭터는 직업, 종, 배경, 재주, 아이템과 일시 효과를 통해 같은 주문을 여러 방식으로 얻을 수 있다.

같은 주문이라도 출처에 따라 다음이 달라질 수 있다.

- 주문 시전 능력치
- 습득과 준비 방식
- 주문 슬롯 사용 가능 여부
- 무료 시전 횟수와 회복 조건
- 상위 레벨 시전 가능 여부
- 의식 시전 가능 여부
- 물질 구성요소와 주문시전 도구
- 주문 교체 시점

캐릭터 전체에 하나의 `knownSpells`와 `preparedSpells` 목록만 두면 이러한 차이를 잃고, 다중직업과 중복 주문 출처를 정확히 처리할 수 없다.

## 결정

독립된 주문 출처마다 하나의 `SpellcastingProfile`을 구성한다.

```text
Character
└─ SpellcastingProfile Set
   ├─ class.wizard
   ├─ species.example
   ├─ feat.magic-initiate
   ├─ item.example
   └─ temporary.effect.example
```

`SpellcastingProfile`은 주문 정의를 복사하지 않고 다음 사용 규칙을 제공한다.

- 출처와 출처 사슬
- 주문 시전 능력치 또는 계산 규칙
- 습득·주문책·준비·항상 준비 정책
- 사용할 수 있는 주문 목록과 선택 조건
- 사용할 수 있는 슬롯 풀과 기타 자원
- 무료 시전과 회복 정책
- 의식 시전과 상위 레벨 시전 정책
- 구성요소와 주문시전 도구 변경
- 주문 교체와 재준비 시점

같은 `spellId`가 여러 프로필에서 사용 가능하면 프로필마다 별도의 `SpellCastRoute`를 생성한다.

```text
spell.example
├─ route: wizard profile + shared spell slots + Intelligence
└─ route: feat profile + free cast + Wisdom
```

행동 UI는 동일 주문을 하나의 카드로 묶어 표시할 수 있지만, 실제 실행은 선택된 `SpellCastRoute`를 기준으로 검증하고 비용을 지불한다.

## 저장 원칙

저장한다.

- 프로필별 플레이어 주문 선택
- 주문책과 같은 영구 저장소에 기록된 주문
- 프로필별 준비 목록
- 주문 교체 결과
- 무료 시전과 슬롯의 현재 소모 상태

파생한다.

- 고정으로 부여되는 프로필과 항상 준비 주문
- 현재 사용 가능한 `SpellCastRoute`
- 주문 공격 보너스와 주문 내성 DC
- 현재 `castable` 여부와 비활성 이유
- 행동 UI의 최종 주문 목록

## 결과

- 다중직업과 종·재주·아이템 주문을 같은 구조에서 처리할 수 있다.
- 같은 주문의 무료 시전과 슬롯 시전을 구분할 수 있다.
- 출처를 제거하거나 변경할 때 해당 프로필의 선택과 경로만 정리할 수 있다.
- 주문 UI는 단순하게 유지하면서 서버에서는 정확한 출처와 비용을 검증할 수 있다.
- 프로필별 준비와 주문책 정책을 별도로 구현해야 하므로 단일 주문 목록보다 구조가 복잡해진다.
