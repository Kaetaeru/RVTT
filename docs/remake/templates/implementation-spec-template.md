# Implementation Spec: <기능 또는 수직 Slice 이름>

- 상태: 초안
- 문서 종류: Implementation Spec
- 구현 상태: 미구현
- 즉시 구현 가능성: BLOCKED
- 작성일:
- 최종 검토일:
- 관련 Quick Flow 구간:
  - [`한눈에 보는 세션 흐름`](../user-guides/QUICK-FLOW.md) — <절 또는 구간>
- 관련 User Guide:
  - [`Player Guide`](../user-guides/player/README.md) — <절>
  - [`DM Guide`](../user-guides/dm/README.md) — <절>
- 관련 Main System Guide:
- 관련 Product·Architecture·System·UI:
- 관련 ADR:
- 선행 명세:
- 후속 명세:
- 대체하는 명세:
- 대체된 명세:

> 이 Spec은 확정된 사용자 결과와 권위 문서를 구현 계약으로 변환한다. 새로운 Product 동작이나 Architecture 결정을 이 문서에서 만들지 않는다.

## 1. 목표와 사용자 결과

### 목표

- 사용자가 최종적으로 무엇을 할 수 있게 되는가
- 완료 후 화면과 게임 상태에서 무엇이 달라지는가

### Player Acceptance Flow

```text
<Quick Flow 또는 Player Guide의 시작 상태>
→ <사용자 행동>
→ <대기·확정·거부 상태>
→ <관찰 가능한 성공 결과>
```

해당 없음이면 이유를 적는다.

### DM Acceptance Flow

```text
<DM 준비 또는 진행 상태>
→ <DM 행동 또는 승인>
→ <Player에게 보이는 결과>
→ <DM이 확인할 수 있는 완료 상태>
```

해당 없음이면 이유를 적는다.

### 성공 기준

- 사용자에게 보이는 성공 결과
- 저장·재접속·Scene 전환 후 유지되는 결과
- 권한별로 달라지는 공개 결과

## 2. 범위와 비범위

### 이번 Spec 범위

- 끝까지 구현하고 검증할 수직 책임

### 비범위

- 의도적으로 다루지 않는 기능
- 후속 Spec이 소유하는 기능
- 제품 비목표

### 종료 경계

이번 Spec이 완료됐을 때 정상 지원되는 마지막 상태를 적는다.

## 3. 근거와 추적성

| 요구사항 | Quick Flow·User Guide | 직접 권위 문서·절 | 구현 계약 | 검증 항목 |
|---|---|---|---|---|
|  |  |  |  |  |

규칙:

- Quick Flow와 User Guide는 Acceptance Flow를 제공한다.
- Product·Architecture·System·UI·ADR이 계약의 직접 근거다.
- Main System Guide는 관련 권위 문서를 찾기 위한 탐색 Reference다.
- `DISCONTINUED`, `SUPERSEDED`, `ARCHIVED` 문서는 근거로 사용하지 않는다.

## 4. 현재 구조 조사

| 현재 경로·계약 | 현재 책임 | 재사용·변경·제거 | 이유와 영향 |
|---|---|---|---|
|  |  |  |  |

확인 항목:

- 기존 Service·Module·Registry·Type
- Command·Remote·Projection
- 저장 Schema와 Migration
- 기존 Test·Diagnostics·Budget 측정 경로
- 제거되거나 대체될 Legacy 흐름

존재하지 않는 파일·Type·API는 `신규 제안`으로 표시한다.

## 5. 전체 실행 흐름

```text
사용자 Intent
→ Client UI·Input Context
→ Command 또는 Read Request
→ Permission·Revision·Readiness 검증
→ Domain·RuleExecution
→ Reservation·Transaction
→ Event·Projection
→ 사용자 결과
```

### 정상 흐름

1. 

### 대기·재개 흐름

1. 

### 취소 흐름

1. 

### 재접속·복구 흐름

1. 

## 6. 상태와 전이

| 상태 | 의미 | 진입 조건 | 허용 행동 | 종료 조건 |
|---|---|---|---|---|
|  |  |  |  |  |

```text
<State A>
→ <State B>
→ <Committed 또는 Completed>

<State B>
→ Cancel·Timeout·Disconnect
→ <안전 상태>
```

오래된 Connection Epoch·AuthorityEpoch·Revision의 입력 처리도 명시한다.

## 7. 책임과 권위 경계

