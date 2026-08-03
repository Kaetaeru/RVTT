# ADR-0042: 저장과 복구는 권위 스냅샷·명령 저널·안전 경계를 결합한다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0005`](ADR-0005-performance-reliability-clean-code.md)
  - [`ADR-0018`](../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0033`](ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0037`](ADR-0037-zero-metadata-interaction-prefabs-and-state-snapshot-transitions.md)
  - [`36. 저장·자동 저장·재접속·서버 종료·세션 복구 모델`](../architecture/persistence-and-session-recovery-model.md)

## 배경

RVTT의 권위 상태는 캐릭터 시트만으로 끝나지 않는다.

- 캐릭터 HP, 자원, 장비, 주문과 성장
- 장면 오브젝트 위치와 상태
- 문, 레버, 상자, 함정과 파괴 오브젝트
- Fog 마스크와 탐험 기록
- 인카운터 참가자, 주도권, 현재 턴과 제어권
- 지속 효과, 집중, 죽음 내성과 휴식 상태
- DM의 장면 편집 이력과 오브젝트 연결
- 봉인된 주사위 결과와 아직 확정되지 않은 해결 단계

이 모든 데이터를 단순한 일정 주기 전체 저장만으로 처리하면 다음 문제가 생긴다.

- 저장 도중 서버가 종료되면 서로 다른 하위 데이터가 다른 시점으로 남는다.
- 공격 피해는 적용됐지만 자원 소모는 저장되지 않는 부분 확정이 발생할 수 있다.
- 주사위 연출 중 재접속했을 때 같은 공격이 두 번 적용될 수 있다.
- 장면 편집 중 미완성 고스트나 절반만 생성된 오브젝트가 남을 수 있다.
- 같은 캠페인을 두 서버가 동시에 수정하면 최신 상태를 덮어쓸 수 있다.
- 스키마 변경 이후 오래된 저장 데이터를 읽지 못할 수 있다.

## 결정

RVTT는 다음 세 계층을 조합해 저장한다.

```text
AuthoritativeSnapshot
+ CommandJournal
+ RecoveryCheckpoint
```

### AuthoritativeSnapshot

특정 권위 revision에서 완전히 일관된 캠페인·세션 상태를 저장한다.

```text
SnapshotHeader
├─ schemaVersion
├─ campaignId
├─ sessionId
├─ authorityRevision
├─ lastJournalSequence
├─ createdAt
├─ buildVersion
└─ checksum
```

스냅샷에는 클라이언트의 임시 UI, 카메라, 고스트 미리보기나 물리 주사위 위치를 저장하지 않는다.

### CommandJournal

마지막 스냅샷 이후 서버가 확정한 의미 명령과 트랜잭션을 순서대로 기록한다.

```text
JournalEntry
├─ entryId
├─ sequence
├─ authorityRevisionBefore
├─ authorityRevisionAfter
├─ commandType
├─ actorOrObjectIds
├─ transactionId
├─ idempotencyKey
├─ committedPayload
├─ committedAt
└─ auditContext
```

저널 항목은 재실행해도 같은 결과가 한 번만 적용되도록 멱등성을 가져야 한다.

### RecoveryCheckpoint

DM이나 시스템이 안전하게 돌아갈 수 있는 의미 있는 시점을 가리킨다.

```text
자동 저장
인카운터 시작 전
인카운터 종료 후
장면 게시 전·후
긴 휴식 완료 후
캐릭터 성장 확정 후
DM 수동 이름 지정 체크포인트
```

체크포인트는 기존 기록을 파괴하지 않는다. 복구는 과거 데이터를 덮어쓰는 것이 아니라, 선택한 체크포인트를 기반으로 새로운 권위 revision을 생성한다.

## 저장 안전 경계

RVTT는 규칙 해결의 임의의 중간 상태를 일반 스냅샷으로 저장하지 않는다.

```text
안전 경계
→ 완전히 확정된 CommitGroup 직후
→ 다음 ActionIntent를 받기 전
→ 장면 편집 트랜잭션 전체 확정 후
→ 턴 시작·종료 절차 전체 완료 후
```

