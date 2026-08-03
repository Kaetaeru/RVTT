# 13. 주문책 저장소와 복사 모델

- 상태: 초안
- 작성일: 2026-08-03
- 관련 문서:
  - [`10. Grant Graph와 Capability 모델`](../../../../architecture/rules-content-grant-capability-model.md)
  - [`11. 공통 실행 계약과 마법 처리 모델`](../../../../architecture/rules-content-execution-and-spell-contract.md)
  - [`12. 주문 획득·준비·시전 권한 모델`](../../../../spell-acquisition-preparation-and-cast-access-model.md)
  - [`ADR-0018`](../../../../decisions/ADR-0018-source-scoped-spellcasting-profiles.md)
  - [`ADR-0019`](../../../../decisions/ADR-0019-item-bound-persistent-spellbook-repositories.md)

## 1. 문서 목적

주문책은 마법사 캐릭터의 단순한 주문 목록이 아니다.

RVTT는 다음 상황을 모두 처리해야 한다.

- 캐릭터 생성 시 기본 주문책을 받는다.
- 레벨업으로 얻은 주문을 주문책에 추가한다.
- 주문 두루마리나 다른 주문책에서 주문을 복사한다.
- 기본 책과 예비 책이 서로 다른 주문 목록을 가진다.
- 책을 장면의 상자에 두거나 다른 캐릭터에게 넘긴다.
- 책을 잃어버리거나 되찾는다.
- 약탈한 주문책을 조사하고 일부 주문을 자신의 책으로 옮긴다.
- 책이 파괴되더라도 준비 상태, 저장 데이터와 복구 기록이 모순되지 않는다.

이 문서는 주문책의 물리적 아이템, 구조화된 주문 내용, 주문 준비 상태와 복사 절차의 경계를 정의한다.

---

## 2. 전체 구조

```text
Campaign persistent data
├─ ItemInstance
│  ├─ itemDefinitionId: item.spellbook
│  ├─ custody / location
│  ├─ name and presentation overrides
│  └─ spellRepositoryId
│
├─ SpellRepositoryRecord
│  ├─ repositoryId
│  ├─ boundItemInstanceId
│  └─ SpellbookEntry map
│
└─ Character
   └─ SpellcastingProfileState
      ├─ primarySpellRepositoryId
      ├─ preparedSpellIds
      └─ profile-specific selections
```

역할을 혼합하지 않는다.

```text
ItemInstance
→ 책이 어디에 있고 누가 접근할 수 있는가

SpellRepositoryRecord
→ 그 책에 어떤 주문이 적혀 있는가

SpellcastingProfileState
→ 캐릭터가 현재 어떤 주문을 준비했는가
```

---

## 3. 주문책은 아이템 결합형 영구 저장소다

주문책의 내용은 일반 아이템 설명 문자열이나 캐릭터의 전역 `knownSpells`에 넣지 않는다.

각 주문책 아이템 인스턴스는 하나의 주문 저장소를 참조한다.

```text
item-instance-42
└─ spellRepositoryId: spell-repository-42
```

주문 저장소도 자신이 연결된 아이템을 역참조한다.

```text
spell-repository-42
└─ boundItemInstanceId: item-instance-42
```

두 방향 참조는 서버 로딩과 마이그레이션에서 일치 여부를 검사한다.

주문책 복제 시 두 책이 같은 저장소를 참조하게 하지 않는다.

```text
원본 주문책
├─ item-instance-42
└─ spell-repository-42

예비 주문책
├─ item-instance-93
└─ spell-repository-93
```

복사된 항목은 같은 `spellId`를 가질 수 있지만 서로 독립된 `SpellbookEntry`다.

---

## 4. 개념 데이터 계약

### 4.1 SpellRepositoryRecord

```text
SpellRepositoryRecord
├─ repositoryId
├─ kind: spellbook
├─ schemaVersion
├─ rulesetId
├─ boundItemInstanceId
├─ status
├─ entriesById
├─ createdAt
├─ updatedAt
└─ revision
```

`status` 후보:

- `active`: 정상 사용 가능
- `unavailable`: 데이터는 존재하지만 현재 규칙상 접근 불가
- `archived`: 삭제 또는 이동 복구를 위해 보관
- `destroyed`: 규칙상 파괴된 상태
- `migration_required`: 콘텐츠 버전 문제로 읽기 전용

보관 위치는 이 레코드가 아니라 연결된 `ItemInstance`에서 판정한다.