| 영역 | 소유 책임 | 읽을 수 있는 값 | 변경 가능한 값 | 소유하지 않는 책임 |
|---|---|---|---|---|
| Client |  |  |  |  |
| Server |  |  |  |  |
| Shared |  |  |  |  |
| Persistence |  |  |  |  |
| DM |  |  |  |  |

반드시 구분한다.

- Source
- Compiled Build
- Authoritative State
- Projection
- Presentation

## 8. 데이터와 Type 계약

### Identity와 Version

- ID 규칙
- Revision·Incarnation·AuthorityEpoch
- Schema Version
- Frozen Build·Policy Version

### 직렬화 Schema

```lua
export type <SerializedType> = {
    schemaVersion: integer,
}
```

### Runtime Type

```lua
export type <RuntimeType> = {
}
```

규칙:

- 필수·선택 필드와 `nil` 의미
- 좌표·거리·시간·수치 단위
- 최대 크기와 상한의 근거
- Roblox Instance 참조와 직렬화 데이터 분리

## 9. Command·Read·Network 계약

| ID | 요청자·권한 | 요청 Schema | 검증 순서 | 성공 결과 | 실패 코드 | 멱등성·순서 |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |

각 계약에 포함한다.

- Protocol·Schema Version
- Command ID·Correlation ID
- expected Revision·Epoch
- Rate·Payload 제한의 측정 또는 추후 측정 계획
- Receipt와 Terminal Result
- Projection Cursor·Gap·Resync
- Client Preview와 Server Correction

## 10. Registry·Compiler·Module 책임

| 경로 또는 Package | 책임 | 공개 계약 | 의존 대상 | 소유하지 않는 책임 |
|---|---|---|---|---|
|  |  |  |  |  |

Registry·Compiler가 있으면 다음을 명시한다.

- 등록 ID와 Version
- 중복·누락·의존성 오류
- Freeze 시점
- Candidate Validation
- Last Known Good 유지
- Extension 실패 격리

## 11. Transaction·Ordering·Event·Projection

```text
Ordering Key
→ Reservation
→ Transaction Plan
→ Authority Commit
→ Domain Event Outbox
→ Projection Barrier
→ Permission-aware Projection
```

정의 항목:

- Ordering Key
- Reservation 범위와 만료
- Commit Group·Invariant
- 부분 실패 안전 상태
- Outbox Event와 Subscriber
- Projection 원자 적용 단위
- Presentation이 Authority를 바꾸지 않는 경계

해당 없음이면 이유를 적는다.

## 12. Persistence·Migration·Rollback

### 저장 원본

- 저장하는 값
- 저장하지 않는 파생값
- Manifest·Chunk 경계
- Journal·Checkpoint 관계

### Migration

- 이전 Schema Version
- 변환 절차
- 반복 실행 안전성
- 실패 시 Last Known Good 또는 복구 경로

### Reconnect·Recovery

- 새 Connection Epoch
- Snapshot·Event Catch-up
- Pending 상태 재개 또는 취소

### Rollback

- 복구 Snapshot과 새 Branch·AuthorityEpoch
- 무효화되는 입력·Projection·Prompt
- 사용자에게 보이는 재동기화 상태

## 13. UI·입력·현지화

| 사용자 상태 | 화면 표시 | 허용 입력 | 비활성·거부 이유 | 복구 안내 |
|---|---|---|---|---|
|  |  |  |  |  |

확인 항목:

- Q·E·1–5의 현재 Context 의미
- Focus와 Text Input 중 단축키 차단
- Loading·Waiting·Denied·Retrying·Resync 상태
- Player·DM·Observer 공개 차이
- 번역 Key와 변수
- 접근성·Layout 설정과 Gameplay Authority 분리

## 14. 실패·동시성·취소

| 상황 | 검출 위치 | 사용자 결과 | Authority 안전 상태 | Retry·Recovery |
|---|---|---|---|---|
| 권한 없음 |  |  |  |  |
| 오래된 Revision·Epoch |  |  |  |  |
| 중복 요청 |  |  |  |  |
| 순서 변경·지연 |  |  |  |  |
| 사용자 이탈 |  |  |  |  |
| Scene·Mode·Turn 변경 |  |  |  |  |
| 저장 실패 |  |  |  |  |
| Module·Subscriber 오류 |  |  |  |  |

## 15. Diagnostics·Budget·Health

### Trace

