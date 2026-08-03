# 공통 기반 규약 공백 감사

- 상태: 검토 필요
- 문서 종류: Audit
- 즉시 구현 명세 가능성: 해당 없음
- 작성일: 2026-08-03
- 관련 문서:
  - [`플랫폼·이동·입력 범위`](../product/platform-movement-and-input-scope.md)
  - [`이동 의미 레이어 자동 제작 파이프라인`](../systems/navigation/navigation-authoring-pipeline.md)
  - [`장면과 월드`](../systems/scene/scenes-and-world.md)
  - [`주문 대상 지정·영역·공간 질의 모델`](../systems/rules/spell-targeting-area-and-spatial-query-model.md)
  - [`인카운터·주도권·턴과 제어권`](../systems/combat/encounter-initiative-turn-and-control-authority-model.md)
  - [`Recipe Step Runtime Foundation`](../specs/shared/001-recipe-step-runtime-foundation.md)
  - [`Standard Step Handler Contracts`](../specs/shared/002-standard-step-handler-contracts.md)

## 1. 목적

현재 기획은 기능별 사용자 경험과 규칙 실행 구조가 상당히 구체화되어 있다. 그러나 여러 기능이 공통으로 의존하는 기반 규약 중 일부는 이름만 존재하거나 제작 파이프라인만 있고, 실제 런타임 계약이 정해지지 않았다.

이 상태에서 `RollAttack`, `ApplyDamage`, `MoveActor`, `SelectTargets` 같은 개별 Recipe Step 명세를 계속 작성하면 다음 문제가 발생한다.

- Step마다 서로 다른 공간·거리·충돌 규칙을 가정한다.
- 이동과 시야가 서로 다른 월드 표현을 사용한다.
- 클라이언트와 서버의 위치 보정 방식이 기능별로 달라진다.
- 동적 문·함정·소환체가 경로, 시야와 범위에 다르게 반영된다.
- 재접속과 롤백 시 실행 순서가 재현되지 않는다.
- 나중에 공통 기반을 확정하면서 이미 작성한 명세를 대량 수정하게 된다.

따라서 개별 규칙 Step 명세를 확대하기 전에 아래 공통 규약의 제품 결정과 시스템 기획을 먼저 완료해야 한다.

## 2. 판정 기준

```text
READY
→ 현재 문서만으로 구현 명세를 작성할 수 있다.

READY_WITH_DEFAULTS
→ 구조는 확정됐고 수치·기본값만 정하면 된다.

BLOCKED
→ 둘 이상의 구현이 제품 동작을 바꾸므로 먼저 결정해야 한다.

MISSING
→ 독립적인 권위 문서가 없다.
```

---

# 3. P0 — 개별 규칙 Step 명세 전에 필요한 기반

## P0-1. 런타임 경로 탐색과 이동 실행

상태: `BLOCKED`

현재 확정된 것은 다음뿐이다.

```text
권위 위치: 연속 좌표
권위 경로: 이동 가능 표면과 연결 그래프
규칙 격자: 없음
전투: 클릭 경로 이동
탐험: 클릭 이동 + WASD
```

이동 의미 레이어 문서는 장면에서 이동 데이터를 만드는 방법을 설명하지만, 실제 런타임 경로 탐색과 이동 명령의 계약은 정하지 않는다.

반드시 결정해야 하는 항목:

### 경로 표현

- 내비게이션 메시, 표면 그래프, waypoint graph 또는 혼합 구조 중 무엇을 권위 표현으로 사용하는가
- 경로 결과가 점 목록인지 표면 구간과 연결 링크의 목록인지
- 같은 시작점과 목적지에서 결과가 결정적으로 동일해야 하는가
- 경로 길이는 직선 거리, 표면 거리 또는 비용 가중 거리 중 무엇인가

### 토큰 형상

- 크기별 수평 footprint
- 높이와 머리 공간 clearance
- 회전 시 footprint 처리
- 비정형 OBJ 토큰의 시각 크기와 규칙상 CreatureSize의 관계
- 통로 통과 가능 여부를 판단하는 기준

### 표면과 높이