### 4.2 SpellbookEntry

```text
SpellbookEntry
├─ entryId
├─ spellId
├─ spellContentVersion
├─ acquisitionKind
├─ sourceReference
├─ inscribedByCharacterId
├─ createdAt
├─ status
└─ revision
```

`acquisitionKind` 후보:

- `character_creation`
- `level_progression`
- `copied_from_spellbook`
- `copied_from_scroll`
- `dm_reward`
- `imported`
- `restored`

`sourceReference`는 가능한 경우 다음을 연결한다.

- 성장 선택 기록
- 원본 주문책 항목
- 주문 두루마리 아이템
- DM 보상 사건
- 데이터 마이그레이션 기록

주문 전체 정의와 번역된 설명은 저장하지 않는다. `spellId`와 콘텐츠 버전으로 카탈로그에서 읽는다.

### 4.3 중복 규칙

하나의 주문책에는 기본적으로 같은 `spellId`의 활성 항목을 하나만 둔다.

같은 주문을 다시 복사하려는 경우:

- 이미 같은 버전의 활성 항목이 있으면 거부한다.
- 버전 마이그레이션이라면 일반 복사가 아니라 명시적 마이그레이션 작업을 사용한다.
- 손상, 암호화와 같은 향후 변형이 필요하면 별도 상태나 콘텐츠 확장으로 처리한다.

---

## 5. 주문책과 캐릭터의 관계

주문책은 특정 캐릭터의 하위 데이터가 아니다.

현재 소유와 접근은 연결 아이템의 보관 위치로 결정한다.

```text
Item custody
├─ character inventory
├─ campaign stash
├─ scene container
├─ scene loose item
├─ NPC inventory
├─ another character inventory
└─ lost or archived location
```

이 구조는 다음을 가능하게 한다.

- 다른 캐릭터에게 주문책을 건넨다.
- 캠프나 공동 보관함에 예비 책을 둔다.
- 적 마법사의 주문책을 약탈한다.
- 책을 장면에 떨어뜨리고 나중에 회수한다.
- 주문책을 캠페인 자산으로 보존한다.

소유권과 읽을 수 있는 권한은 같지 않을 수 있다.

향후 언어, 암호, 식별 또는 소유자 잠금 규칙이 추가되더라도 주문 저장소 구조를 바꾸지 않고 접근 정책을 확장한다.

---

## 6. 기본 주문책 생성

주문책을 사용하는 `SpellcastingProfile`이 캐릭터 생성 과정에서 활성화되면 다음 작업을 하나의 서버 트랜잭션으로 수행한다.

```text
주문책 ItemInstance 생성
→ SpellRepositoryRecord 생성
→ 양방향 ID 연결
→ 캐릭터 생성 주문 선택 검증
→ 초기 SpellbookEntry 생성
→ profile.primarySpellRepositoryId 설정
→ 캐릭터와 아이템 저장 확정
```

중간 단계가 실패하면 빈 주문책, 연결되지 않은 저장소 또는 기록되지 않은 주문이 남지 않게 전체 작업을 취소한다.

주문책에 적히지 않는 캔트립이나 고정 주문은 해당 프로필의 선택 기록 또는 Grant Graph에서 관리한다.

어떤 주문 레벨과 종류가 책에 기록되는지는 `SpellcastingProfile`의 `repositoryEntryPolicy`가 결정한다.

---

## 7. 레벨업 주문 기록

레벨업에서 주문책에 새 주문을 얻는 경우, 선택 결과만 저장하고 책은 따로 변경하지 않는 구조로 두지 않는다.

레벨업 확정 트랜잭션이 실제 주문책 항목을 생성해야 한다.

```text
레벨업 주문 선택
→ 선택 적격성 검증
→ 기록 대상 주문책 선택
→ 대상 책 접근과 상태 검증
→ SpellbookEntry 생성 예약
→ 레벨업과 주문책 변경을 함께 확정
```

기본 동작:

- 접근 가능한 `primarySpellRepositoryId`가 있으면 기본 대상으로 사용한다.
- 기본 책을 사용할 수 없으면 접근 가능한 다른 호환 주문책을 선택하게 한다.
- 기록할 수 있는 책이 없으면 레벨업의 해당 선택을 미완료 상태로 두고 캐릭터 진행 확정을 막는다.
- DM이 규칙 외로 허용할 경우에는 명시적인 예외 작업과 로그를 남긴다.

