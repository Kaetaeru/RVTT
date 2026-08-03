# ADR-0043: 전투는 턴별 복구 타임라인을 유지하고 DM이 안전한 턴 경계로 되돌릴 수 있다

- 상태: 확정
- 결정일: 2026-08-03
- 관련 문서:
  - [`ADR-0018`](../architecture/effect-recipe-resolution-and-commit-model.md)
  - [`ADR-0028`](ADR-0028-effect-recipes-pending-effects-and-commit-groups.md)
  - [`ADR-0033`](ADR-0033-server-authoritative-dice-rolls-and-presentation-gated-resolution.md)
  - [`ADR-0034`](ADR-0034-encounter-initiative-turn-order-and-control-authority.md)
  - [`ADR-0042`](ADR-0042-authoritative-checkpoints-command-journal-and-session-recovery.md)
  - [`37. 전투 턴 스냅샷 타임라인과 DM 되돌리기 모델`](../systems/combat/encounter-turn-snapshot-and-dm-rollback-model.md)

## 배경

전투에서는 규칙 오류, 잘못된 대상 선택, 토큰 오조작, 연결 종료, DM의 판정 번복, 숨겨진 오브젝트의 잘못된 공개와 같은 예외가 언제든 발생할 수 있다.

일반 자동 저장과 인카운터 시작 전 체크포인트만으로는 다음 요구를 만족하지 못한다.

- 몇 턴 전의 정확한 HP, 위치, 자원과 상태로 돌아가기
- 잘못 처리된 한 턴만 다시 진행하기
- 전투 도중 서버가 종료되어도 마지막 턴 경계를 복원하기
- 되돌리기 전에 무엇이 달라지는지 확인하기
- 복구 후 오래된 클라이언트 명령과 피해가 다시 적용되는 것을 막기

## 결정

모든 활성 인카운터는 독립적인 `EncounterRollbackTimeline`을 가진다.

```text
EncounterRollbackTimeline
├─ encounterId
├─ rootCheckpointId
├─ activeBranchId
├─ currentAuthorityRevision
├─ turnCheckpoints[]
├─ rollbackBranches[]
├─ status
└─ retentionPolicy
```

전투 중에는 다음 안전 경계마다 논리적인 턴 스냅샷을 생성한다.

```text
encounter_start
turn_start
turn_end
round_end
encounter_end_candidate
encounter_end_confirmed
```

DM에게는 모든 턴 경계가 타임라인 항목으로 보인다.

```text
전투 시작 직전
라운드 1 · 전사 턴 시작
라운드 1 · 전사 턴 종료
라운드 1 · 고블린 그룹 턴 시작
라운드 1 · 고블린 그룹 턴 종료
라운드 1 종료
...
```

`turn_start`와 `turn_end`는 규칙 절차가 완전히 끝난 안전한 상태만 가리킨다. 해결 중인 공격, 반응창, 주사위 애니메이션, 미확정 DM 승인과 EffectRecipe 중간 단계는 턴 스냅샷이 아니다.

## 스냅샷 의미와 저장 방식

제품과 DM 관점에서는 각 턴의 스냅샷을 모두 유지한다. 구현은 매 턴 전체 월드를 복제할 필요가 없다.

```text
EncounterBaseSnapshot
+ TurnDeltaJournal
+ 주기적 MaterializedSnapshot
→ 임의의 TurnCheckpoint 복원
```

각 턴 항목은 반드시 독립적으로 선택하고 복원할 수 있어야 한다. 내부적으로 델타 압축, copy-on-write와 저널 재생을 사용하더라도 오래된 턴을 제거해서는 안 된다.

전투가 활성 상태인 동안 전체 턴 타임라인을 유지한다. 전투 종료 후에는 즉시 삭제하지 않고 `recent_encounter_archive`로 동결하며, 최소한 DM이 전투 종료를 확정하고 세션 복구 이력을 닫을 때까지 유지한다.

## 저장 범위

턴 체크포인트는 다음 권위 상태를 복원할 수 있어야 한다.

- 라운드, 턴, 현재 Actor와 InitiativeOrder
- 참가자 상태, 합류·이탈·항복·의식불명·사망 상태
- Actor 위치, 회전, 점유 범위와 이동 상태
- HP, 임시 HP, 죽음 내성, 집중과 지속 효과
- 행동, 보너스 행동, 반응, 이동력과 직업 자원
- 주문 슬롯, Feature 사용 횟수와 충전 자원
- 장비 상태, 아이템 소유권과 전투 중 획득·소비
- 소환체와 일시적으로 생성된 Actor
- 문, 레버, 상자, 함정, 비밀문과 파괴 오브젝트 상태
- 현재 공개 Fog와 관찰자별 탐지·은신 관계
- ActorOwnership, ControlAssignment와 위임 상태
- 봉인된 굴림, 확정된 트랜잭션과 멱등성 식별자

카메라, 커서, Hover, 열린 툴팁, Tween 진행률과 물리 주사위 위치는 저장하지 않는다.

파생 수치와 Capability는 오래된 계산 결과를 권위 원본으로 저장하지 않는다. 복구된 캐릭터·장비·효과 상태와 당시의 규칙·출처 팩 버전을 바탕으로 다시 계산한다.

## DM 되돌리기

DM은 인카운터가 활성 상태인 동안 언제든 `OpenEncounterTimeline`을 열 수 있다.

복구 흐름:

