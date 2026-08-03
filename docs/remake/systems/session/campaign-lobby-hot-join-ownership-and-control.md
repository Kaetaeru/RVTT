# 캠페인 로비·중도 참여·소유권·제어권

- 상태: 확정
- 문서 종류: System Planning
- 즉시 구현 명세 가능성: `READY_WITH_DEFAULTS`
- 남은 기본값:
  - 연결 종료 후 자동 인수 대기 시간
  - 세션 Ready 강제 시작 경고 시간
  - Observer의 기본 공개 범위
  - 중도 참여 화면에서 표시할 동기화 단계 문구
- 작성일: 2026-08-03
- 관련 ADR:
  - [`ADR-0049`](../../decisions/ADR-0049-campaign-character-ownership-hot-join-and-control-assignment.md)
  - [`ADR-0058`](../../decisions/ADR-0058-stable-runtime-object-identity-and-command-driven-lifecycle.md)
  - [`ADR-0059`](../../decisions/ADR-0059-versioned-command-protocol-and-projection-stream-synchronization.md)
- 관련 문서:
  - [`Networking Command, Event와 Client Synchronization 계약`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - [`저장·세션 복구 모델`](../../architecture/persistence-and-session-recovery-model.md)
  - [`Runtime Object System과 Entity Lifecycle 계약`](../../architecture/runtime-object-system-and-entity-lifecycle-contract.md)
  - [`인카운터·주도권·턴과 제어권 모델`](../combat/encounter-initiative-turn-and-control-authority-model.md)

## 1. 목적

이 문서는 사용자가 캠페인 로비에 접속하고 Character를 배정받고, 진행 중인 세션에 참가하거나 재접속하며, Actor의 현재 제어권을 안전하게 복원하는 사용자 흐름을 정의한다.

Network Protocol, Snapshot Segment와 Projection Event Schema는 Networking Architecture가 소유한다.

## 2. 데이터 구분

```text
CharacterOwner
→ 캐릭터의 영구적인 캠페인 소유자

ControlAssignment
→ 현재 세션에서 Actor에게 명령을 내릴 수 있는 사용자 또는 시스템

SessionRole
→ DM | Player | Observer

ClientReadyState
→ 현재 Client가 어느 기능을 안전하게 사용할 수 있는지 나타내는 기술 상태
```

이 네 개념을 하나의 `ownerUserId` 또는 `ready` Boolean으로 합치지 않는다.

Owner가 없는 Character는 DM 관리 상태다. DM은 캠페인 관리 화면에서 Owner를 지정·변경·박탈할 수 있다.

## 3. 로비

로비는 다음을 표시한다.

- 캠페인 정보와 재개 가능한 세션 상태
- 현재 접속 사용자와 Session Role
- 배정된 Character와 현재 Controller
- 사용자 Ready 상태
- Client 동기화 상태
- 활성 Scene과 Encounter 요약
- 복구 또는 Migration이 필요한 경고

DM은 다음을 수행할 수 있다.

- Player에게 Owner가 있는 Character 배정
- DM 관리 Character 임시 배정
- Character Owner와 다른 사용자에게 임시 Controller 배정
- Observer 입장 허용 또는 제한
- 세션 시작·재개
- 준비되지 않은 사용자를 제외하거나 기다림

## 4. 사용자 Ready와 Client Ready

### 4.1 사용자 Ready

사용자가 로비에서 `준비`를 눌렀다는 의미다.

- Character 선택과 필요한 설정을 마침
- 세션 시작 의사가 있음
- DM이 시작 판단에 사용할 수 있음

### 4.2 Client Ready

Network와 Runtime 동기화의 기술 상태다.

```text
connected
→ protocol_ready
→ projection_syncing
→ projection_catching_up
→ authority_ready
→ presentation_ready
→ gameplay_ready
```

사용자 Ready가 true여도 `gameplay_ready`가 아니면 Actor Command를 보낼 수 없다.

반대로 Client가 기술적으로 준비됐어도 사용자가 로비 Ready를 누르지 않았을 수 있다.

## 5. 세션 시작

```text
1. DM이 참가자와 Session Role 확인
2. Character와 Control Assignment 확인
3. 필수 사용자의 사용자 Ready 확인
4. Client Authority Ready 확인
5. 활성 Scene Build와 복구 상태 확인
6. 세션 시작 또는 재개 Commit
7. 각 Client에 최신 Projection Catch-up
8. Gameplay Ready 범위 활성화
```

DM이 준비되지 않은 사용자를 두고 강제 시작할 수는 있지만 다음을 명확히 보여준다.

- 아직 동기화 중인 사용자
- Observer로만 입장 가능한 사용자
- Character가 DM 제어로 남는 사용자
- 연결되지 않은 Owner

## 6. 중도 참여

중도 참여는 다음 흐름을 사용한다.

```text
Transport 연결
→ Protocol Negotiation
→ 캠페인 참가 권한과 Session Role 확인
→ Connection Session·Epoch 발급
→ 사용자별 Projection Sync Plan 생성
→ Projection Snapshot Segment 수신
→ Snapshot 원자 적용
→ Base Sequence 이후 Event Catch-up
→ Authority Ready
→ 필요한 Presentation Materialization
→ 안전 경계에서 Control Assignment 활성화
→ Gameplay Ready
```

중도 참여 Client는 Server Raw Snapshot을 받지 않는다.

다음 공개 정책을 적용한 Projection을 받는다.

- Session Role
- Character·Actor 제어권
- Fog와 Perception
- 비밀문·함정 발견 상태
- Journal·Handout 권한
- Observer 공개 정책

## 7. 안전 경계와 참가 시점

미해결 공격, 주사위 공개, Reaction, 저장 Transaction과 Scene Build 교체의 중간 상태에 참가자를 권위 실행 주체로 삽입하지 않는다.

```text
Projection 동기화 완료
→ 현재 Pending Execution 확인
→ 필요한 경우 관찰 전용 상태로 대기
→ Commit 또는 안전 중단 경계 도달
→ 최신 Event Catch-up
→ Control Assignment 활성화
```

동기화 중에도 공개 가능한 전투 화면을 Observer처럼 보여줄 수 있지만, 권위 입력은 Readiness와 Control Assignment가 모두 활성화된 후에만 허용한다.

## 8. 제어권 배정

DM UI에서 Actor를 선택하고 다음을 정한다.

- 대상 사용자 또는 Server Automation
- 즉시 또는 예약 변경
- 이번 행동
- 이번 턴
- 이번 인카운터
- 이번 세션
- 회수 전까지
- 세션 종료 시 자동 반환 여부
- 연결 종료 시 Fallback Controller

플레이어는 자신이 현재 Controller인 Actor에 대해서만 허용된 Command를 보낼 수 있다.

Server는 다음을 다시 검증한다.

- Session Role
- ControlAssignment Revision
- Actor RuntimeObjectRef와 Incarnation
- Active Turn 또는 허용된 Timing Window
- Command Type별 Capability

Client UI에 조작 버튼이 보인다는 사실은 권위가 아니다.

## 9. Observer

Observer는 Character Owner나 Controller가 아니어도 세션을 볼 수 있다.

Observer 정책은 다음을 별도로 정한다.

- 카메라 이동 가능 범위
- 공개 Fog와 Perception View
- DM 전용 정보 접근 여부
- Journal·Handout 접근
- Ping과 채팅 같은 비권위 기능
- Actor Command 금지

Observer에게 DM Raw Projection을 기본으로 제공하지 않는다.

## 10. 연결 종료

연결 종료 시 다음을 유지한다.

- CharacterOwner
- Actor Runtime Object
- Character와 Actor Binding
- 현재 HP, 자원과 Effect
- Encounter 참가 상태
- 진행 중인 권위 Execution

다음은 정책에 따라 변경할 수 있다.

- ControlAssignment
- 입력 대기 상태
- Turn 진행 정책
- Prompt·Reaction 응답 정책

기본 흐름:

```text
Connection Lost
→ 짧은 Grace
→ 진행 중 Command의 처리 상태 확인
→ Commit된 것은 유지
→ 미수신 Result는 Idempotency 상태에 보존
→ 다음 입력 필요 지점에서 세션 정책 적용
→ DM에게 인수·대기·위임 선택지 표시
```

Actor를 연결 종료와 함께 삭제하거나 Archive하지 않는다.

## 11. 재접속

```text
ClientHello + Resume Token + 마지막 Projection Cursor
→ 새 Connection Epoch 발급
→ 이전 Connection Epoch 무효화
→ 최근 Command 상태 확인
→ Delta Resume 가능성 검사
→ Event Catch-up 또는 Full Projection Resync
→ Pending Prompt·Reaction·Roll View 복구
→ Control Assignment 재검증
→ Gameplay Ready
```

재접속 Client가 보내는 로컬 Actor 위치, HP, 인벤토리와 문 상태는 권위 상태로 사용하지 않는다.

### 11.1 Delta Resume

다음을 만족하면 Snapshot 전체를 다시 받지 않을 수 있다.

- 같은 Authority Epoch
- 같은 Session Role과 Projection Policy
- Retained Event Window 안의 View Sequence
- 호환 가능한 Scene Build와 Protocol
- Client Cache Hash 유효

### 11.2 Full Resync

다음 경우 새 Projection Snapshot을 받는다.

- 서버 복구 또는 Rollback으로 Authority Epoch 변경
- Event Retention Window 초과
- Scene Build 교체
- Role·Control·Perception 범위 변경
- Client Projection 무결성 오류
- Protocol 또는 Schema Migration

## 12. 재접속과 진행 중 Command

Client가 Command Result를 받기 전에 연결이 끊길 수 있다.

```text
Client가 같은 Idempotency Key 상태 조회
→ not_seen | received | queued | committed | rejected | cancelled | expired
```

- `not_seen`: 같은 Key로 안전하게 재전송 가능
- `received` 또는 `queued`: 새 중복 Command를 만들지 않고 Result 대기
- `committed`: 최신 Projection과 Result 재전송
- `rejected`: 동일 Terminal Result 재전송

사용자가 같은 버튼을 다시 눌렀다는 이유만으로 새 Idempotency Key를 자동 발급해 중복 행동을 만들지 않는다.

## 13. 재접속과 제어권

DM이 변경하지 않았고 정책상 유효하면 기존 Control Assignment를 복원한다.

다음 경우 자동 복원하지 않는다.

- 다른 Controller에게 명시적으로 이전됨
- Control 기간 종료
- Actor가 다른 Scene Presence로 이전됨
- Authority Epoch 변경 후 Mapping 실패
- Character 또는 Actor가 더 이상 존재하지 않음
- Session Role 변경

복원은 같은 CharacterId만 보는 것이 아니라 현재 ActorId, RuntimeObjectIncarnation과 ControlAssignment Revision을 검증한다.

## 14. 연결 종료 중 전투 정책

캠페인 또는 Encounter 단위로 선택할 수 있다.

```text
pause_on_actor_turn
suggest_dm_takeover
auto_transfer_to_dm
delegate_to_selected_player
server_automation
hold_position_and_skip
```

기본 권장값:

```text
현재 처리 중 행동은 안전 경계까지 완료
→ 다음 입력이 필요한 순간 일시정지
→ DM에게 제어권 인수 제안
```

Server Automation이 공격, 주문과 자원을 자동 사용하려면 DM의 사전 허용이 필요하다.

## 15. 저장 경계

```text
CharacterOwner 변경
→ Campaign Persistent State

ControlAssignment와 기간
→ Active Session State

SessionRole
→ Session Membership State

Client Ready, Connection Epoch와 Projection Cursor
→ Connection·Sync Runtime State
```

Owner 변경과 Control 변경은 별도 Command, Transaction과 감사 로그를 가진다.

Client Ready 자체는 캠페인 장기 저장 데이터가 아니지만 서버 복구와 재접속 진단에 필요한 Connection 기록을 일시 보존할 수 있다.

## 16. 실패 처리

### Protocol 불일치

- 게임 Command 비활성
- 업데이트 필요 표시
- 호환 가능한 Observer Read-only가 명시된 경우에만 제한 입장

### Projection Sync 실패

- 부분 State로 Gameplay Ready 전환 금지
- Segment 재요청
- 반복 실패 시 Full Resync 또는 로비 복귀

### Event Gap

- 권위 입력 일시 정지
- Catch-up 또는 Snapshot Resync
- 연속성 회복 후 재개

### Controller 복원 실패

- Actor와 Character 상태 유지
- DM에게 수동 배정 요청
- Player를 Observer 또는 대기 상태로 유지

### 서버 복구 불완전

- 자동 Gameplay Ready 금지
- DM 복구 화면으로 이동
- 무결성 검사 통과 후 세션 재개

## 17. 테스트 계약

- Owner와 Controller가 다른 Character 입장
- Observer 중도 참여
- 전투 Roll 공개 중 참가
- Reaction Prompt 중 재접속
- Command Result 유실 후 동일 Idempotency Key 재전송
- 이전 Connection Epoch Command 거부
- Event Window 안 Delta Resume
- Event Window 초과 Full Resync
- Rollback 후 이전 Resume Token 거부
- Fog·비밀문 공개 범위가 다른 Player 동시 접속
- 연결 종료 후 DM 인수와 원래 Player 재접속
- Scene Transfer 후 CharacterId 유지·새 ActorId 제어권 배정
- Authority Ready 전에 이동 Command 전송

## 18. 비목표

- 사용자 Ready와 Client Ready를 하나의 상태로 합치지 않는다.
- 중도 참여자에게 Server Raw Snapshot을 전달하지 않는다.
- 연결 종료 시 Actor를 자동 삭제하지 않는다.
- Client의 로컬 상태를 재접속 Authority로 사용하지 않는다.
- Observer에게 기본적으로 DM 전체 정보를 공개하지 않는다.
- 미해결 Transaction 중간에 Controller를 강제로 삽입하지 않는다.