레벨업 주문도 `SpellbookEntry.acquisitionKind = level_progression`으로 출처를 남긴다.

---

## 8. 주문 복사 트랜잭션

다른 주문책이나 주문 두루마리에서 주문을 복사하는 작업은 공통 `RuleExecution` 생명주기를 사용한다.

### 8.1 입력

```text
SpellCopyRequest
├─ actorCharacterId
├─ spellcastingProfileId
├─ sourceType
├─ sourceReferenceId
├─ sourceSpellId or sourceEntryId
├─ destinationRepositoryId
└─ optional DM context
```

### 8.2 서버 검증

최소 검증 항목:

- 요청자가 해당 캐릭터를 조작할 권한이 있는가
- 캐릭터가 주문 복사 기능을 가지고 있는가
- 원본 주문이 실제로 존재하고 읽을 수 있는가
- 주문이 해당 프로필의 복사 가능한 목록에 속하는가
- 주문 레벨과 캐릭터 진행 조건을 충족하는가
- 대상 주문책에 접근할 수 있는가
- 대상 주문책이 활성 상태인가
- 같은 주문이 이미 기록되어 있지 않은가
- 필요한 시간, 화폐, 재료와 기타 비용을 지불할 수 있는가
- 원본의 소비 정책이 무엇인가
- 현재 세션 상태에서 복사 작업을 수행할 수 있는가

### 8.3 비용과 원본 소비

비용은 검증 전에 즉시 차감하지 않는다.

```text
복사 선언
→ 원본과 대상 검증
→ 비용 계산
→ 시간·화폐·재료 예약
→ 필요 시 DM 승인
→ SpellbookEntry 생성
→ 원본 소비와 비용 차감
→ 전체 결과 확정
```

주문 두루마리처럼 복사 성공 후 원본이 소비되는 콘텐츠는 `sourceConsumptionPolicy`로 처리한다.

다른 주문책의 항목은 일반적으로 소비하지 않는다.

복사 실패 시 비용과 원본 소비 여부는 해당 규칙 정의가 결정하며, 부분 실패가 발생해도 서버 트랜잭션 로그에 남긴다.

### 8.4 기록 결과

성공 시 새 항목은 원본과 출처 사슬을 남긴다.

```text
SpellbookEntry
├─ spellId
├─ acquisitionKind: copied_from_spellbook
└─ sourceReference
   ├─ sourceRepositoryId
   └─ sourceEntryId
```

원본 주문 정의 자체를 복사하지 않는다.

---

## 9. 준비 상태와 주문책 접근

준비 목록은 주문책 안에 저장하지 않는다.

```text
SpellcastingProfileState
└─ preparedSpellIds
```

준비 절차는 현재 접근 가능한 주문 저장소의 항목을 합쳐 후보를 계산한다.

```text
접근 가능한 주문책들
→ 호환되는 SpellbookEntry 수집
→ 중복 spellId 통합
→ 프로필 준비 규칙 적용
→ 플레이어 선택
→ preparedSpellIds 저장
```

책이 여러 권이어도 같은 주문은 준비 후보에서 한 번만 표시한다.

### 책을 잃었을 때

책이 접근 불가능해졌다고 이미 준비된 주문을 즉시 삭제하지 않는다.

기본 정책:

- 현재 준비 목록은 유지한다.
- 해당 책에서만 제공되던 주문을 새로 준비하거나 다시 선택할 수 없다.
- 다음 준비 절차에서는 접근 가능한 책들만 후보로 사용한다.
- 주문책이 필요한 의식 시전이나 복사 작업은 사용할 수 없다.

정확한 준비 유지 정책은 프로필의 `preparationRetentionPolicy`로 선언한다.

---

## 10. 주문책에서의 의식 시전

주문책에서 직접 의식 시전할 수 있는 프로필은 준비 목록과 별개로 접근 가능한 주문책을 조회한다.

```text
SpellCastRoute
├─ source: accessible spellbook entry
├─ castMode: ritual
├─ profileId
├─ repositoryId
└─ entryId
```

실행 시 서버는 다음을 다시 확인한다.

- 책에 현재 접근할 수 있는가
- 항목이 여전히 존재하는가
- 주문이 의식 시전을 지원하는가
- 프로필이 주문책 의식 시전을 허용하는가
- 추가 시전 시간을 지불할 수 있는가
- 집중과 구성요소 조건을 충족하는가