```text
전투 일시정지
→ 턴 체크포인트 선택
→ 현재 상태와 차이 미리보기
→ E로 명시적 복구 승인
→ 현재 분기를 보존
→ 선택한 체크포인트에서 새 권위 분기 생성
→ 클라이언트 전체 재동기화
→ 선택한 턴 경계에서 전투 재개
```

복구는 현재 이력을 삭제하거나 과거 revision을 덮어쓰지 않는다.

```text
기존 Branch A · Revision 284
→ 라운드 2 전사 턴 시작으로 복구
→ Branch B · Revision 285 생성
```

Branch A는 감사와 재복구를 위해 남는다.

## 복구 전 차이 표시

복구 확인 화면은 최소한 다음 변경을 요약한다.

```text
Actor 위치 변경
HP·임시 HP·죽음 내성 변경
행동 자원·주문 슬롯·Feature 자원 변경
상태 효과와 집중 변경
아이템 소유권·소비 변경
소환체 생성·제거
문·함정·파괴 오브젝트 상태 변경
Fog와 탐지 상태 변경
주도권·현재 턴·제어권 변경
무효화될 굴림과 트랜잭션 수
```

DM만 볼 수 있는 숨겨진 정보는 플레이어에게 노출하지 않는다.

## 굴림과 재진행

기본 되돌리기는 상태를 복원한 뒤 새로운 전투 분기를 진행한다.

- 이전 분기에서 공개된 굴림은 기록에 남는다.
- 복구 지점 이후의 굴림과 트랜잭션은 현재 분기에서 무효가 된다.
- 같은 행동을 다시 선택하더라도 새 `resolutionId`와 새 굴림을 사용한다.
- 과거의 유리한 굴림만 선택적으로 재사용하지 않는다.
- 디버그·감사 목적의 정확한 재생은 별도 개발자 도구이며 일반 DM 복구와 구분한다.

이미 플레이어에게 공개된 비밀, 지도와 적 정보는 사람의 기억에서 제거할 수 없다. 시스템은 Fog와 DetectionState를 복원하지만 복구 확인창에서 `공개된 정보는 되돌릴 수 없음`을 DM에게 경고한다.

## 동시 입력과 네트워크 안전

되돌리기가 시작되면 서버는 다음을 수행한다.

```text
새 ActionIntent 접수 중단
→ 활성 반응·승인 창 동결
→ 미확정 Resolution 안전 취소 또는 안전 경계 완료
→ rollback fencing token 증가
→ 선택 체크포인트 복원
→ authorityRevision 증가
→ 모든 클라이언트에 전체 재동기화
```

복구 이전 revision을 가진 이동, 공격, 반응과 인벤토리 명령은 모두 거절한다. 이미 확정된 과거 피해와 자원 소모가 네트워크 재전송으로 다시 적용되어서는 안 된다.

## 성능과 보존

턴마다 전체 장면을 직렬화하지 않는다.

- 인카운터 시작 시 전체 기준 스냅샷 생성
- 각 턴 경계에서 변경된 도메인만 델타 기록
- 각 라운드 종료 또는 정책상 간격마다 물질화된 전체 스냅샷 생성
- 최근 체크포인트는 서버 메모리에 유지
- 모든 턴 경계의 복구 정보는 영속 저널에 flush
- 매우 긴 전투도 모든 턴을 논리적으로 선택할 수 있도록 델타를 압축하되 삭제하지 않음

저장 실패 시 턴 종료를 성공적으로 저장했다고 표시하지 않는다. 메모리 타임라인은 유지하고 DM에게 영속화 지연 상태를 알린다.

## 권한과 감사

턴 복구는 DM 전용 권한이다.

모든 복구는 다음을 기록한다.

```text
rollbackId
DM userId
sourceCheckpointId
targetCheckpointId
sourceBranchId
newBranchId
reason
confirmedAt
affectedEntityIds
```

플레이어에게는 공개 가능한 수준으로 `DM이 전투를 라운드 2 전사 턴 시작으로 복구했습니다`라고 알린다. 비밀 정보와 상세 변경값은 표시하지 않는다.

## 결과

### 장점

- DM이 규칙 오류와 오조작을 전투 전체 재시작 없이 수정할 수 있다.
- 전투 중 서버 장애에도 마지막 턴 경계로 안전하게 복원할 수 있다.
- 되돌리기가 새 분기를 만들기 때문에 원본 이력과 감사 기록이 보존된다.
- 긴 전투에서도 모든 턴이 복구 가능한 논리적 스냅샷으로 남는다.

### 비용

- 전투 상태의 델타 추적과 분기 복구 구현이 필요하다.
- Fog, 탐지, 오브젝트와 아이템까지 일관되게 복원해야 한다.
- 이미 사람에게 공개된 비밀 정보는 완전히 되돌릴 수 없다.

## 금지 사항

- 활성 전투의 오래된 턴 스냅샷을 임의로 삭제하지 않는다.
- 해결 중간 상태를 정상 턴 체크포인트로 표시하지 않는다.
- 복구 시 현재 이력을 파괴적으로 덮어쓰지 않는다.
- 이전 revision의 클라이언트 명령을 복구 후 적용하지 않는다.
- 과거 굴림 결과를 선택적으로 재사용해 결과만 바꾸지 않는다.
- 플레이어 클라이언트가 임의로 턴 복구를 실행하지 못하게 한다.
