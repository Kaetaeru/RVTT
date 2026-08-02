# ADR-0014: 캐릭터 원본 데이터와 씬 CharacterActor 분리

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0011`](ADR-0011-persistent-character-runtime-state.md)
  - [`ADR-0012`](ADR-0012-campaign-scoped-character-ownership.md)
  - [`ADR-0013`](ADR-0013-single-character-and-scene-scoped-npcs.md)
  - [`04-scenes-and-world.md`](../04-scenes-and-world.md)

## 배경

플레이어 캐릭터는 캠페인 전체에서 성장하고 현재 HP, 자원, 인벤토리와 상태를 유지한다.

반면 씬에서 필요한 위치, 회전, 토큰 표시와 전투 참여 정보는 특정 씬의 생명주기에 속한다. 이 값을 캐릭터 원본에 함께 저장하면 씬 전환과 복사, 동시 편집, 전투 종료 시 데이터 책임이 섞인다.

## 결정

캐릭터의 영구 원본 데이터와 씬에 배치된 표현을 서로 다른 엔티티로 관리한다.

```text
Campaign
└─ Characters
   └─ Character
      ├─ identity and profile
      ├─ progression source
      ├─ persistent runtime state
      ├─ inventory and equipment
      └─ derived cache

Scene
└─ CharacterActors
   └─ CharacterActor
      ├─ actorId
      ├─ characterId reference
      ├─ transform
      ├─ token presentation
      ├─ visibility
      └─ scene presence state
```

`CharacterActor`는 캐릭터 데이터의 복사본이 아니다. `characterId`로 캠페인 캐릭터 원본을 참조하는 씬 소속 엔티티다.

## Character가 소유하는 데이터

캐릭터 원본은 캠페인 저장 경계 안에서 다음을 소유한다.

- `characterId`와 `campaignId`
- 이름, 초상화와 서술 프로필
- 종, 배경, 능력치와 성장 선택
- 직업 레벨, 하위직업, 재주와 숙련
- 습득 주문과 선택 기록
- 현재 HP와 임시 HP
- 주문 슬롯, 히트 다이스와 직업 자원의 현재 상태
- 집중, 소진, 죽음 내성과 지속 중인 상태 효과
- 인벤토리, 장비, 조율과 아이템별 현재 상태
- 규칙 원본에서 다시 계산할 수 있는 파생 능력치 캐시

최대 HP, AC, 숙련 보너스, 명중 보너스와 주문 DC 같은 파생 값은 원본 선택과 장비에서 계산한다. 캐시는 권위 데이터가 아니며 원본 revision이 바뀌면 폐기할 수 있어야 한다.

## CharacterActor가 소유하는 데이터

씬의 `CharacterActor`는 다음과 같은 씬 배치 상태만 소유한다.

- 씬 안에서 고유한 `actorId`
- 참조 대상 `characterId`
- 소속 `sceneId`
- 위치, 회전과 필요한 배치 크기
- 사용할 토큰 프리팹과 허용된 씬별 외형 오버라이드
- 씬에서의 활성, 배치, 숨김과 공개 상태
- 선택과 상호작용에 필요한 씬 전용 표시 상태

현재 HP, 자원, 인벤토리와 성장 데이터를 `CharacterActor`에 복사하여 별도 원본으로 만들지 않는다.

## 전투 런타임과의 경계

이니셔티브 순서, 현재 턴, 이번 턴에 소비한 이동거리, 행동·보너스 행동·반응 사용 여부와 전투 라운드는 캐릭터 원본이나 `CharacterActor`의 영구 필드가 아니다.

이 값은 현재 씬의 전투 또는 조우 런타임이 `actorId`를 참가자 키로 참조해 관리한다.

```text
Scene Combat Runtime
└─ Participants
   └─ actorId
      ├─ initiative
      ├─ turn resources
      ├─ movement spent
      └─ encounter-only state
```

전투가 종료되면 조우 전용 상태는 정리한다. 다만 피해, 자원 소비와 지속 상태처럼 전투 결과로 확정된 값은 서버가 캐릭터 원본의 persistent runtime state에 반영한다.

## 씬 전환

캐릭터가 다른 씬으로 이동할 때 캐릭터 원본을 복사하거나 이전하지 않는다.

- 기존 씬의 `CharacterActor`를 제거하거나 비활성화한다.
- 대상 씬에 같은 `characterId`를 참조하는 새 `CharacterActor`를 생성한다.
- 캐릭터의 HP, 자원, 인벤토리와 상태는 그대로 유지된다.
- 위치, 공개 상태와 전투 참여는 새 씬 기준으로 설정한다.

씬을 삭제해도 캠페인 캐릭터 원본은 삭제되지 않는다. 해당 씬의 `CharacterActor`만 삭제 대상이 된다.

## 서버 권한과 검증

서버는 `CharacterActor` 생성과 변경 시 최소한 다음을 검증한다.

- `characterId`가 현재 캠페인에 속하는지
- 요청 사용자가 캐릭터 또는 씬을 조작할 권한이 있는지
- `actorId`가 해당 씬에 속하는지
- 위치와 배치 값이 씬 규칙에 유효한지
- 씬 데이터가 캐릭터 원본의 HP, 성장과 인벤토리를 덮어쓰려 하지 않는지

클라이언트가 전달한 캐릭터 데이터 복사본을 권위 상태로 저장하지 않는다.

## 결과

- 캐릭터 상태가 씬 전환과 무관하게 안정적으로 유지된다.
- 씬 복사와 삭제가 캠페인 캐릭터 원본에 영향을 주지 않는다.
- 위치와 토큰 표시를 씬 단위로 관리할 수 있다.
- 전투 런타임을 종료할 때 영구 캐릭터 상태와 조우 전용 상태를 명확히 구분할 수 있다.
- 캐릭터 UI, 씬 토큰과 전투 시스템이 하나의 데이터 복사본을 서로 덮어쓰는 문제를 방지한다.