의식 시전 경로는 일반 슬롯 시전 경로와 같은 주문 카드 아래에 표시할 수 있다.

---

## 11. 여러 주문책과 기본 책

캐릭터는 여러 주문책에 접근할 수 있다.

`primarySpellRepositoryId`는 다음에 사용하는 사용자 선택 기본값이다.

- 레벨업 주문 기록 대상
- 새 주문 복사의 기본 목적지
- UI에서 먼저 펼칠 주문책

기본 책은 영구 소유권을 뜻하지 않는다.

책을 잃거나 양도해 접근할 수 없으면 기본 참조는 유지하되 `unavailable` 상태로 표시하고, 새 기록 작업에서 다른 책을 선택하게 한다.

플레이어는 접근 가능한 호환 주문책을 새 기본 책으로 지정할 수 있다.

기본 책 변경은 주문 항목을 이동시키지 않는다.

---

## 12. 예비 주문책과 책 전체 복제

예비 주문책 제작은 기존 저장소를 공유하는 링크 복제가 아니다.

```text
원본 주문책 선택
→ 새 빈 주문책과 저장소 생성
→ 복사할 항목 선택
→ 각 항목의 비용·시간 계산
→ 새 저장소에 독립 Entry 생성
→ 전체 또는 단계별 확정
```

새 책의 항목은 원본 항목을 `sourceReference`로 기록한다.

원본 책에 나중에 추가된 주문이 예비 책에 자동으로 추가되지 않는다.

사용자가 두 책을 동기화하려면 명시적으로 추가 복사를 수행해야 한다.

---

## 13. 약탈하거나 전달받은 주문책

다른 캐릭터나 NPC의 주문책을 획득해도 그 책의 주문이 자동으로 자신의 주문 목록이나 준비 목록에 들어가지 않는다.

가능한 동작:

- 책 내용을 열람한다.
- 현재 프로필로 복사 가능한 주문을 필터링한다.
- 자신의 책으로 선택 복사한다.
- 규칙이 허용하면 해당 책에서 의식 시전을 시도한다.
- 책 자체를 보관하거나 다른 사람에게 넘긴다.

책의 내용 공개 범위는 아이템 접근 권한과 조사 상태에 따라 결정할 수 있다.

초기 구현에서는 접근 권한이 있는 사용자가 항목 목록을 볼 수 있게 하고, 암호·식별·부분 공개는 후속 확장으로 둔다.

---

## 14. 양도, 분실과 장면 보관

주문책 이동은 일반 아이템 이동 트랜잭션을 사용한다.

```text
character inventory
→ scene container
→ another character inventory
```

주문 저장소는 이동하지 않고 동일한 `ItemInstance` 연결을 유지한다.

장면에 보관된 책의 영구 데이터는 씬 오브젝트 자체에 복사하지 않는다.

씬은 아이템 인스턴스의 배치 또는 보관 참조를 가진다. 캠페인 영구 아이템 자산과 저장소가 권위 원본이다.

아이템 이동 실패 시 주문 저장소의 소유 위치도 바뀐 것으로 처리하지 않는다.

---

## 15. 파괴와 복구

주문책 파괴는 일반 인벤토리 삭제 버튼으로 처리하지 않는다.

명시적 파괴 작업:

```text
파괴 요청
→ 권한과 규칙 검증
→ 연결된 ItemInstance와 Repository 확인
→ 현재 사용 중인 준비·의식·복사 작업 검사
→ status: destroyed 전환
→ 아이템 보관 상태 갱신
→ 로그와 복구 스냅샷 생성
```

파괴된 책의 항목은 정상 플레이에서는 사용할 수 없지만 즉시 물리적으로 삭제하지 않는다.

이유:

- 잘못된 조작 복구
- 저장 마이그레이션
- DM의 서사적 복원
- 감사 로그

영구 삭제는 별도의 보존 정책 이후에만 수행한다.

준비된 주문은 주문책 파괴 순간 자동 제거하지 않는다. 이후의 준비 변경과 책 기반 의식 시전은 제한된다.

---

## 16. 주문책과 콘텐츠 버전

각 항목은 `spellId`와 기록 당시 콘텐츠 버전을 저장한다.

출처 팩이 업데이트되면 다음을 구분한다.

- 같은 주문 ID의 호환 가능한 정의 업데이트
- 명시적 데이터 마이그레이션이 필요한 변경
- 더 이상 사용할 수 없는 콘텐츠 팩
- 주문 ID가 교체되거나 분기된 변경

