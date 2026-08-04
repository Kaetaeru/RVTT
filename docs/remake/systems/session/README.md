# Session 시스템

캠페인 로비, 중도 참여, 영구 Owner, 런타임 Controller, Observer, Client 동기화와 Scene Streaming Ready를 다룬다.

## Main System Guide

- [`Session, Networking, Persistence와 Recovery Guide`](../../guides/session/README.md)
  - Campaign Membership·Character Owner·Control Assignment·Session Role의 관계
  - 사용자 Ready와 기술적 Client Ready 분리
  - Lobby·Hot Join·Disconnect·Reconnect와 Scene Transition
  - Versioned Command·Projection Sync·Snapshot·Journal·Recovery·Rollback의 전체 흐름

## 권위 문서

### 사용자 흐름

- [`campaign-lobby-hot-join-ownership-and-control.md`](campaign-lobby-hot-join-ownership-and-control.md)
  - 로비, Character Owner와 Control Assignment
  - Observer와 중도 참여
  - 연결 종료, 재접속과 제어권 복구
  - 사용자 Ready와 기술적 Client Ready 분리

### Session 상태와 Command Gate

- [`../../architecture/session-play-mode-context-overlay-and-transition-contract.md`](../../architecture/session-play-mode-context-overlay-and-transition-contract.md)
  - Exploration·Encounter·Downtime Base Play Mode
  - Context, Overlay와 Transitional State
  - Pause, Join, Reconnect, Recovery와 Rollback Commit Gate
  - Role·Control·Mode·Ready를 결합한 Effective Command Policy

### Network와 동기화

- [`../../architecture/networking-command-event-and-client-synchronization-contract.md`](../../architecture/networking-command-event-and-client-synchronization-contract.md)
  - Protocol Negotiation과 Connection Epoch
  - Projection Snapshot과 Event Catch-up
  - Authority Ready, Presentation Ready와 Gameplay Ready
  - Command Idempotency, Result 복구와 Event Gap 처리
  - 사용자별 Disclosure Projection

### Scene Streaming과 Ready

- [`../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md`](../../architecture/scene-streaming-client-interest-and-ready-activation-contract.md)
  - Scene Entry Essential과 Controlled Actor Activation Set
  - Client-safe Chunk, Cache, Materialization과 Ready Ack
  - Camera·Movement Prefetch와 Gameplay Scope Gate
  - 중도 참여·재접속 Chunk 재사용
  - Prepare·Commit 기반 Scene Transition
  - 준비되지 않은 Controller와 그룹 전환 정책

### 저장과 서버 복구

- [`../../architecture/persistence-and-session-recovery-model.md`](../../architecture/persistence-and-session-recovery-model.md)
  - Manifest·Chunk Authority Snapshot과 Commit Journal
  - Pending RuleExecution·Resource Reservation 복구
  - Server Restart, Branch, AuthorityEpoch와 DM Rollback

## 고정 경계

- Character Owner, 현재 Controller와 Session Role을 하나의 필드로 합치지 않는다.
- Lobby Ready는 사용자의 시작 의사이고 Client Ready는 기술 동기화 상태다.
- 중도 참여자는 Raw Server State가 아니라 권한별 Projection Snapshot을 받는다.
- Authority Ready 전에는 권위 Gameplay Command를 허용하지 않는다.
- Presentation Ready는 모든 장식이 아니라 현재 Scene Essential Activation Set 준비를 뜻한다.
- Scene Transition은 공개 가능한 정적 Chunk를 먼저 Stage한 뒤 안전 경계에서 Presence를 옮긴다.
- 재접속 Client가 보낸 로컬 상태와 Cache를 권위 상태로 사용하지 않고 Hash·Grant·Cursor를 다시 검증한다.
- 이전 Connection Epoch의 Command와 Ready 신호를 무효화한다.
- Recovery와 Rollback 이후 새 AuthorityEpoch를 발급하고 이전 Branch의 Prompt·Subscriber를 무효화한다.
- Snapshot Chunk 경계와 Gameplay Transaction 경계를 동일시하지 않는다.

## Guide Status

```text
CURRENT
```

현재 권위 문서 관계와 사용자·복구 흐름은 Main System Guide에 반영되어 있다. 권위 계약이 변경되면 Guide를 `UPDATE_REQUIRED`로 전환한다.