- 최대 보행 경사
- 자동으로 넘을 수 있는 최대 턱 높이
- 낙하 가능한 높이와 낙하 확인
- 계단·사다리·점프·등반·비행·수영 연결의 표현
- 다층 표면이 같은 XZ에 겹칠 때 어느 표면을 선택하는가

### 동적 장애물

- 문, 이동식 가구, 파괴 오브젝트, 소환체와 다른 Actor가 경로를 언제 무효화하는가
- Actor를 완전 장애물, 통과 가능 우호 Actor, 임시 점유물 중 어떻게 처리하는가
- 경로 계산 후 실행 전에 장애물이 생겼을 때 재탐색·중단·부분 이동 중 무엇을 하는가

### 전투 이동 실행

- 경로 전체를 한 명령으로 예약하는가
- 이동 중 안전 경계의 간격과 정의
- 기회공격, 준비 행동, 함정, 위험 영역과 시야 공개가 경로의 어느 지점에서 평가되는가
- 중단 후 남은 경로를 자동 재개하는가, 플레이어가 다시 승인하는가
- 부분 이동의 이동력 소비와 롤백 기록 방식

### 탐험 WASD

- 클라이언트 예측 범위
- 서버 승인 주기
- 최대 위치 오차와 보정 방식
- 장애물 충돌 중 입력 누적 처리
- WASD와 클릭 이동 명령의 상호 취소 규칙

권장 문서:

```text
systems/navigation/runtime-pathfinding-and-movement-execution.md
```

이 문서가 확정되기 전 `MoveActor`, `PushActor`, `PullActor`, `TeleportActor`, 위험 영역 진입 Step은 `BLOCKED`다.

## P0-2. 통합 공간 질의 계약

상태: `BLOCKED`

현재 거리, 경로, 시야, 엄폐, AoE, 충돌과 Fog가 각각 공간 정보를 사용하지만 모두 같은 공간 서비스와 판정 순서를 사용한다는 보장이 없다.

통합해야 하는 질의:

```text
Distance
PathDistance
Reachability
LineOfSight
LineOfEffect
Cover
Containment
Overlap
NearestValidPoint
SurfaceProjection
Clearance
Occupancy
RegionEntryExit
```

결정해야 하는 항목:

- 거리 측정 기준점: pivot, footprint 경계, 중심, 가장 가까운 점
- 수직 거리 포함 방식
- 경계에 정확히 닿은 Actor의 포함 여부
- 원뿔·구·원통·선 영역의 연속 좌표 판정
- 엄폐와 시야를 동일 ray 집합으로 계산하는지
- 투명하지만 충돌하는 오브젝트와 보이지만 차단하지 않는 오브젝트 처리
- 문 상태 변경 후 질의 캐시 무효화
- 클라이언트 미리보기와 서버 최종 판정의 허용 오차

권장 문서:

```text
architecture/authoritative-spatial-query-contract.md
```

`SelectTargets`, `ValidateRange`, `ValidateLineOfSight`, `QueryAreaTargets`, `MoveActor` 명세의 선행 조건이다.

## P0-3. Actor·SceneObject 생명주기와 참조 무결성

상태: `MISSING`

현재 여러 문서에서 Actor, Character, NPC, SceneObject와 Item의 ID·revision을 참조하지만 생성부터 제거까지의 공통 생명주기가 없다.

결정해야 하는 항목:

```text
Created
Staged
Active
Hidden
Disabled
Destroyed
Archived
```

- Spawn이 언제 권위 상태가 되는가
- 삭제와 파괴의 차이
- 전투 중 제거된 Actor 참조를 PendingEffect가 보유할 때 처리
- SceneObject가 다른 Scene으로 이동할 수 있는가
- 소환체·임시 오브젝트의 owner와 cleanup 정책
- Character와 현재 Actor가 분리되거나 다시 연결되는 시점
- tombstone을 얼마 동안 유지하는가
- 롤백으로 파괴된 엔티티를 복원할 때 동일 ID를 사용하는가

권장 문서:

```text
architecture/authoritative-entity-lifecycle-and-reference-contract.md
```