주문책에 주문 정의 스냅샷 전체를 저장하지 않는다.

콘텐츠를 찾을 수 없을 때:

- 항목 기록을 삭제하지 않는다.
- 읽기 전용 누락 상태로 표시한다.
- 준비, 시전과 복사를 차단한다.
- 복구 가능한 팩 또는 마이그레이션 정보를 보여준다.

---

## 17. 권한과 서버 권위

클라이언트는 다음을 요청할 수 있지만 직접 확정하지 않는다.

- 주문책 열람
- 기본 책 지정
- 레벨업 주문 기록 대상 선택
- 주문 복사
- 책 전체 복제
- 책 양도와 보관

서버는 매 요청에서 다음을 확인한다.

- 캠페인과 세션 권한
- 캐릭터와 아이템 조작 권한
- 주문책의 실제 보관 위치
- 접근 가능한 거리 또는 세션 문맥
- 프로필의 주문책 호환성
- 원본과 목적지의 현재 revision
- 비용과 시간
- 중복과 콘텐츠 유효성

클라이언트가 보낸 책 내용, 비용 계산과 최종 항목 목록을 신뢰하지 않는다.

동일 책에 대한 동시 수정은 revision 또는 명시적 잠금으로 충돌을 방지한다.

---

## 18. 저장과 로딩

주문책 관련 데이터는 캠페인 영구 저장에 포함한다.

로딩 순서 후보:

```text
아이템 인스턴스 로드
→ 주문 저장소 로드
→ 양방향 연결 검증
→ 콘텐츠 ID와 버전 검증
→ 캐릭터 SpellcastingProfile 구성
→ 접근 가능한 저장소 계산
→ 준비 목록과 시전 경로 검증
```

오류 사례:

- 아이템은 있는데 저장소가 없음
- 저장소는 있는데 아이템이 없음
- 서로 다른 ID를 참조함
- 같은 저장소를 여러 아이템이 참조함
- 항목의 주문 콘텐츠가 없음

이 경우 자동 삭제하지 않고 `migration_required` 또는 격리 상태로 두고 진단 로그를 남긴다.

---

## 19. UI 표현

주문 UI는 세 층으로 나눈다.

### 캐릭터 주문 화면

- 현재 준비된 주문
- 사용할 수 있는 시전 경로와 비용
- 출처별 주문 목록
- 준비되지 않은 이유와 자원 부족 이유

### 주문책 화면

```text
주문책 이름
├─ 현재 위치와 접근 상태
├─ 기록된 주문
├─ 주문 레벨·학파 필터
├─ 현재 준비 여부
├─ 복사 가능한 주문 표시
└─ 다른 책으로 복사
```

### 복사 화면

- 원본 주문과 출처
- 목적지 주문책
- 시간과 비용
- 원본 소비 여부
- 중복 또는 조건 미충족 이유
- 서버 확정 결과

같은 주문이 여러 책에 있어도 캐릭터 주문 화면에서는 중복 카드로 늘리지 않는다. 주문책 화면에서는 각 책의 실제 기록을 따로 보여준다.

---

## 20. 명시적인 비목표

- 주문책을 캐릭터의 단일 `knownSpells` 배열로 만들지 않는다.
- 준비 상태를 주문책 항목에 저장하지 않는다.
- 예비 주문책이 원본과 실시간으로 내용을 공유하지 않는다.
- 주문 정의 전체를 책마다 복사하지 않는다.
- 장면에 책을 놓을 때 영구 데이터를 씬 NPC나 오브젝트 데이터에 복제하지 않는다.
- 클라이언트가 비용과 주문 항목을 직접 수정하게 하지 않는다.
- 책 분실을 데이터 삭제로 처리하지 않는다.

---

## 21. 후속 결정

다음에는 주문 시전 자원의 구조를 구체화해야 한다.

1. 다중직업 공유 주문 슬롯의 계산과 저장
2. 워락형 별도 슬롯 풀과 짧은 휴식 회복
3. 무료 시전, 재주 자원과 아이템 충전의 공통 비용 계약
4. 시전 경로가 여러 개일 때 기본 경로 선택 UI
5. 주문 준비를 언제 변경할 수 있는지 검증하는 시간·휴식 절차
6. 구성요소와 주문시전 도구를 인벤토리와 연결하는 방식
