# ADR-0015: 캐릭터 기본 정보, 서술 프로필과 기본 표현 분리

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0012`](ADR-0012-campaign-scoped-character-ownership.md)
  - [`ADR-0014`](ADR-0014-character-data-and-scene-actor-separation.md)

## 배경

캐릭터 데이터에는 시스템 식별 정보, 플레이어가 편집하는 캐릭터 정체성, 자유로운 서술 정보와 토큰 외형이 함께 필요하다.

이 정보들을 하나의 평평한 구조로 저장하면 플레이어가 수정할 수 없는 값과 편집 가능한 값이 섞이고, 규칙 계산에 사용하지 않는 서술 정보가 성장 데이터와 혼동될 수 있다. 또한 캐릭터의 기본 토큰 외형과 특정 씬에서만 사용하는 외형 변경을 구분해야 한다.

## 결정

캐릭터 원본의 기본 영역을 다음 네 부분으로 분리한다.

```text
Character
├─ metadata
├─ identity
├─ defaultPresentation
└─ profile
```

### metadata

시스템이 관리하는 식별과 저장 정보다.

최소 필드:

- `schemaVersion`
- `characterId`
- `campaignId`
- `revision`
- `createdAt`
- `updatedAt`
- `status`: `active` 또는 `archived`

플레이어 조작 권한과 `assignedPlayerId`는 캐릭터 원본에 직접 저장하지 않는다. 권한 배정은 캠페인 멤버십과 접근 권한 데이터가 관리한다.

### identity

캐릭터 목록, 시트와 명찰에 표시되는 정체성 정보다.

기본 필드:

- `name`
- `pronunciation`
- `pronouns`
- `ageText`
- `heightText`
- `weightText`
- `portraitAssetId`

나이, 키와 몸무게는 규칙 계산용 숫자가 아니라 자유로운 표시 문자열로 저장한다. `Small`, `Medium` 같은 규칙상 크기 분류는 여기에 저장하지 않고 종과 특성에서 계산한다.

### defaultPresentation

모든 씬에서 기본으로 사용할 캐릭터 표현을 저장한다.

기본 필드:

- `tokenPrefabId`
- 허용된 색상, 스케일 변형과 장비 표현 오버라이드

특정 씬에서만 사용하는 외형 변경은 `CharacterActor`가 소유한다. 씬 외형 변경이 캐릭터의 기본 표현을 자동으로 덮어쓰지 않는다.

### profile

규칙 계산과 분리된 서술 정보다.

기본 필드:

- `appearance`
- `personality`
- `backgroundStory`
- `goals`
- `relationships`
- `notes`

D&D의 이상, 유대와 결점을 별도 필수 필드로 강제하지 않는다. 필요한 내용은 `personality`, `relationships`와 `notes`에 자연스럽게 기록한다.

## 데이터 경계

다음 정보는 이 영역에 저장하지 않는다.

- 종, 배경, 직업, 레벨, 재주와 숙련: 성장 원본
- 능력치와 레벨업 선택: 성장 원본
- 현재 HP와 자원: 영구 현재 상태
- 인벤토리와 장비: 인벤토리 영역
- 현재 위치와 회전: `CharacterActor`
- 이니셔티브와 턴 상태: 전투 런타임
- 플레이어 조작 권한: 캠페인 접근 권한
- DM 전용 비밀 메모: 별도 DM 또는 캠페인 노트

## 편집과 검증

- `characterId`, `campaignId`, `schemaVersion`과 `revision`은 클라이언트가 임의로 변경할 수 없다.
- 이름과 프로필 문자열은 길이 제한과 안전한 문자열 검증을 거친다.
- `portraitAssetId`와 `tokenPrefabId`는 허용된 자산 카탈로그에서 검증한다.
- 프로필 수정은 성장, 현재 HP와 인벤토리 revision을 불필요하게 바꾸지 않도록 영역별 변경을 지원할 수 있다.
- 보관된 캐릭터는 일반 플레이 흐름에서 수정하거나 배치할 수 없고, 명시적인 복구 후 다시 활성화한다.

## 결과

- 시스템 필드와 플레이어 편집 필드가 명확히 분리된다.
- 자유로운 캐릭터 서술을 지원하면서 규칙 계산과 섞이지 않는다.
- 캐릭터 기본 외형과 씬별 외형 변경의 책임이 구분된다.
- 권한 재배정이 캐릭터 원본을 변경하지 않는다.
- 이후 성장 원본, 현재 상태와 인벤토리를 독립된 계약으로 설계할 수 있다.