## P0-4. 권위 명령 순서와 논리 시간

상태: `MISSING`

서버 권위, transaction, revision과 Command Journal은 정의되어 있지만, 서로 다른 시스템에서 동시에 발생한 명령의 전역 순서를 정하는 규약이 없다.

결정해야 하는 항목:

- 서버 tick, command sequence, revision의 관계
- 같은 프레임에 들어온 두 플레이어 명령의 순서
- 턴 기반 명령과 실시간 탐험 명령의 공통 ordering
- 문 열기와 이동, 피해와 집중 판정, 제어권 변경과 행동 제출이 경쟁할 때 우선순위
- 과거 revision 요청을 재시도할지 거부할지
- 하나의 transaction이 여러 aggregate를 변경할 때 revision 증가 방식
- Rollback branch에서 논리 시간이 어떻게 새로 시작되는가

권장 문서:

```text
architecture/authoritative-command-ordering-and-logical-time.md
```

Recipe runtime의 멱등성과 복구가 이 규약에 의존한다.

## P0-5. 네트워크 요청·응답 공통 봉투

상태: `MISSING`

각 기능 문서가 `requestId`, `executionId`, `expectedRevision`을 개별적으로 사용하지만 모든 Remote가 따라야 하는 공통 계약은 없다.

공통 필드 후보:

```text
protocolVersion
requestId
sessionId
playerId
commandType
sentAtClient
expectedAuthorityRevision
payloadSchemaVersion
payload
```

결정해야 하는 항목:

- RemoteEvent와 RemoteFunction 사용 원칙
- 요청 크기 제한
- 기능별·플레이어별 rate limit
- 중복 요청 보존 기간
- 응답 timeout과 재전송
- 오래된 클라이언트 protocol 거부
- 악성 또는 과도한 payload 처리
- 사용자 오류와 보안 위반 로그의 분리

권장 문서:

```text
architecture/network-command-envelope-and-validation-contract.md
```

## P0-6. 복제 가시성과 비밀 정보 경계

상태: `BLOCKED`

Fog, 숨은 적, 비밀문, DM 전용 문서와 미확인 아이템이 존재하지만 서버가 어떤 데이터를 어느 클라이언트에 복제하는지에 대한 단일 정책이 없다.

결정해야 하는 항목:

- 보이지 않는 Actor의 Instance 자체를 클라이언트에 복제하는가
- 숨은 적의 위치를 클라이언트 메모리에 절대 보내지 않는가
- 플레이어별 관찰 상태와 파티 공유 상태의 관계
- DM 전용 SceneObject와 Trigger의 복제 여부
- 미확인 아이템의 실제 DefinitionId 노출 여부
- 저널 제목·링크·검색 인덱스의 권한 필터 시점
- Observer가 보는 범위
- 롤백 후 이미 복제된 비밀 데이터를 어떻게 다시 숨기는가

권장 문서:

```text
architecture/observer-scoped-replication-and-secret-data-contract.md
```

단순 UI 숨김은 보안 경계로 인정하지 않아야 한다.

## P0-7. Scene 스트리밍·로딩·활성화 경계

상태: `MISSING`

Scene 데이터와 중도 참여는 기획됐지만 대형 Scene을 언제 로드하고 활성화하며 제거하는지 정해지지 않았다.

결정해야 하는 항목:

- 한 서버에서 동시에 활성화할 수 있는 Scene 수
- 플레이어별 StreamingEnabled와 권위 Actor의 관계
- Scene 진입 전 필수 데이터 barrier
- 지형·오브젝트·Actor·Fog·Navigation·Lighting 로딩 순서
- 일부 에셋 로딩 실패 시 진입 허용 여부
- 중도 참여자가 현재 행동 해결 중 들어왔을 때 snapshot 기준
- Scene 전환 중 기존 Scene 명령의 접수 중단 시점
- 멀리 있는 오브젝트의 서버 물리·충돌·질의 포함 여부

권장 문서:

```text
architecture/scene-streaming-loading-and-activation-contract.md
```

---

# 4. P1 — 기반 구현 전에 확정할 규약

## P1-1. 물리와 규칙 이동의 경계