다음은 완성된 월드 상태로 취급하지 않는다.

```text
대상 지정 미리보기
클라이언트 고스트
아직 제출되지 않은 이동 경로
물리 주사위 애니메이션 위치
미확정 DM 승인 선택
절반만 적용된 EffectRecipe
```

다만 서버가 이미 봉인한 주사위와 `PendingResolution`은 복구용 실행 정보로 별도 기록할 수 있다.

```text
PendingResolutionRecoveryRecord
├─ resolutionId
├─ actionIntentId
├─ sealedRollIds
├─ presentationStage
├─ committedStepIds
├─ pendingStepIds
├─ resourceReservation
└─ safeRecoveryPolicy
```

복구 시 이미 확정된 단계는 다시 적용하지 않고, 미확정 단계만 재개하거나 안전 취소한다.

## 저장 대상 분리

```text
CampaignPersistentState
→ 캐릭터, 장면, 인벤토리, Fog 탐험 기록, 오브젝트와 캠페인 설정

ActiveSessionState
→ 현재 장면, 인카운터, 턴, 일시적 효과, 제어권, 대기 중 해결

PlayerPreferenceState
→ UI 배율, Hotbar 배치, 접힌 패널, 시트 보기 방식과 입력 설정

EphemeralPresentationState
→ 카메라 흔들림, Tween 진행률, 주사위 물리 위치, 커서와 툴팁
```

`EphemeralPresentationState`는 저장하지 않는다.

## 자동 저장 정책

자동 저장은 하나의 고정 타이머만 사용하지 않는다.

```text
중요 사건 직후 저장 예약
+ 짧은 변경의 debounce 병합
+ 정기 안전 체크포인트
+ 서버 종료 최종 flush
```

중요 사건 예시:

- 캐릭터 생성·레벨업 확정
- 아이템 소유권 이전
- 긴 휴식과 자원 회복 완료
- 장면 편집 게시
- 인카운터 시작·종료
- Actor 사망·부활처럼 장기 상태가 바뀌는 사건
- DM이 수동 체크포인트 생성

HP 1 감소처럼 연속으로 발생할 수 있는 변경은 매번 전체 스냅샷을 만들지 않고 저널에 기록한 뒤 debounce된 체크포인트로 합친다.

## 재접속

플레이어가 같은 활성 서버에 재접속하면 서버 권위 상태를 다시 투영한다.

```text
권한 확인
→ 소유 Actor와 제어권 복원
→ CharacterSheetProjection 재생성
→ Encounter·Turn 상태 동기화
→ 현재 Prompt·Reaction·RollPresentation 확인
→ 필요한 화면만 재개
```

연결이 끊긴 동안 Actor의 처리 정책은 캠페인 또는 인카운터 설정으로 정한다.

```text
DM에게 임시 제어권 이전
Actor 턴에서 일시정지
서버 자동화에 위임
현재 행동만 안전 취소
```

기본값은 전투 흐름을 영구적으로 막지 않도록 DM에게 임시 제어권을 제안하되, 자동 이전 여부는 DM이 설정한다.

## 주사위 연출 중 연결 종료

실제 주사위 결과는 물리 연출보다 먼저 서버에서 봉인된다.

```text
연출 전 연결 종료
→ 재접속 후 연출을 다시 시작하거나 결과 즉시 표시

결과 공개 후 연결 종료
→ 공개 완료 상태로 복원

효과 일부 확정 후 연결 종료
→ committedStepIds를 기준으로 남은 단계만 처리
```

같은 `resolutionId`, `rollId`, `transactionId`는 두 번 적용할 수 없다.

## 서버 종료

서버 종료 절차:

```text
새 세션 참가 차단
→ 새 장기 ActionIntent 접수 중단
→ 현재 작업을 다음 안전 경계까지 완료 또는 안전 취소
→ 미기록 JournalEntry flush
→ 최종 권위 스냅샷 기록
→ 활성 세션을 dormant 또는 resumable로 표시
→ 플레이어에게 저장 상태 표시
```