```text
UI Intent
→ Command
→ RuleExecution 또는 Domain Operation
→ Transaction
→ Event
→ Projection
```

### Stable Error Code

| 코드 | 발생 조건 | 사용자 Message Key | Redaction | Support Reference |
|---|---|---|---|---|
|  |  |  |  |  |

### Budget와 측정

- 측정 대상
- 기준 Scene·Scenario
- Sampling·Aggregation
- Warning·Failure 조건
- 아직 수치가 없다면 수치를 확정할 측정 절차

### Health Probe

- Ready·Degraded·Blocked 조건
- 자동 비활성화와 복구 조건

## 16. 구현 순서

각 단계는 저장소가 실행 가능하고 검증 가능해야 한다.

### 단계 1 — <가장 얇은 End-to-End 흐름>

```text
단계 목표:
변경 책임:
선행 조건:
완성되는 실제 흐름:
검증 방법:
실패 시 안전 상태:
완료 기준:
```

### 단계 2 — <예외·복구 확장>

```text
단계 목표:
변경 책임:
선행 조건:
완성되는 실제 흐름:
검증 방법:
실패 시 안전 상태:
완료 기준:
```

## 17. Test 계획

| ID | 범주 | Scenario | 검증 대상 | 방식 | 예상 결과 |
|---|---|---|---|---|---|
|  | 정상 |  |  | Deterministic |  |
|  | 취소 |  |  | Deterministic |  |
|  | 권한 |  |  | Integration |  |
|  | 중복·순서 |  |  | Fault Injection |  |
|  | 재접속 |  |  | Integration |  |
|  | 저장·Migration |  |  | Integration |  |
|  | Rollback |  |  | Deterministic |  |
|  | 성능 |  |  | Profiling |  |
|  | 정보 누출 |  |  | Negative Disclosure |  |

실제 Roblox Integration Test가 필요한 경계와 Headless Harness에서 검증 가능한 경계를 구분한다.

## 18. 완료 기준

- [ ] Quick Flow의 대상 구간이 실제 사용자 흐름으로 완료된다.
- [ ] Player·DM Acceptance Flow의 성공·대기·거부·복구 상태를 확인할 수 있다.
- [ ] 관련 Authority Documents와 충돌하지 않는다.
- [ ] Source·Build·State·Projection·Presentation이 분리된다.
- [ ] Client Intent와 Server Authority 검증이 분리된다.
- [ ] Version·Migration·Deprecation·Recovery·Rollback 경계가 정의된다.
- [ ] Ordering·Reservation·Transaction·Outbox·Projection Barrier가 필요한 범위에서 정의된다.
- [ ] Trace·Error·Budget·Health가 정의된다.
- [ ] Deterministic Scenario와 Roblox Integration 경계가 정의된다.
- [ ] 각 완료 기준이 Test 또는 측정 항목에 연결된다.
- [ ] 관련 User Guide와 Main System Guide의 변경 영향이 확인된다.
- [ ] 문서 검증 Workflow가 성공한다.

## 19. 미결정 사항과 위험

| 항목 | 구현 차단 여부 | 확인 방법 | 결정 위치 | 후속 조치 |
|---|---|---|---|---|
|  |  |  | Product·Architecture·ADR·측정 |  |

중대한 사용자 흐름·권위·저장·공개 계약이 미결정이면 상태를 `초안`으로 유지한다.

## 20. 변경 영향 지도

| 변경 유형 | 영향받는 User Guide | Main System Guide | Authority Documents | 다른 Specs·Migration |
|---|---|---|---|---|
|  |  |  |  |  |

## 21. 준비 완료 Gate

- [ ] 사용자 결과와 비범위가 명확하다.
- [ ] Quick Flow·User Guide·Authority 추적성이 완성됐다.
- [ ] 기존 코드·Schema·Test 조사 결과가 기록됐다.
- [ ] 상태·권한·Data·Command 계약이 완성됐다.
- [ ] 저장·Migration·Recovery·Rollback 영향이 완성됐다.
- [ ] 실패·동시성·취소의 안전 상태가 완성됐다.
- [ ] 구현 단계마다 실제 흐름과 검증이 존재한다.
- [ ] Test·Diagnostics·Performance 측정 계획이 존재한다.
- [ ] 새로운 Product·Architecture 결정이 남아 있지 않다.

모든 항목을 통과한 뒤에만 상태를 `준비 완료`, 즉시 구현 가능성을 `READY`로 변경한다.