상태: `BLOCKED`

리그 없는 OBJ 토큰을 Roblox 물리로 직접 움직일지, 서버가 CFrame을 권위적으로 갱신하고 물리는 표현에만 사용할지 명시해야 한다.

권장 방향:

```text
규칙 위치·충돌·경로
→ RVTT 권위 공간 모델

Roblox 물리
→ 시각 보간과 제한된 환경 연출
```

네트워크 소유권을 플레이어에게 넘긴 물리 토큰을 규칙 권위로 사용하지 않는 편이 안전하다.

## P1-2. 점유·겹침·밀집 규칙

상태: `MISSING`

- 우호 Actor와 같은 공간 통과
- 적 Actor 통과
- 턴 종료 시 겹침 금지 여부
- Tiny·Small·Large 크기 차이
- 소환체 다수의 밀집
- 강제 이동으로 유효 위치가 없을 때 처리
- 비행 Actor의 수직 점유

D&D 규칙과 무격자 3D 공간을 연결하는 별도 정책이 필요하다.

## P1-3. 이동 유형과 능력

상태: `MISSING`

보행 외에 다음이 아직 공통 모델로 정리되지 않았다.

```text
Climb
Swim
Fly
Burrow
Jump
Fall
Hover
Teleport
MountedMovement
```

각 이동 유형이 어떤 Navigation layer와 공간 질의를 사용하는지 정해야 한다.

## P1-4. 동적 월드 변경의 캐시 무효화

상태: `MISSING`

문 열림, 벽 파괴, 오브젝트 Tween, 조명 변경과 Fog 편집 후 다음 캐시를 어떻게 갱신하는지 필요하다.

- pathfinding
- line of sight
- cover
- area query
- visibility
- Fog assist
- interaction reachability

부분 갱신 영역과 갱신 완료 전 명령 처리 정책을 정해야 한다.

## P1-5. Undo·DM Override·Rollback의 관계

상태: `BLOCKED`

세 가지가 모두 과거 상태를 바꾸지만 목적이 다르다.

```text
Editor Undo
→ 아직 게시되지 않은 편집 명령 취소

DM Override
→ 현재 권위 상태를 새 명령으로 수정

Encounter Rollback
→ 과거 체크포인트에서 새 분기 생성
```

어떤 작업이 어느 시스템을 사용하며 기록과 권한이 어떻게 다른지 단일 규약이 필요하다.

## P1-6. Content Pack 의존성·버전·비활성화

상태: `MISSING`

Recipe와 Step schemaVersion은 있으나 Source Pack이 다른 Pack의 Step·Feature·Item을 참조할 때의 의존성 계약이 없다.

- dependency graph
- load order
- missing dependency
- version constraint
- campaign이 사용 중인 Pack 비활성화
- 저장 데이터에 참조된 Definition 제거
- migration과 fallback placeholder

## P1-7. 권한과 Capability의 시스템 관리 범위

상태: `READY_WITH_DEFAULTS`

규칙 Capability와 사용자 권한이 같은 용어로 혼동될 위험이 있다.

다음을 분리해야 한다.

```text
RuleCapability
→ 캐릭터가 어떤 규칙 행동을 할 수 있는가

UserPermission
→ 사용자가 어떤 관리 작업을 할 수 있는가

ControlAssignment
→ 현재 어떤 Actor 입력을 제출할 수 있는가
```

공통 권한 검사 순서와 DM Override 감사 로그를 정해야 한다.

## P1-8. 성능 예산과 부하 등급

상태: `MISSING`

“최적화 필수” 원칙만 있고 시스템별 수치 예산이 없다.

필요한 최소 부하 프로필:

```text
Small Scene
Standard Scene
Large Scene
Stress Scene
```

각 프로필에 대해 다음을 정해야 한다.

- SceneObject 수
- 활성 Actor 수
- 동시 Recipe 실행 수
- path query 수
- spatial query 수
- Fog 영역 수
- 문서 크기
- 저장 chunk 수
- 서버 프레임·메모리·네트워크 예산

## P1-9. 오류 등급·관찰성·안전 모드

