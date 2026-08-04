# RVTT Feedback, Error and Recovery Policy

- 상태: CURRENT
- 문서 종류: Global UX Feedback Policy
- 작성일: 2026-08-05
- Policy Work Order: [`CURRENT-WORK-ORDER`](CURRENT-WORK-ORDER.md)
- Networking 권위: [`Networking Command와 Client Synchronization`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
- Persistence 권위: [`Persistence와 Session Recovery`](../../architecture/persistence-and-session-recovery-model.md)
- Diagnostics 권위: [`Diagnostics와 Observability`](../../architecture/diagnostics-observability-correlated-trace-and-incident-runtime-contract.md)

이 문서는 사용자 행동이 제출된 뒤 완료·거부·대기·재시도·재동기화·복구되는 과정을 일관된 화면 상태로 표현하는 방법을 정의한다.

## 1. 핵심 원칙

```text
입력을 받았음을 즉시 알린다.
→ 처리 위치와 상태를 보여준다.
→ 권위 결과는 Projection으로 확정한다.
→ 실패 이유와 가능한 다음 행동을 보여준다.
→ 복구 후 현재 상태를 다시 확인시킨다.
```

- UI Animation과 Toast는 Authority 결과가 아니다.
- Command Result만으로 HP·Item·Turn·Scene 상태를 직접 변경하지 않는다.
- 사용자는 같은 행동을 다시 눌러야 하는지, 기다려야 하는지, 재선택해야 하는지 구분할 수 있어야 한다.
- 오류를 숨기기 위해 자동 재시도를 무한히 반복하지 않는다.
- 비밀 정보는 Error, Support Reference와 Diagnostic에도 포함하지 않는다.

## 2. Action Lifecycle 표현

모든 Authority Action은 필요한 범위에서 다음 상태를 가진다.

```text
ready
→ intent_created
→ submitted
→ receipt_received
→ processing
→ terminal_result
→ awaiting_projection
→ reconciled
```

종료 변형:

```text
cancelled
denied
expired
stale
retryable_failure
resync_required
recovery_required
```

표현 규칙:

- `submitted`: Control에 Pending 상태와 중복 제출 차단을 적용한다.
- `receipt_received`: 서버가 요청을 받았지만 결과가 아직 확정되지 않았음을 표시한다.
- `awaiting_projection`: 결과 메시지는 받았지만 화면 권위 상태는 아직 Projection을 기다린다.
- `reconciled`: 최신 Projection에서 실제 결과가 확인됐다.
- 권위 수치는 `reconciled` 전에 성공값으로 확정 표시하지 않는다.

## 3. Local Feedback과 Authority Feedback

### Local Feedback

다음 렌더 단계에서 보여줄 수 있다.

- Button Press
- Selection Highlight
- Drag Ghost
- Path Preview
- 제출 Indicator

Local Feedback에는 Preview 또는 Pending임을 나타내는 시각 상태가 있어야 한다.

### Authority Feedback

서버 검증·Commit·Projection 이후에만 확정한다.

- 위치
- HP·Resource
- Item Location
- Turn·Opportunity
- Scene·Fog·Object State
- Character Build·Level

Local Preview와 Authority Result가 다르면 Correction을 숨기지 않고 짧게 설명한다.

## 4. Notification Surface 선택

### Inline State

현재 Control·Field·Card와 직접 관련된 결과. 가장 우선한다.

### Tooltip·Reason Panel

Disabled, Denied, Stale 이유와 해결 조건.

### Toast

비차단 단일 결과. 짧고 행동 가능한 경우에만 Action을 포함한다.

### Banner

Session 전체에 영향을 주는 연결·저장·Mode·권한 상태.

### Authority Prompt

사용자 응답을 기다리는 서버 상태.

### Critical Modal

데이터 손실, Rollback, Publish, Pack 제거처럼 다른 입력을 막아야 하는 결정.

### Recovery Surface

Projection 불일치, 재접속, 서버 복구처럼 현재 Authority-bound 입력을 일시 차단하는 상태.

같은 사건을 Toast, Banner와 Modal로 중복 표시하지 않는다.

## 5. 메시지 작성 규칙

사용자 메시지 순서:

```text
무슨 일이 일어났는가
→ 현재 상태
→ 사용자가 할 수 있는 행동
→ 필요 시 Support Reference
```

좋은 예:

```text
대상이 이동해 공격을 실행하지 못했습니다.
최신 위치를 불러왔습니다. 대상을 다시 선택하세요.
```

나쁜 예:

```text
Error 409
Invalid revision
```

- 내부 Stable Error Code는 진단용으로 보존하되 사용자 문구와 분리한다.
- Raw Stack, DataStore Key, Secret ID와 권한 밖 Entity를 표시하지 않는다.
- 사용자 책임이 아닌 오류에 “잘못했습니다” 같은 비난 표현을 사용하지 않는다.
- 재시도해도 해결되지 않는 상태에 Retry를 제공하지 않는다.

## 6. Error 분류

### Validation

입력 형식·범위·필수 선택 문제. Field 또는 대상 근처에 표시한다.

### Eligibility

현재 자원·Turn·Mode·Capability 때문에 실행 불가. 조건과 해결 가능성을 보여준다.

### Permission

권한 부족. 존재 여부를 공개할 수 없는 대상은 일반화된 문구를 사용한다.

### Conflict·Stale

Revision·Incarnation·대상 상태 변경. 최신 Projection 적용 후 재선택 또는 Rebase 경로를 제공한다.

### Transient Infrastructure

Network·Storage·Service 일시 실패. 안전한 경우 제한된 자동 재시도와 상태 표시를 제공한다.

### Integrity·Recovery

부분 상태, Manifest·Journal 검증 실패, 복구 지점 검토 필요. 일반 행동을 Gate하고 DM·Operator Recovery Flow로 연결한다.

### Client Presentation

Panel·VFX·Camera·Tooltip 오류. Gameplay Authority를 Rollback하지 않고 Fallback UI를 사용한다.

## 7. Retry 정책

자동 Retry 허용 조건:

- 동일 멱등성 Key로 안전하다.
- 사용자 선택과 권한이 아직 유효하다.
- Retry 횟수와 종료 조건이 제한돼 있다.
- 중복 Commit이 불가능하다.

자동 Retry 금지:

- 비용·대상·의도가 최신 상태에서 달라질 수 있다.
- 파괴 행동이다.
- 이전 AuthorityEpoch·ConnectionEpoch 요청이다.
- 사용자의 새 선택이 필요하다.

Retry 중에는 `retrying`과 마지막 안전 상태를 보여준다.

## 8. Projection Gap과 Resync

```text
Sequence Gap·Integrity Failure
→ Authority-bound 입력 Gate
→ Last Known Good Replica 유지
→ Catch-up 요청
→ 실패 시 Full Resync
→ Atomic Replica 교체
→ ViewModel·Focus·Prompt 재구성
```

- 깨진 중간 상태를 화면에 부분 적용하지 않는다.
- Resync 중에도 Camera와 Local Layout은 안전한 범위에서 유지할 수 있다.
- 이전 Pending Command가 새 Replica에서 확인되지 않으면 명확하게 종료한다.
- 사용자가 제출하지 않은 Draft를 자동 Commit하지 않는다.

## 9. Reconnect 정책

Reconnect 화면은 다음 단계를 구분한다.

```text
연결 감지
→ 재접속 시도
→ Session 인증·Role 확인
→ Projection Snapshot 수신
→ Scene·Controlled Actor Ready
→ 입력 재개
```

- 단순 Spinner만 표시하지 않는다.
- 현재 성공한 단계와 실패한 단계를 보여준다.
- Local Layout·Accessibility는 유지할 수 있다.
- Authority Prompt·Selection·Turn·Item·Scene 상태는 서버에서 복원한다.
- 오래된 ConnectionEpoch의 응답은 폐기한다.

## 10. Rollback·Branch 변경

Rollback 전에:

- Target Checkpoint
- 현재와 대상의 주요 Diff
- 영구적으로 지울 수 없는 Player Knowledge 경고
- 영향을 받는 Scene·Turn·Character·Item·Time 범위
- 승인 주체

Rollback 후:

```text
새 AuthorityEpoch
→ 이전 Prompt·Command·Selection·ACK 폐기
→ Full Resync
→ 현재 Branch·Checkpoint 표시
→ 입력 재개
```

과거 Roll 결과나 성공 Command를 선택적으로 재사용하지 않는다.

## 11. Save·Publish·Migration Feedback

다음을 별도 상태로 표시한다.

```text
Local Draft
Auto Save
Source Revision Saved
Compile Running
Candidate Ready
Publish Pending
Published
Live Session Unchanged
Live Patch Pending
Migration Required
Recovery Review Required
```

“저장됨” 하나로 합치지 않는다.

## 12. Empty·Unavailable·Failure 복구

- 데이터가 없으면 Empty 이유와 생성·가져오기 경로를 제공한다.
- 권한 없음은 Request Access를 임의 제공하지 않는다.
- Stream Out 대상은 삭제로 표시하지 않는다.
- Missing Content는 최신 콘텐츠로 자동 치환하지 않고 Missing Reference와 Recovery 상태를 표시한다.
- Panel 오류는 Panel Error Boundary 안에서 복구하며 다른 HUD를 유지한다.

## 13. Support Reference

심각하거나 반복되는 오류에는 안전한 Support Reference를 제공한다.

포함 가능:

- Incident Fingerprint
- Correlation ID의 사용자용 축약
- 발생 시각
- 공개 가능한 Action·Surface 이름

포함 금지:

- Raw Trace
- User Secret
- DataStore Key
- 숨은 Entity ID
- Stack·Credential

## 14. 금지 패턴

- Spinner만 있고 상태 설명이 없음
- 낙관적으로 권위 수치 변경 후 실패 시 조용히 되돌림
- 동일 오류 Toast 무한 반복
- 모든 오류를 Modal로 표시
- 권한 거부 메시지로 숨은 대상 존재 암시
- Retry가 중복 비용·Commit을 만들 수 있음
- Reconnect 후 이전 Prompt와 Pending을 재사용
- Panel 오류 때문에 Session 전체를 종료
- “알 수 없는 오류”만 표시하고 Support Reference도 없음

## 15. 구현 검수

- Action Lifecycle이 ViewModel에 표현된다.
- Local Preview와 Authority Result가 구분된다.
- Denied·Stale·Retry·Resync의 다음 행동이 명확하다.
- Projection Gap에서 부분 상태를 적용하지 않는다.
- Reconnect·Rollback 후 이전 Epoch 상태가 남지 않는다.
- Error 문구가 비밀 정보를 노출하지 않는다.
- Presentation 실패가 Gameplay 결과를 변경하지 않는다.
- 심각 오류에 안전한 Support Reference가 있다.