종료 시간이 부족하면 우선순위는 다음과 같다.

```text
1. 권위 명령 저널
2. 캐릭터와 인벤토리 장기 상태
3. 현재 인카운터·세션 상태
4. 장면 편집 체크포인트
5. 사용자 UI 환경설정
```

프레젠테이션 상태는 포기할 수 있지만, 권위 규칙 결과는 포기하거나 중복 적용해서는 안 된다.

## 단일 작성자 권한

하나의 캠페인 활성 세션은 한 번에 하나의 권위 서버만 수정할 수 있다.

```text
CampaignLease
├─ campaignId
├─ authorityServerId
├─ fencingToken
├─ acquiredAt
├─ renewedAt
└─ expiresAt
```

모든 영속 쓰기는 현재 `fencingToken`을 확인한다. 오래된 서버는 새 서버가 권한을 인수한 뒤 상태를 덮어쓸 수 없다.

중복 서버가 감지되면 새 쓰기를 중단하고 DM에게 읽기 전용 또는 복구 선택지를 제공한다.

## 장면 편집 저장

장면 편집은 확정 명령 단위로 저장한다.

```text
CreateObject
TransformObject
DeleteObject
ChangeObjectState
CreateLink
EditFogMask
PublishSceneRevision
```

클라이언트 고스트와 드래그 중간값은 저장하지 않는다. 다중 선택 이동·복제·삭제는 하나의 원자적 편집 트랜잭션으로 확정한다.

게시된 장면 revision과 작업 중 초안 revision을 구분한다. 서버가 종료돼도 마지막 게시본은 항상 로드 가능해야 한다.

## 수동 저장과 복구 UI

DM은 다음을 사용할 수 있다.

```text
지금 저장
이름 있는 체크포인트 만들기
마지막 안전 체크포인트 보기
인카운터 시작 전으로 복구
장면 게시 전으로 복구
복구 전 변경 비교
```

복구 실행 전에는 영향을 받는 항목을 요약한다.

```text
캐릭터 HP·자원
아이템 소유권
현재 인카운터
장면 오브젝트
Fog 마스크
진행 중 효과
```

복구는 DM 권한, 명시적 확인, 감사 로그를 요구한다.

## 스키마와 마이그레이션

모든 저장 루트는 `schemaVersion`을 가진다.

```text
저장 읽기
→ 버전 확인
→ 순차 마이그레이션
→ 무결성 검사
→ 현재 런타임 모델로 변환
```

마이그레이션 실패 시 원본 저장을 덮어쓰지 않는다. 마지막 정상 스냅샷과 오류 정보를 유지하고 DM에게 안전 복구 경로를 제공한다.

## 결과

### 장점

- 서버 종료와 재접속 후에도 전투와 장면 상태를 복원할 수 있다.
- 주사위·피해·자원 소모의 중복 적용을 막는다.
- 장면 편집의 미완성 상태가 영속화되지 않는다.
- DM이 의미 있는 시점으로 안전하게 복구할 수 있다.
- 저장 스키마 변경과 장기 운영에 대응할 수 있다.

### 비용

- 단순 전체 저장보다 구현 복잡도가 높다.
- 모든 권위 명령에 transaction ID와 멱등성 처리가 필요하다.
- 스냅샷, 저널, 체크포인트의 정리와 보존 정책이 필요하다.
- 복구 시뮬레이션과 장애 테스트가 필수다.

## 구현 요구사항

- 저장 코드는 UI와 규칙 모듈이 직접 호출하지 않고 공통 PersistenceCoordinator를 통과한다.
- CommitGroup은 영속 기록 성공 여부와 권위 revision을 추적한다.
- 모든 영속 명령은 idempotency key를 가진다.
- 활성 캠페인에는 단일 작성자 lease와 fencing token을 적용한다.
- 재접속은 클라이언트가 보낸 과거 상태를 신뢰하지 않고 서버 상태를 다시 투영한다.
- 장애 테스트에는 저장 중 종료, 주사위 공개 중 종료, 효과 일부 확정 후 종료, 중복 서버와 마이그레이션 실패를 포함한다.