상태: `MISSING`

기능별 오류 코드는 많지만 시스템 전체의 오류 등급과 운영 정책이 없다.

```text
UserError
RuleRejection
RecoverableSystemError
ContentError
DataIntegrityError
SecurityViolation
FatalSessionError
```

각 등급별로 사용자 표시, DM 경고, 서버 로그, 자동 재시도, 세션 일시정지와 복구 화면 진입 여부를 정해야 한다.

## P1-10. 테스트 월드와 결정적 재현

상태: `MISSING`

다음 공통 테스트 기반이 필요하다.

- 고정 seed 굴림
- 명령 로그 재생
- 작은 표준 Navigation 시험장
- 문·계단·경사·다층·험지 fixture
- 네트워크 지연·중복·순서 뒤바뀜 주입
- 서버 종료·복구 fixture
- 롤백 branch 비교
- 권한·비밀 정보 누출 검사

---

# 5. P2 — 구현 중 기본값을 정해도 되는 규약

다음은 공통 문서에 자리를 마련하되 프로토타입 측정 후 기본값을 확정해도 된다.

- 경로 미리보기 선의 보간 품질
- 서버 위치 보정 Tween 시간
- 카메라 추적 완충값
- 작은 바닥 틈 자동 연결 허용치
- 경사와 턱의 초기 수치
- path query timeout
- Remote rate limit 구체 수치
- 캐시 유지 시간
- 로그 보존 기간
- 화면상 경로점 단순화 오차

이 값들은 제품 구조를 바꾸지 않으므로 `READY_WITH_DEFAULTS`로 관리할 수 있다.

---

# 6. 기존 문서의 준비도 수정 필요

## `platform-movement-and-input-scope.md`

현재 `READY`로 표시되어 있으나, 제품 범위 문서로서는 확정됐어도 이동 구현 명세의 선행 기획은 아니다.

권장:

```text
문서 자체 준비도: READY
런타임 이동 시스템 준비도: BLOCKED
```

## `standard-recipe-step-library.md`

Step Library의 공통 구조는 `READY`지만 다음 Step 군은 선행 기반이 없어 개별 명세를 작성하면 안 된다.

```text
BLOCKED
- 공간 선택과 범위 검증
- Actor 이동과 강제 이동
- 순간이동 유효 지점
- 영역 진입·퇴장
- 소환 위치 선택
- SceneObject 상태 변경 후 공간 캐시 갱신

진행 가능
- 순수 수치 계산
- 자원 검증과 예약
- 서버 권위 굴림 기록
- 비공간적 분기
- PendingEffect 생성 계약
```

## 현재 `specs/shared/001`, `002`

공통 런타임과 handler 경계 명세는 유지할 수 있다. 다만 실제 서비스 타입인 `AuthoritativeWorldView`, `SpatialQueryService`, `ReferenceResolver`, `CommandJournal`은 위 공통 기반 문서가 확정된 뒤 구체화해야 한다.

---

# 7. 권장 진행 순서

```text
1. 런타임 Pathfinding·Movement Execution
2. 통합 Spatial Query Contract
3. Entity Lifecycle·Reference Integrity
4. Command Ordering·Logical Time
5. Network Envelope·Validation
6. Observer-scoped Replication·Secret Data
7. Scene Streaming·Activation
8. Physics Boundary·Occupancy·Movement Modes
9. Dynamic Cache Invalidation
10. Undo·Override·Rollback 관계
11. Content Pack Dependency
12. Performance·Observability·Test Harness
13. 이후 개별 Recipe Step 명세 재개
```

## 8. 결론

Recipe Step Runtime 기반 명세를 작성한 방향은 유효하다. 하지만 개별 Step Library를 계속 세분화하기 전에, Step들이 의존하는 월드·공간·명령·복제 기반을 먼저 확정해야 한다.

가장 먼저 다뤄야 하는 것은 `런타임 Pathfinding·Movement Execution`이다. 이 문서가 정해져야 이동뿐 아니라 기회공격, 함정, 위험 영역, 시야 공개, 소환 위치와 강제 이동이 동일한 규약을 사용할 수 있다.
